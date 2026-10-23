import { run } from "remix/component"
const app = run({
async loadModule(moduleUrl, exportName) {
const mod = await import(moduleUrl)
return mod[exportName]
},
})
app.addEventListener("error", (e) => console.error(e))
app.ready().catch((e) => console.error(e))
