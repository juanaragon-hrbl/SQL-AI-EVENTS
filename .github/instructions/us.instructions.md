---
applyTo: "**/*.us.md,**/user-stories/**,**/us/**"
---

# User Story Processing — SQL Tasks Only

When a user story (US) is provided, follow this protocol strictly before generating any SQL.

## Step 1 — Parse and Classify

Read every task and acceptance criterion in the user story. Classify each item with one of:

- **SQL** — requires a stored procedure, query, view, schema change, or any T-SQL object
- **NON-SQL** — UI, frontend, translations, configuration, deployment, or anything else

Label each item inline so the classification is transparent. Example:

```
1. Filter out free tier members from result set → SQL
2. Append "Not Applicable In India" translation → NON-SQL (UI / Translations)
3. Add year selector to calendar widget → NON-SQL (UI)
4. Sort result set by Subscription End Date ASC → SQL
```

## Step 2 — Scope Confirmation

After classification, state explicitly:

> "I will implement the following SQL tasks from this user story: [list].
> The following items are out of scope for this session: [list]."

Do not proceed until the scope is stated.

## Step 3 — DDL Review

Before writing any SQL, open and review every DDL file under `/ddl` that is relevant to the tables, views, or objects referenced in the SQL tasks. Confirm:

- Exact table and column names
- Data types and nullability
- Primary keys, foreign keys, and unique constraints
- Any soft-delete pattern (this schema uses a nullable `DeletedDate` column, not `IsDeleted` — confirm the column exists on the table before filtering)

If a required table or column is not found in `/ddl`, say so and ask for clarification rather than assuming.

## Step 4 — Implement SQL Tasks Only

Implement only the SQL-classified items identified in Step 1. For each:

- Follow all coding standards in `.github/copilot-instructions.md` (`SET NOCOUNT ON`, `TRY/CATCH`, explicit transactions, naming prefixes, no `SELECT *`, no cursors, `DeletedDate IS NULL` filter where applicable, header comment block).
- If the SQL task requires a schema change, update the relevant file(s) under `/ddl` as part of the same response.
- Do not produce any UI code, translation strings, configuration changes, or non-SQL artifacts.

## Step 5 — Summary

End with a brief summary that lists:

1. SQL tasks completed and the objects created or modified.
2. NON-SQL tasks explicitly left out and why (out of scope for SQL work).

---

## Quick Reference — What Counts as SQL

| Counts as SQL | Does NOT count as SQL |
|---|---|
| Stored procedure create / alter | Frontend component changes |
| View create / alter | CSS / HTML / JS |
| Schema / DDL change | Translation strings or resource files |
| Query logic (filters, sorts, joins) | API route or controller logic |
| Index or constraint change | Deployment scripts or CI config |
| Scalar / table-valued function | Documentation-only updates |
