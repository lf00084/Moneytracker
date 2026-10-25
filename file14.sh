#!/usr/bin/env bash
set -e
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder"; exit 1; fi
if ! command -v bun >/dev/null 2>&1; then echo "bun not found"; exit 1; fi

B="../$(basename "$PWD")-backup-$(date +%Y%m%d-%H%M%S)"
if command -v zip >/dev/null 2>&1; then
  B="$B.zip"
  zip -qr "$B" . -x "node_modules/*" ".wrangler/*" ".git/*"
else
  B="$B.tar.gz"
  tar czf "$B" --exclude=node_modules --exclude=.wrangler --exclude=.git .
fi
echo "Backup: $B"

echo "Installing Pico CSS v2 from npm..."
bun add @picocss/pico

mkdir -p app/client
cat > "app/client/auth.css" << 'MT_EOF_14'
/* Sign in / Create account. Loaded after Pico (@picocss/pico) on /login and /signup only. */
/* Maps Pico's variables onto the app's own palette so light/dark follow html[data-theme]. */
html:root[data-theme] {
	--pico-font-family: var(--font-sys);
	--pico-font-size: 100%;
	--pico-border-radius: 12px;
	--pico-background-color: var(--bg);
	--pico-color: var(--ink);
	--pico-muted-color: var(--mu);
	--pico-muted-border-color: var(--ln);
	--pico-primary: var(--ac);
	--pico-primary-background: var(--ac);
	--pico-primary-border: var(--ac);
	--pico-primary-underline: var(--acl);
	--pico-primary-hover: var(--ink);
	--pico-primary-hover-background: var(--ac);
	--pico-primary-hover-border: var(--ac);
	--pico-primary-hover-underline: var(--ac);
	--pico-primary-focus: var(--acs);
	--pico-primary-inverse: var(--on);
	--pico-form-element-background-color: var(--s1);
	--pico-form-element-selected-background-color: var(--s2);
	--pico-form-element-border-color: var(--ln);
	--pico-form-element-color: var(--ink);
	--pico-form-element-placeholder-color: var(--mu);
	--pico-form-element-active-background-color: var(--s1);
	--pico-form-element-active-border-color: var(--ac);
	--pico-form-element-focus-color: var(--acs);
	--pico-form-element-invalid-border-color: var(--neg);
	--pico-form-element-invalid-active-border-color: var(--neg);
	--pico-form-element-invalid-focus-color: rgba(255, 90, 77, 0.2);
	--pico-form-element-spacing-vertical: 0.8rem;
	--pico-form-element-spacing-horizontal: 1rem;
	--pico-form-label-font-weight: 600;
	--pico-box-shadow: none;
	--pico-button-box-shadow: none;
	--pico-button-hover-box-shadow: none;
	--pico-text-selection-color: var(--acs);
}

body {
	font-family: var(--pico-font-family);
	font-size: 1rem;
	line-height: 1.5;
}

/* Layout: no card, just a centered column with a max width. */
.auth-main {
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100dvh;
	padding: clamp(1.5rem, 6vh, 3.5rem) 1rem;
}
.auth-wrap {
	width: 100%;
	max-width: 400px;
}
.auth-logo {
	display: flex;
	justify-content: center;
	margin-bottom: 1.75rem;
}
.auth-logo a {
	color: var(--ink);
	text-decoration: none;
}
.auth-wrap h1 {
	margin: 0 0 0.4rem;
	font-size: 1.75rem;
	font-weight: 700;
	letter-spacing: -0.03em;
	line-height: 1.2;
	text-align: center;
	color: var(--ink);
}
.auth-sub {
	margin: 0 0 1.75rem;
	text-align: center;
	font-size: 0.9rem;
	color: var(--mu);
}

/* Buttons */
.auth-wrap button[type="submit"],
.auth-wrap a[role="button"] {
	width: 100%;
	height: 3rem;
	margin: 0;
	padding: 0 1.25rem;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 0.6rem;
	font-size: 0.95rem;
	font-weight: 600;
	letter-spacing: -0.01em;
	text-decoration: none;
	transition: filter 0.15s ease, background-color 0.15s ease, border-color 0.15s ease, transform 0.12s ease;
}
.auth-wrap button[type="submit"]:hover {
	filter: brightness(1.07);
}
.auth-wrap button[type="submit"][aria-busy="true"],
.auth-wrap button[type="submit"][disabled] {
	opacity: 0.85;
	cursor: progress;
}
.auth-wrap a.auth-google[role="button"] {
	--pico-background-color: var(--s1);
	--pico-border-color: var(--ln);
	--pico-color: var(--ink);
	box-shadow: var(--sh1);
}
.auth-wrap a.auth-google[role="button"]:is(:hover, :active, :focus) {
	--pico-background-color: var(--s2);
	--pico-border-color: var(--ln);
	--pico-color: var(--ink);
}

