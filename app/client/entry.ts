// Browser entry: boots the Remix component runtime (soft navigation, form
// interception, prefetching, frame resolution, client-entry hydration) and
// registers document-level progressive-enhancement behaviors.
import { run } from "remix/component"
import { enhance } from "./enhance.ts"
// Hydrated components re-exported here so loadModule resolves their export
// names from this module.
import { ClockWidget } from "../components/clock.tsx"
import { DateCard } from "../components/datecard.tsx"

export { ClockWidget, DateCard }

export const app = run({
	async loadModule(moduleUrl: string, exportName: string) {
		const mod = (await import(/* @vite-ignore */ moduleUrl)) as Record<string, unknown>
		const Component = mod[exportName]
		if (typeof Component !== "function") throw new Error(`Unknown component: ${moduleUrl}#${exportName}`)
		return Component
	},
})

enhance(app)
