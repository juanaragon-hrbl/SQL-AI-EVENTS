# SQL-AI-EVENTS

A DDL reference repository (scripted from SQL Server 2017, schema `[dbo]`) plus GitHub Copilot instructions and skills used to generate T-SQL — mainly stored procedures — for the **Events** domain. There is no application code, build pipeline, linter or test suite; generated SQL is deployed elsewhere.

## Repository layout

| Path | Contents |
| --- | --- |
| `ddl\Tables\` | 259 tables, one file per `[dbo].[ObjectName]`. Events domain: `Event*`, `SubEvent*`, qualifiers/registrations, `AWT_*`, `PromotionAccelerator*`, `GDPR*`, plus data-exchange (`*_IN`, `*_OUT`, `*_Archive`, `*_Extract`), working (`WRK_*`, `Temp*`) and legacy (`*_BAK#`, `*_tmp`, `*_Backup`) tables. |
| `ddl\Views\` | 61 views: `v_Distributor*`, `v_EventQualifiers*`, `v_EventTickets`, `v_aggDSFinancial*`, lineage views, per-region `Events_Promotions_DRS_*`. |
| `ddl\Functions\` | 56 functions (`ufn_` preferred; legacy `udf_`/`ufn_` mix), including `ufn_Qual*` and `ufn_GetDownline*`. |
| `ddl\Stored Procedures\` | 702 `usp_*` procedures, one file each. |
| `ddl\User Defined Types\` | 36 user-defined types. |
| `.github\copilot-instructions.md` | Repo-wide Copilot rules. |
| `.github\instructions\` | `sql.instructions.md` (for `*.sql`) and `us.instructions.md` (user-story processing). |
| `.github\skills\` | Copilot skills (see below). |

### DDL file conventions
- Each file is a standalone `CREATE` script (SSMS-style header, `SET ANSI_NULLS ON`, `SET QUOTED_IDENTIFIER ON`, `GO` batches) — not a migration history.
- Files are saved as **UTF-16**; preserve that encoding when editing with scripts.
- Working/backup/temp tables are not canonical; prefer the non-suffixed object.
- `ddl\` is the source of truth for object names, types, nullability, keys and constraints. Schema changes must update the matching DDL file.

## Key data sources
- Qualification/reporting: `v_Distributor*`, `v_EventQualifiers*`, `v_EventTickets`, `v_aggDSFinancial*`.
- Lineage (downline/upline): `v_dimDSLngDownline` (reads cross-database `PubEvents.dbo.dimDSLngDownline_wBlock`, not in this repo), `v_DistributorLineage`, `v_SupervisorLineage`, `ufn_GetDownline*`.

## Coding standards
- `SET NOCOUNT ON`; DML in `TRY/CATCH`; explicit transactions for multi-table writes.
- Prefix procedures `usp_`, functions `ufn_`.
- No `SELECT *`, no cursors.
- Filter soft-deleted rows with `DeletedDate IS NULL` (verify the column exists on the table).
- Every procedure gets a header comment block with parameters, purpose and examples.

## Copilot skills (`.github\skills\`)
| Skill | Use for |
| --- | --- |
| `ddl-lookup` | Find tables/views/functions/columns before referencing them. |
| `ddl-change` | Schema changes, keeping `ddl\` in sync. |
| `sproc-authoring` | Create/modify `usp_` procedures. |
| `sql-review` | Review T-SQL against standards and DDL. |
| `events-qualification` | Events, sub-events, registrations, tickets, qualifier logic. |
| `lineage-hierarchy` | Downline/upline, sponsor/supervisor, team levels. |
| `us-sql-triage` | Process a user story and implement only its SQL tasks. |

## Typical workflow
1. Look up relevant objects in `ddl\` (`ddl-lookup`).
2. Write or edit the procedure/view/function following the coding standards.
3. If schema changes are needed, update the DDL in the same change.
4. Review with `sql-review`.

For user stories, only tasks explicitly marked as SQL are implemented; UI, translation and config work is excluded (see `.github\instructions\us.instructions.md`).