/* Divider */
.auth-or {
	display: flex;
	align-items: center;
	gap: 0.75rem;
	margin: 1.25rem 0;
	font-size: 0.75rem;
	color: var(--mu);
}
.auth-or::before,
.auth-or::after {
	content: "";
	flex: 1;
	height: 1px;
	background: var(--ln);
}

/* Fields */
.auth-wrap form {
	margin: 0;
}
.auth-wrap .fld {
	position: relative;
	margin-bottom: 1rem;
}
.auth-wrap .fld label {
	margin: 0;
	font-size: 0.85rem;
	color: var(--ink);
}
.auth-wrap .fld input {
	height: 3rem;
	margin: 0.4rem 0 0;
	font-size: 1rem;
}
.auth-wrap .fld input.pw {
	padding-right: 3rem;
}
.auth-wrap .pw-toggle {
	position: absolute;
	right: 0;
	bottom: 0;
	width: 3rem;
	height: 3rem;
	margin: 0;
	padding: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	background: none;
	border: 0;
	border-radius: 0 12px 12px 0;
	color: var(--mu);
	box-shadow: none;
	cursor: pointer;
}
.auth-wrap .pw-toggle:hover {
	color: var(--ink);
}
.auth-wrap .pw-toggle:focus-visible {
	outline: 2px solid var(--ac);
	outline-offset: -2px;
}
.auth-wrap .pw-toggle span {
	display: flex;
}
.auth-wrap .pw-toggle .pw-off,
.auth-wrap .pw-toggle[aria-pressed="true"] .pw-on {
	display: none;
}
.auth-wrap .pw-toggle[aria-pressed="true"] .pw-off {
	display: flex;
}
.auth-wrap .submit-row {
	margin-top: 1.5rem;
}

/* Messages and footer link */
.auth-error {
	margin: 0 0 1.25rem;
	padding: 0.7rem 1rem;
	font-size: 0.875rem;
	font-weight: 500;
	text-align: center;
	color: var(--neg);
	background: rgba(255, 90, 77, 0.1);
	border: 1px solid rgba(255, 90, 77, 0.3);
	border-radius: 12px;
}
.auth-switch {
	margin: 1.5rem 0 0;
	text-align: center;
	font-size: 0.9rem;
	color: var(--mu);
}
.auth-switch a {
	font-weight: 600;
	color: var(--ac);
	text-decoration: none;
}
.auth-switch a:hover {
	text-decoration: underline;
	text-underline-offset: 3px;
}
MT_EOF_14
cat > ".mt_patch14.mjs" << 'MT_EOF_14'
// file14: Pico CSS v2 on the sign-in / create-account pages. Run from the Moneytracker folder.
import { readFileSync, writeFileSync } from "node:fs"

let failed = 0
const edit = (file, steps) => {
	let s = readFileSync(file, "utf8")
	for (const { done, find, replace, label } of steps) {
		if (s.includes(done)) {
			console.log(`  skip  ${file} (${label}) already applied`)
			continue
		}
		if (!s.includes(find)) {
			console.error(`  FAIL  ${file} (${label}) anchor not found`)
			failed++
			continue
		}
		s = s.replace(find, () => replace)
		console.log(`  ok    ${file} (${label})`)
	}
	writeFileSync(file, s)
}

// 1. static assets: Pico (from npm) + auth.css, served as one stylesheet
edit("app/lib/static.ts", [
	{
		label: "imports",
		done: "@picocss/pico",
		find: 'import js from "../client/app.js?raw"\n',
		replace: 'import js from "../client/app.js?raw"\nimport authCss from "../client/auth.css?raw"\nimport pico from "@picocss/pico/css/pico.min.css?raw"\n',
	},
	{
		label: "exports",
		done: "auth: hash(auth)",
		find: "export const files = { css, js }\n\nexport const V = { css: hash(css), js: hash(js) }",
		replace: "const auth = `${pico}\\n${authCss}`\n\nexport const files = { css, js, auth }\n\nexport const V = { css: hash(css), js: hash(js), auth: hash(auth) }",
	},
])

