import { db, oauthAccounts, passwords, userImages, users } from "../db/index.ts"
import { fakeVerify, hashPassword, verifyPassword } from "./crypto.ts"
import { id } from "./util.ts"

export type User = {
	id: string
	email: string
	name: string
	currency: string
	theme: string
	run_at: string
	week_start: string
	usd_rate_minor: number
	usdt_rate: number
}

const normEmail = (e: string) => e.trim().toLowerCase()
const toUser = (r: any): User => ({
	id: r.id,
	email: r.email,
	name: r.name,
	currency: r.currency || "MAD",
	theme: r.theme || "dark",
	run_at: r.run_at || "06:00",
	week_start: r.week_start || "Monday",
	usd_rate_minor: r.usd_rate_minor || 1000,
	usdt_rate: Number(r.usdt_rate_minor) > 0 ? Number(r.usdt_rate_minor) : 1100,
})

export async function getUserById(id: string): Promise<User | null> {
	const row = await db.find(users, id)
	return row ? toUser(row) : null
}

const newUserRow = (id: string, email: string, name: string, verified: number, now: number) => ({
	id,
	email,
	name: name || email.split("@")[0]!,
	email_verified: verified,
	currency: "MAD",
	theme: "dark",
	run_at: "06:00",
	week_start: "Monday",
	usdt_rate_minor: 1100,
	created_at: now,
	updated_at: now,
})

type SignUpResult = { ok: true; user: User } | { ok: false; error: string }

export async function signUpWithPassword(input: { name: string; email: string; password: string }): Promise<SignUpResult> {
	const email = normEmail(input.email)
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return { ok: false, error: "Enter a valid email." }
	if (input.password.length < 8) return { ok: false, error: "Password needs at least 8 characters." }
	if (input.password.length > 200) return { ok: false, error: "Password is too long." }
	if (await db.findOne(users, { where: { email } })) return { ok: false, error: "That email already has an account." }

	const hash = await hashPassword(input.password)
	const now = Date.now()
	const userId = id()
	const row = newUserRow(userId, email, input.name.trim().slice(0, 80), 0, now)

	try {
		await db.transaction(async (tx) => {
			await tx.create(users, row)
			await tx.create(passwords, { user_id: userId, hash, updated_at: now })
		})
	} catch {
		return { ok: false, error: "That email already has an account." }
	}
	return { ok: true, user: toUser(row) }
}

export async function signInWithPassword(emailRaw: string, password: string): Promise<User | null> {
	const user = await db.findOne(users, { where: { email: normEmail(emailRaw) } })
	const pw = user ? await db.findOne(passwords, { where: { user_id: user.id } }) : null
	if (!user || !pw) {
		await fakeVerify(password)
		return null
	}
	return (await verifyPassword(password, pw.hash)) ? toUser(user) : null
}

type GoogleProfile = { id?: string; email?: string | null; name?: string | null; picture?: string | null }

export async function upsertFromGoogle(account: { providerAccountId: string }, profile: GoogleProfile): Promise<User> {
	const link = await db.findOne(oauthAccounts, { where: { provider: "google", provider_account_id: account.providerAccountId } })
	if (link) {
		const existing = await db.find(users, link.user_id)
		if (existing) return toUser(existing)
	}

	const email = normEmail(profile.email ?? "")
	if (!email) throw new Error("Google did not return an email.")
	const now = Date.now()

	return db.transaction(async (tx) => {
		let user = await tx.findOne(users, { where: { email } })
		if (!user) {
			user = await tx.create(users, newUserRow(id(), email, profile.name?.trim() ?? "", 1, now), { returnRow: true })
		}
		await tx.create(oauthAccounts, {
			id: id(),
			user_id: user.id,
			provider: "google",
			provider_account_id: account.providerAccountId,
			created_at: now,
		})
		if (profile.picture) {
			const hasAvatar = await tx.findOne(userImages, { where: { user_id: user.id, kind: "avatar", is_active: 1 } })
			if (!hasAvatar) {
				await tx.create(userImages, {
					id: id(),
					user_id: user.id,
					kind: "avatar",
					source: "google",
					url: profile.picture,
					mime: "",
					size_bytes: 0,
					is_active: 1,
					created_at: now,
				})
			}
		}
		return toUser(user)
	})
}

export async function getActiveAvatar(userId: string): Promise<string | null> {
	const img = await db.findOne(userImages, {
		where: { user_id: userId, kind: "avatar", is_active: 1 },
		orderBy: ["created_at", "desc"],
	})
	return img?.url ?? null
}

export async function updateProfile(userId: string, input: { name: string; email: string }) {
	const email = normEmail(input.email)
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return "Enter a valid email."
	const clash = await db.findOne(users, { where: { email } })
	if (clash && clash.id !== userId) return "That email belongs to another account."
	await db.update(users, userId, {
		name: input.name.trim().slice(0, 80) || email.split("@")[0]!,
		email,
		updated_at: Date.now(),
	})
	return null
}

export async function updatePrefs(userId: string, input: { currency: string; run_at: string; week_start: string; usdt_rate_minor: number; usd_rate_minor: number }) {
	const runAt = input.run_at.trim()
	await db.update(users, userId, {
		currency: input.currency.trim().toUpperCase().slice(0, 8) || "MAD",
		run_at: /^([01]?\d|2[0-3]):[0-5]\d$/.test(runAt) ? runAt.padStart(5, "0") : "06:00",
		week_start: input.week_start.trim().slice(0, 16) || "Monday",
		...(input.usd_rate_minor > 0 && input.usd_rate_minor <= 100000000 ? { usd_rate_minor: input.usd_rate_minor } : {}),
		...(input.usdt_rate_minor > 0 && input.usdt_rate_minor <= 100000000 ? { usdt_rate_minor: input.usdt_rate_minor } : {}),
		updated_at: Date.now(),
	})
}

export async function setTheme(userId: string, theme: string) {
	if (theme !== "dark" && theme !== "light") return
	await db.update(users, userId, { theme, updated_at: Date.now() })
}
