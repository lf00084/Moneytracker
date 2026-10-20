import { asyncContext } from "remix/middleware/async-context";
import { formData } from "remix/middleware/form-data";
import { logger } from "remix/middleware/logger";
import { render } from "remix/middleware/render";
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router";

import rootController from "./actions/controller.tsx";
import { authMiddleware, sessionMiddleware } from "./lib/auth.ts";
import { routes } from "./routes.ts";

// Order matters: the session is loaded first, then the form body, then the user is resolved from the session.
const appMiddleware = createMiddleware(asyncContext(), render(), sessionMiddleware, formData(), authMiddleware);
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
