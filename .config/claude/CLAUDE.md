# Claude Code — Graph Routing

| Question / keywords | Graph to query |
|---|---|---|
| permissions, roles, alerts, cases, scenarios, kyc, teams, superadmin, serializers, exports, dashboard | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-tms-backend/graph.json` |
| ingestion, auth, token, webhook, rfi, postgres, encryption, schema, keyvault, screening | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-tms-client-routes/graph.json` |
| worker, ingestion, chunk, postgres, scenario, storage, provider, validation, upsert, batch | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-tms-worker/graph.json` |
| fcc-backend, django, migration, sqlglot, fcc api, fcc compliance backend | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-fcc-backend/graph.json` |
| fcc-frontend, react, eslint, js, frontend, ui components, fcc ui | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-fcc-frontend/graph.json` |
| fcc-worker, asyncio, celery, fcc worker, task queue, fcc background | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-fcc-worker/graph.json` |
| sams, client facing, api, config bootstrap, sams apis, client routes sams | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-sams-client-facing-apis/graph.json` |
| auth-adapter, django auth, api key, jwt, psycopg2, connection, credential | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-auth-adapter/graph.json` |
| cloudvc, version control, provider, filesystem, blob, cloud storage, vcs | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-cloudvc/graph.json` |
| config, environment, env var, settings, loader, keyvault, configuration | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-config-manager/graph.json` |
| identity, access, secrets, django secrets, user identity, permissions adapter | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-identity-access/graph.json` |
| prometheus, metrics, multiprocess, context, timer, gauge, counter | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-prometheus-metrics/graph.json` |
| queue, adaptor, redis, sqs, backend, message broker, factory | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-queue-adaptor/graph.json` |
| sams, aml, scoring, relevancy, trusted sources, algos, risk | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-sams-aml/graph.json` |
| tms-core, rules, rule repository, core module, shared models, domain logic | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-tms-core-module/graph.json` |
| tms-logging, logging, bootstrap, logger, sink, context, structured log | `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-tms-logging/graph.json` |

Whenever you query a graph.json, explicitly tell the user the full path you used, so they always know which graph was used.

**Note:** Each graph should only be queried for code questions about its corresponding source path.

**Worktrees:** Code under a git worktree (path contains `.claude/worktrees/<name>/...`) maps to the same graph as the main checkout. Ignore the `.claude/worktrees/<name>/` prefix and match on the trailing source path (e.g. `.../.claude/worktrees/feature-x/fcc-monorepo/apps/tms-backend` → `graphify-out-fcc-monorepo-tms-backend/graph.json`). Do not build a separate graph per worktree — always query the existing graph.json for the corresponding source path.

| Graph | Source path |
|---|---|
| `graphify-out-fcc-monorepo-tms-backend` | `fcc-monorepo/apps/tms-backend` |
| `graphify-out-fcc-monorepo-tms-client-routes` | `fcc-monorepo/apps/tms-client-routes` |
| `graphify-out-fcc-monorepo-tms-worker` | `fcc-monorepo/apps/tms-worker` |
| `graphify-out-fcc-monorepo-app-fcc-backend` | `fcc-monorepo/apps/fcc-backend` |
| `graphify-out-fcc-monorepo-app-fcc-frontend` | `fcc-monorepo/apps/fcc-frontend` |
| `graphify-out-fcc-monorepo-app-fcc-worker` | `fcc-monorepo/apps/fcc-worker` |
| `graphify-out-fcc-monorepo-app-sams-client-facing-apis` | `fcc-monorepo/apps/sams-client-facing-apis` |
| `graphify-out-fcc-monorepo-pkg-auth-adapter` | `fcc-monorepo/packages/auth-adapter` |
| `graphify-out-fcc-monorepo-pkg-cloudvc` | `fcc-monorepo/packages/cloudvc` |
| `graphify-out-fcc-monorepo-pkg-config-manager` | `fcc-monorepo/packages/config-manager` |
| `graphify-out-fcc-monorepo-pkg-identity-access` | `fcc-monorepo/packages/identity-access` |
| `graphify-out-fcc-monorepo-pkg-prometheus-metrics` | `fcc-monorepo/packages/prometheus-metrics` |
| `graphify-out-fcc-monorepo-pkg-queue-adaptor` | `fcc-monorepo/packages/QueueAdaptor` |
| `graphify-out-fcc-monorepo-pkg-sams-aml` | `fcc-monorepo/packages/sams-aml` |
| `graphify-out-fcc-monorepo-pkg-tms-core-module` | `fcc-monorepo/packages/tms-core-module` |
| `graphify-out-fcc-monorepo-pkg-tms-logging` | `fcc-monorepo/packages/tms-logging` |

All graph.json files are under `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/`.

## Available Graphs

**TMS Apps:**
- `graphify-out-fcc-monorepo-tms-backend/graph.json` — TMS Backend AML Compliance (6,445 nodes, 40,548 edges)
- `graphify-out-fcc-monorepo-tms-client-routes/graph.json` — TMS Client Routes (1,138 nodes, 2,901 edges)
- `graphify-out-fcc-monorepo-tms-worker/graph.json` — TMS Worker (627 nodes, 1,190 edges)

**FCC Apps:**
- `graphify-out-fcc-monorepo-app-fcc-backend/graph.json` — FCC Backend (6,313 nodes, 44,219 edges)
- `graphify-out-fcc-monorepo-app-fcc-frontend/graph.json` — FCC Frontend (514 nodes, 471 edges)
- `graphify-out-fcc-monorepo-app-fcc-worker/graph.json` — FCC Worker (614 nodes, 1,166 edges)
- `graphify-out-fcc-monorepo-app-sams-client-facing-apis/graph.json` — SAMS Client Facing APIs (691 nodes, 2,272 edges)

**Packages:**
- `graphify-out-fcc-monorepo-pkg-auth-adapter/graph.json` — Auth Adapter (153 nodes, 250 edges)
- `graphify-out-fcc-monorepo-pkg-cloudvc/graph.json` — CloudVC (60 nodes, 124 edges)
- `graphify-out-fcc-monorepo-pkg-config-manager/graph.json` — Config Manager (146 nodes, 301 edges)
- `graphify-out-fcc-monorepo-pkg-identity-access/graph.json` — Identity Access (178 nodes, 394 edges)
- `graphify-out-fcc-monorepo-pkg-prometheus-metrics/graph.json` — Prometheus Metrics (22 nodes, 13 edges)
- `graphify-out-fcc-monorepo-pkg-queue-adaptor/graph.json` — Queue Adaptor (135 nodes, 271 edges)
- `graphify-out-fcc-monorepo-pkg-sams-aml/graph.json` — SAMS AML (548 nodes, 1,080 edges)
- `graphify-out-fcc-monorepo-pkg-tms-core-module/graph.json` — TMS Core Module (1,312 nodes, 3,936 edges)
- `graphify-out-fcc-monorepo-pkg-tms-logging/graph.json` — TMS Logging (189 nodes, 384 edges)

## Cache Cleanup

```bash
rm -rf \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-tms-backend/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-tms-client-routes/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-tms-worker/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-fcc-backend/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-fcc-frontend/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-fcc-worker/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-app-sams-client-facing-apis/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-auth-adapter/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-cloudvc/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-config-manager/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-identity-access/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-prometheus-metrics/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-queue-adaptor/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-sams-aml/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-tms-core-module/cache \
  /home/mahakal/Desktop/src/github.com/work/solytics/graphify-out-repos/graphify-out-fcc-monorepo-pkg-tms-logging/cache
