import { createClient } from "@libsql/client/web";
import { createTursoDatabase } from "@kuboon/remix-data-table-sqlite-turso";

import { env } from "../env.ts";

/** One Turso database for local dev and Cloudflare. The client is created once per isolate. */
const client = createClient({ url: env.TURSO_DATABASE_URL, authToken: env.TURSO_AUTH_TOKEN });

export const db = createTursoDatabase(client);

export * from "./tables.ts";
