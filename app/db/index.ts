import { createClient } from "@libsql/client/web"
import { createTursoDatabase } from "@remix-kbn/data-table-sqlite-turso"
import { env } from "../env.ts"

export const db = createTursoDatabase(createClient({ url: env.TURSO_DATABASE_URL, authToken: env.TURSO_AUTH_TOKEN }))

export * from "./tables.ts"