```

## Incremental Updates (graphify-build)

graphify-build is at `/home/mahakal/Desktop/src/github.com/work/solytics/graphify-build/`. Run all commands from `/home/mahakal/Desktop/src/github.com/work/solytics/` — works for any repo under solytics, not just tms.

```bash
cd /home/mahakal/Desktop/src/github.com/work/solytics

# TMS Apps
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/tms-backend --name fcc-monorepo-tms-backend
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/tms-client-routes --name fcc-monorepo-tms-client-routes
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/tms-worker --name fcc-monorepo-tms-worker

# FCC Apps
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/fcc-backend --name fcc-monorepo-app-fcc-backend
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/fcc-frontend --name fcc-monorepo-app-fcc-frontend
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/fcc-worker --name fcc-monorepo-app-fcc-worker
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/apps/sams-client-facing-apis --name fcc-monorepo-app-sams-client-facing-apis

# Packages
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/auth-adapter --name fcc-monorepo-pkg-auth-adapter
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/cloudvc --name fcc-monorepo-pkg-cloudvc
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/config-manager --name fcc-monorepo-pkg-config-manager
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/identity-access --name fcc-monorepo-pkg-identity-access
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/prometheus-metrics --name fcc-monorepo-pkg-prometheus-metrics
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/QueueAdaptor --name fcc-monorepo-pkg-queue-adaptor
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/sams-aml --name fcc-monorepo-pkg-sams-aml
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/tms-core-module --name fcc-monorepo-pkg-tms-core-module
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py update tms/fcc-monorepo/packages/tms-logging --name fcc-monorepo-pkg-tms-logging

# Any other repo under solytics — same pattern
# ~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py build <repo-path> --name <name>

# Query a graph (never read graph.json directly — files can be 50–500 MB)
~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py query graphify-out-repos/graphify-out-fcc-monorepo-tms-backend/graph.json "how does auth work?"

# Semantic labeling (requires ANTHROPIC_API_KEY)
ANTHROPIC_API_KEY=sk-ant-... ~/.local/share/uv/tools/graphifyy/bin/python graphify-build/cli.py label graphify-out-repos/graphify-out-fcc-monorepo-tms-backend
```
