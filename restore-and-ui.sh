#!/usr/bin/env bash
set -e
[ -d app/ui ] && [ -d app/pages ] || { echo "Run this inside the Moneytracker-main folder"; exit 1; }

cat > wrangler.jsonc << 'MT_EOF'
{
	"$schema": "node_modules/wrangler/config-schema.json",
	"name": "moneytracker",
	"main": "./bootstrap/worker.ts",
	"compatibility_date": "2026-09-02",
	"compatibility_flags": ["nodejs_compat"],
	"workers_dev": true,
	"observability": { "enabled": true },
	"vars": {
		"APP_ORIGIN": "https://moneytracker.YOUR-SUBDOMAIN.workers.dev",
		"TURSO_DATABASE_URL": "https://lf-lf00084.aws-eu-west-1.turso.io"
	}
}
MT_EOF

sed -i '/^wrangler/d' .gitignore

cat > app/ui/css.ts << 'MT_EOF'
export const css = String.raw`
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}

body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}

a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}button{cursor:pointer}
.mu,.lb{color:var(--mu)}.lb{font-size:11px;font-family:var(--mono)}.pos{color:var(--pos)!important}.neg{color:var(--neg)!important}.ea{color:var(--earn)!important}.sp{color:var(--spend)!important}.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}summary::-webkit-details-marker{display:none}

button,input[type=button],input[type=submit],.btn,.sbl,.qk button,.qk4 button,.chip,.ib,.pl{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.qk button:active,.qk4 button:active,.chip:active,.ib:active,.pl:active{transform:scale(.97);opacity:.88}

.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
.tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}

.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;background:var(--s1);border:1px solid var(--ln);border-radius:24px;padding:38px 32px 34px;box-shadow:var(--sh1)}
@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px;border-radius:20px}}
.auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
.auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
.auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
.auth-err-banner{background:rgba(255,90,77,0.12);border:1px solid rgba(255,90,77,0.3);border-radius:12px;padding:10px 14px;color:var(--neg);font-size:13px;font-weight:500;text-align:center;margin:12px 0}
.auth-switch-wrap{display:flex;justify-content:center;margin-top:22px;text-align:center}
.lnk-switch{font-size:14px;color:var(--mu);text-decoration:none}
.lnk-switch b{color:var(--ac);text-decoration:underline;text-underline-offset:3px}
.lnk-switch:hover{color:var(--ink)}

@media(min-width:900px){.m{display:none!important}}
@media(max-width:899px){.d{display:none!important}}

.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){.app{flex-direction:column}}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}

.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg,.bt .lg svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib.sm{width:28px;height:28px}.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}

.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:20px 20px 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}.bt .on svg.ic{stroke-width:2}
.bt .lg svg{opacity:.55;width:26px;height:26px;border-radius:7px}.bt .lg.on svg{opacity:1}

.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sp{flex:1}

h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}

.cd{background:var(--s1);border:1px solid var(--ln);border-radius:16px;box-shadow:var(--sh1);margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}.two .cb{padding:3px 12px 10px}.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}

.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:12px;padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
.btn:hover{filter:brightness(1.06)}
.btn.o{background:var(--s1);color:var(--ink);border:1px solid var(--ln);box-shadow:var(--sh1)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
.btn.full{width:100%;padding:13px;border-radius:12px;margin-top:16px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:500;color:var(--mu);margin-bottom:6px;letter-spacing:-.01em}

.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:10px 14px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
.in:focus,.in.f:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.in::placeholder{color:var(--mu);opacity:.6}
.ln{display:flex;gap:10px;align-items:center}

.stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
.stp button{width:34px;height:34px;border:1px solid var(--ln);background:var(--s1);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;color:var(--ink)}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:12px 16px;border-radius:12px;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}

.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}

.qk{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:12px}
.qk button{display:flex;flex-direction:column;align-items:center;gap:6px;padding:14px 6px 12px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);color:var(--ink)}
.qk button svg.ic{color:var(--spend)}
.qk button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}.qk button.on small{color:var(--spend);opacity:.8}
.qk span{font-weight:600;font-size:13px}.qk small{font-size:11px;color:var(--mu);font-family:var(--mono)}
.pn{display:flex;gap:16px;align-items:flex-end;flex-wrap:wrap}
.pn2{display:flex;gap:12px;align-items:flex-end}
.pn2 .pf{flex:1;min-width:0}
.pn2 .pq{flex:none}
.pn2 label{display:block;margin-bottom:6px}
.pn2 .stp{gap:6px}.pn2 .stp .in{width:46px;padding:10px 4px}
.th2{display:flex;justify-content:space-between;align-items:center;padding:10px 10px 0 14px!important}
.pl{width:32px;height:32px;border-radius:10px;border:1px solid var(--ln);background:var(--s2);color:var(--ink);display:flex;align-items:center;justify-content:center;padding:0;flex:none;box-shadow:var(--sh1)}
.pl svg.ic{width:18px;height:18px;transition:transform .18s ease}
.pl.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}.pl.on svg.ic{transform:rotate(45deg)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.tt{display:flex;align-items:center;gap:12px;margin-top:16px}.tt b{flex:1;font-size:26px;letter-spacing:-.04em}

.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ln3{display:flex;gap:12px;align-items:center}.n3{width:76px;flex:none}

.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}.cm .eb b{font-weight:600}.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}

.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}.li:hover{background:var(--s2)}.li:last-child{border:0}.li:first-child{padding-top:14px}

.hero{display:grid;grid-template-columns:repeat(4,1fr);border:1px solid var(--ln);border-radius:16px;background:var(--s1);box-shadow:var(--sh1);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;background:var(--s1);border:1px solid var(--ln);border-radius:16px;padding:18px 22px 20px;box-shadow:var(--sh1)}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:16px}
.qk4 button{display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;color:var(--ink);text-align:left;box-shadow:var(--sh1)}
.qk4 button svg.ic{color:var(--spend)}
.qk4 button.on{background:var(--sps);color:var(--spend);border-color:var(--spl)}
.qk4 b{display:block;font-size:14px}.qk4 small{font-size:12px;opacity:.65;font-family:var(--mono)}
.qrow{display:flex;align-items:center;gap:16px;margin-top:16px;padding:16px 18px;border:1px solid var(--ln);background:var(--s1);border-radius:16px;box-shadow:var(--sh1);flex-wrap:wrap}
.qrow .eq{font-size:22px;font-weight:600;letter-spacing:-.04em}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
.sl{background:var(--ac);color:var(--on);padding:48px;display:flex;flex-direction:column;justify-content:space-between}
.sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
.sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
.wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.au .in{padding:13px 16px;font-size:15px}
.au .fl{margin-top:14px}.au .fl label{margin-bottom:6px;font-weight:600;font-size:12px;letter-spacing:0.02em}
.au .btn.full{padding:14px 20px;font-size:16px;border-radius:12px;margin-top:20px;font-weight:700}
.au .gbtn{padding:13px 18px;font-size:14px;border-radius:12px;font-weight:600}
.au .gbtn:hover{background:var(--s2)}
.au .or{margin:18px 0 6px}

details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s ease}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}

.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:var(--bg);border:1px solid var(--ln);color:var(--ink)}
.qe{display:flex;gap:10px;align-items:center;padding:10px 0;border-bottom:1px solid var(--ln)}
.qe .in{font-size:14px;padding:8px 12px}
.qadd{display:flex;gap:10px;align-items:center;margin-top:14px}
.qadd .in{font-size:14px;padding:8px 12px}
`;
MT_EOF

