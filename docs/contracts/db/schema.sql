-- Recoup v1 — DB schema draft, contract version 0.1.0 (Stage 2a, 2026-11-27)
-- Owner: docs/contracts. Becomes the first Alembic migration in M0; after that,
-- migrations own the schema and this file is regenerated from them.
-- Plain PostgreSQL only (ADR-008 §5). Tested on PostgreSQL 16.
--
-- Isolation (ADR-018):
--   * Tenant tables: tenant_id + ENABLE/FORCE ROW LEVEL SECURITY, policy on app_current_tenant().
--   * Global tables: catalog, public incidents, anonymous funnel, entitlements. Tenants read, never write.
--   * Infrastructure tables (job, outbox_event, auth_session): no RLS, references only.
-- Money (NFR-03): NUMERIC only. Claim amounts NUMERIC(14,2); billing source amounts NUMERIC(20,10).
--   The stage of each amount is the column it sits in; its source is the *_source column next to it.
-- Claim key (ADR-024): account × contract × Region × billing cycle.

BEGIN;

-- ---------------------------------------------------------------------------
-- Roles (ADR-018 §2). Created here for the draft; in AWS the CDK stack creates them
-- and grants rds_iam (ADR-023 §5).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'recoup_app')       THEN CREATE ROLE recoup_app NOLOGIN;       END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'recoup_catalog')   THEN CREATE ROLE recoup_catalog NOLOGIN;   END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'recoup_lifecycle') THEN CREATE ROLE recoup_lifecycle NOLOGIN; END IF;
END $$;

CREATE SCHEMA recoup;
SET search_path = recoup;

-- Returns NULL when no tenant is set, so every policy matches nothing (fail closed).
CREATE FUNCTION app_current_tenant() RETURNS uuid
  LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.tenant_id', true), '')::uuid $$;

-- ---------------------------------------------------------------------------
-- Enumerations
-- ---------------------------------------------------------------------------
CREATE TYPE claim_stage AS ENUM (           -- docs/contracts/claim-state-machine.yaml
  'detected', 'eligible', 'unproven', 'not_eligible',
  'approved', 'submitted', 'granted', 'denied',
  'posted', 'refunded_outside_bill', 'closed');
CREATE TYPE member_role       AS ENUM ('approver', 'contributor', 'viewer');           -- Q-18
CREATE TYPE member_status     AS ENUM ('invited', 'active', 'removed');
CREATE TYPE connection_status AS ENUM ('pending_deploy', 'testing', 'connected', 'failed', 'disconnected');
CREATE TYPE billing_source    AS ENUM ('cost_explorer', 'cur2');                       -- ADR-009
CREATE TYPE incident_source   AS ENUM ('account_health', 'public_health', 'customer_supplied', 'operator_entered');
CREATE TYPE public_source     AS ENUM ('eventbridge', 'health_api', 'operator_entered'); -- ADR-021
CREATE TYPE window_source     AS ENUM ('health_event', 'entered_by_contributor', 'confirmed_by_contributor');
CREATE TYPE eligibility       AS ENUM ('eligible', 'unproven', 'not_eligible');
CREATE TYPE upload_status     AS ENUM ('awaiting_upload', 'received', 'parsing', 'parsed', 'rejected');
CREATE TYPE approval_status   AS ENUM ('active', 'declined', 'revoked', 'invalidated', 'expired', 'consumed');
CREATE TYPE match_kind        AS ENUM ('verified', 'possible');                         -- ADR-022
CREATE TYPE match_status      AS ENUM ('auto_applied', 'proposed', 'confirmed', 'rejected');
CREATE TYPE job_status        AS ENUM ('queued', 'running', 'succeeded', 'failed', 'dead');
CREATE TYPE actor_type        AS ENUM ('user', 'operator', 'system');
CREATE TYPE review_status     AS ENUM ('open', 'dismissed', 'resolved_by_new_version');

-- ===========================================================================
-- GLOBAL TABLES (no tenant data)
-- ===========================================================================

-- SLA catalog (ADR-005). Loaded from the repo's catalog files by the catalog sync at deploy.
CREATE TABLE sla_contract (
  contract_id      text PRIMARY KEY,                 -- e.g. 'aws.api-gateway'
  service_name     text NOT NULL,
  scope_level      text NOT NULL CHECK (scope_level IN ('region')),  -- ADR-024 §5
  cur_product_codes text[] NOT NULL CHECK (cardinality(cur_product_codes) > 0)  -- ADR-022 §1
);

