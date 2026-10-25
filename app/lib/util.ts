export type Json = Record<string, number | string>

export const id = () => crypto.randomUUID()

export const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max)

export const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []))

export const parseJson = (s: string | null | undefined): Json => {
	try {
		const v = JSON.parse(s || "{}")
		return v && typeof v === "object" && !Array.isArray(v) ? (v as Json) : {}
	} catch {
		return {}
	}
}

export const extKey = (sourceId: string, day: string) => `${sourceId}:${day}`

export const isFixed = (type: string) => type === "job" || type === "fixed"
