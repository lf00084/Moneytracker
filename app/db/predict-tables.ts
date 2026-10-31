import { column as c, table } from "remix/data-table"

export const predictAccount = table({
	name: "predict_account",
	columns: {
		user_id: c.varchar(36),
		key_enc: c.varchar(2000),
		secret_enc: c.varchar(2000),
		wallet: c.varchar(80),
		usdt_minor: c.integer(),
		synced_at: c.integer(),
		last_error: c.varchar(300),
		updated_at: c.integer(),
	},
	primaryKey: "user_id",
})

export const predictMoves = table({
	name: "predict_moves",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(8),
		usdt_minor: c.integer(),
		mad_minor: c.integer(),
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
		saved_at: c.integer(),
	},
})
