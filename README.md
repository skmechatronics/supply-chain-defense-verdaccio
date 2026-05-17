# supply-chain-defense-verdaccio

A time-gated npm registry using [Verdaccio](https://verdaccio.org/) as a supply chain defence mechanism. Packages available to consumers are always behind a configurable age cutoff — no version published within the last N days is visible as `latest`. This buys time to detect malicious or compromised packages before they reach developer machines.

## Concept

The core idea is a **cooldown window**: the registry proxies npm but only surfaces package versions that are at least `minAgeDays` old. A package published yesterday is invisible until the window expires.

- **Default**: 7-day cooldown
- **Override**: explicitly bypassed when a team needs a bleeding-edge dependency
- **Visibility**: a `/packages` endpoint on the demo app shows what resolved and when it was published

## Repository layout

```
local-registry/
  conf/
    config-template.yaml   # verdaccio config with {{MIN_AGE_DAYS}} placeholder
    config.yaml            # generated at build time — do not edit directly
  plugins/                 # @verdaccio/package-filter and its dependencies
  storage/                 # verdaccio package metadata cache
  Dockerfile               # verdaccio 6.6.0 + package-filter 13.0.1
  build-docker-verdaccio.ps1   # build image, inject cooldown, start container
  check-package-versions.ps1   # compare verdaccio vs npm to verify filtering
  build-and-check.ps1          # orchestrator: runs both scripts end-to-end
infra-azure/               # (coming) Terraform for Azure App Service deployment
```

## Local development

### Prerequisites

- Docker Desktop running
- PowerShell 7+

### Run with default 7-day cooldown

```powershell
.\local-registry\build-and-check.ps1
```

### Run with a custom cooldown

```powershell
.\local-registry\build-and-check.ps1 -MinAgeDays 14
```

### Check specific packages

```powershell
.\local-registry\build-and-check.ps1 -MinAgeDays 7 -Packages axios,react,lodash
```

The orchestrator:
1. Generates `config.yaml` from the template, injecting `MinAgeDays`
2. Removes any existing `verdaccio-dev` container
3. Builds the `verdaccio-cooldown:0.1.0` image
4. Starts the container on `http://localhost:4873`
5. Queries both npm and verdaccio for each package and prints a comparison table

### Example output

```
PACKAGE              NPM LATEST      NPM AGE    VERDACCIO       VERD AGE   STATUS
------------------------------------------------------------------------------------------
axios                1.9.0           2.1        1.8.4           18.3       FILTERED
@types/node          22.15.21        0.3        22.15.17        8.4        FILTERED
eslint               9.28.0          5.2        9.27.0          12.1       FILTERED
vite                 6.3.5           3.8        6.3.4           10.6       FILTERED
typescript           5.8.3           42.1       5.8.3           42.1       not filtered
```

Green rows confirm the filter is active. Yellow rows mean the npm latest is already old enough to pass through.

## How it works

### Dockerfile

```dockerfile
FROM verdaccio/verdaccio:6.6.0
USER root
RUN npm install --prefix /verdaccio/plugins @verdaccio/package-filter@13.0.1
USER verdaccio
```

The plugin is baked into the image so no volume mount or runtime install is needed.

### Config template

```yaml
filters:
  '@verdaccio/package-filter':
    minAgeDays: {{MIN_AGE_DAYS}}
```

`build-docker-verdaccio.ps1` replaces `{{MIN_AGE_DAYS}}` before starting the container. The generated `config.yaml` is bind-mounted into the container so it can be changed without a rebuild.

## Roadmap

| Phase | Description | Status |
|---|---|---|
| Local dev | Time-gated registry with verification scripts | Done |
| Demo app | Express app with `/packages` endpoint, pointed at the local registry | Planned |
| Azure infra | Terraform: App Service + Azure Files mount | Planned |
| Override mechanism | API or config flag to bypass the cooldown for a named package | Planned |
| AWS | Equivalent Terraform for AWS (App Runner or ECS) | Future |
