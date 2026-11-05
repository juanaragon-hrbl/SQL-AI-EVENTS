---
name: us-sql-triage
description: Process a user story (US) and implement only its SQL tasks. Use when a user story, acceptance criteria, or ticket text is provided.
---

# User story → SQL only

Follow `.github\instructions\us.instructions.md` strictly:

1. **Classify** every task/acceptance criterion inline as `SQL` or `NON-SQL` (UI, translations, config, deployment).
2. **State scope**: "I will implement the following SQL tasks: [...]. Out of scope: [...]". Do this before any SQL.
3. **DDL review** of all relevant objects (see the `sproc-authoring` skill); ask if something is missing.
4. **Implement SQL items only**, following the coding standards. Update DDL if schema changes are needed. Never produce UI code, translation strings or config.
5. **Summarize**: objects created/modified, and NON-SQL items left out with reasons.
