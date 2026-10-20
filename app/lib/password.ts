// PBKDF2-SHA256 through Web Crypto. Cloudflare Workers caps PBKDF2 at 100,000 iterations.
const ITERATIONS = 100_000;
const enc = new TextEncoder();

const b64 = (b: ArrayBuffer | Uint8Array) => btoa(String.fromCharCode(...new Uint8Array(b)));
const unb64 = (s: string) => Uint8Array.from(atob(s), (ch) => ch.charCodeAt(0));

async function derive(password: string, salt: Uint8Array, iterations: number) {
	const key = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"]);
	return crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt, iterations }, key, 256);
}

export async function hashPassword(password: string): Promise<string> {
	const salt = crypto.getRandomValues(new Uint8Array(16));
	const bits = await derive(password, salt, ITERATIONS);
	return `pbkdf2$${ITERATIONS}$${b64(salt)}$${b64(bits)}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
	const [scheme, iter, salt, hash] = stored.split("$");
	if (scheme !== "pbkdf2" || !iter || !salt || !hash) return false;
	const bits = new Uint8Array(await derive(password, unb64(salt), Number(iter)));
	const want = unb64(hash);
	if (bits.length !== want.length) return false;
	let diff = 0;
	for (let i = 0; i < bits.length; i++) diff |= bits[i]! ^ want[i]!;
	return diff === 0;
}

/** Spend the same time on unknown emails so response time does not reveal which emails exist. */
export async function fakeVerify(password: string) {
	await derive(password, new Uint8Array(16), ITERATIONS);
}
