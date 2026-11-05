---
name: lineage-hierarchy
description: Write SQL involving distributor downline/upline, sponsor/supervisor lineage, or team levels. Use for "downline", "upline", "team", "lineage", "level from HL/UL".
---

# Lineage / hierarchy

Check these objects in `ddl\` before writing any lineage SQL:

- `Views\v_dimDSLngDownline` — `PK_Distributor`, `PK_MainDistributor`, `PK_DSDownline`, `DSLevelFromHL/UL`, `SPLevelFromHL/UL` (reads `PubEvents.dbo.dimDSLngDownline_wBlock`).
- `Views\v_DistributorLineage`, `Views\v_SupervisorLineage`.
- `Functions\ufn_GetDownline*` (`ufn_GetDownline`, `...BlockedBySP`, `...BlockedByFTEASP`, `...MX`, etc.) — pick the variant matching the blocking rule needed.
- Qualification functions `ufn_Qual*` / `ufn_GetQualifier_*` that consume downlines.

Rules: open the DDL of the chosen object and confirm level semantics (DS vs SP, HL vs UL) before use; join on the PK_* columns; filter `DeletedDate IS NULL` on `dimDistributor` when joining it; avoid recursive cursors/loops — use the precomputed lineage views.
