import { env } from "cloudflare:workers";
import { createGoogleAuthProvider } from "remix/auth";
import { createCookie } from "remix/cookie";
import { createSessionAuthScheme } from "remix/middleware/auth";
import { createCookieSessionStorage } from "remix/session-storage/cookie";

import { users } from "../data/schema.ts";

import { db } from "./db.ts";

export type User = { id: number; email: string; name: string };

export let sessionCookie = createCookie("__session", {
	secrets: [env.SESSION_SECRET],
	httpOnly: true,
	secure: !import.meta.env.DEV,
	sameSite: "lax",
	path: "/",
	maxAge: 60 * 60 * 24 * 30,
});

export let sessionStorage = createCookieSessionStorage();

export let sessionScheme = createSessionAuthScheme<User, { userId: number }>({
	read(session) {
		return session.get("auth") as { userId: number } | null;
	},
	async verify(value) {
		let user = await db.query(users).where({ id: value.userId }).first();
		return user ? { id: user.id, email: user.email, name: user.name } : null;
	},
	invalidate(session) {
		session.unset("auth");
	},
});

export function googleProvider(url: URL) {
	return createGoogleAuthProvider({
		clientId: env.GOOGLE_CLIENT_ID,
		clientSecret: env.GOOGLE_CLIENT_SECRET,
		redirectUri: new URL("/auth/google/callback", url),
	});
}

let toHex = (bytes: Uint8Array) =>
	Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
let fromHex = (text: string) =>
	new Uint8Array((text.match(/../g) ?? []).map((h) => parseInt(h, 16)));

async function derive(password: string, salt: Uint8Array<ArrayBuffer>) {
	let key = await crypto.subtle.importKey(
		"raw",
		new TextEncoder().encode(password),
		"PBKDF2",
		false,
		["deriveBits"],
	);
	let bits = await crypto.subtle.deriveBits(
		{ name: "PBKDF2", hash: "SHA-256", salt, iterations: 100000 },
		key,
		256,
	);
	return new Uint8Array(bits);
}

function same(a: Uint8Array, b: Uint8Array) {
	if (a.length !== b.length) return false;
	let diff = 0;
	for (let i = 0; i < a.length; i++) diff |= a[i]! ^ b[i]!;
	return diff === 0;
}

export async function hashPassword(password: string) {
	let salt = crypto.getRandomValues(new Uint8Array(16));
	return `${toHex(salt)}:${toHex(await derive(password, salt))}`;
}

export async function checkPassword(password: string, stored: string) {
	let [saltHex, hashHex] = stored.split(":");
	let salt = fromHex(saltHex ?? "");
	let derived = await derive(password, salt.length ? salt : new Uint8Array(16));
	return Boolean(hashHex) && same(derived, fromHex(hashHex!));
}
