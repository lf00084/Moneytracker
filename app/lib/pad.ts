import { sql } from "remix/data-table"
import { db, padEntries, padSpaces } from "../db/index.ts"
import { id, parseJson, text } from "./util.ts"

import { COLORS, TYPES, type Entry, type PadData, type Space } from "./padmeta.ts"

export type { Entry, PadData, Space }

type Result = Promise<string | void>

export async function loadPad(uid: string, pick: string, done = false): Promise<PadData> {
	const [sp, en] = await Promise.all([
		db.findMany(padSpaces, { where: { user_id: uid, kind: "project" }, orderBy: ["sort", "asc"] }),
		db.findMany(padEntries, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 3000 }),
	])
	const spaces = sp
		.filter((x) => !x.archived_at)
		.map((x): Space => {
			const j = parseJson(x.sub)
			return { id: x.id, title: x.title, color: String(j.c || COLORS[0]), type: String(j.t || "mix"), bar: j.b !== 0 }
		})
	const entries = en.map((x): Entry => {
		const j = parseJson(x.ref)
		return { id: x.id, space: x.space_id ?? "", kind: x.kind, body: x.body, who: String(j.n || ""), tag: String(j.t || ""), today: !!x.on_home, at: x.created_at }
	})
	return { spaces, space: spaces.find((x) => x.id === pick) ?? spaces[0] ?? null, entries, done }
}

const mine = async (uid: string, v: unknown) => {
	const i = text(v, 36)
	return i ? ((await db.findOne(padSpaces, { where: { id: i, user_id: uid } })) ?? null) : null
}

export async function addSpace(uid: string, f: FormData): Result {
	const title = text(f.get("title"), 60)
	if (!title) return "Give the project a name"
	const color = COLORS.includes(text(f.get("color"), 9)) ? text(f.get("color"), 9) : COLORS[0]!
	const type = (TYPES as readonly string[]).includes(text(f.get("type"), 8)) ? text(f.get("type"), 8) : "mix"
	const nid = text(f.get("nid"), 36)
	const now = Date.now()
	try {
		await db.create(padSpaces, {
			id: /^[0-9a-f-]{36}$/.test(nid) ? nid : id(),
			user_id: uid,
			kind: "project",
			title,
			sub: JSON.stringify({ c: color, t: type, b: f.get("bar") ? 1 : 0 }),
			sort: now,
			archived_at: null as never,
			created_at: now,
			updated_at: now,
		})
	} catch {
		return "You already have a project with that name"
	}
}

export async function editSpace(uid: string, f: FormData): Result {
	const s = await mine(uid, f.get("id"))
	if (!s) return "Project not found"
	const title = text(f.get("title"), 60)
	if (!title) return "Give the project a name"
	const color = COLORS.includes(text(f.get("color"), 9)) ? text(f.get("color"), 9) : COLORS[0]!
	const type = (TYPES as readonly string[]).includes(text(f.get("type"), 8)) ? text(f.get("type"), 8) : "mix"
	try {
		await db.update(padSpaces, s.id, { title, sub: JSON.stringify({ c: color, t: type, b: f.get("bar") ? 1 : 0 }), updated_at: Date.now() })
	} catch {
		return "You already have a project with that name"
	}
}

export async function deleteSpace(uid: string, f: FormData) {
	const s = await mine(uid, f.get("id"))
	if (!s) return
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from pad_entries where space_id = ${s.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from pad_spaces where id = ${s.id} and user_id = ${uid}`)
	})
}

export async function addEntry(uid: string, f: FormData): Result {
	const body = text(f.get("body"), 2000)
	if (!body) return "Write something first"
	const tab = text(f.get("tab"), 8)
	const mode = text(f.get("mode"), 8)
	const now = Date.now()
	let space: string | null = null
	let kind = "task"
	let ref = "{}"
	let home = 0
	if (tab === "said") {
		kind = "said"
		ref = JSON.stringify({ n: text(f.get("who"), 40) || "Someone", t: mode === "info" ? "Info" : "Tip" })
		space = (await mine(uid, f.get("space")))?.id ?? null
	} else if (tab === "home") {
		home = mode === "later" ? 0 : 1
	} else {
		const s = await mine(uid, f.get("space"))
		if (!s) return "Create a project first"
		space = s.id
		const t = parseJson(s.sub).t
		kind = t === "notes" ? "note" : t === "tasks" ? "task" : mode === "note" ? "note" : "task"
	}
	await db.create(padEntries, { id: id(), user_id: uid, space_id: space as never, kind, body, ref, on_home: home, created_at: now, updated_at: now })
}

export async function toggleEntry(uid: string, f: FormData) {
	const e = await db.findOne(padEntries, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (e && (e.kind === "task" || e.kind === "done")) await db.update(padEntries, e.id, { kind: e.kind === "task" ? "done" : "task", updated_at: Date.now() })
}

export async function deleteEntry(uid: string, f: FormData) {
	await db.deleteMany(padEntries, { where: { id: text(f.get("id"), 36), user_id: uid } })
}

export async function editEntry(uid: string, f: FormData): Result {
	const body = text(f.get("body"), 2000)
	if (!body) return "Write something first"
	await db.updateMany(padEntries, { body, updated_at: Date.now() }, { where: { id: text(f.get("id"), 36), user_id: uid } })
}
