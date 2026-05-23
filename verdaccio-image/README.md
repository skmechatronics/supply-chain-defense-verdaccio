# verdaccio-image

Production Docker image for the Verdaccio cooldown registry.

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
docker build --build-arg MIN_AGE_DAYS=7 -t verdaccio-cooldown:0.1.0 .
```

To change the cooldown window, rebuild with a new value and push a new tag.

## Security

The registry has no authentication — access is `$all` (read-only proxy, no publish). Security is enforced at the network level: the App Service should be restricted to the client's VNet or approved IP ranges. Do not expose the registry publicly.