cat > app/ui/script.ts << 'MT_EOF'
/**
 * Tiny inline script, plain JavaScript. All data now lives in the database and every change is a
 * normal form post. This script only handles what a form cannot: picking a quick buy, the
 * quantity stepper, open/close panels, selecting a note, choosing an income mode, and the theme.
 * The browser still remembers two small UI things: the theme and whether "I owe" is open.
 */
export const themeBoot = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;

export const script = String.raw`
(function(){
var d=document,r=d.documentElement;
function all(sel,root){return [].slice.call((root||d).querySelectorAll(sel))}
function money(n){return (Math.round(n*100)/100).toLocaleString('en-US')}

function setTheme(t){
  r.setAttribute('data-theme',t);
  try{localStorage.setItem('mtheme',t)}catch(e){}
  try{fetch('/settings/theme',{method:'POST',body:new URLSearchParams({theme:t}),credentials:'same-origin',redirect:'manual'})}catch(e){}
}

/* ---------- quick buy ---------- */
function calc(f){
  var q=parseFloat(f.querySelector('[data-qty]').value)||0,p=parseFloat(String(f.querySelector('[data-price]').value).replace(',','.'))||0;
  var t=Math.round(q*p*100)/100,o=f.querySelector('[data-tot]');
  o.textContent=(o.getAttribute('data-pre')||'')+(t?'−':'')+money(t);
}
function pick(q,keep){
  var w=q.closest('[data-qb]'),f=w.querySelector('[data-qp]'),n=q.getAttribute('data-q');
  all('[data-q]',w).forEach(function(b){b.classList.toggle('on',b===q)});
  f.hidden=false;
  f.querySelector('[data-cat]').value=n;
  var ti=f.querySelector('[data-qt]');if(ti)ti.textContent=n;
  var lw=f.querySelector('[data-labelwrap]');if(lw)lw.hidden=!q.hasAttribute('data-o');
  if(!keep)f.querySelector('[data-qty]').value=1;
  f.querySelector('[data-price]').value=q.getAttribute('data-p')||'';
  calc(f);
}
all('.qk4').forEach(function(g){var first=g.querySelector('[data-q]');if(first)pick(first,false)});

/* ---------- notes ---------- */
function endEdit(c){
  var id=c.querySelector('[data-eid]');if(id)id.value='';
  var eb=c.querySelector('.eb');if(eb)eb.hidden=true;
  c.querySelector('textarea').value='';
}
all('[data-list]').forEach(function(L){
  var last=L.lastElementChild;
  if(L.getAttribute('data-list')!=='dash'&&last&&last.scrollIntoView)last.scrollIntoView({block:'end'});
});

/* ---------- "I owe" open or closed, kept in the browser ---------- */
var open={};try{open=JSON.parse(localStorage.getItem('mt:open')||'{}')}catch(e){}
all('details[data-keep-open]').forEach(function(x){var k=x.getAttribute('data-keep-open');if(k in open)x.open=!!open[k]});
d.addEventListener('toggle',function(e){
  var x=e.target;
  if(x.matches&&x.matches('details[data-keep-open]')){
    open[x.getAttribute('data-keep-open')]=x.open;
    try{localStorage.setItem('mt:open',JSON.stringify(open))}catch(err){}
  }
},true);

/* ---------- clicks ---------- */
d.addEventListener('click',function(e){
  var t=e.target,q;
  if(t.closest('[data-theme-toggle]')){setTheme(r.getAttribute('data-theme')==='dark'?'light':'dark');return}
  if((q=t.closest('[data-set-theme]'))){setTheme(q.getAttribute('data-set-theme'));return}
  if((q=t.closest('[data-eye]'))){
    var v=q.parentNode.firstChild,hide=q.getAttribute('data-s')!=='1';
    q.setAttribute('data-s',hide?'1':'0');
    v.innerHTML=hide?(v.getAttribute('data-bal')+' <small>'+v.getAttribute('data-cur')+'</small>'):'••••••';
    return
  }
  if((q=t.closest('[data-tg],[data-pay]'))){
    var w=q.closest('.dbw'),which=q.hasAttribute('data-tg')?'[data-addp]':'[data-payp]',other=q.hasAttribute('data-tg')?'[data-payp]':'[data-addp]';
    var p=w.querySelector(which),o=w.querySelector(other);
    if(o)o.hidden=true;
    p.hidden=!p.hidden;
    if(!p.hidden){var i=p.querySelector('input[name=amount]');if(i)i.focus()}
    return
  }
  if((q=t.closest('[data-plus]'))){
    if(q.getAttribute('data-plus')==='src'){
      var pn=q.closest('.cd').querySelector('[data-pnl]');
      pn.hidden=!pn.hidden;
      q.classList.toggle('on',!pn.hidden);
      if(!pn.hidden){var fi=pn.querySelector('input[name=name]');if(fi)fi.focus()}
    }else{
      var qf=d.querySelector('.mm [data-qp]');
      if(qf){
        qf.scrollIntoView({behavior:'smooth',block:'center'});
        var pi=qf.querySelector('[data-price]');if(pi)pi.focus();
      }
    }
    return
  }
  if((q=t.closest('[data-q]'))){pick(q,false);return}
  if((q=t.closest('[data-step]'))){
    var f2=q.closest('[data-qp]'),i2=f2.querySelector('[data-qty]');
    i2.value=Math.max(1,(parseFloat(i2.value)||0)+parseInt(q.getAttribute('data-step'),10));calc(f2);return
  }
  if((q=t.closest('[data-mode]'))){
    var form=q.closest('form');
    all('[data-mode]',form).forEach(function(c){c.classList.toggle('on',c===q)});
    form.querySelector('[data-mode-input]').value=q.getAttribute('data-mode');
    return
  }
  if((q=t.closest('.bub'))){
    q.classList.toggle('sel');var a=q.parentNode.querySelector('.acts');a.hidden=!a.hidden;return
  }
  if((q=t.closest('[data-act]'))){
    var m=q.closest('.msg'),act=q.getAttribute('data-act'),body=m.querySelector('.bub').textContent;
    if(act==='copy'){try{navigator.clipboard.writeText(body)}catch(x){}return}
    if(act==='edit'){
      var key=m.parentNode.getAttribute('data-list'),c=d.querySelector('[data-comp="'+key+'"]');
      c.querySelector('[data-eid]').value=m.getAttribute('data-id');
      c.querySelector('.eb').hidden=false;
      var ta=c.querySelector('textarea');ta.value=body;ta.focus();
    }
    return
  }
  if((q=t.closest('[data-cancel]'))){endEdit(q.closest('[data-comp]'));return}
});

d.addEventListener('input',function(e){
  var f=e.target.closest&&e.target.closest('[data-qp]');
  if(f)calc(f);
});

d.addEventListener('submit',function(e){
  var f=e.target,msg=f.getAttribute&&f.getAttribute('data-confirm');
  if(msg&&!confirm(msg))e.preventDefault();
});

d.addEventListener('keydown',function(e){
  if(e.key!=='Enter'||e.shiftKey)return;
  var t=e.target;
  if(t.matches&&t.matches('[data-comp] textarea')){
    e.preventDefault();
    if(t.value.trim()){var f=t.closest('form');if(f.requestSubmit)f.requestSubmit();else f.submit()}
  }
});

/* ---------- live clock (Africa/Casablanca) ---------- */
function updateLiveClock(){
  var tEls = all('[data-clock-time]');
  var dEls = all('[data-clock-date]');
  var sEls = all('[data-clock-subdate]');
  if(!tEls.length) return;
  var now = new Date();
  try{
    var tf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', hour: '2-digit', minute: '2-digit', hour12: false });
    var df = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', weekday: 'long', day: 'numeric', month: 'long' });
    var nf = new Intl.DateTimeFormat('en-GB', { timeZone: 'Africa/Casablanca', day: '2-digit', month: '2-digit', year: 'numeric' });
    var af = new Intl.DateTimeFormat('ar-MA', { timeZone: 'Africa/Casablanca', weekday: 'long' });
    var tStr = tf.format(now);
    var dStr = df.format(now);
    var sStr = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + '</span>';
    tEls.forEach(function(el){ el.textContent = tStr; });
    dEls.forEach(function(el){ el.textContent = dStr; });
    sEls.forEach(function(el){ el.innerHTML = sStr; });
  }catch(err){}
}
setInterval(updateLiveClock, 1000);

/* ---------- background fallback ---------- */
var bgCustomEl = d.querySelector('[data-bg-custom]');
if(bgCustomEl){
  var bgUrl = bgCustomEl.getAttribute('data-bg-custom');
  if(bgUrl){
    var testImg = new Image();
    testImg.onerror = function(){
      bgCustomEl.classList.add('bg-fallback-auto');
    };
    testImg.src = bgUrl;
  }
}
})();
`;
MT_EOF

