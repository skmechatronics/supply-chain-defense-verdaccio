import { readFileSync } from "fs";
import { join } from "path";
import { differenceInDays } from "date-fns";

export const REGISTRY = "https://vdcd-app-ause.azurewebsites.net";
const NPM_REGISTRY = "https://registry.npmjs.org";
const MIN_AGE_DAYS = 7;

export interface PackageInfo {
  name: string;
  requestedVersion: string;
  resolvedVersion: string | null;
  publishedAt: string | null;
  ageInDays: number | null;
  status: "safe" | "cooling" | "unknown";
  error?: string;
}

export interface PackagesPayload {
  registry: string;
  npmrc: string;
  fetchedAt: string;
  packages: PackageInfo[];
}

function encodePackageName(name: string): string {
  return name.startsWith("@")
    ? `@${encodeURIComponent(name.slice(1))}`
    : encodeURIComponent(name);
}

async function fetchPackageMeta(
  name: string,
  requestedVersion: string,
  resolvedVersion: string
): Promise<PackageInfo> {
  try {
    const res = await fetch(`${NPM_REGISTRY}/${encodePackageName(name)}`, {
      cache: "no-store",
    });

    if (!res.ok) {
      return { name, requestedVersion, resolvedVersion, publishedAt: null, ageInDays: null, status: "unknown", error: `HTTP ${res.status}` };
    }

    const meta = await res.json();
    const publishedAt: string | undefined = meta.time?.[resolvedVersion];

    if (!publishedAt) {
      return { name, requestedVersion, resolvedVersion, publishedAt: null, ageInDays: null, status: "unknown" };
    }

    const ageInDays = differenceInDays(new Date(), new Date(publishedAt));
    const status: PackageInfo["status"] = ageInDays >= MIN_AGE_DAYS ? "safe" : "cooling";

    return { name, requestedVersion, resolvedVersion, publishedAt, ageInDays, status };
  } catch (err) {
    const message = err instanceof Error ? err.message : "unknown error";
    return { name, requestedVersion, resolvedVersion, publishedAt: null, ageInDays: null, status: "unknown", error: message };
  }
}

export async function getPackages(): Promise<PackagesPayload> {
  const lock = JSON.parse(readFileSync(join(process.cwd(), "package-lock.json"), "utf-8"));

  const root = lock.packages[""];
  const directDeps: Record<string, string> = {
    ...root.dependencies,
    ...root.devDependencies,
  };

  const packages = await Promise.all(
    Object.entries(directDeps).map(([name, requestedVersion]) => {
      const entry = lock.packages[`node_modules/${name}`];
      if (!entry) {
        return Promise.resolve<PackageInfo>({
          name,
          requestedVersion,
          resolvedVersion: null,
          publishedAt: null,
          ageInDays: null,
          status: "unknown",
          error: "not in lock file",
        });
      }
      return fetchPackageMeta(name, requestedVersion, entry.version);
    })
  );

  return {
    registry: REGISTRY,
    npmrc: `registry=${REGISTRY}`,
    fetchedAt: new Date().toISOString(),
    packages,
  };
}
