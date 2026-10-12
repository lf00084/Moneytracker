import { asyncContext } from "remix/middleware/async-context";
import { auth } from "remix/middleware/auth";
import { logger } from "remix/middleware/logger";
import { render } from "remix/middleware/render";
import { session } from "remix/middleware/session";
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router";

import controller from "./controller.tsx";
import { loadAssetEntry } from "./middleware/asset-entry.ts";
import { routes } from "./routes.ts";
import { sessionCookie, sessionScheme, sessionStorage } from "./utils/auth.ts";
import { assets } from "./utils/assets.ts";

const appMiddleware = createMiddleware(
	asyncContext(),
	loadAssetEntry(),
	render({ assets }),
	session(sessionCookie, sessionStorage),
	auth({ schemes: [sessionScheme] }),
);
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

router.map(routes, controller);
