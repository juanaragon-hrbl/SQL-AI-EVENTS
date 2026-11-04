This repository is used for AI-assisted SQL development. It contains no application code, build pipeline, lint, or test suite (so no build/test commands) — it is a DDL reference repo (scripted from SQL Server) plus Copilot instructions used to generate T-SQL (mainly stored procedures) that is deployed elsewhere.

Treat the SQL DDL stored under `/ddl` as the source of truth for the database schema.

When generating or editing SQL, especially stored procedures, always review the relevant DDL files first and keep suggestions aligned with object names, column names, data types, nullability, keys, and constraints defined there.

If a requested SQL change depends on schema changes, update the related DDL in `/ddl` as part of the same task.

## Database Platform
SQL Server 2017, schema [dbo]

## DDL Location
All schema definitions are in the /ddl folder.
Always reference these as the source of truth for table/column names.

### Repository layout
- `ddl/tables/` — 170+ table definitions (one file per object, named exactly after the `[dbo].[ObjectName]`). Includes dimensional/fact tables (`dim*`, `fact*`, `agg*`), rule tables (`Rule*`), AI prediction input/output tables (`AI_*_IN`/`AI_*_OUT`), and legacy backup/temp copies (`*_BAK#`, `*_tmp`, `*_Backup`) — do not treat backup/temp tables as canonical; prefer the non-suffixed version.
- `ddl/views/` — `v_*` and `v_RPT_*` reporting views, plus a few test-support objects (`TestClasses.sql`, `Tests.sql`, `Private_SysIndexes.sql`, `Private_SysTypes.sql`).
- `ddl/functions/` — scalar/table-valued functions. Legacy objects use `fn_`/`udf_`/`ufn_` prefixes inconsistently (e.g. `udf_GenerateDates.sql` vs `fn_GenerateDates.sql`); new functions must use `ufn_` per the coding standard below.
- `ddl/sprocs/` — currently empty; no existing stored procedure DDL has been captured here yet. New stored procedures created with Copilot's help should be added here as one `.sql` file per procedure, named `usp_<Name>.sql`.
- Each DDL file is a standalone `CREATE` script (SSMS-style `/****** Object: ... ******/` header, `SET ANSI_NULLS ON` / `SET QUOTED_IDENTIFIER ON`, `GO` batches) scripted from SQL Server — not a migration history. **Files are saved as UTF-16**; when reading/writing them with scripting tools, preserve that encoding.
- `v_RPT_*` views and `agg*`/`fact*` tables are the primary data sources for reporting stored procedures; `dimDSLngDownline`/`dimDSLngUpline` and the `udf_Common_GetLineage*`/`udf_GetLineage*` functions implement the distributor downline/upline hierarchy used throughout qualification and reporting logic — check these before writing any new lineage- or team-level-related SQL.

## Coding Standards
- Always use SET NOCOUNT ON
- Always wrap DML in TRY/CATCH
- Use explicit transactions for multi-table writes
- Prefix stored procedures: usp_
- Prefix functions: ufn_
- Never use SELECT *, never use cursors
- Always filter soft-deleted rows. This schema has no `IsDeleted` column; the actual pattern is a nullable `DeletedDate` (see `dimDistributor`, `DimNCClub`) — filter with `DeletedDate IS NULL`. Verify the column exists on the specific table before assuming the pattern applies.
- Generate a header comment block for this procedure with parameters, purpose, and examples

## Business Rules
- [Add your domain rules here, e.g. StatusId values]
- [Add what "active", "pending", etc. mean in your system]

## User Story Processing

When a user story is provided as input, follow the full protocol in `.github/instructions/us.instructions.md` before producing any SQL.

The critical rule: **implement only tasks explicitly marked as SQL in the user story**. Ignore all UI, translation, configuration, and non-SQL work, and clearly list what was excluded and why.

Never generate UI code, translation strings, or non-SQL artifacts in response to a user story, even if the story requests them.
