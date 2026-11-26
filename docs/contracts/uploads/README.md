# Evidence upload formats (v1)

Owner of the decision to take evidence by upload: [ADR-010](../../adr/ADR-010-customer-evidence-by-upload.md). This folder owns the **formats, limits and evidence rules**. Each SLA contract lists the formats it accepts in `evidence_formats` ([SLA contract format](../sla-contract/README.md)).

## Formats

| Format ID | What it is | Record schema | Contracts |
|---|---|---|---|
| `apigw-access-log-jsonl/1` | API Gateway access-log extract, JSON Lines, one request per line | [apigw-access-log-jsonl.v1.schema.json](apigw-access-log-jsonl.v1.schema.json) | aws.api-gateway |
| `canonical-request-csv/1` | Recoup's own CSV, for logs kept anywhere (CloudWatch, a SIEM, an APM tool); header `timestamp,status_code,error_class,resource_id,request_id` | [canonical-request-csv.v1.schema.json](canonical-request-csv.v1.schema.json) | every request-based contract |
| `context-document/1` | A postmortem or notes (PDF, Markdown, plain text) | — (not parsed) | any; context only, never feeds eligibility (ADR-010 §5) |

S3 and DynamoDB formats are added when their snapshots are transcribed (Q-03 verify). Native S3 server access logs are a likely candidate; until then, `canonical-request-csv/1` is the path.

## Limits (applied before parsing; ADR-010 §3)

| Limit | Value |
|---|---|
| File size | ≤ 100 MB as uploaded; ≤ 1 GB after gzip decompression (decompression stops at the cap and the file is rejected) |
| Files per incident window | ≤ 20 |
| Encoding | UTF-8; gzip (`.gz`) or uncompressed |
| Line length | ≤ 64 KB; a longer line counts as malformed |
| Malformed lines | Counted and reported. A file with more than 0.1% malformed lines is rejected. |
| Records outside the incident window | Ignored and counted |
| Content type | Checked by parsing, not by extension or the declared type; nothing is executed |

## Upload flow

1. `POST /claims/{id}/evidence-uploads` with format, incident, file name and size returns a pre-signed S3 POST. The policy pins the object key (`tenants/<tenant>/uploads/<upload_id>`), a `content-length-range` and server-side encryption with the tenant's encryption context ([ADR-018](../../adr/ADR-018-tenant-isolation-row-level-security.md) §5).
2. The browser uploads straight to S3; the file never passes through the API.
3. `POST /evidence-uploads/{id}/complete`. The worker checks size, computes the SHA-256, parses, and emits `evidence.processed` ([events](../events/)).
4. Raw files are deleted 30 days after the claim closes (Q-27; R-52).

## Evidence rules

- **`apigw-internal-5xx`** (aws.api-gateway): a request counts as an *Error* when `status` is 5xx **and** it isn't an integration failure. The fields that separate the two (`integrationStatus`, `errorResponseType`) are an open interpretation: [Q-37](../../product/QUESTIONS.md#q-37-which-api-gateway-access-log-fields-mark-an-internal-error--open-assumption-a-37). Until it's answered, A-37 applies:
  - a 5xx with `errorResponseType` of `INTEGRATION_FAILURE` or `INTEGRATION_TIMEOUT`, or with a 5xx `integrationStatus`, is **not** an Error;
  - any other 5xx **is** an Error;
  - a 5xx without both fields makes the claim *unproven*, with the reason "errors can't be classified".
- **`canonical-request-csv/1`:** `error_class = service_internal` is an Error. A 5xx row marked `unknown` makes the claim *unproven*.
- **Availability per interval** = (requests − errors) ÷ requests × 100. An interval with no requests takes the contract's `empty_interval_value` (R-18).

## Excerpts for the packet (R-29)

- **Allow-list first.** An excerpt keeps only these fields: timestamp, status, API ID, request ID, stage and error type. Everything else is dropped, including IPs, user agents, identities, paths and query strings.
- **Pattern redaction** runs over every kept value: email addresses, IPv4 and IPv6 addresses, bearer tokens, AWS access keys, and 13–19 digit numbers.
- **Review before final.** P-02 sees the list of dropped fields and redaction counts before the packet is final, and the review is recorded on `log_excerpt`.
- Excerpts cover the error intervals plus one interval either side, capped at 2,000 lines per incident.