CREATE TABLE sla_contract_version (
  id                 uuid PRIMARY KEY,
  contract_id        text NOT NULL REFERENCES sla_contract,
  version            text NOT NULL,                  -- e.g. '2022-05-05'
  effective_from     date NOT NULL,
  effective_to       date,                           -- NULL = in force
  source_url         text NOT NULL,
  source_read_at     date NOT NULL,
  page_last_updated  date NOT NULL,
  snapshot_sha256    char(64) NOT NULL CHECK (snapshot_sha256 ~ '^[0-9a-f]{64}$'),
  structured         jsonb NOT NULL,                 -- validated against sla-contract.v1.schema.json
  structured_sha256  char(64) NOT NULL CHECK (structured_sha256 ~ '^[0-9a-f]{64}$'),
  published_ref      text NOT NULL,                  -- git commit of the merge that added it
  published_at       timestamptz NOT NULL,
  UNIQUE (contract_id, version),
  CHECK (effective_to IS NULL OR effective_to > effective_from)
);

CREATE TABLE sla_recheck_review (                    -- R-17, J-09
  id                   uuid PRIMARY KEY,
  contract_id          text NOT NULL REFERENCES sla_contract,
  detected_at          timestamptz NOT NULL,
  latest_version_id    uuid NOT NULL REFERENCES sla_contract_version,
  fetched_text_sha256  char(64) NOT NULL,
  diff_summary         text NOT NULL,                -- untrusted page text; shown escaped
  status               review_status NOT NULL DEFAULT 'open',
  decided_by           text,                         -- operator sub
  decided_at           timestamptz,
  resolved_version_id  uuid REFERENCES sla_contract_version
);

-- Public AWS Health capture (ADR-021).
CREATE TABLE public_health_message (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_arn         text NOT NULL,
  communication_id  text NOT NULL,
  delivery_region   text NOT NULL,
  backup_event      boolean NOT NULL,
  received_at       timestamptz NOT NULL,
  raw               jsonb NOT NULL,                  -- untrusted (NFR-09)
  raw_sha256        char(64) NOT NULL,
  UNIQUE (event_arn, communication_id)               -- AWS de-dup advice
);

CREATE TABLE public_incident (                       -- projection; R-34, R-12
  id                 uuid PRIMARY KEY,
  source             public_source NOT NULL,
  event_arn          text UNIQUE,                    -- NULL only for operator_entered
  service            text NOT NULL,                  -- Health 'service' code, e.g. 'APIGATEWAY'
  event_type_code    text,
  event_region       text NOT NULL,                  -- AWS Region or 'global'
  start_time         timestamptz NOT NULL,
  end_time           timestamptz,
  status             text NOT NULL CHECK (status IN ('open', 'closed', 'upcoming')),
  description        text,                           -- untrusted
  last_updated_time  timestamptz NOT NULL,
  source_url         text,                           -- required for operator_entered
  entered_by         text,                           -- operator sub, operator_entered only
  captured_at        timestamptz NOT NULL,
  CHECK ((source = 'operator_entered') = (event_arn IS NULL)),
  CHECK (source <> 'operator_entered' OR (source_url IS NOT NULL AND entered_by IS NOT NULL)),
  CHECK (end_time IS NULL OR end_time >= start_time)
);
CREATE INDEX public_incident_lookup ON public_incident (service, event_region, start_time);

-- Anonymous no-access check (J-01, Q-31). No contact data.
CREATE TABLE estimate_run (
  id               uuid PRIMARY KEY,
  anon_session_id  uuid NOT NULL,
  created_at       timestamptz NOT NULL,
  inputs           jsonb NOT NULL,                   -- regions, services, spend bands
  result           jsonb NOT NULL                    -- incidents, ranges, assumptions (R-34)
);

CREATE TABLE funnel_event (                          -- KPI-03 (R-35, R-09)
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  anon_session_id  uuid NOT NULL,
  event_type       text NOT NULL CHECK (event_type IN (
                     'estimate_viewed', 'book_interview_clicked', 'connect_clicked',
                     'signed_up', 'connection_created', 'connection_test_passed', 'report_completed')),
  occurred_at      timestamptz NOT NULL,
  properties       jsonb NOT NULL DEFAULT '{}'       -- IDs and enums only; no tenant content
);

-- Commercial flag set by P-06 (R-55: all packets for pilot tenants). Holds no tenant content.
CREATE TABLE tenant_entitlement (
  tenant_id        uuid PRIMARY KEY,
  pilot_agreement  boolean NOT NULL DEFAULT false,
  updated_by       text NOT NULL,
  updated_at       timestamptz NOT NULL
);

