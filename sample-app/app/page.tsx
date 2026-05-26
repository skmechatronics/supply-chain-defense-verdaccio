import PackageTable from "@/components/PackageTable";
import { getPackages } from "@/lib/getPackages";

export const dynamic = "force-dynamic";

export default async function Home() {
  const data = await getPackages();

  const safe = data.packages.filter((p) => p.status === "safe").length;
  const cooling = data.packages.filter((p) => p.status === "cooling").length;
  const unknown = data.packages.filter((p) => p.status === "unknown").length;

  return (
    <main className="max-w-7xl mx-auto px-6 py-10 space-y-8">
      {/* Header */}
      <div className="space-y-1">
        <h1 className="text-2xl font-semibold tracking-tight text-white">
          Supply Chain Dashboard
        </h1>
        <p className="text-sm text-gray-400">
          Packages resolved via{" "}
          <span className="font-mono text-indigo-400">{data.registry}</span>
          {" · "}fetched at{" "}
          <span className="font-mono text-gray-300">
            {new Date(data.fetchedAt).toLocaleString('en-AU', { timeZone: 'UTC' })}
          </span>
        </p>
      </div>

      {/* .npmrc pill */}
      <div className="flex items-center gap-3 bg-gray-900 border border-gray-800 rounded-lg px-4 py-3 w-fit">
        <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">.npmrc</span>
        <code className="text-sm text-emerald-400 font-mono">{data.npmrc}</code>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-3 gap-4">
        <StatCard label="Safe" value={safe} color="text-emerald-400" dot="bg-emerald-400" />
        <StatCard label="Cooling down" value={cooling} color="text-amber-400" dot="bg-amber-400" />
        <StatCard label="Unknown" value={unknown} color="text-gray-400" dot="bg-gray-500" />
      </div>

      {/* Table */}
      <PackageTable packages={data.packages} />
    </main>
  );
}

function StatCard({ label, value, color, dot }: { label: string; value: number; color: string; dot: string }) {
  return (
    <div className="bg-gray-900 border border-gray-800 rounded-lg px-5 py-4 flex items-center gap-4">
      <span className={`w-2.5 h-2.5 rounded-full flex-shrink-0 ${dot}`} />
      <div>
        <p className="text-xs text-gray-500 uppercase tracking-wider">{label}</p>
        <p className={`text-2xl font-semibold mt-0.5 ${color}`}>{value}</p>
      </div>
    </div>
  );
}
