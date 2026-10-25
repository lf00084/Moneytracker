import { column as c, table } from "remix/data-table"

export const users = table({
	name: "users",
	columns: {
		id: c.varchar(36),
		email: c.varchar(255),
		name: c.varchar(255),
		email_verified: c.integer(),
		currency: c.varchar(8),
		theme: c.varchar(8),
		phone: c.varchar(64),
		bio: c.varchar(500),
		run_at: c.varchar(8),
		week_start: c.varchar(16),
		bg_mode: c.varchar(8),
		bg_url: c.varchar(2048),
		usd_rate_minor: c.integer(),
		usdt_rate_minor: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})

export const passwords = table({
	name: "passwords",
	columns: { user_id: c.varchar(36), hash: c.varchar(255), updated_at: c.integer() },
	primaryKey: "user_id",
})

export const sessions = table({
	name: "sessions",
	columns: {
		id: c.varchar(64),
		user_id: c.varchar(36),
		data: c.varchar(65535),
		created_at: c.integer(),
		expires_at: c.integer(),
	},
})

export const oauthAccounts = table({
	name: "oauth_accounts",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		provider: c.varchar(32),
		provider_account_id: c.varchar(255),
		created_at: c.integer(),
	},
})

export const userImages = table({
	name: "user_images",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(16),
		source: c.varchar(16),
		url: c.varchar(2048),
		mime: c.varchar(64),
		size_bytes: c.integer(),
		is_active: c.integer(),
		created_at: c.integer(),
	},
})

export const incomeSources = table({
	name: "income_sources",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		name: c.varchar(80),
		mode: c.varchar(8),
		amount_minor: c.integer(),
		every: c.varchar(8),
		created_at: c.integer(),
		type: c.varchar(16),
		config: c.varchar(2000),
		currency: c.varchar(8),
		active: c.integer(),
		sort: c.integer(),
	},
})

export const incomes = table({
	name: "incomes",
	columns: {
		id: c.varchar(80),
		user_id: c.varchar(36),
		source_id: c.varchar(36),
		amount_minor: c.integer(),
		day: c.varchar(10),
		created_at: c.integer(),
		meta: c.varchar(2000),
		ext_key: c.varchar(120),
		usd_minor: c.integer(),
	},
})

export const purchases = table({
	name: "purchases",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		name: c.varchar(120),
		qty: c.integer(),
		unit_minor: c.integer(),
		total_minor: c.integer(),
		day: c.varchar(10),
		debt_id: c.varchar(36),
		created_at: c.integer(),
	},
})

export const people = table({
	name: "people",
	columns: { id: c.varchar(36), user_id: c.varchar(36), name: c.varchar(80) },
})

export const debts = table({
	name: "debts",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		person_id: c.varchar(36),
		kind: c.varchar(8),
		item_name: c.varchar(40),
		item_qty: c.integer(),
		amount_minor: c.integer(),
		updated_at: c.integer(),
		last_delta: c.integer(),
		created_at: c.integer(),
	},
})

export const debtPayments = table({
	name: "debt_payments",
	columns: {
		id: c.varchar(36),
		debt_id: c.varchar(36),
		user_id: c.varchar(36),
		amount_minor: c.integer(),
		purchase_id: c.varchar(36),
		created_at: c.integer(),
	},
})

export const goals = table({
	name: "goals",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		title: c.varchar(120),
		target_minor: c.integer(),
		saved_minor: c.integer(),
		is_wish: c.integer(),
		done_at: c.integer(),
		created_at: c.integer(),
	},
})

export const goalItems = table({
	name: "goal_items",
	columns: { id: c.varchar(36), user_id: c.varchar(36), goal_id: c.varchar(36), name: c.varchar(120), price_minor: c.integer(), done_at: c.integer(), created_at: c.integer() },
})

export const notes = table({
	name: "notes",
	columns: { id: c.varchar(36), user_id: c.varchar(36), body: c.varchar(5000), created_at: c.integer(), updated_at: c.integer() },
})

export const tradeSessions = table({
	name: "trade_sessions",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		day: c.varchar(10),
		deposit_minor: c.integer(),
		rate_minor: c.integer(),
		purchase_id: c.varchar(36),
		income_id: c.varchar(36),
		status: c.varchar(8),
		pnl_minor: c.integer(),
		return_usdt_minor: c.integer(),
		return_mad_minor: c.integer(),
		created_at: c.integer(),
		settled_at: c.integer(),
	},
})

export const tradeResults = table({
	name: "trade_results",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		session_id: c.varchar(36),
		game: c.varchar(8),
		idx: c.integer(),
		won: c.integer(),
		state: c.varchar(8),
		asset: c.varchar(8),
		tf: c.integer(),
		pnl_minor: c.integer(),
		created_at: c.integer(),
	},
})
