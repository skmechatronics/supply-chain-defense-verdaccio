# Vetting Checklist

This project uses Verdaccio and third-party plugins to defend against supply chain attacks. That creates an obvious irony: the defense tooling is itself a supply chain dependency. This document records what was checked and when, so the trust decision is deliberate rather than assumed.

## Disclaimer

This pattern **shifts** the trust boundary — it does not eliminate it. Instead of implicitly trusting the entire npm registry, you are explicitly trusting:

- Verdaccio core
- Any Verdaccio plugins in use
- The Docker base image
- This repository's own plugin code

A compromised Verdaccio or plugin would have the same blast radius as a compromised npm package. Vet accordingly.

---

## Verdaccio Core

| Check | What to verify |
|---|---|
| Source | [github.com/verdaccio/verdaccio](https://github.com/verdaccio/verdaccio) — confirm it is the canonical repo |
| Maintainers | Review current maintainer list; check for recent ownership changes |
| Release cadence | Is the project actively maintained? Stale projects accumulate unpatched CVEs |
| CVEs | Search [osv.dev](https://osv.dev) and GitHub Security Advisories for the pinned version |
| Docker image | Pin to a specific image digest (`@sha256:...`), not a mutable tag like `latest` or `6.x` |
| Dockerfile review | Read the official Dockerfile — confirm no unexpected network calls or bundled scripts |

**Pinned version:** `6.6.0`
**Pinned digest:** `sha256:722734053e72f998cca9a6337285ea8236b0a8615cff8f6c8c49698e026e7054`
**Last reviewed:** _fill in_

---

## Verdaccio Plugins

Plugins run inside the Verdaccio process with full access to the request/response cycle. They are the highest-risk dependency in this stack.

### General checks (apply to every plugin)

| Check | What to verify |
|---|---|
| Source | Confirm the npm package resolves to the expected GitHub repo — look for publish provenance |
| Maintainer | Single maintainer plugins are higher risk; check for recent maintainer changes |
| Download count | Low download counts mean less community scrutiny |
| Last published | Abandoned plugins do not receive security fixes |
| Source review | Read the full source — auth plugins are usually small enough to audit completely |
| Dependencies | Run `npm ls` on the plugin; each transitive dep is also in scope |
| Pinned version | Lock to an exact version in `package.json`; review before any upgrade |

### `@verdaccio/package-filter` (cooldown plugin — this repo)

This plugin is maintained in this repository. The same supply chain risks apply to this code as to any other dependency a consumer of this pattern installs.

**Pinned version:** `13.0.1`
**Last reviewed:** _fill in_

### Azure AD / OIDC auth plugin _(planned)_

No plugin selected yet. Before selecting one:

- Prefer a plugin that uses standard OIDC flows over custom Azure AD-specific code
- Verify the plugin does not cache or log tokens
- Review token validation logic — confirm it checks issuer, audience, and expiry
- Check whether the plugin has had a security audit

**Selected plugin:** _fill in_
**Last reviewed:** _fill in_

---

## Review cadence

- Re-check CVEs for pinned versions quarterly
- Review plugin source again before any version upgrade
- Re-verify Docker image digest after any base image update
