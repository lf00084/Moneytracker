import appCss from "../client/app.css?raw";
import appJs from "../client/app.js?raw";
import themeJs from "../client/theme.js?raw";
import entryJs from "../client/dist/entry.js?raw";

export const hash = (s: string) => {
	let h = 5381;
	for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0;
	return (h >>> 0).toString(36);
};

export const V = { css: hash(appCss), js: hash(appJs), theme: hash(themeJs), entry: hash(entryJs) };
