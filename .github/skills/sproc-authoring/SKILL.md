---
name: sproc-authoring
description: Create or modify T-SQL stored procedures (usp_) for SQL Server 2017 following this repo's coding standards and DDL. Use when asked to create/write/edit a stored procedure or usp_.
---

# Stored procedure authoring

1. **Check for an existing proc**: look in `ddl\Stored Procedures\` (700+ exist) for similar `usp_*` before writing a new one; reuse their conventions.
2. **Review DDL first**: open every table/view/function you will reference under `ddl\Tables`, `ddl\Views`, `ddl\Functions`. Confirm names, types, nullability, keys. Ignore `*_BAK#`, `*_tmp`, `*_Backup` tables. If an object or column is missing, ask — never assume.
3. **Write the proc** (`[dbo]` schema, SQL Server 2017):
   - Header comment block: purpose, parameters, examples (`EXEC dbo.usp_X @P = ...`).
   - `SET NOCOUNT ON`; all DML in `BEGIN TRY / BEGIN CATCH`.
   - Explicit transaction for multi-table writes; `ROLLBACK` in CATCH when `@@TRANCOUNT > 0`, then `THROW`.
   - No `SELECT *`, no cursors.
   - Soft-deleted rows: filter `DeletedDate IS NULL` only after verifying the column exists on that table.
   - Name `usp_<Name>`; helper functions `ufn_<Name>`.
4. **Save** to `ddl\Stored Procedures\usp_<Name>.sql`, one object per file, SSMS-style header, `SET ANSI_NULLS ON` / `SET QUOTED_IDENTIFIER ON`, `GO` batches, **UTF-16 encoding**.
5. If the proc needs schema changes, update the matching DDL files in the same task.
