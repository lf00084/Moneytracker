#!/usr/bin/env bash
set -e
if [ ! -f package.json ] || [ ! -d app ]; then echo "Run this inside the Moneytracker folder"; exit 1; fi
B="../$(basename "$PWD")-backup-$(date +%Y%m%d-%H%M%S).zip"
zip -qr "$B" . -x "node_modules/*" ".wrangler/*" ".git/*"
echo "Backup: $B"
rm -rf .mt_backup .mt_file7.css .mt_patch7.cjs file9.sh file10.sh file11.sh vite.client.config.ts bootstrap app scripts database package.json tsconfig.json vite.config.ts
cat > ".gitignore" << 'MT_EOF_7f3a9c'
node_modules
build
dist
.dev.vars
.wrangler
bun.lock
MT_EOF_7f3a9c
cat > ".npmrc" << 'MT_EOF_7f3a9c'
@jsr:registry=https://npm.jsr.io
MT_EOF_7f3a9c
mkdir -p "app/client"
cat > "app/client/app.css" << 'MT_EOF_7f3a9c'
:root:root:root{--pico-font-family:var(--font-sys);--pico-font-size:100%;--pico-line-height:1.45;--pico-background-color:var(--bg);--pico-color:var(--ink);--pico-muted-color:var(--mu);--pico-muted-border-color:var(--ln);--pico-primary:var(--ac);--pico-primary-background:var(--ac);--pico-primary-border:var(--ac);--pico-primary-hover:var(--ac);--pico-primary-hover-background:var(--ac);--pico-primary-hover-border:var(--ac);--pico-primary-focus:var(--acs);--pico-primary-inverse:var(--on);--pico-border-radius:12px;--pico-border-width:1px;--pico-outline-width:3px;--pico-block-spacing-vertical:0px;--pico-block-spacing-horizontal:0px;--pico-form-element-background-color:var(--s1);--pico-form-element-border-color:var(--ln);--pico-form-element-color:var(--ink);--pico-form-element-placeholder-color:var(--mu);--pico-form-element-active-background-color:var(--s1);--pico-form-element-active-border-color:var(--ac);--pico-form-element-focus-color:var(--ac);--pico-form-element-disabled-background-color:var(--s2);--pico-form-element-spacing-vertical:.8rem;--pico-form-element-spacing-horizontal:1rem;--pico-form-element-invalid-border-color:var(--neg);--pico-form-element-invalid-active-border-color:var(--neg);--pico-form-element-invalid-focus-color:var(--neg)}
html input:not([type=checkbox]):not([type=radio]):not([type=hidden]),html select,html textarea,form,h1,h2,h3{margin:0}
button:not(:focus-visible):focus{box-shadow:none}
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}
.cd,.sc,.xc,.hero{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background:var(--bg)}
a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}
button{cursor:pointer}
.mu,.lb{color:var(--mu)}
.lb{font-size:11px;font-family:var(--mono)}
.pos{color:var(--pos)!important}
.neg{color:var(--neg)!important}
.ea{color:var(--earn)!important}
.sp{color:var(--spend)!important}
.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}
details{margin:0}
details>summary:not([role])::after,details>summary::after{content:none}
details>summary:not([role]){color:inherit}
details[open]>summary{margin-bottom:0}
summary::-webkit-details-marker{display:none}
button,input[type=button],input[type=submit],.btn,.sbl,.chip,.ib{transition:transform .12s ease,opacity .12s ease}
button:active,.btn:active,.sbl:active,.chip:active,.ib:active{transform:scale(.97);opacity:.88}
.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI Arabic','Noto Sans Arabic','Geeza Pro',system-ui,sans-serif;font-weight:600;font-size:12px}
.tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}
.tf-clock .clock-date,.tf-clock .clock-subdate{display:none}
.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;padding:8px 4px}
@media(max-width:480px){
	.auth-glass-box{padding:8px 0}
}
.auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
.auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
.auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
.auth-err-banner{background:rgba(255,90,77,0.12);border:1px solid rgba(255,90,77,0.3);border-radius:12px;padding:10px 14px;color:var(--neg);font-size:13px;font-weight:500;text-align:center;margin:12px 0}
.auth-switch-wrap{display:flex;justify-content:center;margin-top:22px;text-align:center}
.lnk-switch{font-size:14px;color:var(--mu);text-decoration:none}
.lnk-switch b{color:var(--ac);text-decoration:underline;text-underline-offset:3px}
.lnk-switch:hover{color:var(--ink)}
@media(min-width:900px){
	.m{display:none!important}
}
@media(max-width:899px){
	.d{display:none!important}
}
.app{display:flex;min-height:100dvh;position:relative}
@media(max-width:899px){
	.app{flex-direction:column}
}
main{flex:1;min-width:0;position:relative}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:transparent}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}
.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib{flex:none;aspect-ratio:1}
.ib.sm{width:28px;height:28px;min-width:28px}
.ib svg.ic{width:16px;height:16px}
.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:var(--rc) var(--rc) 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{position:relative;flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{position:relative;width:26px;height:26px}
.bt a.on::before{content:"";position:absolute;width:52px;height:38px;border-radius:12px;background:var(--acs);border:1px solid var(--acl)}
.bt .on{color:var(--ac)}
.bt .on svg.ic{stroke-width:2}
.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);background:var(--s1);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:14px;font-size:16px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}
.sbl.on{font-weight:700;background:var(--acs);color:var(--ac)}
.sbl.on svg.ic{stroke-width:2}
.sbl svg.ic{width:24px;height:24px}
.sb .sp{flex:1}
h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}
.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}
.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}
.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}
.cd{margin-top:14px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}
.two .cb{padding:3px 12px 10px}
.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--s2);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ac);border-radius:4px}
.mt.n i{background:var(--spend)}
.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:6px 14px;font-size:12px;background:var(--s2);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer}
.chip:hover{color:var(--ink)}
.chip.on{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.chip.n{color:var(--spend);border-color:var(--spl)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.fl{margin-top:14px}
.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}
.ln{display:flex;gap:10px;align-items:center}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}
.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ac);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}
.sg{display:flex;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:4px;gap:4px}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:9px}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}
.pnl{margin-top:12px;padding-top:4px;border-top:1px solid var(--ln)}
.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}
.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);background:var(--s2);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}
.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--bg);border:1px solid var(--ln);border-radius:14px;padding:12px 14px;margin:4px 0 10px}
.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}
.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}
.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}
.bub.sel{outline:1.5px solid var(--ac)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}
.cm .eb b{font-weight:600}
.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}
.cin textarea{flex:1;background:var(--s1);border:1px solid var(--ln);border-radius:22px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink)}
.cin textarea:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ac);color:var(--on);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}
.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:12px;background:none;border:0;width:100%;text-align:left;color:var(--ink)}
.li:hover{background:var(--s2)}
.li:last-child{border:0}
.li:first-child{padding-top:14px}
.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}
.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--ln);font-weight:600;font-size:15px}
.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
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
.sf .in{display:block;margin-bottom:10px}
.sf .btn.full{margin-top:0}
.chips.nm{flex-wrap:nowrap;overflow-x:auto;margin:0 0 10px;padding-bottom:2px;scrollbar-width:none}
.chips.nm::-webkit-scrollbar{display:none}
.chips.nm .chip{flex:none;white-space:nowrap}
.bgc{display:flex;overflow:hidden;padding:0}
.bgc>.ct{flex:1;min-width:0}
.sc.bgc>.ct{padding:18px 22px 20px}
.addb{flex:none;width:64px;border:0;border-right:1px solid var(--acl);border-radius:0;background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0}
.addb svg.ic{width:30px;height:30px;stroke-width:2;transition:transform .18s ease}
.addb.on svg.ic{transform:rotate(45deg)}
.addb:active{transform:none;opacity:.8}
.bgc .adp{margin:6px 14px 14px}
.sc.bgc .adp{margin:14px 0 0}
.sc.bgc summary.sh{cursor:pointer}
.l1{gap:12px}
.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}
.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.ok{color:var(--earn)}
.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}
.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}
.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}
.spf .ln .in{flex:1 1 0}
.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.in.pr2{width:84px;flex:none;padding:6px 10px;font-size:13px;border-radius:10px}
.rw>.rt{max-width:62%;justify-content:flex-end}
.xc{position:relative;margin-top:14px;overflow:hidden;min-width:0}
.xh{display:flex;align-items:center;box-sizing:border-box;min-height:80px;padding:12px 112px 12px 16px;cursor:pointer;list-style:none;position:relative}
.xh::-webkit-details-marker{display:none}
.xh>div{min-width:0}
.xc .chev{position:absolute;right:66px;top:50%;margin-top:-10px}
.xp{position:absolute;right:12px;top:18px;width:46px;height:44px;border-radius:13px;border:1px solid var(--acl);background:var(--acs);color:var(--ac);display:flex;align-items:center;justify-content:center;padding:0;z-index:2}
.xp svg.ic{width:24px;height:24px;stroke-width:2;transition:transform .18s ease}
.xp.on svg.ic{transform:rotate(45deg)}
.xb{padding:4px 16px 8px;border-top:1px solid var(--ln)}
.xf{padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.xl{display:flex;justify-content:space-between;align-items:center;gap:10px;font-size:12px;color:var(--mu);font-family:var(--mono)}
.xl b{color:var(--ink);font-weight:600;white-space:nowrap}
.xf form{margin:12px 0 0}
.xfm .ln{gap:10px;margin:0}
.xfm .ln .in{flex:1 1 0;margin:0}
.xfm .ln .in.pr{flex:0 0 96px;width:96px}
.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}
.gw:last-child{border-bottom:0}
.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}
.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}
.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}
.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}
.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
.top-status-bar.tsplit{justify-content:space-between}
.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}
.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}
main{transition:opacity .2s ease}
html[data-nav=busy],html[data-nav=busy] a,html[data-nav=busy] button{cursor:progress}
html[data-nav=busy] main{opacity:.55}
button[data-busy]{cursor:progress}
.btn[data-busy]{opacity:.7}
.btn[data-busy]::after{content:"";display:inline-block;width:12px;height:12px;margin-left:8px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:spin .6s linear infinite;vertical-align:-2px}
@keyframes spin{to{transform:rotate(360deg)}}
@media(prefers-reduced-motion:reduce){
	main{transition:none}
	.btn[data-busy]::after{animation:none}
}
.trd{max-width:640px;margin:0 auto}
.tbn{margin:2px 0 6px;line-height:1.5}
.tbr{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px 0;border-bottom:1px solid var(--ln)}
.tbr:last-child{border-bottom:0;padding-bottom:0}
.tbr.lock{opacity:.45}
.tbf{display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0}
.tbf .in{width:96px;flex:0 1 96px;min-width:0;padding:8px 10px;font-size:14px;border-radius:12px}
.btn.win{background:rgba(76,195,138,.14);color:var(--pos);border-color:rgba(76,195,138,.45)}
.tbs{font-size:11px;font-weight:600;border:1px solid currentColor;border-radius:12px;padding:2px 9px;font-family:var(--mono)}
.sw{border-bottom:1px solid var(--ln)}
.sw:last-child{border:0}
.sw>.rw{border:0}
.hx{margin:0 0 12px;border:1px solid var(--ln);background:var(--bg);border-radius:14px;overflow:hidden}
.hx>summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 12px;list-style:none;cursor:pointer;font-size:12px;color:var(--mu);font-family:var(--mono)}
.hx>summary::-webkit-details-marker{display:none}
.hx>summary>span:nth-child(2){margin-left:auto;color:var(--earn)}
.hx[open]>summary .chev{transform:rotate(180deg)}
.hxb{padding:2px 12px 12px}
.hxg{display:grid;grid-template-columns:repeat(4,1fr);gap:8px}
.hc{display:flex;flex-direction:column;align-items:center;gap:2px;padding:9px 4px;border-radius:12px}
.hc b{font-size:14px;color:var(--ink)}
.hc small{font-size:11px;font-family:var(--mono)}
.hc.on b{color:var(--ac)}
.hxm{display:flex;gap:8px;align-items:center;margin-top:10px}
.hxm .in{padding:9px 12px;font-size:14px}
.hxm .btn{flex:none}
.kf{display:none;margin-top:2px}
form[data-kind=fixed] .kf-fixed,form[data-kind=manual] .kf-manual,form[data-kind=daily] .kf-daily,form[data-kind=monthly] .kf-monthly,form[data-kind=exoclick] .kf-exoclick{display:block}
.kf .in{margin-bottom:8px}
.kf .ln .in{margin-bottom:8px}
.kf .lb{margin-bottom:10px}
.ad>.in{display:block;width:100%}
.btn.miss{background:var(--s2);color:var(--mu);border-color:var(--ln)}

.btn{font-weight:600;font-size:15px;letter-spacing:.01em;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:999px;min-height:44px;padding:0 24px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center;box-shadow:0 1px 2px rgba(0,0,0,.28),0 1px 3px 1px rgba(0,0,0,.14);transition:box-shadow .2s,filter .2s,transform .12s}
.btn:hover{filter:brightness(1.07);box-shadow:0 1px 3px rgba(0,0,0,.28),0 4px 8px 3px rgba(0,0,0,.14)}
.btn.o{background:transparent;color:var(--ac);border:1px solid var(--acl);box-shadow:none}
.btn.o:hover{background:var(--acs);filter:none;box-shadow:none}
.btn.xs{min-height:32px;padding:0 14px;font-size:12px;box-shadow:none}
.btn.full{width:100%;min-height:52px;font-size:16px;font-weight:700;margin-top:20px}
.in{min-width:0;font-size:15px;font-family:inherit}
.gbtn{width:100%;min-height:48px;display:flex;align-items:center;justify-content:center;gap:10px;padding:0 20px;border-radius:999px;border:1px solid var(--ln);background:transparent;font-weight:600;font-size:15px;color:var(--ink);transition:background .2s,border-color .2s}
.gbtn:hover{background:var(--acs);border-color:var(--acl)}
.of{position:relative;margin-top:14px}
.of input{height:56px;padding:22px 16px 6px;border-radius:12px;font-size:16px}
.of label{position:absolute;left:17px;top:19px;margin:0;color:var(--mu);font-size:16px;line-height:1;pointer-events:none;transition:top .15s,font-size .15s,color .15s}
.of input::placeholder{color:transparent}
.of input:focus+label,.of input:not(:placeholder-shown)+label,.of input:-webkit-autofill+label{top:9px;font-size:11px;font-weight:600;color:var(--ac)}
MT_EOF_7f3a9c
mkdir -p "app/client"
cat > "app/client/app.js" << 'MT_EOF_7f3a9c'
(function () {
	if (window.__mt) return
	window.__mt = 1
	var d = document
	var r = d.documentElement
	var all = function (sel, root) {
		return [].slice.call((root || d).querySelectorAll(sel))
	}
	var focusFirst = function (box) {
		var i = box.querySelector("input:not([type=hidden])")
		if (i) i.focus()
	}

	function setTheme(t) {
		r.setAttribute("data-theme", t)
		try {
			localStorage.setItem("mtheme", t)
		} catch (e) {}
		try {
			fetch("/settings/theme", { method: "POST", body: new URLSearchParams({ theme: t }), credentials: "same-origin", redirect: "manual" })
		} catch (e) {}
	}

	function endEdit(c) {
		var id = c.querySelector("[data-eid]")
		if (id) id.value = ""
		var eb = c.querySelector(".eb")
		if (eb) eb.hidden = true
		c.querySelector("textarea").value = ""
	}

	var open = {}
	try {
		open = JSON.parse(localStorage.getItem("mt:open") || "{}")
	} catch (e) {}

	d.addEventListener(
		"toggle",
		function (e) {
			var x = e.target
			if (x.matches && x.matches("details[data-keep-open]")) {
				open[x.getAttribute("data-keep-open")] = x.open
				try {
					localStorage.setItem("mt:open", JSON.stringify(open))
				} catch (err) {}
			}
			if (x.matches && x.matches(".xd") && !x.open) {
				var xf = x.querySelector("[data-adp]")
				var xb = x.parentNode.querySelector("[data-xplus]")
				if (xf) xf.hidden = true
				if (xb) xb.classList.remove("on")
			}
		},
		true,
	)

	d.addEventListener("click", function (e) {
		var t = e.target
		var q = t.closest("button[name][value]")
		if (q && q.form) {
			var sh = q.form.querySelector('input[type=hidden][data-sub="' + q.name + '"]')
			if (!sh) {
				sh = d.createElement("input")
				sh.type = "hidden"
				sh.name = q.name
				sh.setAttribute("data-sub", q.name)
				q.form.appendChild(sh)
			}
			sh.value = q.value
		}
		if ((q = t.closest("[data-close]"))) {
			var cd = q.closest("details")
			if (cd) cd.open = false
			return
		}
		if (t.closest("[data-theme-toggle]")) return setTheme(r.getAttribute("data-theme") === "dark" ? "light" : "dark")
		if ((q = t.closest("[data-set-theme]"))) return setTheme(q.getAttribute("data-set-theme"))
		if ((q = t.closest("[data-eye]"))) {
			var v = q.parentNode.firstChild
			var hide = q.getAttribute("data-s") !== "1"
			q.setAttribute("data-s", hide ? "1" : "0")
			v.innerHTML = hide ? v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>" : "••••••"
			return
		}
		if ((q = t.closest("[data-edit-bal]"))) {
			var bf = q.closest(".cd,.sc").querySelector("[data-balf]")
			bf.hidden = !bf.hidden
			q.textContent = bf.hidden ? "Edit balance" : "Cancel"
			if (!bf.hidden) {
				var bi = bf.querySelector("input:not([type=hidden])")
				if (bi) {
					bi.focus()
					bi.select()
				}
			}
			return
		}
		if ((q = t.closest("[data-all]"))) {
			var af = q.closest(".iw").querySelector("input")
			af.value = q.getAttribute("data-all")
			af.focus()
			return
		}
		if ((q = t.closest("[data-tg],[data-pay]"))) {
			var add = q.hasAttribute("data-tg")
			var w = q.closest(".dbw")
			var p = w.querySelector(add ? "[data-addp]" : "[data-payp]")
			var o = w.querySelector(add ? "[data-payp]" : "[data-addp]")
			if (o) o.hidden = true
			p.hidden = !p.hidden
			if (!p.hidden) {
				var i = p.querySelector("input[name=amount]")
				if (i) i.focus()
			}
			return
		}
		if ((q = t.closest("[data-xplus]"))) {
			var xc = q.closest(".xc")
			var xd = xc.querySelector("details")
			var xm = xc.querySelector("[data-adp]")
			if (xm) {
				if (!xd.open) {
					xd.open = true
					xm.hidden = false
				} else xm.hidden = !xm.hidden
				q.classList.toggle("on", !xm.hidden)
				if (!xm.hidden) focusFirst(xm)
			}
			return
		}
		if ((q = t.closest("[data-nm]"))) {
			var nf = q.closest("form")
			nf.querySelector("[data-name]").value = q.getAttribute("data-nm")
			var pin = nf.querySelector("[data-price]")
			if (pin) pin.focus()
			return
		}
		if ((q = t.closest("[data-bigadd]"))) {
			var tf = q.getAttribute("data-for")
			var ap = tf ? d.getElementById(tf) : q.closest(".bgc").querySelector("[data-adp]")
			ap.hidden = !ap.hidden
			q.classList.toggle("on", !ap.hidden)
			if (!ap.hidden) focusFirst(ap)
			return
		}
		if ((q = t.closest("[data-mode]"))) {
			var form = q.closest("form")
			var mode = q.getAttribute("data-mode")
			all("[data-mode]", form).forEach(function (c) {
				c.classList.toggle("on", c === q)
			})
			form.querySelector("[data-mode-input]").value = mode
			form.setAttribute("data-kind", mode)
			form.setAttribute("data-m", mode)
			return
		}
		if ((q = t.closest(".bub"))) {
			q.classList.toggle("sel")
			var a = q.parentNode.querySelector(".acts")
			a.hidden = !a.hidden
			return
		}
		if ((q = t.closest("[data-act]"))) {
			var m = q.closest(".msg")
			var act = q.getAttribute("data-act")
			var body = m.querySelector(".bub").textContent
			if (act === "copy") {
				try {
					navigator.clipboard.writeText(body)
				} catch (x) {}
			} else if (act === "edit") {
				var c = d.querySelector('[data-comp="' + m.parentNode.getAttribute("data-list") + '"]')
				c.querySelector("[data-eid]").value = m.getAttribute("data-id")
				c.querySelector(".eb").hidden = false
				var ta = c.querySelector("textarea")
				ta.value = body
				ta.focus()
			}
			return
		}
		if ((q = t.closest("[data-cancel]"))) endEdit(q.closest("[data-comp]"))
	})

	d.addEventListener(
		"click",
		function (e) {
			var b = e.target.closest && e.target.closest("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn"))) e.preventDefault()
		},
		true,
	)

	d.addEventListener("submit", function (e) {
		var f = e.target
		var msg = f.getAttribute && f.getAttribute("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		setTimeout(function () {
			if (e.defaultPrevented) return
			all("button", f).forEach(function (b) {
				if (!b.disabled) {
					b.disabled = true
					b.setAttribute("data-busy", "1")
				}
			})
		}, 0)
	})

	function unbusy() {
		all("button[data-busy]").forEach(function (b) {
			b.disabled = false
			b.removeAttribute("data-busy")
		})
	}
	window.addEventListener("pageshow", function (e) {
		if (e.persisted) unbusy()
	})

	d.addEventListener("keydown", function (e) {
		var t = e.target
		if (e.key !== "Enter" || e.shiftKey || !(t.matches && t.matches("[data-comp] textarea"))) return
		e.preventDefault()
		if (t.value.trim()) t.closest("form").requestSubmit()
	})

	var zone = "Africa/Casablanca"
	var fmt = function (loc, o) {
		o.timeZone = zone
		return new Intl.DateTimeFormat(loc, o)
	}
	var tf = fmt("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })
	var df = fmt("en-GB", { weekday: "long", day: "numeric", month: "long" })
	var nf = fmt("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })
	var af = fmt("ar-MA", { weekday: "long" })
	function tick() {
		var now = new Date()
		var sub = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + "</span>"
		all("[data-clock-time]").forEach(function (el) {
			el.textContent = tf.format(now)
		})
		all("[data-clock-date]").forEach(function (el) {
			el.textContent = df.format(now)
		})
		all("[data-clock-subdate]").forEach(function (el) {
			el.innerHTML = sub
		})
	}
	setInterval(tick, 1000)

	all("details[data-keep-open]").forEach(function (x) {
		var k = x.getAttribute("data-keep-open")
		if (k in open) x.open = !!open[k]
	})

	var rb = false
	try {
		rb = sessionStorage.getItem("mt:rb") === "1"
		sessionStorage.removeItem("mt:rb")
	} catch (e) {}
	if (rb) all("[data-eye]").forEach(function (q) {
		q.setAttribute("data-s", "1")
		var v = q.parentNode.firstChild
		v.innerHTML = v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>"
	})

	all("[data-list]").forEach(function (L) {
		var last = L.lastElementChild
		if (L.getAttribute("data-list") !== "dash" && last && last.scrollIntoView) last.scrollIntoView({ block: "end" })
	})

	var loaded = Date.now()
	setInterval(function () {
		if (!d.querySelector("[data-exo]") || d.hidden || Date.now() - loaded < 240000) return
		var a = d.activeElement
		if (a && a.matches && a.matches("input,textarea,select")) return
		if (d.querySelector("[data-adp]:not([hidden]),[data-addp]:not([hidden])")) return
		try {
			if (d.querySelector('[data-eye][data-s="1"]')) sessionStorage.setItem("mt:rb", "1")
		} catch (e) {}
		location.reload()
	}, 30000)
})()
MT_EOF_7f3a9c
mkdir -p "app"
cat > "app/commands.ts" << 'MT_EOF_7f3a9c'
import * as act from "./lib/actions.ts"
import * as inc from "./lib/income.ts"
import { toMinor } from "./lib/money.ts"
import * as trading from "./lib/trading.ts"
import { setTheme, updatePrefs, updateProfile, type User } from "./lib/users.ts"

export type Command = {
	run: (user: User, f: FormData) => Promise<unknown>
	to: string
	back?: boolean
	fail?: string
	empty?: boolean
}

const field = (f: FormData, key: string) => String(f.get(key) ?? "")

const quiet = (fn: (u: User, f: FormData) => Promise<unknown>) => async (u: User, f: FormData) => {
	await fn(u, f)
}