cat > app/ui/shell.ts << 'MT_EOF'
import { css } from "./css.ts";
import { clockWidget, ic, logo, themeIcons } from "./parts.ts";
import { script, themeBoot } from "./script.ts";
import { liveClockNow } from "../lib/time.ts";

export type MobileTab = "home" | "notes" | "goals" | "history" | "profile" | "";
export type DesktopTab = "home" | "notes" | "plan" | "history" | "settings" | "";

const splitCss = ".top-status-bar.tsplit{justify-content:space-between}.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}";

export type PageOptions = {
title: string;
user?: boolean;
mobile: string;
desktop: string;
mobileTab?: MobileTab;
desktopTab?: DesktopTab;
dock?: string;
full?: boolean;
theme?: string;
mobileBar?: boolean;
};

const bottomBar = (a: MobileTab) =>
'<nav class="bt" aria-label="Main">' +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["goals", "Goals", "goal", "/goals"],
["history", "History", "hist", "/history"],
["profile", "Profile", "user", "/profile"],
] as const
)
.map(([key, label, icon, href]) => `<a href="${href}" class="${a === key ? "on" : ""}" aria-label="${label}">${ic(icon)}</a>`)
.join("") +
"</nav>";

const sidebar = (a: DesktopTab) =>
`<aside class="sb d">${logo("/home")}` +
(
[
["home", "Home", "home", "/home"],
["notes", "Notes", "notes", "/notes"],
["plan", "Plan", "goal", "/plan"],
["history", "History", "hist", "/history"],
["settings", "Settings", "gear", "/settings"],
] as const
)
.map(([key, label, icon, href]) => `<a class="sbl${a === key ? " on" : ""}" href="${href}">${ic(icon)}${label}</a>`)
.join("") +
`<div class="sp"></div><button type="button" class="sbl" data-theme-toggle>${themeIcons}<span>Theme</span></button>` +
`<form method="post" action="/logout"><button class="sbl">${ic("out")}<span class="neg">Log out</span></button></form></aside>`;

