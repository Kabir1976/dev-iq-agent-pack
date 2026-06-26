# Workspace Topology

Read when `.dev-iq/config.yaml` → `workspace.role` is `prod` or `tests`.
Monorepo users (the default) do not need this file.

## Roles

| Role | Meaning | Behavior |
|------|---------|----------|
| `monorepo` (default) | Production code and tests in one workspace | All four DI layers assessable from this workspace |
| `prod` | This repo holds production code; tests live in a separate repo | QUALITY layer may be UNGRADED for test coverage — note `companion_repo` |
| `tests` | This repo holds tests; production code is elsewhere | INTENT and DESIGN layers assessed via companion repo — note if unset |

## Companion Repo Fetch Fallback

When `workspace.role` is `prod` or `tests`, the agent resolves cross-repo data in this order:

1. **MCP** — if a filesystem or VCS MCP server is configured pointing at the companion repo, use it.
2. **Local path** — if `companion_repo.path` is set and the path exists on disk, read directly.
3. **Manual paste** — if neither is available, ask the user to paste the relevant content inline.

## UNGRADED Contract

When `companion_repo` is unset or unreachable, the affected layer is **UNGRADED** with an explicit reason:

- `companion_repo_unset` — `workspace.role` is `prod` or `tests` but no companion is configured.
- `companion_repo_unreachable` — companion is configured but MCP failed and local path does not exist.

Never fabricate coverage or test data from the wrong repo. State the reason and the layer that is UNGRADED, then continue with the layers that are assessable.
