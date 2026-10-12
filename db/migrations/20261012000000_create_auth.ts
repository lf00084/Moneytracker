import { createMigration } from "remix/data-table/migrations";

import { accounts, users } from "../../app/data/schema.ts";

export default createMigration({
	async up({ schema }) {
		await schema.createTable(users);
		await schema.createIndex(users, "email", { unique: true });
		await schema.createTable(accounts);
		await schema.createIndex(accounts, "provider_key", { unique: true });
		await schema.createIndex(accounts, "user_id");
	},
	async down({ schema }) {
		await schema.dropTable(accounts, { ifExists: true });
		await schema.dropTable(users, { ifExists: true });
	},
});