CREATE TABLE operator_audit_record (                 -- every P-06 action (Q-32)
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  operator_sub text NOT NULL,
  action       text NOT NULL,
  target_type  text NOT NULL,
  target_id    text NOT NULL,
  details      jsonb NOT NULL DEFAULT '{}',
  occurred_at  timestamptz NOT NULL,
  trace_id     text
);

-- ===========================================================================
-- INFRASTRUCTURE TABLES (no RLS; references only — ADR-018 §5)
-- ===========================================================================

CREATE TABLE auth_session (                          -- ADR-017 §3–4
  id              char(64) PRIMARY KEY,              -- SHA-256 of the cookie value
  pool            text NOT NULL CHECK (pool IN ('customer', 'operator')),
  user_sub        text NOT NULL,
  tenant_id       uuid,                              -- selected tenant; NULL for operators
  mfa_at          timestamptz NOT NULL,
  created_at      timestamptz NOT NULL,
  last_seen_at    timestamptz NOT NULL,
  expires_at      timestamptz NOT NULL,
  revoked_at      timestamptz,
  csrf_hash       char(64) NOT NULL,
  CHECK ((pool = 'operator') = (tenant_id IS NULL))
);

CREATE TABLE job (                                   -- ADR-020
  id             uuid PRIMARY KEY,
  tenant_id      uuid,                               -- NULL for global jobs
  kind           text NOT NULL,
  payload        jsonb NOT NULL,                     -- references only
  payload_schema text NOT NULL,                      -- e.g. 'report.build/1'
  status         job_status NOT NULL DEFAULT 'queued',
  run_after      timestamptz NOT NULL,
  attempts       integer NOT NULL DEFAULT 0,
  max_attempts   integer NOT NULL,
  lease_until    timestamptz,
  fencing_token  bigint NOT NULL DEFAULT 0,
  parent_id      uuid REFERENCES job,
  join_required  boolean NOT NULL DEFAULT false,     -- counts toward the parent's join
  dedupe_key     text UNIQUE,                        -- e.g. 'sla_recheck:2026-11-28T03:00Z'
  last_error     jsonb,                              -- {class, code, message}
  created_at     timestamptz NOT NULL,
  finished_at    timestamptz
);
CREATE INDEX job_ready ON job (run_after) WHERE status = 'queued';

CREATE TABLE outbox_event (                          -- ADR-006 §3; docs/contracts/events/
  event_id        uuid PRIMARY KEY,
  tenant_id       uuid,
  type            text NOT NULL,                     -- e.g. 'claim.stage_changed'
  schema_version  integer NOT NULL,
  aggregate_type  text NOT NULL,
  aggregate_id    uuid NOT NULL,
  aggregate_seq   bigint NOT NULL,
  correlation_id  text NOT NULL,
  causation_id    text,
  actor           jsonb NOT NULL,
  payload         jsonb NOT NULL,                    -- references and summaries only
  occurred_at     timestamptz NOT NULL,
  published_at    timestamptz,
  attempts        integer NOT NULL DEFAULT 0,
  UNIQUE (aggregate_type, aggregate_id, aggregate_seq)
);
CREATE INDEX outbox_unpublished ON outbox_event (occurred_at) WHERE published_at IS NULL;

-- ===========================================================================
-- TENANT TABLES (RLS)
-- ===========================================================================

CREATE TABLE tenant (
  id          uuid PRIMARY KEY,
  tenant_id   uuid GENERATED ALWAYS AS (id) STORED,  -- uniform RLS column
  name        text NOT NULL,
  status      text NOT NULL CHECK (status IN ('active', 'exiting', 'deleted')),
  created_at  timestamptz NOT NULL,
  exit_requested_at timestamptz
);

CREATE TABLE tenant_member (                         -- R-56, Q-18, Q-36
  tenant_id   uuid NOT NULL REFERENCES tenant,
  user_sub    text NOT NULL,                         -- Cognito sub (invites live in tenant_invitation)
  email       text NOT NULL,
  role        member_role NOT NULL,
  status      member_status NOT NULL,
  invited_by  text,
  created_at  timestamptz NOT NULL,
  PRIMARY KEY (tenant_id, user_sub)
);

CREATE TABLE tenant_invitation (                     -- A-36
  id          uuid PRIMARY KEY,
  tenant_id   uuid NOT NULL REFERENCES tenant,
  email       text NOT NULL,
  role        member_role NOT NULL,
  token_hash  char(64) NOT NULL UNIQUE,
  invited_by  text NOT NULL,
  created_at  timestamptz NOT NULL,
  expires_at  timestamptz NOT NULL,
  accepted_at timestamptz
);

