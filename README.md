# supply-chain-defense-verdaccio

A time-gated npm registry using [Verdaccio](https://verdaccio.org/) as a supply chain defence mechanism. Packages available to consumers are always behind a configurable age cutoff — no version published within the last N days is visible as `latest`. This buys time to detect malicious or compromised packages before they reach developer machines.

## Concept

The core idea is a **cooldown window**: the registry proxies npm but only surfaces package versions that are at least `minAgeDays` old. A package published yesterday is invisible until the window expires.

- **Default**: 7-day cooldown
- **Override**: explicitly bypassed when a team needs a bleeding-edge dependency
- **Visibility**: a `/packages` endpoint on the demo app shows what resolved and when it was published

## Repository layout

```
local-registry/    # Docker-based local registry for development and testing
infra-azure/       # Terraform for Azure hosting (App Service + Azure Files)
```

- [Local registry](local-registry/README.md) — run the time-gated registry locally
- [Azure infrastructure](infra-azure/README.md) — deploy to Azure

## Roadmap

| Phase | Description | Status |
|---|---|---|
| Local dev | Time-gated registry with verification scripts | Done |
| Demo app | Express app with `/packages` endpoint, pointed at the local registry | Planned |
| Azure infra | OpenTofu: App Service + Azure Files mount | Planned |
| Override mechanism | API or config flag to bypass the cooldown for a named package | Planned |
| AWS | Equivalent Terraform for AWS (App Runner or ECS) | Future |
