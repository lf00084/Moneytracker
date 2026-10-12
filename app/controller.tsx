import { completeAuth, finishExternalAuth, startExternalAuth } from "remix/auth";
import { Auth } from "remix/middleware/auth";
import { redirect } from "remix/response/redirect";
import { createController } from "remix/router";
import { Session } from "remix/session";

import { accounts, users } from "./data/schema.ts";
import { routes } from "./routes.ts";
import { AuthPage, HomePage } from "./ui/pages.tsx";
import { checkPassword, googleProvider, hashPassword, type User } from "./utils/auth.ts";
import { db } from "./utils/db.ts";

type GoogleProfile = { id: string; email?: string | null; name?: string | null };

let emailOk = (email: string) => email.length <= 255 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
let passwordOk = (password: string) => password.length >= 8 && password.length <= 128;

async function readForm(request: Request) {
	let form = await request.formData();
	return {
		email: String(form.get("email") ?? "").trim().toLowerCase(),
		password: String(form.get("password") ?? ""),
		name: String(form.get("name") ?? "").trim().slice(0, 100),
	};
}

export default createController(routes, {
	actions: {
		home(context) {
			let state = context.get(Auth);
			if (!state.ok) return redirect("/login");
			return context.render(<HomePage user={state.identity as User} />);
		},
		login(context) {
			if (context.get(Auth).ok) return redirect("/");
			return context.render(
				<AuthPage mode="login" error={context.url.searchParams.get("error")} />,
			);
		},
		async loginSubmit(context) {
			let { email, password } = await readForm(context.request);
			let user = emailOk(email) ? await db.query(users).where({ email }).first() : null;
			let valid = await checkPassword(password, user?.password_hash ?? "");
			if (!user || !valid) return redirect("/login?error=invalid");
			completeAuth(context).set("auth", { userId: user.id });
			return redirect("/");
		},
		signup(context) {
			if (context.get(Auth).ok) return redirect("/");
			return context.render(
				<AuthPage mode="signup" error={context.url.searchParams.get("error")} />,
			);
		},
		async signupSubmit(context) {
			let { email, password, name } = await readForm(context.request);
			if (!emailOk(email) || !passwordOk(password)) return redirect("/signup?error=weak");
			if (await db.query(users).where({ email }).first()) return redirect("/signup?error=exists");
			let user = await db.create(
				users,
				{ email, name, password_hash: await hashPassword(password), created_at: Date.now() },
				{ returnRow: true },
			);
			completeAuth(context).set("auth", { userId: user.id });
			return redirect("/");
		},
		logout(context) {
			context.get(Session).destroy();
			return redirect("/login");
		},
		googleStart(context) {
			return startExternalAuth(googleProvider(context.url), context);
		},
		async googleCallback(context) {
			let profile: GoogleProfile;
			try {
				let finished = await finishExternalAuth(googleProvider(context.url), context);
				profile = finished.result.profile as unknown as GoogleProfile;
			} catch {
				return redirect("/login?error=google");
			}
			let key = `google:${profile.id}`;
			let account = await db.query(accounts).where({ provider_key: key }).first();
			let userId = account?.user_id;
			if (userId === undefined) {
				let email = (profile.email ?? "").toLowerCase();
				if (!emailOk(email)) return redirect("/login?error=google");
				if (await db.query(users).where({ email }).first()) {
					return redirect("/login?error=email_taken");
				}
				let user = await db.create(
					users,
					{ email, name: (profile.name ?? "").slice(0, 100), password_hash: "", created_at: Date.now() },
					{ returnRow: true },
				);
				await db.create(accounts, {
					user_id: user.id,
					provider: "google",
					provider_key: key,
					created_at: Date.now(),
				});
				userId = user.id;
			}
			completeAuth(context).set("auth", { userId });
			return redirect("/");
		},
	},
});
