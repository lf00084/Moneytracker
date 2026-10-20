import { fld, GOOGLE } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";

const esc = (s: string) => s.replace(/[&<>"']/g, (ch) => `&#${ch.charCodeAt(0)};`);

/** Same look as the old `auth()` form, now with a real Google link and an error line. */
const form = (up: boolean, wide: boolean, error: string) =>
	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">${wide ? "" : '<div style="height:22px"></div>'}` +
	`<h1 class="t" style="margin-bottom:20px">${up ? "Sign up" : "Sign in"}</h1>` +
	`<a class="gbtn" href="/login/google">${GOOGLE}${up ? "Sign up with Google" : "Continue with Google"}</a><div class="or">or</div>` +
	(error ? `<div class="neg" role="alert" style="margin:0 0 14px;font-size:13px">${esc(error)}</div>` : "") +
	(up ? fld("Name", "", { name: "name", p: "Your name" }) : "") +
	fld("Email", "", { t: "email", name: "email", p: "you@email.com" }) +
	fld("Password", "", { t: "password", name: "password", p: "••••••••" }) +
	`<button class="btn full">${up ? "Create account" : "Sign in"}</button>` +
	`<div style="display:flex;justify-content:space-between;margin-top:16px"><a class="lnk" href="${up ? "/login" : "/signup"}">${
		up ? "I have an account" : "Create account"
	}</a></div></form>`;

const split = (up: boolean, error: string) =>
	`<div class="split"><div class="sl"><div style="font-weight:600">moneytracker</div><h2>Quiet<br>money.</h2><div class="lb" style="color:inherit;opacity:.6">earned · bought · owed · saved</div></div><div class="sr">${form(up, true, error)}</div></div>`;

export const loginPage = (error = "") =>
	page({ title: "Sign in", user: false, full: true, mobile: form(false, false, error), desktop: split(false, error) });

export const signupPage = (error = "") =>
	page({ title: "Sign up", user: false, full: true, mobile: form(true, false, error), desktop: split(true, error) });
