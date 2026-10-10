import { createAction } from "remix/router";

import DocumentLayout from "~/resources/layouts/document";
import routes from "~/routes/web";

/** GET /about */
export default createAction(routes.about, (ctx) => {
	return ctx.render(
		<DocumentLayout title="About">
			<h1>About</h1>
			<p>A second route, to show how routes, controllers and the layout fit together.</p>
		</DocumentLayout>,
	);
});
