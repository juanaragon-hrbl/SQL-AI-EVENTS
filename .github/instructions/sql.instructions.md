---
applyTo: "**/*.sql"
---

Use the DDL files in `/ddl` as the authoritative schema reference for SQL work in this repository.

Before suggesting a stored procedure or any other SQL object, verify the referenced tables, columns, types, keys, and constraints against the DDL files.

Keep SQL changes consistent with the schema defined in `/ddl`, and update the DDL when SQL changes require schema updates.
