---
name: sql-review
description: Review T-SQL (stored procedures, views, functions) against this repo's standards and DDL. Use for "review this proc/query", "check my SQL".
---

# SQL review checklist

Verify against the DDL first (names, types, nullability, keys), then check:

- **Standards**: `SET NOCOUNT ON`; DML in TRY/CATCH; explicit transaction for multi-table writes with rollback + `THROW`; header block (purpose, params, examples); `usp_`/`ufn_` prefixes; no `SELECT *`; no cursors.
- **Soft delete**: `DeletedDate IS NULL` where the column exists (verify per table).
- **Correctness**: join keys and grain (duplicates from one-to-many), NULL handling in joins/`NOT IN`, implicit conversions, date boundaries (use `>= start AND < end`), SQL Server 2017 compatibility (no newer syntax).
- **Performance**: sargable predicates (no functions on indexed columns), `NOLOCK` use is deliberate, avoid scalar UDFs in large sets, temp tables/indexes for big intermediates, no row-by-row loops.
- **Safety**: parameterized dynamic SQL (`sp_executesql`), no unintended data deletion, GDPR tables (`GDPR*`) handled carefully.

Output findings grouped by severity (bug / risk / nit) with line references and suggested fixes; skip trivial style comments.
