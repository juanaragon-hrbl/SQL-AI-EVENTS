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
- `ddl\Tables\` — 259 table definitions (one file per object, named exactly after the `[dbo].[ObjectName]`). Covers the Events domain: `Event*`, `SubEvent*`, qualifiers/registrations, `AWT_*`, `PromotionAccelerator*`, `GDPR*`, plus data-exchange variants (`*_IN`, `*_OUT`, `*_Archive`, `*_Extract`), working tables (`WRK_*`, `Temp*`) and legacy copies (`*_BAK#`, `*_tmp`, `*_Backup`) — do not treat working/backup/temp tables as canonical; prefer the non-suffixed version.
- `ddl\Views\` — `v_*` views (distributor, event, qualifier, AWT, `v_aggDSFinancial*`) and per-region `Events_Promotions_DRS_*` views.
- `ddl\Functions\` — scalar/table-valued functions. Legacy objects use `udf_` and `ufn_` prefixes inconsistently; new functions must use `ufn_` per the coding standard below.
- `ddl\Stored Procedures\` — 700+ existing `usp_*` procedures, one `.sql` file per procedure. Review similar ones for conventions; add new procedures here as `usp_<Name>.sql`.
- `ddl\User Defined Types\` — user-defined types.
- Each DDL file is a standalone `CREATE` script (SSMS-style `/****** Object: ... ******/` header, `SET ANSI_NULLS ON` / `SET QUOTED_IDENTIFIER ON`, `GO` batches) scripted from SQL Server — not a migration history. **Files are saved as UTF-16**; when reading/writing them with scripting tools, preserve that encoding.
- Key data sources for reporting and qualification stored procedures: the `v_Distributor*`, `v_EventQualifiers*`, `v_EventTickets` and `v_aggDSFinancial*` views. The lineage views `v_dimDSLngDownline`, `v_DistributorLineage`, `v_SupervisorLineage` (the downline view reads `PubEvents.dbo.dimDSLngDownline_wBlock`, a cross-database table not in this repo) and the `ufn_GetDownline*` functions implement the distributor downline hierarchy used throughout qualification (`ufn_Qual*`) and reporting logic — check these before writing any new lineage- or team-level-related SQL.

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