export function page(o: PageOptions): string {
const user = o.user !== false;
const { timeStr, dateStr, subDateStr } = liveClockNow();
const clock = clockWidget(timeStr, dateStr, subDateStr);
const topBar = `<div class="top-status-bar">${clock}</div>`;
const mobileTop = `<div class="top-status-bar tsplit">${clock}<div class="clock-subdate" dir="ltr">${subDateStr}</div></div>`;

return (
`<!DOCTYPE html><html lang="en" data-theme="${o.theme === "light" ? "light" : "dark"}"><head><meta charset="utf-8">` +
`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">` +
`<meta name="theme-color" content="#121212"><title>${o.title} · moneytracker</title>` +
`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&display=swap">` +
`<style>${css}${splitCss}</style><script>${o.theme ? "" : themeBoot}</script></head>` +
`<body>` +
`<div class="app">` +
(user
? sidebar(o.desktopTab ?? "")
: `<div class="tf-clock">${clock}<button type="button" class="ib" data-theme-toggle aria-label="Theme">${themeIcons}</button></div>`) +
(user
? `<main><div class="m">${mobileTop}</div><div class="m mm">${o.mobile}</div><div class="d">${topBar}</div><div class="d pg${o.full ? " full" : ""}">${o.desktop}</div></main>`
: `<main class="auth-viewport">${o.desktop}</main>`) +
(user ? `<div class="dock m">${o.dock ?? ""}${bottomBar(o.mobileTab ?? "")}</div>` : "") +
`</div><script>${script}</script></body></html>`
);
}
MT_EOF

cat > app/pages/screens.ts << 'MT_EOF'
import { esc } from "../lib/html.ts";
import type { DebtView, Goal, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel, dayOf, hhmm, longDay, today } from "../lib/time.ts";
import { chips, fld, hd, ic, ICON_KEYS, sec, tg, themeSwitch } from "../ui/parts.ts";
import { page } from "../ui/shell.ts";

function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);

	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${esc(n)} ${fmt(a)}`).join(" · ") || "nothing yet";

	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";

	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = s.goals.reduce((a, g) => a + Math.min(g.saved, g.target || g.saved), 0);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;

	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}

const cur = (s: State) => esc(s.user.currency);
const back = (s: State) => `<input type="hidden" name="back" value="${esc(s.back)}">`;
const err = (s: State) => (s.error ? `<div class="neg" role="alert" style="margin:10px 0;font-size:13px">${esc(s.error)}</div>` : "");
const pctOf = (g: Goal) => (g.target ? Math.min(100, Math.round((g.saved / g.target) * 100)) : 0);

const avatar = (s: State) => {
	const url = s.avatar ? encodeURI(s.avatar).replace(/'/g, "%27") : "";
	return `<div class="av"${url ? ` style="background:url('${esc(url)}') center/cover"` : ""}>${url ? "" : esc((s.user.name.trim()[0] ?? "?").toUpperCase())}</div>`;
};

const debtRow = (s: State, d: DebtView) => {
	const unit = d.kind === "money" ? cur(s) : esc(d.item);
	const label = d.kind === "money" ? `${fmt(d.owed)} ${cur(s)}` : `${d.owed} ${esc(d.item)}`;
	const pct = d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0;
	const hidden = `<input type="hidden" name="debt_id" value="${d.id}">${back(s)}`;
	const panel = (flag: string, action: string, title: string, btn: string) =>
		`<form method="post" action="${action}" class="ad" ${flag} hidden>${hidden}<label>${title} ${esc(d.person)}</label><div class="ln"><input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off"><span class="mu">${unit}</span><button class="btn xs">${btn}</button></div></form>`;
	return (
		`<div class="dbw"><div class="db"><button type="button" class="ib sm hi" data-tg aria-label="Add debt to ${esc(d.person)}">${ic("plus")}</button>` +
		`<div class="dn"><div class="l1"><b>${esc(d.person)}</b><span class="sp">${label}</span></div><div class="mt s n"><i style="width:${pct}%"></i></div></div>` +
		`<button type="button" class="btn xs o" data-pay>Pay</button></div>` +
		panel("data-addp", "/debts", "Add to", "Add") +
		panel("data-payp", "/debts/pay", "Pay", "Pay") +
		`</div>`
	);
};

const debtList = (s: State) => s.debts.map((d) => debtRow(s, d)).join("") || '<div class="lb" style="padding:8px 0">Nobody to pay. All clear.</div>';

const newPerson = (s: State) =>
	`<div class="sub">New person</div><form method="post" action="/debts" class="ln3">${back(s)}<input class="in" name="name" placeholder="Name" autocomplete="off"><input class="in n3" name="cig" placeholder="cig" inputmode="numeric"><input class="in n3" name="amount" placeholder="${cur(s)}" inputmode="decimal"><button class="btn xs">Add</button></form><div class="lb" style="margin-top:10px">Cleared people are hidden. Type their name again to bring them back.</div>`;

