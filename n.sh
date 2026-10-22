#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
for f in app/pages/screens.ts app/pages/auth.ts app/ui/css.ts app/ui/script.ts; do [ -f "$f" ] || { echo "missing $f, run this from the project root"; exit 1; }; done
patch -p1 --no-backup-if-mismatch <<'MT_PATCH'
--- a/app/pages/screens.ts
+++ b/app/pages/screens.ts
@@ -37,8 +37,9 @@
 	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
 	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
 	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
+	const all = d.kind === "money" ? plain(d.owed) : String(d.owed);
 	const panel = (flag: string, action: string, title: string, btn: string) =>
-		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off"><span class="mu">${unit}</span><button class="btn xs">${btn}</button>${flag === "data-addp" ? `<button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove this debt from ${esc(d.person)}? Use it for a mistake." aria-label="Remove debt">${ic("trash")}</button>` : ""}</div></form>`;
+		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off">${flag === "data-payp" ? `<button type="button" class="all" data-all="${all}" aria-label="Fill the full amount">All</button>` : ""}<span class="mu">${unit}</span></div><button class="btn xs">${btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove ${esc(d.person)} from the list without marking it paid?" aria-label="Remove without paying">${ic("trash")}</button></div></form>`;
 	return (
 		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
 		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="sp">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
@@ -58,7 +59,7 @@
 		? `<div class="sc bgc rgt"><div class="ct"><div class="sh"><span>${title}</span><span class="lb">${right}</span></div>${body}</div>${bigAdd(label, target, true)}</div>`
 		: `<div class="cd bgc rgt"><div class="ct"><div class="tg">${title}</div><div class="cb">${body}</div></div>${bigAdd(label, target, true)}</div>`;
 const addDebtPanel = (s: State) =>
-	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><button class="btn full">Add</button></form>`;
+	`<form method="post" action="/debts" class="sf adp" data-adp hidden>${back(s)}${nameChips([...new Set(s.debts.map((d) => d.person))])}<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required><div class="iw"><input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required><span class="mu">${cur(s)}</span></div><button class="btn full">Add</button></form>`;
 const owePair = (s: State) => {
 	const c = calc(s);
 	return `<div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>`;
--- a/app/pages/auth.ts
+++ b/app/pages/auth.ts
@@ -6,7 +6,7 @@
 	`<div class="auth-glass-box">` +
 	`<div class="auth-logo-center">${logo("/login")}</div>` +
 	`<h1 class="auth-title">${up ? "Create account" : "Sign in"}</h1>` +
-	`<div class="auth-sub">${up ? "Quiet money tracking. Start in seconds." : "Quiet money. Welcome back."}</div>` +
+	`<div class="auth-sub">${up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>` +
 	`<form class="au" method="post" action="${up ? "/signup" : "/login"}">` +
 	`<a class="gbtn" href="/login/google">${GOOGLE}<span>${up ? "Sign up with Google" : "Continue with Google"}</span></a>` +
 	`<div class="or">or</div>` +
--- a/app/ui/css.ts
+++ b/app/ui/css.ts
@@ -300,4 +300,11 @@
 .top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
 .top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
 .xo{padding:0;border:0;background:none}.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
+.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
+.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
+.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:11px 0}
+.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
+.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
+.iw .all:hover{filter:brightness(1.15)}
+.sf .iw{margin-bottom:10px}
 `;
--- a/app/ui/script.ts
+++ b/app/ui/script.ts
@@ -71,6 +71,11 @@
     v.innerHTML=hide?(v.getAttribute('data-bal')+' <small>'+v.getAttribute('data-cur')+'</small>'):'••••••';
     return
   }
+  if((q=t.closest('[data-all]'))){
+    var af=q.closest('.iw').querySelector('input');
+    af.value=q.getAttribute('data-all');af.focus();
+    return
+  }
   if((q=t.closest('[data-tg],[data-pay]'))){
     var w=q.closest('.dbw'),which=q.hasAttribute('data-tg')?'[data-addp]':'[data-payp]',other=q.hasAttribute('data-tg')?'[data-payp]':'[data-addp]';
     var p=w.querySelector(which),o=w.querySelector(other);
MT_PATCH
echo done
