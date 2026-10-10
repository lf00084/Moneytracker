import type { Client } from "@libsql/client/web";
import type { RemixNode } from "remix/component";
import type { Middleware, RequestContext } from "remix/router";
import { createClient } from "@libsql/client/web";
import { completeAuth, createGoogleAuthProvider, finishExternalAuth, startExternalAuth } from "remix/auth";
import { renderToStream } from "remix/component/server";
import { createCookie } from "remix/cookie";
import { csrf, getCsrfToken } from "remix/middleware/csrf";
import { formData } from "remix/middleware/form-data";
import { renderWith } from "remix/middleware/render";
import { session } from "remix/middleware/session";
import { createHtmlResponse } from "remix/response/html";
import { createAction, createRouter } from "remix/router";
import { get, post, route } from "remix/routes";
import { createCookieSessionStorage } from "remix/session-storage/cookie";

export interface Env {
  TURSO_DATABASE_URL: string;
  TURSO_AUTH_TOKEN: string;
  GOOGLE_CLIENT_ID: string;
  GOOGLE_CLIENT_SECRET: string;
  SESSION_SECRET: string;
  APP_URL: string;
}

type Arg = string | number | null;
interface User { id: string; name: string; email: string; picture: string | null }
interface Settings { timezone: string; dayStartHour: number; goalMode: "kept" | "earned"; filledDisplay: "locked" | "done" | "hidden" }
interface Goal { name: string; reason: string; targetCents: number }
interface Src { id: string; name: string; cents: number | null }
interface Sess { get(key: string): unknown; set(key: string, value: unknown): void; flash(key: string, value: unknown): void; destroy(): void }
type Data = Awaited<ReturnType<typeof load>>;

const routes = route({
  home: get("/"),
  api: get("/api/home"),
  login: get("/auth/google"),
  callback: get("/auth/google/callback"),
  logout: post("/logout"),
  goal: post("/goal"),
  sourceAdd: post("/sources"),
  sourceDelete: post("/sources/delete"),
  entry: post("/entries"),
  settings: get("/settings"),
  settingsSave: post("/settings"),
  accountDelete: post("/account/delete"),
});

const GOAL_MODES = ["kept", "earned"] as const;
const DISPLAYS = ["done", "locked", "hidden"] as const;
const nf = new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const fmt = (c: number) => nf.format(c / 100);
const plain = (c: number) => (c / 100).toFixed(2);

function pick<T extends string>(v: unknown, allowed: readonly T[], fallback: T): T {
  return allowed.find((a) => a === v) ?? fallback;
}

function text(v: unknown, max: number) {
  return String(v ?? "").trim().slice(0, max);
}

function toCents(v: unknown) {
  let s = String(v ?? "").trim().replace(",", ".");
  return /^\d{1,9}(\.\d{1,2})?$/.test(s) ? Math.round(Number(s) * 100) : null;
}

function validZone(z: string) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: z });
    return true;
  } catch {
    return false;
  }
}

function zones() {
  let list: string[] = [];
  try {
    list = Intl.supportedValuesOf("timeZone");
  } catch {}
  return list.includes("UTC") ? list : ["UTC", ...list];
}