const owePair = (s: State) => {
	const c = calc(s);
	return `<div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>`;
};

const chev = `<span class="chev">${ic("chev")}</span>`;

const tgp = (t: string, key: string, b: string) =>
	`<div class="cd"><div class="tg th2"><span>${t}</span><button type="button" class="pl" data-plus="${key}" aria-label="Add">${ic("plus")}</button></div><div class="cb">${b}</div></div>`;

const spendRow = (n: string, sub: string, a: string) =>
	`<div class="by"><div><div>${n}</div><div class="lb">${sub}</div></div><b class="sp">${a}</b></div>`;

const oweM = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<details class="cd" data-keep-open="${key}"${open ? " open" : ""}><summary class="osum"><div class="tg0">I owe</div><div class="ow"><b class="sp big2">${fmt(c.oweMoney)} <small>${cur(s)}</small></b><span class="sp sm">${c.oweExtra}</span></div>${chev}</summary><div class="cb">${debtList(s)}${open ? newPerson(s) : ""}</div></details>`;
};

const oweD = (s: State, open: boolean, key: string) => {
	const c = calc(s);
	return `<details class="sc" data-keep-open="${key}"${open ? " open" : ""}><summary class="sh"><span>I owe</span><span class="rr"><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span>${chev}</span></summary>${debtList(s)}</details>`;
};

const goalM = (s: State) => {
	const c = calc(s);
	const chipHtml = [
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
	return tg(
		"Road to goals",
		`<div class="gl"><span class="big">${c.pct}<small>%</small></span><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div><div class="mt"><i style="width:${c.pct}%"></i></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}`,
	);
};

const goalFold = (s: State, key: string) => {
	const c = calc(s);
	const chipHtml = [
		...s.goals.map((g) => `<span class="chip">${esc(g.title)} ${pctOf(g)}%</span>`),
		...s.debts.filter((d) => d.kind === "money").map((d) => `<span class="chip n">${esc(d.person)} ${d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0}%</span>`),
	].join("");
	return `<details class="cd" data-keep-open="${key}"><summary class="osum"><div class="tg0">Road to goals</div><div class="ow"><b class="big2">${c.pct}<small>%</small></b><span class="lb">${fmt(c.toGo)} ${cur(s)} to go</span></div>${chev}</summary><div class="cb"><div class="mt"><i style="width:${c.pct}%"></i></div>${chipHtml ? `<div class="chips">${chipHtml}</div>` : ""}</div></details>`;
};

const saveBtn = (s: State, g: Goal) =>
	g.done
		? '<span class="chip">done</span>'
		: `<form method="post" action="/goals/save" style="display:contents">${back(s)}<input type="hidden" name="id" value="${g.id}"><input type="hidden" name="amount" value="100"><button class="btn xs">Save 100</button></form>`;

const goalLeft = (s: State, g: Goal) =>
	g.target ? `${fmt(Math.max(0, g.target - g.saved))} left of ${fmt(g.target)}` : `${fmt(g.saved)} ${cur(s)} saved`;

const newWish = (s: State, wide: boolean) =>
	`<form method="post" action="/goals" class="ln"${wide ? ' style="margin-top:18px"' : ""}>${back(s)}<input class="in" name="name" placeholder="${wide ? "New wish" : "Name"}" autocomplete="off"><input class="in${wide ? "" : " n3"}" name="price"${wide ? ' style="width:120px"' : ""} placeholder="Price" inputmode="decimal"><button class="btn xs">Add</button></form>`;

const wishesM = (s: State) =>
	s.goals
		.map((g) => tg(esc(g.title), `<div class="l1"><span class="lb">${goalLeft(s, g)}</span>${saveBtn(s, g)}</div><div class="mt"><i style="width:${pctOf(g)}%"></i></div>`))
		.join("") + tg("New wish", newWish(s, false));

const wishD = (s: State) =>
	sec(
		"Wish list",
		`${s.goals.filter((g) => !g.done).length} active`,
		s.goals
			.map(
				(g) =>
					`<div class="wr"><div style="flex:1"><div class="l1"><b>${esc(g.title)}</b><span class="lb">${goalLeft(s, g)}</span></div><div class="mt"><i style="width:${pctOf(g)}%"></i></div></div>${saveBtn(s, g)}</div>`,
			)
			.join("") + newWish(s, true),
	);

const debtsM = (s: State) => tg("Debts", owePair(s) + debtList(s));

const srcLabel = (x: Source) => (x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto · every day") : "manual");

const srcRows = (s: State) =>
	s.sources
		.map((x) => {
			const right =
				x.mode === "auto"
					? `<b class="ea">+${fmt(x.amount)}</b>`
					: `<form method="post" action="/income/add" style="display:contents">${back(s)}<input type="hidden" name="source_id" value="${x.id}"><button class="btn xs o">Add ${fmt(x.amount)}</button></form>`;
			return `<div class="rw"><div><div>${esc(x.name)}<span class="tag">${x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto") : "manual"}</span></div><div class="lb">${srcLabel(x)}</div></div>${right}</div>`;
		})
		.join("") || '<div class="lb" style="padding:8px 0">No sources yet. Add one below.</div>';

const modeChips = `<input type="hidden" name="mode" value="manual" data-mode-input><div class="chips"><span class="chip on" data-mode="manual" style="cursor:pointer">Manual</span><span class="chip" data-mode="daily" style="cursor:pointer">Auto daily</span><span class="chip" data-mode="monthly" style="cursor:pointer">Monthly</span></div>`;