edit("app/routes.ts", [
	{
		label: "authCss route",
		done: "authCss:",
		find: '\t\tjs: get("/assets/app.js"),\n',
		replace: '\t\tjs: get("/assets/app.js"),\n\t\tauthCss: get("/assets/auth.css"),\n',
	},
])

edit("app/controllers/assets.ts", [
	{
		label: "authCss action",
		done: "authCss:",
		find: '\t\tjs: file(files.js, "application/javascript; charset=utf-8"),\n',
		replace: '\t\tjs: file(files.js, "application/javascript; charset=utf-8"),\n\t\tauthCss: file(files.auth, "text/css; charset=utf-8"),\n',
	},
])

// 2. layout: auth pages load Pico; no clock, no theme button
edit("app/components/layout.tsx", [
	{
		label: "Document prop type",
		done: "auth?: boolean",
		find: "\tpath?: string\n\tchildren?: RemixNode\n}\n\nconst THEME_BOOT",
		replace: "\tpath?: string\n\tauth?: boolean\n\tchildren?: RemixNode\n}\n\nconst THEME_BOOT",
	},
	{
		label: "Document args",
		done: "path, auth, children",
		find: "({ title, user = true, theme, desc, path, children }) => {",
		replace: "({ title, user = true, theme, desc, path, auth, children }) => {",
	},
	{
		label: "auth stylesheet link",
		done: "/assets/auth.css",
		find: '<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />\n',
		replace: '<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />\n\t\t\t\t{auth ? <link rel="stylesheet" href={`/assets/auth.css?v=${V.auth}`} /> : null}\n',
	},
	{
		label: "AuthLayout",
		done: '<main class="auth-main">',
		find: `	<Document title={title} path={path} desc={desc} user={false}>
		<div class="app">
			<div class="tf-clock">
				<ClockWidget />
				<button type="button" class="ib" data-theme-toggle aria-label="Theme">
					<ThemeIcons />
				</button>
			</div>
			<main class="auth-viewport">{children}</main>
		</div>
	</Document>`,
		replace: `	<Document title={title} path={path} desc={desc} user={false} auth>
		<div class="app">
			<main class="auth-main">{children}</main>
		</div>
	</Document>`,
	},
])

// 3. eye-off icon for the password toggle
edit("app/components/ui.tsx", [
	{
		label: "eyeoff icon",
		done: "eyeoff:",
		find: `	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',\n`,
		replace: `	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
	eyeoff: '<path d="M3 3l18 18M10.6 6.1A9.8 9.8 0 0 1 12 6c6 0 10 6 10 6a17 17 0 0 1-3.2 3.9M6.6 7.6A17 17 0 0 0 2 12s4 7 10 7a9.6 9.6 0 0 0 4.2-1M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',\n`,
	},
])

