# local-registry

Runs Verdaccio locally as a time-gated npm proxy. Packages are filtered so that only versions at least `minAgeDays` old are visible as `latest`.

## Prerequisites

- Docker Desktop running
- PowerShell 7+

## Usage

### Run with default 7-day cooldown

```powershell
.\build-and-check.ps1
```

### Run with a custom cooldown

```powershell
.\build-and-check.ps1 -MinAgeDays 14
```

### Check specific packages

```powershell
.\build-and-check.ps1 -MinAgeDays 7 -Packages axios,react,lodash
```

The orchestrator:
1. Generates `conf/config.yaml` from the template, injecting `MinAgeDays`
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

`build-docker-verdaccio.ps1` replaces `{{MIN_AGE_DAYS}}` before starting the container. The generated `conf/config.yaml` is bind-mounted into the container so it can be changed without a rebuild.

## File layout

```
conf/
  config-template.yaml   # verdaccio config with {{MIN_AGE_DAYS}} placeholder
  config.yaml            # generated at build time — do not edit directly
plugins/
  package.json           # declares @verdaccio/package-filter dependency
storage/                 # verdaccio package metadata cache (gitignored, created at runtime)
Dockerfile
build-docker-verdaccio.ps1   # build image, inject cooldown, start container
check-package-versions.ps1   # compare verdaccio vs npm to verify filtering
build-and-check.ps1          # orchestrator: runs both scripts end-to-end
```