const addSourceForm = (s: State, wide: boolean) =>
	wide
		? `<form method="post" action="/income" class="ln" style="margin-top:18px">${back(s)}<input class="in" name="name" placeholder="New source" autocomplete="off"><input class="in" name="amount" style="width:100px" placeholder="Amount" inputmode="decimal"><button class="btn xs">Add</button>${modeChips}</form>`
		: `<form method="post" action="/income">${back(s)}${fld("Name", "", { name: "name" })}${fld("Amount", "", { t: "number", name: "amount" })}${modeChips}<button class="btn full" style="margin-top:14px">Add source</button></form>`;

const incomeM = (s: State) => tg("Sources", srcRows(s)) + tg("Add a source", addSourceForm(s, false));

const incD = (s: State, title = "Income sources") => sec(title, `+${fmt(calc(s).earned)} today`, srcRows(s) + addSourceForm(s, true));

const cardsM = (s: State) => {
	const c = calc(s);
	const row = (cls: string, big: string) => `<div class="big2 ${cls}" style="white-space:nowrap">${big} <small>${cur(s)}</small></div>`;
	return `<div class="two">${tg("Earned today", row("ea", `+${fmt(c.earned)}`))}${tg("Bought today", row("sp", `−${fmt(c.bought)}`))}</div>`;
};

const buyRows = (s: State) =>
	`<div>${
		s.buys
			.map((b) => spendRow(esc(b.qty > 1 ? `${b.name} ×${b.qty}` : b.name), `${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`, `−${fmt(b.total)}`))
			.join("") || '<div class="lb" style="padding:8px 0">Nothing bought today.</div>'
	}</div>`;

const quickBtns = (s: State, desk: boolean) => {
	const items = [...s.quick.map((k) => ({ n: k.name, p: k.price ? fmt(k.price).replace(/,/g, "") : "", i: k.icon, sub: `${fmt(k.price)} each`, o: false })), { n: "Other", p: "", i: "Other", sub: "custom", o: true }];
	return items
		.map((k) => {
			const a = ` data-q="${esc(k.n)}" data-p="${esc(k.p)}"${k.o ? ' data-o="1"' : ""}`;
			return desk
				? `<button type="button"${a}>${ic(k.i)}<span><b>${esc(k.n)}</b><small>${k.sub}</small></span></button>`
				: `<button type="button"${a}>${ic(k.i)}<span>${esc(k.n)}</span><small>${k.sub}</small></button>`;
		})
		.join("");
};

const quickM = (s: State) =>
	`<div data-qb><form method="post" action="/buy" data-qp>${back(s)}${tg(
		"Quick buy",
		'<input type="hidden" name="category" value="Other"><div class="pn2"><div class="pf"><label class="lb">Price each</label><input class="in" name="price" data-price value="" inputmode="decimal" autocomplete="off"></div><div class="pq"><label class="lb">Quantity</label><div class="stp"><button type="button" data-step="-1">−</button><input class="in f" name="qty" data-qty value="1" inputmode="numeric"><button type="button" data-step="1">+</button></div></div></div><button class="btn full">Add <span data-tot data-pre="· ">0</span></button>',
	)}</form></div>`;

const quickD = (s: State) =>
	`<div data-qb><div class="qk4" data-qgrid>${quickBtns(s, true)}</div><form method="post" action="/buy" class="qrow" data-qp>${back(s)}<input type="hidden" name="category" data-cat value="Smoke"><div data-labelwrap hidden style="width:140px"><div class="lb">What</div><input class="in" name="label" data-label autocomplete="off"></div><div><div class="lb">Quantity</div><div class="stp"><button type="button" data-step="-1">−</button><input class="in f" name="qty" data-qty value="1" inputmode="numeric"><button type="button" data-step="1">+</button></div></div><div style="width:110px"><div class="lb">Price each</div><input class="in" name="price" data-price value="" inputmode="decimal"></div><div class="eq sp" data-tot data-pre="= ">= 0</div><button class="btn" style="margin-left:auto">Add</button></form></div>`;

const hero = (s: State) => {
	const c = calc(s);
	return `<div class="hero"><div><div class="lb">Earned today</div><div class="v ea">+${fmt(c.earned)}</div><div class="lb">${c.earnedLine}</div></div><div><div class="lb">Bought today</div><div class="v sp">−${fmt(c.bought)}</div><div class="lb">${s.buys.length} buys</div></div><div><div class="lb">Road to goals</div><div class="v">${c.pct}%</div><div class="mt"><i style="width:${c.pct}%"></i></div></div><div><div class="lb">I owe</div><div class="v sp">${fmt(c.oweMoney)}</div><div class="lb">${cur(s)} ${c.oweExtra}</div></div></div>`;
};

const noteList = (s: State, key: string) => {
	if (key === "dash")
		return `<div data-list="dash">${
			s.notes
				.slice(-2)
				.reverse()
				.map((n) => `<div class="rw"><span>${esc(n.body)}</span><span class="lb">${hhmm(n.at)}</span></div>`)
				.join("") || '<div class="lb" style="padding:8px 0">No notes yet.</div>'
		}</div>`;
	let last = "";
	let out = "";
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at));
		if (label !== last) {
			out += `<div class="day"><span>${esc(label)}</span></div>`;
			last = label;
		}
		out +=
			`<div class="msg" data-id="${n.id}"><div class="bub">${esc(n.body)}</div><div class="meta">${n.edited ? "edited · " : ""}${hhmm(n.at)}</div>` +
			`<div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button>` +
			`<form method="post" action="/notes/delete" style="display:contents" data-confirm="Delete this note?">${back(s)}<input type="hidden" name="id" value="${n.id}"><button class="btn xs dng">Delete</button></form></div></div>`;
	}
	return `<div data-list="${key}">${out}</div>`;
};

const chatHead =
	'<div class="ch"><div class="av s">S</div><div><b>Message yourself</b><div class="lb">only you can see this</div></div></div>';