CREATE TABLE anon_session_link (                     -- ties the free check to a sign-up (KPI-03)
  tenant_id        uuid NOT NULL REFERENCES tenant,
  anon_session_id  uuid NOT NULL,
  linked_at        timestamptz NOT NULL,
  PRIMARY KEY (tenant_id, anon_session_id)
);

CREATE TABLE aws_connection (                        -- F-01, ADR-003
  id                 uuid PRIMARY KEY,
  tenant_id          uuid NOT NULL REFERENCES tenant,
  aws_account_id     char(12) NOT NULL CHECK (aws_account_id ~ '^[0-9]{12}$'),
  external_id        text NOT NULL UNIQUE CHECK (length(external_id) >= 32),  -- NFR-02: unique across ALL tenants
  role_arn           text,                           -- known after deploy
  template_version   text NOT NULL,
  template_sha256    char(64) NOT NULL,
  status             connection_status NOT NULL,
  cur_bucket         text,
  cur_prefix         text,
  cur_export_region  text,
  -- Discovery answers recorded at connection (ADR-014 §3; Q-04, Q-05, Q-08, Q-20)
  answer_seller        text CHECK (answer_seller IN ('aws_inc', 'aws_india', 'reseller', 'unknown')),
  answer_support_plan  text,
  answer_log_retention text,
  detected_legal_entity text,                        -- from CUR line_item_legal_entity
  detected_health_api   boolean,                     -- from the connection test
  consecutive_access_denied integer NOT NULL DEFAULT 0,  -- R-11 backoff limit
  created_by         text NOT NULL,
  created_at         timestamptz NOT NULL,
  disconnected_at    timestamptz,
  disconnect_reason  text CHECK (disconnect_reason IN ('assume_role_denied', 'customer_request', 'tenant_exit')),
  UNIQUE (tenant_id, aws_account_id)
);

CREATE TABLE connection_test (                       -- R-09
  id             uuid PRIMARY KEY,
  tenant_id      uuid NOT NULL REFERENCES tenant,
  connection_id  uuid NOT NULL REFERENCES aws_connection,
  requested_by   text NOT NULL,
  started_at     timestamptz NOT NULL,
  finished_at    timestamptz,
  results        jsonb NOT NULL DEFAULT '[]'         -- [{check, outcome, reason_code, detail}]
);

CREATE TABLE account_health_event (                  -- R-12, Q-16: every event read is stored
  id            uuid PRIMARY KEY,
  tenant_id     uuid NOT NULL REFERENCES tenant,
  connection_id uuid NOT NULL REFERENCES aws_connection,
  event_arn     text NOT NULL,
  scope         text NOT NULL CHECK (scope IN ('ACCOUNT_SPECIFIC', 'PUBLIC')),
  service       text NOT NULL,
  event_type_code text NOT NULL,
  region        text NOT NULL,
  start_time    timestamptz NOT NULL,
  end_time      timestamptz,
  status        text NOT NULL,
  raw           jsonb NOT NULL,                      -- untrusted
  raw_sha256    char(64) NOT NULL,
  read_at       timestamptz NOT NULL,
  UNIQUE (tenant_id, connection_id, event_arn)
);

CREATE TABLE customer_incident (                     -- R-14
  id            uuid PRIMARY KEY,
  tenant_id     uuid NOT NULL REFERENCES tenant,
  connection_id uuid NOT NULL REFERENCES aws_connection,
  service       text NOT NULL,
  region        text NOT NULL,
  start_time    timestamptz NOT NULL,
  end_time      timestamptz NOT NULL CHECK (end_time > start_time),
  source_note   text,                                -- untrusted
  entered_by    text NOT NULL,
  entered_at    timestamptz NOT NULL
);

CREATE TABLE billing_charge (                        -- F-05; derived monthly aggregates, not raw rows
  id             uuid PRIMARY KEY,
  tenant_id      uuid NOT NULL REFERENCES tenant,
  connection_id  uuid NOT NULL REFERENCES aws_connection,
  billing_period date NOT NULL CHECK (extract(day FROM billing_period) = 1),
  product_code   text NOT NULL,
  region         text NOT NULL,
  amount         numeric(20,10) NOT NULL,
  currency       char(3) NOT NULL CHECK (currency = 'USD'),  -- Q-20
  source         billing_source NOT NULL,
  source_ref     jsonb NOT NULL,                     -- CE request hash, or CUR file keys + delivery time
  read_at        timestamptz NOT NULL,
  UNIQUE (tenant_id, connection_id, billing_period, product_code, region, source)
);

