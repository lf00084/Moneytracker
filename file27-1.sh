#!/bin/bash
set -e
rm -f app/components/notes.tsx
mkdir -p app/client
cat > app/client/app.css <<'MT_EOF'
:root:root:root{--pico-font-family:var(--font-sys);--pico-font-size:100%;--pico-line-height:1.45;--pico-background-color:var(--bg);--pico-color:var(--ink);--pico-muted-color:var(--mu);--pico-muted-border-color:var(--ln);--pico-primary:var(--ac);--pico-primary-background:var(--ac);--pico-primary-border:var(--ac);--pico-primary-hover:var(--ac);--pico-primary-hover-background:var(--ac);--pico-primary-hover-border:var(--ac);--pico-primary-focus:var(--acs);--pico-primary-inverse:var(--on);--pico-border-radius:12px;--pico-border-width:1px;--pico-outline-width:3px;--pico-block-spacing-vertical:0px;--pico-block-spacing-horizontal:0px;--pico-form-element-background-color:var(--s1);--pico-form-element-border-color:var(--ln);--pico-form-element-color:var(--ink);--pico-form-element-placeholder-color:var(--mu);--pico-form-element-active-background-color:var(--s1);--pico-form-element-active-border-color:var(--ac);--pico-form-element-focus-color:var(--ac);--pico-form-element-disabled-background-color:var(--s2);--pico-form-element-spacing-vertical:.8rem;--pico-form-element-spacing-horizontal:1rem;--pico-form-element-invalid-border-color:var(--neg);--pico-form-element-invalid-active-border-color:var(--neg);--pico-form-element-invalid-focus-color:var(--neg)}
html input:not([type=checkbox]):not([type=radio]):not([type=hidden]),html select,html textarea,form,h1,h2,h3{margin:0}
button:not(:focus-visible):focus{box-shadow:none}
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label{-webkit-touch-callout:none;touch-action:manipulation}
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
.bt{display:flex;align-items:stretch;justify-content:space-around;height:50px;padding:0 6px env(safe-area-inset-bottom,0px);box-sizing:content-box;background:var(--bg);background:color-mix(in srgb,var(--bg) 84%,transparent);-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px);border-top:1px solid var(--ln)}
.bt a{flex:1 1 0;min-width:0;max-width:72px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;color:var(--mu);text-decoration:none}
.bt .bp{display:flex;align-items:center;justify-content:center;width:38px;height:22px;border-radius:11px;transition:background .15s}
.bt svg.ic{width:18px;height:18px;stroke-width:1.9}
.bt .bl{font-size:10px;line-height:1;font-weight:500}
.bt a.on{color:var(--ac)}
.bt a.on .bp{background:var(--acs)}
.bt a.on .bl{font-weight:600}
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
.av{width:72px;height:72px;border-radius:50%;background:var(--acs);color:var(--ac);border:1px solid var(--acl);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
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
.xo{padding:0;border:0;background:none}
.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
main{transition:opacity .2s ease}
html[data-nav=busy],html[data-nav=busy] a,html[data-nav=busy] button{cursor:progress}
html[data-nav=busy] main{opacity:.55}
button[data-busy]{cursor:progress}
.btn[data-busy]{opacity:.7}
.sb-l{display:contents}
.sb-i{position:absolute;inset:0;display:none;align-items:center;justify-content:center;pointer-events:none}
button[data-busy]{position:relative}
button[data-busy] .sb-l{visibility:hidden}
button[data-busy] .sb-i{display:flex}
button[data-busy] .sb-i svg.ic{width:18px;height:18px;transform:none;animation:spin .7s linear infinite}
button[data-lock]{opacity:.5}
@keyframes spin{to{transform:rotate(360deg)}}
@media(prefers-reduced-motion:reduce){
	main{transition:none}
	button[data-busy] .sb-i svg.ic{animation:none}
}
.trd{max-width:640px;margin:0 auto}
.tbn{margin:2px 0 6px;line-height:1.5}
.tbr{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px 0;border-bottom:1px solid var(--ln)}
.tbr:last-child{border-bottom:0;padding-bottom:0}
.tbr.lock{opacity:.45}
.tbf{display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0}
.tbf .in{width:96px;flex:0 1 96px;min-width:0;padding:8px 10px;font-size:14px;border-radius:12px}
.tbr:has(.tbp){flex-wrap:wrap}
.tbp{flex:1 1 100%;flex-wrap:wrap;justify-content:flex-start;margin-top:2px}
.tbp .in{flex:1 1 100%;width:100%;padding:10px 12px}
.tst{display:flex;align-items:center;gap:14px;padding:16px 18px;border-radius:22px;border:1px solid var(--ln);margin-bottom:12px}
.tst b{display:block;font-size:26px;font-weight:700;letter-spacing:-.03em;line-height:1.1}
.tst .lb{margin-top:4px}
.tsi{flex:none;width:48px;height:48px;border-radius:50%;display:flex;align-items:center;justify-content:center;border:2px solid currentColor}
.tsi svg.ic{width:26px;height:26px;stroke-width:2.6}
.tst.ok{color:var(--pos);background:rgba(76,195,138,.1);border-color:rgba(76,195,138,.4)}
.tst.no{color:var(--neg);background:rgba(255,90,77,.1);border-color:rgba(255,90,77,.4)}
.tst.no .tsi svg.ic{transform:rotate(45deg)}
.tst .lb{color:var(--ink);opacity:.75}
.btn.win{background:rgba(76,195,138,.14);color:var(--pos);border-color:rgba(76,195,138,.45)}
.tbs{font-size:11px;font-weight:600;border:1px solid currentColor;border-radius:12px;padding:2px 9px;font-family:var(--mono)}
.sw{border-bottom:1px solid var(--ln)}
.sw:last-child{border:0}
.sw>.rw{border:0}
.hx{margin:0 0 12px;border:1px solid var(--ln);background:var(--bg);border-radius:14px;overflow:hidden}
.hx>summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:9px 12px;list-style:none;cursor:pointer;font-size:12px;color:var(--mu);font-family:var(--mono)}
.hx>summary::-webkit-details-marker{display:none}
.hx>summary>span:nth-child(2){margin-left:auto;color:var(--earn)}
.hx>summary .chev{position:static;margin:0;right:auto;top:auto;flex:none}
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
.of{position:relative;margin-top:14px}
.of input{height:56px;padding:22px 16px 6px;border-radius:12px;font-size:16px}
.of label{position:absolute;left:17px;top:19px;margin:0;color:var(--mu);font-size:16px;line-height:1;pointer-events:none;transition:top .15s,font-size .15s,color .15s}
.of input::placeholder{color:transparent}
.of input:focus+label,.of input:not(:placeholder-shown)+label,.of input:-webkit-autofill+label{top:9px;font-size:11px;font-weight:600;color:var(--ac)}

/* file15 */
.rt b small{font-size:11px;color:var(--mu);font-weight:400;letter-spacing:0;margin-left:3px}
.xbare .xb{border-top:0;padding:8px 16px 6px}
.addrow{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:11px 14px;border:1px dashed var(--acl);border-radius:var(--rm);background:var(--acs);color:var(--ac);font-weight:600;font-size:13px}
.addrow svg.ic{width:18px;height:18px;stroke-width:2;transition:transform .18s ease}
.addrow.on svg.ic{transform:rotate(45deg)}
.incbare{padding:6px 22px 18px}
.incbare .addrow{margin-top:12px}
details[data-fixed]>.xh{cursor:default;padding-right:70px}
.dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}
.mm>.cd .big2{font-size:24px}
.mm .xbare .xb{padding:2px 14px}
.hr{display:grid;grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;align-items:center;padding:9px 0}
.hn{min-width:0;font-size:15px}
.hr .ea{white-space:nowrap;text-align:right;font-size:15px}
.hr .ub{width:32px;height:32px;border-radius:12px;background:var(--s2)}
.hr .btn.xs{min-height:34px;min-width:96px;font-size:14px;white-space:nowrap}
.hspan{grid-column:2/4;justify-self:end}
.sw .ad{margin:0 0 10px}
.hx{margin:0 0 8px;border:0;background:var(--s2);border-radius:14px}
.hx>summary{min-height:38px;padding:5px 6px 5px 12px;justify-content:flex-start;gap:10px}
.hx>summary>span:nth-child(2){margin-left:0;color:var(--mu)}
.hx>summary .chev{margin-left:auto;width:28px;height:28px;border-radius:50%;background:var(--s1);align-items:center;justify-content:center}

