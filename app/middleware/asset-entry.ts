import type { ScriptEntry } from "@pitlane/assets";

import { getContext } from "remix/middleware/async-context";
import { createContextKey, type Middleware } from "remix/router";

import { assets } from "../utils/assets.ts";

interface AssetEntry {
	scriptEntry: ScriptEntry;
}

const assetEntryKey = createContextKey<AssetEntry>();

export function loadAssetEntry(): Middleware<{ key: typeof assetEntryKey; value: AssetEntry }> {
	return async (context, next) => {
		const scriptEntry = await assets.getScriptEntry("bootstrap/browser.ts");
		context.set(assetEntryKey, { scriptEntry });
		return next();
	};
}

export function getAssetEntry(): AssetEntry {
	return getContext().get(assetEntryKey);
}
