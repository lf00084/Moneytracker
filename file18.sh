#!/bin/bash
set -e
cd "$(dirname "$0")"
if grep -q "file18:" app/client/app.css 2>/dev/null; then echo "already applied"; exit 0; fi
for f in app/screens.tsx app/client/app.css app/components/layout.tsx app/components/income.tsx app/components/ui.tsx app/components/pad.tsx; do [ -f "$f" ] || { echo "run this inside the Moneytracker folder (missing $f)"; exit 1; }; done
T=$(mktemp -d)
trap "rm -rf $T" EXIT
mkdir -p "$T/p"
cp -r app "$T/p/"
cat > "$T/patch.js" << 'PATCH_EOF'
const fs = require("fs")
const read = (f) => fs.readFileSync(f, "utf8")
const rep = (file, from, to, n = 1) => {
	const src = read(file)
	const parts = src.split(from)
	if (parts.length - 1 !== n) {
		console.error(`patch failed in ${file}: expected ${n} match(es) for:\n${from}\nfound ${parts.length - 1}`)
		process.exit(1)
	}
	fs.writeFileSync(file, parts.join(to))
}
const between = (file, a, b, to) => {
	const src = read(file)
	const i = src.indexOf(a)
	const j = src.indexOf(b)
	if (i < 0 || j < 0 || j < i || src.indexOf(a, i + 1) >= 0) {
		console.error(`patch failed in ${file}: anchors not found (${a.slice(0, 40)})`)
		process.exit(1)
	}
	fs.writeFileSync(file, src.slice(0, i) + to + src.slice(j))
}

// icons: bottom bar set + revert arrow
rep(
	"app/components/ui.tsx",
	`	chev: '<path d="M6 9l6 6 6-6"/>',\n`,
	`	chev: '<path d="M6 9l6 6 6-6"/>',
	bhome: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
	btrade: '<path d="m22 7-8.5 8.5-5-5L2 17"/><path d="M16 7h6v6"/>',
	bdoc: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h8"/>',
	bsun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
	bchat: '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22z"/>',
	buser: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
	revert: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
`,
)

// fonts + bottom bar order and icons
rep("app/components/layout.tsx", "&family=Noto+Sans+Arabic:wght@500;600&display=swap", "&family=JetBrains+Mono:wght@400;500;600&family=Noto+Sans+Arabic:wght@500;600&display=swap")
between(
	"app/components/layout.tsx",
	"const TABS = [",
	"export const BottomBar",
	`const TABS = [
	{ key: "home", label: "Home", icon: "bhome", href: "/home" },
	{ key: "trading", label: "Trading", icon: "btrade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "bdoc", href: "/pad" },
	{ key: "income", label: "Income", icon: "bsun", href: "/income" },
	{ key: "notes", label: "Notes", icon: "bchat", href: "/notes" },
	{ key: "profile", label: "Profile", icon: "buser", href: "/profile" },
] as const

`,
)

// income rows on home: undo button sits before the amount (grid: name | undo | amount)
between(
	"app/components/income.tsx",
	"const HomeAct = view<",
	"const DeleteSource = view<",
	`const HomeAct = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const amt = (n: number) => (
		<b class="ea">
			+{fmt(n)} <small>{cur}</small>
		</b>
	)
	if (x.type === "exoclick") {
		return (
			<>
				<span></span>
				{amt(sum)}
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				<span></span>
				{amt(x.amount)}
			</>
		)
	}
	if (got.length) {
		return (
			<>
				<form method="post" action="/income/delete" style={contents} data-confirm={\`Undo +\${fmt(sum)} \${cur} from \${x.name}?\`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={\`Undo \${x.name}\`}>
						<Icon name="revert" />
					</button>
				</form>
				{amt(sum)}
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</button>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan" data-tg>
			Add
		</button>
	)
})

`,
)

// home screen (mobile only)
rep("app/screens.tsx", `import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"\n`, `import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"\nimport { HomeBalance, HomeToday } from "./components/home.tsx"\n`)
rep(
	"app/screens.tsx",
	`			<>
				<ErrorBanner s={s} />
				<BalanceCard s={s} />
				<TodayCards s={s} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
				<PadHome />
			</>`,
	`			<div class="hm">
				<ErrorBanner s={s} />
				<HomeBalance s={s} />
				<HomeToday s={s} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</div>`,
)

// pad.tsx no longer exports PadHome: drop the import and the desktop use so the build passes
if (!/export const PadHome\b/.test(read("app/components/pad.tsx"))) {
	rep("app/screens.tsx", 'import { PadBody, PadHome, type PadTab } from "./components/pad.tsx"', 'import { PadBody, type PadTab } from "./components/pad.tsx"')
	rep("app/screens.tsx", "\t\t\t\t\t\t<PadHome />\n", "")
}
PATCH_EOF
cat > "$T/home.tsx" << 'HOME_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { calc } from "../lib/view.ts"
import { Icon, view } from "./ui.tsx"

