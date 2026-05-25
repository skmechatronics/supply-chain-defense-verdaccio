# verdaccio-image

Production Docker image for the Verdaccio cooldown registry. Used for both local development and Azure deployment — there is one image, not two.

## Base image

```
verdaccio/verdaccio:6.6.0@sha256:722734053e72f998cca9a6337285ea8236b0a8615cff8f6c8c49698e026e7054
```

The base image is pinned by digest rather than tag. A tag can be overwritten on Docker Hub; a digest cannot — this ensures the build is reproducible and cannot be silently replaced with a different image. When upgrading Verdaccio, pull the new tag and update the digest in the Dockerfile:

```powershell
docker pull verdaccio/verdaccio:<new-tag>
docker inspect --format='{{index .RepoDigests 0}}' verdaccio/verdaccio:<new-tag>
```

## Build

`minAgeDays` is baked into the image at build time via the `MIN_AGE_DAYS` build argument (default: 7):

```powershell
docker build --build-arg MIN_AGE_DAYS=7 -t verdaccio-cooldown:local .
```

To change the cooldown window, rebuild with a new value and push a new tag.

## Plugin — verdaccio-cooldown-filter

The cooldown filter is a custom Verdaccio filter plugin at `plugins/verdaccio-cooldown-filter/`. It is copied directly into the image at build time — no npm install from the public registry.

### How it works

On every metadata request (`GET /<package>`), the plugin:

1. Removes any version published within the last `minAgeDays` days from the version list
2. Updates `dist-tags.latest` to point to the newest surviving version
3. Removes any dist-tags that pointed to filtered versions

The filter mutates `packageInfo` in place before Verdaccio sends the response — Verdaccio v6 ignores the callback's second argument.

### Runtime env vars

| Variable | Format | Effect |
|---|---|---|
| `PACKAGE_BLOCKS` | `pkg@version,pkg@version` | Blocks specific versions regardless of age |
| `PACKAGE_OVERRIDES` | `pkg@version,pkg@version` | Allows specific versions through the age gate |

Both default to empty (no blocks, no overrides).

### Example

```powershell
docker run -e "PACKAGE_BLOCKS=next@15.3.2" -e "PACKAGE_OVERRIDES=next@16.2.6" verdaccio-cooldown:local
```

At startup the plugin logs:

```
cooldown-filter: initialized (minAgeDays=7, overrides=[ 'next@16.2.6' ], blocks=[ 'next@15.3.2' ])
```

## Security

The registry has no authentication — access is `$all` (read-only proxy, no publish). Security is enforced at the network level: the App Service should be restricted to the client's VNet or approved IP ranges. Do not expose the registry publicly.