// 4. the auth screens
{
	const file = "app/screens.tsx"
	let s = readFileSync(file, "utf8")
	if (s.includes("const AuthField")) {
		console.log(`  skip  ${file} (auth screens) already applied`)
	} else {
		const oldImport = 'import { ErrorBanner, Field, GoogleMark, Logo, PageHeader, Section, view } from "./components/ui.tsx"'
		const start = s.indexOf("const AuthCard = view<")
		const end = s.indexOf("export const LoginScreen")
		if (!s.includes(oldImport) || start < 0 || end < start) {
			console.error(`  FAIL  ${file} (auth screens) anchor not found`)
			failed++
		} else {
			const card = `type AuthFieldProps = { label: string; name: string; type?: string; placeholder?: string; autocomplete: string; password?: boolean; minlength?: number }

const AuthField = view<AuthFieldProps>(({ label, name, type = "text", placeholder = "", autocomplete, password = false, minlength }) => (
	<div class="fld">
		<label>
			{label}
			<input class={password ? "pw" : undefined} name={name} type={type} placeholder={placeholder} autocomplete={autocomplete} autocapitalize="none" spellcheck="false" required minlength={minlength} />
		</label>
		{password ? (
			<button type="button" class="pw-toggle" data-pw aria-label="Show password" aria-pressed="false">
				<span class="pw-on">
					<Icon name="eye" />
				</span>
				<span class="pw-off">
					<Icon name="eyeoff" />
				</span>
			</button>
		) : null}
	</div>
))

const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-wrap">
		<div class="auth-logo">
			<Logo href="/login" />
		</div>
		<h1>{up ? "Create account" : "Sign in"}</h1>
		<p class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</p>
		<a class="auth-google" role="button" href="/login/google">
			<GoogleMark />
			<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
		</a>
		<div class="auth-or" role="separator">
			or
		</div>
		{error ? (
			<p class="auth-error" role="alert">
				{error}
			</p>
		) : null}
		<form method="post" action={up ? "/signup" : "/login"}>
			{up ? <AuthField label="Name" name="name" placeholder="Your name" autocomplete="name" /> : null}
			<AuthField label="Email" name="email" type="email" placeholder="you@email.com" autocomplete="email" />
			<AuthField label="Password" name="password" type="password" placeholder="••••••••" autocomplete={up ? "new-password" : "current-password"} password minlength={up ? 8 : undefined} />
			<div class="submit-row">
				<button type="submit">{up ? "Create account" : "Sign in"}</button>
			</div>
		</form>
		<p class="auth-switch">
			{up ? (
				<>
					Already have an account? <a href="/login">Sign in</a>
				</>
			) : (
				<>
					Don't have an account? <a href="/signup">Create account</a>
				</>
			)}
		</p>
	</div>
))

`
			s = s.slice(0, start) + card + s.slice(end)
			s = s.replace(oldImport, 'import { ErrorBanner, GoogleMark, Icon, Logo, PageHeader, Section, view } from "./components/ui.tsx"')
			writeFileSync(file, s)
			console.log(`  ok    ${file} (auth screens)`)
		}
	}
}

// 5. client js: password show/hide, Pico busy spinner on submit
edit("app/client/app.js", [
	{
		label: "password toggle",
		done: "[data-pw]",
		find: '\t\tif ((q = t.closest("[data-eye]"))) {',
		replace: `		if ((q = t.closest("[data-pw]"))) {
			var pwi = q.parentNode.querySelector("input")
			if (pwi) {
				var pwShow = pwi.type === "password"
				pwi.type = pwShow ? "text" : "password"
				q.setAttribute("aria-pressed", pwShow ? "true" : "false")
				q.setAttribute("aria-label", pwShow ? "Hide password" : "Show password")
			}
			return
		}
		if ((q = t.closest("[data-eye]"))) {`,
	},
	{
		label: "busy spinner on",
		done: 'b.setAttribute("aria-busy"',
		find: '\t\t\t\t\tb.setAttribute("data-busy", "1")\n',
		replace: '\t\t\t\t\tb.setAttribute("data-busy", "1")\n\t\t\t\t\tif (b.type === "submit") b.setAttribute("aria-busy", "true")\n',
	},
	{
		label: "busy spinner off",
		done: 'b.removeAttribute("aria-busy")',
		find: '\t\t\tb.removeAttribute("data-busy")\n',
		replace: '\t\t\tb.removeAttribute("data-busy")\n\t\t\tb.removeAttribute("aria-busy")\n',
	},
])

// 6. app.css: drop the old card / clock / auth rules that auth.css and Pico replace
{
	const file = "app/client/app.css"
	let s = readFileSync(file, "utf8")
	const before = s
	s = s.replace(",.hero,.auth-glass-box{", ",.hero{")
	s = s.replace(/@media\(max-width:480px\)\{\n\t\.auth-glass-box\{[^\n]*\}\n\}\n/, "")
	s = s
		.split("\n")
		.filter((l) => !/^(\.tf-clock|\.auth-|\.lnk-switch|\.gbtn|\.or[:{,]|\.au \.or)/.test(l))
		.join("\n")
	if (s === before) console.log(`  skip  ${file} (old auth css) already removed`)
	else {
		writeFileSync(file, s)
		console.log(`  ok    ${file} (old auth css removed)`)
	}
}

if (failed) {
	console.error(`\n${failed} patch step(s) failed. Your files differ from the version this script expects; nothing was reverted. Restore from the backup zip and send me the folder.`)
	process.exit(1)
}
MT_EOF_14
echo "Applying changes..."
if ! bun .mt_patch14.mjs; then rm -f .mt_patch14.mjs; exit 1; fi
rm -f .mt_patch14.mjs

echo "Typecheck..."
bun run typecheck || echo "Typecheck printed issues above. Send them to me."
echo "Done. Start it with: bun run dev   (then open /login and /signup)"
