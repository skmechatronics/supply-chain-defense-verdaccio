# sample-app

A Next.js dashboard that visualises the cooldown status of every direct dependency in its own `package.json` / `package-lock.json`.

It is intentionally a real application that installs packages through the Verdaccio registry, so it doubles as a live demo of the cooldown filter in action.

## What it shows

| Column | Source |
|---|---|
| Package / Requested | `package-lock.json` root entry |
| Resolved | Exact version from lock file |
| Published | Fetched from `registry.npmjs.org` |
| Age (days) | Calculated from publish date |
| Status | `cooling` < 7 days old · `safe` ≥ 7 days |

## How it works

1. `lib/getPackages.ts` reads `package-lock.json` to get resolved versions for all direct dependencies — no network call needed.
2. For each package it fetches the full packument from `registry.npmjs.org` to retrieve the publish timestamp for that exact version.
3. Age and status are calculated locally using the same 7-day threshold as the Verdaccio cooldown filter.

The `.npmrc` shown in the header is what you would set in a consuming project to route installs through Verdaccio.

## Running locally

```bash
# Point npm at your local or Azure-hosted Verdaccio registry
echo "registry=http://localhost:4873" > .npmrc

npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Environment

The Verdaccio registry URL is hardcoded in `lib/getPackages.ts` (`REGISTRY`). Update it to point at your deployment before running against a remote registry.

## Stack

- Next.js 16 (App Router)
- Tailwind CSS
- `date-fns` for age calculation
