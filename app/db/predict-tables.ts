import { column as c, table } from "remix/data-table"

export const predictAccount = table({
	name: "predict_account",
	columns: {
		user_id: c.varchar(36),
		key_enc: c.varchar(2000),
		secret_enc: c.varchar(2000),
		wallet: c.varchar(80),
		usdt_minor: c.integer(),
		funding_minor: c.integer(),
		// Exact decimal strings straight from Binance (0.000000001 USDT is real).
		predict_text: c.varchar(40),
		funding_text: c.varchar(40),
		prev_funding_minor: c.integer(),
		prev_predict_minor: c.integer(),
		synced_at: c.integer(),
		last_error: c.varchar(300),
		fee_bps: c.integer(),
		p2p_since: c.integer(),
		p2p_synced_at: c.integer(),
		p2p_error: c.varchar(300),
		updated_at: c.integer(),
	},
	primaryKey: "user_id",
})

export const predictMoves = table({
	name: "predict_moves",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(16),
		usdt_minor: c.integer(),
		mad_minor: c.integer(),
		order_no: c.varchar(64),
		fee_minor: c.integer(),
		bank_id: c.varchar(36),
		pay: c.varchar(60),
		day: c.varchar(10),
		created_at: c.integer(),
	},
})

export const predictDays = table({
	name: "predict_days",
	columns: {
		id: c.varchar(60),
		user_id: c.varchar(36),
		day: c.varchar(10),
		open_minor: c.integer(),
		balance_minor: c.integer(),
		bought_minor: c.integer(),
		sold_minor: c.integer(),
		profit_minor: c.integer(),
		locked: c.integer(),
		saved_at: c.integer(),
	},
})

export const moveHints = table({
	name: "move_hints",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(16),
		usdt_minor: c.integer(),
		found_at: c.integer(),
		status: c.varchar(8),
		resolved_at: c.integer(),
	},
})

export const predictChecks = table({
	name: "predict_checks",
	columns: {
		id: c.varchar(60),
		user_id: c.varchar(36),
		day: c.varchar(10),
		done: c.integer(),
		done_at: c.integer(),
	},
	primaryKey: "id",
})