export const commands = {
	buy: { run: (u, f) => act.addBuy(u.id, f), to: "/home" },
	deleteBuy: { run: (u, f) => act.deleteBuy(u.id, f), to: "/home" },
	setBalance: { run: (u, f) => act.setBalance(u.id, f), to: "/profile" },
	historyIncome: { run: (u, f) => act.addDayIncome(u.id, f), to: "/history" },
	addDebt: { run: (u, f) => act.addDebt(u.id, f), to: "/debts" },
	payDebt: { run: (u, f) => act.payDebt(u.id, f), to: "/debts" },
	clearDebt: { run: (u, f) => act.clearDebt(u.id, f), to: "/debts" },
	addNote: { run: quiet((u, f) => act.saveNote(u.id, f)), to: "/notes" },
	deleteNote: { run: quiet((u, f) => act.deleteNote(u.id, f)), to: "/notes" },
	addWish: { run: (u, f) => act.addGoal(u.id, f), to: "/goals" },
	buyWish: { run: (u, f) => act.buyWish(u.id, f), to: "/goals" },
	deleteWish: { run: (u, f) => act.deleteWish(u.id, f), to: "/goals" },
	editGoal: { run: (u, f) => act.editGoal(u.id, f), to: "/goals" },
	editGoalItem: { run: (u, f) => act.editGoalItem(u.id, f), to: "/goals" },
	addGoalItem: { run: (u, f) => act.addGoalItem(u.id, f), to: "/goals" },
	deleteGoalItem: { run: (u, f) => act.deleteGoalItem(u.id, f), to: "/goals" },
	addSource: { run: (u, f) => inc.addSource(u.id, f), to: "/income" },
	setHours: { run: (u, f) => inc.setHours(u.id, f), to: "/home" },
	addNamed: { run: (u, f) => inc.addNamed(u.id, f), to: "/home" },
	addIncome: { run: (u, f) => act.addIncome(u.id, f), to: "/income" },
	deleteIncome: { run: (u, f) => act.deleteIncome(u.id, f), to: "/income" },
	toggleSource: { run: (u, f) => act.toggleSource(u.id, f), to: "/income" },
	editSource: { run: (u, f) => inc.editSource(u.id, f), to: "/income" },
	deleteSource: { run: (u, f) => act.deleteSource(u.id, f), to: "/income" },
	tradeDeposit: { run: (u) => trading.startTrade(u), to: "/trading" },
	tradeSet: { run: (u, f) => trading.setPredict(u.id, f), to: "/trading" },
	tradeResult: { run: (u, f) => trading.saveResult(u.id, f), to: "/trading" },
	tradeUndo: { run: (u, f) => trading.undoResult(u.id, f), to: "/trading" },
	tradeFinish: { run: (u, f) => trading.finishTrade(u.id, f), to: "/trading" },
	tradeReopen: { run: (u, f) => trading.reopenTrade(u.id, f), to: "/trading" },
	saveProfile: { run: (u, f) => updateProfile(u.id, { name: field(f, "name"), email: field(f, "email") }), to: "/profile", back: false, fail: "/profile/edit" },
	saveSettings: {
		run: quiet((u, f) => updatePrefs(u.id, { currency: field(f, "currency"), run_at: field(f, "run_at"), week_start: field(f, "week"), usdt_rate_minor: toMinor(f.get("usdt")), usd_rate_minor: toMinor(f.get("usd_rate")) })),
		to: "/settings",
	},
	setTheme: { run: quiet((u, f) => setTheme(u.id, field(f, "theme"))), to: "/settings", empty: true },
} satisfies Record<string, Command>

export type CommandName = keyof typeof commands

export const errorOf = (r: unknown) => (typeof r === "string" && r ? r : "")
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/buys.tsx" << 'MT_EOF_7f3a9c'
import type { Buy, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Back, Card, Empty, ExpandCard, Icon, ListCard, NameChips, view } from "./ui.tsx"

export const buyName = (b: Buy) => (b.qty > 1 ? `${b.name} ×${b.qty}` : b.name)

export const SpendRow = view<{ s: State; id: string; name: string; sub: string; amount: string }>(({ s, id, name, sub, amount }) => (
	<div class="by">
		<div>
			<div>{name}</div>
			<div class="lb">{sub}</div>
		</div>
		<span class="rt">
			<b class="sp">{amount}</b>
			<form method="post" action="/buy/delete" style={{ display: "contents" }} data-confirm="Undo this buy? The money comes back.">
				<Back s={s} />
				<input type="hidden" name="id" value={id} />
				<button class="ub" aria-label="Undo buy">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
))

const BuyRows = view<{ s: State }>(({ s }) => (
	<div>
		{s.buys.length ? (
			s.buys.map((b) => <SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={`${hhmm(b.at)}${b.qty > 1 ? ` · ${b.qty} × ${fmt(b.unit)}` : ""}`} amount={`−${fmt(b.total)}`} />)
		) : (
			<Empty>Nothing bought today.</Empty>
		)}
	</div>
))

const SpendFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.names} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Item" autocomplete="off" required />
			<input class="in pr" name="price" data-price placeholder="Price" inputmode="decimal" autocomplete="off" required />
		</div>
		<button class="btn full">Add a spend</button>
	</>
))

export const BuysExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="buys"
		open
		title="Today's buys"
		label="Add a spend"
		form={
			<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>
				<SpendFields s={s} />
			</form>
		}
	>
		<BuyRows s={s} />
	</ExpandCard>
))

export const BuysDesktop = view<{ s: State }>(({ s }) => (
	<>
		<form method="post" action="/buy" id="f-buy-d" class="sc spf" data-sp data-adp hidden>
			<SpendFields s={s} />
		</form>
		<ListCard title="Today's buys" right={`${s.buys.length}`} target="f-buy-d" label="Add a spend">
			<BuyRows s={s} />
		</ListCard>
	</>
))

export const TodayCards = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="two">
			<Card title="Earned today">
				<div class="big2" style={{ whiteSpace: "nowrap" }}>
					+{fmt(c.earned)} <small>{s.user.currency}</small>
				</div>
			</Card>
			<Card title="Bought today">
				<div class="big2" style={{ whiteSpace: "nowrap" }}>
					−{fmt(c.bought)} <small>{s.user.currency}</small>
				</div>
			</Card>
		</div>
	)
})

export const Hero = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hero">
			<div>
				<div class="lb">Earned today</div>
				<div class="v">+{fmt(c.earned)}</div>
				{c.earnedLine ? <div class="lb">{c.earnedLine}</div> : null}
			</div>
			<div>
				<div class="lb">Bought today</div>
				<div class="v">−{fmt(c.bought)}</div>
				<div class="lb">{s.buys.length} buys</div>
			</div>
			<div>
				<div class="lb">Road to goals</div>
				<div class="v">{c.pct}%</div>
				<div class="mt">
					<i style={{ width: `${c.pct}%` }}></i>
				</div>
			</div>
			<div>
				<div class="lb">I owe</div>
				<div class="v sp">{fmt(c.oweMoney)}</div>
				<div class="lb">
					{s.user.currency} {c.oweExtra}
				</div>
			</div>
		</div>
	)
})
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/debts.tsx" << 'MT_EOF_7f3a9c'
import type { DebtView, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { calc, debtPct, peopleCount, pctOf } from "../lib/view.ts"
import { Back, BigAdd, Empty, ExpandCard, Icon, NameChips, view } from "./ui.tsx"

type DebtProps = { s: State; d: DebtView }

const DebtPanel = view<DebtProps & { kind: "add" | "pay" }>(({ s, d, kind }) => {
	const pay = kind === "pay"
	const unit = d.kind === "money" ? s.user.currency : d.item
	const all = d.kind === "money" ? plain(d.owed) : String(d.owed)
	return (
		<form method="post" action={pay ? "/debts/pay" : "/debts"} class="ad" data-addp={pay ? undefined : true} data-payp={pay ? true : undefined} hidden>
			<input type="hidden" name="debt_id" value={d.id} />
			<Back s={s} />
			<label>
				{pay ? "Pay" : "Add to"} {d.person}
			</label>
			<div class="ln">
				<div class="iw">
					<input class="in f" name="amount" inputmode="decimal" placeholder="0" autocomplete="off" />
					{pay ? (
						<button type="button" class="all" data-all={all} aria-label="Fill the full amount">
							All
						</button>
					) : null}
					<span class="mu">{unit}</span>
				</div>
				<button class="btn xs">{pay ? "Pay" : "Add"}</button>
				<button class="ub" formaction="/debts/clear" formnovalidate data-confirm-btn={`Remove ${d.person} from the list without marking it paid?`} aria-label="Remove without paying">
					<Icon name="trash" />
				</button>
			</div>
		</form>
	)
})

const DebtRow = view<DebtProps>(({ s, d }) => {
	const label = d.kind === "money" ? `${fmt(d.owed)} ${s.user.currency}` : `${d.owed} ${d.item}`
	return (
		<div class="dbw">
			<div class="db">
				<button type="button" class="ib sm hi" data-tg aria-label={`Add debt to ${d.person}`}>
					<Icon name="plus" />
				</button>
				<div class="dn">
					<div class="l1">
						<b>{d.person}</b>
						<span>{label}</span>
					</div>
					<div class="mt s n">
						<i style={{ width: `${debtPct(d)}%` }}></i>
					</div>
				</div>
				<button type="button" class="btn xs o" data-pay>
					Pay
				</button>
			</div>
			<DebtPanel s={s} d={d} kind="add" />
			<DebtPanel s={s} d={d} kind="pay" />
		</div>
	)
})

const DebtList = view<{ s: State }>(({ s }) => (s.debts.length ? <>{s.debts.map((d) => <DebtRow key={d.id} s={s} d={d} />)}</> : <Empty>Nobody to pay. All clear.</Empty>))

const AddDebtPanel = view<{ s: State }>(({ s }) => (
	<form method="post" action="/debts" class="sf adp" data-adp hidden>
		<Back s={s} />
		<NameChips names={[...new Set(s.debts.map((d) => d.person))]} />
		<input class="in" name="name" data-name placeholder="Person name" autocomplete="off" required />
		<div class="iw">
			<input class="in" name="amount" data-price placeholder="Debt amount" inputmode="decimal" autocomplete="off" required />
			<span class="mu">{s.user.currency}</span>
		</div>
		<button class="btn full">Add</button>
	</form>
))

type OweProps = { s: State; open: boolean; storeKey: string }

export const OweMobile = view<OweProps>(({ s, open, storeKey }) => {
	const c = calc(s)
	const n = peopleCount(s)
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="I owe"
			label="Add debt"
			head={
				<>
					<b class="big2 sp">
						{fmt(c.oweMoney)} <small>{s.user.currency}</small>
					</b>
					<span class="sp sm">{c.oweExtra}</span>
				</>
			}
			foot={
				<div class="xl">
					<span>{n === 1 ? "1 person" : `${n} people`}</span>
				</div>
			}
			form={<AddDebtPanel s={s} />}
		>
			<DebtList s={s} />
		</ExpandCard>
	)
})

export const OweDesktop = view<OweProps>(({ s, open, storeKey }) => {
	const c = calc(s)
	return (
		<div class="sc bgc">
			<BigAdd label="Add debt" />
			<div class="ct">
				<details data-keep-open={storeKey} open={open ? true : undefined}>
					<summary class="sh">
						<span>I owe</span>
						<span class="rr">
							<span class="lb">{`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`}</span>
							<span class="chev">
								<Icon name="chev" />
							</span>
						</span>
					</summary>
					<DebtList s={s} />
				</details>
				<AddDebtPanel s={s} />
			</div>
		</div>
	)
})

export const RoadCard = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	const chips = [
		...s.goals.map((g) => ({ key: `g${g.id}`, text: `${g.title} ${pctOf(s, g)}%` })),
		...s.debts.filter((d) => d.kind === "money").map((d) => ({ key: `d${d.id}`, text: `${d.person} ${debtPct(d)}%` })),
	]
	return (
		<div class="cd jarc">
			<i class="jar" style={{ width: `${c.pct}%` }}></i>
			<div class="jin">
				<div class="tg">Road to goals</div>
				<div class="cb">
					<div class="gl">
						<span class="big">
							{c.pct}
							<small>%</small>
						</span>
						<span class="lb">{`${fmt(c.toGo)} ${s.user.currency} to go`}</span>
					</div>
					{chips.length ? (
						<div class="chips">
							{chips.map((x) => (
								<span key={x.key} class="chip">
									{x.text}
								</span>
							))}
						</div>
					) : null}
				</div>
			</div>
		</div>
	)
})
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/goals.tsx" << 'MT_EOF_7f3a9c'
import type { Goal, GoalItem, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { canAfford, goalLeft, goalStat, pctOf } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, view } from "./ui.tsx"

const contents = { display: "contents" }

const ItemRow = view<{ s: State; it: GoalItem; manage: boolean }>(({ s, it, manage }) => {
	const ok = canAfford(s, it)
	const cls = it.done ? "gi gdone" : "gi"
	const hid = () => (
		<>
			<Back s={s} />
			<input type="hidden" name="id" value={it.id} />
		</>
	)
	const name = (
		<>
			<span class="gn">{it.name}</span>
			<span class="lb">{fmt(it.price)}</span>
		</>
	)

	if (!manage) {
		return (
			<div class={cls}>
				{name}
				<span class="wb">
					{it.done ? null : (
						<form method="post" action="/goals/buy" style={contents} data-confirm={`Mark ${it.name} as bought? It will be added as a spend.`}>
							{hid()}
							<button class={ok ? "btn xs" : "btn xs off"} disabled={ok ? undefined : true}>
								Bought
							</button>
						</form>
					)}
				</span>
			</div>
		)
	}

	return (
		<div class="dbw">
			<div class={cls}>
				{name}
				<span class="wb">
					{it.done ? null : (
						<button type="button" class="ub" data-pay aria-label={`Edit ${it.name}`}>
							<Icon name="edit" />
						</button>
					)}
					<form method="post" action="/goals/item/delete" style={contents} data-confirm={`Remove ${it.name} from this goal?`}>
						{hid()}
						<button class="ub" aria-label={`Remove ${it.name}`}>
							<Icon name="trash" />
						</button>
					</form>
				</span>
			</div>
			{it.done ? null : (
				<form method="post" action="/goals/item/edit" class="ad" data-payp hidden>
					{hid()}
					<label>Edit {it.name}</label>
					<div class="ln">
						<input class="in f" name="name" value={it.name} autocomplete="off" required />
						<input class="in pr2" name="price" value={plain(it.price)} placeholder="Price" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs">Save</button>
					</div>
				</form>
			)}
		</div>
	)
})

const GoalRow = view<{ s: State; g: Goal; manage: boolean }>(({ s, g, manage }) => {
	const pct = pctOf(s, g)
	const info = (
		<div class="dn">
			<div class="l1">
				<b>{g.title}</b>
				<span class="lb">{goalLeft(s, g)}</span>
			</div>
			<div class={pct >= 100 ? "mt s full" : "mt s"}>
				<i style={{ width: `${pct}%` }}></i>
			</div>
		</div>
	)
	const items = g.items.map((it) => <ItemRow key={it.id} s={s} it={it} manage={manage} />)

	if (!manage) {
		return (
			<div class="gw">
				<div class="db">{info}</div>
				{items}
			</div>
		)
	}

	return (
		<div class="gw">
			<div class="dbw">
				<div class="db">
					<button type="button" class="ib sm hi" data-tg aria-label={`Add item to ${g.title}`}>
						<Icon name="plus" />
					</button>
					{info}
					<span class="wb">
						<button type="button" class="ub" data-pay aria-label={`Rename ${g.title}`}>
							<Icon name="edit" />
						</button>
						<form method="post" action="/goals/delete" style={contents} data-confirm={`Delete ${g.title} and all its items?`}>
							<Back s={s} />
							<input type="hidden" name="id" value={g.id} />
							<button class="ub" aria-label={`Delete ${g.title}`}>
								<Icon name="trash" />
							</button>
						</form>
					</span>
				</div>
				<form method="post" action="/goals/item" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="goal_id" value={g.id} />
					<label>Add item to {g.title}</label>
					<div class="ln">
						<input class="in f" name="name" placeholder="Item to buy" autocomplete="off" required />
						<input class="in pr2" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs">Add</button>
					</div>
				</form>
				<form method="post" action="/goals/edit" class="ad" data-payp hidden>
					<Back s={s} />
					<input type="hidden" name="id" value={g.id} />
					<label>Rename goal</label>
					<div class="ln">
						<input class="in f" name="name" value={g.title} autocomplete="off" required />
						<button class="btn xs">Save</button>
					</div>
				</form>
			</div>
			{items}
		</div>
	)
})

const GoalList = view<{ s: State; manage: boolean }>(({ s, manage }) =>
	s.goals.length ? (
		<>{s.goals.map((g) => <GoalRow key={g.id} s={s} g={g} manage={manage} />)}</>
	) : (
		<Empty>{manage ? "No goals yet. Tap + to add one." : "No goals yet. Add some in Manage."}</Empty>
	),
)

const GoalForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/goals" class="sf xfm" data-adp hidden>
		<Back s={s} />
		<input class="in" name="name" placeholder="Goal name" autocomplete="off" required />
		<button class="btn full">Add goal</button>
	</form>
))

export const GoalsExpand = view<{ s: State; open: boolean; storeKey: string; manage: boolean }>(({ s, open, storeKey, manage }) => {
	const g = goalStat(s)
	const sub = !g.target ? (g.pct === 100 ? "all bought" : "no items yet") : g.pct >= 100 ? "ready to buy" : `${fmt(g.toGo)} ${s.user.currency} to go`
	const head = (
		<>
			<b class="big2">
				{g.pct}
				<small>%</small>
			</b>
			<span class="lb">{sub}</span>
		</>
	)
	if (manage) {
		return (
			<ExpandCard
				storeKey={storeKey}
				open={open}
				title="Goals"
				head={head}
				jar={g.pct}
				label="Add goal"
				foot={
					<div class="xl">
						<span>Pencil edits, bin removes</span>
					</div>
				}
				form={<GoalForm s={s} />}
			>
				<GoalList s={s} manage />
			</ExpandCard>
		)
	}
	return (
		<ExpandCard
			storeKey={storeKey}
			open={open}
			title="Goals"
			head={head}
			jar={g.pct}
			foot={
				<div class="xl">
					<span>{`Left to buy ${fmt(g.target)} ${s.user.currency}`}</span>
					<a class="lnk" href="/goals">
						Manage
					</a>
				</div>
			}
		>
			<GoalList s={s} manage={false} />
		</ExpandCard>
	)
})
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/history.tsx" << 'MT_EOF_7f3a9c'
import type { DayRow, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { dayNet } from "../lib/view.ts"
import { buyName, SpendRow } from "./buys.tsx"
import { IncomeRow } from "./income.tsx"
import { Back, Card, ErrorBanner, PageHeader, Section, view } from "./ui.tsx"

const DayItems = view<{ s: State; d: DayRow }>(({ s, d }) => (
	<>
		{d.incomes.map((i) => (
			<IncomeRow key={i.id} s={s} i={i} />
		))}
		{d.buys.map((b) => (
			<SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : ""} amount={`−${fmt(b.total)}`} />
		))}
	</>
))

const DayForms = view<{ s: State; wide: boolean }>(({ s, wide }) => {
	const t = today()
	const body = (
		<>
			<form method="post" action="/buy">
				<Back s={s} />
				<div class="ln">
					<input class="in" name="label" placeholder="Item" autocomplete="off" required />
					<input class="in pr" name="price" placeholder="Price" inputmode="decimal" autocomplete="off" required />
				</div>
				<div class="ln" style={{ marginTop: "8px" }}>
					<input class="in" type="date" name="day" value={t} max={t} required />
					<button class="btn xs">Add buy</button>
				</div>
			</form>
			<form method="post" action="/history/income" style={{ marginTop: "14px" }}>
				<Back s={s} />
				<div class="ln">
					<input class="in" name="label" placeholder="Name (optional)" autocomplete="off" />
					<input class="in pr" name="amount" placeholder="Income" inputmode="decimal" autocomplete="off" required />
				</div>
				<div class="ln" style={{ marginTop: "8px" }}>
					<input class="in" type="date" name="day" value={t} max={t} required />
					<button class="btn xs">Add income</button>
				</div>
			</form>
		</>
	)
	return wide ? <Section title="Add to any day">{body}</Section> : <Card title="Add to any day">{body}</Card>
})

export const HistoryMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<DayForms s={s} wide={false} />
		{s.days.map((d) => (
			<Card key={d.day} title={d.label}>
				<div class="l1">
					<span>
						<span class="lb">Earned</span> <b class="ea">+{fmt(d.earned)}</b>
					</span>
					<span>
						<span class="lb">Bought</span> <b class="sp">−{fmt(d.bought)}</b>
					</span>
					<b>{dayNet(d.earned, d.bought)}</b>
				</div>
				<DayItems s={s} d={d} />
			</Card>
		))}
	</>
))

export const HistoryDesktop = view<{ s: State }>(({ s }) => {
	const earned = s.days.reduce((a, d) => a + d.earned, 0)
	const bought = s.days.reduce((a, d) => a + d.bought, 0)
	return (
		<>
			<PageHeader title="History" right="last 30 days" />
			<ErrorBanner s={s} />
			<DayForms s={s} wide />
			<Section title="Last 30 days" right={`+${fmt(earned)} earned · −${fmt(bought)} bought`}>
				<div class="th">
					<span>Day</span>
					<span>Earned</span>
					<span>Bought</span>
					<span>Net</span>
					<span>What</span>
				</div>
				{s.days.map((d) => (
					<div key={d.day} class="tr">
						<b>{d.label}</b>
						<b class="ea">+{fmt(d.earned)}</b>
						<b class="sp">−{fmt(d.bought)}</b>
						<b>{dayNet(d.earned, d.bought)}</b>
						<div>
							<DayItems s={s} d={d} />
						</div>
					</div>
				))}
			</Section>
		</>
	)
})
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/income.tsx" << 'MT_EOF_7f3a9c'
import type { Income, Source, State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { isFixed } from "../lib/util.ts"
import { calc, gotToday, srcAmount } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, view } from "./ui.tsx"

const contents = { display: "contents" }
const rateOf = (x: Source) => Number(x.config.rate_minor) || 0
const tagOf = (x: Source) => (!x.active ? "paused" : x.type === "exoclick" ? "exoclick" : isFixed(x.type) ? "fixed" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "daily") : "manual")
const usdTxt = (n: number) => `$${fmt(n)}`
const exoSub = (s: State, x: Source) => s.exo[x.id] || `${usdTxt(s.exoToday[x.id] ?? 0)} today`

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
))

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`incl. ${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">+{fmt(i.amount)}</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}>
				<Back s={s} />
				<input type="hidden" name="id" value={i.id} />
				<button class="ub" aria-label="Undo income">
					<Icon name="undo" />
				</button>
			</form>
		</span>
	</div>
))

const HoursPanel = view<{ s: State; x: Source; row: Income }>(({ s, x, row }) => {
	const rate = rateOf(x)
	const h = row.hours
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`} open={h ? undefined : true}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))}` : `${fmt(rate)} / hour`}</span>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hxb">
				<div class="hxg">
					{opts.map((n) => (
						<form key={n} method="post" action="/income/hours" style={contents}>
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input type="hidden" name="hours" value={String(n)} />
							<input type="hidden" name="toggle" value="1" />
							<button class={h === n ? "chip hc on" : "chip hc"}>
								<b>{n}h</b>
								<small>+{fmt(n * rate)}</small>
							</button>
						</form>
					))}
				</div>
				<form method="post" action="/income/hours" class="hxm">
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<input class="in" name="hours" value={h && !opts.includes(h) ? String(h) : ""} placeholder="Other hours" inputmode="decimal" autocomplete="off" />
					<button class="btn xs o">Set</button>
					<button type="button" class="btn xs o" data-close>
						Close
					</button>
				</form>
			</div>
		</details>
	)
})

const SourceMain = view<{ s: State; x: Source; toggle: boolean }>(({ s, x, toggle }) => {
	const got = gotToday(s, x)
	const sum = got.reduce((a, i) => a + i.amount, 0)
	const fixed = srcAmount(x)
	if (toggle && !x.active) {
		return (
			<form method="post" action="/income/toggle" style={contents}>
				<Hid s={s} id={x.id} />
				<button class="btn xs o">Resume</button>
			</form>
		)
	}
	if (x.type === "exoclick") {
		return (
			<>
				<b class="ea">+{fmt(sum)}</b>
				{s.exo[x.id] ? (
					<a class="btn xs o" href="/income">
						Fix
					</a>
				) : null}
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				<b class="ea">+{fmt(x.amount)}</b>
				{toggle ? (
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">Pause</button>
					</form>
				) : null}
			</>
		)
	}
	if (got.length) {
		return (
			<>
				<b class="ea">+{fmt(sum)}</b>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		)
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o">Add {fmt(fixed)}</button>
			</form>
		)
	}
	return (
		<form method="post" action="/income/add" class="ln" style={{ gap: "6px" }}>
			<Back s={s} />
			<input type="hidden" name="source_id" value={x.id} />
			<input class="in pr2" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs o">Add</button>
		</form>
	)
})

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
))

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const got = fixedSrc ? gotToday(s, x)[0] : undefined
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} + ${fmt(rateOf(x))} / hour`) : ""
	return (
		<div class="sw" data-exo={x.type === "exoclick" ? "1" : undefined}>
			<div class="rw">
				<div>
					<div>{x.name}</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle={false} />
				</span>
			</div>
			{got ? <HoursPanel s={s} x={x} row={got} /> : null}
		</div>
	)
})

const NamedFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<NameChips names={s.incNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Name (e.g. Tip)" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
		</div>
		<button class="btn full">Add income</button>
	</>
))

const KINDS: [string, string][] = [
	["fixed", "Fixed + hours"],
	["manual", "Manual"],
	["daily", "Auto daily"],
	["monthly", "Monthly"],
	["exoclick", "ExoClick"],
]

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<input class="in" name="name" placeholder="Source name (e.g. Construction)" autocomplete="off" required />
		<input type="hidden" name="kind" value="fixed" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 8px" }}>
			{KINDS.map(([k, l]) => (
				<span key={k} class={k === "fixed" ? "chip on" : "chip"} data-mode={k} style={{ cursor: "pointer" }}>
					{l}
				</span>
			))}
		</div>
		<div class="kf kf-fixed">
			<div class="ln">
				<input class="in" name="fixed" placeholder="Per day" inputmode="decimal" autocomplete="off" />
				<input class="in" name="rate" placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
			</div>
			<div class="lb">Tap it once a day on Home, then pick the extra hours.</div>
		</div>
		<div class="kf kf-manual">
			<div class="lb">You type the amount yourself each day.</div>
		</div>
		<div class="kf kf-daily kf-monthly">
			<input class="in" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
			<div class="lb">Added for you automatically.</div>
		</div>
		<div class="kf kf-exoclick">
			<input class="in" name="api_key" type="password" placeholder="ExoClick API key" autocomplete="off" />
			<div class="lb">Saved encrypted. Counted in USD during the day, converted to {s.user.currency} when the day ends.</div>
		</div>
		<button class="btn full">Add source</button>
	</>
))

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-kind="fixed" data-adp hidden>
		<SourceFields s={s} />
	</form>
))

export const IncomeDesktop = view<{ s: State; title?: string; id?: string }>(({ s, title = "Income today", id = "f-inc-d" }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return (
		<>
			<form method="post" action="/income/named" id={id} class="sc spf" data-adp hidden>
				<NamedFields s={s} />
			</form>
			<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add manual income">
				{sources.length || others.length ? (
					<>
						{sources.map((x) => (
							<HomeRow key={x.id} s={s} x={x} />
						))}
						{others.map((i) => (
							<IncomeRow key={i.id} s={s} i={i} />
						))}
					</>
				) : (
					<Empty>No sources yet. Add one on the Income page.</Empty>
				)}
			</ListCard>
		</>
	)
})

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixedSrc = isFixed(x.type)
	const fixed = srcAmount(x)
	const cur = s.user.currency
	const sub = x.type === "exoclick" ? exoSub(s, x) : fixedSrc ? `${fmt(fixed)} + ${fmt(rateOf(x))} / hour ${cur}` : x.mode === "auto" ? `${fmt(x.amount)} ${cur}` : ""
	return (
		<div class="dbw" data-exo={x.type === "exoclick" ? "1" : undefined}>
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{tagOf(x)}</span>
					</div>
					{sub ? <div class={x.type === "exoclick" && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
				</div>
				<span class="rt">
					<form method="post" action="/income/toggle" style={contents}>
						<Hid s={s} id={x.id} />
						<button class="btn xs o">{x.active ? "Pause" : "Resume"}</button>
					</form>
					<button type="button" class="ub" data-tg aria-label={`Edit ${x.name}`}>
						<Icon name="edit" />
					</button>
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			<form method="post" action="/income/edit" class="ad" data-addp hidden>
				<Hid s={s} id={x.id} />
				<label>Edit {x.name}</label>
				<input class="in f" name="name" value={x.name} autocomplete="off" required />
				{fixedSrc ? (
					<div class="ln" style={{ marginTop: "8px" }}>
						<input class="in" name="fixed" value={fixed ? plain(fixed) : ""} placeholder="Per day" inputmode="decimal" autocomplete="off" />
						<input class="in" name="rate" value={rateOf(x) ? plain(rateOf(x)) : ""} placeholder="Per extra hour" inputmode="decimal" autocomplete="off" />
					</div>
				) : null}
				{x.type === "exoclick" ? <input class="in" style={{ marginTop: "8px" }} name="api_key" type="password" placeholder="New API key (leave empty to keep)" autocomplete="off" /> : null}
				{!fixedSrc && x.type !== "exoclick" && x.mode === "auto" ? <input class="in" style={{ marginTop: "8px" }} name="amount" value={plain(x.amount)} placeholder="Amount" inputmode="decimal" autocomplete="off" /> : null}
				<button class="btn xs" style={{ marginTop: "10px" }}>
					Save
				</button>
			</form>
		</div>
	)
})

export const IncomeExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="income"
		open
		title="Income sources"
		label="Add source"
		head={
			<>
				<b class="big2">{s.sources.length}</b>
				<span class="lb">{`${s.sources.filter((x) => x.active).length} active`}</span>
			</>
		}
		form={<SourceForm s={s} />}
	>
		{s.sources.length ? <>{s.sources.map((x) => <ManageRow key={x.id} s={s} x={x} />)}</> : <Empty>No sources yet. Tap + to add one.</Empty>}
	</ExpandCard>
))

export const HomeIncome = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return (
		<ExpandCard
			storeKey="inc"
			open
			title="Income today"
			label="Add manual income"
			head={
				<>
					<b class="big2">
						+{fmt(c.earned)} <small>{s.user.currency}</small>
					</b>
					<span class="lb">{c.earnedLine}</span>
				</>
			}
			form={
				<form method="post" action="/income/named" class="sf xfm" data-adp hidden>
					<NamedFields s={s} />
				</form>
			}
		>
			{sources.length || others.length ? (
				<>
					{sources.map((x) => (
						<HomeRow key={x.id} s={s} x={x} />
					))}
					{others.map((i) => (
						<IncomeRow key={i.id} s={s} i={i} />
					))}
				</>
			) : (
				<Empty>No sources yet. Add one on the Income page.</Empty>
			)}
		</ExpandCard>
	)
})
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/layout.tsx" << 'MT_EOF_7f3a9c'
import type { RemixNode } from "remix/component"
import { env } from "../env.ts"
import { SITE } from "../lib/assets.ts"
import { liveClockNow } from "../lib/time.ts"
import { V } from "../lib/static.ts"
import { Icon, Logo, ThemeIcons, view } from "./ui.tsx"

type DocumentProps = {
	title: string
	user?: boolean
	theme?: string
	desc?: string
	path?: string
	children?: RemixNode
}

