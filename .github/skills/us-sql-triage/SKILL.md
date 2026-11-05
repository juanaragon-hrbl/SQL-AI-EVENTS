---
name: us-sql-triage
description: Process a user story (US) and implement only its SQL tasks. Use when a US number (e.g. 665485), work item URL, user story, acceptance criteria, or ticket text is provided.
---

# User story → SQL only

**Step 0 — Fetch the US.** If only a US number (or work item URL) is given, retrieve it with the `azure-devops-readonly` MCP server: org `Herbalife-GTS`, project `Herbalife One`, URL `https://dev.azure.com/Herbalife-GTS/Herbalife%20One/_workitems/edit/<ID>`. Read title, description, acceptance criteria and child tasks. Read-only; if it can't be fetched, ask the user for the text.

Follow `.github\instructions\us.instructions.md` strictly:

1. **Classify** every task/acceptance criterion inline as `SQL` or `NON-SQL` (UI, translations, config, deployment).
2. **State scope**: "I will implement the following SQL tasks: [...]. Out of scope: [...]". Do this before any SQL.
3. **DDL review** of all relevant objects (see the `sproc-authoring` skill); ask if something is missing.
4. **Implement SQL items only**, following the coding standards. Update DDL if schema changes are needed. Never produce UI code, translation strings or config.
5. **Document & summarize**: write `docs\user-stories\US-<US-ID>.md` with requirements, acceptance criteria, objects reviewed, impact, work performed, proposals, pending tests and open questions. Mark facts vs inferences, and work performed vs proposed. Save each proposed script to `docs\scripts\US-<US-ID>_<ObjectName>.sql` (scripts only, no documentation there) and link it from Proposals; all documentation stays in the `docs\user-stories` file. Then summarize: objects created/modified, and NON-SQL items left out with reasons.

**Constraints:** never execute scripts or procedures, never modify the database, never update the US in Azure DevOps. If information is insufficient, say so instead of assuming.
