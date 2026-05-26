import { readFileSync } from "fs";
import { join } from "path";
import { differenceInDays } from "date-fns";

export const REGISTRY = "https://vdcd-app-ause.azurewebsites.net";

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

async function fetchPackageMeta(name: string, version: string): Promise<PackageInfo> {
  try {
    const res = await fetch(`${REGISTRY}/${encodeURIComponent(name)}`, {
      cache: 'no-store',
    });

    if (!res.ok) {
      return { name, requestedVersion: version, resolvedVersion: null, publishedAt: null, ageInDays: null, status: "unknown", error: `HTTP ${res.status}` };
    }

    const meta = await res.json();
    const resolvedVersion: string = meta["dist-tags"]?.latest ?? version.replace(/^\^|~/, "");
    const publishedAt: string | undefined = meta.time?.[resolvedVersion];

    if (!publishedAt) {
      return { name, requestedVersion: version, resolvedVersion, publishedAt: null, ageInDays: null, status: "unknown" };
    }

    const ageInDays = differenceInDays(new Date(), new Date(publishedAt));
    const status: PackageInfo["status"] = ageInDays >= 7 ? "safe" : "cooling";

    return { name, requestedVersion: version, resolvedVersion, publishedAt, ageInDays, status };
  } catch (err) {
    const message = err instanceof Error ? err.message : "unknown error";
    return { name, requestedVersion: version, resolvedVersion: null, publishedAt: null, ageInDays: null, status: "unknown", error: message };
  }
}

export async function getPackages(): Promise<PackagesPayload> {
  const pkgPath = join(process.cwd(), "package.json");
  const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));

  const deps: Record<string, string> = {
    ...pkg.dependencies,
    ...pkg.devDependencies,
  };

  const packages = await Promise.all(
    Object.entries(deps).map(([name, version]) => fetchPackageMeta(name, version as string))
  );

  return {
    registry: REGISTRY,
    npmrc: `registry=${REGISTRY}`,
    fetchedAt: new Date().toISOString(),
    packages,
  };
}