.pdtabs{margin:8px 0 4px;flex-wrap:nowrap;overflow-x:auto;scrollbar-width:none}
.pdtabs::-webkit-scrollbar{display:none}
.pdtabs .chip{flex:none;white-space:nowrap}
.pdx{margin-top:12px}
.pdf{display:flex;flex-wrap:wrap;gap:8px;margin:0 0 14px}
.pdi{flex:1 1 140px;min-width:0;width:100%;font-size:15px;font-family:inherit;background:var(--s1);color:var(--ink);border:1px solid var(--ln);border-radius:14px;padding:10px 14px;margin:0;resize:none;outline:0}
.pdi:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
textarea.pdi{flex-basis:100%}
.pdf .btn.xs{margin-left:auto}
.pdc{display:flex;justify-content:space-between;align-items:center;gap:12px;padding:14px 16px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdc>span:first-child{display:flex;flex-direction:column;gap:2px;min-width:0}
.pdc b{font-weight:600;letter-spacing:-.01em;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.pdn{padding:12px 14px;margin-bottom:8px;background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
.pdt{white-space:pre-wrap;word-break:break-word}
.pdm{display:flex;justify-content:space-between;align-items:center;gap:8px;margin-top:8px;flex-wrap:wrap}
.pda{display:flex;gap:6px}
.pda .chip{padding:3px 10px;font-size:11px}
.pdhd{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px}
.pdtt{font-size:20px;font-weight:700;letter-spacing:-.03em;margin:4px 0 2px}
.pde{padding:14px 2px}
.pdhome .pdf{margin:12px 0}
.pdhome .pdn{background:var(--s2);box-shadow:none}

.nt-ttl{font-size:18px;font-weight:700;letter-spacing:-.02em}
.nt-page{display:flex;flex-direction:column;gap:10px;padding:2px 0 14px}
.nt-c{background:var(--s1);border:1px solid var(--ln);border-radius:22px}
.nt-m{font-family:var(--mono);font-size:12px;color:var(--mu)}
.nt-spread{display:flex;justify-content:space-between;align-items:baseline}
.nt-seg{display:flex;background:var(--s2);border-radius:14px;padding:3px;gap:2px}
.nt-seg a{flex:1;text-align:center;padding:7px 0;border-radius:11px;font-size:14px;font-weight:600;color:var(--mu)}
.nt-seg a.on{background:var(--s1);color:var(--ink);box-shadow:0 1px 2px rgba(0,0,0,.1)}
.nt-pj{display:flex;gap:8px;overflow:hidden}
.nt-pc{flex:none;padding:7px 12px;border-radius:18px;border:1px solid var(--ln);background:var(--s1);font-size:14px;font-weight:600;color:var(--ink);display:flex;gap:6px;align-items:center}
.nt-pc small{font:12px var(--mono);color:var(--mu)}
.nt-pc.on{background:var(--acs);border-color:var(--acl);color:var(--ac)}
.nt-ph{padding:12px 14px}
.nt-ph b{font-size:18px}
.nt-bar2{height:5px;background:var(--s2);border-radius:3px;margin-top:9px}
.nt-bar2 i{display:block;height:5px;width:67%;background:var(--ac);border-radius:3px}
.nt-fl{display:flex;gap:6px;padding:0 2px}
.nt-fl span{font:12px var(--mono);padding:5px 11px;border-radius:12px;background:var(--s2);color:var(--mu)}
.nt-fl .on{background:var(--ink);color:var(--bg)}
.nt-list{overflow:hidden}
.nt-it{display:flex;gap:10px;align-items:flex-start;padding:11px 14px;border-top:1px solid var(--ln)}
.nt-it:first-child{border-top:0}
.nt-ck{flex:none;width:22px;height:22px;border-radius:50%;border:2px solid var(--mu);margin-top:1px;display:flex;align-items:center;justify-content:center;color:var(--on)}
.nt-ck.d{background:var(--ac);border-color:var(--ac)}
.nt-ck svg.ic{width:16px;height:16px;stroke-width:2.4}
.nt-it p{margin:0;font-size:15px;line-height:1.35}
.nt-it.dn p{color:var(--mu);text-decoration:line-through}
.nt-it.nt{border-left:3px solid var(--ac);background:var(--acs)}
.nt-it.nt p{font-size:14px}
.nt-it .nt-m{margin-top:3px}
.nt-gl{font:12px var(--mono);color:var(--mu);padding:2px 4px 0}
.nt-q{padding:13px 14px;border-top:1px solid var(--ln)}
.nt-q:first-child{border-top:0}
.nt-q p{margin:0 0 10px;font-size:15px;line-height:1.4}
.nt-who{display:flex;align-items:center;gap:10px}
.nt-av{width:30px;height:30px;border-radius:50%;background:var(--acs);color:var(--ac);font-weight:700;font-size:13px;display:flex;align-items:center;justify-content:center}
.nt-who b{font-size:14px;display:block}
.nt-who .nt-tag{margin-left:auto}
.nt-tag{font:11px var(--mono);padding:2px 8px;border-radius:8px;background:var(--s2);color:var(--mu)}
.nt-tag.t{background:var(--acs);color:var(--ac)}
.nt-cmp{flex:none;padding:8px 12px 10px;background:var(--bg)}
.nt-cin{display:flex;align-items:center;gap:8px;padding:6px 6px 6px 14px}
.nt-cin input{flex:1;border:0;background:none;font:inherit;font-size:15px;height:38px;min-width:0;color:var(--ink);outline:0;box-shadow:none;padding:0}
.nt-tg2{display:flex;background:var(--s2);border-radius:12px;padding:2px}
.nt-tg2 span{padding:5px 10px;border-radius:10px;font-size:12px;font-weight:600;color:var(--mu)}
.nt-tg2 .on{background:var(--s1);color:var(--ac)}
.nt-sd{width:38px;height:38px;border-radius:50%;background:var(--ac);color:var(--on);border:0;display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.nt-sd svg.ic{width:18px;height:18px;stroke-width:2}
.nt-ov{position:fixed;inset:0;background:rgba(17,24,39,.42);z-index:40}
.nt-sht{position:fixed;left:50%;transform:translateX(-50%);width:100%;max-width:560px;bottom:0;background:var(--s1);border-radius:26px 26px 0 0;padding:10px 16px calc(16px + env(safe-area-inset-bottom,0px));display:flex;flex-direction:column;gap:10px;box-shadow:0 -8px 24px rgba(0,0,0,.15);z-index:41}
.nt-gr{width:40px;height:4px;border-radius:2px;background:var(--ln);align-self:center}
.nt-shh{display:flex;justify-content:space-between;align-items:center}
.nt-shh b{font-size:18px}
.nt-fi{background:var(--bg);border-radius:14px;padding:8px 12px}
.nt-fi .nt-m{display:block;font-size:11px}
.nt-fi b{font-size:16px;font-weight:600}
.nt-cl{display:flex;gap:12px;align-items:center}
.nt-cl i{width:26px;height:26px;border-radius:50%}
.nt-cl i.on{outline:2px solid var(--ink);outline-offset:2px}
.nt-op{display:flex;gap:12px;align-items:center;padding:9px 12px;border:1px solid var(--ln);border-radius:16px}
.nt-op.on{border-color:var(--ac);background:var(--acs)}
.nt-op b{font-size:15px;display:block}
.nt-op span.d{font-size:12px;color:var(--mu)}
.nt-rd{width:20px;height:20px;border-radius:50%;border:2px solid var(--mu);margin-left:auto;flex:none}
.nt-op.on .nt-rd{border:6px solid var(--ac)}
.nt-pv{width:46px;height:36px;border-radius:10px;background:var(--s2);flex:none;display:flex;flex-direction:column;justify-content:center;gap:5px;padding:0 8px}
.nt-pr2{display:flex;align-items:center;gap:4px}
.nt-pr2 u{width:7px;height:7px;border-radius:50%;border:1.5px solid var(--mu);box-sizing:border-box;flex:none}
.nt-pr2 i{height:4px;flex:1;border-radius:2px;background:var(--mu)}
.nt-tr2{display:flex;justify-content:space-between;align-items:center;font-size:14px}
.nt-tgl{width:40px;height:24px;border-radius:12px;background:var(--ac);position:relative}
.nt-tgl::after{content:"";position:absolute;right:3px;top:3px;width:18px;height:18px;border-radius:50%;background:var(--on)}
.nt-go{height:48px;border-radius:24px;background:var(--ac);color:var(--on);font-weight:700;font-size:16px;display:flex;align-items:center;justify-content:center}

/* file18: home (mobile) + bottom bar restyle */
html{--h-ink:var(--ink);--h-ink2:var(--ink);--h-mu:var(--mu);--h-ln:var(--ln);--h-ln2:var(--ln);--h-card:var(--s1);--h-chip:var(--s2);--h-chip2:var(--s2);--h-bar:var(--s2);--h-sub:var(--s2);--h-bg:var(--bg);--h-earn:var(--earn);--h-ac:var(--ac);--h-acs:var(--acs);--h-acl:var(--acl);--h-pur:var(--spend);--h-solid:var(--ac);--h-fill:var(--ac);--h-on:var(--on);--h-mono:'JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--h-sans:Inter,var(--font-sys)}
html[data-theme=light]{--h-ink:#1f2430;--h-ink2:#374151;--h-mu:#5f6672;--h-ln:#eceef1;--h-ln2:#e1e4e8;--h-card:#fff;--h-chip:#eceef1;--h-chip2:#f1f2f4;--h-bar:#e5e7eb;--h-sub:#f1f2f4;--h-bg:#f3f4f6;--h-earn:#8a5a00;--h-ac:#2f6f78;--h-acs:#d6f1f1;--h-acl:#a9dcdc;--h-pur:#6a4fd1;--h-solid:#3b727b;--h-fill:#2f6f78;--h-on:#fff;}

/* bottom bar (all pages) */

/* top row on home */
.app:has(.hm) .mm{padding-left:12px;padding-right:12px}

/* home base */
.hm{display:flex;flex-direction:column;gap:6px;padding-top:8px;font-family:var(--h-sans);color:var(--h-ink)}
.hm-c,.hm .xc{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none;margin:0}
.hm-m,.hm .tg0{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .tg0{font-weight:400}

/* balance */
.hm-bal{display:grid;grid-template-columns:1fr auto;grid-template-areas:"l b" "v b";align-items:center;height:44px;padding:4px 6px 4px 14px;column-gap:10px}
.hm-bal .hm-m{grid-area:l;font-size:11px;line-height:1.1}
.hm-bal .hm-dots{grid-area:v}
.hm-bal .ib{grid-area:b;align-self:center;justify-self:end;width:32px;height:32px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);box-shadow:none}
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
.hm .hr{grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;min-height:44px;padding:4px 0}
.hm .hn{font-size:15px;font-weight:500}
.hm .hn .lb,.hm .by .lb{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .hr .ea,.hm .by .ea{color:var(--h-earn)!important;font-weight:600;font-size:15px;white-space:nowrap;text-align:right}
.hm .hr .ea small,.hm .by .ea small{font-size:12px;font-weight:500;color:inherit;margin-left:3px}
.hm .ub{width:30px;height:30px;border-radius:50%;border:0;background:var(--h-chip2);color:var(--h-mu);box-shadow:none}
.hm .hr .ub{justify-self:end;align-self:center}
.hm .ub svg.ic{width:16px;height:16px;stroke-width:1.6}
.hm .by{border-bottom:0;border-top:1px solid var(--h-ln);min-height:44px;padding:4px 0}
.hm .by:first-child{border-top:0}
.hm .btn.xs{height:36px;min-height:36px;padding:0 18px;border-radius:18px;font:600 15px/1 var(--h-sans);letter-spacing:0;box-shadow:none}
.hm .btn.xs.o{border:1px solid var(--h-acl);background:var(--h-card);color:var(--h-ac)}
.hm .btn.xs.o:hover{background:var(--h-acs);filter:none}
.hm .btn.xs:not(.o){background:var(--h-fill);border:1px solid var(--h-fill);color:var(--h-on)}
.hm .hr .btn.xs,.hm .btn.xs.hadd{height:34px;min-height:34px;min-width:96px;padding:0 14px;border-radius:17px;font:600 14px/1 var(--h-sans);align-self:center;justify-self:end;white-space:nowrap}
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

/* file19: pad + other pages */
.hm{display:block;gap:0;padding-top:0}
.hm-f{display:flex;flex-direction:column;gap:6px;padding-top:8px}
.mm.hm{padding-top:8px}
.hm .cd,.hm .sc,.hm .hero{background:var(--h-card);border:1px solid var(--h-ln);border-radius:22px;box-shadow:none}
.hm .cd{margin-top:8px}
.hm .tg{font:400 12px/1.3 var(--h-mono);color:var(--h-mu)}
.hm .lb,.hm .mu.sm{font-family:var(--h-mono)}
.hm .rw,.hm .by,.hm .db{border-color:var(--h-ln)}
.hm .big{font-size:34px;font-weight:700;letter-spacing:0}
.hm .big2{font-weight:700;letter-spacing:0}
.hm .hd{margin:10px 4px 2px}
.hm .hd h1.t{font-size:18px;font-weight:700;letter-spacing:0}
.hm .btn{background:var(--h-fill);border-color:var(--h-fill);color:var(--h-on);box-shadow:none;font-family:var(--h-sans)}
.hm .btn.o{background:var(--h-card);border-color:var(--h-acl);color:var(--h-ac)}
.hm .btn.full{border-radius:24px;min-height:48px;font-size:16px}
.hm .btn.off,.hm .btn:disabled{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .in,.hm .of input{background:var(--h-card);border:1px solid var(--h-ln2);border-radius:14px;color:var(--h-ink)}
.hm .chip{background:var(--h-chip);border-color:var(--h-ln);color:var(--h-mu)}
.hm .chip.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .av{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.hm .sg{background:var(--h-chip);border-color:var(--h-ln)}
.hm .li:hover{background:var(--h-chip)}
.hm .mt{background:var(--h-bar)}
.hm .mt i{background:var(--h-mu)}
.hm .mt.n i{background:var(--h-pur)}
.hm .pos{color:var(--pos)!important}
.hm .nt-page{padding-top:0}

/* pad */
.nt-c{background:var(--h-card);border-color:var(--h-ln)}
.nt-m{font-family:var(--h-mono);color:var(--h-mu)}
.nt-f{display:contents}
.nt-b{flex:1;min-width:0}
.nt-it{align-items:flex-start}
button.nt-ck{background:none;padding:0;cursor:pointer;color:var(--h-on);flex:none}
button.nt-ck.d{background:var(--h-ac);border-color:var(--h-ac)}
.nt-x{flex:none;width:26px;height:26px;border-radius:50%;border:0;background:none;color:var(--h-mu);padding:0;display:flex;align-items:center;justify-content:center;opacity:.75}
.nt-x svg.ic{width:16px;height:16px;transform:rotate(45deg)}
.nt-em{padding:16px 14px}
.nt-pj{overflow-x:auto;scrollbar-width:none}
.nt-pj::-webkit-scrollbar{display:none}
.nt-pc{text-decoration:none;white-space:nowrap}
.nt-dot{width:8px;height:8px;border-radius:50%;flex:none}
.nt-pc.on{background:var(--h-acs);border-color:var(--h-acl);color:var(--h-ac)}
.nt-fl a{font:12px var(--h-mono);padding:5px 11px;border-radius:12px;background:var(--h-chip);color:var(--h-mu)}
.nt-fl a.on{background:var(--h-ink);color:var(--h-card)}
.nt-bar2{background:var(--h-bar)}
.nt-bar2 i{background:var(--h-ac)}
.nt-del{text-align:center;margin:2px 0 6px}
.nt-del button{background:none;border:0;padding:6px;color:var(--h-mu);font-size:12px;text-decoration:underline;width:auto}
.nt-who .nt-tag{margin-left:auto}
.nt-cin .nt-who-i{flex:0 0 76px;width:76px;border-right:1px solid var(--h-ln);padding-right:8px;border-radius:0}
.nt-cin input{background:none;border:0;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-tg2{position:relative;background:var(--h-chip)}
.nt-tg2 label{display:flex;margin:0}
.nt-tg2 input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-tg2 input:checked+span{background:var(--h-card);color:var(--h-ac)}
.nt-tg2 span{cursor:pointer}
.nt-sd{background:var(--h-fill);color:var(--h-on)}
.nt-sel{width:100%;margin:6px 0 0;padding:6px 12px;height:34px;border-radius:14px;border:1px solid var(--h-ln2);background:var(--h-card);color:var(--h-mu);font-size:13px}
.nt-cmp{background:var(--bg)}
.nt-sht{max-height:92dvh;overflow:auto;background:var(--h-card)}
.nt-fi{display:block;background:var(--h-bg);margin:0}
.nt-fi input{display:block;width:100%;height:auto;border:0;background:none;padding:0;margin:0;font-size:16px;font-weight:600;box-shadow:none;color:var(--h-ink);border-radius:0}
.nt-cl label{position:relative;display:block;margin:0;cursor:pointer}
.nt-cl input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-cl input:checked+i{outline:2px solid var(--h-ink);outline-offset:2px}
.nt-op{position:relative;cursor:pointer;margin:0}
.nt-op input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.nt-op:has(input:checked){border-color:var(--h-ac);background:var(--h-acs)}
.nt-op:has(input:checked) .nt-rd{border:6px solid var(--h-ac)}
.nt-tr2{margin:0;cursor:pointer}
input.nt-tgl[type=checkbox],input.nt-tgl[type=checkbox]:checked{-webkit-appearance:none;appearance:none;background-image:none;width:40px;height:24px;border-radius:12px;border:0;padding:0;margin:0;position:relative;background-color:var(--h-chip);flex:none}
input.nt-tgl[type=checkbox]:checked{background-color:var(--h-ac)}
input.nt-tgl[type=checkbox]::after{content:"";position:absolute;left:3px;right:auto;top:3px;width:18px;height:18px;border-radius:50%;background:var(--h-card);transition:left .15s}
input.nt-tgl[type=checkbox]:checked::after{left:19px}
.nt-go{border:0;width:100%;background:var(--h-fill);color:var(--h-on);text-decoration:none}

/* balance reveal + goals manage row */
.hm-bal{height:auto;min-height:48px;padding:8px 8px 8px 14px}
.hm-dots:has(small){font-size:18px;line-height:1.15;letter-spacing:0}
.hm-two .hm-c{flex:1 1 0}
.hm .gw .db{gap:10px}

/* file20: spacing, shadow, centered icons, invoice, pad edit */
.hm-f{gap:12px}
.hm-two{gap:10px}
.hm .cd{margin-top:12px}
.nt-page{gap:12px}
.hm-c,.hm .xc,.hm .cd,.hm .sc,.hm .hero,.nt-c{box-shadow:var(--sh1)}

/* header icons centered inside the summary */
.hm .xp{top:50%;margin-top:-19px;right:14px}
.hm .xc:has(details[data-fixed]) .xp{top:50%}
.hm .xc .chev{top:50%;margin-top:-11px}
.hm .xc:has(.xp.on) .chev{display:none}
.hm details[data-fixed]>.xh{padding:9px 70px 9px 16px}
.hm .xb:empty{display:none}
.hm .osum .ow .em{font:400 14px/1.4 var(--h-sans);color:var(--h-mu)}

/* balance card (home + profile) */
.hm-bal .hm-ba{display:flex;align-items:center;justify-content:flex-end;gap:8px}
.hm-bal .hm-ba .ib{grid-area:auto;align-self:center}
.hm-balc{padding:0;overflow:hidden}
.hm-bedit{padding:0 14px 14px}

/* exoclick invoice */
.inv{display:flex;align-items:center;gap:10px;padding:8px 8px 8px 14px;margin-bottom:12px}
.inv>div:first-child{flex:1;min-width:0}
.inv-a{font-size:20px;font-weight:700;line-height:1.2}
.inv-st{font:600 12px/1 var(--h-mono);padding:5px 10px;border-radius:12px;background:var(--h-chip);color:var(--h-mu);flex:none}
.inv-st.pending{background:rgba(166,106,0,.14);color:var(--h-earn)}
.inv-st.processing{background:rgba(109,79,214,.14);color:var(--h-pur)}
.inv-st.paid{background:rgba(18,161,80,.14);color:var(--pos)}
.inv .ub svg.ic{transform:rotate(45deg)}

/* pad: tap copies, long press edits */
.nt-b{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none;cursor:pointer}
.nt-it,.nt-q{flex-wrap:wrap}
.nt-q .nt-b p{margin:0 0 10px}
.nt-edit{flex:1 1 0;min-width:0;display:flex;flex-direction:column;gap:8px;margin:0}
.nt-edit textarea{width:100%;margin:0;padding:8px 12px;border:1px solid var(--h-ln2);border-radius:14px;background:var(--h-card);color:var(--h-ink);font:15px/1.35 var(--h-sans);resize:none}
.nt-eb{display:flex;gap:8px;justify-content:flex-end}
.nt-edit .nt-cin{padding:4px 6px 4px 14px}
.nt-xc{flex:none;width:30px;height:30px;border:0;background:none;color:var(--mu);padding:0;display:flex;align-items:center;justify-content:center;border-radius:50%}
.nt-xc svg.ic{width:18px;height:18px;transform:rotate(45deg)}
.nt-mn{position:relative;flex:none;align-self:flex-start}
.nt-mn[hidden],.nt-dd[hidden]{display:none!important}
.nt-mn .nt-x svg.ic{transform:none}
.nt-dd{position:absolute;right:0;top:calc(100% + 4px);z-index:40;min-width:150px;padding:4px;background:var(--s1);border:1px solid var(--ln);border-radius:14px;box-shadow:0 10px 28px rgba(0,0,0,.28)}
.nt-dd form{display:block;margin:0}
.nt-dd button{position:relative;display:flex;align-items:center;gap:10px;width:100%;padding:10px 12px;border:0;border-radius:10px;background:none;color:var(--ink);font:inherit;font-size:14px;text-align:left;cursor:pointer}
.nt-dd button:hover{background:var(--s2)}
.nt-dd button.dg{color:var(--neg)}
.nt-dd svg.ic{width:16px;height:16px;flex:none}
.nt-list:not(.nt-scr):has(.nt-dd:not([hidden])),.nt-q:has(.nt-dd:not([hidden])){overflow:visible}
.nt-dd.up{top:auto;bottom:calc(100% + 4px)}
.nt-toast{position:fixed;left:50%;bottom:96px;transform:translateX(-50%);background:var(--h-ink);color:var(--h-card);padding:8px 16px;border-radius:18px;font-size:13px;z-index:60}

/* balance icons: centered on the whole card (middle, right), not just the first row */
.hm-balc,.hm-c.hm-bal{position:relative}
.hm-bal{grid-template-columns:minmax(0,1fr);grid-template-areas:"l" "v";padding-right:58px}
.hm-balc .hm-bal{padding-right:104px}
.hm-bal .hm-ba{position:absolute;right:8px;top:50%;transform:translateY(-50%);z-index:2}
.hm-balc:has(.hm-bedit:not([hidden])) .hm-bedit{padding-right:104px}

/* pad: low project card with background progress, tighter spacing, scrolling notes */
.nt-page,.hm .nt-page{gap:6px;padding-bottom:8px}
.nt-ph.nt-pg{position:relative;overflow:hidden;display:flex;align-items:center;gap:10px;padding:0 6px 0 14px;min-height:42px}
.nt-pg>b{position:relative;z-index:1;font-size:16px;flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.nt-pg>.nt-m{position:relative;z-index:1;flex:none;white-space:nowrap}
.nt-pgf{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.nt-pgf.full{background:var(--ac);opacity:.32}
.nt-gs{position:relative;z-index:1;flex:none;width:34px;height:34px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:var(--mu);text-decoration:none}
.nt-gs svg.ic{width:18px;height:18px}
.nt-list.nt-scr{overflow-y:auto;max-height:calc(100dvh - 300px);min-height:150px;overscroll-behavior:contain;scrollbar-width:thin}
.nt-go.dg{background:rgba(255,90,77,.12);color:var(--neg);border:1px solid rgba(255,90,77,.35)}


.hm-two .hm-c.hm-bal{flex:1 1 0;min-width:0;min-height:48px;padding:8px 8px 8px 14px}
.hm-two .hm-dots{white-space:nowrap}
.hm-c.hm-pr{padding-right:14px;text-decoration:none;color:inherit}
.hm-pr .hm-dots{letter-spacing:0;font-size:16px}
.hm-pr .hm-dots.no{color:var(--h-mu)}

.pseg{display:flex;gap:4px;margin-top:6px}
.pseg b{height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:600;background:var(--s2);color:var(--mu);border:1px solid transparent;min-width:0}
.pseg b.on{background:var(--ac);color:var(--on)}
.pseg b.cur{background:var(--acs);color:var(--ac);border-color:var(--acl)}
.psl{display:flex;gap:4px;margin:4px 0 6px}
.psl span{text-align:center;font:400 11px/1.2 var(--mono);color:var(--mu);min-width:0}
.pbt{display:flex;gap:6px;margin:6px 0}
.pbt .btn{flex:1 1 0;min-width:0;flex-direction:column;gap:2px;min-height:54px;padding:6px 10px;border-radius:16px;line-height:1.2}
.pbt .btn small{font:400 12px/1.2 var(--mono);opacity:.85}
.pres{display:flex;flex-direction:column;gap:4px;margin-top:8px}
.sg{padding:3px;gap:3px}
.sg button{padding:5px 12px;line-height:1.2}
.sg svg.ic{width:16px;height:16px}
.hm-bal:has(.hm-ba){display:grid;grid-template-columns:minmax(0,1fr) auto;grid-template-areas:"l b" "v b";align-items:center;column-gap:10px;min-height:48px;padding:8px 8px 8px 14px}
.hm-balc .hm-bal:has(.hm-ba){padding-right:8px}
.hm-bal .hm-ba{position:static;transform:none;grid-area:b;align-self:center;justify-self:end;display:flex;align-items:center;gap:8px}
.hm-bal:has(.hm-ba) .hm-m{grid-area:l}
.hm-bal:has(.hm-ba) .hm-dots{grid-area:v}
.hm-balc:has(.hm-bedit:not([hidden])) .hm-bedit{padding-right:14px}
.tnote{display:flex;gap:10px;align-items:baseline;padding:12px 14px;margin-bottom:12px;border-radius:16px;border:1px solid var(--ln);background:var(--s2);font-size:13px;line-height:1.4;color:var(--ink)}
.tnote b{font:600 12px/1.4 var(--mono);color:var(--mu);text-transform:uppercase;letter-spacing:.04em}

/* file21: icon buttons without browser margins, centered balance icons, compact theme switch */
button.ib{margin:0}
.hm-bal:has(.hm-ba){grid-template-rows:auto auto;align-content:center}
.hm-bal:has(.hm-ba) .hm-ba{grid-column:2;grid-row:1 / span 2;align-self:center;justify-self:end;margin:0;height:32px}
.hm-bal:has(.hm-ba) .hm-m{grid-column:1;grid-row:1}
.hm-bal:has(.hm-ba) .hm-dots{grid-column:1;grid-row:2}
.hm-bal .ib,.hm-bal .hm-ba .ib{margin:0;align-self:center}
.sg{align-items:stretch;margin:0}
.sg button{margin:0;min-height:0;height:34px;padding:0 12px;line-height:1;box-sizing:border-box}
.hm .cd .cb .sg{margin:0}

/* trading: three result buttons, game rows, stop notice */
.pbt.p3 .btn{flex-direction:row;min-height:46px;padding:0 8px;border-radius:14px;font-size:14px}
.btn.lost{background:rgba(255,170,60,.14);color:var(--earn);border-color:rgba(255,170,60,.45)}
.gm{margin:0;padding:10px 0;border-bottom:1px solid var(--ln)}
.gm:last-of-type{border-bottom:0}
.gmh{display:flex;justify-content:space-between;align-items:baseline;gap:10px;margin-bottom:2px}
.gmh span{font-size:14px;font-weight:600}
.gmh b{font:600 14px/1.2 var(--mono);color:var(--ink);white-space:nowrap}
.tstop{display:flex;flex-direction:column;gap:6px;padding:14px 16px;margin-bottom:12px;border-radius:18px;border:1px solid rgba(255,90,77,.4);background:rgba(255,90,77,.1);font-size:14px;line-height:1.45;color:var(--ink)}
.tstop b{font-size:18px;font-weight:700;color:var(--neg);letter-spacing:-.02em}

/* pad: chat-style lists, newest at the bottom */
.nt-wrap{display:flex;flex-direction:column;gap:6px}
.nt-wrap.nt-scr{overflow-y:auto;max-height:calc(100dvh - 300px);min-height:150px;overscroll-behavior:contain;scrollbar-width:thin}
.nt-scr{scroll-behavior:auto}
.nt-it,.nt-q{transition:background .15s ease}
.nt-it:hover,.nt-q:hover{background:var(--h-chip)}
.nt-it.nt:hover{background:var(--h-acs)}
.nt-cmp .nt-c{border-radius:26px;box-shadow:var(--sh1)}
.nt-cmp{padding-top:10px}
.nt-list.nt-scr>:last-child{padding-bottom:14px}

/* file22: field errors, game picker, trading page polish */
.fld{display:flex;flex-direction:column;gap:6px}
.ferr{font-size:13px;font-weight:600;color:var(--neg);line-height:1.3}
.in.bad,.hm .in.bad{border-color:var(--neg)!important;box-shadow:0 0 0 3px rgba(255,90,77,.18)}
.gm{display:flex;flex-direction:column;gap:10px;margin:10px 0 0;padding:14px;border:1px solid var(--ln);border-radius:18px;background:var(--s2)}
.gm:first-of-type{margin-top:0}
.gmh{margin:0}
.gmh span{font-size:15px}
.gq{font-size:13px;color:var(--mu)}
.gseg{display:grid;grid-template-columns:1fr 1fr;gap:6px;padding:3px;border-radius:14px;background:var(--bg);border:1px solid var(--ln)}
.gseg label{position:relative;display:block;margin:0;cursor:pointer}
.gseg input{position:absolute;opacity:0;pointer-events:none;width:0;height:0}
.gseg span{display:flex;align-items:center;justify-content:center;min-height:40px;padding:0 8px;border-radius:11px;font-size:14px;font-weight:600;color:var(--mu);text-align:center}
.gseg input:checked+span{background:var(--acs);color:var(--ac);box-shadow:inset 0 0 0 1px var(--acl)}
.gyes,.gno{display:none}
.gm:has(input[value=yes]:checked) .gyes{display:flex;flex-direction:column;gap:8px}
.gm:has(input[value=no]:checked) .gno{display:block}
.gm .pbt{margin:0}
.gm .btn.full.gsk{margin-top:0;min-height:46px;font-size:15px}
.rw.gdn{padding:12px 14px;margin-bottom:8px;border:1px solid var(--ln);border-radius:14px;background:var(--s2)}
.rw.gdn:last-of-type{margin-bottom:0}
.trd{display:flex;flex-direction:column;gap:0}
.trd .cd{margin-top:0;margin-bottom:12px}
.trd .cd .tg{font-weight:600;letter-spacing:.01em;margin-bottom:6px}
.trd .cb>.rw{padding:10px 0}
.trd .cb>.rw:first-of-type{padding-top:2px}
.trd .pres .in{min-height:48px;font-size:16px}
.hm-top{display:grid;grid-template-columns:2fr 1fr;gap:10px;align-items:stretch}
.hm-top>.hm-c{min-width:0}
.hm-date{display:flex;align-items:center;justify-content:center;gap:8px;padding:0 10px;min-height:48px}
.hm-date b{font-size:24px;line-height:1;font-weight:700;letter-spacing:-.02em;font-variant-numeric:tabular-nums}
.hm-dm{display:flex;flex-direction:column;gap:2px}
.hm-dm small{display:block;font:500 11px/1.1 var(--h-mono);color:var(--h-mu);text-transform:uppercase}
.hm-tl{display:flex;flex-direction:column;padding:2px 14px}
.hm-tr{display:grid;grid-template-columns:10px minmax(0,1fr) auto;column-gap:8px;align-items:center;padding:5px 0;color:inherit;text-decoration:none}
.hm-tr+.hm-tr{border-top:1px solid var(--h-ln)}
.hm-td{width:8px;height:8px;border-radius:50%}
.hm-tn{font-size:14px;font-weight:500;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.hm-tb{grid-column:1 / -1;height:3px;border-radius:2px;background:var(--h-bg);margin-top:4px;overflow:hidden}
.hm-tb i{display:block;height:100%;border-radius:2px}
.hm-pd{display:flex;align-items:center;justify-content:space-between;gap:10px;min-height:44px;padding:6px 6px 6px 14px}
.hm-pt{font-size:14px;font-weight:600;min-width:0}
.hm-pg{display:flex;align-items:center;justify-content:center;height:32px;padding:0 16px;border:0;border-radius:11px;background:var(--h-fill);color:var(--h-on);font:600 13px var(--h-sans);text-decoration:none;cursor:pointer}
MT_EOF
mkdir -p app/client
cat > app/client/app.js <<'MT_EOF'
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
		if (t.closest && !t.closest("[data-xplus]") && t.closest("details[data-fixed] > summary")) {
			e.preventDefault()
			return
		}
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
		if ((q = t.closest("[data-pw]"))) {
			var pwi = q.parentNode.querySelector("input")
			if (pwi) {
				var pwShow = pwi.type === "password"
				pwi.type = pwShow ? "text" : "password"
				q.setAttribute("aria-pressed", pwShow ? "true" : "false")
				q.setAttribute("aria-label", pwShow ? "Hide password" : "Show password")
			}
			return
		}
		if ((q = t.closest("[data-eye]"))) {
			var v = q.closest(".hm-bal").querySelector(".hm-dots")
			var hide = q.getAttribute("data-s") !== "1"
			q.setAttribute("data-s", hide ? "1" : "0")
			v.innerHTML = hide ? v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>" : "••••••"
			return
		}
		if ((q = t.closest("[data-edit-bal]"))) {
			var bf = q.closest(".cd,.sc").querySelector("[data-balf]")
			bf.hidden = !bf.hidden
			q.setAttribute("aria-label", bf.hidden ? "Edit balance" : "Cancel")
			q.classList.toggle("hi", !bf.hidden)
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
			e.preventDefault()
			var xc = q.closest(".xc")
			var xd = xc.querySelector("details")
			var xm = xc.querySelector("[data-adp]")
			if (xm) {
				if (xd && !xd.open) {
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
	})

	d.addEventListener(
		"click",
		function (e) {
			var b = e.target.closest && e.target.closest("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn"))) e.preventDefault()
		},
		true,
	)

	// Fallback spinner for any submit button that is not the shared Submit component.
	var SPIN = '<span class="sb-i" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg></span>'
	d.addEventListener("submit", function (e) {
		var f = e.target
		var msg = f.getAttribute && f.getAttribute("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		var sub = e.submitter
		setTimeout(function () {
			if (e.defaultPrevented) return
			all("button", f).forEach(function (b) {
				if (b.disabled) return
				b.disabled = true
				if (!sub || b === sub) {
					b.setAttribute("data-busy", "1")
					b.setAttribute("aria-busy", "true")
					if (!b.querySelector(".sb-i")) b.insertAdjacentHTML("beforeend", SPIN)
				} else b.setAttribute("data-lock", "1")
			})
		}, 0)
	})

	function unbusy() {
		all("button[data-busy],button[data-lock]").forEach(function (b) {
			b.disabled = false
			b.removeAttribute("data-busy")
			b.removeAttribute("data-lock")
			b.removeAttribute("aria-busy")
		})
	}
	window.addEventListener("pageshow", function (e) {
		if (e.persisted) unbusy()
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
	var wf = fmt("en-GB", { weekday: "short" })
	var yf = fmt("en-GB", { day: "numeric" })
	var mf = fmt("en-GB", { month: "short" })
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
		all("[data-d-wd]").forEach(function (el) {
			el.textContent = wf.format(now)
		})
		all("[data-d-day]").forEach(function (el) {
			el.textContent = yf.format(now)
		})
		all("[data-d-mo]").forEach(function (el) {
			el.textContent = mf.format(now)
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

;(function () {
	var d = document
	var K = "mt:pad:v1"
	var TABS = {
		projects: { space: "project", entry: "note", head: "Projects", add: "New project", ph: "Write a note", empty: "No projects yet. Add your first one above.", noun: "notes" },
		people: { space: "person", entry: "quote", head: "People", add: "Add a person", ph: "What did they say?", empty: "No one yet. Add a person, then what they said.", noun: "things said" },
		books: { space: "book", entry: "lesson", head: "Books", add: "Book name", sub: "Author (optional)", ref: "Chapter or page (optional)", ph: "What did you learn?", empty: "No books yet. Add a book, then what you learned from it.", noun: "lessons" },
		tips: { entry: "tip", flat: true, ph: "Something useful to remember", ref: "Where from (optional)", empty: "Nothing saved yet." },
	}
	var data = { spaces: [], entries: [] }
	var load = function () {
		try {
			var v = JSON.parse(localStorage.getItem(K) || "null")
			if (v && v.spaces && v.entries) data = v
		} catch (e) {}
	}
	var save = function () {
		try {
			localStorage.setItem(K, JSON.stringify(data))
		} catch (e) {}
	}
	var uid = function () {
		return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
	}
	var esc = function (s) {
		return String(s).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
		})
	}
	var when = function (t) {
		return new Date(t).toLocaleDateString("en-GB", { day: "numeric", month: "short" })
	}
	var spaceOf = function (id) {
		return data.spaces.filter(function (s) {
			return s.id === id
		})[0]
	}
	var entriesOf = function (fn) {
		return data.entries
			.filter(fn)
			.sort(function (a, b) {
				return b.at - a.at
			})
	}
	var entryHtml = function (e, label) {
		return (
			'<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + "</div>" +
			'<div class="pdm"><span class="lb">' + (label ? esc(label) + " · " : "") + (e.ref ? esc(e.ref) + " · " : "") + when(e.at) + "</span>" +
			'<span class="pda"><button type="button" class="chip' + (e.home ? " on" : "") + '" data-pd="home">Home</button>' +
			'<button type="button" class="chip" data-pd="edit">Edit</button>' +
			'<button type="button" class="chip" data-pd="del">Delete</button></span></div></div>'
		)
	}
	var composer = function (c, spaceId) {
		return (
			'<form class="pdf" data-pd="entry" data-space="' + (spaceId || "") + '">' +
			'<textarea class="pdi" name="body" rows="3" placeholder="' + esc(c.ph) + '" required></textarea>' +
			(c.ref ? '<input class="pdi" name="ref" placeholder="' + esc(c.ref) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>'
		)
	}
	var tabHtml = function (key) {
		var c = TABS[key]
		var id = decodeURIComponent(location.hash.slice(1))
		if (c.flat) return composer(c, "") + (entriesOf(function (e) { return e.kind === c.entry }).map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">' + c.empty + "</div>")
		var sp = id && spaceOf(id)
		if (sp && sp.kind === c.space) {
			var list = entriesOf(function (e) { return e.space === sp.id })
			return (
				'<div class="pdhd"><a class="chip" href="#" data-pd="back">‹ ' + c.head + "</a>" +
				'<button type="button" class="chip" data-pd="delspace" data-id="' + sp.id + '">Delete</button></div>' +
				'<h2 class="pdtt">' + esc(sp.title) + "</h2>" + (sp.sub ? '<div class="lb">' + esc(sp.sub) + "</div>" : "") +
				composer(c, sp.id) +
				(list.map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">Nothing here yet.</div>')
			)
		}
		var spaces = data.spaces
			.filter(function (s) { return s.kind === c.space })
			.sort(function (a, b) { return b.at - a.at })
		return (
			'<form class="pdf" data-pd="space"><input class="pdi" name="title" placeholder="' + esc(c.add) + '" autocomplete="off" required>' +
			(c.sub ? '<input class="pdi" name="sub" placeholder="' + esc(c.sub) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>' +
			(spaces.map(function (s) {
				var n = data.entries.filter(function (e) { return e.space === s.id }).length
				return '<a class="pdc" href="#' + encodeURIComponent(s.id) + '"><span><b>' + esc(s.title) + '</b><span class="lb">' + (s.sub ? esc(s.sub) + " · " : "") + n + " " + c.noun + '</span></span><span class="mu">›</span></a>'
			}).join("") || '<div class="lb pde">' + c.empty + "</div>")
		)
	}
	var homeHtml = function () {
		var list = entriesOf(function (e) { return e.home }).slice(0, 6)
		return (
			'<div class="sh"><span>Pinned notes</span><span class="lb">' + list.length + "</span></div>" +
			'<form class="pdf" data-pd="entry" data-space="" data-home="1"><input class="pdi" name="body" placeholder="Add a note to home" autocomplete="off" required><button class="btn xs">Add</button></form>' +
			(list.map(function (e) {
				var s = e.space && spaceOf(e.space)
				return '<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + '</div><div class="pdm"><span class="lb">' + (s ? esc(s.title) + " · " : "") + when(e.at) + '</span><span class="pda"><button type="button" class="chip" data-pd="home">Unpin</button></span></div></div>'
			}).join("") || '<div class="lb pde">Pin any note with the Home button.</div>')
		)
	}
	var paint = function () {
		[].slice.call(d.querySelectorAll("[data-pad]")).forEach(function (r) {
			var a = d.activeElement
			if (a && r.contains(a) && a.value) return
			r.innerHTML = tabHtml(r.getAttribute("data-pad"))
		})
		var h = d.activeElement
		;[].slice.call(d.querySelectorAll("[data-pad-home]")).forEach(function (r) {
			if (h && r.contains(h) && h.value) return
			r.innerHTML = homeHtml()
		})
	}
	var repaint = function () {
		save()
		;[].slice.call(d.querySelectorAll("[data-pad],[data-pad-home]")).forEach(function (r) {
			r.innerHTML = r.hasAttribute("data-pad") ? tabHtml(r.getAttribute("data-pad")) : homeHtml()
		})
	}
	d.addEventListener("submit", function (e) {
		var f = e.target
		var kind = f.getAttribute && f.getAttribute("data-pd")
		if (kind !== "space" && kind !== "entry") return
		e.preventDefault()
		var root = f.closest("[data-pad]")
		var tab = root && root.getAttribute("data-pad")
		var c = tab && TABS[tab]
		var v = function (n) {
			var i = f.elements[n]
			return i ? i.value.trim() : ""
		}
		var now = Date.now()
		if (kind === "space" && c) {
			if (!v("title")) return
			data.spaces.push({ id: uid(), kind: c.space, title: v("title").slice(0, 120), sub: v("sub").slice(0, 120), at: now })
		} else if (kind === "entry") {
			if (!v("body")) return
			var home = f.getAttribute("data-home") === "1"
			data.entries.push({ id: uid(), space: f.getAttribute("data-space") || null, kind: c ? c.entry : "note", body: v("body").slice(0, 4000), ref: v("ref").slice(0, 120), home: home, at: now })
		}
		repaint()
	})
	d.addEventListener("click", function (e) {
		var b = e.target.closest && e.target.closest("[data-pd]")
		if (!b || b.tagName === "FORM") return
		var act = b.getAttribute("data-pd")
		var row = b.closest("[data-id]")
		var id = row ? row.getAttribute("data-id") : b.getAttribute("data-id")
		var en = id && data.entries.filter(function (x) { return x.id === id })[0]
		if (act === "back") {
			e.preventDefault()
			history.pushState("", "", location.pathname)
			return repaint()
		}
		if (act === "home" && en) en.home = !en.home
		else if (act === "edit" && en) {
			var t = prompt("Edit", en.body)
			if (t === null || !t.trim()) return
			en.body = t.trim().slice(0, 4000)
		} else if (act === "del" && en) {
			if (!confirm("Delete this?")) return
			data.entries = data.entries.filter(function (x) { return x.id !== id })
		} else if (act === "delspace" && id) {
			if (!confirm("Delete this and everything inside it?")) return
			data.spaces = data.spaces.filter(function (x) { return x.id !== id })
			data.entries = data.entries.filter(function (x) { return x.space !== id })
			history.pushState("", "", location.pathname)
		} else return
		repaint()
	})
	addEventListener("hashchange", paint)
	addEventListener("storage", function (e) {
		if (e.key !== K) return
		load()
		paint()
	})
	load()
	paint()
})()

/* file20 */
;(function () {
	var d = document
	var hold = 0
	var fired = false
	var sx = 0
	var sy = 0
	var toast = function (t) {
		var x = d.createElement("div")
		x.className = "nt-toast"
		x.textContent = t
		d.body.appendChild(x)
		setTimeout(function () {
			x.remove()
		}, 1100)
	}
	var copy = function (t) {
		try {
			if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(t)
		} catch (e) {}
		var a = d.createElement("textarea")
		a.value = t
		a.style.cssText = "position:fixed;opacity:0"
		d.body.appendChild(a)
		a.select()
		try {
			d.execCommand("copy")
		} catch (e) {}
		a.remove()
		return Promise.resolve()
	}
	var edit = function (it) {
		var f = it && it.querySelector("[data-edit]")
		var b = it && it.querySelector("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		var mn = it.querySelector(".nt-mn")
		if (mn) mn.hidden = true
		var ta = f.querySelector("input[name=body],textarea")
		if (!ta.value) ta.value = ta.defaultValue || it.querySelector("[data-copy] p").textContent.trim()
		ta.focus()
		ta.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "center", behavior: "smooth" })
	}
	d.addEventListener("pointerdown", function (e) {
		var b = e.target.closest && e.target.closest("[data-copy]")
		if (!b) return
		fired = false
		sx = e.clientX
		sy = e.clientY
		clearTimeout(hold)
		hold = setTimeout(function () {
			fired = true
			if (navigator.vibrate) navigator.vibrate(15)
			edit(b.closest("[data-pad-item]"))
		}, 450)
	})
	d.addEventListener("pointermove", function (e) {
		if (hold && (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8)) clearTimeout(hold)
	})
	;["pointerup", "pointercancel", "pointerleave"].forEach(function (n) {
		d.addEventListener(n, function () {
			clearTimeout(hold)
		}, true)
	})
	d.addEventListener("contextmenu", function (e) {
		if (e.target.closest && e.target.closest("[data-copy]")) e.preventDefault()
	})
	var closeMenus = function () {
		[].slice.call(d.querySelectorAll(".nt-dd:not([hidden])")).forEach(function (m) {
			m.hidden = true
			var o = m.parentNode.querySelector("[data-menu]")
			if (o) o.setAttribute("aria-expanded", "false")
		})
	}
	d.addEventListener("keydown", function (e) {
		if (e.key === "Escape") closeMenus()
	})
	d.addEventListener("click", function (e) {
		var t = e.target
		var mb = t.closest && t.closest("[data-menu]")
		if (mb) {
			var dd = mb.parentNode.querySelector(".nt-dd")
			var was = !dd.hidden
			closeMenus()
			if (!was) {
				dd.classList.remove("up")
				dd.hidden = false
				mb.setAttribute("aria-expanded", "true")
				var box = mb.closest(".nt-scr")
				if (box) {
					var br = box.getBoundingClientRect()
					var dr = dd.getBoundingClientRect()
					if (dr.bottom > br.bottom) dd.classList.add("up")
				}
			}
			return
		}
		var me = t.closest && t.closest("[data-menu-edit]")
		if (me) {
			closeMenus()
			edit(me.closest("[data-pad-item]"))
			return
		}
		if (!(t.closest && t.closest(".nt-dd"))) closeMenus()
		var b = t.closest && t.closest("[data-copy]")
		if (b) {
			if (fired) {
				fired = false
				return
			}
			var p = b.querySelector("p")
			copy((p || b).textContent.trim()).then(function () {
				toast("Copied")
			})
			return
		}
		var x = t.closest && t.closest("[data-edit-x]")
		if (x) {
			var it = x.closest("[data-pad-item]")
			it.querySelector("[data-edit]").hidden = true
			it.querySelector("[data-copy]").hidden = false
			var mn2 = it.querySelector(".nt-mn")
			if (mn2) mn2.hidden = false
			return
		}
		var a = t.closest && t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")
		if (a) {
			setTimeout(function () {
				var box = a.closest(".xc,.dbw,.sc,.cd") || d
				var f = [].slice.call(box.querySelectorAll("[data-adp],[data-addp],[data-payp]")).filter(function (n) {
					return !n.hidden && n.offsetParent
				})[0]
				if (!f) return
				var i = f.querySelector("input:not([type=hidden]),textarea")
				if (i) i.focus({ preventScroll: true })
				f.scrollIntoView({ block: "center", behavior: "smooth" })
			}, 60)
		}
	})

	var dis = {}
	try {
		dis = JSON.parse(localStorage.getItem("mt:inv") || "{}")
	} catch (e) {}
	;[].slice.call(d.querySelectorAll("[data-inv]")).forEach(function (n) {
		if (dis[n.getAttribute("data-inv")]) n.hidden = true
	})
	d.addEventListener("click", function (e) {
		var x = e.target.closest && e.target.closest("[data-inv-x]")
		if (!x) return
		var n = x.closest("[data-inv]")
		dis[n.getAttribute("data-inv")] = 1
		try {
			localStorage.setItem("mt:inv", JSON.stringify(dis))
		} catch (err) {}
		n.hidden = true
	})
})()

;(function () {
	var run = function () {
		;[].slice.call(document.querySelectorAll("[data-bottom]")).forEach(function (l) {
			l.scrollTop = l.scrollHeight
		})
	}
	run()
	window.addEventListener("load", run)
	window.addEventListener("pageshow", run)
})()

;(function () {
	var MSG = { win: "Enter how much you won in USDT", lose: "Enter how much you lost in USDT" }
	var clear = function (f) {
		var i = f.querySelector("[name=pnl]")
		var e = f.querySelector(".ferr")
		if (i) i.classList.remove("bad")
		if (e) {
			e.hidden = true
			e.textContent = ""
		}
	}
	document.addEventListener(
		"submit",
		function (e) {
			var f = e.target
			if (!f.hasAttribute || !f.hasAttribute("data-pnl")) return
			var o = e.submitter && e.submitter.value
			if (o !== "win" && o !== "lose") return
			var i = f.querySelector("[name=pnl]")
			var n = parseFloat(String(i.value).replace(",", "."))
			if (isFinite(n) && n > 0) return
			e.preventDefault()
			e.stopImmediatePropagation()
			var er = f.querySelector(".ferr")
			i.classList.add("bad")
			er.textContent = MSG[o]
			er.hidden = false
			;(er.parentNode || i).scrollIntoView({ block: "center", behavior: "smooth" })
			i.focus({ preventScroll: true })
		},
		true,
	)
	document.addEventListener("input", function (e) {
		var f = e.target.closest && e.target.closest("[data-pnl]")
		if (f && e.target.name === "pnl") clear(f)
	})
})()
MT_EOF
mkdir -p app
cat > app/commands.ts <<'MT_EOF'
import * as act from "./lib/actions.ts"
import * as inc from "./lib/income.ts"
import { toMinor } from "./lib/money.ts"
import * as pad from "./lib/pad.ts"
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
	tradeResult: { run: (u, f) => trading.saveResult(u.id, f), to: "/trading" },
	tradeGame: { run: (u, f) => trading.saveGame(u.id, f), to: "/trading" },
	tradeUndo: { run: (u, f) => trading.undoResult(u.id, f), to: "/trading" },
	tradeFinish: { run: (u, f) => trading.finishTrade(u.id, f), to: "/trading" },
	tradeReopen: { run: (u, f) => trading.reopenTrade(u.id, f), to: "/trading" },
	saveProfile: { run: (u, f) => updateProfile(u.id, { name: field(f, "name"), email: field(f, "email") }), to: "/profile", back: false, fail: "/profile/edit" },
	saveSettings: {
		run: quiet((u, f) => updatePrefs(u.id, { currency: field(f, "currency"), run_at: field(f, "run_at"), day_start: parseInt(field(f, "day_start"), 10), week_start: field(f, "week"), usdt_rate_minor: toMinor(f.get("usdt")), usd_rate_minor: toMinor(f.get("usd_rate")) })),
		to: "/settings",
	},
	setTheme: { run: quiet((u, f) => setTheme(u.id, field(f, "theme"))), to: "/settings", empty: true },
	padAddSpace: { run: (u, f) => pad.addSpace(u.id, f), to: "/pad", fail: "/pad/new" },
	padEditSpace: { run: (u, f) => pad.editSpace(u.id, f), to: "/pad", fail: "/pad" },
	padDelSpace: { run: quiet((u, f) => pad.deleteSpace(u.id, f)), to: "/pad" },
	padAdd: { run: (u, f) => pad.addEntry(u.id, f), to: "/pad" },
	padToggle: { run: quiet((u, f) => pad.toggleEntry(u.id, f)), to: "/pad" },
	padEdit: { run: (u, f) => pad.editEntry(u.id, f), to: "/pad" },
	padDel: { run: quiet((u, f) => pad.deleteEntry(u.id, f)), to: "/pad" },
} satisfies Record<string, Command>

export type CommandName = keyof typeof commands

export const errorOf = (r: unknown) => (typeof r === "string" && r ? r : "")
MT_EOF
mkdir -p app/components
cat > app/components/balancecard.tsx <<'MT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { Icon, view } from "./ui.tsx"

export const BalanceCard = view<{ s: State }>(({ s }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
			••••••
		</b>
		<div class="hm-ba">
			<button type="button" class="ib" data-eye aria-label="Show balance">
				<Icon name="eye" />
			</button>
		</div>
		<div class="hm-m">Total balance</div>
	</div>
))
MT_EOF
mkdir -p app/components
cat > app/components/bottombar.tsx <<'MT_EOF'
import { Icon, view } from "./ui.tsx"

export type MobileTab = "home" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | ""

const TABS = [
	{ key: "home", label: "Home", icon: "bhome", href: "/home" },
	{ key: "trading", label: "Predict", icon: "btrade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "bdoc", href: "/pad" },
	{ key: "income", label: "Income", icon: "bsun", href: "/income" },
	{ key: "profile", label: "Profile", icon: "buser", href: "/profile" },
] as const

export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label} aria-current={active === t.key ? "page" : undefined}>
				<span class="bp">
					<Icon name={t.icon} />
				</span>
				<span class="bl">{t.label}</span>
			</a>
		))}
	</nav>
))
MT_EOF
mkdir -p app/components
cat > app/components/buys.tsx <<'MT_EOF'
import type { Buy, State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { hhmm } from "../lib/time.ts"
import { calc } from "../lib/view.ts"
import { Back, Empty, ExpandCard, Icon, ListCard, NameChips, Submit, view } from "./ui.tsx"

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
				<Submit class="ub" aria-label="Undo buy">
					<Icon name="undo" />
				</Submit>
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
		<Submit class="btn full">Add a spend</Submit>
	</>
))

export const BuysExpand = view<{ s: State }>(({ s }) => (
	<ExpandCard
		storeKey="buys"
		open
		fixed
		title="Today's buys"
		label="Add a spend"
		head={s.buys.length ? undefined : <span class="em">Nothing bought today.</span>}
		form={
			<form method="post" action="/buy" class="sf xfm" data-sp data-adp hidden>
				<SpendFields s={s} />
			</form>
		}
	>
		{s.buys.length ? <BuyRows s={s} /> : null}
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
MT_EOF
mkdir -p app/components
cat > app/components/datecard.tsx <<'MT_EOF'
import { dateParts } from "../lib/time.ts"
import { view } from "./ui.tsx"

export const DateCard = view(() => {
	const { weekday, day, month } = dateParts()
	return (
		<div class="hm-c hm-date" aria-label="Today">
			<b data-d-day>{day}</b>
			<div class="hm-dm">
				<small data-d-wd>{weekday}</small>
				<small data-d-mo>{month}</small>
			</div>
		</div>
	)
})
MT_EOF
mkdir -p app/components
cat > app/components/home.tsx <<'MT_EOF'
import type { State } from "../lib/data.ts"
import { fmt } from "../lib/money.ts"
import { today } from "../lib/time.ts"
import { flowOf, resOf, TRIES } from "../lib/trade-math.ts"
import { calc } from "../lib/view.ts"
import { Submit, view } from "./ui.tsx"

export type PadProject = { id: string; title: string; color: string; left: number; total: number }
export type PadLeft = { projects: PadProject[]; home: { left: number; total: number } }

const Stat = view<{ label: string; sign: string; value: number; cur: string }>(({ label, sign, value, cur }) => (
	<div class="hm-c hm-bal">
		<b class="hm-dots">{`${sign}${fmt(value)}`} <small>{cur}</small></b>
		<div class="hm-m">{label}</div>
	</div>
))

export const HomeToday = view<{ s: State }>(({ s }) => {
	const c = calc(s)
	return (
		<div class="hm-two">
			<Stat label="Earned today" sign="+" value={c.earned} cur={s.user.currency} />
			<Stat label="Bought today" sign="−" value={c.bought} cur={s.user.currency} />
		</div>
	)
})

export const HomePredict = view<{ s: State }>(({ s }) => {
	const day = today(s.user.day_start)
	const open = s.trades.find((t) => t.status === "open")
	const done = s.trades.find((t) => t.day === day && t.status === "settled")
	const f = open ? flowOf(open.deposit, open.results) : null
	const won = !!done && resOf(done.results).some((x) => x.won)
	const title = f
		? f.over
			? f.won
				? "5 min done · finish the games"
				: "Stop trading · finish the games"
			: f.tryNo > 1
				? `Second try · ${fmt(f.left)} USDT left`
				: `Predict is open · try ${f.tryNo} of ${TRIES}`
		: done
			? won
				? "Won today · predict ended"
				: "Done for today"
			: "You can predict today"
	return (
		<div class="hm-c hm-pd">
			<span class="hm-pt">{title}</span>
			{f ? (
				<a class="hm-pg" href="/trading">
					Continue
				</a>
			) : !done ? (
				<form method="post" action="/trading/deposit" style={{ margin: 0 }}>
					<input type="hidden" name="back" value="/trading" />
					<Submit class="hm-pg">Start</Submit>
				</form>
			) : null}
		</div>
	)
})

const TaskRow = view<{ href: string; title: string; color: string; left: number; total: number }>(({ href, title, color, left, total }) => (
	<a class="hm-tr" href={href}>
		<i class="hm-td" style={{ background: color }}></i>
		<span class="hm-tn">{title}</span>
		<span class="hm-m">{`${left} left`}</span>
		<span class="hm-tb">
			<i style={{ width: `${total ? Math.round(((total - left) / total) * 100) : 0}%`, background: color }}></i>
		</span>
	</a>
))

export const HomeTasks = view<{ p: PadLeft }>(({ p }) => {
	if (!p.projects.length && p.home.left < 1) return null
	return (
		<div class="hm-c hm-tl">
			{p.projects.map((x) => (
				<TaskRow key={x.id} href={`/pad?p=${x.id}`} title={x.title} color={x.color} left={x.left} total={x.total} />
			))}
			{p.home.left > 0 ? <TaskRow href="/pad/home" title="Home" color="#8b979e" left={p.home.left} total={p.home.total} /> : null}
		</div>
	)
})
MT_EOF
mkdir -p app/components
cat > app/components/layout.tsx <<'MT_EOF'
import type { RemixNode } from "remix/component"
import { env } from "../env.ts"
import { SITE } from "../lib/assets.ts"
import { liveClockNow } from "../lib/time.ts"
import { V } from "../lib/static.ts"
import { BottomBar, type MobileTab } from "./bottombar.tsx"
import { Icon, Logo, Submit, ThemeIcons, view } from "./ui.tsx"

type DocumentProps = {
	title: string
	user?: boolean
	theme?: string
	desc?: string
	path?: string
	auth?: boolean
	children?: RemixNode
}

const THEME_BOOT = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`
const REGISTER_SW = `if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))`
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Noto+Sans+Arabic:wght@500;600&display=swap"

export const Document = view<DocumentProps>(({ title, user = true, theme, desc, path, auth, children }) => {
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
				{auth ? <link rel="stylesheet" href={`/assets/auth.css?v=${V.auth}`} /> : null}
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

export const TopBar = view(() => (
	<div class="top-status-bar">
		<ClockWidget />
	</div>
))

export type DesktopTab = "home" | "plan" | "income" | "trading" | "pad" | "history" | "settings" | ""

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
	{ key: "trading", label: "Predict", icon: "trade", href: "/trading" },
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
			<Submit class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</Submit>
		</form>
	</aside>
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
				<div class="m mm hm">{mobile}</div>
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
	<Document title={title} path={path} desc={desc} user={false} auth>
		<div class="app">
			<main class="auth-main">{children}</main>
		</div>
	</Document>
))
MT_EOF
mkdir -p app/components
cat > app/components/profile.tsx <<'MT_EOF'
import type { State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { LANG } from "../lib/view.ts"
import { Avatar, Back, Card, ErrorBanner, Field, Icon, PageHeader, Section, Submit, ThemeSwitch, view } from "./ui.tsx"

const BalanceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/profile/balance">
		<Back s={s} />
		<div class="fl">
			<label>Balance ({s.user.currency})</label>
			<input class="in f" name="balance" inputmode="decimal" value={plain(s.balance)} autocomplete="off" required />
		</div>
		<Submit class="btn full" style={{ marginTop: "14px" }}>
			Update balance
		</Submit>
	</form>
))

export const BalanceEditCard = view<{ s: State; edit?: boolean }>(({ s, edit = false }) => (
	<div class="cd hm-balc">
		<div class="hm-bal">
			<b class="hm-dots" data-bal={`${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}`} data-cur={s.user.currency}>
				••••••
			</b>
			<div class="hm-ba">
				<button type="button" class="ib" data-eye aria-label="Show balance">
					<Icon name="eye" />
				</button>
				{edit ? (
					<button type="button" class="ib" data-edit-bal aria-label="Edit balance">
						<Icon name="edit" />
					</button>
				) : null}
			</div>
			<div class="hm-m">Total balance</div>
		</div>
		{edit ? (
			<div class="hm-bedit" data-balf hidden>
				<BalanceForm s={s} />
			</div>
		) : null}
	</div>
))

const ProfileForm = view<{ s: State; cancel: string; showError?: boolean }>(({ s, cancel, showError = false }) => (
	<form method="post" action="/profile/edit">
		{showError ? <ErrorBanner s={s} /> : null}
		<Field label="Name" value={s.user.name} name="name" first />
		<Field label="Email" value={s.user.email} type="email" name="email" />
		<div style={{ display: "flex", gap: "10px", marginTop: "18px" }}>
			<Submit class="btn" style={{ flex: "1" }}>
				Save
			</Submit>
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
		<div class="fl">
			<label>Day resets at</label>
			<select class="in" name="day_start" style={{ width: "100%" }}>
				{Array.from({ length: 24 }, (_, h) => (
					<option key={h} value={String(h)} selected={h === s.user.day_start ? true : undefined}>
						{String(h).padStart(2, "0")}:00
					</option>
				))}
			</select>
		</div>
		<Field label="1 USD in MAD (ExoClick)" value={plain(s.user.usd_rate_minor)} name="usd_rate" />
		<Field label="Week starts" value={s.user.week_start} name="week" />
		<Submit class="btn" style={{ marginTop: "14px" }}>
			Save
		</Submit>
	</form>
))

const DataButtons = view(() => (
	<div style={{ display: "flex", gap: "10px", marginTop: "6px" }}>
		<a class="btn o" style={{ flex: "1" }} href="/export.csv">
			Export CSV
		</a>
		<form method="post" action="/account/delete" style={{ flex: "1", display: "flex" }} data-confirm="Delete your account and all your data? This cannot be undone.">
			<Submit class="btn dng" style={{ flex: "1" }}>
				Delete account
			</Submit>
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
		<BalanceEditCard s={s} edit />
		<Card title="Appearance">
			<ThemeSwitch />
		</Card>
		<Card title="Account">
			<LinkRow href="/profile/edit" label="Edit profile" />
			<LinkRow href="/settings" label="Settings" />
			<LinkRow href="/history" label="History" />
			<form method="post" action="/logout">
				<Submit class="li">
					<span class="neg">Log out</span>
					<span class="mu">›</span>
				</Submit>
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
				<BalanceEditCard s={s} edit />
				<Section title="Profile">
					<ProfileForm s={s} cancel="/home" />
				</Section>
				<Section title="Account">
					<form method="post" action="/logout">
						<Submit class="btn o">Log out</Submit>
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
MT_EOF
mkdir -p app/components
cat > app/components/ui.tsx <<'MT_EOF'
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
	home: '<path d="M3 11l9-8 9 8v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
	goal: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>',
	hist: '<path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/>',
	gear: '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
	edit: '<path d="M4 20h4L19 9l-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
	pad: '<path d="M6 3h9l4 4v14H6z"/><path d="M14 3v5h5M9 13h7M9 17h5"/>',
	trade: '<circle cx="12" cy="10" r="7"/><path d="M7.5 21h9M8.8 16.6 7.5 21M15.2 16.6l1.3 4.4M8.6 8.2a4 4 0 0 1 2.8-2"/>',
	coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
	out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
	plus: '<path d="M12 5v14M5 12h14"/>',
	trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
	undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
	send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
	back: '<path d="M15 5l-7 7 7 7"/>',
	chev: '<path d="M6 9l6 6 6-6"/>',
	check: '<path d="m5 12 5 5 9-9"/>',
	bhome: '<path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="M9 22V12h6v10"/>',
	btrade: '<circle cx="12" cy="10" r="7"/><path d="M7.5 21h9M8.8 16.6 7.5 21M15.2 16.6l1.3 4.4M8.6 8.2a4 4 0 0 1 2.8-2"/>',
	bdoc: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h8"/>',
	bsun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M6.34 17.66l-1.41 1.41M19.07 4.93l-1.41 1.41"/>',
	buser: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
	revert: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>',
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

/**
 * Shared submit button. Use it for every button that submits a form.
 * While its form is submitting, the page script marks it data-busy and CSS shows
 * only the rotate icon (label and icons are hidden, size stays the same).
 */
export const Submit = view<Record<string, any>>(({ children, ...rest }) => (
	<button {...rest}>
		<span class="sb-l">{children}</span>
		<span class="sb-i" aria-hidden="true">
			<Icon name="revert" />
		</span>
	</button>
))

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
	fixed?: boolean
	children?: RemixNode
}

export const ExpandCard = view<ExpandProps>(({ storeKey, open, title, head, foot, form, label = "", jar = -1, fixed = false, children }) => (
	<div class={label ? "xc" : "xc xn"}>
		<details class="xd" data-keep-open={fixed ? undefined : storeKey} data-fixed={fixed ? "1" : undefined} open={open || fixed ? true : undefined}>
			<summary class="xh osum">
				{jar >= 0 ? <i class={jar >= 100 ? "xj full" : "xj"} style={{ width: `${jar}%` }}></i> : null}
				<div>
					<div class="tg0">{title}</div>
					{head ? <div class="ow">{head}</div> : null}
				</div>
				{fixed ? null : (
					<span class="chev">
						<Icon name="chev" />
					</span>
				)}
				{label ? (
					<button type="button" class="xp" data-xplus aria-label={label}>
						<Icon name="plus" />
					</button>
				) : null}
			</summary>
			<div class="xb">{children}</div>
			<div class={foot ? "xf" : "xf xo"}>
				{foot}
				{form}
			</div>
		</details>
	</div>
))
MT_EOF
mkdir -p app/controllers
cat > app/controllers/pages.tsx <<'MT_EOF'
import { createController } from "remix/router"
import type { RemixNode } from "remix/component"
import * as act from "../lib/actions.ts"
import { loadState, type Part, type State } from "../lib/data.ts"
import { DebtsScreen, GoalsScreen, HistoryScreen, HomeScreen, IncomeScreen, PadScreen, ProfileEditScreen, ProfileScreen, SettingsScreen, TradingScreen } from "../screens.tsx"
import { routes } from "../routes.ts"
import { go, takeError, userOf, type Ctx } from "../request.ts"
import { loadPad } from "../lib/pad.ts"
import type { PadData } from "../lib/padmeta.ts"
import { saveTab, type User } from "../lib/users.ts"
import type { PadTab } from "../components/pad.tsx"
import type { PadLeft } from "../components/home.tsx"

const KEEP = /^\/(home|trading|income|profile|history|plan|settings|pad(\/(said|home))?)(\?p=[0-9a-f-]{36})?$/

const remember = async (user: User, path: string) => {
	if (user.last_tab === path || !KEEP.test(path)) return
	try {
		await saveTab(user.id, path)
	} catch {}
}

const padLeft = (d: PadData): PadLeft => ({
	projects: d.spaces
		.map((x) => {
			const es = d.entries.filter((e) => e.space === x.id && (e.kind === "task" || e.kind === "done"))
			return { id: x.id, title: x.title, color: x.color, left: es.filter((e) => e.kind === "task").length, total: es.length }
		})
		.filter((x) => x.left > 0),
	home: (() => {
		const es = d.entries.filter((e) => !e.space && (e.kind === "task" || e.kind === "done"))
		return { left: es.filter((e) => e.kind === "task").length, total: es.length }
	})(),
})

const page = (path: string, parts: Part[], render: (s: State) => RemixNode) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	await remember(user, path)
	return ctx.render(render(await loadState(user, parts, { back: path, error: takeError(ctx) })))
}

const padPage = (tab: PadTab) => async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	const url = new URL(ctx.request.url)
	const q = url.searchParams
	const p = q.get("p") ?? ""
	await remember(user, `${url.pathname}${p ? `?p=${p}` : ""}`)
	const d = await loadPad(user.id, p)
	return ctx.render(<PadScreen u={user} d={d} tab={tab} f={q.get("f") ?? ""} error={takeError(ctx)} />)
}

const homePage = async (ctx: Ctx) => {
	const user = userOf(ctx)
	if (!user) return go("/login")
	await remember(user, "/home")
	const [s, d] = await Promise.all([
		loadState(user, ["today", "sources", "names", "incnames", "debts", "goals", "balance", "trading"], { back: "/home", error: takeError(ctx) }),
		loadPad(user.id, ""),
	])
	return ctx.render(<HomeScreen s={s} p={padLeft(d)} />)
}

export default createController(routes.pages, {
	actions: {
		root: (ctx: Ctx) => {
			const user = userOf(ctx)
			if (!user) return go("/login")
			return go(KEEP.test(user.last_tab) ? user.last_tab : "/home")
		},
		home: homePage,
		debts: page("/debts", ["debts", "goals", "balance"], (s) => <DebtsScreen s={s} />),
		goals: page("/goals", ["goals", "debts", "balance"], (s) => <GoalsScreen s={s} />),
		plan: page("/plan", ["goals", "debts", "sources", "today", "balance"], (s) => <GoalsScreen s={s} />),
		income: page("/income", ["sources", "today", "invoice"], (s) => <IncomeScreen s={s} />),
		history: page("/history", ["history"], (s) => <HistoryScreen s={s} />),
		profile: page("/profile", ["avatar", "balance"], (s) => <ProfileScreen s={s} />),
		profileEdit: page("/profile/edit", ["avatar", "balance"], (s) => <ProfileEditScreen s={s} />),
		settings: page("/settings", ["balance"], (s) => <SettingsScreen s={s} />),
		pad: padPage("projects"),
		padSaid: padPage("said"),
		padHome: padPage("home"),
		padNew: padPage("new"),
		padProject: padPage("edit"),
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
MT_EOF
mkdir -p app/db
cat > app/db/tables.ts <<'MT_EOF'
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
		day_start: c.integer(),
		week_start: c.varchar(16),
		bg_mode: c.varchar(8),
		bg_url: c.varchar(2048),
		usd_rate_minor: c.integer(),
		usdt_rate_minor: c.integer(),
		last_tab: c.varchar(80),
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
		updated_at: c.integer(),
		last_delta: c.integer(),
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

export const padSpaces = table({
	name: "pad_spaces",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		kind: c.varchar(16),
		title: c.varchar(120),
		sub: c.varchar(500),
		sort: c.integer(),
		archived_at: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})

export const padEntries = table({
	name: "pad_entries",
	columns: {
		id: c.varchar(36),
		user_id: c.varchar(36),
		space_id: c.varchar(36),
		kind: c.varchar(16),
		body: c.varchar(2000),
		ref: c.varchar(500),
		on_home: c.integer(),
		created_at: c.integer(),
		updated_at: c.integer(),
	},
})
MT_EOF
mkdir -p app/lib
cat > app/lib/actions.ts <<'MT_EOF'
import { sql } from "remix/data-table"
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, people, purchases } from "../db/index.ts"
import { balanceOf } from "./data.ts"
import { fmt, toMinor, toSigned } from "./money.ts"
import { todayFor } from "./users.ts"
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

const pickDay = (f: FormData, t: string) => {
	const d = text(f.get("day"), 10) || t
	return realDay(d) && d <= t ? d : null
}

const own = (f: FormData, key = "id", max = 36) => text(f.get(key), max)

export async function addBuy(uid: string, f: FormData): Result {
	const unit = toMinor(f.get("price"))
	if (!unit) return "Enter a price"
	const day = pickDay(f, await todayFor(uid))
	if (!day) return "Pick a day that is not in the future"
	const qty = count(f.get("qty")) || 1
	await db.create(purchases, { id: id(), user_id: uid, name: text(f.get("label"), 120) || "Item", qty, unit_minor: unit, total_minor: unit * qty, day, created_at: Date.now() })
}

export async function addDayIncome(uid: string, f: FormData): Result {
	const amount = toMinor(f.get("amount"))
	if (!amount) return "Enter an amount"
	const day = pickDay(f, await todayFor(uid))
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
	const t = await todayFor(uid)
	if (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: t, created_at: now, meta: '{"adjust":1}', ext_key: "" })
	else await db.create(purchases, { id: id(), user_id: uid, name: "Balance adjustment", qty: 1, unit_minor: -diff, total_minor: -diff, day: t, created_at: now })
}

export async function deleteBuy(uid: string, f: FormData): Result {
	const p = await db.findOne(purchases, { where: { id: own(f), user_id: uid } })
	if (!p) return
	await db.transaction(async (tx) => {
		if (p.debt_id) {
			const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } })
			const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor
			const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } })
			if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back, updated_at: Date.now(), last_delta: back })
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
			await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n, updated_at: Date.now(), last_delta: n })
		} else {
			const m = toMinor(f.get("amount"))
			if (!m) return "Enter an amount"
			await db.update(debts, d.id, { amount_minor: d.amount_minor + m, updated_at: Date.now(), last_delta: m })
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
			if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money, updated_at: Date.now(), last_delta: money })
			else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, updated_at: Date.now(), last_delta: money, created_at: Date.now() })
		}
		if (cig) {
			const row = mine.find((d) => d.kind === "item")
			if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig, updated_at: Date.now(), last_delta: cig })
			else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "item", item_name: "cig", item_qty: cig, amount_minor: 0, updated_at: Date.now(), last_delta: cig, created_at: Date.now() })
		}
	})
}

export async function clearDebt(uid: string, f: FormData) {
	const d = await db.findOne(debts, { where: { id: own(f, "debt_id"), user_id: uid } })
	if (d) await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0, updated_at: Date.now(), last_delta: -(d.item_qty ?? 0) } : { amount_minor: 0, updated_at: Date.now(), last_delta: -d.amount_minor })
}

export async function payDebt(uid: string, f: FormData): Result {
	const d = await db.findOne(debts, { where: { id: own(f, "debt_id"), user_id: uid } })
	if (!d) return
	if (d.kind === "item") {
		const n = Math.min(count(f.get("amount")), d.item_qty ?? 0)
		if (!n) return "Enter an amount"
		await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n, updated_at: Date.now(), last_delta: -n })
		return
	}
	const pay = Math.min(toMinor(f.get("amount")), d.amount_minor)
	if (!pay) return "Enter an amount"
	const person = await db.find(people, d.person_id)
	const purchaseId = id()
	const now = Date.now()
	const t = await todayFor(uid)
	await db.transaction(async (tx) => {
		await tx.create(purchases, { id: purchaseId, user_id: uid, name: `Paid ${person?.name ?? ""}`.trim(), qty: 1, unit_minor: pay, total_minor: pay, day: t, debt_id: d.id, created_at: now })
		await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now })
		await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay, updated_at: now, last_delta: -pay })
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
	const t = await todayFor(uid)
	const bal = await balanceOf(uid)
	if (it.price_minor > bal) return `Not enough balance for ${it.name}. You have ${fmt(Math.max(0, bal))}`
	await db.transaction(async (tx) => {
		await tx.create(purchases, { id: id(), user_id: uid, name: it.name, qty: 1, unit_minor: it.price_minor, total_minor: it.price_minor, day: t, created_at: Date.now() })
		await tx.update(goalItems, it.id, { done_at: Date.now() })
	})
}

export async function addIncome(uid: string, f: FormData): Result {
	const s = await db.findOne(incomeSources, { where: { id: own(f, "source_id"), user_id: uid } })
	if (!s) return "Unknown source"
	if (s.type === "exoclick") return "ExoClick income is added automatically"
	const day = await todayFor(uid)
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
	if (row.ext_key.startsWith("trade:")) return "Undo this from the Predict page"
	if (row.ext_key) {
		const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null
		if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead"
	}
	await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } })
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
			sql`delete from pad_entries where user_id = ${uid}`,
			sql`delete from pad_spaces where user_id = ${uid}`,
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
MT_EOF
mkdir -p app/lib
cat > app/lib/data.ts <<'MT_EOF'
import { sql } from "remix/data-table"
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, people, purchases } from "../db/index.ts"
import { settleAuto } from "./auto.ts"
import { exoStatus, latestInvoice, liveExo, settleExo, type Invoice } from "./exoclick.ts"
import type { TradeSession } from "./trade-math.ts"
import { loadTrades } from "./trading.ts"
import { addDays, dayLabel, today } from "./time.ts"
import { getActiveAvatar, type User } from "./users.ts"
import { parseJson, rowsOf, type Json } from "./util.ts"

export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number }
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; hours: number; locked: boolean }
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number }
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number; at: number; delta: number }
export type GoalItem = { id: string; name: string; price: number; done: boolean }
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] }
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] }
export type Part = "today" | "sources" | "debts" | "goals" | "history" | "balance" | "avatar" | "invoice" | "names" | "incnames" | "trading"

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
	days: DayRow[]
	balance: number
	invoice: Invoice | null
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
				at: d.updated_at || d.created_at,
				delta: d.last_delta || 0,
			}
		})
		.filter((d) => d.owed > 0)
		.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1))
}

export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
	const need = new Set(parts)
	const uid = user.id
	const t = today(user.day_start)
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
		days: [],
		balance: 0,
		invoice: null,
	}

	const needSources = need.has("sources") || need.has("today") || need.has("history")
	if (needSources || need.has("balance")) await settleAll(uid)

	const jobs: Promise<void>[] = []
	if (need.has("invoice")) jobs.push(latestInvoice(uid).then((v) => void (s.invoice = v)))
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
						label: dayLabel(day, t),
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
MT_EOF
mkdir -p app/lib
cat > app/lib/time.ts <<'MT_EOF'
const TZ = "Africa/Casablanca"

const dayFmt = new Intl.DateTimeFormat("en-CA", { timeZone: TZ, year: "numeric", month: "2-digit", day: "2-digit" })
const timeFmt = new Intl.DateTimeFormat("en-GB", { timeZone: TZ, hour: "2-digit", minute: "2-digit" })

export const dayOf = (ms: number, h = 0) => dayFmt.format(ms - h * 3600000)
export const today = (h = 0) => dayOf(Date.now(), h)
export const hhmm = (ms: number, h = 0) => timeFmt.format(ms - h * 3600000)

export function addDays(day: string, n: number) {
	const d = new Date(`${day}T12:00:00Z`)
	d.setUTCDate(d.getUTCDate() + n)
	return d.toISOString().slice(0, 10)
}

export function dayLabel(day: string, t = today()) {
	if (day === t) return "Today"
	if (day === addDays(t, -1)) return "Yesterday"
	return new Date(`${day}T12:00:00Z`).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" }).replace(",", "")
}

export function timeAgo(ms: number) {
	const s = Math.max(0, Math.floor((Date.now() - ms) / 1000))
	if (s < 60) return "just now"
	const m = Math.floor(s / 60)
	if (m < 60) return `${m} min ago`
	const h = Math.floor(m / 60)
	if (h < 24) return `${h}h ago`
	const d = Math.floor(h / 24)
	if (d < 30) return d === 1 ? "1 day ago" : `${d} days ago`
	const mo = Math.floor(d / 30)
	if (mo < 12) return mo === 1 ? "1 month ago" : `${mo} months ago`
	const y = Math.floor(d / 365)
	return y === 1 ? "1 year ago" : `${y} years ago`
}

const part = (locale: string, options: Intl.DateTimeFormatOptions, now: Date) => new Intl.DateTimeFormat(locale, { timeZone: TZ, ...options }).format(now)

export function dateParts() {
	const now = new Date()
	return {
		weekday: part("en-GB", { weekday: "short" }, now),
		day: part("en-GB", { day: "numeric" }, now),
		month: part("en-GB", { month: "short" }, now),
	}
}

export function liveClockNow() {
	const now = new Date()
	return {
		timeStr: part("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false }, now),
		dateStr: part("en-GB", { weekday: "long", day: "numeric", month: "long" }, now),
		numDate: part("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" }, now),
		arabicDay: part("ar-MA", { weekday: "long" }, now),
	}
}
MT_EOF
mkdir -p app/lib
cat > app/lib/trade-math.ts <<'MT_EOF'
export const FIVE = 1600
export const GAME = 400
export const GAMES = 2
export const DEPOSIT = FIVE + GAME * GAMES
export const TRIES = 2

export type GameKey = "ga" | "gb"
export type Game = "step" | "res" | GameKey
export type Kind = "won" | "lost" | "miss" | "skip"
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

export type Flow = {
	tryNo: number
	base: number
	left: number
	stakes: number[]
	won: boolean
	over: boolean
	stop: boolean
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const resOf = (r: TradeResult[]) => r.filter((x) => x.game === "res" && isDone(x)).sort((a, b) => a.idx - b.idx)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const kindOf = (x: TradeResult): Kind => (x.asset === "skip" ? "skip" : x.won ? "won" : x.tf <= 0 || 0 - x.pnl >= x.tf ? "miss" : "lost")
export const letter = (x: TradeResult) => ({ won: "W", lost: "L", miss: "M", skip: "S" })[kindOf(x)]
export const word = (x: TradeResult) => ({ won: "Won", lost: "Lost", miss: "Miss", skip: "Skipped" })[kindOf(x)]
export const hasGames = (deposit: number) => deposit > FIVE
export const gameOf = (r: TradeResult[], g: GameKey) => r.find((x) => x.game === g && isDone(x))
export const gamesDone = (r: TradeResult[]) => !!gameOf(r, "ga") && !!gameOf(r, "gb")
export const gamesStrip = (r: TradeResult[]) => (["ga", "gb"] as const).map((g) => { const x = gameOf(r, g); return x ? letter(x) : "-" }).join(" ")

export const stakesFor = (base: number) => {
	const a = Math.round(base / 4)
	return [a, a, base - 2 * a]
}

export function flowOf(deposit: number, rows: TradeResult[]): Flow {
	const res = resOf(rows)
	const won = res.some((x) => x.won)
	const left = Math.min(deposit, FIVE) + res.reduce((a, x) => a + x.pnl, 0)
	const over = won || res.length >= TRIES || (res.length > 0 && left <= 0)
	const tryNo = Math.min(res.length + 1, TRIES)
	return {
		tryNo,
		base: left,
		left,
		stakes: stakesFor(left),
		won,
		over,
		stop: over && !won,
	}
}

export const allDone = (deposit: number, rows: TradeResult[]) => flowOf(deposit, rows).over && (!hasGames(deposit) || gamesDone(rows))
MT_EOF
mkdir -p app
cat > app/routes.ts <<'MT_EOF'
import { get, post, route } from "remix/routes"

export const routes = route({
	pages: {
		root: get("/"),
		home: get("/home"),
		debts: get("/debts"),
		goals: get("/goals"),
		pad: get("/pad"),
		padSaid: get("/pad/said"),
		padHome: get("/pad/home"),
		padNew: get("/pad/new"),
		padProject: get("/pad/project"),
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
		tradeResult: post("/trading/result"),
		tradeGame: post("/trading/game"),
		tradeUndo: post("/trading/undo"),
		tradeFinish: post("/trading/finish"),
		tradeReopen: post("/trading/reopen"),
		saveProfile: post("/profile/edit"),
		saveSettings: post("/settings"),
		setTheme: post("/settings/theme"),
		padAddSpace: post("/pad/space"),
		padDelSpace: post("/pad/space/delete"),
		padEditSpace: post("/pad/space/edit"),
		padAdd: post("/pad/add"),
		padToggle: post("/pad/toggle"),
		padDel: post("/pad/delete"),
		padEdit: post("/pad/edit"),
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
		authCss: get("/assets/auth.css"),
	},
})
MT_EOF
mkdir -p app
cat > app/screens.tsx <<'MT_EOF'
import { BuysDesktop, BuysExpand, Hero } from "./components/buys.tsx"
import { OweDesktop, OweMobile, RoadCard } from "./components/debts.tsx"
import { GoalsExpand } from "./components/goals.tsx"
import { HistoryDesktop, HistoryMobile } from "./components/history.tsx"
import { HomePredict, HomeTasks, HomeToday, type PadLeft } from "./components/home.tsx"
import { HomeIncome, IncomeDesktop, IncomeExpand, InvoiceCard } from "./components/income.tsx"
import { BalanceCard } from "./components/balancecard.tsx"
import { DateCard } from "./components/datecard.tsx"
import { AppLayout, AuthLayout } from "./components/layout.tsx"
import { PadBody, PadComposer, type PadTab } from "./components/pad.tsx"
import type { PadData } from "./lib/padmeta.ts"
import type { User } from "./lib/users.ts"
import { EditProfileMobile, ProfileMobile, SettingsDesktop, SettingsMobile } from "./components/profile.tsx"
import { TradingBody } from "./components/trading.tsx"
import { ErrorBanner, FloatField, GoogleMark, Logo, PageHeader, Section, Submit, view } from "./components/ui.tsx"
import type { State } from "./lib/data.ts"
import { fmt } from "./lib/money.ts"
import { calc } from "./lib/view.ts"

export const HomeScreen = view<{ s: State; p: PadLeft }>(({ s, p }) => (
	<AppLayout
		title="Home"
		theme={s.user.theme}
		mobileTab="home"
		desktopTab="home"
		mobile={
			<div class="hm hm-f">
				<ErrorBanner s={s} />
				<div class="hm-top">
					<BalanceCard s={s} />
					<DateCard />
				</div>
				<HomeToday s={s} />
				<HomePredict s={s} />
				<HomeTasks p={p} />
				<HomeIncome s={s} />
				<BuysExpand s={s} />
				<GoalsExpand s={s} open={false} storeKey="goals" manage={false} />
				<OweMobile s={s} open={false} storeKey="owe" />
			</div>
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
						<IncomeDesktop s={s} bare />
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
					<OweMobile s={s} open storeKey="owe-page" manage />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Debts" right={`${fmt(c.oweMoney)} ${s.user.currency} ${c.oweExtra}`} />
					<div class="g3">
						<div>
							<OweDesktop s={s} open storeKey="owe-page" manage />
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
					<InvoiceCard s={s} />
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
					<InvoiceCard s={s} />
<IncomeExpand s={s} />
				</>
			}
		/>
	)
})

export const PadScreen = view<{ u: User; d: PadData; tab: PadTab; f: string; error: string }>(({ u, d, tab, f, error }) => (
	<AppLayout
		title="Pad"
		theme={u.theme}
		mobileTab="pad"
		desktopTab="pad"
		mobile={<PadBody d={d} tab={tab} f={f} error={error} />}
		dock={<PadComposer d={d} tab={tab} f={f} />}
		desktop={
			<div class="chat">
				<PadBody d={d} tab={tab} f={f} error={error} />
				<PadComposer d={d} tab={tab} f={f} />
			</div>
		}
	/>
))

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
			title="Predict"
			theme={s.user.theme}
			mobileTab="trading"
			desktopTab="trading"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Predict" right={right} />
					<TradingBody s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Predict" right={right} />
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
				<Submit class="btn full">{up ? "Create account" : "Sign in"}</Submit>
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
MT_EOF
mkdir -p database
cat > database/schema.sql <<'MT_EOF'
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
  last_tab      TEXT NOT NULL DEFAULT '',
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
  updated_at    INTEGER NOT NULL DEFAULT 0,
  last_delta    INTEGER NOT NULL DEFAULT 0,
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

CREATE TABLE IF NOT EXISTS pad_spaces (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL,
  title         TEXT NOT NULL,
  sub           TEXT NOT NULL DEFAULT '',
  sort          INTEGER NOT NULL DEFAULT 0,
  archived_at   INTEGER,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS pad_spaces_list_idx ON pad_spaces(user_id, kind, archived_at, sort);
CREATE UNIQUE INDEX IF NOT EXISTS pad_spaces_title_uq ON pad_spaces(user_id, kind, lower(title));

CREATE TABLE IF NOT EXISTS pad_entries (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  space_id      TEXT REFERENCES pad_spaces(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL,
  body          TEXT NOT NULL,
  ref           TEXT NOT NULL DEFAULT '',
  on_home       INTEGER NOT NULL DEFAULT 0,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS pad_entries_space_idx ON pad_entries(space_id, created_at DESC);
CREATE INDEX IF NOT EXISTS pad_entries_kind_idx ON pad_entries(user_id, kind, created_at DESC);
CREATE INDEX IF NOT EXISTS pad_entries_home_idx ON pad_entries(user_id, created_at DESC) WHERE on_home = 1;
MT_EOF
mkdir -p scripts
cat > scripts/migrate.ts <<'MT_EOF'
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
	"ALTER TABLE users ADD COLUMN day_start INTEGER NOT NULL DEFAULT 5",
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
	"ALTER TABLE users ADD COLUMN last_tab TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE trade_results ADD COLUMN state TEXT NOT NULL DEFAULT 'done'",
	"ALTER TABLE trade_results ADD COLUMN asset TEXT NOT NULL DEFAULT ''",
	"ALTER TABLE trade_results ADD COLUMN tf INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE debts ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0",
	"ALTER TABLE debts ADD COLUMN last_delta INTEGER NOT NULL DEFAULT 0",
]
for (const statement of addColumns) {
	try {
		await client.execute(statement)
		console.log("added:", statement)
	} catch (err) {
		if (!/duplicate column/i.test(String(err))) throw err
	}
}

await client.execute("UPDATE users SET day_start = 5 WHERE day_start = 17")
await client.execute(`UPDATE incomes SET meta = replace(meta, '"name":"Trading"', '"name":"Predict"') WHERE ext_key LIKE 'trade:%'`)
await client.execute("CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_key_idx ON incomes(ext_key) WHERE ext_key <> ''")
await client.execute("INSERT INTO goal_items (id, user_id, goal_id, name, price_minor, done_at, created_at) SELECT lower(hex(randomblob(16))), user_id, id, title, target_minor, NULL, created_at FROM goals g WHERE target_minor > 0 AND NOT EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = g.id)")
await client.execute("UPDATE goals SET target_minor = 0 WHERE target_minor > 0 AND EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = goals.id)")

await client.execute("DROP TABLE IF EXISTS notes")

const { rows } = await client.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
console.log("tables:", rows.map((r) => r.name).join(", "))
client.close()
MT_EOF