function dayOf(now: Date, zone: string, startHour: number) {
  return new Intl.DateTimeFormat("en-CA", { timeZone: zone, year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date(now.getTime() - startHour * 3600000));
}

const sess = (ctx: RequestContext): Sess => Reflect.get(ctx, "session");
const form = (ctx: RequestContext): FormData => Reflect.get(ctx, "formData");
const go = (path: string) => new Response(null, { status: 303, headers: { Location: path } });

function flashes(ctx: RequestContext) {
  let s = sess(ctx);
  let n = s.get("notice");
  let e = s.get("error");
  return { notice: typeof n === "string" ? n : undefined, error: typeof e === "string" ? e : undefined };
}

const openDb = (env: Env) => createClient({ url: env.TURSO_DATABASE_URL, authToken: env.TURSO_AUTH_TOKEN });

async function userOf(ctx: RequestContext, db: Client): Promise<User | null> {
  let a = sess(ctx).get("auth");
  if (typeof a !== "object" || a === null) return null;
  let id = Reflect.get(a, "userId");
  if (typeof id !== "string") return null;
  let r = (await db.execute({ sql: "SELECT id, name, email, picture FROM users WHERE id = ?", args: [id] })).rows[0];
  return r ? { id: String(r.id), name: String(r.name), email: String(r.email), picture: r.picture == null ? null : String(r.picture) } : null;
}

function store(db: Client, uid: string) {
  const one = async (sql: string, args: Arg[]) => (await db.execute({ sql, args })).rows[0];
  return {
    async settings(): Promise<Settings> {
      let r = await one("SELECT * FROM settings WHERE user_id = ?", [uid]);
      let zone = r ? String(r.timezone) : "UTC";
      return {
        timezone: validZone(zone) ? zone : "UTC",
        dayStartHour: r ? Number(r.day_start_hour) : 0,
        goalMode: pick(r?.goal_mode, GOAL_MODES, "kept"),
        filledDisplay: pick(r?.filled_display, DISPLAYS, "done"),
      };
    },
    async saveSettings(name: string, s: Settings) {
      await db.batch([
        { sql: "UPDATE users SET name = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", args: [name, uid] },
        {
          sql: "INSERT INTO settings (user_id, timezone, day_start_hour, goal_mode, filled_display) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET timezone = excluded.timezone, day_start_hour = excluded.day_start_hour, goal_mode = excluded.goal_mode, filled_display = excluded.filled_display",
          args: [uid, s.timezone, s.dayStartHour, s.goalMode, s.filledDisplay],
        },
      ], "write");
    },
    async goal(): Promise<Goal | null> {
      let r = await one("SELECT name, reason, target_cents FROM goals WHERE user_id = ?", [uid]);
      return r ? { name: String(r.name), reason: String(r.reason), targetCents: Number(r.target_cents) } : null;
    },
    async saveGoal(g: Goal) {
      await db.execute({
        sql: "INSERT INTO goals (user_id, name, reason, target_cents) VALUES (?, ?, ?, ?) ON CONFLICT(user_id) DO UPDATE SET name = excluded.name, reason = excluded.reason, target_cents = excluded.target_cents",
        args: [uid, g.name, g.reason, g.targetCents],
      });
    },
    async sources(day: string): Promise<Src[]> {
      let r = await db.execute({
        sql: "SELECT s.id, s.name, e.amount_cents AS cents FROM sources s LEFT JOIN daily_entries e ON e.source_id = s.id AND e.user_id = s.user_id AND e.date = ? WHERE s.user_id = ? AND s.type = 'manual' ORDER BY s.created_at, s.name",
        args: [day, uid],
      });
      return r.rows.map((x) => ({ id: String(x.id), name: String(x.name), cents: x.cents == null ? null : Number(x.cents) }));
    },
    async addSource(name: string) {
      let r = await db.execute({ sql: "INSERT OR IGNORE INTO sources (id, user_id, name, type) VALUES (?, ?, ?, 'manual')", args: [crypto.randomUUID(), uid, name] });
      return r.rowsAffected > 0;
    },
    async deleteSource(id: string) {
      await db.batch([
        { sql: "DELETE FROM daily_entries WHERE user_id = ? AND source_id = ?", args: [uid, id] },
        { sql: "DELETE FROM sources WHERE user_id = ? AND id = ?", args: [uid, id] },
      ], "write");
    },
    async saveEntry(sourceId: string, day: string, cents: number) {
      let r = await db.execute({
        sql: "INSERT INTO daily_entries (id, user_id, source_id, date, amount_cents, origin) SELECT ?, ?, id, ?, ?, 'manual' FROM sources WHERE id = ? AND user_id = ? AND type = 'manual' ON CONFLICT(user_id, source_id, date) DO UPDATE SET amount_cents = excluded.amount_cents",
        args: [crypto.randomUUID(), uid, day, cents, sourceId, uid],
      });
      return r.rowsAffected > 0;
    },
    async totals(day: string) {
      let r = await one("SELECT COALESCE(SUM(amount_cents), 0) AS total, COALESCE(SUM(CASE WHEN date = ? THEN amount_cents ELSE 0 END), 0) AS today FROM daily_entries WHERE user_id = ?", [day, uid]);
      return { total: Number(r?.total ?? 0), today: Number(r?.today ?? 0) };
    },
    async wipe() {
      await db.batch([
        { sql: "DELETE FROM daily_entries WHERE user_id = ?", args: [uid] },
        { sql: "DELETE FROM sources WHERE user_id = ?", args: [uid] },
        { sql: "DELETE FROM goals WHERE user_id = ?", args: [uid] },
        { sql: "DELETE FROM settings WHERE user_id = ?", args: [uid] },
        { sql: "DELETE FROM users WHERE id = ?", args: [uid] },
      ], "write");
    },
  };
}

async function load(db: Client, uid: string) {
  let st = store(db, uid);
  let settings = await st.settings();
  let day = dayOf(new Date(), settings.timezone, settings.dayStartHour);
  let [goal, sources, totals] = await Promise.all([st.goal(), st.sources(day), st.totals(day)]);
  let spent = 0;
  let kept = totals.total - spent;
  let basis = settings.goalMode === "earned" ? totals.total : kept;
  let target = goal ? goal.targetCents : 0;
  return { settings, goal, sources, day, earned: totals.total, earnedToday: totals.today, spentToday: 0, kept, basis, left: Math.max(0, target - basis) };
}

const css = `:root{--bg:#f4f6f4;--card:#fff;--ink:#14201a;--mut:#6b7a72;--line:#e2e8e4;--acc:#0f9d58;--soft:#e4f4ea;--bad:#d93025}
@media (prefers-color-scheme:dark){:root{--bg:#0d1210;--card:#151c18;--ink:#eaf1ec;--mut:#8a9a91;--line:#25312a;--acc:#34c27a;--soft:#16261d;--bad:#ff6b5e}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.45 system-ui,sans-serif;padding-bottom:5.5rem}
a{color:var(--acc)}
.top{max-width:30rem;margin:0 auto;padding:1rem 1rem 0;display:flex;align-items:center;gap:.6rem}
.top b{font-size:1.05rem;flex:1}
.top img{width:2rem;height:2rem;border-radius:50%;object-fit:cover}
.top form{margin:0}
main{max-width:30rem;margin:0 auto;padding:1rem;display:grid;gap:.9rem}
.card{background:var(--card);border:1px solid var(--line);border-radius:1.1rem;padding:1rem 1.1rem}
.card h2{margin:0 0 .6rem;font-size:1rem}
.hero{text-align:center;padding:1.4rem 1.1rem}
.label{margin:0;color:var(--mut);font-size:.8rem;text-transform:uppercase;letter-spacing:.04em}
.big{margin:.2rem 0 0;font-size:3rem;font-weight:800;line-height:1.1;letter-spacing:-.02em}
.sub{margin:0 0 .9rem;color:var(--mut)}
.muted{color:var(--mut);font-size:.9rem;margin:.5rem 0 0}
.reason{margin:.4rem 0 0;font-size:.9rem}
.stats{display:grid;grid-template-columns:1fr 1fr;gap:.9rem}
.num{margin:.2rem 0 0;font-size:1.35rem;font-weight:700}
progress{appearance:none;-webkit-appearance:none;width:100%;height:.65rem;border:0;border-radius:99px;background:var(--line);overflow:hidden;display:block}
progress::-webkit-progress-bar{background:var(--line)}
progress::-webkit-progress-value{background:var(--acc);border-radius:99px}
progress::-moz-progress-bar{background:var(--acc)}
.row{display:flex;align-items:center;gap:.6rem;flex-wrap:wrap;padding:.5rem 0;border-top:1px solid var(--line)}
.row:first-of-type{border-top:0}
.row form{display:contents}
.name{flex:1;font-weight:600;min-width:5rem}
.amt{font-weight:700}
.row input{width:7rem;flex:0 0 7rem}
input,select,textarea{font:inherit;width:100%;padding:.65rem .8rem;border:1px solid var(--line);border-radius:.8rem;background:var(--bg);color:inherit}
label{display:block;font-weight:600;font-size:.9rem}
label input,label select,label textarea{margin-top:.3rem;font-weight:400}
.stack{display:grid;gap:.8rem}
button,.btn{font:inherit;font-weight:600;padding:.6rem 1rem;border-radius:.8rem;border:1px solid var(--line);background:var(--card);color:var(--ink);cursor:pointer;text-decoration:none;display:inline-block;text-align:center}
.primary{background:var(--acc);border-color:var(--acc);color:#fff}
.danger{background:var(--bad);border-color:var(--bad);color:#fff}
.ghost{background:none;border:0;color:var(--mut);padding:.3rem .5rem}
details{width:100%}
summary{cursor:pointer;color:var(--acc);font-weight:600;font-size:.9rem;padding:.3rem 0}
details form{margin-top:.5rem;display:flex;gap:.6rem}
details form input{flex:1}
.alert{padding:.7rem .9rem;border-radius:.9rem;border:1px solid var(--acc);background:var(--soft);margin:0}
.alert.bad{border-color:var(--bad);background:none;color:var(--bad)}
.tabs{position:fixed;left:0;right:0;bottom:0;display:flex;justify-content:center;gap:.5rem;padding:.5rem .5rem calc(.5rem + env(safe-area-inset-bottom));background:var(--card);border-top:1px solid var(--line)}
.tabs a{flex:1;max-width:11rem;text-align:center;padding:.6rem;border-radius:.8rem;color:var(--mut);text-decoration:none;font-weight:600}
.tabs a.on{background:var(--soft);color:var(--acc)}
.landing{text-align:center;padding:3rem 1rem}
.landing h1{font-size:2rem;line-height:1.15;margin:0 0 .8rem}
.landing p{color:var(--mut);margin:0 0 1.5rem}`;

const csrfField = (t: string) => <input type="hidden" name="_csrf" value={t} />;

function shell(o: { title: string; user: User | null; token: string; tab?: "home" | "settings"; notice?: string; error?: string }, body: RemixNode) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{o.title}</title>
        <style>{css}</style>
      </head>
      <body>
        {o.user ? (
          <div class="top">
            <b>Money goal</b>
            {o.user.picture ? <img src={o.user.picture} alt="" /> : null}
            <form method="post" action="/logout">
              {csrfField(o.token)}
              <button type="submit" class="ghost">Log out</button>
            </form>
          </div>
        ) : null}
        <main>
          {o.notice ? <p class="alert">{o.notice}</p> : null}
          {o.error ? <p class="alert bad">{o.error}</p> : null}
          {body}
        </main>
        {o.user ? (
          <nav class="tabs">
            <a href="/" class={o.tab === "home" ? "on" : ""}>Home</a>
            <a href="/settings" class={o.tab === "settings" ? "on" : ""}>Settings</a>
          </nav>
        ) : null}
      </body>
    </html>
  );
}