const THEME_BOOT = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`
const REGISTER_SW = `if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))`
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap"

export const Document = view<DocumentProps>(({ title, user = true, theme, desc, path, children }) => {
	const description = desc ?? SITE.desc
	const origin = env.APP_ORIGIN.replace(/\/$/, "")
	const fullTitle = `${title} · ${SITE.name}`
	const ld = JSON.stringify({
		"@context": "https://schema.org",
		"@type": "WebApplication",
		name: SITE.name,
		url: origin,
		description: SITE.desc,
		applicationCategory: "FinanceApplication",
		operatingSystem: "Any",
	}).replace(/</g, "\\u003c")

	return (
		<html lang="en" data-theme={theme === "light" ? "light" : "dark"}>
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
				<meta name="theme-color" content={SITE.color} />
				<title>{fullTitle}</title>
				<meta name="description" content={description} />
				<meta name="robots" content={user ? "noindex,nofollow" : "index,follow"} />
				<meta name="application-name" content={SITE.name} />
				<meta name="apple-mobile-web-app-title" content={SITE.name} />
				<meta name="mobile-web-app-capable" content="yes" />
				<meta name="apple-mobile-web-app-capable" content="yes" />
				<meta name="apple-mobile-web-app-status-bar-style" content="black" />
				<meta name="format-detection" content="telephone=no" />
				<link rel="manifest" href="/manifest.webmanifest" />
				<link rel="icon" href="/favicon.svg" type="image/svg+xml" />
				<link rel="icon" href="/icon-192.png" sizes="192x192" type="image/png" />
				<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
				<meta property="og:type" content="website" />
				<meta property="og:site_name" content={SITE.name} />
				<meta property="og:title" content={fullTitle} />
				<meta property="og:description" content={description} />
				<meta property="og:image" content={`${origin}/icon-512.png`} />
				<meta name="twitter:card" content="summary" />
				<meta name="twitter:title" content={fullTitle} />
				<meta name="twitter:description" content={description} />
				{path && !user ? <link rel="canonical" href={`${origin}${path}`} /> : null}
				{path && !user ? <meta property="og:url" content={`${origin}${path}`} /> : null}
				{user ? null : <script type="application/ld+json">{ld}</script>}
				<link rel="preconnect" href="https://fonts.googleapis.com" />
				<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
				<link rel="stylesheet" href={FONTS} />
				<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2.1.1/css/pico.min.css" />
				<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />
				{theme ? null : <script>{THEME_BOOT}</script>}
			</head>
			<body>
				{children}
				<script src={`/assets/app.js?v=${V.js}`} defer></script>
				<script>{REGISTER_SW}</script>
			</body>
		</html>
	)
})

type Parts = { numDate: string; arabicDay: string }

const SubDate = view<Parts>(({ numDate, arabicDay }) => (
	<>
		<span class="clock-num">{numDate}</span> <span class="clock-dot">·</span> <span class="clock-ar">{arabicDay}</span>
	</>
))

export const ClockWidget = view(() => {
	const { timeStr, dateStr, numDate, arabicDay } = liveClockNow()
	return (
		<div class="live-clock" data-tz="Africa/Casablanca" aria-label="Local Casablanca time">
			<div class="clock-time" data-clock-time>
				{timeStr}
			</div>
			<div class="clock-date" data-clock-date>
				{dateStr}
			</div>
			<div class="clock-subdate" data-clock-subdate dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})

export const TopBar = view<{ split?: boolean }>(({ split }) => {
	if (!split) {
		return (
			<div class="top-status-bar">
				<ClockWidget />
			</div>
		)
	}
	const { numDate, arabicDay } = liveClockNow()
	return (
		<div class="top-status-bar tsplit">
			<ClockWidget />
			<div class="clock-subdate" dir="ltr">
				<SubDate numDate={numDate} arabicDay={arabicDay} />
			</div>
		</div>
	)
})

export type DesktopTab = "home" | "notes" | "plan" | "income" | "trading" | "pad" | "history" | "settings" | ""

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "history", label: "History", icon: "hist", href: "/history" },
	{ key: "settings", label: "Settings", icon: "gear", href: "/settings" },
] as const

export const Sidebar = view<{ active: DesktopTab }>(({ active }) => (
	<aside class="sb d">
		<Logo href="/home" />
		{LINKS.map((l) => (
			<a key={l.key} class={active === l.key ? "sbl on" : "sbl"} href={l.href}>
				<Icon name={l.icon} />
				{l.label}
			</a>
		))}
		<div class="sp"></div>
		<button type="button" class="sbl" data-theme-toggle>
			<ThemeIcons />
			<span>Theme</span>
		</button>
		<form method="post" action="/logout">
			<button class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</button>
		</form>
	</aside>
))

export type MobileTab = "home" | "notes" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "income", label: "Income", icon: "gear", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "profile", label: "Profile", icon: "user", href: "/profile" },
] as const

export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label}>
				<Icon name={t.icon} />
			</a>
		))}
	</nav>
))

type AppLayoutProps = {
	title: string
	theme?: string
	mobile: RemixNode
	desktop: RemixNode
	mobileTab?: MobileTab
	desktopTab?: DesktopTab
	dock?: RemixNode
	full?: boolean
}

export const AppLayout = view<AppLayoutProps>(({ title, theme, mobile, desktop, mobileTab = "", desktopTab = "", dock, full }) => (
	<Document title={title} theme={theme}>
		<div class="app">
			<Sidebar active={desktopTab} />
			<main>
				<div class="m">
					<TopBar split />
				</div>
				<div class="m mm">{mobile}</div>
				<div class="d">
					<TopBar />
				</div>
				<div class={full ? "d pg full" : "d pg"}>{desktop}</div>
			</main>
			<div class="dock m">
				{dock}
				<BottomBar active={mobileTab} />
			</div>
		</div>
	</Document>
))

type AuthLayoutProps = { title: string; path: string; desc: string; children?: RemixNode }

export const AuthLayout = view<AuthLayoutProps>(({ title, path, desc, children }) => (
	<Document title={title} path={path} desc={desc} user={false}>
		<div class="app">
			<div class="tf-clock">
				<ClockWidget />
				<button type="button" class="ib" data-theme-toggle aria-label="Theme">
					<ThemeIcons />
				</button>
			</div>
			<main class="auth-viewport">{children}</main>
		</div>
	</Document>
))
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/notes.tsx" << 'MT_EOF_7f3a9c'
import type { RemixNode } from "remix/component"
import type { State } from "../lib/data.ts"
import { dayLabel, dayOf, hhmm } from "../lib/time.ts"
import { Back, Empty, Icon, Section, view } from "./ui.tsx"

export const NoteList = view<{ s: State; listKey: string }>(({ s, listKey }) => {
	if (listKey === "dash") {
		const latest = s.notes.slice(-2).reverse()
		return (
			<div data-list="dash">
				{latest.length ? (
					latest.map((n) => (
						<div key={n.id} class="rw">
							<span>{n.body}</span>
							<span class="lb">{hhmm(n.at)}</span>
						</div>
					))
				) : (
					<Empty>No notes yet.</Empty>
				)}
			</div>
		)
	}

	const items: RemixNode[] = []
	let last = ""
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at))
		if (label !== last) {
			items.push(
				<div key={`day-${n.id}`} class="day">
					<span>{label}</span>
				</div>,
			)
			last = label
		}
		items.push(
			<div key={n.id} class="msg" data-id={n.id}>
				<div class="bub">{n.body}</div>
				<div class="meta">
					{n.edited ? "edited · " : ""}
					{hhmm(n.at)}
				</div>
				<div class="acts" hidden>
					<button type="button" class="btn xs o" data-act="copy">
						Copy
					</button>
					<button type="button" class="btn xs o" data-act="edit">
						Edit
					</button>
					<form method="post" action="/notes/delete" style={{ display: "contents" }} data-confirm="Delete this note?">
						<Back s={s} />
						<input type="hidden" name="id" value={n.id} />
						<button class="btn xs dng">Delete</button>
					</form>
				</div>
			</div>,
		)
	}
	return <div data-list={listKey}>{items}</div>
})

export const ChatHead = view(() => (
	<div class="ch">
		<div class="av s">S</div>
		<div>
			<b>Message yourself</b>
			<div class="lb">only you can see this</div>
		</div>
	</div>
))

export const Composer = view<{ s: State; listKey: string }>(({ s, listKey }) => (
	<form class="cm" data-comp={listKey} method="post" action="/notes">
		<Back s={s} />
		<input type="hidden" name="id" data-eid />
		<div class="eb" hidden>
			<span>
				<b>Editing</b> message
			</span>
			<button type="button" data-cancel>
				✕
			</button>
		</div>
		<div class="cin">
			<textarea rows="1" name="text" placeholder="Message yourself"></textarea>
			<button class="send" aria-label="Send">
				<Icon name="send" />
			</button>
		</div>
	</form>
))

export const NoteCard = view<{ s: State }>(({ s }) => (
	<Section title="Note to yourself" right={`${s.notes.length} saved`}>
		<form class="cin" data-comp="dash" method="post" action="/notes" style={{ margin: "14px 0" }}>
			<Back s={s} />
			<input type="hidden" name="id" data-eid />
			<textarea rows="1" name="text" placeholder="Message yourself"></textarea>
			<button class="send" aria-label="Send">
				<Icon name="send" />
			</button>
		</form>
		<NoteList s={s} listKey="dash" />
	</Section>
))
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/profile.tsx" << 'MT_EOF_7f3a9c'
import type { State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { LANG } from "../lib/view.ts"
import { Avatar, Back, Card, ErrorBanner, Field, Icon, PageHeader, Section, ThemeSwitch, view } from "./ui.tsx"

const BalanceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/profile/balance">
		<Back s={s} />
		<div class="fl">
			<label>Balance ({s.user.currency})</label>
			<input class="in f" name="balance" inputmode="decimal" value={plain(s.balance)} autocomplete="off" required />
		</div>
		<button class="btn full" style={{ marginTop: "14px" }}>
			Update balance
		</button>
	</form>
))

export const BalanceCard = view<{ s: State; edit?: boolean }>(({ s, edit = false }) => (
	<div class="cd">
		<div class="tg">Total balance</div>
		<div class="cb">
			<div class="ow" style={{ margin: "0" }}>
				<span style={{ display: "flex", alignItems: "center", gap: "10px" }}>
					<b class="big2" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
						••••••
					</b>
					<button type="button" class="ib sm" data-eye aria-label="Show balance">
						<Icon name="eye" />
					</button>
				</span>
				{edit ? (
					<button type="button" class="lnk" data-edit-bal>
						Edit balance
					</button>
				) : null}
			</div>
			{edit ? (
				<div data-balf hidden>
					<BalanceForm s={s} />
				</div>
			) : null}
		</div>
	</div>
))

const ProfileForm = view<{ s: State; cancel: string; showError?: boolean }>(({ s, cancel, showError = false }) => (
	<form method="post" action="/profile/edit">
		{showError ? <ErrorBanner s={s} /> : null}
		<Field label="Name" value={s.user.name} name="name" first />
		<Field label="Email" value={s.user.email} type="email" name="email" />
		<div style={{ display: "flex", gap: "10px", marginTop: "18px" }}>
			<button class="btn" style={{ flex: "1" }}>
				Save
			</button>
			<a class="btn o" style={{ flex: "1" }} href={cancel}>
				Cancel
			</a>
		</div>
	</form>
))

const PrefsForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/settings">
		<Field label="Currency" value={s.user.currency} name="currency" />
		<Field label={`1 USDT costs (${s.user.currency})`} value={plain(s.user.usdt_rate)} name="usdt" />
		<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />
		<Field label="1 USD in MAD (ExoClick)" value={plain(s.user.usd_rate_minor)} name="usd_rate" />
		<Field label="Week starts" value={s.user.week_start} name="week" />
		<button class="btn" style={{ marginTop: "14px" }}>
			Save
		</button>
	</form>
))

const DataButtons = view(() => (
	<div style={{ display: "flex", gap: "10px", marginTop: "6px" }}>
		<a class="btn o" style={{ flex: "1" }} href="/export.csv">
			Export CSV
		</a>
		<form method="post" action="/account/delete" style={{ flex: "1", display: "flex" }} data-confirm="Delete your account and all your data? This cannot be undone.">
			<button class="btn dng" style={{ flex: "1" }}>
				Delete account
			</button>
		</form>
	</div>
))

const LinkRow = view<{ href: string; label: string }>(({ href, label }) => (
	<a class="li" href={href}>
		<span>{label}</span>
		<span class="mu">›</span>
	</a>
))

export const ProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "10px", margin: "20px 0 6px" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
			<div style={{ textAlign: "center" }}>
				<div style={{ fontSize: "22px", fontWeight: "700", letterSpacing: "-.04em" }}>{s.user.name}</div>
				<div class="lb">{s.user.email}</div>
				<div class="chips" style={{ justifyContent: "center", marginTop: "10px" }}>
					<span class="chip" style={{ cursor: "default" }}>
						{s.user.currency}
					</span>
					<span class="chip" style={{ cursor: "default" }}>
						{LANG}
					</span>
				</div>
			</div>
		</div>
		<BalanceCard s={s} edit />
		<Card title="Appearance">
			<ThemeSwitch />
		</Card>
		<Card title="Account">
			<LinkRow href="/profile/edit" label="Edit profile" />
			<LinkRow href="/settings" label="Settings" />
			<LinkRow href="/history" label="History" />
			<form method="post" action="/logout">
				<button class="li">
					<span class="neg">Log out</span>
					<span class="mu">›</span>
				</button>
			</form>
		</Card>
	</>
))

export const EditProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<div style={{ display: "flex", justifyContent: "center", margin: "14px 0 0" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
		</div>
		<Card title="Profile">
			<ProfileForm s={s} cancel="/profile" showError />
		</Card>
	</>
))

export const SettingsMobile = view<{ s: State }>(({ s }) => (
	<>
		<ErrorBanner s={s} />
		<Card title="Money & income">
			<PrefsForm s={s} />
		</Card>
		<Card title="Data">
			<DataButtons />
		</Card>
		<div class="lb" style={{ textAlign: "center", margin: "18px 0" }}>
			Moneytracker v1.0 · stable
		</div>
	</>
))

export const SettingsDesktop = view<{ s: State }>(({ s }) => (
	<>
		<PageHeader title="Settings" right={`${s.user.currency} · ${LANG}`} />
		<ErrorBanner s={s} />
		<div class="g3">
			<div>
				<BalanceCard s={s} edit />
				<Section title="Profile">
					<ProfileForm s={s} cancel="/home" />
				</Section>
				<Section title="Account">
					<form method="post" action="/logout">
						<button class="btn o">Log out</button>
					</form>
				</Section>
			</div>
			<div>
				<Section title="Appearance">
					<ThemeSwitch />
				</Section>
				<Section title="Money & income">
					<PrefsForm s={s} />
				</Section>
				<Section title="Data">
					<DataButtons />
				</Section>
			</div>
		</div>
	</>
))
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/trading.tsx" << 'MT_EOF_7f3a9c'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { dayLabel } from "../lib/time.ts"
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcLost,
	btcOf,
	DEPOSIT,
	isDone,
	PICKS,
	PRED_COUNT,
	predOf,
	strip,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "../lib/trade-math.ts"
import { Back, Card, Icon, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

type RowState = "result" | "active" | "wait" | "skip"

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const PredictRow = view<{ s: State; t: TradeSession; game: Game; idx: number; r: TradeResult | undefined; state: RowState; canUndo: boolean }>(
	({ s, t, game, idx, r, state, canUndo }) => {
		const meta = r && r.asset ? `${r.asset} ${r.tf}m` : ""
		if (r && isDone(r)) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						{meta ? <div class="lb">{meta}</div> : null}
					</div>
					<span class="rt">
						<span class={`tbs ${r.won ? "pos" : "mu"}`}>{r.won ? "Win" : "Missed"}</span>
						<b class={r.won ? tone(r.pnl) : "mu"}>{sg(r.pnl)}</b>
						{canUndo ? (
							<form method="post" action="/trading/undo" style={contents} data-confirm={`Move predict ${idx} back to waiting?`}>
								<SessionHid s={s} t={t} />
								<input type="hidden" name="result_id" value={r.id} />
								<button class="ub" aria-label={`Undo predict ${idx}`}>
									<Icon name="undo" />
								</button>
							</form>
						) : null}
					</span>
				</div>
			)
		}
		if (r) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
						<div class="lb">{meta ? `${meta} · waiting` : "waiting"}</div>
					</div>
					<form method="post" action="/trading/result" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<input class="in" name="pnl" placeholder="PnL USDT" inputmode="decimal" autocomplete="off" />
						<button class="btn xs win" name="outcome" value="win">
							Win
						</button>
						<button class="btn xs miss" name="outcome" value="miss" formnovalidate>
							Miss
						</button>
					</form>
					{canUndo ? (
						<form method="post" action="/trading/undo" style={contents}>
							<SessionHid s={s} t={t} />
							<input type="hidden" name="result_id" value={r.id} />
							<button class="ub" aria-label={`Cancel predict ${idx}`}>
								<Icon name="undo" />
							</button>
						</form>
					) : null}
				</div>
			)
		}
		if (state === "active" && game === "btc") {
			return (
				<div class="tbr" style={{ flexDirection: "column", alignItems: "stretch" }}>
					<b>Predict {idx}</b>
					<form method="post" action="/trading/set" style={contents}>
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<div class="hxg">
							{PICKS.map(([a, m]) => (
								<button key={`${a}-${m}`} class="chip hc" name="pick" value={`${a}-${m}`}>
									<b>{a}</b>
									<small>{m}m</small>
								</button>
							))}
						</div>
					</form>
				</div>
			)
		}
		if (state === "active") {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
					</div>
					<form method="post" action="/trading/set" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<button class="btn xs o">Set</button>
					</form>
				</div>
			)
		}
		return (
			<div class="tbr lock">
				<div>
					<b>Predict {idx}</b>
				</div>
				<span class="lb">{state === "skip" ? "skipped" : "waiting"}</span>
			</div>
		)
	},
)

const BtcCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = btcOf(t.results)
	const done = btcDone(t.results)
	const lost = btcLost(t.results)
	return (
		<Card title="Crypto · up or down">
			<div class="lb tbn">1 USDT. Up to {BTC_ROUNDS} predicts. Pick BTC or ETH and 5 or 15 minutes, then wait for the result. Win goes to the next one. Miss ends it.</div>
			{Array.from({ length: BTC_ROUNDS }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx)
				const state: RowState = r ? "result" : done ? "skip" : idx === list.length + 1 && list.every(isDone) ? "active" : "wait"
				return <PredictRow key={idx} s={s} t={t} game="btc" idx={idx} r={r} state={state} canUndo={!!r && idx === list.length} />
			})}
			{done ? <div class="lb tbn">{lost ? "Finished. This one missed." : `Finished. You won all ${BTC_ROUNDS}.`}</div> : null}
		</Card>
	)
})

const PredCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = predOf(t.results)
	return (
		<Card title="3 predicts · lol or sport">
			<div class="lb tbn">3 USDT. Each predict is on its own. Tap Set, then wait. Type the PnL and tap Win, or tap Miss.</div>
			{Array.from({ length: PRED_COUNT }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx)
				return <PredictRow key={idx} s={s} t={t} game="pred" idx={idx} r={r} state={r ? "result" : "active"} canUndo={!!r} />
			})}
		</Card>
	)
})

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency
	const pnl = totalPnl(t.results)
	const back = backUsdt(t.deposit, pnl)
	const net = toMad(pnl, t.rate)
	return (
		<Card title="Open trade">
			<div class="ow" style={{ margin: "0 0 8px" }}>
				<b class={`big2 ${t.results.some(isDone) ? tone(pnl) : ""}`}>
					{t.results.some(isDone) ? sg(pnl) : "0"} <small>USDT PnL</small>
				</b>
				<span class="lb">{dayLabel(t.day)}</span>
			</div>
			<div class="rw">
				<span class="mu">Deposit</span>
				<span>{`${fmt(t.deposit)} USDT · ${fmt(toMad(t.deposit, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">You get back</span>
				<span>{`${fmt(back)} USDT · ${fmt(toMad(back, t.rate))} ${cur}`}</span>
			</div>
			<div class="rw">
				<span class="mu">Net for your balance</span>
				<b class={tone(net)}>{`${sg(net)} ${cur}`}</b>
			</div>
			{t.results.some(isDone) && !allDone(t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the predicts that are left?">
					<SessionHid s={s} t={t} />
					<button class="btn o full">Finish now</button>
				</form>
			) : null}
			<div class="lb tbn">When every predict has a result, the money is added to your balance by itself.</div>
		</Card>
	)
})

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency
	const rate = s.user.usdt_rate
	const cost = toMad(DEPOSIT, rate)
	return (
		<Card title="Today's trade">
			<div class="ow" style={{ margin: "0 0 6px" }}>
				<b class="big2">
					{fmt(DEPOSIT)} <small>USDT</small>
				</b>
				<span class="lb">{`${fmt(cost)} ${cur}`}</span>
			</div>
			<div class="lb">{`1 USDT = ${fmt(rate)} ${cur}. You can change it in Settings.`}</div>
			<form method="post" action="/trading/deposit" data-confirm={`Deposit ${fmt(DEPOSIT)} USDT? It counts as a buy of ${fmt(cost)} ${cur}.`}>
				<Back s={s} />
				<button class="btn full">Deposit {fmt(DEPOSIT)} USDT</button>
			</form>
			<div class="lb tbn">Then you do 4 up or down predicts (1 USDT) and 3 more predicts (3 USDT).</div>
		</Card>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate)
	const btc = strip(btcOf(t.results))
	const pred = strip(predOf(t.results))
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{`${btc ? `BTC ${btc}` : ""}${btc && pred ? " · " : ""}${pred ? `P ${pred}` : ""}`}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this trade again? The money it added is taken back.">
						<SessionHid s={s} t={t} />
						<button class="ub" aria-label="Open this trade again">
							<Icon name="undo" />
						</button>
					</form>
				) : null}
			</span>
		</div>
	)
})

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0)
	return (
		<Card title={`Past trades · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	return (
		<div class="trd">
			{open ? (
				<>
					<OpenSummary s={s} t={open} />
					<BtcCard s={s} t={open} />
					<PredCard s={s} t={open} />
				</>
			) : (
				<StartCard s={s} />
			)}
			<PastCard s={s} list={settled} canReopen={!open} />
		</div>
	)
})
MT_EOF_7f3a9c
mkdir -p "app/components"
cat > "app/components/ui.tsx" << 'MT_EOF_7f3a9c'
import { unsafeHTML, type Handle, type RemixNode } from "remix/component"
import type { State } from "../lib/data.ts"

export function view<P extends Record<string, any> = {}>(render: (props: P) => RemixNode) {
	return function View(handle: Handle<P>) {
		return () => render(handle.props)
	}
}

const ICONS: Record<string, string> = {
	sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
	moon: '<path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5z"/>',
	user: '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>',
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	notes: '<path d="M21 12a8 8 0 0 1-11.6 7.1L3 21l1.9-6.4A8 8 0 1 1 21 12z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
	pad: '<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h7M9 17h5"/>',
	trade: '<path d="M3 17l5-6 4 3 8-9"/><path d="M15 5h5v5"/>',
	coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
	undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	chev: '<path d="M6 9l6 6 6-6"/>',
	eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
	Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
	Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
	Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
	Other: '<path d="M12 5v14M5 12h14"/>',
	Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
	Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
	Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
	Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
	Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
	Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
}

export const Icon = view<{ name: string }>(({ name }) => <svg class="ic" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS[name] ?? "")} />)

export const ThemeIcons = view(() => (
	<>
		<svg class="ic t-sun" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.sun!)} />
		<svg class="ic t-moon" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.moon!)} />
	</>
))

const GOOGLE_INNER =
	'<path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/>'

export const GoogleMark = view(() => <svg width="18" height="18" viewBox="0 0 48 48" innerHTML={unsafeHTML(GOOGLE_INNER)} />)

const GOAT_INNER =
	'<rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/>'

const GoatMark = view(() => <svg viewBox="0 0 24 24" innerHTML={unsafeHTML(GOAT_INNER)} />)

export const Logo = view<{ href: string }>(({ href }) => (
	<a class="logo" href={href}>
		<GoatMark />
		<span>moneytracker</span>
	</a>
))

export const Card = view<{ title: RemixNode; children?: RemixNode }>(({ title, children }) => (
	<div class="cd">
		<div class="tg">{title}</div>
		<div class="cb">{children}</div>
	</div>
))

export const Section = view<{ title: RemixNode; right?: RemixNode; children?: RemixNode }>(({ title, right = "", children }) => (
	<div class="sc">
		<div class="sh">
			<span>{title}</span>
			<span class="lb">{right}</span>
		</div>
		{children}
	</div>
))

export const PageHeader = view<{ title: string; right?: RemixNode; back?: string }>(({ title, right = "", back }) => (
	<div class="hd">
		{back ? (
			<a class="back" href={back}>
				<Icon name="back" />
				<h1 class="t">{title}</h1>
			</a>
		) : (
			<h1 class="t">{title}</h1>
		)}
		<span class="lb">{right}</span>
	</div>
))

type FieldProps = { label: string; value?: string; name?: string; type?: string; placeholder?: string; first?: boolean }

export const Field = view<FieldProps>(({ label, value = "", name, type, placeholder = "", first }) => (
	<div class="fl">
		<label>{label}</label>
		<input class={first ? "in f" : "in"} name={name} type={type} value={value} placeholder={value ? undefined : placeholder} autocomplete="off" />
	</div>
))

export const FloatField = view<{ label: string; name: string; type?: string; auto?: string }>(({ label, name, type = "text", auto }) => (
	<div class="of">
		<input name={name} type={type} placeholder=" " autocomplete={auto} />
		<label>{label}</label>
	</div>
))

export const Back = view<{ s: State }>(({ s }) => <input type="hidden" name="back" value={s.back} />)

export const ErrorBanner = view<{ s: State }>(({ s }) =>
	s.error ? (
		<div class="neg" role="alert" style={{ margin: "10px 0", fontSize: "13px" }}>
			{s.error}
		</div>
	) : null,
)

export const Empty = view<{ children?: RemixNode }>(({ children }) => (
	<div class="lb" style={{ padding: "8px 0" }}>
		{children}
	</div>
))

export const Avatar = view<{ avatar: string | null; name: string }>(({ avatar, name }) => {
	const url = avatar ? encodeURI(avatar).replace(/'/g, "%27") : ""
	return (
		<div class="av" style={url ? { background: `url('${url}') center/cover` } : undefined}>
			{url ? "" : (name.trim()[0] ?? "?").toUpperCase()}
		</div>
	)
})

export const ThemeSwitch = view(() => (
	<div class="sg">
		<button type="button" data-set-theme="dark">
			<Icon name="moon" />
			Dark
		</button>
		<button type="button" data-set-theme="light">
			<Icon name="sun" />
			White
		</button>
	</div>
))

export const NameChips = view<{ names: string[] }>(({ names }) =>
	names.length ? (
		<div class="chips nm">
			{names.map((n) => (
				<span key={n} class="chip" data-nm={n}>
					{n}
				</span>
			))}
		</div>
	) : null,
)

export const BigAdd = view<{ label: string; target?: string; right?: boolean }>(({ label, target = "", right = false }) => (
	<button type="button" class={right ? "addb r" : "addb"} data-bigadd data-for={target || undefined} aria-label={label}>
		<Icon name="plus" />
	</button>
))

export const ListCard = view<{ title: RemixNode; right: RemixNode; target: string; label: string; children?: RemixNode }>(({ title, right, target, label, children }) => (
	<div class="sc bgc rgt">
		<div class="ct">
			<div class="sh">
				<span>{title}</span>
				<span class="lb">{right}</span>
			</div>
			{children}
		</div>
		<BigAdd label={label} target={target} right />
	</div>
))

type ExpandProps = {
	storeKey: string
	open: boolean
	title: string
	head?: RemixNode
	foot?: RemixNode
	form?: RemixNode
	label?: string
	jar?: number
	children?: RemixNode
}

export const ExpandCard = view<ExpandProps>(({ storeKey, open, title, head, foot, form, label = "", jar = -1, children }) => (
	<div class={label ? "xc" : "xc xn"}>
		<details class="xd" data-keep-open={storeKey} open={open ? true : undefined}>
			<summary class="xh osum">
				{jar >= 0 ? <i class={jar >= 100 ? "xj full" : "xj"} style={{ width: `${jar}%` }}></i> : null}
				<div>
					<div class="tg0">{title}</div>
					{head ? <div class="ow">{head}</div> : null}
				</div>
				<span class="chev">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="xb">{children}</div>
			<div class={foot ? "xf" : "xf xo"}>
				{foot}
				{form}
			</div>
		</details>
		{label ? (
			<button type="button" class="xp" data-xplus aria-label={label}>
				<Icon name="plus" />
			</button>
		) : null}
	</div>
))
MT_EOF_7f3a9c
mkdir -p "app/controllers"
cat > "app/controllers/assets.ts" << 'MT_EOF_7f3a9c'
import { createController } from "remix/router"
import { assets } from "../lib/assets.ts"
import { files, hash } from "../lib/static.ts"
import { routes } from "../routes.ts"

const file = (body: string, type: string) => {
	const etag = `"${hash(body)}"`
	return (ctx: { request: Request }) => {
		const pinned = new URL(ctx.request.url).searchParams.has("v")
		const headers = { "Cache-Control": pinned ? "public, max-age=31536000, immutable" : "no-cache", ETag: etag }
		return ctx.request.headers.get("if-none-match") === etag ? new Response(null, { status: 304, headers }) : new Response(body, { headers: { ...headers, "Content-Type": type } })
	}
}

export default createController(routes.assets, {
	actions: {
		manifest: () => assets.manifest(),
		favicon: () => assets.favicon(),
		faviconIco: () => assets.icon192(),
		icon192: () => assets.icon192(),
		icon512: () => assets.icon512(),
		iconMaskable: () => assets.iconMaskable(),
		appleIcon: () => assets.appleIcon(),
		sw: () => assets.sw(),
		robots: () => assets.robots(),
		sitemap: () => assets.sitemap(),
		css: file(files.css, "text/css; charset=utf-8"),
		js: file(files.js, "application/javascript; charset=utf-8"),
	},
})
MT_EOF_7f3a9c
mkdir -p "app/controllers"
cat > "app/controllers/auth.tsx" << 'MT_EOF_7f3a9c'
import { finishExternalAuth, startExternalAuth } from "remix/auth"
import { createController } from "remix/router"
import { LoginScreen, SignupScreen } from "../screens.tsx"
import { env } from "../env.ts"
import * as act from "../lib/actions.ts"
import { googleProvider } from "../lib/auth.ts"
import { signInWithPassword, signUpWithPassword, upsertFromGoogle } from "../lib/users.ts"
import { routes } from "../routes.ts"
import { fail, formOf, go, signInAs, signOut, takeError, userOf, type Ctx } from "../request.ts"

export default createController(routes.auth, {
	actions: {
		login(ctx: Ctx) {
			if (userOf(ctx)) return go("/home")
			return ctx.render(<LoginScreen error={takeError(ctx)} />)
		},

		async signIn(ctx: Ctx) {
			const f = formOf(ctx)
			const user = await signInWithPassword(String(f.get("email") ?? ""), String(f.get("password") ?? ""))
			if (!user) return fail(ctx, "/login", "Wrong email or password.")
			signInAs(ctx, user.id)
			return go("/home")
		},

		signup(ctx: Ctx) {
			if (userOf(ctx)) return go("/home")
			return ctx.render(<SignupScreen error={takeError(ctx)} />)
		},

		async signUp(ctx: Ctx) {
			const f = formOf(ctx)
			const result = await signUpWithPassword({
				name: String(f.get("name") ?? ""),
				email: String(f.get("email") ?? ""),
				password: String(f.get("password") ?? ""),
			})
			if (!result.ok) return fail(ctx, "/signup", result.error)
			signInAs(ctx, result.user.id)
			return go("/home")
		},

		logout(ctx: Ctx) {
			signOut(ctx)
			return go("/login")
		},

		googleLogin(ctx: Ctx) {
			if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
				return fail(ctx, "/login", "Google login is not configured. Please sign in with email and password.")
			}
			return startExternalAuth(googleProvider, ctx as never, { returnTo: "/home" })
		},

		async googleCallback(ctx: Ctx) {
			try {
				const { result, returnTo } = await finishExternalAuth(googleProvider, ctx as never)
				const user = await upsertFromGoogle(result.account, result.profile as never)
				signInAs(ctx, user.id)
				return go(returnTo ?? "/home")
			} catch (err) {
				console.error("google sign-in failed", err)
				return fail(ctx, "/login", "Google sign-in failed. Try again.")
			}
		},

		async deleteAccount(ctx: Ctx) {
			const user = userOf(ctx)
			if (!user) return go("/login")
			await act.deleteAccount(user.id)
			signOut(ctx)
			return go("/signup")
		},
	},
})
MT_EOF_7f3a9c
mkdir -p "app/controllers"
cat > "app/controllers/commands.ts" << 'MT_EOF_7f3a9c'
import { createController } from "remix/router"
import { commands, errorOf, type Command, type CommandName } from "../commands.ts"
import { routes } from "../routes.ts"
import { backTo, fail, formOf, go, userOf, type Ctx } from "../request.ts"

const form = (name: CommandName) => async (ctx: Ctx) => {
	const c: Command = commands[name]
	const user = userOf(ctx)
	if (!user) return c.empty ? new Response(null, { status: 401 }) : go("/login")
	const f = formOf(ctx)
	const error = errorOf(await c.run(user, f))
	if (c.empty) return new Response(null, { status: 204 })
	const to = c.back === false ? c.to : backTo(f, c.to)
	return error ? fail(ctx, c.fail ?? to, error) : go(to)
}

export default createController(routes.commands, {
	actions: Object.fromEntries((Object.keys(commands) as CommandName[]).map((name) => [name, form(name)])) as never,
})
MT_EOF_7f3a9c
mkdir -p "app/controllers"
cat > "app/controllers/pages.tsx" << 'MT_EOF_7f3a9c'
import { createController } from "remix/router"
import type { RemixNode } from "remix/component"
import * as act from "../lib/actions.ts"
import { loadState, type Part, type State } from "../lib/data.ts"
import { DebtsScreen, GoalsScreen, HistoryScreen, HomeScreen, IncomeScreen, NotesScreen, PadScreen, ProfileEditScreen, ProfileScreen, SettingsScreen, TradingScreen } from "../screens.tsx"
import { routes } from "../routes.ts"
import { go, takeError, userOf, type Ctx } from "../request.ts"

const page = (path: string, parts: Part[], render: (s: State) => RemixNode) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	return ctx.render(render(await loadState(user, parts, { back: path, error: takeError(ctx) })))
}

export default createController(routes.pages, {
	actions: {
		root: (ctx: Ctx) => go(userOf(ctx) ? "/home" : "/login"),
		home: page("/home", ["today", "sources", "names", "incnames", "debts", "goals", "notes", "balance"], (s) => <HomeScreen s={s} />),
		debts: page("/debts", ["debts", "goals", "balance"], (s) => <DebtsScreen s={s} />),
		notes: page("/notes", ["notes"], (s) => <NotesScreen s={s} />),
		goals: page("/goals", ["goals", "debts", "balance"], (s) => <GoalsScreen s={s} />),
		plan: page("/plan", ["goals", "debts", "sources", "today", "balance"], (s) => <GoalsScreen s={s} />),
		income: page("/income", ["sources", "today"], (s) => <IncomeScreen s={s} />),
		history: page("/history", ["history"], (s) => <HistoryScreen s={s} />),
		profile: page("/profile", ["avatar", "balance"], (s) => <ProfileScreen s={s} />),
		profileEdit: page("/profile/edit", ["avatar", "balance"], (s) => <ProfileEditScreen s={s} />),
		settings: page("/settings", ["balance"], (s) => <SettingsScreen s={s} />),
		pad: page("/pad", [], (s) => <PadScreen s={s} />),
		trading: page("/trading", ["trading"], (s) => <TradingScreen s={s} />),

		async exportCsv(ctx: Ctx) {
			const user = userOf(ctx)
			if (!user) return go("/login")
			return new Response(await act.exportCsv(user.id), {
				headers: { "Content-Type": "text/csv; charset=utf-8", "Content-Disposition": 'attachment; filename="moneytracker.csv"' },
			})
		},
	},
})
MT_EOF_7f3a9c
mkdir -p "app/db"
cat > "app/db/index.ts" << 'MT_EOF_7f3a9c'
import { createClient } from "@libsql/client/web"
import { createTursoDatabase } from "@remix-kbn/data-table-sqlite-turso"
import { env } from "../env.ts"

export const db = createTursoDatabase(createClient({ url: env.TURSO_DATABASE_URL, authToken: env.TURSO_AUTH_TOKEN }))

export * from "./tables.ts"
MT_EOF_7f3a9c
mkdir -p "app/db"
cat > "app/db/session-storage.ts" << 'MT_EOF_7f3a9c'
import { createSession, type Session, type SessionStorage } from "remix/session"
import { sql } from "remix/data-table"
import { db } from "./index.ts"
import { sessions as sessionsTable } from "./tables.ts"
const TTL_MS = 30 * 24 * 60 * 60 * 1000
export function createDbSessionStorage(): SessionStorage {
	return {
		async read(cookie) {
			if (!cookie) return createSession()
			try {
				const row = await db.find(sessionsTable, cookie)
				if (!row || row.expires_at < Date.now()) return createSession()
				return createSession(row.id, JSON.parse(row.data))
			} catch {
				return createSession()
			}
		},
		async save(session: Session) {
			if (session.deleteId) await db.delete(sessionsTable, session.deleteId)
			if (session.destroyed) {
				await db.delete(sessionsTable, session.id)
				return null
			}
			if (session.size === 0 && !session.dirty) return null
			const auth = session.get("auth") as { userId?: string } | undefined
			const now = Date.now()
			await db.exec(sql`
insert into sessions (id, user_id, data, created_at, expires_at)
values (${session.id}, ${auth?.userId ?? null}, ${JSON.stringify(session.data)}, ${now}, ${now + TTL_MS})
on conflict(id) do update set
user_id = excluded.user_id,
data = excluded.data,
expires_at = excluded.expires_at
`)
			return session.id
		},
	}
}
MT_EOF_7f3a9c
mkdir -p "app/db"
cat > "app/db/tables.ts" << 'MT_EOF_7f3a9c'
import { column as c, table } from "remix/data-table"

export const users = table({
	name: "users",
	columns: {
		id: c.varchar(36),
		email: c.varchar(255),
		name: c.varchar(255),
		email_verified: c.integer(),
		currency: c.varchar(8),
		theme: c.varchar(8),
		phone: c.varchar(64),
		bio: c.varchar(500),
		run_at: c.varchar(8),
		week_start: c.varchar(16),
		bg_mode: c.varchar(8),
		bg_url: c.varchar(2048),
		usd_rate_minor: c.integer(),
		usdt_rate_minor: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})

export const passwords = table({
	name: "passwords",
	columns: { user_id: c.varchar(36), hash: c.varchar(255), updated_at: c.integer() },
	primaryKey: "user_id",
})

export const sessions = table({
	name: "sessions",
	columns: {
		id: c.varchar(64),
		user_id: c.varchar(36),
		data: c.varchar(65535),
		created_at: c.integer(),
		expires_at: c.integer(),
	},
})

export const oauthAccounts = table({
	name: "oauth_accounts",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		provider: c.varchar(32),
		provider_account_id: c.varchar(255),
		created_at: c.integer(),
	},
})

export const userImages = table({
	name: "user_images",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(16),
		source: c.varchar(16),
		url: c.varchar(2048),
		mime: c.varchar(64),
		size_bytes: c.integer(),
		is_active: c.integer(),
		created_at: c.integer(),
	},
})

export const incomeSources = table({
	name: "income_sources",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		name: c.varchar(80),
		mode: c.varchar(8),
		amount_minor: c.integer(),
		every: c.varchar(8),
		created_at: c.integer(),
		type: c.varchar(16),
		config: c.varchar(2000),
		currency: c.varchar(8),
		active: c.integer(),
		sort: c.integer(),
	},
})

export const incomes = table({
	name: "incomes",
	columns: {
		id: c.varchar(80),
		user_id: c.varchar(36),
		source_id: c.varchar(36),
		amount_minor: c.integer(),
		day: c.varchar(10),
		created_at: c.integer(),
		meta: c.varchar(2000),
		ext_key: c.varchar(120),
		usd_minor: c.integer(),
	},
})

export const purchases = table({
	name: "purchases",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		name: c.varchar(120),
		qty: c.integer(),
		unit_minor: c.integer(),
		total_minor: c.integer(),
		day: c.varchar(10),
		debt_id: c.varchar(36),
		created_at: c.integer(),
	},
})

export const people = table({
	name: "people",
	columns: { id: c.varchar(36), user_id: c.varchar(36), name: c.varchar(80) },
})

export const debts = table({
	name: "debts",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		person_id: c.varchar(36),
		kind: c.varchar(8),
		item_name: c.varchar(40),
		item_qty: c.integer(),
		amount_minor: c.integer(),
		created_at: c.integer(),
	},
})

export const debtPayments = table({
	name: "debt_payments",
	columns: {
		id: c.varchar(36),
		debt_id: c.varchar(36),
		user_id: c.varchar(36),
		amount_minor: c.integer(),
		purchase_id: c.varchar(36),
		created_at: c.integer(),
	},
})

export const goals = table({
	name: "goals",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		title: c.varchar(120),
		target_minor: c.integer(),
		saved_minor: c.integer(),
		is_wish: c.integer(),
		done_at: c.integer(),
		created_at: c.integer(),
	},
})

export const goalItems = table({
	name: "goal_items",
	columns: { id: c.varchar(36), user_id: c.varchar(36), goal_id: c.varchar(36), name: c.varchar(120), price_minor: c.integer(), done_at: c.integer(), created_at: c.integer() },
})

export const notes = table({
	name: "notes",
	columns: { id: c.varchar(36), user_id: c.varchar(36), body: c.varchar(5000), created_at: c.integer(), updated_at: c.integer() },
})

export const tradeSessions = table({
	name: "trade_sessions",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		day: c.varchar(10),
		deposit_minor: c.integer(),
		rate_minor: c.integer(),
		purchase_id: c.varchar(36),
		income_id: c.varchar(36),
		status: c.varchar(8),
		pnl_minor: c.integer(),
		return_usdt_minor: c.integer(),
		return_mad_minor: c.integer(),
		created_at: c.integer(),
		settled_at: c.integer(),
	},
})

export const tradeResults = table({
	name: "trade_results",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		session_id: c.varchar(36),
		game: c.varchar(8),
		idx: c.integer(),
		won: c.integer(),
		state: c.varchar(8),
		asset: c.varchar(8),
		tf: c.integer(),
		pnl_minor: c.integer(),
		created_at: c.integer(),
	},
})
MT_EOF_7f3a9c
mkdir -p "app"
cat > "app/env.ts" << 'MT_EOF_7f3a9c'
import { env as cfEnv } from "cloudflare:workers"

const raw = (cfEnv as unknown as Record<string, unknown>) ?? {}

const getVal = (key: string, fallback = "") => {
	const val = raw[key]
	if (typeof val === "string" && val.trim()) return val.trim()
	if (typeof process !== "undefined" && process.env?.[key]) return process.env[key]!.trim()
	return fallback
}

const dbUrl = getVal("TURSO_DATABASE_URL")

export const env = {
	TURSO_DATABASE_URL: dbUrl.startsWith("http://") ? dbUrl.replace(/^http:\/\//, "https://") : dbUrl,
	TURSO_AUTH_TOKEN: getVal("TURSO_AUTH_TOKEN"),
	SESSION_SECRET: getVal("SESSION_SECRET", import.meta.env.DEV ? "moneytracker-dev-session-secret-not-for-production" : ""),
	GOOGLE_CLIENT_ID: getVal("GOOGLE_CLIENT_ID"),
	GOOGLE_CLIENT_SECRET: getVal("GOOGLE_CLIENT_SECRET"),
	APP_ORIGIN: getVal("APP_ORIGIN", "http://localhost:3000"),
}

export const missingEnv = () => (["TURSO_DATABASE_URL", "TURSO_AUTH_TOKEN", "SESSION_SECRET"] as const).filter((k) => !env[k])
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/actions.ts" << 'MT_EOF_7f3a9c'
import { sql } from "remix/data-table"
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases } from "../db/index.ts"
import { balanceOf } from "./data.ts"
import { fmt, toMinor, toSigned } from "./money.ts"
import { today } from "./time.ts"
import { extKey, id, isFixed, parseJson, text } from "./util.ts"

type Result = Promise<string | void>

const count = (v: unknown) => {
	const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")))
	return Number.isFinite(n) && n > 0 ? Math.min(n, 100000) : 0
}

const realDay = (v: string) => {
	const t = Date.parse(`${v}T12:00:00Z`)
	return /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(t) && new Date(t).toISOString().slice(0, 10) === v
}

const pickDay = (f: FormData) => {
	const d = text(f.get("day"), 10) || today()
	return realDay(d) && d <= today() ? d : null
}

const own = (f: FormData, key = "id", max = 36) => text(f.get(key), max)

export async function addBuy(uid: string, f: FormData): Result {
	const unit = toMinor(f.get("price"))
	if (!unit) return "Enter a price"
	const day = pickDay(f)
	if (!day) return "Pick a day that is not in the future"
	const qty = count(f.get("qty")) || 1
	await db.create(purchases, { id: id(), user_id: uid, name: text(f.get("label"), 120) || "Item", qty, unit_minor: unit, total_minor: unit * qty, day, created_at: Date.now() })
}

export async function addDayIncome(uid: string, f: FormData): Result {
	const amount = toMinor(f.get("amount"))
	if (!amount) return "Enter an amount"
	const day = pickDay(f)
	if (!day) return "Pick a day that is not in the future"
	const label = text(f.get("label"), 60)
	await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day, created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: "" })
}

export async function setBalance(uid: string, f: FormData): Result {
	const target = toSigned(f.get("balance"))
	if (target === null) return "Enter your balance"
	const diff = target - (await balanceOf(uid))
	if (!diff) return
	const now = Date.now()
	if (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: today(), created_at: now, meta: '{"adjust":1}', ext_key: "" })
	else await db.create(purchases, { id: id(), user_id: uid, name: "Balance adjustment", qty: 1, unit_minor: -diff, total_minor: -diff, day: today(), created_at: now })
}

export async function deleteBuy(uid: string, f: FormData): Result {
	const p = await db.findOne(purchases, { where: { id: own(f), user_id: uid } })
	if (!p) return
	await db.transaction(async (tx) => {
		if (p.debt_id) {
			const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } })
			const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor
			const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } })
			if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back })
			await tx.exec(sql`delete from debt_payments where purchase_id = ${p.id} and user_id = ${uid}`)
		}
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key in (select 'trade:' || id from trade_sessions where purchase_id = ${p.id} and user_id = ${uid})`)
		await tx.exec(sql`delete from trade_results where user_id = ${uid} and session_id in (select id from trade_sessions where purchase_id = ${p.id} and user_id = ${uid})`)
		await tx.exec(sql`delete from trade_sessions where purchase_id = ${p.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from purchases where id = ${p.id} and user_id = ${uid}`)
	})
}

