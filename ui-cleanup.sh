#!/usr/bin/env bash
# Task 1 (money UI cleanup) + Task 2 (homepage matches login). Run from the project root: bash ui-cleanup.sh
set -e
cd "$(dirname "$0")"
for f in app/pages/screens.ts app/ui/css.ts; do [ -f "$f" ] || { echo "missing $f, run this from the project root"; exit 1; }; done
cat > /tmp/mt_ui_cleanup.patch <<'MT_PATCH'
--- a/app/pages/screens.ts
+++ b/app/pages/screens.ts
@@ -39,10 +39,10 @@
 	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
 	const all = d.kind === "money" ? plain(d.owed) : String(d.owed);
 	const panel = (flag: string, action: string, title: string, btn: string) =>
-		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}${flag === "data-payp" && d.kind === "money" ? ` · you have ${fmt(Math.max(0, s.balance))} ${cur(s)}` : ""}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off">${flag === "data-payp" ? `<button type="button" class="all" data-all="${all}" aria-label="Fill the full amount">All</button>` : ""}<span class="mu">${unit}</span></div><button class="btn xs">${btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove ${esc(d.person)} from the list without marking it paid?" aria-label="Remove without paying">${ic("trash")}</button></div></form>`;
+		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}</label><div class="ln"><div class="iw"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off">${flag === "data-payp" ? `<button type="button" class="all" data-all="${all}" aria-label="Fill the full amount">All</button>` : ""}<span class="mu">${unit}</span></div><button class="btn xs">${btn}</button><button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn="Remove ${esc(d.person)} from the list without marking it paid?" aria-label="Remove without paying">${ic("trash")}</button></div></form>`;
 	return (
 		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
-		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="sp">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
+		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span>${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
 		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
 		panel("data-addp", "/debts", "Add to", "Add") +
 		panel("data-payp", "/debts/pay", "Pay", "Pay") +
@@ -80,7 +80,7 @@
 const roadChips = (s: State) =>
 	[
 		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(s, g)}%</span>`),
-		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
+		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
 	].join("");
 const goalM = (s: State) => {
 	const c = calc(s);
@@ -184,13 +184,13 @@
 const c = calc(s);
 const rows = s.sources.filter((x) => x.active).map((x) => homeRow(s, x)).join("") + s.incomesToday.filter((i) => !i.sourceId).map((i) => incRow(s, i)).join("");
 const form = `<form method="post" action="/history/income" class="sf xfm" data-adp hidden>${back(s)}<div class="ln"><input class="in" name="amount" placeholder="Other income today" inputmode="decimal" autocomplete="off" required><button class="btn">Add</button></div></form>`;
-return xcard("inc", true, "Income today", `<b class="big2 ea">+${fmt(c.earned)} <small>${cur(s)}</small></b><span class="lb">${c.earnedLine}</span>`, rows || '<div class="lb" style="padding:8px 0">No sources yet.</div>', "", form, "Add other income");
+return xcard("inc", true, "Income today", `<b class="big2">+${fmt(c.earned)} <small>${cur(s)}</small></b><span class="lb">${c.earnedLine}</span>`, rows || '<div class="lb" style="padding:8px 0">No sources yet.</div>', "", form, "Add other income");
 };
 const incD = (s: State, title = "Income sources", id = "f-src-d") => addSourceForm(s, true, id) + listCard(true, title, `+${fmt(calc(s).earned)} today`, srcRows(s), id, "Add source");
 const cardsM = (s: State) => {
 	const c = calc(s);
 	const row = (cls: string, big: string) => `<div class="big2 ${cls}" style="white-space:nowrap">${big} <small>${cur(s)}</small></div>`;
-	return `<div class="two">${tg("Earned today", row("ea", `+${fmt(c.earned)}`))}${tg("Bought today", row("sp", `−${fmt(c.bought)}`))}</div>`;
+	return `<div class="two">${tg("Earned today", row("", `+${fmt(c.earned)}`))}${tg("Bought today", row("", `−${fmt(c.bought)}`))}</div>`;
 };
 const buyRows = (s: State) =>
 	`<div>${
@@ -205,7 +205,7 @@
 const buysD = (s: State) => spendForm(s, true, "f-buy-d") + listCard(true, "Today's buys", `${s.buys.length}`, buyRows(s), "f-buy-d", "Add a spend");
 const hero = (s: State) => {
 	const c = calc(s);
-	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v ea">+${fmt(c.earned)}</div>${c.earnedLine ? `<div class="lb">${c.earnedLine}</div>` : ""}</div><div><div class="lb">Bought today</div><div class="v sp">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
+	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v">+${fmt(c.earned)}</div>${c.earnedLine ? `<div class="lb">${c.earnedLine}</div>` : ""}</div><div><div class="lb">Bought today</div><div class="v">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
 };
 const noteList = (s: State, key: string) => {
 	if (key === "dash")
--- a/app/ui/css.ts
+++ b/app/ui/css.ts
@@ -1,5 +1,5 @@
 export const css = String.raw`
-html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
+html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
 html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
 *{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
 a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
@@ -9,6 +9,8 @@
 ::selection{background:var(--acs);color:var(--ink)}
 [hidden]{display:none!important}
 
+/* one look for every surface: login box, cards, hero. Radius and shadow come from the tokens on html. */
+.cd,.sc,.xc,.hero,.auth-glass-box{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
 body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}
 
 a{color:inherit;text-decoration:none}
@@ -30,11 +32,12 @@
 .clock-dot{opacity:.5}
 .clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
 .tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}
+.tf-clock .clock-date,.tf-clock .clock-subdate{display:none}
 
 .auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
 .auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
-.auth-glass-box{width:100%;background:var(--s1);border:1px solid var(--ln);border-radius:24px;padding:38px 32px 34px;box-shadow:var(--sh1)}
-@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px;border-radius:20px}}
+.auth-glass-box{width:100%;padding:38px 32px 34px}
+@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px}}
 .auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
 .auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
 .auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
@@ -62,7 +65,7 @@
 .ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
 .ib{flex:none;aspect-ratio:1}.ib.sm{width:28px;height:28px;min-width:28px}.ib svg.ic{width:16px;height:16px}.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}
 
-.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:20px 20px 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
+.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:var(--rc) var(--rc) 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
 .bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
 .bt svg.ic{position:relative;width:26px;height:26px}
 .bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
@@ -83,7 +86,7 @@
 .big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
 .big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}
 
-.cd{background:var(--s1);border:1px solid var(--ln);border-radius:16px;box-shadow:var(--sh1);margin-top:14px}
+.cd{margin-top:14px}
 .tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
 .cb{padding:8px 14px 14px}
 .two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
@@ -98,22 +101,22 @@
 .chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
 .chip.n{color:var(--spend);border-color:var(--spl)}
 
-.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:12px;padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
+.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:var(--rm);padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
 .btn:hover{filter:brightness(1.06)}
 .btn.o{background:var(--s1);color:var(--ink);border:1px solid var(--ln);box-shadow:var(--sh1)}
 .btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
 .btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
-.btn.full{width:100%;padding:13px;border-radius:12px;margin-top:16px}
-.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:500;color:var(--mu);margin-bottom:6px;letter-spacing:-.01em}
+.btn.full{width:100%;padding:14px 20px;font-size:16px;font-weight:700;border-radius:var(--rm);margin-top:20px}
+.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}
 
-.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:10px 14px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
+.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:var(--rm);padding:13px 16px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
 .in:focus,.in.f:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
 .in::placeholder{color:var(--mu);opacity:.6}
 .ln{display:flex;gap:10px;align-items:center}
 
 .stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
 .stp button{width:34px;height:34px;border:1px solid var(--ln);background:var(--s1);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;color:var(--ink)}
-.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:12px 16px;border-radius:12px;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
+.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:13px 18px;border-radius:var(--rm);border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
 .or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
 .lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}
 
@@ -167,12 +170,12 @@
 
 .li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}.li:hover{background:var(--s2)}.li:last-child{border:0}.li:first-child{padding-top:14px}
 
-.hero{display:grid;grid-template-columns:repeat(4,1fr);border:1px solid var(--ln);border-radius:16px;background:var(--s1);box-shadow:var(--sh1);margin:20px 0 16px;overflow:hidden}
+.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
 .hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:26px}
 .hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
 .g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
 .g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
-.sc{margin-top:24px;background:var(--s1);border:1px solid var(--ln);border-radius:16px;padding:18px 22px 20px;box-shadow:var(--sh1)}
+.sc{margin-top:24px;padding:18px 22px 20px}
 .sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
 .sc .rw,.sc .by,.sc .db{padding:14px 0}
 .qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:16px}
@@ -190,11 +193,7 @@
 .sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
 .sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
 .wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
-.au .in{padding:13px 16px;font-size:15px}
-.au .fl{margin-top:14px}.au .fl label{margin-bottom:6px;font-weight:600;font-size:12px;letter-spacing:0.02em}
-.au .btn.full{padding:14px 20px;font-size:16px;border-radius:12px;margin-top:20px;font-weight:700}
-.au .gbtn{padding:13px 18px;font-size:14px;border-radius:12px;font-weight:600}
-.au .gbtn:hover{background:var(--s2)}
+.gbtn:hover{background:var(--s2)}
 .au .or{margin:18px 0 6px}
 
 details.cd>summary{padding:14px 16px;display:block;position:relative}
@@ -265,7 +264,7 @@
 .srcf{margin-top:14px}.srcf .ln{gap:10px}.srcf .in.pr{flex:0 0 96px;width:96px}.srcf .btn.full{margin-top:10px}
 .in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
 .rw>.rt{max-width:62%;justify-content:flex-end}
-.xc{position:relative;margin-top:14px;background:var(--s1);border:1px solid var(--ln);border-radius:16px;box-shadow:var(--sh1);overflow:hidden;min-width:0}
+.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
 .xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
 .xh::-webkit-details-marker{display:none}
 .xh>div{min-width:0}
@@ -302,7 +301,7 @@
 .xo{padding:0;border:0;background:none}.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
 .iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
 .iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
-.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:11px 0}
+.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
 .iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
 .iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
 .iw .all:hover{filter:brightness(1.15)}
MT_PATCH
if ! patch -p1 --dry-run -s < /tmp/mt_ui_cleanup.patch >/dev/null 2>&1; then
  echo "Patch does not apply cleanly (already applied, or the files changed). Nothing was modified."
  rm -f /tmp/mt_ui_cleanup.patch
  exit 1
fi
patch -p1 --no-backup-if-mismatch < /tmp/mt_ui_cleanup.patch
rm -f /tmp/mt_ui_cleanup.patch
echo "Done. Changed: app/pages/screens.ts, app/ui/css.ts"
