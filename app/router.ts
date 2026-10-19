import { asyncContext } from "remix/middleware/async-context";
import { logger } from "remix/middleware/logger";
import { render } from "remix/middleware/render";
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router";

import rootController from "./actions/controller.tsx";
import { routes } from "./routes.ts";

// No `assets` option: every page is rendered on the server and ships no client scripts.
const appMiddleware = createMiddleware(asyncContext(), render());
type AppContext = MiddlewareContext<typeof appMiddleware>;

declare module "remix" {
	interface RouterTypes {
		context: AppContext;
	}
}

const middleware = [];

if (import.meta.env.DEV) middleware.push(logger());

middleware.push(...appMiddleware);

export const router = createRouter<AppContext>({ middleware });

router.map(routes, rootController);
