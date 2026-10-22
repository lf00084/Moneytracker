import { fld, GOOGLE, logo } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";
const esc = (s: string) => s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);
const form = (up: boolean, error: string) =>
	`<div class="auth-center-wrap">` +
	`<div class="auth-glass-box">` +
	`<div class="auth-logo-center">${logo("/login")}</div>` +
	`<h1 class="auth-title">${up ? "Create account" : "Sign in"}</h1>` +
	`<div class="auth-sub">${up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>` +
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">` +
	`<a class="gbtn" href="/login/google">${GOOGLE}<span>${up ? "Sign up with Google" : "Continue with Google"}</span></a>` +
	`<div class="or">or</div>` +
	(error ? `<div class="auth-err-banner" role="alert">${esc(error)}</div>` : "") +
	(up ? fld("Name", "", { name: "name", p: "Your name" }) : "") +
	fld("Email", "", { t: "email", name: "email", p: "you@email.com" }) +
	fld("Password", "", { t: "password", name: "password", p: "••••••••" }) +
	`<button class="btn full">${up ? "Create account" : "Sign in"}</button>` +
	`<div class="auth-switch-wrap"><a class="lnk-switch" href="${up ? "/login" : "/signup"}">${
		up ? "Already have an account? <b>Sign in</b>" : "Don't have an account? <b>Create account</b>"
	}</a></div>` +
	`</form>` +
	`</div>` +
	`</div>`;
export const loginPage = (error = "") =>
	page({ title: "Sign in", path: "/login", desc: "Sign in to Moneytracker, your quiet personal money tracker.", user: false, full: true, mobile: form(false, error), desktop: form(false, error) });
export const signupPage = (error = "") =>
	page({ title: "Create account", path: "/signup", desc: "Create a free Moneytracker account and start tracking your spending, debts and goals.", user: false, full: true, mobile: form(true, error), desktop: form(true, error) });
