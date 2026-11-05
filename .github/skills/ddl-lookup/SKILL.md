---
name: ddl-lookup
description: Find the canonical table, view, function or column in the DDL and report its schema. Use for "which table has...", "columns of...", or before referencing any database object.
---

# DDL lookup

Folders under `ddl\`: `Tables`, `Views`, `Functions`, `Stored Procedures`, `User Defined Types`. Files are named after the object and saved as **UTF-16** (use a UTF-16-aware search/read).

- Prefixes: `dim*`/`fact*`/`agg*` (warehouse), `Rule*` (rules), `AI_*_IN`/`AI_*_OUT` (AI prediction), `v_*`/`v_RPT_*` (views).
- Functions use mixed legacy prefixes `fn_`, `udf_`, `ufn_`; search all three. New ones use `ufn_`.
- Skip `*_BAK#`, `*_tmp`, `*_Backup`; prefer the non-suffixed object.
- Some views read cross-database (e.g. `PubEvents.dbo.dimDSLngDownline_wBlock`); that base table is not in this repo.

Report: exact object name, columns with type and nullability, PK/FK/unique constraints, and whether `DeletedDate` exists. If not found, say so.
