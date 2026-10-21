export const toMinor = (s: unknown) => {
	const n = parseFloat(String(s ?? "").replace(",", "."));
	return Number.isFinite(n) && n > 0 && n <= 1e9 ? Math.round(n * 100) : 0;
};
export const fmt = (minor: number) => {
	const v = minor / 100;
	return v.toLocaleString("en-US", { maximumFractionDigits: 2, minimumFractionDigits: Number.isInteger(v) ? 0 : 2 });
};
export const toSigned = (s: unknown) => {
const raw = String(s ?? "").trim();
if (!raw) return null;
const n = parseFloat(raw.replace(",", "."));
return Number.isFinite(n) && Math.abs(n) <= 1e9 ? Math.round(n * 100) : null;
};
