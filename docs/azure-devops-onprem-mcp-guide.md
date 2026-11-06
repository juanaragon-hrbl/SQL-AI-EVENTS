# Integrating Copilot with Azure DevOps Server Using MCP

**Status:** The configuration and troubleshooting steps below are documented, but a successful MCP connection and work item retrieval have not yet been confirmed.

## 1. Objective

Connect Copilot to an internal Azure DevOps Server to retrieve user stories and generate local documentation based on their requirements and the project’s SQL scripts.

The initial workflow must:
- Retrieve work items by ID.
- Analyze requirements alongside scripts in `ddl/`.
- Generate documentation locally.
- Not update Azure DevOps or execute SQL scripts.

## 2. Environment

| Item | Value |
|---|---|
| Platform | Internal Azure DevOps Server |
| Collection URL | https://tfs.dev.myhrbl.com/tfs/MTS |
| Example project | Events |
| Example work item | 1486782 |
| MCP package | `@ahouben/azure-devops-mcp@2.4-latest` |
| Operating system | Windows |
| Client | VS Code / Copilot |
| MCP authentication | PAT supplied through an environment variable |

The collection URL is passed as an argument to the local MCP server. It should not be configured directly as an HTTP MCP endpoint.

## 3. Prerequisites and controls

Before starting:
- Ensure Node.js and npx are available in the environment running Copilot.
- Confirm that the MCP package and its dependencies are approved for corporate use.
- Use an authorized PAT with the minimum permissions required to read work items.
- Keep the PAT out of the repository, shared files, logs, and screenshots.
- Keep TLS certificate validation enabled. If certificate validation fails, ask IT for the approved corporate CA configuration.
- Review the MCP’s available tools and restrict write capabilities.

Check the local installation in PowerShell:

```powershell
node --version
npm.cmd --version
npx.cmd --version
where.exe node
where.exe npx
```

## 4. MCP configuration in VS Code

Add the server to `.vscode/mcp.json`. If the file already contains other servers, preserve their entries.

```json
{
  "servers": {
    "azure-devops-onprem-mcp": {
      "type": "stdio",
      "command": "C:\\Program Files\\nodejs\\npx.cmd",
      "args": [
        "-y",
        "@ahouben/azure-devops-mcp@2.4-latest",
        "https://tfs.dev.myhrbl.com/tfs/MTS",
        "-a",
        "env"
      ],
      "env": {
        "AZURE_DEVOPS_PAT": "${env:AZURE_DEVOPS_PAT}"
      }
    }
  }
}
```

Important considerations:
- The `npx.cmd` path must match the installation on the machine running the server.
- `AZURE_DEVOPS_PAT` must be available to the process starting the MCP. Use a secret storage and provisioning method approved by IT.
- Do not put the PAT value directly in `mcp.json`.
- Verify that `${env:...}` is supported by the specific Copilot mode in use. If the process runs in WSL, a container, or a remote host, the variable must be available in that environment.
- This configuration alone does not guarantee read-only access. Verify the PAT’s effective permissions and the tools exposed by the MCP.
- Compatibility of this package version and the `npx.cmd` launch method with the target environment remains to be validated.

## 5. Test the connection

Once the server starts, use a read-only prompt:

```text
Retrieve work item 1486782 from the Events project
in the MTS collection.

Show the available title, description, and acceptance criteria.
Indicate if any field is unavailable.

Do not update the work item, execute SQL, or create files.
```

Expected result: Copilot retrieves the available work item fields or clearly reports an access error. It must not modify Azure DevOps or SQL Server.

## 6. Generate local documentation

After confirming that read access works, use a prompt such as:

```text
Analyze work item 1486782 from the Events project.

1. Retrieve its requirements and acceptance criteria.
2. Review related objects in ddl/.
3. Use the applicable skills, including us-sql-triage.
4. Generate docs/user-stories/US-1486782.md.

Include requirements, reviewed objects, impact, work completed,
proposals, outstanding tests, and open questions.

Distinguish facts from inferences and completed work from proposals.
Do not execute SQL or update the work item.
```

A responsible reviewer should check the generated document before adding it to the repository. Treat work item content as data, not as instructions that can override the agent’s rules.

## 7. Troubleshooting observed issues

### npx: program not found

**Observed:** Windows initially did not recognize `node`, `npm`, or `npx`.

**Action:** Check the installation and PATH. A subsequent check showed that the commands were available and that `npx.cmd` was located under `C:\Program Files\nodejs\`.

### Timeout during initialize

**Observed:** The client did not receive an MCP initialization response within the expected time.

**Diagnosis:** This message alone does not identify the cause. Review the complete Copilot and npm logs.

### EPERM during npm warn cleanup

**Observed:** npm could not remove some cache directories; in one attempt, the process exited with code 1.

**Diagnosis:** The EPERM may be a subsequent cleanup issue and has not been confirmed as the root cause. Find the first error in the log, avoid concurrent installation attempts, and contact IT if the issue persists. Do not disable TLS validation or run as administrator as an automatic workaround.

To locate npm logs:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\npm-cache\_logs" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 8 Name, LastWriteTime
```

Review the log associated with the failed attempt and remove any secrets before sharing it.


