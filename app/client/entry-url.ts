// Browser module URL for the Remix component runtime entry.
// Dev loads the source module straight through Vite; production loads the
// prebuilt bundle served by the /assets/entry.js route.
export const ENTRY_HREF = import.meta.env.DEV ? "/app/client/entry.ts" : "/assets/entry.js"

// Client-entry IDs used with clientEntry(entryId("Name"), Component). The
// server embeds these in the rendered HTML; the runtime imports the module
// and hydrates the named export.
export const entryId = (name: string) => `${ENTRY_HREF}#${name}`