CREATE TABLE cur_credit_line (                       -- ADR-022 §2
  id              uuid PRIMARY KEY,
  tenant_id       uuid NOT NULL REFERENCES tenant,
  connection_id   uuid NOT NULL REFERENCES aws_connection,
  fingerprint     char(64) NOT NULL,
  billing_period  date NOT NULL,
  usage_account_id char(12) NOT NULL,
  product_code    text,                              -- may be empty in CUR
  line_item_type  text NOT NULL CHECK (line_item_type IN ('Credit', 'Refund')),
  description     text,                              -- untrusted
  amount          numeric(20,10) NOT NULL CHECK (amount > 0),  -- stored positive
  currency        char(3) NOT NULL,
  first_seen_at   timestamptz NOT NULL,
  last_seen_at    timestamptz NOT NULL,
  in_latest_export boolean NOT NULL,                 -- false => 'posted line changed' check (ADR-022 §7)
  source_ref      jsonb NOT NULL,
  UNIQUE (tenant_id, fingerprint)
);

CREATE TABLE report (                                -- J-03; NFR-11 timestamps
  id            uuid PRIMARY KEY,
  tenant_id     uuid NOT NULL REFERENCES tenant,
  connection_id uuid NOT NULL REFERENCES aws_connection,
  status        text NOT NULL CHECK (status IN ('queued', 'running', 'completed', 'failed')),
  requested_by  text NOT NULL,
  requested_at  timestamptz NOT NULL,
  started_at    timestamptz,
  completed_at  timestamptz,
  claim_window_start date NOT NULL,
  claim_window_end   date NOT NULL,
  billing_basis billing_source,                      -- what the charges came from
  ce_calls_made integer NOT NULL DEFAULT 0,          -- R-10 (shown vs made)
  failure       jsonb                                -- typed failure (R-05)
);

CREATE TABLE claim (                                 -- ADR-024 key; ADR-004 stages
  id                 uuid PRIMARY KEY,
  tenant_id          uuid NOT NULL REFERENCES tenant,
  connection_id      uuid NOT NULL REFERENCES aws_connection,
  aws_account_id     char(12) NOT NULL,
  contract_id        text NOT NULL REFERENCES sla_contract,
  contract_version_id uuid NOT NULL REFERENCES sla_contract_version,
  region             text NOT NULL,
  billing_period     date NOT NULL CHECK (extract(day FROM billing_period) = 1),
  stage              claim_stage NOT NULL DEFAULT 'detected',
  stage_version      integer NOT NULL DEFAULT 1,      -- optimistic lock; bound by approvals (R-36)
  content_hash       char(64),                       -- hash of the current packet content
  ready              boolean NOT NULL DEFAULT false,  -- R-32 (derived, stored for queries)
  not_ready_reasons  jsonb NOT NULL DEFAULT '[]',
  deadline_earlier   date NOT NULL,                  -- Q-14
  deadline_later     date NOT NULL,
  -- Amounts by stage (R-02). Source columns name where each came from.
  estimate_amount    numeric(14,2),
  estimate_basis     billing_source,                 -- charges behind the estimate
  approved_amount    numeric(14,2),
  granted_amount     numeric(14,2),                  -- customer-entered
  posted_amount      numeric(14,2),                  -- from the matched CUR credit line
  refunded_outside_bill_amount numeric(14,2),        -- customer-entered (R-54)
  credit_not_seen    boolean NOT NULL DEFAULT false, -- R-54
  posted_line_changed boolean NOT NULL DEFAULT false, -- ADR-022 §7
  owner_user_sub     text,                           -- R-45 recipient
  created_at         timestamptz NOT NULL,
  updated_at         timestamptz NOT NULL,
  UNIQUE (tenant_id, aws_account_id, contract_id, region, billing_period),
  CHECK (deadline_later >= deadline_earlier),
  CHECK (stage <> 'posted' OR posted_amount IS NOT NULL),
  CHECK (stage NOT IN ('granted', 'posted') OR granted_amount IS NOT NULL),
  CHECK (stage <> 'refunded_outside_bill' OR refunded_outside_bill_amount IS NOT NULL),
  CHECK (posted_amount IS NULL OR refunded_outside_bill_amount IS NULL)
);

