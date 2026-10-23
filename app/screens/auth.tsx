import { AuthLayout } from "../components/Layout.tsx";
import { GoogleMark, Logo } from "../components/Icon.tsx";
import { Field } from "../components/ui.tsx";
import { view } from "../components/view.ts";

/** Shared card for sign in and sign up. */
const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-center-wrap">
		<div class="auth-glass-box">
			<div class="auth-logo-center">
				<Logo href="/login" />
			</div>
			<h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1>
			<div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>
			<form class="au" method="post" action={up ? "/signup" : "/login"} data-rmx-document>
				<a class="gbtn" href="/login/google" data-rmx-document>
					<GoogleMark />
					<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
				</a>
				<div class="or">or</div>
				{error ? (
					<div class="auth-err-banner" role="alert">
						{error}
					</div>
				) : null}
				{up ? <Field label="Name" name="name" placeholder="Your name" /> : null}
				<Field label="Email" type="email" name="email" placeholder="you@email.com" />
				<Field label="Password" type="password" name="password" placeholder="••••••••" />
				<button class="btn full">{up ? "Create account" : "Sign in"}</button>
				<div class="auth-switch-wrap">
					<a class="lnk-switch" href={up ? "/login" : "/signup"} data-rmx-document>
						{up ? (
							<>
								Already have an account? <b>Sign in</b>
							</>
						) : (
							<>
								Don't have an account? <b>Create account</b>
							</>
						)}
					</a>
				</div>
			</form>
		</div>
	</div>
));

export const LoginScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker.">
		<AuthCard up={false} error={error} />
	</AuthLayout>
));

export const SignupScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals.">
		<AuthCard up error={error} />
	</AuthLayout>
));
