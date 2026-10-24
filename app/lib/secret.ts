import { env } from "../env.ts"
const enc = new TextEncoder()
const dec = new TextDecoder()
let cached: { s: string; k: CryptoKey } | null = null
const b64 = (u: Uint8Array) => btoa(String.fromCharCode(...u))
const unb64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))
async function key() {
if (cached && cached.s === env.SESSION_SECRET) return cached.k
const base = await crypto.subtle.importKey("raw", enc.encode(env.SESSION_SECRET), "PBKDF2", false, ["deriveKey"])
const k = await crypto.subtle.deriveKey({ name: "PBKDF2", salt: enc.encode("moneytracker-secret-v1"), iterations: 100000, hash: "SHA-256" }, base, { name: "AES-GCM", length: 256 }, false, ["encrypt", "decrypt"])
cached = { s: env.SESSION_SECRET, k }
return k
}
export async function encryptSecret(plain: string): Promise<string> {
const iv = crypto.getRandomValues(new Uint8Array(12))
const ct = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv }, await key(), enc.encode(plain)))
return `v1.${b64(iv)}.${b64(ct)}`
}
export async function decryptSecret(v: string): Promise<string | null> {
try {
const [p, i, c] = v.split(".")
if (p !== "v1" || !i || !c) return null
return dec.decode(await crypto.subtle.decrypt({ name: "AES-GCM", iv: unb64(i) }, await key(), unb64(c)))
} catch {
return null
}
}