function landing() {
  return (
    <section class="landing">
      <h1>Know exactly how much is left to your goal</h1>
      <p>Log what you earn each day. Keep one number in front of you.</p>
      <a href="/auth/google" class="btn primary">Sign in with Google</a>
    </section>
  );
}

function goalForm(goal: Goal | null, t: string, title: string) {
  return (
    <section class="card">
      <h2>{title}</h2>
      <form method="post" action="/goal" class="stack">
        {csrfField(t)}
        <label>Goal name<input name="name" value={goal?.name ?? ""} required maxLength={60} placeholder="New laptop" /></label>
        <label>Why it matters<input name="reason" value={goal?.reason ?? ""} maxLength={200} placeholder="Work faster and earn more" /></label>
        <label>Target amount<input name="target" value={goal ? plain(goal.targetCents) : ""} required inputMode="decimal" placeholder="1500.00" /></label>
        <button type="submit" class="primary">Save goal</button>
      </form>
    </section>
  );
}

function editEntry(s: Src, t: string) {
  return (
    <details>
      <summary>Edit</summary>
      <form method="post" action="/entries">
        {csrfField(t)}
        <input type="hidden" name="source_id" value={s.id} />
        <input name="amount" value={plain(s.cents ?? 0)} required inputMode="decimal" aria-label={s.name} />
        <button type="submit" class="primary">Save</button>
      </form>
    </details>
  );
}

