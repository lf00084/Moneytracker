import type { RemixNode } from "remix/component";
import type { Middleware } from "remix/router";

import { renderToStream } from "remix/component/server";
import { renderWith } from "remix/middleware/render";
import { createHtmlResponse } from "remix/response/html";
import { createRouter } from "remix/router";

import about from "~/app/http/controllers/about";
import defaultHandler from "~/app/http/controllers/default-handler";
import home from "~/app/http/controllers/home";
import { documentAssets } from "~/app/lib/assets";
import { DocumentAssets } from "~/resources/layouts/document";
import routes from "~/routes/web";

/** Builds the router. Both the worker and any tests call this. */
export default function application() {
	let middleware: Middleware[] = [renderWith(createHtmlRenderer) as Middleware];

	let router = createRouter({ middleware, defaultHandler });

	router.map(routes.home, home);
	router.map(routes.about, about);

	return router;
}

/** `ctx.render(<jsx />)`: streams the page and prepends the doctype. */
function createHtmlRenderer() {
	return async function render(node: RemixNode, init?: ResponseInit) {
		let headers = new Headers(init?.headers);
		headers.set("content-type", "text/html; charset=utf-8");

		let assets = await documentAssets();
		let stream = renderToStream(<DocumentAssets value={assets}>{node}</DocumentAssets>);

		return createHtmlResponse(stream, { ...init, headers });
	};
}
