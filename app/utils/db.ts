import { createD1Database } from "@pitlane/data-table-d1";
import { env } from "cloudflare:workers";

export let db = createD1Database(env.DB);
