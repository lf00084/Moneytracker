/** Money is stored as integer minor units (MAD * 100). */
export const toMinor = (s: unknown) => {
	const n = parseFloat(String(s ?? "").replace(",", "."));
	return Number.isFinite(n) && n > 0 && n <= 1e9 ? Math.round(n * 100) : 0;
};

export const fmt = (minor: number) => {
	const v = minor / 100;
	return v.toLocaleString("en-US", { maximumFractionDigits: 2, minimumFractionDigits: Number.isInteger(v) ? 0 : 2 });
};