export const HomeBalance = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<button type="button" class="ib" data-eye aria-label="Show balance">
			<Icon name="eye" />
		</button>
		<div class="hm-m">Total balance</div>
	</div>
))

export const HomeToday = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hm-two">
			<div class="hm-c">
				<div class="hm-m">Earned today</div>
				<div class="hm-big">
					+{fmt(c.earned)} <small>{s.user.currency}</small>
				</div>
			</div>
			<div class="hm-c">
				<div class="hm-m">Bought today</div>
				<div class="hm-big">
					−{fmt(c.bought)} <small>{s.user.currency}</small>
				</div>
			</div>
		</div>
	)
})
HOME_EOF
cat > "$T/file18.css" << 'CSS_EOF'

/* file18: home (mobile) + bottom bar restyle */
html{--h-ink:var(--ink);--h-ink2:var(--ink);--h-mu:var(--mu);--h-ln:var(--ln);--h-ln2:var(--ln);--h-card:var(--s1);--h-chip:var(--s2);--h-chip2:var(--s2);--h-bar:var(--s2);--h-sub:var(--s2);--h-bg:var(--bg);--h-earn:var(--earn);--h-ac:var(--ac);--h-acs:var(--acs);--h-acl:var(--acl);--h-pur:var(--spend);--h-solid:var(--ac);--h-fill:var(--ac);--h-on:var(--on);--h-btmu:var(--mu);--h-btln:var(--ln);--h-mono:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--h-sans:Inter,var(--font-sys)}
html[data-theme=light]{--h-ink:#1f2430;--h-ink2:#374151;--h-mu:#5f6672;--h-ln:#eceef1;--h-ln2:#e1e4e8;--h-card:#fff;--h-chip:#eceef1;--h-chip2:#f1f2f4;--h-bar:#e5e7eb;--h-sub:#f1f2f4;--h-bg:#f3f4f6;--h-earn:#8a5a00;--h-ac:#2f6f78;--h-acs:#d6f1f1;--h-acl:#a9dcdc;--h-pur:#6a4fd1;--h-solid:#3b727b;--h-fill:#2f6f78;--h-on:#fff;--h-btmu:#5f6672;--h-btln:#e5e7eb}

/* bottom bar (all pages) */
.bt{height:64px;padding:0 10px env(safe-area-inset-bottom,0px);justify-content:space-around;border-top:1px solid var(--h-btln);background:var(--s1);box-shadow:none}
.bt a,.bt button{flex:none;width:52px;height:42px;border-radius:14px;border:1px solid transparent;color:var(--h-btmu)}
.bt a.on{width:58px;background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.bt a.on::before{content:none}
.bt svg.ic,.bt .on svg.ic{width:20px;height:20px;stroke-width:1.8}

/* top row on home */
.app:has(.hm) .mm{padding-left:12px;padding-right:12px}
.app:has(.hm) .top-status-bar.tsplit{padding:14px 16px 0}
.app:has(.hm) .top-status-bar.tsplit .clock-time{font-family:var(--h-sans);font-size:18px;font-weight:700;letter-spacing:0;color:var(--h-ink)}
.app:has(.hm) .top-status-bar.tsplit .clock-subdate,.app:has(.hm) .top-status-bar.tsplit .clock-num,.app:has(.hm) .top-status-bar.tsplit .clock-dot{font-family:var(--h-mono);font-size:13px;font-weight:500;color:var(--h-mu);opacity:1}
.app:has(.hm) .top-status-bar.tsplit .clock-ar{font-size:13px;font-weight:500;color:var(--h-mu)}

/* home base */
.hm{display:flex;flex-direction:column;gap:6px;padding-top:8px;font-family:var(--h-sans);color:var(--h-ink)}
.hm-c,.hm .xc{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none;margin:0}
.hm-m,.hm .tg0{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .tg0{font-weight:400}

/* balance */
.hm-bal{display:grid;grid-template-columns:1fr auto;grid-template-areas:"l b" "v b";align-items:center;height:44px;padding:4px 6px 4px 14px;column-gap:10px}
.hm-bal .hm-m{grid-area:l;font-size:11px;line-height:1.1}
.hm-bal .hm-dots{grid-area:v}
.hm-bal .ib{grid-area:b;width:32px;height:32px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);box-shadow:none}
.hm .ib svg.ic{width:20px;height:20px;stroke-width:1.8}
.hm-dots{display:block;font-size:17px;line-height:1;letter-spacing:3px;font-weight:700}
.hm-dots:has(small){letter-spacing:0;font-size:19px}
.hm-dots small{font-size:12px;font-weight:500;color:var(--h-mu);letter-spacing:0}

/* earned / bought */
.hm-two{display:flex;gap:6px}
.hm-two .hm-c{flex:1;min-width:0;padding:6px 12px}
.hm-big{font-size:20px;font-weight:700;line-height:1.2;margin-top:2px;white-space:nowrap}
.hm-big small{font-size:13px;font-weight:500;color:var(--h-mu)}

/* income card */
.hm .xbare .xb{padding:4px 14px;border:0}
.hm .sw{border-top:1px solid var(--h-ln);border-bottom:0}
.hm .sw:first-child,.hm .sw:has(.hx)+.sw{border-top:0}
.hm .sw:last-child{border:0}
.hm .sw+.sw:last-child{border-top:1px solid var(--h-ln)}
.hm .hr{grid-template-columns:minmax(0,1fr) 32px auto;column-gap:10px;min-height:44px;padding:4px 0}
.hm .hn{font-size:15px;font-weight:500}
.hm .hn .lb,.hm .by .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hr .ea,.hm .by .ea{color:var(--h-earn)!important;font-weight:600;font-size:15px;white-space:nowrap;text-align:right}
.hm .hr .ea small,.hm .by .ea small{font-size:12px;font-weight:500;color:inherit;margin-left:3px}
.hm .ub{width:30px;height:30px;border-radius:50%;border:0;background:var(--h-chip2);color:var(--h-mu);box-shadow:none}
.hm .hr .ub{justify-self:center}
.hm .ub svg.ic{width:16px;height:16px;stroke-width:1.6}
.hm .by{border-bottom:0;border-top:1px solid var(--h-ln);min-height:44px;padding:4px 0}
.hm .by:first-child{border-top:0}
.hm .btn.xs{height:36px;min-height:36px;padding:0 18px;border-radius:18px;font:600 15px/1 var(--h-sans);letter-spacing:0;box-shadow:none}
.hm .btn.xs.o{border:1px solid var(--h-acl);background:var(--h-card);color:var(--h-ac)}
.hm .btn.xs.o:hover{background:var(--h-acs);filter:none}
.hm .btn.xs:not(.o){background:var(--h-fill);border:1px solid var(--h-fill);color:var(--h-on)}
.hm .btn.xs.off,.hm .btn.xs:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu);opacity:.8}
.hm .sw .ad{background:var(--h-bg);border:1px solid var(--h-ln2);border-radius:14px;padding:8px;margin:0 0 8px}
.hm .ad .ln{gap:8px;margin:0}
.hm .ad .in{height:36px;padding:0 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font-size:14px;margin:0}
.hm .ad .iw{height:36px;padding:0 12px;border-radius:14px;border-color:var(--h-ln2);background:var(--h-card)}
.hm .ad .iw .in{height:34px;padding:0;border:0;background:transparent}
.hm .ad label{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .in::placeholder{color:var(--h-mu);opacity:.85}

/* extra hours */
.hm .hx{background:var(--h-chip);border:0;border-radius:16px;margin:0 0 4px;overflow:hidden}
.hm .hx>summary{min-height:38px;padding:0 5px 0 12px;gap:8px;font:400 13px/1 var(--h-mono);color:var(--h-ink2)}
.hm .hx>summary>span:nth-child(2){color:var(--h-mu)}
.hm .hx>summary .chev{background:var(--h-card);color:var(--h-mu);width:28px;height:28px}
.hm .hxb{padding:0}
.hm .hxg{gap:8px;padding:2px 10px 0}
.hm .hc{background:var(--h-card);border:0;border-radius:12px;padding:7px 4px;gap:0;color:var(--h-ink);box-shadow:none}
.hm .hc b{font-size:14px;font-weight:600;color:var(--h-ink)}
.hm .hc small{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hc.on{background:var(--h-acs);box-shadow:inset 0 0 0 1px var(--h-acl)}
.hm .hc.on b{color:var(--h-ac)}
.hm .hxm{margin:0;padding:10px;gap:8px}
.hm .hxm .in{height:36px;padding:0 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font-size:14px;flex:1;margin:0}

/* expandable cards: buys, goals, owe */
.hm .xh{min-height:0;padding:9px 112px 9px 16px}
.hm .xn .xh{padding-right:52px}
.hm details[data-fixed]>.xh{padding:9px 70px 0 16px}
.hm .osum .ow{margin:0;gap:0;flex-wrap:nowrap;align-items:baseline}
.hm .ow .big2{font-size:26px;font-weight:700;letter-spacing:0;line-height:1.15}
.hm .ow .big2.sp{color:var(--h-pur)!important}
.hm .ow .big2 small{font:500 13px/1 var(--h-mono);color:var(--h-mu);margin-left:6px;letter-spacing:0}
.hm .ow .big2.sp small{color:var(--h-mu);margin-left:0}
.hm .ow>.lb,.hm .ow>.sm{font:500 13px/1 var(--h-mono);color:var(--h-mu)!important;margin-left:6px}
.hm .xc .chev{top:22px;margin-top:0;color:var(--h-ink);right:75px}
.hm .xn .chev{right:16px}
.hm .xc .chev svg.ic{width:22px;height:22px;stroke-width:1.8}
.hm .xp{width:46px;height:38px;border-radius:14px;top:13px;right:14px;border:1px solid var(--h-acl);background:var(--h-acs);color:var(--h-ac)}
.hm .xc:has(details[data-fixed]) .xp{top:10px}
.hm .xp svg.ic{width:20px;height:20px;stroke-width:1.8}
.hm .xj{opacity:.2}
.hm .xb{padding:0;border-top:0}
.hm .xbare .xb{padding:4px 14px}
.hm details[data-fixed] .xb{padding:2px 16px 9px}
.hm .xb .lb[style]{font:400 14px/1.4 var(--h-sans);color:var(--h-mu);padding:0!important}
.hm .xf{padding:9px 16px;background:var(--h-sub);border-top:1px solid var(--h-ln)}
.hm .xl{font:400 14px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .xl b{color:var(--h-ink)}
.hm .lnk{color:var(--h-ac);font:600 15px/1.3 var(--h-sans);text-decoration:underline;text-underline-offset:3px}
.hm details[data-keep-open=owe] .xf{padding:0;border:0;background:none}
.hm details[data-keep-open=owe] .xf .xl{display:none}
.hm details[data-keep-open=owe] .xf form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--h-ln);background:var(--h-sub)}
.hm details[data-fixed] .xf{padding:0;border:0;background:none}
.hm details[data-fixed] .xf form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--h-ln);background:var(--h-sub)}
.hm .xf .in,.hm .xf .iw{border-color:var(--h-ln2);background:var(--h-card);color:var(--h-ink)}
.hm .xf .btn.full{border-radius:24px;min-height:48px;font-size:16px;background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none}
.hm .xf .chip{background:var(--h-card);border-color:var(--h-ln2);color:var(--h-mu)}

