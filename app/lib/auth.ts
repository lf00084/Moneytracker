import { auth, createSessionAuthScheme } from "remix/middleware/auth";
import { createGoogleAuthProvider } from "remix/auth";
import { createCookie } from "remix/cookie";
import { session } from "remix/middleware/session";

import { createDbSessionStorage } from "../db/session-storage.ts";
import { env } from "../env.ts";
import { getUserById } from "./users.ts";

const sessionCookie = createCookie("__session", {
	secrets: [env.SESSION_SECRET],
	httpOnly: true,
	secure: import.meta.env.PROD,
	sameSite: "lax",
	path: "/",
	maxAge: 60 * 60 * 24 * 30,
});

/** Session loaded from the sessions table, then the signed-in user resolved from it. */
export const sessionMiddleware = session(sessionCookie, createDbSessionStorage());

export const authMiddleware = auth({
	schemes: [
		createSessionAuthScheme({
			read(s) {
				return s.get("auth") as { userId: string } | null;
			},
			verify(value) {
				return getUserById(value.userId);
			},
			invalidate(s) {
				s.unset("auth");
			},
		}),
	],
});

/** Created once at module scope, as Remix asks. The callback must be registered in Google Cloud. */
export const googleProvider = createGoogleAuthProvider({
	clientId: env.GOOGLE_CLIENT_ID,
	clientSecret: env.GOOGLE_CLIENT_SECRET,
	redirectUri: new URL("/auth/google/callback", env.APP_ORIGIN),
});