CREATE TABLE claim_incident (                        -- ADR-024 §2
  id                     uuid PRIMARY KEY,
  tenant_id              uuid NOT NULL REFERENCES tenant,
  claim_id               uuid NOT NULL REFERENCES claim,
  source                 incident_source NOT NULL,
  account_health_event_id uuid REFERENCES account_health_event,
  public_incident_id     uuid REFERENCES public_incident,
  customer_incident_id   uuid REFERENCES customer_incident,
  window_start           timestamptz NOT NULL,
  window_end             timestamptz NOT NULL CHECK (window_end > window_start),
  window_source          window_source NOT NULL,
  window_confirmed_by    text,
  match_evidence         jsonb NOT NULL,             -- R-13: event + billed service/region it matched
  CHECK (num_nonnulls(account_health_event_id, public_incident_id, customer_incident_id) = 1),
  CHECK ((source = 'account_health') = (account_health_event_id IS NOT NULL)),
  CHECK ((source IN ('public_health', 'operator_entered')) = (public_incident_id IS NOT NULL)),
  CHECK ((source = 'customer_supplied') = (customer_incident_id IS NOT NULL))
);

CREATE TABLE claim_transition (                      -- ADR-004; append-only
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id     uuid NOT NULL REFERENCES tenant,
  claim_id      uuid NOT NULL REFERENCES claim,
  from_stage    claim_stage,
  to_stage      claim_stage NOT NULL,
  from_version  integer,
  to_version    integer NOT NULL,
  transition    text NOT NULL,                       -- id from claim-state-machine.yaml
  evidence_type text NOT NULL,
  evidence_ref  jsonb NOT NULL,
  actor_type    actor_type NOT NULL,
  actor_sub     text,
  reason        text,
  idempotency_key text NOT NULL,
  occurred_at   timestamptz NOT NULL,
  trace_id      text,
  UNIQUE (tenant_id, claim_id, idempotency_key)      -- C01: duplicate command → one transition
);

CREATE TABLE eligibility_result (                    -- F-04; R-18 – R-24
  id                   uuid PRIMARY KEY,
  tenant_id            uuid NOT NULL REFERENCES tenant,
  claim_id             uuid NOT NULL REFERENCES claim,
  claim_stage_version  integer NOT NULL,             -- stale results rejected (C09 analogue)
  contract_version_id  uuid NOT NULL REFERENCES sla_contract_version,
  contract_snapshot_sha256 char(64) NOT NULL,        -- R-24
  inputs_sha256        char(64) NOT NULL,
  result               eligibility NOT NULL,
  reasons              jsonb NOT NULL,               -- [{code, detail}]
  exclusions           jsonb NOT NULL,               -- R-19: every exclusion with its outcome
  monthly_uptime_percent numeric(9,6),
  credit_percent       numeric(5,2),
  charges_amount       numeric(20,10),
  credit_amount        numeric(14,2),                -- stage: estimate
  claimable            boolean NOT NULL,             -- R-21 minimum credit
  trace                jsonb NOT NULL,               -- R-23: inputs, tier, rounding, result
  computed_at          timestamptz NOT NULL
);

CREATE TABLE evidence_upload (                       -- R-52, ADR-010; formats in docs/contracts/uploads/
  id             uuid PRIMARY KEY,
  tenant_id      uuid NOT NULL REFERENCES tenant,
  claim_id       uuid NOT NULL REFERENCES claim,
  claim_incident_id uuid NOT NULL REFERENCES claim_incident,
  format_id      text NOT NULL,
  s3_key         text NOT NULL,
  declared_size  bigint NOT NULL,
  sha256         char(64),
  status         upload_status NOT NULL,
  rejection      jsonb,
  uploaded_by    text NOT NULL,
  created_at     timestamptz NOT NULL,
  received_at    timestamptz,
  raw_deleted_at timestamptz                         -- Q-27: 30 days after claim closes
);

CREATE TABLE availability_interval (                 -- R-18 computed from evidence
  tenant_id       uuid NOT NULL REFERENCES tenant,
  claim_id        uuid NOT NULL REFERENCES claim,
  interval_start  timestamptz NOT NULL,
  requests        bigint NOT NULL CHECK (requests >= 0),
  errors          bigint NOT NULL CHECK (errors >= 0 AND errors <= requests),
  availability    numeric(9,6) NOT NULL,             -- 100 when requests = 0 (contract rule)
  upload_ids      uuid[] NOT NULL,
  PRIMARY KEY (tenant_id, claim_id, interval_start)
);

CREATE TABLE log_excerpt (                           -- R-29
  id            uuid PRIMARY KEY,
  tenant_id     uuid NOT NULL REFERENCES tenant,
  claim_id      uuid NOT NULL REFERENCES claim,
  s3_key        text NOT NULL,
  sha256        char(64) NOT NULL,
  line_count    integer NOT NULL,
  redactions    jsonb NOT NULL,                      -- [{kind, count, sample_positions}]
  reviewed_by   text,                                -- P-02 sees removals before final
  reviewed_at   timestamptz,
  created_at    timestamptz NOT NULL
);