export async function addDebt(uid: string, f: FormData): Result {
	const debtId = own(f, "debt_id")
	if (debtId) {
		const d = await db.findOne(debts, { where: { id: debtId, user_id: uid } })
		if (!d) return
		if (d.kind === "item") {
			const n = count(f.get("amount"))
			if (!n) return "Enter an amount"
			await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n })
		} else {
			const m = toMinor(f.get("amount"))
			if (!m) return "Enter an amount"
			await db.update(debts, d.id, { amount_minor: d.amount_minor + m })
		}
		return
	}
	const name = text(f.get("name"), 80)
	const cig = count(f.get("cig"))
	const money = toMinor(f.get("amount"))
	if (!name) return "Enter a name"
	if (!cig && !money) return "Enter an amount"
	await db.transaction(async (tx) => {
		const all = await tx.findMany(people, { where: { user_id: uid } })
		const person = all.find((p) => p.name.toLowerCase() === name.toLowerCase()) ?? (await tx.create(people, { id: id(), user_id: uid, name }, { returnRow: true }))
		const mine = await tx.findMany(debts, { where: { user_id: uid, person_id: person.id } })
		if (money) {
			const row = mine.find((d) => d.kind === "money")
			if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money })
			else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, created_at: Date.now() })
		}
		if (cig) {
			const row = mine.find((d) => d.kind === "item")
			if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig })
			else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "item", item_name: "cig", item_qty: cig, amount_minor: 0, created_at: Date.now() })
		}
	})
}

export async function clearDebt(uid: string, f: FormData) {
	const d = await db.findOne(debts, { where: { id: own(f, "debt_id"), user_id: uid } })
	if (d) await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 })
}

export async function payDebt(uid: string, f: FormData): Result {
	const d = await db.findOne(debts, { where: { id: own(f, "debt_id"), user_id: uid } })
	if (!d) return
	if (d.kind === "item") {
		const n = Math.min(count(f.get("amount")), d.item_qty ?? 0)
		if (!n) return "Enter an amount"
		await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n })
		return
	}
	const pay = Math.min(toMinor(f.get("amount")), d.amount_minor)
	if (!pay) return "Enter an amount"
	const person = await db.find(people, d.person_id)
	const purchaseId = id()
	const now = Date.now()
	await db.transaction(async (tx) => {
		await tx.create(purchases, { id: purchaseId, user_id: uid, name: `Paid ${person?.name ?? ""}`.trim(), qty: 1, unit_minor: pay, total_minor: pay, day: today(), debt_id: d.id, created_at: now })
		await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now })
		await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay })
	})
}

export async function addGoal(uid: string, f: FormData): Result {
	const title = text(f.get("name"), 120)
	if (!title) return "Enter a goal name"
	await db.create(goals, { id: id(), user_id: uid, title, target_minor: 0, saved_minor: 0, is_wish: 1, created_at: Date.now() })
}

export async function addGoalItem(uid: string, f: FormData): Result {
	const g = await db.findOne(goals, { where: { id: own(f, "goal_id"), user_id: uid } })
	if (!g) return "Goal not found"
	const name = text(f.get("name"), 120)
	if (!name) return "Enter an item"
	const price = toMinor(f.get("price"))
	if (!price) return "Enter a price"
	await db.create(goalItems, { id: id(), user_id: uid, goal_id: g.id, name, price_minor: price, created_at: Date.now() })
}

export async function editGoal(uid: string, f: FormData): Result {
	const name = text(f.get("name"), 120)
	if (!name) return "Enter a goal name"
	await db.exec(sql`update goals set title = ${name} where id = ${own(f)} and user_id = ${uid}`)
}

export async function editGoalItem(uid: string, f: FormData): Result {
	const name = text(f.get("name"), 120)
	if (!name) return "Enter an item"
	const price = toMinor(f.get("price"))
	if (!price) return "Enter a price"
	await db.exec(sql`update goal_items set name = ${name}, price_minor = ${price} where id = ${own(f)} and user_id = ${uid} and done_at is null`)
}

export async function deleteGoalItem(uid: string, f: FormData) {
	await db.exec(sql`delete from goal_items where id = ${own(f)} and user_id = ${uid}`)
}

export async function deleteWish(uid: string, f: FormData) {
	const gid = own(f)
	await db.exec(sql`delete from goal_items where goal_id = ${gid} and user_id = ${uid}`)
	await db.exec(sql`delete from goals where id = ${gid} and user_id = ${uid}`)
}

export async function buyWish(uid: string, f: FormData): Result {
	const it = await db.findOne(goalItems, { where: { id: own(f), user_id: uid } })
	if (!it || it.done_at) return
	const bal = await balanceOf(uid)
	if (it.price_minor > bal) return `Not enough balance for ${it.name}. You have ${fmt(Math.max(0, bal))}`
	await db.transaction(async (tx) => {
		await tx.create(purchases, { id: id(), user_id: uid, name: it.name, qty: 1, unit_minor: it.price_minor, total_minor: it.price_minor, day: today(), created_at: Date.now() })
		await tx.update(goalItems, it.id, { done_at: Date.now() })
	})
}

export async function addIncome(uid: string, f: FormData): Result {
	const s = await db.findOne(incomeSources, { where: { id: own(f, "source_id"), user_id: uid } })
	if (!s) return "Unknown source"
	if (s.type === "exoclick") return "ExoClick income is added automatically"
	const day = today()
	const key = extKey(s.id, day)
	if (await db.findOne(incomes, { where: { user_id: uid, ext_key: key } })) return `${s.name} is already added today`
	let amount = 0
	let meta: Record<string, number> = {}
	if (isFixed(s.type)) {
		const cfg = parseJson(s.config)
		amount = Number(cfg.fixed_minor) || 0
		meta = { fixed_minor: amount, hours: 0, rate_minor: Number(cfg.rate_minor) || 0 }
	} else amount = toMinor(f.get("amount")) || s.amount_minor
	if (amount <= 0) return "Amount must be more than 0"
	await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, amount_minor: amount, day, created_at: Date.now(), meta: JSON.stringify(meta), ext_key: key })
}

export async function toggleSource(uid: string, f: FormData) {
	const s = await db.findOne(incomeSources, { where: { id: own(f), user_id: uid } })
	if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 })
}

export async function deleteSource(uid: string, f: FormData) {
	const s = await db.findOne(incomeSources, { where: { id: own(f), user_id: uid } })
	if (!s) return
	await db.transaction(async (tx) => {
		await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`)
		await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`)
	})
}

export async function deleteIncome(uid: string, f: FormData): Result {
	const row = await db.findOne(incomes, { where: { id: own(f, "id", 80), user_id: uid } })
	if (!row) return
	if (row.ext_key.startsWith("trade:")) return "Undo this from the Trading page"
	if (row.ext_key) {
		const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null
		if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead"
	}
	await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } })
}

export async function saveNote(uid: string, f: FormData) {
	const body = text(f.get("text"), 5000)
	if (!body) return
	const noteId = own(f)
	const now = Date.now()
	if (noteId) await db.updateMany(notes, { body, updated_at: now }, { where: { id: noteId, user_id: uid } })
	else await db.create(notes, { id: id(), user_id: uid, body, created_at: now, updated_at: now })
}

export async function deleteNote(uid: string, f: FormData) {
	await db.deleteMany(notes, { where: { id: own(f), user_id: uid } })
}

export async function deleteAccount(uid: string) {
	await db.transaction(async (tx) => {
		for (const stmt of [
			sql`delete from debt_payments where user_id = ${uid}`,
			sql`delete from debts where user_id = ${uid}`,
			sql`delete from people where user_id = ${uid}`,
			sql`delete from purchases where user_id = ${uid}`,
			sql`delete from incomes where user_id = ${uid}`,
			sql`delete from income_sources where user_id = ${uid}`,
			sql`delete from trade_results where user_id = ${uid}`,
			sql`delete from trade_sessions where user_id = ${uid}`,
			sql`delete from goal_items where user_id = ${uid}`,
			sql`delete from goals where user_id = ${uid}`,
			sql`delete from notes where user_id = ${uid}`,
			sql`delete from quick_buys where user_id = ${uid}`,
			sql`delete from user_images where user_id = ${uid}`,
			sql`delete from oauth_accounts where user_id = ${uid}`,
			sql`delete from passwords where user_id = ${uid}`,
			sql`delete from sessions where user_id = ${uid}`,
			sql`delete from users where id = ${uid}`,
		])
			await tx.exec(stmt)
	})
}