const composer = (s: State, key: string) =>
	`<form class="cm" data-comp="${key}" method="post" action="/notes">${back(s)}<input type="hidden" name="id" data-eid><div class="eb" hidden><span><b>Editing</b> message</span><button type="button" data-cancel>✕</button></div><div class="cin"><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></div></form>`;

const noteD = (s: State) =>
	sec(
		"Note to yourself",
		`${s.notes.length} saved`,
		`<form class="cin" data-comp="dash" method="post" action="/notes" style="margin:14px 0">${back(s)}<input type="hidden" name="id" data-eid><textarea rows="1" name="text" placeholder="Message yourself"></textarea><button class="send" aria-label="Send">${ic("send")}</button></form>${noteList(s, "dash")}`,
	);

const dayNet = (e: number, b: number) => `${e - b < 0 ? "−" : "+"}${fmt(Math.abs(e - b))}`;

const histM = (s: State) =>
	s.days
		.map((d) =>
			tg(
				esc(d.label),
				`<div class="l1"><span><span class="lb">Earned</span> <b class="ea">+${fmt(d.earned)}</b></span><span><span class="lb">Bought</span> <b class="sp">−${fmt(d.bought)}</b></span><b>${dayNet(d.earned, d.bought)}</b></div>${chips(d.items.map(esc))}`,
			),
		)
		.join("");

const histD = (s: State) => {
	const e = s.days.reduce((a, d) => a + d.earned, 0);
	const b = s.days.reduce((a, d) => a + d.bought, 0);
	return sec(
		"Last 7 days",
		`+${fmt(e)} earned · −${fmt(b)} bought`,
		'<div class="th"><span>Day</span><span>Earned</span><span>Bought</span><span>Net</span><span>What</span></div>' +
			s.days.map((d) => `<div class="tr"><b>${esc(d.label)}</b><b class="ea">+${fmt(d.earned)}</b><b class="sp">−${fmt(d.bought)}</b><b>${dayNet(d.earned, d.bought)}</b>${chips(d.items.map(esc))}</div>`).join(""),
	);
};

const editFields = (s: State) =>
	fld("Name", esc(s.user.name), { f: true, name: "name" }) +
	fld("Email", esc(s.user.email), { t: "email", name: "email" }) +
	fld("Phone", esc(s.user.phone), { t: "tel", name: "phone", p: "+212 6 00 00 00 00" }) +
	fld("Bio", esc(s.user.bio), { name: "bio", p: "A line about you" });

const profileForm = (s: State, cancel: string) =>
	`<form method="post" action="/profile/edit">${err(s)}${editFields(s)}<div style="display:flex;gap:10px;margin-top:18px"><button class="btn" style="flex:1">Save</button><a class="btn o" style="flex:1" href="${cancel}">Cancel</a></div></form>`;

const quickEditor = (s: State) => {
	const opts = (sel: string) => ICON_KEYS.map((k) => `<option value="${k}"${k === sel ? " selected" : ""}>${k}</option>`).join("");
	const rows =
		s.quick
			.map(
				(k) =>
					`<form class="qe" method="post" action="/settings/quick"><input type="hidden" name="op" value="save"><input type="hidden" name="id" value="${k.id}"><select class="in sel" name="icon" aria-label="Icon">${opts(k.icon)}</select><input class="in" name="name" value="${esc(k.name)}" aria-label="Name" autocomplete="off"><input class="in n3" name="price" value="${k.price ? fmt(k.price).replace(/,/g, "") : ""}" inputmode="decimal" aria-label="Price" autocomplete="off"><button class="btn xs">Save</button><button class="ib sm" name="op" value="delete" aria-label="Remove" data-confirm="Remove ${esc(k.name)}?">×</button></form>`,
			)
			.join("") || '<div class="lb" style="padding:8px 0">No quick buys yet. Add one below.</div>';
	return `<div class="lb" style="margin-bottom:6px">These are the buttons under Quick buy.</div>${rows}<form class="qadd" method="post" action="/settings/quick"><input type="hidden" name="op" value="add"><select class="in sel" name="icon" aria-label="Icon">${opts("Tag")}</select><input class="in" name="name" placeholder="Name" autocomplete="off"><input class="in n3" name="price" placeholder="Price" inputmode="decimal" autocomplete="off"><button class="btn xs">Add</button></form>`;
};

const prefsForm = (s: State) =>
	`<form method="post" action="/settings">${fld("Currency", esc(s.user.currency), { name: "currency" })}${fld("Auto income runs at", esc(s.user.run_at), { name: "run_at" })}${fld("Week starts", esc(s.user.week_start), { name: "week" })}<button class="btn" style="margin-top:14px">Save</button></form>`;

const dataButtons = `<div style="display:flex;gap:10px;margin-top:6px"><a class="btn o" style="flex:1" href="/export.csv">Export CSV</a><form method="post" action="/account/delete" style="flex:1;display:flex" data-confirm="Delete your account and all your data? This cannot be undone."><button class="btn dng" style="flex:1">Delete account</button></form></div>`;

const balanceCard = (s: State) =>
	tg(
		"Total balance",
		`<div class="ow" style="margin:0"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></div>`,
	);

const profileM = (s: State) =>
	`<div style="display:flex;flex-direction:column;align-items:center;gap:10px;margin:20px 0 6px">${avatar(s)}<div style="text-align:center"><div style="font-size:22px;font-weight:700;letter-spacing:-.04em">${esc(s.user.name)}</div><div class="lb">${esc(s.user.email)}</div></div></div>` +
	balanceCard(s) +
	tg("Appearance", themeSwitch()) +
	tg(
		"Account",
		'<a class="li" href="/profile/edit"><span>Edit profile</span><span class="mu">›</span></a><a class="li" href="/settings"><span>Settings</span><span class="mu">›</span></a><a class="li" href="/history"><span>History</span><span class="mu">›</span></a><form method="post" action="/logout"><button class="li"><span class="neg">Log out</span><span class="mu">›</span></button></form>',
	);

