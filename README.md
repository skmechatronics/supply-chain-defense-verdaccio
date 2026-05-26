# supply-chain-defense-verdaccio

A time-gated npm registry using [Verdaccio](https://verdaccio.org/) as a supply chain defence mechanism. Packages available to consumers are always behind a configurable age cutoff — no version published within the last N days is visible as `latest`. This buys time to detect malicious or compromised packages before they reach developer machines.

## Concept

The core idea is a **cooldown window**: the registry proxies npm but only surfaces package versions that are at least `minAgeDays` old. A package published yesterday is invisible until the window expires.

- **Default**: 7-day cooldown
- **Override**: explicitly bypassed when a team needs a bleeding-edge dependency
- **Visibility**: a `/packages` endpoint on the demo app shows what resolved and when it was published

## Repository layout

```
verdaccio-image/   # Dockerfile + custom cooldown filter plugin (shared by local and Azure)
local-registry/    # Scripts to build and run the registry locally
infra-azure/       # OpenTofu for Azure hosting (App Service)
sample-app/        # Next.js demo app pointed at the registry
```

- [Local registry](local-registry/README.md) — run the time-gated registry locally
- [Azure infrastructure](infra-azure/README.md) — deploy to Azure
- [Vetting checklist](VETTING.md) — trust boundary and audit trail for Verdaccio and its plugins

## Known limitations

### The filter protects resolution, not locked installs

The cooldown filter intercepts metadata requests (`GET /<package>`). When a `package-lock.json` already exists, npm skips metadata resolution and downloads tarballs directly from the `resolved` URLs in the lock file — the filter never runs. This is correct behaviour: `package-lock.json` exists precisely to give you reproducible, deterministic installs.

**The filter's job is to govern what goes INTO the lock file**, not to re-check it on every restore. Protection happens when a developer runs `npm install <new-package>`, `npm update`, or generates a fresh lock file. Once a version is committed to the lock file it has already passed through the registry — that is the point at which the cooldown window applies.

To protect against restoring a lock file that was committed before a block was added, add a CI step that parses `package-lock.json` and fails the build if any resolved version matches an entry in `PACKAGE_BLOCKS`. This is a client-side complement to the server-side registry filter.

## Roadmap

| Phase | Description | Status |
|---|---|---|
| Local dev | Time-gated registry with verification scripts | Done |
| Demo app | Express app with `/packages` endpoint, pointed at the local registry | Planned |
| Azure infra | OpenTofu: App Service + Azure Files mount | Planned |
| Override mechanism | `PACKAGE_OVERRIDES` and `PACKAGE_BLOCKS` env vars on the registry | Done |
| AWS | Equivalent Terraform for AWS (App Runner or ECS) | Future |