CREATE TABLE packet (                                -- F-06; R-28 – R-32, R-55
  id            uuid PRIMARY KEY,
  tenant_id     uuid NOT NULL REFERENCES tenant,
  claim_id      uuid NOT NULL REFERENCES claim,
  version       integer NOT NULL,
  content_hash  char(64) NOT NULL,
  fields        jsonb NOT NULL,                      -- per contract claim_fields
  missing       jsonb NOT NULL DEFAULT '[]',
  complete      boolean NOT NULL,
  log_excerpt_id uuid REFERENCES log_excerpt,
  entitlement   text NOT NULL CHECK (entitlement IN ('free_largest', 'pilot', 'not_built')),
  built_at      timestamptz NOT NULL,
  UNIQUE (claim_id, version)
);

CREATE TABLE approval (                              -- F-08; R-36 – R-38
  id              uuid PRIMARY KEY,
  tenant_id       uuid NOT NULL REFERENCES tenant,
  claim_id        uuid NOT NULL REFERENCES claim,
  approver_sub    text NOT NULL,
  content_hash    char(64) NOT NULL,
  amount          numeric(14,2) NOT NULL,
  claim_stage_version integer NOT NULL,
  policy_revision text NOT NULL,
  expires_at      timestamptz NOT NULL,              -- duration: Q-38
  status          approval_status NOT NULL,
  reason          text,                              -- decline / revoke reason
  created_at      timestamptz NOT NULL,
  decided_at      timestamptz
);
CREATE UNIQUE INDEX approval_one_active ON approval (tenant_id, claim_id) WHERE status = 'active';

CREATE TABLE case_submission (                       -- F-09; R-39, R-41
  id               uuid PRIMARY KEY,
  tenant_id        uuid NOT NULL REFERENCES tenant,
  claim_id         uuid NOT NULL REFERENCES claim,
  approval_id      uuid NOT NULL REFERENCES approval,
  aws_case_id      text NOT NULL CHECK (aws_case_id ~ '^[0-9]{5,20}$'),  -- customer-entered
  resubmission_of  uuid REFERENCES case_submission,
  entered_by       text NOT NULL,
  entered_at       timestamptz NOT NULL,
  UNIQUE (tenant_id, aws_case_id)
);

CREATE TABLE case_outcome (                          -- R-40
  id                 uuid PRIMARY KEY,
  tenant_id          uuid NOT NULL REFERENCES tenant,
  submission_id      uuid NOT NULL UNIQUE REFERENCES case_submission,
  outcome            text NOT NULL CHECK (outcome IN ('granted', 'denied')),
  granted_amount     numeric(14,2) CHECK (granted_amount > 0),
  granted_on         date,
  denial_reason_code text,                           -- fixed list (ADR-011 §4)
  denial_case_text   text,                           -- pasted, untrusted (NFR-09)
  predicted_result   jsonb NOT NULL,                 -- R-40 / Q-25
  entered_by         text NOT NULL,
  entered_at         timestamptz NOT NULL,
  CHECK ((outcome = 'granted') = (granted_amount IS NOT NULL AND granted_on IS NOT NULL)),
  CHECK ((outcome = 'denied')  = (denial_reason_code IS NOT NULL))
);

CREATE TABLE credit_match (                          -- F-10; ADR-022
  id                 uuid PRIMARY KEY,
  tenant_id          uuid NOT NULL REFERENCES tenant,
  claim_id           uuid NOT NULL REFERENCES claim,
  credit_line_id     uuid NOT NULL REFERENCES cur_credit_line,
  kind               match_kind NOT NULL,
  status             match_status NOT NULL,
  failed_criteria    text[] NOT NULL DEFAULT '{}',   -- why it's only 'possible'
  variance_vs_estimate numeric(14,2),
  variance_vs_granted  numeric(14,2),
  decided_by         text,
  decided_at         timestamptz,
  created_at         timestamptz NOT NULL,
  UNIQUE (claim_id, credit_line_id),
  CHECK (kind = 'verified' OR status <> 'auto_applied')
);
-- A credit line backs at most one posted claim.
CREATE UNIQUE INDEX credit_line_used_once ON credit_match (tenant_id, credit_line_id)
  WHERE status IN ('auto_applied', 'confirmed');

CREATE TABLE refund_outside_bill (                   -- R-54
  id           uuid PRIMARY KEY,
  tenant_id    uuid NOT NULL REFERENCES tenant,
  claim_id     uuid NOT NULL UNIQUE REFERENCES claim,
  amount       numeric(14,2) NOT NULL CHECK (amount > 0),
  refunded_on  date NOT NULL,
  entered_by   text NOT NULL,
  entered_at   timestamptz NOT NULL
);