/* goals open */
.hm .gw{padding:10px 16px 4px;border-top:1px solid var(--h-ln);border-bottom:0}
.hm .gw .db{padding:0;border:0;gap:0}
.hm .gw .l1{margin-bottom:0;align-items:baseline}
.hm .gw .l1 b{font-size:17px;font-weight:700;white-space:normal;overflow:visible}
.hm .gw .l1 .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .gw .mt{height:4px;margin:8px 0;background:var(--h-bar);border-radius:2px}
.hm .gw .mt i{background:var(--h-mu);border-radius:2px}
.hm .gw .mt.full i{background:var(--h-ac)}
.hm .gi{height:48px;margin-left:6px;padding:0 0 0 22px;gap:10px;border-left:2px solid var(--h-ln2)}
.hm .gn{font-size:16px}
.hm .gi .lb{font:400 13px/1 var(--h-mono);color:var(--h-mu);margin-right:4px}
.hm .gi .btn.xs{height:34px;min-height:34px;padding:0 18px;border-radius:20px;background:var(--h-solid);border-color:var(--h-solid)}
.hm .gi .btn.xs.off{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}

/* owe open */
.hm .xc .db{padding:9px 14px;gap:12px;border-top:1px solid var(--h-ln);border-bottom:0;align-items:center}
.hm .gw .db{padding:0;border:0;gap:0}
.hm .db .ib.sm{width:40px;height:40px;min-width:40px;background:var(--h-acs);border:1px solid var(--h-acl);color:var(--h-ac);box-shadow:none}
.hm .db .l1 b{font-size:17px;font-weight:600}
.hm .db .l1>span{font-size:16px;color:var(--h-ink2)}
.hm .dn .dl{margin:2px 0 6px;font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .db .mt.s{height:4px;background:var(--h-bar);border-radius:2px}
.hm .db .mt.s i{border-radius:2px}
.hm .db .btn.xs{height:34px;min-height:34px;border-radius:20px}
.hm .db .l1>b{white-space:normal;overflow:visible}
CSS_EOF
(cd "$T/p" && node "$T/patch.js" && cp "$T/home.tsx" app/components/home.tsx && cat "$T/file18.css" >> app/client/app.css)
cp -r "$T/p/app/." app/
echo "done. home page + bottom bar updated (file18). run: bun run dev"
