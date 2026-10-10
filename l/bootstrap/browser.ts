import { run } from "remix/component";

/**
 * Client islands the server can hydrate, keyed by the module URL the island writes.
 * Empty on purpose: pages without an island link no script at all.
 */
const CLIENT_MODULES: Record<string, () => Promise<unknown>> = {};

let runtime = run({
	async loadModule(moduleUrl, exportName) {
		let load = CLIENT_MODULES[moduleUrl];
		if (!load) throw new Error(`Unknown client entry module: ${moduleUrl}`);

		let mod = await load();
		if (!mod || typeof mod !== "object") throw new Error(`Invalid module: ${moduleUrl}`);

		let entry = Reflect.get(mod, exportName);
		if (typeof entry !== "function") throw new Error(`Missing export ${exportName}`);

		return entry;
	},

	async resolveFrame(src, options) {
		let { target, signal, method, formData } = options ?? {};
		let headers = new Headers({ accept: "text/html" });
		if (target) headers.set("x-remix-target", target);
		return await fetch(src, { credentials: "same-origin", headers, signal, method, body: formData });
	},
});

runtime.addEventListener("error", (event) => {
	console.error("A client entry failed to hydrate", event.error);
});
