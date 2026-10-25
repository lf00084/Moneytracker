import { env } from "../env.ts"

const ITERATIONS = 100_000
const enc = new TextEncoder()
const dec = new TextDecoder()

const b64 = (b: ArrayBuffer | Uint8Array) => btoa(String.fromCharCode(...new Uint8Array(b)))
const unb64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))

async function derive(password: string, salt: Uint8Array, iterations: number) {
	const key = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"])
	return crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt, iterations }, key, 256)
}

export async function hashPassword(password: string) {
	const salt = crypto.getRandomValues(new Uint8Array(16))
	return `pbkdf2$${ITERATIONS}$${b64(salt)}$${b64(await derive(password, salt, ITERATIONS))}`
}

export async function verifyPassword(password: string, stored: string) {
	const [scheme, iter, salt, hash] = stored.split("$")
	if (scheme !== "pbkdf2" || !iter || !salt || !hash) return false
	const bits = new Uint8Array(await derive(password, unb64(salt), Number(iter)))
	const want = unb64(hash)
	if (bits.length !== want.length) return false
	let diff = 0
	for (let i = 0; i < bits.length; i++) diff |= bits[i]! ^ want[i]!
	return diff === 0
}

export async function fakeVerify(password: string) {
	await derive(password, new Uint8Array(16), ITERATIONS)
}

let cached: { s: string; k: CryptoKey } | null = null

async function secretKey() {
	if (cached && cached.s === env.SESSION_SECRET) return cached.k
	const base = await crypto.subtle.importKey("raw", enc.encode(env.SESSION_SECRET), "PBKDF2", false, ["deriveKey"])
	const k = await crypto.subtle.deriveKey({ name: "PBKDF2", salt: enc.encode("moneytracker-secret-v1"), iterations: ITERATIONS, hash: "SHA-256" }, base, { name: "AES-GCM", length: 256 }, false, ["encrypt", "decrypt"])
	cached = { s: env.SESSION_SECRET, k }
	return k
}

export async function encryptSecret(plain: string) {
	const iv = crypto.getRandomValues(new Uint8Array(12))
	const ct = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv }, await secretKey(), enc.encode(plain)))
	return `v1.${b64(iv)}.${b64(ct)}`
}

export async function decryptSecret(v: string) {
	try {
		const [p, i, c] = v.split(".")
		if (p !== "v1" || !i || !c) return null
		return dec.decode(await crypto.subtle.decrypt({ name: "AES-GCM", iv: unb64(i) }, await secretKey(), unb64(c)))
	} catch {
		return null
	}
}