const editM = (s: State) => `<div style="display:flex;justify-content:center;margin:14px 0 0">${avatar(s)}</div>` + tg("Profile", profileForm(s, "/profile"));

const settingsM = (s: State) =>
	err(s) +
	tg("Quick buys", quickEditor(s)) +
	tg("Money & income", prefsForm(s)) +
	tg("Data", dataButtons);

const settingsD = (s: State) =>
	'<div class="hd"><h1 class="t">Settings</h1><span></span></div>' +
	err(s) +
	`<div class="g3"><div>${sec("Profile", "", profileForm(s, "/home"))}${sec(
		"Account",
		"",
		`<form method="post" action="/logout"><button class="btn o">Log out</button></form>`,
	)}</div><div>${sec("Appearance", "", themeSwitch())}${sec("Quick buys", "", quickEditor(s))}${sec("Money & income", "", prefsForm(s))}${sec(
		"Data",
		"",
		dataButtons,
	)}</div></div>`;

const dashboardD = (s: State) =>
	hero(s) +
	`<div class="g2"><div>${sec("Quick buy", "tap, set quantity and price", quickD(s))}${sec("Today's buys", `${s.buys.length}`, buyRows(s))}</div><div>${oweD(s, false, "owe")}${incD(s, "Income today")}${noteD(s)}</div></div>`;

const debtsD = (s: State) => {
	const c = calc(s);
	return (
		`<div class="hd"><h1 class="t">Debts</h1><span class="lb">${fmt(c.oweMoney)} ${cur(s)} ${c.oweExtra}</span></div>` +
		`<div class="g3"><div>${oweD(s, true, "owe-page")}</div><div>${sec("Add", "new person or more to a name", newPerson(s).replace('<div class="sub">New person</div>', ""))}${sec(
			"How it works",
			"",
			'<div class="rw"><span>+ left of a name</span><span class="mu">adds to that person</span></div><div class="rw"><span>Pay</span><span class="mu">counts as a buy today</span></div><div class="rw"><span>Paid to 0</span><span class="mu">hidden, kept in history</span></div><div class="rw"><span>Type old name</span><span class="mu">brings them back</span></div>',
		)}</div></div>`
	);
};

const notesD = (s: State) => `<div class="chat" data-x>${chatHead}${noteList(s, "d")}<div style="margin:30px 0 0">${composer(s, "d")}</div></div>`;

const planD = (s: State) => `<div class="hd"><h1 class="t">Plan</h1><span class="lb">goals + income</span></div><div class="g3"><div>${wishD(s)}</div><div>${incD(s)}</div></div>`;

const historyD = (s: State) => `<div class="hd"><h1 class="t">History</h1><span class="lb">last 7 days</span></div>${histD(s)}`;

const base = (s: State) => ({
	theme: s.user.theme,
});

const homeBar = () => `<div style="text-align:right"><div style="font-size:14px;font-weight:600;letter-spacing:-.01em">Today</div><div class="lb">${longDay(today())}</div></div>`;

export const homePage = (s: State) =>
	page({
		...base(s),
		title: "Home",
		mobileTab: "home",
		desktopTab: "home",
		mobileBar: homeBar(),
		mobile: cardsM(s) + tgp("Income sources", "src", `<div>${srcRows(s)}</div><div class="pnl" data-pnl hidden>${addSourceForm(s, false)}</div>`) + quickM(s) + tgp(`Today's buys · ${s.buys.length}`, "buy", buyRows(s)) + goalFold(s, "goal") + oweM(s, false, "owe"),
		desktop: dashboardD(s),
	});

export const debtsPage = (s: State) =>
	page({
		...base(s),
		title: "Debts",
		mobileTab: "home",
		desktopTab: "home",
		mobile: hd("Debts", s.debts.map((d) => esc(d.person)).slice(0, 2).join(" + ")) + goalM(s) + oweM(s, true, "owe-page"),
		desktop: debtsD(s),
	});

export const notesPage = (s: State) =>
	page({ ...base(s), title: "Notes", mobileTab: "notes", desktopTab: "notes", mobile: chatHead + noteList(s, "m"), dock: composer(s, "m"), desktop: notesD(s) });

export const goalsPage = (s: State) =>
	page({ ...base(s), title: "Goals", mobileTab: "goals", desktopTab: "plan", mobile: hd("Goals", "wishes + debts") + goalM(s) + wishesM(s) + debtsM(s), desktop: planD(s) });

export const incomePage = (s: State) =>
	page({ ...base(s), title: "Income", mobileTab: "home", desktopTab: "plan", mobile: hd("Income", `+${fmt(calc(s).earned)} today`) + incomeM(s), desktop: planD(s) });

export const historyPage = (s: State) =>
	page({ ...base(s), title: "History", mobileTab: "history", desktopTab: "history", mobile: hd("History", "last 7 days") + histM(s), desktop: historyD(s) });

export const profilePage = (s: State) =>
	page({ ...base(s), title: "Profile", mobileTab: "profile", desktopTab: "settings", mobile: profileM(s), desktop: settingsD(s) });

export const profileEditPage = (s: State) =>
	page({ ...base(s), title: "Edit profile", mobileTab: "profile", desktopTab: "settings", mobile: hd("Edit profile", "", "/profile") + editM(s), desktop: settingsD(s) });

export const settingsPage = (s: State) =>
	page({ ...base(s), title: "Settings", mobileTab: "profile", desktopTab: "settings", mobile: hd("Settings", "", "/profile") + settingsM(s), desktop: settingsD(s) });
MT_EOF

echo "Done: wrangler.jsonc restored, .gitignore fixed, UI updated"