const cell = (v: string | number) => {
	let s = String(v)
	if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`
	return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
}

export async function exportCsv(uid: string) {
	const [bs, is, ss] = await Promise.all([
		db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
		db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
		db.findMany(incomeSources, { where: { user_id: uid } }),
	])
	const names = new Map(ss.map((s) => [s.id, s.name]))
	const num = (minor: number) => fmt(minor).replace(/,/g, "")
	const lines = ["date,type,name,qty,amount"]
	for (const i of is) {
		const m = parseJson(i.meta)
		lines.push([i.day, "income", cell(names.get(i.source_id ?? "") ?? (String(m.label ?? m.name ?? "").trim() || "Other")), 1, num(i.amount_minor)].join(","))
	}
	for (const b of bs) lines.push([b.day, "buy", cell(b.name), b.qty, num(b.total_minor)].join(","))
	return lines.join("\n")
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/assets.ts" << 'MT_EOF_7f3a9c'
import { env } from "../env.ts"
const SITE_DESC = "Moneytracker is a quiet personal money tracker. Log what you spend and earn, track debts and wishes, and watch your road to your goals."
const bytes = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))
const png = (s: string) => new Response(bytes(s), { headers: { "Content-Type": "image/png", "Cache-Control": "public, max-age=604800" } })
const text = (body: string, type: string, cache = "public, max-age=86400") => new Response(body, { headers: { "Content-Type": type, "Cache-Control": cache } })
const origin = () => env.APP_ORIGIN.replace(/\/$/, "")
const I192 = "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"
const I512 = "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"
const A180 = "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"
const M512 = "iVBORw0KGgoAAAANSUhEUgAAAgAAAAIABAMAAAAGVsnJAAAAMFBMVEV1ws9yvMlvt8Vvt8Rvt8NutcJttMFclqEzT1UXHiIUGR0TGBwTGBsTGBoQExYNDRBXH/pNAAAO90lEQVR42u3dfXAU5R0H8N9uQGIhdxvAl/GSuyN0QseaiFUaDYpjJSJEMFoo4U2BakmV6ThDK2/2xZnWGpTWzoADM3Wmo7WEWhAjxHbUOoSRNxnNhYSOTTkvd4naYpO7Cx0gmez2j3sn99zthd1n9zbf+wsmucs+n/v9fs/LPrsrnKKx/RIJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgHwE6PPpdbDyZ/kAIMyq8wb1aL7iHf9dKQ8AJj3/0hKnDkEg+5dc2nxY848t+IHWxzljvme4r6atWOvE+uqBF0+8eI+idQyM0z5Sr6revE55dF+Zpp/qnfW17dvGrw6Wmj4CAkc+H1jw57YLj3+oZQx4a95q/tUi5z+pIWT2GiB0zZQ/vu/qn26pkbX7UN/iXcd/99hZX8F+yewRoJS8332R+sfd9grN6dQqBrwPb2s8O+8fRHTpmsJCc9cAxf62i4jknsW7aGOXqNH337hlsewjIuWboaBkbgCSwpHOwHvfbqoa0qISeusatz32ceTfLsH04wBFif7j7NznT9R4NWj/4u2b50bbT8Gg2QEGDtjjR75kV+PiKx4RyTWNW5bEHUNDN5scQOhP+u7u27W17goF5PFNWx5LiqN+yeQAweSh2tma7S8tuiIBuffSicUfJ/kGFbNHwLnkGPWu3LpzzpV8XM/8pqPJdWTgTbNHAKWW6fblmw5dwYDIV7vpT6mDX80HQtr3AimHqHTMPzF+1Ekg123feVdK3RdM3wuMaMPnf9374CgF5P+98MwjPp0PcJzOn0/D5buvXekfXQGofnjtJ5RnAMqIocp/791cXOQeTQDUbrztkxHDrGCepQARfbbsxGj6Qrl3+8t9+h/dOP3/BJ3pmlEbzn1hoXbtqjZrAAx/Z5NLzjUJ5Ls2fZ1D+/mcF+he9lHOw6GefS/bKA8BBCnNUEU585uDOVYBefanq9LUO0GQ8jECaHhZV44h0LP/5TYiq6QA0ZlXDuUUAnLtyVWUpwBpO+rh2pOLcvmQ3lcOpQ0AxfwAjDWrzn1/zCEE5OqPFqb/ieknQ/ZrPOmrwOxcOoKefQfTV4Cih8x+XsBWzBir9u5X3xHIs7sYCaMUd5scQK5jjPmG56vvCHr272R0Aa7Rz60NrgFE6scC8uxPmV2A6WuAEFrIHAv4VK7oDsjMMUCnXWsB4ZTGHxh+28/4ogs8AXXrAv7WAQaA6O8wew2gEPM7Gl72uqockBcwA0AI2fNgNshcsvBfvUJNCPSccrJ+pP04SPsIsF3L3MYysP+IihCQb+pi1opJa7pND1C0lrn2Ic/3qPqEnUwmV7knD1KAnaZnmsLt2acBLeyFoJD2R6v5FhnhXIbF++nChWzdmFyxuvAiK1w7GgtNnwLkZ3fVivSZK2s32sf2E0LOPJgO2yezVzJ6X8g6FhrYy543D0/TPgc0HwiRXOqsZP41eaXTnfndztluZgSUVla6zR8BVMzexqJUBrO9Wwmwf0UqpjyIAKLX/cx+TAz4M/cDgfZ29pv9h/JgIEQUyDRc7c8SAkp/pmF2ZV5EgFxhr2D+0DmnNFMay5Wl7EJf4apw50MEUHhlhs6+L2MbxAxXBAhHXZQfNSDgCTB7woL2jIPBK3ireYbCVPqNOez5nD1jI0pb2TXCMU+H9usCIE8LOtkToiMT2QmiPLiTXT6UyT53fqQABQ4PMAPZedOz7C9Z+JIdOwWegXyJAFJm/IzZjsDRwQzvHGSPlBz3BvU4Vl0iQK4smsM8WtsHGd45lVnohZK7S935AkABz2n2eC7jOID9ttN69AF6AWQcC43upcsoSDcA5fxb7DI4qleB5/xhSY9D1WePkCBvdGkbAjfe79Ol/XptkCgSn5ipaQDscXv0OVJ9UoDIf+lRLUOg4oan/PocqOaLorEQmCGP69fs08r2vf83Kb8igHx33rBGqzpY8J8f3anXZibdAJSeM89qlQQVF19t1SkA9NslJjh+/ETShws5duJiUoPde+Y169V+HbfJiYc2/SvRE1TkeOH7pNOJBPj7r2vdlH8AVHLsuT/EDtz9+qqcvkPhzILYkYmDDetbKR8BRMf3ft4cESh7c0NuWzuEUNW5suinXHy82Z2XACR+8PT6I24imv7e08+JOU1mFXfDuve+RUTiTcfWfaVj+3UbBxARkXTqh/9+dcEXU1obnntTacolBGyzyu+e8MKCL6ef++AXK8I6HqLO1wuUvHO/+NslJ+uX/mX6YE6XPUvF4rs/UZ75/hvX/fJJPRNAbwDRMX7j1C0NVUNlw3WP5HJmVxnfVnZgA21p+PYjB3Rtv95XjIhDH24Qrp8dJhJyiwCJyH1wQ3hGrc7t1/2SGbHk4KZz7aMbxjgP/bqrVef263/NkOh8I7IIltMOryARkVDyxmS928/hoikheheJ3MYBEbwy3Y+O283UhNDCHAQE7bfEGg1AwZz2eIYUshiA0Bm/rJy9Ll4W+xUhuNByEZDoBUtYI5sp7/oS/aDVIiDStRMRiS2Msd2Uk/Wroj8QBLIeQGwT9aS1z69PJzDlZH3V0ui8V+F3VOOIdw64yvdspB0jriefcrK+aoE9xDsD9J0NprT/woFCIiLh1AMl3vqh16pSp8cF7fVVtafDhZFtorY7q0NWSwElmgJieOVkx7GNkYWCRPsH66tq26VAtPtXKGi5GhC74m/imhCJjmMblycLFAxeqKptl6h0XjMRsa8+zO9eIFYCDhOJjmMNSQIFgxM21bZLRPItocs7TesARLo2ocUuEZHouFAfFygYnNBQ2yoRkdjxpDu5y7RWNxgrAVJkoWBCTEAcnNBQG532BuwS5wPi1w1GOveJa0KxpZIJ9fSam4iGEu2n0usXOYn4lUCeERCZDrrKY2dIxKEJ9auJiK5LtD9aBIROu/UABLInSkBU4IKLiMT25Ylln2gRCFlwLiB0SFKiBET+dtA7k4j6QkkdYsAuEQnCXRacDIUVIpq4JqmDl6vfbiOSFyRfUDq0rpmIgi4L1gCSJCL7NbcktdYWIEq9RMBbc4DvZJBnL0BE1HPM9lR8obvnRAURUe/x+FUk3pqmbXN8fPtljn8rSKTcuPWl+G1GhbMziSjpKhJvTdPuqT6us2GOAIoYJKLzy+MCcvWRNqKkIuCtadp9lUxEijtoQQBpqoeI5I7lW2M3WrVFN0FEi0BfTdPuq4aJiIruESxYA5TI5XRyx/Kt4vpmd7wExIpA36xY+0kqtmIEFNVFWiV3LN+8Y5EvUQIiRaBv1t4T0faTMt5jQYD4HFfuWNa4Y5EvVgIiRaBv1t7jLcOpM2erAcTzWu68o3HHIp8tvg9K6Zdn7T3eUnH52oHVxgHx3k3uvaORVv8+3uDe41/sPt5SEUzqLy0JkPhe5d47GoXumW2x//entJ/jehDHVWGiwsCl+J0RlPM3NrnilU65fjCl/T1zryu0YA1IOT0q91YnbZ2Uj1Ykh32I41CQ45pgZ8pdt+We5P+VJref46lRY3qBqMBl04T01cJaRXBApRTPIsh1VVhl98ZzMmjESDCX/tJSAKrPd2l/30xzACjqUyBoSQDVXyzHU6N8a4CkebHItyKosmEcT41y7gZV9m88J4N8ASTzZQDXobDK3bIc98kiBfhGQIe66sbz1CjfCAirjQAXx4Piem5Q3XRQsGoRNOeLL4Cq8qZYFkBRN8YveihoUQBJ3cPyFMmqcwGlWFXLeJ4a5QsQOz2azYnjqVHeRVBdBFi3FxBU7X8McRXQ7SYq6V6Z7jMYf+l030BTRICtqjn7Lzk2dFs2BVT18ArPFUHOKaAmBzhnAOdeQCnPmgOOtVyXAzgDlGRvnVLeStZNgew5wDsDeE+Hs+bAJM4ZwBsgaw44OWcA7xTIlgOqH8eVrxFASvnhzBnA+Xi4A5Ss9ZsqA7inQIZHyRmSAQYsimbKgaJp3A+HewTIlTb2nTYrbtbl/uGmAsiUA2J7p063TzZTCmTIAbnMJlk+BTLlgAEZYEAEiJ1PMlopvsM/AIxIAf801pKPsIo/AP8UYOeAXo8QMFsECIwcEN+p5B8AhgB0M3JAWGgAgAEpwMoBQzLAkP0B6XNAbHEZEADGAPjTtjTjM9oslQLpH0JjTAYYs0VGCIzMAaHFZcShGATQOTLYxfBKN42VFEiXAxXOSveYiYA0OSAcNaT5hgGMyAHRb0wGGJQCI3NAj2cqmzgCSAivcKcODQzKAMMALnuCrHjGoAzgfR+h+Mtxf0oOOOZ5hDEVAUQpOcCcIFoXQEzJAeMywLAUSM0B4zLAwO3y4RVJY4HJRmWAUeMASnnKNvdtIWZIAXLcHn8qp2OuYQFg5BUjYmIBhO/WQJOkQCIHjMwAA1MgkQOOW0M0FlMgngNZts1YNgViOWBoBhiZAlR6e6WTiBy3BmlspoAs2iTivznWPCkQyQFjM8DYK0eLljYbsDnWRAC2yTbJgK2B5kkBCngCp/lvDTRPBFDR0mb+m2PNBGCbZnQGGJwCFDi8p9M3hiOAbFVh2dgjGGfsny+a/aXuTxU1dQpQ95xuGsspQE4PjW0AQRrjAIa/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPF7/B13sQaO95Bc/AAAAAElFTkSuQmCC"
const SVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\"><rect width=\"24\" height=\"24\" rx=\"5\" fill=\"#13181b\"/><g transform=\"translate(12 12) scale(.62) translate(-12 -12.2)\"><path fill=\"#6fb7c4\" d=\"M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z\"/><path d=\"M9.2 11.4l2 1M14.8 11.4l-2 1\" stroke=\"#13181b\" stroke-width=\"1.5\"/></g></svg>"
const SW = "const C=\"mt-v2\",O=\"<!doctype html><meta name=viewport content='width=device-width,initial-scale=1'><body style='font:16px system-ui;background:#13181b;color:#e8edf0;display:grid;place-items:center;min-height:100vh;margin:0'><p>You are offline</p>\";\nself.addEventListener(\"install\",()=>self.skipWaiting());\nself.addEventListener(\"activate\",(e)=>e.waitUntil(caches.keys().then((k)=>Promise.all(k.filter((x)=>x!==C).map((x)=>caches.delete(x)))).then(()=>self.clients.claim())));\nself.addEventListener(\"fetch\",(e)=>{const r=e.request;if(r.method!==\"GET\")return;const u=new URL(r.url);const same=u.origin===self.location.origin;if((same&&((u.pathname.startsWith(\"/assets/\")&&u.searchParams.has(\"v\"))||/^\\/(icon-|apple-touch-icon|favicon)/.test(u.pathname)))||u.hostname===\"fonts.gstatic.com\"||u.hostname===\"fonts.googleapis.com\"){e.respondWith(caches.open(C).then((c)=>c.match(r).then((h)=>h||fetch(r).then((n)=>{if(n.ok||n.type===\"opaque\")c.put(r,n.clone());return n}))));return}if(r.mode===\"navigate\")e.respondWith(fetch(r).catch(()=>new Response(O,{headers:{\"Content-Type\":\"text/html\"}})))});"
export const SITE = { name: "Moneytracker", desc: SITE_DESC, color: "#13181b" }
export const assets = {
	manifest: () =>
		text(
			JSON.stringify({
				id: "/",
				name: "Moneytracker",
				short_name: "Money",
				description: SITE_DESC,
				start_url: "/home",
				scope: "/",
				display: "standalone",
				orientation: "portrait",
				background_color: "#13181b",
				theme_color: "#13181b",
				categories: ["finance", "productivity"],
				icons: [
					{ src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
					{ src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
					{ src: "/icon-maskable.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
				],
			}),
			"application/manifest+json",
		),
	favicon: () => text(SVG, "image/svg+xml; charset=utf-8"),
	icon192: () => png(I192),
	icon512: () => png(I512),
	iconMaskable: () => png(M512),
	appleIcon: () => png(A180),
	sw: () => text(SW, "application/javascript; charset=utf-8", "no-cache"),
	robots: () => text(`User-agent: *\nAllow: /login\nAllow: /signup\nDisallow: /\nSitemap: ${origin()}/sitemap.xml\n`, "text/plain; charset=utf-8"),
	sitemap: () =>
		text(
			`<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>${origin()}/login</loc></url><url><loc>${origin()}/signup</loc></url></urlset>`,
			"application/xml; charset=utf-8",
		),
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/auth.ts" << 'MT_EOF_7f3a9c'
import { auth, createSessionAuthScheme } from "remix/middleware/auth"
import { createGoogleAuthProvider } from "remix/auth"
import { createCookie } from "remix/cookie"
import { session } from "remix/middleware/session"
import { createDbSessionStorage } from "../db/session-storage.ts"
import { env } from "../env.ts"
import { getUserById } from "./users.ts"
const sessionCookie = createCookie("__session", {
	secrets: [env.SESSION_SECRET],
	httpOnly: true,
	secure: import.meta.env.PROD,
	sameSite: "lax",
	path: "/",
	maxAge: 60 * 60 * 24 * 30,
})
export const sessionMiddleware = session(sessionCookie, createDbSessionStorage())
export const authMiddleware = auth({
	schemes: [
		createSessionAuthScheme({
			read(s) {
				const v = s.get("auth") as { userId?: string } | null
				return v && typeof v.userId === "string" ? (v as { userId: string }) : null
			},
			async verify(value) {
				try {
					return await getUserById(value.userId)
				} catch {
					return null
				}
			},
			invalidate(s) {
				s.unset("auth")
			},
		}),
	],
})
export const googleProvider = createGoogleAuthProvider({
	clientId: env.GOOGLE_CLIENT_ID,
	clientSecret: env.GOOGLE_CLIENT_SECRET,
	redirectUri: new URL("/auth/google/callback", env.APP_ORIGIN),
})
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/auto.ts" << 'MT_EOF_7f3a9c'
import { sql } from "remix/data-table"

import { db, incomes, incomeSources, users } from "../db/index.ts"
import { addDays, dayOf, hhmm, today } from "./time.ts"
import { extKey, id, rowsOf } from "./util.ts"

const hm = (v: string | null | undefined) => {
	const m = /^(\d{1,2}):(\d{2})$/.exec(v ?? "")
	return m ? `${m[1]!.padStart(2, "0")}:${m[2]}` : "06:00"
}

const pad = (n: number) => String(n).padStart(2, "0")
const lastDayOf = (y: number, m: number) => new Date(Date.UTC(y, m, 0)).getUTCDate()

export async function settleAuto(uid: string): Promise<void> {
	const all = await db.findMany(incomeSources, { where: { user_id: uid, mode: "auto" } })
	const srcs = all.filter((s) => s.active !== 0 && s.amount_minor > 0)
	if (!srcs.length) return

	const u = await db.find(users, uid)
	const runAt = hm(u?.run_at)
	const now = Date.now()
	const t = today()
	const nowHm = hhmm(now)

	const res = await db.exec(sql`select ext_key as k from incomes where user_id = ${uid} and ext_key <> ''`)
	const have = new Set(rowsOf(res).map((r) => String(r.k ?? r[0] ?? "")))

	const due = (d: string) => d < t || (d === t && nowHm >= runAt)

	for (const s of srcs) {
		const created = dayOf(s.created_at)
		const createdHm = hhmm(s.created_at)
		const started = (d: string) => d > created || (d === created && createdHm < runAt)
		const days: string[] = []

		if (s.every === "month") {
			const dom = Number(created.slice(8, 10))
			let y = Number(created.slice(0, 4))
			let m = Number(created.slice(5, 7))
			const endY = Number(t.slice(0, 4))
			const endM = Number(t.slice(5, 7))
			for (let i = 0; i < 36 && (y < endY || (y === endY && m <= endM)); i++) {
				days.push(`${y}-${pad(m)}-${pad(Math.min(dom, lastDayOf(y, m)))}`)
				if (++m > 12) (m = 1), y++
			}
		} else {
			const from = created > addDays(t, -62) ? created : addDays(t, -62)
			for (let d = from; d <= t; d = addDays(d, 1)) days.push(d)
		}

		for (const d of days) {
			if (!due(d) || !started(d)) continue
			const key = extKey(s.id, d)
			if (have.has(key)) continue
			have.add(key)
			try {
				await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, amount_minor: s.amount_minor, day: d, created_at: now, meta: '{"auto":1}', ext_key: key })
			} catch {}
		}
	}
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/crypto.ts" << 'MT_EOF_7f3a9c'
import { env } from "../env.ts"

const ITERATIONS = 100_000
const enc = new TextEncoder()
const dec = new TextDecoder()

const b64 = (b: ArrayBuffer | Uint8Array) => btoa(String.fromCharCode(...new Uint8Array(b)))
const unb64 = (s: string) => Uint8Array.from(atob(s), (c) => c.charCodeAt(0))

async function derive(password: string, salt: Uint8Array, iterations: number) {
	const key = await crypto.subtle.importKey("raw", enc.encode(password), "PBKDF2", false, ["deriveBits"])
	return crypto.subtle.deriveBits({ name: "PBKDF2", hash: "SHA-256", salt, iterations }, key, 256)
}

export async function hashPassword(password: string) {
	const salt = crypto.getRandomValues(new Uint8Array(16))
	return `pbkdf2$${ITERATIONS}$${b64(salt)}$${b64(await derive(password, salt, ITERATIONS))}`
}

export async function verifyPassword(password: string, stored: string) {
	const [scheme, iter, salt, hash] = stored.split("$")
	if (scheme !== "pbkdf2" || !iter || !salt || !hash) return false
	const bits = new Uint8Array(await derive(password, unb64(salt), Number(iter)))
	const want = unb64(hash)
	if (bits.length !== want.length) return false
	let diff = 0
	for (let i = 0; i < bits.length; i++) diff |= bits[i]! ^ want[i]!
	return diff === 0
}

export async function fakeVerify(password: string) {
	await derive(password, new Uint8Array(16), ITERATIONS)
}

let cached: { s: string; k: CryptoKey } | null = null

async function secretKey() {
	if (cached && cached.s === env.SESSION_SECRET) return cached.k
	const base = await crypto.subtle.importKey("raw", enc.encode(env.SESSION_SECRET), "PBKDF2", false, ["deriveKey"])
	const k = await crypto.subtle.deriveKey({ name: "PBKDF2", salt: enc.encode("moneytracker-secret-v1"), iterations: ITERATIONS, hash: "SHA-256" }, base, { name: "AES-GCM", length: 256 }, false, ["encrypt", "decrypt"])
	cached = { s: env.SESSION_SECRET, k }
	return k
}

export async function encryptSecret(plain: string) {
	const iv = crypto.getRandomValues(new Uint8Array(12))
	const ct = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv }, await secretKey(), enc.encode(plain)))
	return `v1.${b64(iv)}.${b64(ct)}`
}

export async function decryptSecret(v: string) {
	try {
		const [p, i, c] = v.split(".")
		if (p !== "v1" || !i || !c) return null
		return dec.decode(await crypto.subtle.decrypt({ name: "AES-GCM", iv: unb64(i) }, await secretKey(), unb64(c)))
	} catch {
		return null
	}
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/data.ts" << 'MT_EOF_7f3a9c'
import { sql } from "remix/data-table"
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases } from "../db/index.ts"
import { settleAuto } from "./auto.ts"
import { exoStatus, liveExo, settleExo } from "./exoclick.ts"
import type { TradeSession } from "./trade-math.ts"
import { loadTrades } from "./trading.ts"
import { addDays, dayLabel, today } from "./time.ts"
import { getActiveAvatar, type User } from "./users.ts"
import { parseJson, rowsOf, type Json } from "./util.ts"

export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number }
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; hours: number; locked: boolean }
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number }
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number }
export type GoalItem = { id: string; name: string; price: number; done: boolean }
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] }
export type Note = { id: string; body: string; at: number; edited: boolean }
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] }
export type Part = "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar" | "names" | "incnames" | "trading"

export type State = {
	user: User
	back: string
	error: string
	avatar: string | null
	names: string[]
	incNames: string[]
	exo: Record<string, string>
	exoToday: Record<string, number>
	trades: TradeSession[]
	buys: Buy[]
	incomesToday: Income[]
	sources: Source[]
	debts: DebtView[]
	goals: Goal[]
	notes: Note[]
	days: DayRow[]
	balance: number
}

const settleAll = async (uid: string) => void (await Promise.all([settleAuto(uid), settleExo(uid)]))

const scalar = (r: unknown) => {
	const row = rowsOf(r)[0]
	return Number(row?.s ?? row?.[0] ?? 0) || 0
}

const total = async (uid: string) => {
	const [i, p] = await Promise.all([
		db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
		db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
	])
	return scalar(i) - scalar(p)
}

const names = (r: unknown) => rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean)

export async function balanceOf(uid: string) {
	await settleAll(uid)
	return total(uid)
}

const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number }): Buy => ({
	id: r.id,
	name: r.name,
	qty: r.qty,
	unit: r.unit_minor,
	total: r.total_minor,
	day: r.day,
	at: r.created_at,
})

async function loadDebts(uid: string): Promise<DebtView[]> {
	const [pe, de, pay] = await Promise.all([
		db.findMany(people, { where: { user_id: uid } }),
		db.findMany(debts, { where: { user_id: uid } }),
		db.findMany(debtPayments, { where: { user_id: uid } }),
	])
	const who = new Map(pe.map((p) => [p.id, p.name]))
	const paid = new Map<string, number>()
	for (const p of pay) paid.set(p.debt_id, (paid.get(p.debt_id) ?? 0) + p.amount_minor)
	return de
		.map((d): DebtView => {
			const kind = d.kind === "item" ? "item" : "money"
			return {
				id: d.id,
				person: who.get(d.person_id) ?? "?",
				kind,
				item: d.item_name || "cig",
				owed: kind === "item" ? (d.item_qty ?? 0) : d.amount_minor,
				paid: paid.get(d.id) ?? 0,
			}
		})
		.filter((d) => d.owed > 0)
		.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1))
}

export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
	const need = new Set(parts)
	const uid = user.id
	const t = today()
	const s: State = {
		user,
		back: extra.back,
		error: extra.error ?? "",
		avatar: null,
		names: [],
		incNames: [],
		exo: {},
		exoToday: {},
		trades: [],
		buys: [],
		incomesToday: [],
		sources: [],
		debts: [],
		goals: [],
		notes: [],
		days: [],
		balance: 0,
	}

	const needSources = need.has("sources") || need.has("today") || need.has("history")
	if (needSources || need.has("balance")) await settleAll(uid)

	const jobs: Promise<void>[] = []
	if (need.has("avatar")) jobs.push(getActiveAvatar(uid).then((a) => void (s.avatar = a)))

	let sourceRows: Source[] = []
	if (needSources) {
		const rows = await db.findMany(incomeSources, { where: { user_id: uid }, orderBy: ["created_at", "asc"] })
		sourceRows = rows
			.map((r) => ({
				id: r.id,
				name: r.name,
				mode: r.mode,
				every: r.every ?? "",
				amount: r.amount_minor,
				created: r.created_at,
				type: r.type || "manual",
				config: parseJson(r.config),
				currency: r.currency || "MAD",
				active: r.active !== 0,
				sort: r.sort ?? 0,
			}))
			.sort((a, b) => a.sort - b.sort)
		s.sources = sourceRows
		jobs.push(exoStatus(sourceRows).then((e) => void (s.exo = e)))
	}

	const byId = new Map(sourceRows.map((x) => [x.id, x.name]))
	const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string; meta: string }): Income => {
		const m = parseJson(r.meta)
		return {
			id: r.id,
			sourceId: r.source_id ?? "",
			source: byId.get(r.source_id ?? "") ?? (String(m.label ?? m.name ?? "").trim() || "Other"),
			amount: r.amount_minor,
			day: r.day,
			hours: Number(m.hours) || 0,
			locked: !!m.trade,
		}
	}

	if (need.has("today")) {
		const exoIds = sourceRows.filter((x) => x.type === "exoclick")
		jobs.push(
			db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
				s.buys = rows.map(toBuy)
			}),
			Promise.all([
				db.findMany(incomes, { where: { user_id: uid, day: t } }),
				liveExo(uid, exoIds.filter((x) => x.active).map((x) => x.id), user.usd_rate_minor),
			]).then(([rows, live]) => {
				const exo = new Set(exoIds.map((x) => x.id))
				s.incomesToday = rows.filter((r) => !(r.source_id && exo.has(r.source_id))).map(toIncome)
				for (const x of sourceRows) {
					const v = live[x.id]
					if (!v) continue
					s.exoToday[x.id] = v.usd
					s.incomesToday.push({ id: `exo-${x.id}`, sourceId: x.id, source: x.name, amount: v.mad, day: v.day, hours: 0, locked: true })
				}
			}),
		)
	}

	if (need.has("names"))
		jobs.push(
			db
				.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null and name not like 'Deposit % USDT' group by lower(name) order by c desc, max(created_at) desc`)
				.then((r) => void (s.names = names(r))),
		)

	if (need.has("incnames"))
		jobs.push(
			db
				.exec(sql`select min(json_extract(meta, '$.label')) as n, count(*) as c from incomes where user_id = ${uid} and json_extract(meta, '$.label') is not null and json_extract(meta, '$.label') <> '' group by lower(json_extract(meta, '$.label')) order by c desc, max(created_at) desc limit 12`)
				.then((r) => void (s.incNames = names(r))),
		)

	if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)))
	if (need.has("trading")) jobs.push(loadTrades(uid).then((x) => void (s.trades = x)))

	if (need.has("goals"))
		jobs.push(
			Promise.all([
				db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
				db.findMany(goalItems, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
			]).then(([rows, its]) => {
				s.goals = rows.map((g) => {
					const items: GoalItem[] = its.filter((i) => i.goal_id === g.id).map((i) => ({ id: i.id, name: i.name, price: i.price_minor, done: !!i.done_at }))
					const left = items.filter((i) => !i.done)
					return { id: g.id, title: g.title, target: left.reduce((a, i) => a + i.price, 0), saved: g.saved_minor, done: items.length > 0 && left.length === 0, items }
				})
			}),
		)

	if (need.has("notes"))
		jobs.push(
			db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
				s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }))
			}),
		)

	if (need.has("history"))
		jobs.push(
			Promise.all([
				db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
				db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
			]).then(([bs, is]) => {
				s.days = Array.from({ length: 30 }, (_, i) => {
					const day = addDays(t, -i)
					const b = bs.filter((x) => x.day === day)
					const inc = is.filter((x) => x.day === day && parseJson(x.meta).final !== 0)
					return {
						day,
						label: dayLabel(day),
						earned: inc.reduce((a, x) => a + x.amount_minor, 0),
						bought: b.reduce((a, x) => a + x.total_minor, 0),
						buys: b.map(toBuy),
						incomes: inc.map(toIncome),
					}
				}).filter((d, i) => i === 0 || d.buys.length || d.incomes.length)
			}),
		)

	if (need.has("balance")) jobs.push(total(uid).then((b) => void (s.balance = b)))

	await Promise.all(jobs)
	return s
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/exoclick.ts" << 'MT_EOF_7f3a9c'
import { sql } from "remix/data-table"
import { db, incomes, incomeSources, users } from "../db/index.ts"
import { decryptSecret } from "./crypto.ts"
import { addDays, dayOf } from "./time.ts"
import { extKey, id, parseJson, rowsOf, type Json } from "./util.ts"

const BASE = "https://api.exoclick.com/v2"
const EVERY = 4 * 60000
const RESET_HOUR = 5
const exoDay = (ms: number) => dayOf(ms - RESET_HOUR * 3600000)
const tokens = new Map<string, { t: string; exp: number }>()
const lastTry = new Map<string, number>()
const errors = new Map<string, string>()
type Day = { usd: number; imp: number; clicks: number }

const jf = async (url: string, init: RequestInit) => {
	const c = new AbortController()
	const id = setTimeout(() => c.abort(), 8000)
	try {
		return await fetch(url, { ...init, signal: c.signal })
	} finally {
		clearTimeout(id)
	}
}
const login = async (apiKey: string): Promise<string | null> => {
	const hit = tokens.get(apiKey)
	if (hit && hit.exp > Date.now()) return hit.t
	const r = await jf(`${BASE}/login`, { method: "POST", headers: { "Content-Type": "application/json", Accept: "application/json" }, body: JSON.stringify({ api_token: apiKey }) })
	if (!r.ok) return null
	const b: any = await r.json().catch(() => null)
	const t = b?.token ?? b?.session_token ?? b?.access_token ?? b?.session_key ?? b?.key
	if (!t) return null
	tokens.set(apiKey, { t: String(t), exp: Date.now() + 14 * 60000 })
	return String(t)
}
const call = (token: string, from: string, to: string) =>
	jf(`${BASE}/statistics/p/date?date_from=${from}&date_to=${to}`, { headers: { Authorization: `Bearer ${token}`, Accept: "application/json" } })
const listOf = (b: any): any[] => (Array.isArray(b?.result) ? b.result : Array.isArray(b?.data) ? b.data : Array.isArray(b) ? b : [])
const cents = (v: unknown) => Math.round((Number(v) || 0) * 100)
const revOf = (r: any) => cents(r.revenue ?? r.earnings ?? r.money ?? r.publisher_revenue ?? 0)
const dateOf = (r: any) => {
	const d = String(r.date ?? r.ddate ?? r.day ?? r.d ?? "")
	return /^\d{4}-\d{2}-\d{2}/.test(d) ? d.slice(0, 10) : ""
}
const add = (m: Map<string, Day>, d: string, r: any) => {
	const x = m.get(d) ?? { usd: 0, imp: 0, clicks: 0 }
	x.usd += revOf(r)
	x.imp += Number(r.impressions ?? r.views ?? r.imp ?? 0) || 0
	x.clicks += Number(r.clicks ?? r.click ?? 0) || 0
	m.set(d, x)
}

async function fetchDays(apiKey: string, from: string, to: string): Promise<Map<string, Day> | string> {
	try {
		let token = await login(apiKey)
		if (!token) return "ExoClick rejected the API key"
		let r = await call(token, from, to)
		if (r.status === 401 || r.status === 403) {
			tokens.delete(apiKey)
			token = await login(apiKey)
			if (!token) return "ExoClick rejected the API key"
			r = await call(token, from, to)
		}
		if (!r.ok) return `ExoClick error ${r.status}`
		const out = new Map<string, Day>()
		for (const row of listOf(await r.json().catch(() => null))) {
			const d = dateOf(row)
			if (d) add(out, d, row)
		}
		return out
	} catch {
		return "Could not reach ExoClick"
	}
}

const col = (r: any, n: string, i: number) => r[n] ?? r[i]

async function settleOne(uid: string, s: { id: string; config: string; created_at: number }, rate: number, t: string, now: number) {
	const cfg = parseJson(s.config)
	const enc = String(cfg.key_enc ?? "")
	if (!enc) return
	const apiKey = await decryptSecret(enc)
	if (!apiKey) return
	const y = addDays(t, -1)
	const checked = String(cfg.checked ?? "")
	const floor = addDays(t, -31)
	let from = checked ? addDays(checked, 1) : dayOf(s.created_at)
	if (from < floor) from = floor
	const gap = from <= y
	const res = rowsOf(await db.exec(sql`select id, day, usd_minor, meta from incomes where user_id = ${uid} and source_id = ${s.id} and day >= ${from}`))
	const have = new Map<string, { id: string; usd: number; meta: Json }>()
	for (const r of res) have.set(String(col(r, "day", 1)), { id: String(col(r, "id", 0)), usd: Number(col(r, "usd_minor", 2)) || 0, meta: parseJson(String(col(r, "meta", 3))) })
	const todayRow = have.get(t)
	const stale = !todayRow || now - (Number(todayRow.meta.fetched_at) || 0) > EVERY
	if (!gap && !stale) return
	if ((lastTry.get(s.id) ?? 0) + EVERY > now) return
	lastTry.set(s.id, now)
	const data = await fetchDays(apiKey, from, t)
	if (typeof data === "string") {
		errors.set(s.id, data)
		return
	}
	errors.delete(s.id)
	const days = new Set<string>([...data.keys(), t])
	for (const [d, r] of have) if (d < t && r.meta.final !== 1) days.add(d)
	for (const d of days) {
		const ex = have.get(d)
		if (ex && ex.meta.final === 1) continue
		const got = data.get(d)
		const usd = got ? got.usd : (ex?.usd ?? 0)
		const final = d < t
		if (!ex && final && usd === 0) continue
		const values = {
			usd_minor: usd,
			amount_minor: final ? Math.round((usd * rate) / 100) : 0,
			meta: JSON.stringify({ final: final ? 1 : 0, rate_minor: rate, fetched_at: now, imp: got?.imp ?? 0, clicks: got?.clicks ?? 0 }),
		}
		if (ex) await db.update(incomes, ex.id, values)
		else {
			try {
				await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, day: d, created_at: now, ext_key: extKey(s.id, d), ...values })
			} catch { }
		}
	}
	if (gap) await db.update(incomeSources, s.id, { config: JSON.stringify({ ...cfg, checked: y }) })
}

export async function settleExo(uid: string): Promise<void> {
	const all = await db.findMany(incomeSources, { where: { user_id: uid, type: "exoclick" } })
	const srcs = all.filter((s) => s.active !== 0)
	if (!srcs.length) return
	const u = await db.find(users, uid)
	const rate = u?.usd_rate_minor || 1000
	const now = Date.now()
	const t = exoDay(now)
	for (const s of srcs) {
		try {
			await settleOne(uid, s, rate, t, now)
		} catch {
			errors.set(s.id, "Could not sync ExoClick")
		}
	}
}

export async function exoStatus(list: { id: string; type: string; config: Json }[]): Promise<Record<string, string>> {
	const out: Record<string, string> = {}
	for (const x of list) {
		if (x.type !== "exoclick") continue
		const enc = String(x.config.key_enc ?? "")
		out[x.id] = !enc ? "Set your API key" : !(await decryptSecret(enc)) ? "Session secret changed. Set the API key again" : (errors.get(x.id) ?? "")
	}
	return out
}

