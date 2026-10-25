import { db, incomes, incomeSources } from "../db/index.ts"
import { toMinor } from "./money.ts"
import { encryptSecret } from "./crypto.ts"
import { today } from "./time.ts"
import { extKey, id, isFixed, parseJson, text } from "./util.ts"

export async function addSource(uid: string, f: FormData): Promise<string | void> {
	const name = text(f.get("name"), 80)
	if (!name) return "Enter a name"
	const kind = text(f.get("kind"), 12) || "fixed"
	const taken = await db.findMany(incomeSources, { where: { user_id: uid } })
	if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`
	let type = "manual"
	let mode = "manual"
	let every = ""
	let amount = 0
	let currency = "MAD"
	let config: Record<string, number | string> = {}
	if (kind === "fixed") {
		const fixed = toMinor(f.get("fixed"))
		const rate = toMinor(f.get("rate"))
		if (!fixed) return "Enter the fixed amount per day"
		if (!rate) return "Enter the price per extra hour"
		type = "fixed"
		config = { fixed_minor: fixed, rate_minor: rate }
	} else if (kind === "daily" || kind === "monthly") {
		amount = toMinor(f.get("amount"))
		if (!amount) return "Enter how much it pays"
		mode = "auto"
		every = kind === "daily" ? "day" : "month"
	} else if (kind === "exoclick") {
		const k = text(f.get("api_key"), 200)
		if (!k) return "Enter your ExoClick API key"
		type = "exoclick"
		mode = "auto"
		every = "day"
		currency = "USD"
		config = { key_enc: await encryptSecret(k) }
	} else if (kind !== "manual") return "Pick a source type"
	const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] })
	await db.create(incomeSources, { id: id(), user_id: uid, name, mode, amount_minor: amount, every, created_at: Date.now(), type, config: JSON.stringify(config), currency, active: 1, sort: (last?.sort ?? -1) + 1 })
}

export async function editSource(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (!s) return "Unknown source"
	const name = text(f.get("name"), 80)
	if (!name) return "Enter a name"
	const taken = await db.findMany(incomeSources, { where: { user_id: uid } })
	if (taken.some((x) => x.id !== s.id && x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`
	const cfg = parseJson(s.config)
	const patch: { name: string; config?: string; amount_minor?: number } = { name }
	if (isFixed(s.type)) {
		const fixed = toMinor(f.get("fixed"))
		const rate = toMinor(f.get("rate"))
		if (!fixed) return "Enter the fixed amount per day"
		if (!rate) return "Enter the price per extra hour"
		patch.config = JSON.stringify({ ...cfg, fixed_minor: fixed, rate_minor: rate })
	} else if (s.type === "exoclick") {
		const k = text(f.get("api_key"), 200)
		if (k) patch.config = JSON.stringify({ ...cfg, key_enc: await encryptSecret(k) })
	} else if (s.mode === "auto") {
		const a = toMinor(f.get("amount"))
		if (!a) return "Enter how much it pays"
		patch.amount_minor = a
	}
	await db.update(incomeSources, s.id, patch)
}

export async function setHours(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } })
	if (!s || !isFixed(s.type)) return "Unknown source"
	const raw = text(f.get("hours"), 8).replace(",", ".")
	let h = raw === "" ? 0 : Number(raw)
	if (!Number.isFinite(h) || h < 0 || h > 24) return "Hours must be between 0 and 24"
	h = Math.round(h * 100) / 100
	const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, today()) } })
	if (!row) return `Add ${s.name} first`
	const meta = parseJson(row.meta)
	const cfg = parseJson(s.config)
	if (f.get("toggle") && Number(meta.hours) === h) h = 0
	const fixed = Number(meta.fixed_minor) || Number(cfg.fixed_minor) || 0
	const rate = Number(cfg.rate_minor) || 0
	await db.update(incomes, row.id, { amount_minor: fixed + Math.round(h * rate), meta: JSON.stringify({ ...meta, fixed_minor: fixed, hours: h, rate_minor: rate }) })
}

export async function addNamed(uid: string, f: FormData): Promise<string | void> {
	const amount = toMinor(f.get("amount"))
	if (!amount) return "Enter an amount"
	const label = text(f.get("label"), 60)
	await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day: today(), created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: "" })
}
