"use client";

import { useState } from "react";
import type { PackageInfo } from "@/lib/getPackages";

const STATUS_STYLES: Record<PackageInfo["status"], { badge: string; label: string }> = {
  safe: { badge: "bg-emerald-900 text-emerald-300 border border-emerald-700", label: "Safe" },
  cooling: { badge: "bg-amber-900 text-amber-300 border border-amber-700", label: "Cooling" },
  unknown: { badge: "bg-gray-800 text-gray-400 border border-gray-700", label: "Unknown" },
};

type SortKey = "name" | "ageInDays" | "publishedAt" | "status";

export default function PackageTable({ packages }: { packages: PackageInfo[] }) {
  const [sort, setSort] = useState<{ key: SortKey; dir: 1 | -1 }>({ key: "name", dir: 1 });
  const [filter, setFilter] = useState("");

  const toggle = (key: SortKey) =>
    setSort((s) => ({ key, dir: s.key === key ? (-s.dir as 1 | -1) : 1 }));

  const sorted = [...packages]
    .filter((p) => p.name.toLowerCase().includes(filter.toLowerCase()))
    .sort((a, b) => {
      const av = a[sort.key] ?? "";
      const bv = b[sort.key] ?? "";
      return av < bv ? -sort.dir : av > bv ? sort.dir : 0;
    });

  return (
    <div className="space-y-3">
      <input
        type="text"
        placeholder="Filter packages…"
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        className="w-full max-w-sm bg-gray-900 border border-gray-700 rounded-md px-3 py-2 text-sm text-gray-100 placeholder-gray-600 focus:outline-none focus:ring-1 focus:ring-indigo-500"
      />

      <div className="overflow-x-auto rounded-lg border border-gray-800">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-800 bg-gray-900">
              <Th label="Package" sortKey="name" current={sort} onSort={toggle} />
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Requested</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Resolved</th>
              <Th label="Published" sortKey="publishedAt" current={sort} onSort={toggle} />
              <Th label="Age (days)" sortKey="ageInDays" current={sort} onSort={toggle} />
              <Th label="Status" sortKey="status" current={sort} onSort={toggle} />
            </tr>
          </thead>
          <tbody>
            {sorted.map((pkg, i) => (
              <tr
                key={pkg.name}
                className={`border-b border-gray-800 transition-colors hover:bg-gray-900/60 ${i % 2 === 0 ? "bg-gray-950" : "bg-gray-900/30"}`}
              >
                <td className="px-4 py-3 font-mono text-indigo-300 font-medium">{pkg.name}</td>
                <td className="px-4 py-3 font-mono text-gray-400">{pkg.requestedVersion}</td>
                <td className="px-4 py-3 font-mono text-gray-300">{pkg.resolvedVersion ?? "—"}</td>
                <td className="px-4 py-3 text-gray-300">
                  {pkg.publishedAt ? new Date(pkg.publishedAt).toLocaleString('en-AU', { timeZone: 'UTC' }) : "—"}
                </td>
                <td className="px-4 py-3 text-gray-300">
                  {pkg.ageInDays !== null ? (
                    <span className={pkg.ageInDays < 7 ? "text-amber-400 font-semibold" : "text-emerald-400"}>
                      {pkg.ageInDays}d
                    </span>
                  ) : (
                    <span className="text-gray-600">—</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${STATUS_STYLES[pkg.status].badge}`}>
                    {STATUS_STYLES[pkg.status].label}
                  </span>
                  {pkg.error && (
                    <span className="ml-2 text-xs text-red-400 font-mono" title={pkg.error}>
                      err
                    </span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {sorted.length === 0 && (
          <div className="text-center py-12 text-gray-600">No packages match your filter.</div>
        )}
      </div>

      <p className="text-xs text-gray-600">
        {sorted.length} of {packages.length} packages · cooldown threshold: 7 days
      </p>
    </div>
  );
}

function Th({
  label,
  sortKey,
  current,
  onSort,
}: {
  label: string;
  sortKey: SortKey;
  current: { key: SortKey; dir: 1 | -1 };
  onSort: (k: SortKey) => void;
}) {
  const active = current.key === sortKey;
  return (
    <th
      className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-300 transition-colors"
      onClick={() => onSort(sortKey)}
    >
      {label}
      <span className="ml-1 text-gray-600">{active ? (current.dir === 1 ? "↑" : "↓") : "↕"}</span>
    </th>
  );
}
