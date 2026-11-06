// USDT amounts are tiny by nature: a Predict or Funding wallet can hold
// 0.000000001 USDT and Binance reports it with full precision. Cent-based
// integers would round that to zero, so balances are also kept as decimal
// strings and added with BigInt at 1e-12 to stay exact.

const SCALE = 12

const num = (v: unknown) => {
	const n = Number(String(v ?? "").trim().replace(",", "."))
	return Number.isFinite(n) ? n : 0
}

const scaled = (v: unknown): bigint => {
	const n = num(v)
	if (!n) return 0n
	const [i, f] = Math.abs(n).toFixed(SCALE).split(".")
	const b = BigInt(`${i || "0"}${f || ""}`)
	return n < 0 ? -b : b
}

const fromScaled = (v: bigint) => {
	const neg = v < 0n
	const s = (neg ? -v : v).toString().padStart(SCALE + 1, "0")
	const i = s.slice(0, -SCALE)
	const f = s.slice(-SCALE).replace(/0+$/, "")
	return `${neg ? "-" : ""}${i}${f ? `.${f}` : ""}`
}

// Plain decimal string, never in exponent form, safe to store in a column.
export const normUsdt = (v: unknown) => fromScaled(scaled(v))

export const sumUsdt = (...vals: unknown[]) => fromScaled(vals.reduce<bigint>((a, v) => a + scaled(v), 0n))

export const usdtNum = (v: unknown) => num(v)

// Display: keeps every decimal Binance sent (so 0.000000001 shows as such),
// trims trailing zeros, and groups the integer part. Strings are formatted
// from their own digits so 1234567.891 never turns into 1234567.8910000001.
export function showUsdt(v: unknown): string {
	const raw = typeof v === "string" ? v.trim().replace(",", ".") : String(v ?? "")
	const n = num(raw)
	if (!n) return "0"
	let s = /[eE]/.test(raw) ? n.toFixed(SCALE) : raw
	let neg = s.startsWith("-")
	if (neg) s = s.slice(1)
	if (!/^\d*\.?\d*$/.test(s) || !s) {
		s = Math.abs(n).toFixed(SCALE)
		neg = n < 0
	}
	const [i0, f0] = s.split(".")
	const i = (i0 || "0").replace(/^0+(?=\d)/, "")
	const f = (f0 || "").replace(/0+$/, "")
	const grouped = i.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
	const out = `${neg ? "-" : ""}${grouped}${f ? `.${f}` : ""}`
	return out === "0" || out === "-0" ? "0" : out
}

// ---- USDT → MAD -----------------------------------------------------------
// rate is stored in minor units (1048 = 10.48 MAD per USDT). The product is
// kept at 1e-10 MAD so even 0.000000001 USDT leaves a visible trace instead of
// being rounded to zero at the cent boundary.

const MAD_DECIMALS = 10

// Decimal string of a value scaled by `decimals` (e.g. 12 → 1e-12 units).
export const parseScaled = (v: unknown, decimals: number): bigint => {
	const n = num(v)
	if (!n) return 0n
	const [i, f] = Math.abs(n).toFixed(decimals).split(".")
	const b = BigInt(`${i || "0"}${f || ""}`)
	return n < 0 ? -b : b
}

export const formatScaled = (v: bigint, decimals: number): string => {
	const neg = v < 0n
	const s = (neg ? -v : v).toString().padStart(decimals + 1, "0")
	const i = s.slice(0, decimals ? -decimals : undefined) || "0"
	const f = decimals ? s.slice(-decimals).replace(/0+$/, "") : ""
	return `${neg ? "-" : ""}${i}${f ? `.${f}` : ""}`
}

// MAD value of a USDT amount, as a decimal string with up to 10 decimals.
export const madFromUsdt = (usdt: unknown, rateMinor: number): string => {
	// usdt×1e12 × rate(MAD×100) == MAD×1e14, so dividing by 1e4 leaves MAD at
	// 1e-10 precision: 0.000000001 USDT at 10.48 MAD stays 0.0000000104 MAD
	// instead of disappearing at the cent boundary.
	const scaled = parseScaled(usdt, SCALE) * BigInt(Math.max(0, Math.round(rateMinor)))
	return formatScaled(scaled / 10000n, MAD_DECIMALS)
}

// Adding MAD decimal strings (any precision) without float drift.
export const addMad = (...vals: string[]): string => {
	const sum = vals.reduce((a, v) => a + parseScaled(v, MAD_DECIMALS), 0n)
	return formatScaled(sum, MAD_DECIMALS)
}

// Display for a MAD decimal string: thousands grouped and two decimals by
// default. `dp` up to 10 keeps the sub-cent part (used under the balance to
// show what the USDT wallet is worth); a value that is real but rounds away
// says "< 0.000001" instead of pretending it is zero.
export function showMad(text: string | number, dp?: number): string {
	const v = typeof text === "number" ? parseScaled(text, 2) * 100000000n : parseScaled(text, MAD_DECIMALS)
	const neg = v < 0n
	const abs = neg ? -v : v
	// Anything worth a cent or more reads as money; a smaller amount keeps its
	// decimals so a tiny USDT balance never shows up as a flat zero.
	// Two decimals unless that would hide real money: below one cent, or when the
	// fraction is so small it rounds away at the cent, keep more places so the
	// USDT part still moves the number the user reads.
	const cent = 10n ** BigInt(MAD_DECIMALS - 2)
	const places = dp ?? (abs >= cent ? (abs % cent > 0n && abs % cent < cent / 2n ? 4 : 2) : 6)
	const f = 10n ** BigInt(MAD_DECIMALS - places)
	const q = (abs + f / 2n) / f
	if (q === 0n && abs > 0n) return `< ${(1 / 10 ** places).toFixed(places)}`
	const s = q.toString().padStart(places + 1, "0")
	const i = s.slice(0, -places).replace(/\B(?=(\d{3})+(?!\d))/g, ",")
	const raw = s.slice(-places)
	const frac = places > 2 ? raw.replace(/0+$/, "").padEnd(2, "0") : raw
	return `${neg ? "-" : ""}${i || "0"}${frac ? `.${frac}` : ""}`
}

// Integer minor units (cents) -> MAD decimal string.
export const minorToMad = (minor: number): string => formatScaled(BigInt(Math.round(minor || 0)), 2)
