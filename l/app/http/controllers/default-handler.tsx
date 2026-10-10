import type { RequestContext } from "remix/router";

import DocumentLayout from "~/resources/layouts/document";

/** Renders the 404 page for any URL that matches no route. */
export default function defaultHandler(ctx: RequestContext) {
	return ctx.render(
		<DocumentLayout title="Not found">
			<h1>404</h1>
			<p>
				Nothing here. <a href="/">Go home</a>.
			</p>
		</DocumentLayout>,
		{ status: 404 },
	);
}
