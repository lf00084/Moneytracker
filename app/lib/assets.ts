import type { ScriptEntry } from "@pitlane/assets";

import { createAssetResolver } from "@pitlane/assets";
import manifest from "@pitlane/assets/manifest";

const assets = createAssetResolver(manifest);

export interface DocumentAssets {
	stylesheets: string[];
	script: ScriptEntry;
}

/** Looks up the hashed CSS and the client entry from the manifest the Vite plugin writes. */
export async function documentAssets(): Promise<DocumentAssets> {
	let [stylesheets, script] = await Promise.all([
		assets.getStylesheets("resources/layouts/document.tsx"),
		assets.getScriptEntry("bootstrap/browser.ts"),
	]);

	return { stylesheets, script };
}
