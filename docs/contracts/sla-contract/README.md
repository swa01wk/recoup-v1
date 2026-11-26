# SLA contract file format (v1)

Owner of the catalog rules: [ADR-005](../../adr/ADR-005-sla-catalog-pinned-snapshots.md). This folder owns the **file format**.

- Schema: [sla-contract.v1.schema.json](sla-contract.v1.schema.json) (JSON Schema 2020-12; files are authored in YAML).
- Example: [examples/aws.api-gateway.2022-05-05.example.yaml](examples/aws.api-gateway.2022-05-05.example.yaml). It's an example of the format, not a catalog entry; it fails catalog CI on purpose.

## Layout in the product repo (from M1)

```
catalog/
  aws.api-gateway/
    2022-05-05/
      snapshot.txt      # the terms as published, plain text, never edited after commit
      contract.yaml     # this format; snapshot_sha256 = sha256(snapshot.txt)
```

## Rules the catalog CI enforces

1. `contract.yaml` validates against the schema.
2. `snapshot_sha256` equals the SHA-256 of `snapshot.txt`, and isn't all zeros (R-15).
3. Every `cites.lines` range exists in the snapshot.
4. Versions of one contract don't overlap in `effective_from` / `effective_to`, and a committed version is never edited (ADR-005 §4). A change is a new folder.
5. Every contract has golden tests: the published examples, the minimum-credit edge, an empty interval, and each tier boundary (ADR-005 consequences).
6. Every value in `evidence_formats` exists in [../uploads/README.md](../uploads/README.md).
7. `rounding.basis: recoup_default` must name its Q-xx.

## How a file gets into the product

The catalog sync (worker, `recoup_catalog` role) loads each committed version into `sla_contract_version` at deploy ([schema.sql](../db/schema.sql)). P-06 never edits a contract in the product. A recheck review (J-09) is closed either by dismissing it or by a merged PR that adds the new version; the sync then marks the review `resolved_by_new_version`.

## Exclusion evaluation kinds (R-19)

| Kind | Rules the exclusion out when | Otherwise |
|---|---|---|
| `health_event_attribution` | An AWS Health event (account-specific or public) for the contract's service and Region overlaps the incident window | *unproven* |
| `contributor_attestation` | A contributor (P-02) attests, with name and time, that the cause wasn't on the customer side | *unproven* |
| `account_status` | The account shows no suspension: billed usage continues through the cycle in CUR or Cost Explorer | *unproven* |
| `not_evaluable` | Never by itself | *unproven* unless P-02 attests |
