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