function addSourceForm(t: string) {
  return (
    <details>
      <summary>+ Add source</summary>
      <form method="post" action="/sources">
        {csrfField(t)}
        <input name="name" required maxLength={60} placeholder="Uber, Freelance, Shop" aria-label="Source name" />
        <button type="submit" class="primary">Add</button>
      </form>
    </details>
  );
}

function homeView(d: Data, t: string) {
  let pending = d.sources.filter((s) => s.cents === null);
  let filled = d.sources.filter((s) => s.cents !== null);
  let display = d.settings.filledDisplay;
  let label = d.settings.goalMode === "earned" ? "earned" : "kept";
  return (
    <>
      {d.goal ? (
        <section class="card hero">
          <p class="label">{d.goal.name}</p>
          <p class="big">{fmt(d.left)}</p>
          <p class="sub">left to goal</p>
          <progress value={Math.max(0, Math.min(d.basis, d.goal.targetCents))} max={d.goal.targetCents}></progress>
          <p class="muted">{fmt(d.basis)} {label} of {fmt(d.goal.targetCents)}</p>
          {d.goal.reason ? <p class="reason">{d.goal.reason}</p> : null}
        </section>
      ) : (
        goalForm(null, t, "Set your goal")
      )}
      <div class="stats">
        <div class="card"><p class="label">Earned today</p><p class="num">{fmt(d.earnedToday)}</p></div>
        <div class="card"><p class="label">Spent today</p><p class="num">{fmt(d.spentToday)}</p></div>
      </div>
      <section class="card">
        <h2>Fill today</h2>
        {d.sources.length === 0 ? <p class="muted">Add a source of income to start.</p> : null}
        {pending.map((s) => (
          <div class="row" key={s.id}>
            <form method="post" action="/entries">
              {csrfField(t)}
              <input type="hidden" name="source_id" value={s.id} />
              <span class="name">{s.name}</span>
              <input name="amount" required inputMode="decimal" placeholder="0.00" aria-label={s.name} />
              <button type="submit" class="primary">Save</button>
            </form>
          </div>
        ))}
        {display === "locked" ? filled.map((s) => (
          <div class="row" key={s.id}>
            <span class="name">{s.name}</span>
            <span class="amt">{fmt(s.cents ?? 0)}</span>
            {editEntry(s, t)}
          </div>
        )) : null}
        {d.sources.length > 0 && pending.length === 0 ? <p class="muted">All filled for today.</p> : null}
        {addSourceForm(t)}
      </section>
      {display === "done" && filled.length > 0 ? (
        <section class="card">
          <h2>Done</h2>
          {filled.map((s) => (
            <div class="row" key={s.id}>
              <span class="name">{s.name}</span>
              <span class="amt">{fmt(s.cents ?? 0)}</span>
              {editEntry(s, t)}
            </div>
          ))}
        </section>
      ) : null}
    </>
  );
}

