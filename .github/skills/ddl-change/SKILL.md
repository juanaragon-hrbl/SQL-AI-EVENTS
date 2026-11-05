---
name: ddl-change
description: Apply schema changes (add/alter column, new table, view, index, constraint) and keep ddl\ files in sync. Use for "add column", "alter table", "create table/view".
---

# DDL change

1. Open the current DDL file for every affected object (`ddl\Tables|Views|Functions|User Defined Types`) and confirm the existing definition.
2. Make the change in the file in the repo's format: SSMS-style `/****** Object: ... ******/` header, `SET ANSI_NULLS ON`, `SET QUOTED_IDENTIFIER ON`, `GO` batches, one object per file named after the object. Save as **UTF-16**.
3. Also provide the deployable `ALTER`/`CREATE` script (idempotent where practical, e.g. `IF COL_LENGTH(...) IS NULL`), since the files are not a migration history.
4. Find dependents with a grep across `ddl\` (UTF-16-aware) for the object/column name: procs, views, functions that must change.
5. Prefer nullable or defaulted new columns to avoid breaking existing inserts; never name new objects with `_BAK`/`_tmp` suffixes.
6. Summarize objects changed and impacted dependents.
