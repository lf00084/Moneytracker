import { createAction } from "remix/router";

import DocumentLayout from "~/resources/layouts/document";
import routes from "~/routes/web";

/** GET / */
export default createAction(routes.home, (ctx) => {
	return ctx.render(
		<DocumentLayout title="Remix starter">
			<h1>Remix + Vite + Cloudflare</h1>
			<p>
				Edit <code>app/http/controllers/home.tsx</code> and refresh.
			</p>
		</DocumentLayout>,
	);
});
