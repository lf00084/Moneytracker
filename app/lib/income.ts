import { banks, db, incomes, incomeSources, sourceAdjusts } from "../db/index.ts"
import { ensureCash, getSetup, pendingList } from "./banks.ts"
import { toMinor } from "./money.ts"
import { encryptSecret } from "./crypto.ts"
import { today } from "./time.ts"
import { todayFor, type User } from "./users.ts"
import { extKey, id, isFixed, parseJson, text } from "./util.ts"

const days = (v: unknown) => {
	const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")))
	return Number.isFinite(n) && n > 0 ? Math.min(n, 90) : 0
}

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
	const payDays = days(f.get("pay_days"))
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

	if (kind !== "exoclick" && text(f.get("pay"), 8) === "instant") {
		const list = await ensureCash(uid)
		const pick = text(f.get("to"), 36)
		const bank = pick ? list.find((b) => b.id === pick) : null
		const cash = list.find((b) => b.kind === "cash")
		config = { ...config, instant: 1, to: bank?.id ?? cash?.id ?? "" }
	} else if (payDays && kind !== "exoclick") {
		config = { ...config, instant: 0, pay_days: payDays }
	}

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
	const newCfg: Record<string, any> = { ...cfg }
	const patch: { name: string; config?: string; amount_minor?: number } = { name }

	if (isFixed(s.type)) {
		const fixed = toMinor(f.get("fixed"))
		const rate = toMinor(f.get("rate"))
		if (!fixed) return "Enter the fixed amount per day"
		if (!rate) return "Enter the price per extra hour"
		newCfg.fixed_minor = fixed
		newCfg.rate_minor = rate
	} else if (s.type === "exoclick") {
		const k = text(f.get("api_key"), 200)
		if (k) newCfg.key_enc = await encryptSecret(k)
	} else if (s.mode === "auto") {
		const a = toMinor(f.get("amount"))
		if (!a) return "Enter how much it pays"
		patch.amount_minor = a
	}

	if (s.type !== "exoclick") {
		const payMode = text(f.get("pay"), 8)
		if (payMode === "instant") {
			const list = await ensureCash(uid)
			const pick = text(f.get("to"), 36)
			const bank = pick ? list.find((b) => b.id === pick) : null
			const cash = list.find((b) => b.kind === "cash")
			newCfg.instant = 1
			newCfg.to = bank?.id ?? cash?.id ?? ""
			delete newCfg.pay_days
		} else if (payMode === "pending") {
			newCfg.instant = 0
			delete newCfg.to
			if (f.get("pay_days") !== null) newCfg.pay_days = days(f.get("pay_days"))
		} else if (f.get("pay_days") !== null && !Number(newCfg.instant)) {
			newCfg.pay_days = days(f.get("pay_days"))
		}
	}

	patch.config = JSON.stringify(newCfg)
	await db.update(incomeSources, s.id, patch)
}

export async function adjustPending(user: User, f: FormData): Promise<string | void> {
	const uid = user.id
	const sid = text(f.get("source_id"), 36)
	const s = await db.findOne(incomeSources, { where: { id: sid, user_id: uid } })
	if (!s) return "Unknown source"
	const target = toMinor(f.get("amount"))
	if (target === null || target < 0) return "Enter a valid pending amount"
	const curList = await pendingList(uid, user.usd_rate_minor, today(user.day_start))
	const cur = curList.find((p) => p.id === s.id)
	const currentLeft = cur?.left ?? 0
	const diff = target - currentLeft
	if (!diff) return
	await db.create(sourceAdjusts, {
		id: id(),
		user_id: uid,
		source_id: s.id,
		amount_minor: diff,
		note: text(f.get("note"), 80) || "Pending adjustment",
		day: await todayFor(uid),
		created_at: Date.now(),
	})
}

export async function setHours(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } })
	if (!s || !isFixed(s.type)) return "Unknown source"
	const raw = text(f.get("hours"), 8).replace(",", ".")
	let h = raw === "" ? 0 : Number(raw)
	if (!Number.isFinite(h) || h < 0 || h > 24) return "Hours must be between 0 and 24"
	h = Math.round(h * 100) / 100
	const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, await todayFor(uid)) } })
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
	const to = text(f.get("to"), 36)
	await db.create(incomes, {
		id: id(),
		user_id: uid,
		amount_minor: amount,
		day: await todayFor(uid),
		created_at: Date.now(),
		meta: JSON.stringify({ manual: 1, instant: 1, to, label }),
		ext_key: "",
	})
}
