const parse = (s: unknown) => parseFloat(String(s ?? "").replace(",", "."))

export const toMinor = (s: unknown) => {
	const n = parse(s)
	return Number.isFinite(n) && n > 0 && n <= 1e9 ? Math.round(n * 100) : 0
}

export const toSigned = (s: unknown) => {
	if (!String(s ?? "").trim()) return null
	const n = parse(s)
	return Number.isFinite(n) && Math.abs(n) <= 1e9 ? Math.round(n * 100) : null
}

export const fmt = (minor: number) => {
	const v = minor / 100
	return v.toLocaleString("en-US", { maximumFractionDigits: 2, minimumFractionDigits: Number.isInteger(v) ? 0 : 2 })
}

export const plain = (minor: number) => (minor / 100).toFixed(2).replace(/\.00$/, "")
