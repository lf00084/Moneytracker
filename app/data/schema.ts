import { column as c, table } from "remix/data-table";

export let users = table({
	name: "users",
	columns: {
		id: c.integer().primaryKey().autoIncrement(),
		email: c.varchar(255).notNull().unique(),
		name: c.varchar(255).notNull(),
		password_hash: c.varchar(512).notNull(),
		created_at: c.integer().notNull(),
	},
});

export let accounts = table({
	name: "accounts",
	columns: {
		id: c.integer().primaryKey().autoIncrement(),
		user_id: c.integer().notNull(),
		provider: c.varchar(32).notNull(),
		provider_key: c.varchar(255).notNull().unique(),
		created_at: c.integer().notNull(),
	},
});