function settingsView(d: Data, user: User, t: string) {
  let s = d.settings;
  return (
    <>
      <section class="card">
        <h2>Profile and day</h2>
        <form method="post" action="/settings" class="stack">
          {csrfField(t)}
          <label>Name<input name="name" value={user.name} required maxLength={80} /></label>
          <label>Timezone
            <select name="timezone">
              {zones().map((z) => <option key={z} value={z} selected={z === s.timezone}>{z}</option>)}
            </select>
          </label>
          <label>Your day starts at
            <select name="day_start_hour">
              {Array.from({ length: 24 }, (_, h) => <option key={h} value={String(h)} selected={h === s.dayStartHour}>{String(h).padStart(2, "0")}:00</option>)}
            </select>
          </label>
          <label>Goal counts
            <select name="goal_mode">
              <option value="kept" selected={s.goalMode === "kept"}>Kept (earned minus spent)</option>
              <option value="earned" selected={s.goalMode === "earned"}>Earned only</option>
            </select>
          </label>
          <label>After a source is filled
            <select name="filled_display">
              <option value="done" selected={s.filledDisplay === "done"}>Move to the done list</option>
              <option value="locked" selected={s.filledDisplay === "locked"}>Keep it locked in place</option>
              <option value="hidden" selected={s.filledDisplay === "hidden"}>Hide it</option>
            </select>
          </label>
          <button type="submit" class="primary">Save settings</button>
        </form>
        <p class="muted">Today for you is {d.day}. Signed in as {user.email}.</p>
      </section>
      {goalForm(d.goal, t, d.goal ? "Goal" : "Set your goal")}
      <section class="card">
        <h2>Sources</h2>
        {d.sources.length === 0 ? <p class="muted">No sources yet.</p> : null}
        {d.sources.map((x) => (
          <div class="row" key={x.id}>
            <span class="name">{x.name}</span>
            <form method="post" action="/sources/delete">
              {csrfField(t)}
              <input type="hidden" name="source_id" value={x.id} />
              <button type="submit" class="ghost">Delete</button>
            </form>
          </div>
        ))}
        {addSourceForm(t)}
      </section>
      <section class="card">
        <h2>Delete account</h2>
        <form method="post" action="/account/delete" class="stack">
          {csrfField(t)}
          <label>Type DELETE to remove your account and all its data<input name="confirm" autoComplete="off" placeholder="DELETE" /></label>
          <button type="submit" class="danger">Delete my account</button>
        </form>
      </section>
    </>
  );
}

