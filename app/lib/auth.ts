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
export const sessionMiddleware = session(sessionCookie, createDbSessionStorage());
export const authMiddleware = auth({
schemes: [
createSessionAuthScheme({
read(s) {
const v = s.get("auth") as { userId?: string } | null;
return v && typeof v.userId === "string" ? (v as { userId: string }) : null;
},
async verify(value) {
try {
return await getUserById(value.userId);
} catch {
return null;
}
},
invalidate(s) {
s.unset("auth");
},
}),
],
});
export const googleProvider = createGoogleAuthProvider({
clientId: env.GOOGLE_CLIENT_ID,
clientSecret: env.GOOGLE_CLIENT_SECRET,
redirectUri: new URL("/auth/google/callback", env.APP_ORIGIN),
});
