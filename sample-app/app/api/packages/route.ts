import { NextResponse } from "next/server";
import { getPackages } from "@/lib/getPackages";

export async function GET() {
  const data = await getPackages();
  return NextResponse.json(data);
}
