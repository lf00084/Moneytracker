#!/bin/bash
set -e
cd "$(dirname "$0")"
[ -f app/client/app.css ] && [ -f app/components/income.tsx ] || { echo "run this inside the Moneytracker folder"; exit 1; }
cat > app/client/app.css << 'EOF'
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
.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
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
.earn-top{display:flex;flex-direction:column;gap:3px;min-width:0}
.earn-top .lb{font-size:11px}
.earn-top b{font-size:20px;font-weight:700;letter-spacing:-.04em;line-height:1;white-space:nowrap}
.earn-top small,.rt b small{font-size:11px;color:var(--mu);font-weight:400;letter-spacing:0;margin-left:3px}
.xbare .xb{border-top:0;padding:8px 16px 6px}
.addrow{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:11px 14px;border:1px dashed var(--acl);border-radius:var(--rm);background:var(--acs);color:var(--ac);font-weight:600;font-size:13px}
.addrow svg.ic{width:18px;height:18px;stroke-width:2;transition:transform .18s ease}
.addrow.on svg.ic{transform:rotate(45deg)}
.incbare{padding:6px 22px 18px}
.incbare .addrow{margin-top:12px}
details[data-fixed]>.xh{cursor:default;padding-right:70px}
.dn .dl{margin:-2px 0 8px;font-size:11px;line-height:1.3}
.mm>.cd .big2{font-size:24px}
.mm .two .big2{font-size:20px}
.mm .xbare .xb{padding:2px 14px}
.hr{display:grid;grid-template-columns:minmax(0,1fr) auto 32px;column-gap:10px;align-items:center;padding:9px 0}
.hn{min-width:0;font-size:15px}
.hr .ea{white-space:nowrap;text-align:right;font-size:15px}
.hr .ub{width:32px;height:32px;border-radius:12px;background:var(--s2)}
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

.app:has(.nt-page) .tsplit .clock-time{display:none}
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
.hm .btn.xs.hadd{height:30px;min-height:30px;padding:0 14px;border-radius:15px;font-size:13px;align-self:center;justify-self:end}
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
.bt{box-shadow:var(--sh1)}

/* header icons centered inside the summary */
.hm .xp{top:50%;margin-top:-19px;right:14px}
.hm .xc:has(details[data-fixed]) .xp{top:50%}
.hm .xc .chev{top:50%;margin-top:-11px}
.hm .xc:has(.xp.on) .chev{display:none}
.hm details[data-fixed]>.xh{padding:9px 70px 9px 16px}
.hm .xb:empty{display:none}
.hm .osum .ow .em{font:400 14px/1.4 var(--h-sans);color:var(--h-mu)}

/* balance card (home + profile) */
.hm-bal{column-gap:0;grid-template-columns:1fr auto auto;grid-template-areas:"l e b" "v e b"}
.hm-bal .ib{margin-left:10px}
.hm-bal .lnk{grid-area:e;align-self:center;margin-left:10px}
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
.nt-toast{position:fixed;left:50%;bottom:96px;transform:translateX(-50%);background:var(--h-ink);color:var(--h-card);padding:8px 16px;border-radius:18px;font-size:13px;z-index:60}
EOF
cat > app/components/income.tsx << 'EOF'
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
			<b class="ea">
				+{fmt(i.amount)} <small>{s.user.currency}</small>
			</b>
			<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} ${s.user.currency} from ${i.source}?`}>
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
	const cur = s.user.currency
	const opts = [1, 2, 3, 4]
	return (
		<details class="hx" data-keep-open={`hx-${x.id}-${row.day}`}>
			<summary>
				<span>Extra hours</span>
				<span>{h ? `+${h}h · +${fmt(Math.round(h * rate))} ${cur}` : `${fmt(rate)} ${cur} / hour`}</span>
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

const HomeAct = view<{ s: State; x: Source }>(({ s, x }) => {
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
				{amt(sum)}
				<span></span>
			</>
		)
	}
	if (x.mode === "auto") {
		return (
			<>
				{amt(x.amount)}
				<span></span>
			</>
		)
	}
	if (got.length) {
		return (
			<>
				{amt(sum)}
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} ${cur} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="revert" />
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
				<button class="btn xs o hspan">
					Add {fmt(fixed)} {cur}
				</button>
			</form>
		)
	}
	return (
		<button type="button" class="btn xs o hspan hadd" data-tg>
			Add
		</button>
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
	const all = gotToday(s, x)
	const got = fixedSrc ? all[0] : undefined
	const cur = s.user.currency
	const exo = x.type === "exoclick"
	const sub = exo ? exoSub(s, x) : fixedSrc ? (got ? `${fmt(srcAmount(x))} ${cur}${got.hours ? ` + ${got.hours}h` : ""}` : `${fmt(srcAmount(x))} ${cur} + ${fmt(rateOf(x))} / hour`) : ""
	const manual = !fixedSrc && !exo && x.mode !== "auto" && !all.length
	return (
		<div class="sw dbw" data-exo={exo ? "1" : undefined}>
			<div class="hr">
				<div class="hn">
					<div>{x.name}</div>
					{sub ? <div class={exo && s.exo[x.id] ? "lb neg" : "lb"}>{sub}</div> : null}
					{exo && s.exo[x.id] ? (
						<a class="lnk" href="/income">
							Fix
						</a>
					) : null}
				</div>
				<HomeAct s={s} x={x} />
			</div>
			{manual ? (
				<form method="post" action="/income/add" class="ad" data-addp hidden>
					<Back s={s} />
					<input type="hidden" name="source_id" value={x.id} />
					<div class="ln">
						<input class="in" name="amount" placeholder="Amount today" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs">Add</button>
					</div>
				</form>
			) : null}
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

const TodayRows = view<{ s: State }>(({ s }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	return sources.length || others.length ? (
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
	)
})

export const IncomeDesktop = view<{ s: State; title?: string; id?: string; bare?: boolean }>(({ s, title = "Income today", id = "f-inc-d", bare = false }) => {
	const sources = s.sources.filter((x) => x.active)
	const others = s.incomesToday.filter((i) => !i.sourceId)
	if (bare) {
		return (
			<div class="sc incbare">
				<TodayRows s={s} />
			</div>
		)
	}
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

export const InvoiceCard = view<{ s: State }>(({ s }) => {
	const v = s.invoice
	if (!v) return null
	const label = v.status === "paid" ? "Paid" : v.status === "processing" ? "Processing" : "Pending"
	const sub = v.status === "paid" ? (v.paid ? `paid ${v.paid}` : "paid") : v.due ? `due ${v.due}` : v.date ? `issued ${v.date}` : ""
	return (
		<div class="hm-c inv" data-inv={`${v.id}:${v.status}`}>
			<div>
				<div class="hm-m">{`ExoClick invoice${v.period ? ` · ${v.period}` : ""}`}</div>
				<div class="inv-a">{`$${v.usd.toFixed(2)}`}</div>
				{sub ? <div class="hm-m">{sub}</div> : null}
			</div>
			<span class={`inv-st ${v.status}`}>{label}</span>
			<button type="button" class="ub" data-inv-x aria-label="Close">
				<Icon name="plus" />
			</button>
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

export const HomeIncome = view<{ s: State }>(({ s }) => (
	<div class="xc xbare">
		<div class="xb">
			<TodayRows s={s} />
		</div>
	</div>
))
EOF
echo done
