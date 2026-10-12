import type { Handle } from "remix/component";

import type { User } from "../utils/auth.ts";

import { Layout } from "./layout.tsx";

const messages: Record<string, string> = {
	invalid: "Wrong email or password.",
	exists: "An account with this email already exists.",
	weak: "Use a valid email and a password of 8 to 128 characters.",
	email_taken: "This email already has a password account. Log in with your password.",
	google: "Google sign-in failed. Try again.",
};

export function AuthPage(handle: Handle<{ mode: "login" | "signup"; error: string | null }>) {
	return () => {
		let { mode, error } = handle.props;
		let login = mode === "login";
		let message = error ? messages[error] : undefined;

		return (
			<Layout>
				<h1>{login ? "Log in bach t7seb flosk" : "Create account"}</h1>
				{message ? <p role="alert">{message}</p> : null}
				<form method="post" action={login ? "/login" : "/signup"}>
					{login ? null : (
						<label>
							Name
							<input type="text" name="name" />
						</label>
					)}
					<label>
						Email
						<input type="email" name="email" required />
					</label>
					<label>
						Password
						<input type="password" name="password" required minLength={8} />
					</label>
					<button type="submit">{login ? "Log in" : "Sign up"}</button>
				</form>
				<p>
					<a href="/auth/google">Continue with Google</a>
				</p>
				<p>
					{login ? <a href="/signup">Create an account</a> : <a href="/login">I already have an account</a>}
				</p>
			</Layout>
		);
	};
}

export function HomePage(handle: Handle<{ user: User }>) {
	return () => {
		let { user } = handle.props;

		return (
			<Layout>
				<h1>Hello, {user.name || user.email}</h1>
				<p>{user.email}</p>
				<form method="post" action="/logout">
					<button type="submit">Log out</button>
				</form>
			</Layout>
		);
	};
}
