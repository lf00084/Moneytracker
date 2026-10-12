import { generateD1Migrations } from "@pitlane/data-table-d1/migrations";

let migrations = await generateD1Migrations({ to: "db/d1-migrations" });
console.log(`Generated ${migrations.length} migration(s).`);