CREATE TABLE deadline_notice (                       -- R-45: exactly one email per claim per lead time
  tenant_id     uuid NOT NULL REFERENCES tenant,
  claim_id      uuid NOT NULL REFERENCES claim,
  lead_days     integer NOT NULL CHECK (lead_days IN (14, 3)),
  due_on        date NOT NULL,
  outbox_event_id uuid NOT NULL,
  created_at    timestamptz NOT NULL,
  PRIMARY KEY (tenant_id, claim_id, lead_days)
);

CREATE TABLE audit_record (                          -- NFR-08: same transaction as the change
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id    uuid NOT NULL REFERENCES tenant,
  actor_type   actor_type NOT NULL,
  actor_sub    text,
  action       text NOT NULL,
  target_type  text NOT NULL,
  target_id    text NOT NULL,
  outcome      text NOT NULL CHECK (outcome IN ('succeeded', 'denied')),
  details      jsonb NOT NULL DEFAULT '{}',
  occurred_at  timestamptz NOT NULL,
  trace_id     text,
  request_id   text
);

-- ---------------------------------------------------------------------------
-- RLS on every tenant table (ADR-018 §1)
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'tenant', 'tenant_member', 'tenant_invitation', 'anon_session_link',
    'aws_connection', 'connection_test', 'account_health_event', 'customer_incident',
    'billing_charge', 'cur_credit_line', 'report', 'claim', 'claim_incident',
    'claim_transition', 'eligibility_result', 'evidence_upload', 'availability_interval',
    'log_excerpt', 'packet', 'approval', 'case_submission', 'case_outcome',
    'credit_match', 'refund_outside_bill', 'deadline_notice', 'audit_record']
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON %I USING (tenant_id = app_current_tenant()) '
      'WITH CHECK (tenant_id = app_current_tenant())', t);
  END LOOP;
END $$;

-- Append-only tables: no UPDATE or DELETE for the app (deletion runs as recoup_lifecycle).
-- ---------------------------------------------------------------------------
-- Grants (ADR-018 §2)
-- ---------------------------------------------------------------------------
GRANT USAGE ON SCHEMA recoup TO recoup_app, recoup_catalog, recoup_lifecycle;
GRANT EXECUTE ON FUNCTION app_current_tenant() TO recoup_app, recoup_catalog, recoup_lifecycle;

-- recoup_app: tenant work; reads global tables; writes only the anonymous funnel and infrastructure.
GRANT SELECT ON sla_contract, sla_contract_version, public_incident, tenant_entitlement TO recoup_app;
GRANT SELECT, INSERT ON estimate_run, funnel_event TO recoup_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth_session, job, outbox_event TO recoup_app;
GRANT SELECT, INSERT, UPDATE ON
  tenant, tenant_member, tenant_invitation, anon_session_link, aws_connection, connection_test,
  account_health_event, customer_incident, billing_charge, cur_credit_line, report, claim,
  claim_incident, eligibility_result, evidence_upload, availability_interval, log_excerpt,
  packet, approval, case_submission, case_outcome, credit_match, refund_outside_bill, deadline_notice
  TO recoup_app;
GRANT DELETE ON availability_interval TO recoup_app;   -- recomputed per evidence change
GRANT SELECT, INSERT ON claim_transition, audit_record TO recoup_app;  -- append-only

-- recoup_catalog: global tables only; NO grant on any tenant table.
GRANT SELECT, INSERT, UPDATE ON sla_contract, sla_contract_version, sla_recheck_review,
  public_health_message, public_incident, tenant_entitlement TO recoup_catalog;
GRANT SELECT, INSERT ON operator_audit_record TO recoup_catalog;
GRANT SELECT ON estimate_run, funnel_event TO recoup_catalog;          -- KPI-03 reporting
GRANT SELECT, INSERT, UPDATE ON job, outbox_event, auth_session TO recoup_catalog;

-- recoup_lifecycle: deletion under RLS, one tenant per transaction (R-53, Q-27).
GRANT SELECT, DELETE ON
  tenant_member, tenant_invitation, anon_session_link, connection_test, account_health_event,
  customer_incident, billing_charge, cur_credit_line, evidence_upload, availability_interval,
  log_excerpt TO recoup_lifecycle;
GRANT SELECT, UPDATE ON aws_connection, evidence_upload, tenant TO recoup_lifecycle;
GRANT SELECT ON claim TO recoup_lifecycle;                            -- open-claim check before deletion
GRANT SELECT, INSERT ON audit_record TO recoup_lifecycle;

COMMIT;
