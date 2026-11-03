import { column as c, table } from "remix/data-table"

export const moneySetup = table({
	name: "money_setup",
	columns: {
		user_id: c.varchar(36),
		from_day: c.varchar(10),
		default_bank: c.varchar(36),
		all_time: c.integer(),
		created_at: c.integer(),
	},
	primaryKey: "user_id",
})

export const banks = table({
	name: "banks",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		name: c.varchar(40),
		kind: c.varchar(8),
		icon_url: c.varchar(300),
		opening_minor: c.integer(),
		sort: c.integer(),
		created_at: c.integer(),
	},
})

export const bankMoves = table({
	name: "bank_moves",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		bank_id: c.varchar(36),
		amount_minor: c.integer(),
		kind: c.varchar(8),
		note: c.varchar(80),
		ref: c.varchar(36),
		day: c.varchar(10),
		created_at: c.integer(),
	},
})

export const sourcePayments = table({
	name: "source_payments",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		source_id: c.varchar(36),
		source_name: c.varchar(80),
		amount_minor: c.integer(),
		bank_id: c.varchar(36),
		move_id: c.varchar(36),
		day: c.varchar(10),
		created_at: c.integer(),
	},
})

export const sourceAdjusts = table({
	name: "source_adjusts",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		source_id: c.varchar(36),
		amount_minor: c.integer(),
		note: c.varchar(80),
		day: c.varchar(10),
		created_at: c.integer(),
	},
})

export const dailySnapshots = table({
	name: "daily_snapshots",
	columns: {
		id: c.varchar(64),
		user_id: c.varchar(36),
		day: c.varchar(10),
		money_minor: c.integer(),
		usdt_minor: c.integer(),
		onhold_minor: c.integer(),
		total_minor: c.integer(),
		rate_minor: c.integer(),
		start_rate_minor: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})

export const payMaps = table({
	name: "pay_maps",
	columns: {
		id: c.varchar(120),
		user_id: c.varchar(36),
		method: c.varchar(60),
		bank_id: c.varchar(36),
		created_at: c.integer(),
	},
})
