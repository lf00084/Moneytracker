import { balance } from "./balance.ts"
import { job } from "./job.ts"
import { manual } from "./manual.ts"
import type { Json, SourceType } from "./types.ts"

export type { Ctx, Entry, Field, Json, SourceType } from "./types.ts"

const registry: Record<string, SourceType> = { manual, job, balance }

export const typeList = Object.values(registry)

export const typeOf = (key: string | null | undefined): SourceType => (key && Object.hasOwn(registry, key) ? registry[key]! : manual)

export const extKey = (sourceId: string, day: string) => `${sourceId}:${day}`

export const parseJson = (s: string | null | undefined): Json => {
try {
const v = JSON.parse(s || "{}")
return v && typeof v === "object" && !Array.isArray(v) ? (v as Json) : {}
} catch {
return {}
}
}