function googleProvider(env: Env) {
  return createGoogleAuthProvider({
    clientId: env.GOOGLE_CLIENT_ID,
    clientSecret: env.GOOGLE_CLIENT_SECRET,
    redirectUri: new URL("/auth/google/callback", env.APP_URL),
  });
}

function firstString(...values: unknown[]) {
  for (let v of values) if (typeof v === "string" && v !== "") return v;
  return null;
}

export default function application(env: Env) {
  let cookie = createCookie("__session", { secrets: [env.SESSION_SECRET], httpOnly: true, sameSite: "Lax", maxAge: 60 * 60 * 24 * 30 });
  let middleware: Middleware[] = [
    session(cookie, createCookieSessionStorage()) as Middleware,
    formData() as Middleware,
    csrf({ origin: env.APP_URL }) as Middleware,
    renderWith(createHtmlRenderer) as Middleware,
  ];
  let router = createRouter({ middleware, defaultHandler: notFound(env) });

  router.map(routes.home, createAction(routes.home, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    let t = getCsrfToken(ctx);
    let fl = flashes(ctx);
    if (!user) return ctx.render(shell({ title: "Money goal", user: null, token: t, ...fl }, landing()));
    let d = await load(db, user.id);
    return ctx.render(shell({ title: "Home", user, token: t, tab: "home", ...fl }, homeView(d, t)));
  }));

  router.map(routes.api, createAction(routes.api, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return Response.json({ error: "unauthorized" }, { status: 401 });
    let d = await load(db, user.id);
    return Response.json({
      day: d.day,
      goal: d.goal,
      earnedCents: d.earned,
      keptCents: d.kept,
      leftCents: d.left,
      earnedTodayCents: d.earnedToday,
      sources: d.sources.map((s) => ({ id: s.id, name: s.name, todayCents: s.cents })),
    });
  }));

  router.map(routes.login, createAction(routes.login, (ctx) => startExternalAuth(googleProvider(env), ctx, { returnTo: "/" })));

  router.map(routes.callback, createAction(routes.callback, async (ctx) => {
    try {
      let { result, returnTo } = await finishExternalAuth(googleProvider(env), ctx);
      let profile: Record<string, unknown> = Object(result.profile ?? {});
      let account: Record<string, unknown> = Object(result.account ?? {});
      let googleId = firstString(profile.sub, profile.id, account.id, account.subject);
      let email = firstString(profile.email);
      if (!googleId || !email) throw new Error("Google did not return an id and email");
      let name = firstString(profile.name, profile.given_name, email.split("@")[0]) ?? "User";
      let picture = firstString(profile.picture, profile.picture_url);
      let cf: Record<string, unknown> = Object(Reflect.get(ctx.request, "cf") ?? {});
      let zone = firstString(cf.timezone);
      let db = openDb(env);
      await db.execute({
        sql: "INSERT INTO users (id, google_id, email, name, picture) VALUES (?, ?, ?, ?, ?) ON CONFLICT(google_id) DO UPDATE SET email = excluded.email, picture = excluded.picture, updated_at = CURRENT_TIMESTAMP",
        args: [crypto.randomUUID(), googleId, email, name, picture],
      });
      let row = (await db.execute({ sql: "SELECT id FROM users WHERE google_id = ?", args: [googleId] })).rows[0];
      if (!row) throw new Error("User was not saved");
      let userId = String(row.id);
      await db.execute({ sql: "INSERT OR IGNORE INTO settings (user_id, timezone) VALUES (?, ?)", args: [userId, zone && validZone(zone) ? zone : "UTC"] });
      let s = await completeAuth(ctx);
      s.set("auth", { userId });
      return go(returnTo ?? "/");
    } catch (error) {
      console.error("Google sign-in failed", error);
      sess(ctx).flash("error", "Sign-in failed. Please try again.");
      return go("/");
    }
  }));

  router.map(routes.logout, createAction(routes.logout, (ctx) => {
    sess(ctx).destroy();
    return go("/");
  }));

  router.map(routes.goal, createAction(routes.goal, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    let f = form(ctx);
    let name = text(f.get("name"), 60);
    let target = toCents(f.get("target"));
    if (!name || !target) {
      sess(ctx).flash("error", "Give the goal a name and a target above zero.");
      return go("/");
    }
    await store(db, user.id).saveGoal({ name, reason: text(f.get("reason"), 200), targetCents: target });
    sess(ctx).flash("notice", "Goal saved.");
    return go("/");
  }));

  router.map(routes.sourceAdd, createAction(routes.sourceAdd, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    let name = text(form(ctx).get("name"), 60);
    if (!name) sess(ctx).flash("error", "Give the source a name.");
    else if (!(await store(db, user.id).addSource(name))) sess(ctx).flash("error", "You already have a source with that name.");
    return go("/");
  }));

  router.map(routes.sourceDelete, createAction(routes.sourceDelete, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    await store(db, user.id).deleteSource(text(form(ctx).get("source_id"), 64));
    sess(ctx).flash("notice", "Source deleted.");
    return go("/settings");
  }));

  router.map(routes.entry, createAction(routes.entry, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    let f = form(ctx);
    let cents = toCents(f.get("amount"));
    if (cents === null) {
      sess(ctx).flash("error", "Enter an amount like 85 or 85.50.");
      return go("/");
    }
    let st = store(db, user.id);
    let settings = await st.settings();
    let day = dayOf(new Date(), settings.timezone, settings.dayStartHour);
    if (!(await st.saveEntry(text(f.get("source_id"), 64), day, cents))) sess(ctx).flash("error", "That source was not found.");
    return go("/");
  }));

  router.map(routes.settings, createAction(routes.settings, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    let d = await load(db, user.id);
    let t = getCsrfToken(ctx);
    return ctx.render(shell({ title: "Settings", user, token: t, tab: "settings", ...flashes(ctx) }, settingsView(d, user, t)));
  }));

  router.map(routes.settingsSave, createAction(routes.settingsSave, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    let f = form(ctx);
    let name = text(f.get("name"), 80);
    let timezone = text(f.get("timezone"), 64);
    let hour = Number(f.get("day_start_hour"));
    if (!name || !validZone(timezone) || !Number.isInteger(hour) || hour < 0 || hour > 23) {
      sess(ctx).flash("error", "Check your name, timezone and day start.");
      return go("/settings");
    }
    await store(db, user.id).saveSettings(name, {
      timezone,
      dayStartHour: hour,
      goalMode: pick(f.get("goal_mode"), GOAL_MODES, "kept"),
      filledDisplay: pick(f.get("filled_display"), DISPLAYS, "done"),
    });
    sess(ctx).flash("notice", "Settings saved.");
    return go("/settings");
  }));

  router.map(routes.accountDelete, createAction(routes.accountDelete, async (ctx) => {
    let db = openDb(env);
    let user = await userOf(ctx, db);
    if (!user) return go("/");
    if (text(form(ctx).get("confirm"), 10) !== "DELETE") {
      sess(ctx).flash("error", "Type DELETE to confirm.");
      return go("/settings");
    }
    await store(db, user.id).wipe();
    sess(ctx).destroy();
    return go("/");
  }));

  return router;
}

function notFound(env: Env) {
  return async (ctx: RequestContext) => {
    let user = await userOf(ctx, openDb(env));
    return ctx.render(
      shell({ title: "Not found", user, token: getCsrfToken(ctx) }, (
        <section class="landing">
          <h1>404</h1>
          <p>Nothing here.</p>
          <a href="/" class="btn primary">Go home</a>
        </section>
      )),
      { status: 404 },
    );
  };
}

function createHtmlRenderer() {
  return async function render(node: RemixNode, init?: ResponseInit) {
    let headers = new Headers(init?.headers);
    headers.set("content-type", "text/html; charset=utf-8");
    return createHtmlResponse(renderToStream(node), { ...init, headers });
  };
}
