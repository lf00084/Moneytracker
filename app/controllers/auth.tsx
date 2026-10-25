import { finishExternalAuth, startExternalAuth } from "remix/auth"
import { createController } from "remix/router"
import { LoginScreen, SignupScreen } from "../screens.tsx"
import { env } from "../env.ts"
import * as act from "../lib/actions.ts"
import { googleProvider } from "../lib/auth.ts"
import { signInWithPassword, signUpWithPassword, upsertFromGoogle } from "../lib/users.ts"
import { routes } from "../routes.ts"
import { fail, formOf, go, signInAs, signOut, takeError, userOf, type Ctx } from "../request.ts"

export default createController(routes.auth, {
	actions: {
		login(ctx: Ctx) {
			if (userOf(ctx)) return go("/home")
			return ctx.render(<LoginScreen error={takeError(ctx)} />)
		},

		async signIn(ctx: Ctx) {
			const f = formOf(ctx)
			const user = await signInWithPassword(String(f.get("email") ?? ""), String(f.get("password") ?? ""))
			if (!user) return fail(ctx, "/login", "Wrong email or password.")
			signInAs(ctx, user.id)
			return go("/home")
		},

		signup(ctx: Ctx) {
			if (userOf(ctx)) return go("/home")
			return ctx.render(<SignupScreen error={takeError(ctx)} />)
		},

		async signUp(ctx: Ctx) {
			const f = formOf(ctx)
			const result = await signUpWithPassword({
				name: String(f.get("name") ?? ""),
				email: String(f.get("email") ?? ""),
				password: String(f.get("password") ?? ""),
			})
			if (!result.ok) return fail(ctx, "/signup", result.error)
			signInAs(ctx, result.user.id)
			return go("/home")
		},

		logout(ctx: Ctx) {
			signOut(ctx)
			return go("/login")
		},

		googleLogin(ctx: Ctx) {
			if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
				return fail(ctx, "/login", "Google login is not configured. Please sign in with email and password.")
			}
			return startExternalAuth(googleProvider, ctx as never, { returnTo: "/home" })
		},

		async googleCallback(ctx: Ctx) {
			try {
				const { result, returnTo } = await finishExternalAuth(googleProvider, ctx as never)
				const user = await upsertFromGoogle(result.account, result.profile as never)
				signInAs(ctx, user.id)
				return go(returnTo ?? "/home")
			} catch (err) {
				console.error("google sign-in failed", err)
				return fail(ctx, "/login", "Google sign-in failed. Try again.")
			}
		},

		async deleteAccount(ctx: Ctx) {
			const user = userOf(ctx)
			if (!user) return go("/login")
			await act.deleteAccount(user.id)
			signOut(ctx)
			return go("/signup")
		},
	},
})