export async function liveExo(uid: string, ids: string[], rate: number): Promise<Record<string, { day: string; usd: number; mad: number }>> {
	const out: Record<string, { day: string; usd: number; mad: number }> = {}
	if (!ids.length) return out
	const day = exoDay(Date.now())
	for (const id of ids) {
		const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(id, day) } })
		const usd = row?.usd_minor || 0
		out[id] = { day, usd, mad: Math.round((usd * rate) / 100) }
	}
	return out
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/income.ts" << 'MT_EOF_7f3a9c'
import { db, incomes, incomeSources } from "../db/index.ts"
import { toMinor } from "./money.ts"
import { encryptSecret } from "./crypto.ts"
import { today } from "./time.ts"
import { extKey, id, isFixed, parseJson, text } from "./util.ts"

export async function addSource(uid: string, f: FormData): Promise<string | void> {
	const name = text(f.get("name"), 80)
	if (!name) return "Enter a name"
	const kind = text(f.get("kind"), 12) || "fixed"
	const taken = await db.findMany(incomeSources, { where: { user_id: uid } })
	if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`
	let type = "manual"
	let mode = "manual"
	let every = ""
	let amount = 0
	let currency = "MAD"
	let config: Record<string, number | string> = {}
	if (kind === "fixed") {
		const fixed = toMinor(f.get("fixed"))
		const rate = toMinor(f.get("rate"))
		if (!fixed) return "Enter the fixed amount per day"
		if (!rate) return "Enter the price per extra hour"
		type = "fixed"
		config = { fixed_minor: fixed, rate_minor: rate }
	} else if (kind === "daily" || kind === "monthly") {
		amount = toMinor(f.get("amount"))
		if (!amount) return "Enter how much it pays"
		mode = "auto"
		every = kind === "daily" ? "day" : "month"
	} else if (kind === "exoclick") {
		const k = text(f.get("api_key"), 200)
		if (!k) return "Enter your ExoClick API key"
		type = "exoclick"
		mode = "auto"
		every = "day"
		currency = "USD"
		config = { key_enc: await encryptSecret(k) }
	} else if (kind !== "manual") return "Pick a source type"
	const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] })
	await db.create(incomeSources, { id: id(), user_id: uid, name, mode, amount_minor: amount, every, created_at: Date.now(), type, config: JSON.stringify(config), currency, active: 1, sort: (last?.sort ?? -1) + 1 })
}

export async function editSource(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } })
	if (!s) return "Unknown source"
	const name = text(f.get("name"), 80)
	if (!name) return "Enter a name"
	const taken = await db.findMany(incomeSources, { where: { user_id: uid } })
	if (taken.some((x) => x.id !== s.id && x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`
	const cfg = parseJson(s.config)
	const patch: { name: string; config?: string; amount_minor?: number } = { name }
	if (isFixed(s.type)) {
		const fixed = toMinor(f.get("fixed"))
		const rate = toMinor(f.get("rate"))
		if (!fixed) return "Enter the fixed amount per day"
		if (!rate) return "Enter the price per extra hour"
		patch.config = JSON.stringify({ ...cfg, fixed_minor: fixed, rate_minor: rate })
	} else if (s.type === "exoclick") {
		const k = text(f.get("api_key"), 200)
		if (k) patch.config = JSON.stringify({ ...cfg, key_enc: await encryptSecret(k) })
	} else if (s.mode === "auto") {
		const a = toMinor(f.get("amount"))
		if (!a) return "Enter how much it pays"
		patch.amount_minor = a
	}
	await db.update(incomeSources, s.id, patch)
}

export async function setHours(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } })
	if (!s || !isFixed(s.type)) return "Unknown source"
	const raw = text(f.get("hours"), 8).replace(",", ".")
	let h = raw === "" ? 0 : Number(raw)
	if (!Number.isFinite(h) || h < 0 || h > 24) return "Hours must be between 0 and 24"
	h = Math.round(h * 100) / 100
	const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, today()) } })
	if (!row) return `Add ${s.name} first`
	const meta = parseJson(row.meta)
	const cfg = parseJson(s.config)
	if (f.get("toggle") && Number(meta.hours) === h) h = 0
	const fixed = Number(meta.fixed_minor) || Number(cfg.fixed_minor) || 0
	const rate = Number(cfg.rate_minor) || 0
	await db.update(incomes, row.id, { amount_minor: fixed + Math.round(h * rate), meta: JSON.stringify({ ...meta, fixed_minor: fixed, hours: h, rate_minor: rate }) })
}

export async function addNamed(uid: string, f: FormData): Promise<string | void> {
	const amount = toMinor(f.get("amount"))
	if (!amount) return "Enter an amount"
	const label = text(f.get("label"), 60)
	await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day: today(), created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, label } : { manual: 1 }), ext_key: "" })
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/money.ts" << 'MT_EOF_7f3a9c'
const parse = (s: unknown) => parseFloat(String(s ?? "").replace(",", "."))

export const toMinor = (s: unknown) => {
	const n = parse(s)
	return Number.isFinite(n) && n > 0 && n <= 1e9 ? Math.round(n * 100) : 0
}

export const toSigned = (s: unknown) => {
	if (!String(s ?? "").trim()) return null
	const n = parse(s)
	return Number.isFinite(n) && Math.abs(n) <= 1e9 ? Math.round(n * 100) : null
}

export const fmt = (minor: number) => {
	const v = minor / 100
	return v.toLocaleString("en-US", { maximumFractionDigits: 2, minimumFractionDigits: Number.isInteger(v) ? 0 : 2 })
}

export const plain = (minor: number) => (minor / 100).toFixed(2).replace(/\.00$/, "")
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/static.ts" << 'MT_EOF_7f3a9c'
import css from "../client/app.css?raw"
import js from "../client/app.js?raw"

export const hash = (s: string) => {
	let h = 5381
	for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0
	return (h >>> 0).toString(36)
}

export const files = { css, js }

export const V = { css: hash(css), js: hash(js) }
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/time.ts" << 'MT_EOF_7f3a9c'
const TZ = "Africa/Casablanca"

const dayFmt = new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" })
const timeFmt = new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "2-digit", minute: "2-digit" })

export const dayOf = (ms: number) => dayFmt.format(ms)
export const today = () => dayOf(Date.now())
export const hhmm = (ms: number) => timeFmt.format(ms)

export function addDays(day: string, n: number) {
	const d = new Date(`${day}T12:00:00Z`)
	d.setUTCDate(d.getUTCDate() + n)
	return d.toISOString().slice(0, 10)
}

export function dayLabel(day: string) {
	const t = today()
	if (day === t) return "Today"
	if (day === addDays(t, -1)) return "Yesterday"
	return new Date(`${day}T12:00:00Z`).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" }).replace(",", "")
}

const part = (locale: string, options: Intl.DateTimeFormatOptions, now: Date) => new Intl.DateTimeFormat(locale, { timeZone: TZ, ...options }).format(now)

export function liveClockNow() {
	const now = new Date()
	return {
		timeStr: part("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false }, now),
		dateStr: part("en-GB", { weekday: "long", day: "numeric", month: "long" }, now),
		numDate: part("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" }, now),
		arabicDay: part("ar-MA", { weekday: "long" }, now),
	}
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/trade-math.ts" << 'MT_EOF_7f3a9c'
export const DEPOSIT = 400
const BTC_STAKE = 100
const PRED_STAKE = 300
export const BTC_ROUNDS = 4
export const PRED_COUNT = 3
export const PICKS: [string, number][] = [
	["BTC", 5],
	["BTC", 15],
	["ETH", 5],
	["ETH", 15],
]

export type Game = "btc" | "pred"
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number; state: "set" | "done"; asset: string; tf: number }
export type TradeSession = {
	id: string
	day: string
	deposit: number
	rate: number
	status: "open" | "settled"
	pnl: number
	returnUsdt: number
	returnMad: number
	at: number
	results: TradeResult[]
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const btcOf = (r: TradeResult[]) => r.filter((x) => x.game === "btc").sort((a, b) => a.idx - b.idx)
export const predOf = (r: TradeResult[]) => r.filter((x) => x.game === "pred").sort((a, b) => a.idx - b.idx)
export const btcLost = (r: TradeResult[]) => btcOf(r).some((x) => isDone(x) && !x.won)
export const btcDone = (r: TradeResult[]) => btcLost(r) || doneOf(btcOf(r)).length >= BTC_ROUNDS
const predDone = (r: TradeResult[]) => doneOf(predOf(r)).length >= PRED_COUNT
export const allDone = (r: TradeResult[]) => btcDone(r) && predDone(r)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const missAmount = (game: Game, r: TradeResult[]) => (game === "btc" ? BTC_STAKE + doneOf(btcOf(r)).reduce((a, x) => a + x.pnl, 0) : PRED_STAKE / PRED_COUNT)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const strip = (r: TradeResult[]) => doneOf(r).map((x) => (x.won ? "W" : "M")).join(" ")
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/trading.ts" << 'MT_EOF_7f3a9c'
import { sql } from "remix/data-table"
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts"
import { today } from "./time.ts"
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcOf,
	DEPOSIT,
	doneOf,
	isDone,
	missAmount,
	PICKS,
	PRED_COUNT,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "./trade-math.ts"
import type { User } from "./users.ts"
import { id, text } from "./util.ts"

const usdtMinor = (v: unknown) => {
	const raw = String(v ?? "").trim().replace(",", ".")
	if (!raw) return null
	const n = Math.abs(Number(raw))
	return Number.isFinite(n) && n <= 100000 ? Math.round(n * 100) : null
}

const toResult = (r: { id: string; game: string; idx: number; won: number; pnl_minor: number; state: string; asset: string; tf: number }): TradeResult => ({
	id: r.id,
	game: r.game === "pred" ? "pred" : "btc",
	idx: r.idx,
	won: r.won !== 0,
	pnl: r.pnl_minor,
	state: r.state === "set" ? "set" : "done",
	asset: r.asset || "",
	tf: r.tf || 0,
})

async function resultsOf(uid: string, sessionId: string): Promise<TradeResult[]> {
	const rows = await db.findMany(tradeResults, { where: { user_id: uid, session_id: sessionId }, orderBy: ["created_at", "asc"] })
	return rows.map(toResult)
}

export async function loadTrades(uid: string): Promise<TradeSession[]> {
	const rows = await db.findMany(tradeSessions, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 30 })
	if (!rows.length) return []
	const res = await db.findMany(tradeResults, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 })
	const by = new Map<string, TradeResult[]>()
	for (const r of res) {
		const list = by.get(r.session_id) ?? []
		list.push(toResult(r))
		by.set(r.session_id, list)
	}
	return rows.map(
		(s): TradeSession => ({
			id: s.id,
			day: s.day,
			deposit: s.deposit_minor,
			rate: s.rate_minor,
			status: s.status === "settled" ? "settled" : "open",
			pnl: s.pnl_minor ?? 0,
			returnUsdt: s.return_usdt_minor ?? 0,
			returnMad: s.return_mad_minor ?? 0,
			at: s.created_at,
			results: (by.get(s.id) ?? []).sort((a, b) => (a.game === b.game ? a.idx - b.idx : a.game === "btc" ? -1 : 1)),
		}),
	)
}

export async function startTrade(user: User): Promise<string | void> {
	const uid = user.id
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open trade first"
	const cost = toMad(DEPOSIT, user.usdt_rate)
	if (!cost) return "Set the USDT price in Settings first"
	const now = Date.now()
	const day = today()
	const sessionId = id()
	const purchaseId = id()
	await db.transaction(async (tx) => {
		await tx.create(purchases, {
			id: purchaseId,
			user_id: uid,
			name: `Deposit ${DEPOSIT / 100} USDT`,
			qty: 1,
			unit_minor: cost,
			total_minor: cost,
			day,
			created_at: now,
		})
		await tx.create(tradeSessions, {
			id: sessionId,
			user_id: uid,
			day,
			deposit_minor: DEPOSIT,
			rate_minor: user.usdt_rate,
			purchase_id: purchaseId,
			status: "open",
			pnl_minor: 0,
			return_usdt_minor: 0,
			return_mad_minor: 0,
			created_at: now,
		})
	})
}

async function settle(uid: string, s: { id: string; deposit_minor: number; rate_minor: number }, results: TradeResult[]) {
	const pnl = totalPnl(results)
	const back = backUsdt(s.deposit_minor, pnl)
	const mad = toMad(back, s.rate_minor)
	const now = Date.now()
	const incomeId = mad > 0 ? id() : ""
	await db.transaction(async (tx) => {
		if (mad > 0) {
			await tx.create(incomes, {
				id: incomeId,
				user_id: uid,
				amount_minor: mad,
				day: today(),
				created_at: now,
				meta: JSON.stringify({ trade: 1, name: "Trading", usdt_minor: back }),
				ext_key: `trade:${s.id}`,
			})
		}
		await tx.update(tradeSessions, s.id, {
			status: "settled",
			pnl_minor: pnl,
			return_usdt_minor: back,
			return_mad_minor: mad,
			income_id: incomeId,
			settled_at: now,
		})
	})
}

export async function setPredict(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const game: Game = f.get("game") === "pred" ? "pred" : "btc"
	const idx = Math.floor(Number(f.get("idx")))
	const max = game === "btc" ? BTC_ROUNDS : PRED_COUNT
	if (!Number.isInteger(idx) || idx < 1 || idx > max) return "Unknown predict"
	let asset = ""
	let tf = 0
	if (game === "btc") {
		const [a, t] = text(f.get("pick"), 8).split("-")
		const ok = PICKS.some(([pa, pt]) => pa === a && pt === Number(t))
		if (!ok) return "Pick BTC or ETH and 5 or 15 minutes"
		asset = a!
		tf = Number(t)
	}
	const rows = await resultsOf(uid, s.id)
	if (rows.some((r) => r.game === game && r.idx === idx)) return "That predict is already set"
	if (game === "btc") {
		if (btcDone(rows)) return "The up or down predicts are finished"
		if (btcOf(rows).some((r) => !isDone(r))) return "Wait for the result of the last predict first"
		if (idx !== btcOf(rows).length + 1) return "Do the predicts in order"
	}
	await db.create(tradeResults, { id: id(), user_id: uid, session_id: s.id, game, idx, won: 0, pnl_minor: 0, state: "set", asset, tf, created_at: Date.now() })
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const game: Game = f.get("game") === "pred" ? "pred" : "btc"
	const idx = Math.floor(Number(f.get("idx")))
	const outcome = text(f.get("outcome"), 4)
	if (outcome !== "win" && outcome !== "miss") return "Pick Win or Miss"
	const rows = await resultsOf(uid, s.id)
	const cur = rows.find((r) => r.game === game && r.idx === idx)
	if (!cur || isDone(cur)) return "Set this predict first"
	const won = outcome === "win"
	let pnl = 0
	if (won) {
		const amount = usdtMinor(f.get("pnl"))
		if (!amount) return "Enter the PnL in USDT"
		pnl = amount
	} else {
		pnl = -missAmount(game, rows)
	}
	await db.update(tradeResults, cur.id, { state: "done", won: won ? 1 : 0, pnl_minor: pnl })
	const next = rows.map((r): TradeResult => (r.id === cur.id ? { ...r, state: "done", won, pnl } : r))
	if (allDone(next)) await settle(uid, s, next)
}

export async function undoResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const r = await db.findOne(tradeResults, { where: { id: text(f.get("result_id"), 36), session_id: s.id, user_id: uid } })
	if (!r) return
	if (r.game === "btc") {
		const last = btcOf(await resultsOf(uid, s.id)).at(-1)
		if (last?.id !== r.id) return "Undo the latest predict first"
	}
	if (r.state === "set") await db.deleteMany(tradeResults, { where: { id: r.id, user_id: uid } })
	else await db.update(tradeResults, r.id, { state: "set", won: 0, pnl_minor: 0 })
}

export async function finishTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s) return "Trade not found"
	if (s.status !== "open") return "This trade is already settled"
	const rows = await resultsOf(uid, s.id)
	const done = doneOf(rows)
	if (!done.length) return "Add at least one result first"
	await db.deleteMany(tradeResults, { where: { session_id: s.id, user_id: uid, state: "set" } })
	await settle(uid, s, done)
}

export async function reopenTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } })
	if (!s || s.status !== "settled") return
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } })
	if (open) return "Finish your open trade first"
	const key = `trade:${s.id}`
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key = ${key}`)
		await tx.exec(
			sql`update trade_sessions set status = 'open', income_id = '', settled_at = null, pnl_minor = 0, return_usdt_minor = 0, return_mad_minor = 0 where id = ${s.id} and user_id = ${uid}`,
		)
	})
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/users.ts" << 'MT_EOF_7f3a9c'
import { db, oauthAccounts, passwords, userImages, users } from "../db/index.ts"
import { fakeVerify, hashPassword, verifyPassword } from "./crypto.ts"
import { id } from "./util.ts"

export type User = {
	id: string
	email: string
	name: string
	currency: string
	theme: string
	run_at: string
	week_start: string
	usd_rate_minor: number
	usdt_rate: number
}

const normEmail = (e: string) => e.trim().toLowerCase()
const toUser = (r: any): User => ({
	id: r.id,
	email: r.email,
	name: r.name,
	currency: r.currency || "MAD",
	theme: r.theme || "dark",
	run_at: r.run_at || "06:00",
	week_start: r.week_start || "Monday",
	usd_rate_minor: r.usd_rate_minor || 1000,
	usdt_rate: Number(r.usdt_rate_minor) > 0 ? Number(r.usdt_rate_minor) : 1100,
})

export async function getUserById(id: string): Promise<User | null> {
	const row = await db.find(users, id)
	return row ? toUser(row) : null
}

const newUserRow = (id: string, email: string, name: string, verified: number, now: number) => ({
	id,
	email,
	name: name || email.split("@")[0]!,
	email_verified: verified,
	currency: "MAD",
	theme: "dark",
	run_at: "06:00",
	week_start: "Monday",
	usdt_rate_minor: 1100,
	created_at: now,
	updated_at: now,
})

type SignUpResult = { ok: true; user: User } | { ok: false; error: string }

export async function signUpWithPassword(input: { name: string; email: string; password: string }): Promise<SignUpResult> {
	const email = normEmail(input.email)
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return { ok: false, error: "Enter a valid email." }
	if (input.password.length < 8) return { ok: false, error: "Password needs at least 8 characters." }
	if (input.password.length > 200) return { ok: false, error: "Password is too long." }
	if (await db.findOne(users, { where: { email } })) return { ok: false, error: "That email already has an account." }

	const hash = await hashPassword(input.password)
	const now = Date.now()
	const userId = id()
	const row = newUserRow(userId, email, input.name.trim().slice(0, 80), 0, now)

	try {
		await db.transaction(async (tx) => {
			await tx.create(users, row)
			await tx.create(passwords, { user_id: userId, hash, updated_at: now })
		})
	} catch {
		return { ok: false, error: "That email already has an account." }
	}
	return { ok: true, user: toUser(row) }
}

export async function signInWithPassword(emailRaw: string, password: string): Promise<User | null> {
	const user = await db.findOne(users, { where: { email: normEmail(emailRaw) } })
	const pw = user ? await db.findOne(passwords, { where: { user_id: user.id } }) : null
	if (!user || !pw) {
		await fakeVerify(password)
		return null
	}
	return (await verifyPassword(password, pw.hash)) ? toUser(user) : null
}

type GoogleProfile = { id?: string; email?: string | null; name?: string | null; picture?: string | null }

export async function upsertFromGoogle(account: { providerAccountId: string }, profile: GoogleProfile): Promise<User> {
	const link = await db.findOne(oauthAccounts, { where: { provider: "google", provider_account_id: account.providerAccountId } })
	if (link) {
		const existing = await db.find(users, link.user_id)
		if (existing) return toUser(existing)
	}

	const email = normEmail(profile.email ?? "")
	if (!email) throw new Error("Google did not return an email.")
	const now = Date.now()

	return db.transaction(async (tx) => {
		let user = await tx.findOne(users, { where: { email } })
		if (!user) {
			user = await tx.create(users, newUserRow(id(), email, profile.name?.trim() ?? "", 1, now), { returnRow: true })
		}
		await tx.create(oauthAccounts, {
			id: id(),
			user_id: user.id,
			provider: "google",
			provider_account_id: account.providerAccountId,
			created_at: now,
		})
		if (profile.picture) {
			const hasAvatar = await tx.findOne(userImages, { where: { user_id: user.id, kind: "avatar", is_active: 1 } })
			if (!hasAvatar) {
				await tx.create(userImages, {
					id: id(),
					user_id: user.id,
					kind: "avatar",
					source: "google",
					url: profile.picture,
					mime: "",
					size_bytes: 0,
					is_active: 1,
					created_at: now,
				})
			}
		}
		return toUser(user)
	})
}

export async function getActiveAvatar(userId: string): Promise<string | null> {
	const img = await db.findOne(userImages, {
		where: { user_id: userId, kind: "avatar", is_active: 1 },
		orderBy: ["created_at", "desc"],
	})
	return img?.url ?? null
}

export async function updateProfile(userId: string, input: { name: string; email: string }) {
	const email = normEmail(input.email)
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return "Enter a valid email."
	const clash = await db.findOne(users, { where: { email } })
	if (clash && clash.id !== userId) return "That email belongs to another account."
	await db.update(users, userId, {
		name: input.name.trim().slice(0, 80) || email.split("@")[0]!,
		email,
		updated_at: Date.now(),
	})
	return null
}

export async function updatePrefs(userId: string, input: { currency: string; run_at: string; week_start: string; usdt_rate_minor: number; usd_rate_minor: number }) {
	const runAt = input.run_at.trim()
	await db.update(users, userId, {
		currency: input.currency.trim().toUpperCase().slice(0, 8) || "MAD",
		run_at: /^([01]?\d|2[0-3]):[0-5]\d$/.test(runAt) ? runAt.padStart(5, "0") : "06:00",
		week_start: input.week_start.trim().slice(0, 16) || "Monday",
		...(input.usd_rate_minor > 0 && input.usd_rate_minor <= 100000000 ? { usd_rate_minor: input.usd_rate_minor } : {}),
		...(input.usdt_rate_minor > 0 && input.usdt_rate_minor <= 100000000 ? { usdt_rate_minor: input.usdt_rate_minor } : {}),
		updated_at: Date.now(),
	})
}

export async function setTheme(userId: string, theme: string) {
	if (theme !== "dark" && theme !== "light") return
	await db.update(users, userId, { theme, updated_at: Date.now() })
}
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/util.ts" << 'MT_EOF_7f3a9c'
export type Json = Record<string, number | string>

export const id = () => crypto.randomUUID()

export const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max)

export const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []))

export const parseJson = (s: string | null | undefined): Json => {
	try {
		const v = JSON.parse(s || "{}")
		return v && typeof v === "object" && !Array.isArray(v) ? (v as Json) : {}
	} catch {
		return {}
	}
}

export const extKey = (sourceId: string, day: string) => `${sourceId}:${day}`

export const isFixed = (type: string) => type === "job" || type === "fixed"
MT_EOF_7f3a9c
mkdir -p "app/lib"
cat > "app/lib/view.ts" << 'MT_EOF_7f3a9c'
import type { DebtView, Goal, GoalItem, Source, State } from "./data.ts"
import { isFixed } from "./util.ts"
import { fmt } from "./money.ts"

export const LANG = "English"

export function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0)
	const bought = s.buys.reduce((a, b) => a + b.total, 0)
	const bySource = new Map<string, number>()
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount)
	const earnedLine = [...bySource].map(([n, a]) => `${n} ${fmt(a)}`).join(" · ")
	const money = s.debts.filter((d) => d.kind === "money")
	const oweMoney = money.reduce((a, d) => a + d.owed, 0)
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0)
	const oweExtra = oweItems ? `+ ${oweItems} cig` : ""
	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0)
	const wishSaved = Math.min(Math.max(0, s.balance), wishTarget)
	const debtPaid = money.reduce((a, d) => a + d.paid, 0)
	const total = wishTarget + oweMoney + debtPaid
	const done = wishSaved + debtPaid
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0
	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) }
}

const covered = (s: State, g: Goal) => Math.min(Math.max(0, s.balance), g.target)
export const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round((covered(s, g) / g.target) * 100)) : 0)
const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target

export const goalLeft = (s: State, g: Goal) =>
	g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${s.user.currency} · ready` : `${fmt(g.target - covered(s, g))} to go`

export function goalStat(s: State) {
	const target = s.goals.reduce((a, g) => a + g.target, 0)
	const saved = Math.min(Math.max(0, s.balance), target)
	const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0
	return { target, pct, toGo: Math.max(0, target - saved) }
}

export const canAfford = (s: State, it: GoalItem) => s.balance >= it.price

export const debtPct = (d: DebtView) => (d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0)

export const peopleCount = (s: State) => new Set(s.debts.map((d) => d.person)).size

export const srcAmount = (x: Source) => (isFixed(x.type) ? Number(x.config.fixed_minor) || 0 : x.amount)
export const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id)

export const dayNet = (earned: number, bought: number) => `${earned - bought < 0 ? "−" : "+"}${fmt(Math.abs(earned - bought))}`
MT_EOF_7f3a9c
mkdir -p "app"
cat > "app/request.ts" << 'MT_EOF_7f3a9c'
import { completeAuth } from "remix/auth"
import { Auth } from "remix/middleware/auth"
import { Session } from "remix/session"
import type { User } from "./lib/users.ts"

