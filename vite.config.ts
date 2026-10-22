import { cloudflare } from "@cloudflare/vite-plugin"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"
const ui = (file: string) => fileURLToPath(new URL(`./app/ui/${file}`, import.meta.url))
export default defineConfig({
server: { host: "0.0.0.0", port: 3000, allowedHosts: true },
resolve: {
tsconfigPaths: true,
alias: [
{ find: "~/app/ui/jsx-runtime", replacement: ui("jsx-runtime.ts") },
{ find: "~/app/ui/jsx-dev-runtime", replacement: ui("jsx-dev-runtime.ts") },
],
},
oxc: { jsx: { runtime: "automatic", importSource: "~/app/ui" } },
plugins: [cloudflare()],
})