export type Ctx = Parameters<typeof completeAuth>[0] & {
	get: (key: any) => any
	render: (node: unknown, init?: ResponseInit) => Response
}

export const go = (href: string) => new Response(null, { status: 303, headers: { Location: href } })

export const json = (data: unknown, status = 200) =>
	new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } })

export const userOf = (ctx: Ctx): User | null => {
	const a = ctx.get(Auth)
	return a?.ok ? (a.identity as User) : null
}

export const formOf = (ctx: Ctx) => (ctx.get(FormData) as FormData | null) ?? new FormData()

export const backTo = (f: FormData, fallback: string) => {
	const b = String(f.get("back") ?? "")
	return /^\/(?![/\\])/.test(b) ? b : fallback
}

export function takeError(ctx: Ctx) {
	const e = ctx.get(Session).get("error")
	return typeof e === "string" ? e : ""
}

export function fail(ctx: Ctx, to: string, message: string) {
	ctx.get(Session).flash("error", message)
	return go(to)
}

export function signInAs(ctx: Ctx, userId: string) {
	const session = completeAuth(ctx)
	session.set("auth", { userId })
}

export function signOut(ctx: Ctx) {
	const session = ctx.get(Session)
	session.unset("auth")
	session.regenerateId(true)
}
MT_EOF_7f3a9c
mkdir -p "app"
cat > "app/router.ts" << 'MT_EOF_7f3a9c'
import { asyncContext } from "remix/middleware/async-context"
import { formData } from "remix/middleware/form-data"
import { logger } from "remix/middleware/logger"
import { render } from "remix/middleware/render"
import { createMiddleware, createRouter, type MiddlewareContext } from "remix/router"
import { Session } from "remix/session"
import assetsController from "./controllers/assets.ts"
import authController from "./controllers/auth.tsx"
import commandsController from "./controllers/commands.ts"
import pagesController from "./controllers/pages.tsx"
import { authMiddleware, sessionMiddleware } from "./lib/auth.ts"
import { routes } from "./routes.ts"

const appMiddleware = createMiddleware(asyncContext(), render(), sessionMiddleware, formData(), authMiddleware)

type AppContext = MiddlewareContext<typeof appMiddleware>

declare module "remix" {
	interface RouterTypes {
		context: AppContext
	}
}

const clearStaleCookie = async (context: any, next: () => Promise<Response>) => {
	const res = await next()
	if (!/(^|;\s*)__session=/.test(context.request.headers.get("cookie") ?? "")) return res
	let empty = false
	try {
		empty = context.get(Session).size === 0
	} catch { }
	if (!empty) return res
	const headers = new Headers(res.headers)
	headers.append("Set-Cookie", `__session=; Path=/; Max-Age=0; HttpOnly; SameSite=Lax${import.meta.env.PROD ? "; Secure" : ""}`)
	return new Response(res.body, { status: res.status, statusText: res.statusText, headers })
}

export const router = createRouter<AppContext>({
	middleware: [...(import.meta.env.DEV ? [logger()] : []), ...appMiddleware, clearStaleCookie],
})

router.map(routes.pages, pagesController)
router.map(routes.auth, authController)
router.map(routes.commands, commandsController)
router.map(routes.assets, assetsController)
MT_EOF_7f3a9c
mkdir -p "app"
cat > "app/routes.ts" << 'MT_EOF_7f3a9c'
import { get, post, route } from "remix/routes"

export const routes = route({
	pages: {
		root: get("/"),
		home: get("/home"),
		debts: get("/debts"),
		notes: get("/notes"),
		goals: get("/goals"),
		pad: get("/pad"),
		trading: get("/trading"),
		income: get("/income"),
		plan: get("/plan"),
		history: get("/history"),
		profile: get("/profile"),
		profileEdit: get("/profile/edit"),
		settings: get("/settings"),
		exportCsv: get("/export.csv"),
	},

	auth: {
		login: get("/login"),
		signIn: post("/login"),
		signup: get("/signup"),
		signUp: post("/signup"),
		logout: post("/logout"),
		googleLogin: get("/login/google"),
		googleCallback: get("/auth/google/callback"),
		deleteAccount: post("/account/delete"),
	},

	commands: {
		buy: post("/buy"),
		deleteBuy: post("/buy/delete"),
		setBalance: post("/profile/balance"),
		historyIncome: post("/history/income"),
		addDebt: post("/debts"),
		payDebt: post("/debts/pay"),
		clearDebt: post("/debts/clear"),
		addNote: post("/notes"),
		deleteNote: post("/notes/delete"),
		addWish: post("/goals"),
		buyWish: post("/goals/buy"),
		deleteWish: post("/goals/delete"),
		editGoal: post("/goals/edit"),
		editGoalItem: post("/goals/item/edit"),
		addGoalItem: post("/goals/item"),
		deleteGoalItem: post("/goals/item/delete"),
		addSource: post("/income"),
		addIncome: post("/income/add"),
		setHours: post("/income/hours"),
		addNamed: post("/income/named"),
		deleteIncome: post("/income/delete"),
		toggleSource: post("/income/toggle"),
		editSource: post("/income/edit"),
		deleteSource: post("/income/source/delete"),
		tradeDeposit: post("/trading/deposit"),
		tradeSet: post("/trading/set"),
		tradeResult: post("/trading/result"),
		tradeUndo: post("/trading/undo"),
		tradeFinish: post("/trading/finish"),
		tradeReopen: post("/trading/reopen"),
		saveProfile: post("/profile/edit"),
		saveSettings: post("/settings"),
		setTheme: post("/settings/theme"),
	},

	assets: {
		manifest: get("/manifest.webmanifest"),
		favicon: get("/favicon.svg"),
		faviconIco: get("/favicon.ico"),
		icon192: get("/icon-192.png"),
		icon512: get("/icon-512.png"),
		iconMaskable: get("/icon-maskable.png"),
		appleIcon: get("/apple-touch-icon.png"),
		sw: get("/sw.js"),
		robots: get("/robots.txt"),
		sitemap: get("/sitemap.xml"),
		css: get("/assets/app.css"),
		js: get("/assets/app.js"),
	},
})
MT_EOF_7f3a9c
mkdir -p "app"
cat > "app/screens.tsx" << 'MT_EOF_7f3a9c'
import { BuysDesktop, BuysExpand, Hero, TodayCards } from "./components/buys.tsx"
import { OweDesktop, OweMobile, RoadCard } from "./components/debts.tsx"
import { GoalsExpand } from "./components/goals.tsx"
import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"
import { HomeIncome, IncomeDesktop, IncomeExpand } from "./components/income.tsx"
import { AppLayout, AuthLayout } from "./components/layout.tsx"
import { ChatHead, Composer, NoteCard, NoteList } from "./components/notes.tsx"
import { BalanceCard, EditProfileMobile, ProfileMobile, SettingsDesktop, SettingsMobile } from "./components/profile.tsx"
import { TradingBody } from "./components/trading.tsx"
import { ErrorBanner, FloatField, GoogleMark, Logo, PageHeader, Section, view } from "./components/ui.tsx"
import type { State } from "./lib/data.ts"
import { fmt } from "./lib/money.ts"
import { calc } from "./lib/view.ts"

export const HomeScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Home"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="home"
		mobile={
			<>
				<ErrorBanner s={s} />
				<BalanceCard s={s} />
				<TodayCards s={s} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<Hero s={s} />
				<div class="g2">
					<div>
						<BuysDesktop s={s} />
					</div>
					<div>
						<OweDesktop s={s} open={false} storeKey="owe" />
						<IncomeDesktop s={s} title="Income today" />
						<NoteCard s={s} />
					</div>
				</div>
			</>
		}
	/>
))

export const DebtsScreen = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<AppLayout
			title="Debts"
			theme={s.user.theme}
			mobileTab="home"
			desktopTab="home"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={s.debts.map((d) => d.person).slice(0, 2).join(" + ")} />
					<RoadCard s={s} />
					<OweMobile s={s} open storeKey="owe-page" />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`} />
					<div class="g3">
						<div>
							<OweDesktop s={s} open storeKey="owe-page" />
						</div>
						<div>
							<Section title="How it works">
								<div class="rw">
									<span>+ left of a name</span>
									<span class="mu">adds to that person</span>
								</div>
								<div class="rw">
									<span>Pay</span>
									<span class="mu">counts as a buy today</span>
								</div>
								<div class="rw">
									<span>Paid to 0</span>
									<span class="mu">hidden, kept in history</span>
								</div>
								<div class="rw">
									<span>Type old name</span>
									<span class="mu">brings them back</span>
								</div>
							</Section>
						</div>
					</div>
				</>
			}
		/>
	)
})

export const GoalsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Goals"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="plan"
		mobile={
			<>
				<PageHeader title="Goals" right="add, edit, remove" />
				<ErrorBanner s={s} />
				<GoalsExpand s={s} open storeKey="goals-page" manage />
			</>
		}
		desktop={
			<>
				<ErrorBanner s={s} />
				<PageHeader title="Plan" right="goals + income" />
				<div class="g3">
					<div>
						<GoalsExpand s={s} open storeKey="goals-d" manage />
					</div>
					<div>
						<IncomeDesktop s={s} />
					</div>
				</div>
			</>
		}
	/>
))

export const HistoryScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="History"
		theme={s.user.theme}
		mobileTab="history"
		desktopTab="history"
		mobile={
			<>
				<PageHeader title="History" right="last 30 days" />
				<HistoryMobile s={s} />
			</>
		}
		desktop={<HistoryDesktop s={s} />}
	/>
))

export const IncomeScreen = view<{ s: State }>(({ s }) => {
	const earned = calc(s).earned
	return (
		<AppLayout
			title="Income"
			theme={s.user.theme}
			mobileTab="income"
			desktopTab="income"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Income" right={earned ? `+${fmt(earned)} today` : ""} />
					<IncomeExpand s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<div class="hd">
						<h1 class="t">Income</h1>
						<span></span>
					</div>
					<IncomeExpand s={s} />
				</>
			}
		/>
	)
})

export const NotesScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Notes"
		theme={s.user.theme}
		mobileTab="notes"
		desktopTab="notes"
		mobile={
			<>
				<ChatHead />
				<NoteList s={s} listKey="m" />
			</>
		}
		dock={<Composer s={s} listKey="m" />}
		desktop={
			<div class="chat" data-x>
				<ChatHead />
				<NoteList s={s} listKey="d" />
				<div style={{ margin: "30px 0 0" }}>
					<Composer s={s} listKey="d" />
				</div>
			</div>
		}
	/>
))

export const PadScreen = view<{ s: State }>(({ s }) => <AppLayout title="Pad" theme={s.user.theme} mobileTab="pad" desktopTab="pad" mobile={null} desktop={null} />)

export const ProfileScreen = view<{ s: State }>(({ s }) => (
	<AppLayout title="Profile" theme={s.user.theme} mobileTab="profile" desktopTab="settings" mobile={<ProfileMobile s={s} />} desktop={<SettingsDesktop s={s} />} />
))

export const ProfileEditScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Edit profile"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="Edit profile" back="/profile" />
				<EditProfileMobile s={s} />
			</>
		}
		desktop={<SettingsDesktop s={s} />}
	/>
))

export const SettingsScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Settings"
		theme={s.user.theme}
		mobileTab="profile"
		desktopTab="settings"
		mobile={
			<>
				<PageHeader title="Settings" back="/profile" />
				<SettingsMobile s={s} />
			</>
		}
		desktop={<SettingsDesktop s={s} />}
	/>
))

export const TradingScreen = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.user.usdt_rate)} ${s.user.currency}`
	return (
		<AppLayout
			title="Trading"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Trading" right={right} />
					<TradingBody s={s} />
				</>
			}
		/>
	)
})

const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-center-wrap">
		<div class="auth-glass-box">
			<div class="auth-logo-center">
				<Logo href="/login" />
			</div>
			<h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1>
			<div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>
			<form class="au" method="post" action={up ? "/signup" : "/login"}>
				<a class="gbtn" href="/login/google">
					<GoogleMark />
					<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
				</a>
				<div class="or">or</div>
				{error ? (
					<div class="auth-err-banner" role="alert">
						{error}
					</div>
				) : null}
				{up ? <FloatField label="Name" name="name" auto="name" /> : null}
				<FloatField label="Email" type="email" name="email" auto="email" />
				<FloatField label="Password" type="password" name="password" auto={up ? "new-password" : "current-password"} />
				<button class="btn full">{up ? "Create account" : "Sign in"}</button>
				<div class="auth-switch-wrap">
					<a class="lnk-switch" href={up ? "/login" : "/signup"}>
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
))

export const LoginScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker.">
		<AuthCard up={false} error={error} />
	</AuthLayout>
))

export const SignupScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals.">
		<AuthCard up error={error} />
	</AuthLayout>
))
MT_EOF_7f3a9c
mkdir -p "bootstrap"
cat > "bootstrap/worker.ts" << 'MT_EOF_7f3a9c'
import { missingEnv } from "../app/env.ts"

const page = (message: string, status: number) =>
	new Response(
		`<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Moneytracker</title><body style="font:16px system-ui;background:#111;color:#eee;display:grid;place-items:center;min-height:100vh;margin:0;padding:16px;text-align:center"><p>${message}</p>`,
		{ status, headers: { "Content-Type": "text/html; charset=utf-8" } },
	)

export default {
	async fetch(request: Request) {
		const missing = missingEnv()
		if (missing.length) return page(`Missing config: ${missing.join(", ")}`, 500)
		try {
			const { router } = await import("../app/router.ts")
			return await router.fetch(request)
		} catch (e) {
			console.error(e)
			return page("Something went wrong. Please try again.", 500)
		}
	},
}
MT_EOF_7f3a9c
mkdir -p "database"
cat > "database/schema.sql" << 'MT_EOF_7f3a9c'
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE,
  name          TEXT NOT NULL DEFAULT '',
  email_verified INTEGER NOT NULL DEFAULT 0,
  currency      TEXT NOT NULL DEFAULT 'MAD',
  theme         TEXT NOT NULL DEFAULT 'dark',
  phone         TEXT NOT NULL DEFAULT '',
  bio           TEXT NOT NULL DEFAULT '',
  run_at        TEXT NOT NULL DEFAULT '06:00',
  week_start    TEXT NOT NULL DEFAULT 'Monday',
  bg_mode       TEXT NOT NULL DEFAULT 'auto',
  bg_url        TEXT NOT NULL DEFAULT '',
  usd_rate_minor INTEGER NOT NULL DEFAULT 1000,
  usdt_rate_minor INTEGER NOT NULL DEFAULT 1100,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS passwords (
  user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  hash          TEXT NOT NULL,
  updated_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  id            TEXT PRIMARY KEY,
  user_id       TEXT REFERENCES users(id) ON DELETE CASCADE,
  data          TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  expires_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user_idx    ON sessions(user_id);
CREATE INDEX IF NOT EXISTS sessions_expires_idx ON sessions(expires_at);

CREATE TABLE IF NOT EXISTS oauth_accounts (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider      TEXT NOT NULL,
  provider_account_id TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  UNIQUE (provider, provider_account_id)
);
CREATE INDEX IF NOT EXISTS oauth_user_idx ON oauth_accounts(user_id);

CREATE TABLE IF NOT EXISTS user_images (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL DEFAULT 'avatar',
  source        TEXT NOT NULL DEFAULT 'upload',
  url           TEXT NOT NULL,
  mime          TEXT,
  size_bytes    INTEGER,
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS user_images_user_idx ON user_images(user_id, kind, is_active);

CREATE TABLE IF NOT EXISTS quick_buys (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  icon          TEXT NOT NULL DEFAULT 'Tag',
  price_minor   INTEGER NOT NULL DEFAULT 0,
  sort          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS quick_buys_user_idx ON quick_buys(user_id, sort);

CREATE TABLE IF NOT EXISTS income_sources (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  mode          TEXT NOT NULL DEFAULT 'manual',
  amount_minor  INTEGER NOT NULL DEFAULT 0,
  every         TEXT,
  created_at    INTEGER NOT NULL,
  type          TEXT NOT NULL DEFAULT 'manual',
  config        TEXT NOT NULL DEFAULT '{}',
  currency      TEXT NOT NULL DEFAULT 'MAD',
  active        INTEGER NOT NULL DEFAULT 1,
  sort          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS income_sources_user_idx ON income_sources(user_id);

CREATE TABLE IF NOT EXISTS incomes (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_id     TEXT REFERENCES income_sources(id) ON DELETE SET NULL,
  amount_minor  INTEGER NOT NULL,
  day           TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  meta          TEXT NOT NULL DEFAULT '{}',
  ext_key       TEXT NOT NULL DEFAULT '',
  usd_minor     INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS incomes_day_idx ON incomes(user_id, day);

CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_uq ON incomes(user_id, ext_key) WHERE ext_key <> '';

CREATE TABLE IF NOT EXISTS purchases (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  qty           INTEGER NOT NULL DEFAULT 1,
  unit_minor    INTEGER NOT NULL,
  total_minor   INTEGER NOT NULL,
  day           TEXT NOT NULL,
  debt_id       TEXT,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS purchases_day_idx ON purchases(user_id, day);

CREATE TABLE IF NOT EXISTS people (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  UNIQUE (user_id, name)
);

CREATE TABLE IF NOT EXISTS debts (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  person_id     TEXT NOT NULL REFERENCES people(id),
  kind          TEXT NOT NULL DEFAULT 'money',
  item_name     TEXT,
  item_qty      INTEGER,
  amount_minor  INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS debts_user_idx ON debts(user_id, person_id);

CREATE TABLE IF NOT EXISTS debt_payments (
  id            TEXT PRIMARY KEY,
  debt_id       TEXT NOT NULL REFERENCES debts(id) ON DELETE CASCADE,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_minor  INTEGER NOT NULL,
  purchase_id   TEXT REFERENCES purchases(id) ON DELETE SET NULL,
  created_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS goals (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  target_minor  INTEGER NOT NULL DEFAULT 0,
  saved_minor   INTEGER NOT NULL DEFAULT 0,
  is_wish       INTEGER NOT NULL DEFAULT 0,
  done_at       INTEGER,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS goals_user_idx ON goals(user_id);

CREATE TABLE IF NOT EXISTS goal_items (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_id       TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  price_minor   INTEGER NOT NULL DEFAULT 0,
  done_at       INTEGER,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS goal_items_goal_idx ON goal_items(goal_id);
CREATE INDEX IF NOT EXISTS goal_items_user_idx ON goal_items(user_id);

CREATE TABLE IF NOT EXISTS notes (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body          TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS notes_user_idx ON notes(user_id, created_at);

CREATE TABLE IF NOT EXISTS trade_sessions (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  day           TEXT NOT NULL,
  deposit_minor INTEGER NOT NULL,
  rate_minor    INTEGER NOT NULL,
  purchase_id   TEXT,
  income_id     TEXT,
  status        TEXT NOT NULL DEFAULT 'open',
  pnl_minor     INTEGER NOT NULL DEFAULT 0,
  return_usdt_minor INTEGER NOT NULL DEFAULT 0,
  return_mad_minor  INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  settled_at    INTEGER
);
CREATE INDEX IF NOT EXISTS trade_sessions_user_idx ON trade_sessions(user_id, status, created_at);

CREATE TABLE IF NOT EXISTS trade_results (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id    TEXT NOT NULL REFERENCES trade_sessions(id) ON DELETE CASCADE,
  game          TEXT NOT NULL,
  idx           INTEGER NOT NULL,
  won           INTEGER NOT NULL,
  pnl_minor     INTEGER NOT NULL,
  state         TEXT NOT NULL DEFAULT 'done',
  asset         TEXT NOT NULL DEFAULT '',
  tf            INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  UNIQUE (session_id, game, idx)
);
CREATE INDEX IF NOT EXISTS trade_results_user_idx ON trade_results(user_id, created_at);
MT_EOF_7f3a9c
cat > "package.json" << 'MT_EOF_7f3a9c'
{
	"name": "moneytracker",
	"version": "1.0.0",
	"private": true,
	"type": "module",
	"scripts": {
		"dev": "vite dev",
		"build": "vite build",
		"deploy": "vite build && wrangler deploy",
		"typecheck": "tsc --noEmit",
		"db:migrate": "bun --env-file=.dev.vars scripts/migrate.ts"
	},
	"dependencies": {
		"@libsql/client": "^0.15.0",
		"@remix-kbn/data-table-sqlite-turso": "npm:@jsr/remix-kbn__data-table-sqlite-turso@^0.6.0",
		"remix": "3.0.0"
	},
	"devDependencies": {
		"@cloudflare/vite-plugin": "^1.63.1",
		"@types/node": "^26.4.0",
		"typescript": "^6.0.3",
		"vite": "^8.3.4",
		"wrangler": "^4.149.0"
	}
}
MT_EOF_7f3a9c
mkdir -p "scripts"
cat > "scripts/migrate.ts" << 'MT_EOF_7f3a9c'
import { createClient } from "@libsql/client"
import { readFileSync } from "node:fs"

const url = process.env.TURSO_DATABASE_URL
const authToken = process.env.TURSO_AUTH_TOKEN
if (!url) throw new Error("TURSO_DATABASE_URL is not set (put it in .dev.vars)")

const client = createClient({ url, authToken })
const schema = readFileSync(new URL("../database/schema.sql", import.meta.url), "utf8")

await client.executeMultiple(schema)

const addColumns = [
	"ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE users ADD COLUMN run_at TEXT NOT NULL DEFAULT '06:00'",
	"ALTER TABLE users ADD COLUMN week_start TEXT NOT NULL DEFAULT 'Monday'",
	"ALTER TABLE users ADD COLUMN bg_mode TEXT NOT NULL DEFAULT 'auto'",
	"ALTER TABLE users ADD COLUMN bg_url TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE users ADD COLUMN usdt_rate_minor INTEGER NOT NULL DEFAULT 1100",
	"ALTER TABLE income_sources ADD COLUMN type TEXT NOT NULL DEFAULT 'manual'",
	"ALTER TABLE income_sources ADD COLUMN config TEXT NOT NULL DEFAULT '{}'",
	"ALTER TABLE income_sources ADD COLUMN currency TEXT NOT NULL DEFAULT 'MAD'",
	"ALTER TABLE income_sources ADD COLUMN active INTEGER NOT NULL DEFAULT 1",
	"ALTER TABLE income_sources ADD COLUMN sort INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE incomes ADD COLUMN meta TEXT NOT NULL DEFAULT '{}'",
	"ALTER TABLE incomes ADD COLUMN ext_key TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE incomes ADD COLUMN usd_minor INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE users ADD COLUMN usd_rate_minor INTEGER NOT NULL DEFAULT 1000",
	"ALTER TABLE trade_results ADD COLUMN state TEXT NOT NULL DEFAULT 'done'",
	"ALTER TABLE trade_results ADD COLUMN asset TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE trade_results ADD COLUMN tf INTEGER NOT NULL DEFAULT 0",
]
for (const statement of addColumns) {
	try {
		await client.execute(statement)
		console.log("added:", statement)
	} catch (err) {
		if (!/duplicate column/i.test(String(err))) throw err
	}
}

await client.execute("CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_key_idx ON incomes(ext_key) WHERE ext_key <> ''")
await client.execute("INSERT INTO goal_items (id, user_id, goal_id, name, price_minor, done_at, created_at) SELECT lower(hex(randomblob(16))), user_id, id, title, target_minor, NULL, created_at FROM goals g WHERE target_minor > 0 AND NOT EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = g.id)")
await client.execute("UPDATE goals SET target_minor = 0 WHERE target_minor > 0 AND EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = goals.id)")

const { rows } = await client.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
console.log("tables:", rows.map((r) => r.name).join(", "))
client.close()
MT_EOF_7f3a9c
cat > "tsconfig.json" << 'MT_EOF_7f3a9c'
{
	"include": ["app", "bootstrap", "scripts", "vite.config.ts"],
	"compilerOptions": {
		"target": "ES2022",
		"lib": ["ES2022", "DOM", "DOM.Iterable"],
		"module": "ESNext",
		"moduleResolution": "bundler",
		"jsx": "react-jsx",
		"jsxImportSource": "remix/component",
		"strict": true,
		"noUncheckedIndexedAccess": true,
		"isolatedModules": true,
		"verbatimModuleSyntax": true,
		"skipLibCheck": true,
		"noEmit": true,
		"allowImportingTsExtensions": true,
		"types": ["vite/client", "node"]
	}
}
MT_EOF_7f3a9c
cat > "vite.config.ts" << 'MT_EOF_7f3a9c'
import { cloudflare } from "@cloudflare/vite-plugin"
import { defineConfig } from "vite"

export default defineConfig({
	server: { host: "0.0.0.0", port: 3000, allowedHosts: true },
	oxc: { jsx: { runtime: "automatic", importSource: "remix/component" } },
	plugins: [cloudflare()],
})
MT_EOF_7f3a9c
echo "Done. Now: npm install && npm run typecheck && npm run dev"
