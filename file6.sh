#!/usr/bin/env bash
set -e
cd "${1:-.}"
mkdir -p "app/client"
cat > app/client/app.css << '__EOF_MT__'
html{--bg:#13181b;--s1:#1b2125;--s2:#242b30;--ln:rgba(255,255,255,0.09);--ink:#e8edf0;--mu:#8b979e;--ac:#6fb7c4;--acs:rgba(111,183,196,0.16);--acl:rgba(111,183,196,0.5);--on:#0f1417;--pos:#4cc38a;--neg:#ff6b5e;--earn:#f2b84b;--spend:#a894ff;--sps:rgba(168,148,255,0.16);--spl:rgba(168,148,255,0.5);--bub:rgba(111,183,196,0.14);--sh1:none;--rc:20px;--rm:12px;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,'SF Pro Text','SF Pro Display',system-ui,sans-serif;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#f4f4f5;--s1:#fff;--s2:#eef0f1;--ln:rgba(60,70,90,0.12);--ink:#3f4655;--mu:#8a909c;--ac:#4d8490;--acs:#d5f2f5;--acl:#8fd3db;--on:#fff;--pos:#12a150;--neg:#e0382b;--earn:#a66a00;--spend:#6d4fd6;--sps:#ece8ff;--spl:#bfb2f5;--bub:#d5f2f5;--sh1:0 1px 3px rgba(20,30,40,0.08)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ac);outline-offset:2px}
::selection{background:var(--acs);color:var(--ink)}
[hidden]{display:none!important}

/* one look for every surface: login box, cards, hero. Radius and shadow come from the tokens on html. */
.cd,.sc,.xc,.hero,.auth-glass-box{background:var(--s1);border:1px solid var(--ln);border-radius:var(--rc);box-shadow:var(--sh1)}
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
.tf-clock .clock-date,.tf-clock .clock-subdate{display:none}

.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;padding:38px 32px 34px}
@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px}}
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
.ib{flex:none;aspect-ratio:1}.ib.sm{width:28px;height:28px;min-width:28px}.ib svg.ic{width:16px;height:16px}.ib.hi{background:var(--acs);color:var(--ac);border-color:var(--acl)}

.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);border-radius:var(--rc) var(--rc) 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
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
.sb .sp{flex:1}

h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}

.cd{margin-top:14px}
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

.btn{font-weight:600;font-size:14px;background:var(--ac);color:var(--on);border:1px solid var(--ac);border-radius:var(--rm);padding:11px 20px;flex:none;display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center}
.btn:hover{filter:brightness(1.06)}
.btn.o{background:var(--s1);color:var(--ink);border:1px solid var(--ln);box-shadow:var(--sh1)}
.btn.dng{background:rgba(255,90,77,0.12);color:var(--neg);border:1px solid rgba(255,90,77,0.35)}
.btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
.btn.full{width:100%;padding:14px 20px;font-size:16px;font-weight:700;border-radius:var(--rm);margin-top:20px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:600;color:var(--mu);margin-bottom:6px;letter-spacing:.02em}

.in{width:100%;min-width:0;background:var(--bg);border:1px solid var(--ln);border-radius:var(--rm);padding:13px 16px;outline:0;color:var(--ink);font-size:15px;font-family:inherit}
.in:focus,.in.f:focus{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.in::placeholder{color:var(--mu);opacity:.6}
.ln{display:flex;gap:10px;align-items:center}

.stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
.stp button{width:34px;height:34px;border:1px solid var(--ln);background:var(--s1);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;color:var(--ink)}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:13px 18px;border-radius:var(--rm);border:1px solid var(--ln);background:var(--s1);box-shadow:var(--sh1);font-weight:600;font-size:14px;color:var(--ink)}
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

.hero{display:grid;grid-template-columns:repeat(4,1fr);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;padding:18px 22px 20px}
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
.gbtn:hover{background:var(--s2)}
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
details.dd>summary{padding:14px 16px;display:block;position:relative}
details.dd[open]>summary{padding-bottom:4px}
details.dd>.cb{padding-top:6px}
details.dd .chev{position:absolute;right:16px;top:14px}
.sc.bgc summary.sh{cursor:pointer}
.wi{padding:12px 0;border-top:1px solid var(--ln)}
.wi:first-child{border-top:0;padding-top:0}
.wa{display:flex;gap:8px;justify-content:flex-end;align-items:center;margin-top:10px}
.l1{gap:12px}.l1>b{min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.l1>span,.l1>.sp,.ow>*,.by>b,.rw>b,.by .rt b,.rw .rt b,.big2,.v{white-space:nowrap;flex:none}
.by>div:first-child,.rw>div:first-child{min-width:0}
.rt{display:flex;align-items:center;gap:10px;flex:none}
.ub{width:30px;height:30px;border-radius:9px;border:1px solid var(--ln);background:var(--s2);color:var(--mu);display:flex;align-items:center;justify-content:center;padding:0;flex:none}
.ub:hover{color:var(--ink)}.ub svg.ic{width:16px;height:16px}
.btn:disabled,.btn.off{background:var(--s2);color:var(--mu);border-color:var(--ln);box-shadow:none;opacity:.7;cursor:not-allowed;pointer-events:none}
.tl{display:block;font-weight:400;margin-top:3px;font-size:11px;color:var(--mu);font-family:var(--mono)}
.th2>span{min-width:0}
.pnl.top{margin:0 0 12px;padding:0 0 12px;border-top:0;border-bottom:1px solid var(--ln)}
.sh .pl{margin-left:10px}
.ok{color:var(--earn)}


.mm,.pg{overflow-x:hidden;min-width:0}
.cd,.sc{overflow:hidden;min-width:0}
.dn{min-width:0}.dbw,.db{min-width:0;max-width:100%}
.ow{gap:10px;flex-wrap:wrap}
.spf{padding:14px}.sc.spf{padding:18px 22px}
.spf .ln{gap:10px;margin:0}.spf .ln .in{flex:1 1 0}.spf .ln .in.pr{flex:0 0 96px;width:96px}
.spf .btn.full{margin-top:10px}
.spf .chips.nm{margin-bottom:10px}
.addb.r{border-right:0;border-left:1px solid var(--acl)}
.jarc{position:relative}
.jar{position:absolute;left:0;top:0;bottom:0;background:var(--ac);opacity:.28;pointer-events:none;transition:width .5s ease}
.jarc .jin{position:relative;z-index:1}
.wb{display:flex;align-items:center;gap:8px;flex:none}
.srcf{margin-top:14px}.srcf .ln{gap:10px}.srcf .in.pr{flex:0 0 96px;width:96px}.srcf .btn.full{margin-top:10px}
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
.xfm .ln{gap:10px;margin:0}.xfm .ln .in{flex:1 1 0;margin:0}.xfm .ln .in.pr{flex:0 0 96px;width:96px}.xfm .btn.full{margin-top:10px}
.gw{padding-bottom:6px;border-bottom:1px solid var(--ln)}.gw:last-child{border-bottom:0}.gw .db{border-bottom:0;padding:12px 0 6px}
.gi{display:flex;align-items:center;gap:10px;padding:7px 0 7px 12px;margin-left:13px;border-left:2px solid var(--ln)}
.gn{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-size:14px}
.gi .lb{white-space:nowrap;flex:none}
.gdone .gn{text-decoration:line-through;opacity:.55}
.ad .ln .in{flex:1 1 0;min-width:0}.ad .ln .in.pr2{flex:0 0 84px;width:84px}
.xj{position:absolute;left:0;top:0;bottom:0;background:var(--mu);opacity:.2;pointer-events:none;transition:width .5s ease,background .3s ease,opacity .3s ease}
.xj.full{background:var(--ac);opacity:.32}
.xh>div,.xh .chev{position:relative;z-index:1}
.xc .chev{position:absolute}
.xn .xh{padding-right:48px}.xn .chev{right:16px}
.gw .mt i{background:var(--mu);transition:width .5s ease,background .3s ease}.gw .mt.full i{background:var(--ac)}
.clock-time{font-family:'Geist',var(--font-sys);font-weight:600;font-size:26px;letter-spacing:-.04em;font-variant-numeric:tabular-nums}
.clock-date,.clock-subdate,.clock-num,.clock-ar,.clock-dot{font-size:14px;line-height:1.3;font-weight:500;letter-spacing:0}
.clock-date,.clock-subdate{opacity:1;color:var(--mu)}
.clock-date,.clock-num{font-family:'Geist',var(--font-sys);font-variant-numeric:tabular-nums}
.clock-ar{font-family:'Noto Sans Arabic','Geeza Pro','Segoe UI Arabic',system-ui,sans-serif}
.clock-subdate{gap:6px;margin-top:4px}
.top-status-bar.tsplit .clock-time{font-size:16px;font-weight:600;letter-spacing:-.01em;color:var(--ink)}
.top-status-bar.tsplit .clock-subdate,.top-status-bar.tsplit .clock-num,.top-status-bar.tsplit .clock-ar,.top-status-bar.tsplit .clock-dot{font-size:16px;font-weight:600;margin-top:0}
.xo{padding:0;border:0;background:none}.xo>form{margin:0;padding:12px 16px 14px;border-top:1px solid var(--ln);background:var(--s2)}
.iw{flex:1 1 0;min-width:0;display:flex;align-items:center;gap:10px;background:var(--bg);border:1px solid var(--ln);border-radius:12px;padding:0 14px;transition:border-color .12s ease,box-shadow .12s ease}
.iw:focus-within{border-color:var(--ac);box-shadow:0 0 0 3px var(--acs)}
.iw .in,.iw .in:focus{flex:1 1 0;min-width:0;width:auto;margin:0;border:0;border-radius:0;background:transparent;box-shadow:none;padding:13px 0}
.iw .mu{flex:none;font-size:12px;font-family:var(--mono)}
.iw .all{flex:none;background:none;border:0;padding:4px 2px;color:var(--ac);font-size:13px;font-weight:700;letter-spacing:.01em}
.iw .all:hover{filter:brightness(1.15)}
.sf .iw{margin-bottom:10px}
.top-status-bar.tsplit{justify-content:space-between}.top-status-bar.tsplit .live-clock{align-items:flex-start;text-align:left}.top-status-bar.tsplit .live-clock .clock-date,.top-status-bar.tsplit .live-clock .clock-subdate{display:none}
.sk{height:12px;border-radius:6px;margin:14px 0;background:linear-gradient(90deg,rgba(128,128,128,.14),rgba(128,128,128,.26),rgba(128,128,128,.14));background-size:200% 100%;animation:sk 1.2s linear infinite}
@keyframes sk{to{background-position:-200% 0}}
.nb{position:fixed;top:env(safe-area-inset-top,0px);left:0;right:0;height:3px;z-index:1000;pointer-events:none;background:linear-gradient(90deg,var(--ac),var(--acl));transform:scaleX(0);transform-origin:0 50%;opacity:0;border-radius:0 3px 3px 0}
.nb.on{opacity:1;transform:scaleX(.88);transition:transform 12s cubic-bezier(.05,.75,.1,1)}
.nb.done{opacity:0;transform:scaleX(1);transition:transform .18s ease-out,opacity .3s ease .18s}
main{transition:opacity .2s ease}
html[data-nav=busy],html[data-nav=busy] a,html[data-nav=busy] button{cursor:progress}
html[data-nav=busy] main{opacity:.55}
button[data-busy]{cursor:progress}
.btn[data-busy]{opacity:.7}
.btn[data-busy]::after{content:"";display:inline-block;width:12px;height:12px;margin-left:8px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:spin .6s linear infinite;vertical-align:-2px}
@keyframes spin{to{transform:rotate(360deg)}}
.skc{overflow:hidden}
.skc .skt{width:40%;height:14px;margin:4px 0 18px}
.toast{position:fixed;left:50%;bottom:calc(76px + env(safe-area-inset-bottom,0px));transform:translateX(-50%);max-width:min(92vw,420px);padding:11px 16px;border-radius:var(--rm);background:var(--s2);color:var(--ink);border:1px solid var(--ln);box-shadow:0 8px 24px rgba(0,0,0,.25);font-size:13px;z-index:1000;animation:toast .2s ease-out}
.toast.out{opacity:0;transition:opacity .4s}
@keyframes toast{from{opacity:0;transform:translate(-50%,8px)}}
@media(prefers-reduced-motion:reduce){.nb.on,.nb.done,main{transition:none}.sk,.btn[data-busy]::after{animation:none}}
.srw{border-bottom:1px solid var(--ln)}
.srw:last-child{border-bottom:0}
.srw>.rw{border:0;padding:12px 0}
.sc .srw>.rw{padding:14px 0}
.hrs{margin:0 0 12px;background:var(--bg);border:1px solid var(--ln);border-radius:14px;overflow:hidden}
.hrs-h{display:flex;align-items:center;gap:10px;padding:10px 14px;font-size:13px;font-weight:600}
.hrs-h .lb{flex:1;text-align:right}
.hv{display:flex;flex:none;color:var(--mu);transition:transform .18s ease}
.hrs[open] .hv{transform:rotate(180deg)}
.hrs-b{padding:0 14px 12px}
.hrs-b .chips{margin:2px 0 10px}
.hrx{gap:8px}
.hrx .in{flex:1 1 0;padding:9px 12px;font-size:14px;border-radius:12px}
.mh{display:none}
form[data-m=manual] .mh-manual,form[data-m=job] .mh-job,form[data-m=daily] .mh-daily,form[data-m=monthly] .mh-monthly{display:block}
.ln.src-job{display:none;margin-top:10px}
form[data-m=job] .ln.src-job{display:flex}
form[data-m=job] .src-amt{display:none}
.qi{margin-top:16px;padding-top:14px;border-top:1px solid var(--ln)}
.qi .chips.nm{margin:0 0 10px}
.qi .ln .in{flex:1 1 0}
.qi .ln .in.pr{flex:0 0 96px;width:96px}
.trd{max-width:640px;margin:0 auto}
.tbn{margin:2px 0 6px;line-height:1.5}
.tbr{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px 0;border-bottom:1px solid var(--ln)}
.tbr:last-child{border-bottom:0;padding-bottom:0}
.tbr.lock{opacity:.45}
.tbf{display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0}
.tbf .in{width:96px;flex:0 1 96px;min-width:0;padding:8px 10px;font-size:14px;border-radius:12px}
.btn.win{background:rgba(76,195,138,.14);color:var(--pos);border-color:rgba(76,195,138,.45)}
.btn.lose{background:rgba(255,90,77,.12);color:var(--neg);border-color:rgba(255,90,77,.4)}
.tbs{font-size:11px;font-weight:600;border:1px solid currentColor;border-radius:12px;padding:2px 9px;font-family:var(--mono)}
__EOF_MT__
mkdir -p "app/client"
cat > app/client/app.js << '__EOF_MT__'
(function(){
if(window.__mt)return;window.__mt=1;
var d=document,r=d.documentElement,nav=window.navigation;
function all(sel,root){return [].slice.call((root||d).querySelectorAll(sel))}
function money(n){return (Math.round(n*100)/100).toLocaleString('en-US')}

function setTheme(t){
  r.setAttribute('data-theme',t);
  try{localStorage.setItem('mtheme',t)}catch(e){}
  try{fetch('/settings/theme',{method:'POST',body:new URLSearchParams({theme:t}),credentials:'same-origin',redirect:'manual'})}catch(e){}
}

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

function endEdit(c){
  var id=c.querySelector('[data-eid]');if(id)id.value='';
  var eb=c.querySelector('.eb');if(eb)eb.hidden=true;
  c.querySelector('textarea').value='';
}
function tails(){
  all('[data-list]').forEach(function(L){
    var last=L.lastElementChild;
    if(L.getAttribute('data-list')!=='dash'&&last&&last.scrollIntoView)last.scrollIntoView({block:'end'});
  });
}

var open={};try{open=JSON.parse(localStorage.getItem('mt:open')||'{}')}catch(e){}
d.addEventListener('toggle',function(e){
  var x=e.target;
  if(x.matches&&x.matches('details[data-keep-open]')){
    open[x.getAttribute('data-keep-open')]=x.open;
    try{localStorage.setItem('mt:open',JSON.stringify(open))}catch(err){}
  }
  if(x.matches&&x.matches('.xd')&&!x.open){var xf=x.querySelector('[data-adp]'),xb=x.parentNode.querySelector('[data-xplus]');if(xf)xf.hidden=true;if(xb)xb.classList.remove('on')}
},true);

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
  if((q=t.closest('[data-edit-bal]'))){var bf=q.closest('.cd,.sc').querySelector('[data-balf]');bf.hidden=!bf.hidden;q.textContent=bf.hidden?'Edit balance':'Cancel';if(!bf.hidden){var bi=bf.querySelector('input:not([type=hidden])');if(bi){bi.focus();bi.select()}}return}
  if((q=t.closest('[data-all]'))){
    var af=q.closest('.iw').querySelector('input');
    af.value=q.getAttribute('data-all');af.focus();
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
    var pn=q.closest('.cd,.sc').querySelector('[data-pnl]');
    if(pn){
      pn.hidden=!pn.hidden;
      q.classList.toggle('on',!pn.hidden);
      if(!pn.hidden){var fi=pn.querySelector('input:not([type=hidden])');if(fi)fi.focus()}
    }
    return
  }
  if((q=t.closest('[data-xplus]'))){
    var xc=q.closest('.xc'),xd=xc.querySelector('details'),xm=xc.querySelector('[data-adp]');
    if(xm){
      if(!xd.open){xd.open=true;xm.hidden=false}else xm.hidden=!xm.hidden;
      q.classList.toggle('on',!xm.hidden);
      if(!xm.hidden){var xi=xm.querySelector('input:not([type=hidden])');if(xi)xi.focus()}
    }
    return
  }
  if((q=t.closest('[data-nm]'))){
    var nf=q.closest('form'),nin=nf.querySelector('[data-name]'),pin=nf.querySelector('[data-price]');
    nin.value=q.getAttribute('data-nm');
    if(pin)pin.focus();
    return
  }
  if((q=t.closest('[data-bigadd]'))){
    var tf=q.getAttribute('data-for'),ap=tf?d.getElementById(tf):q.closest('.bgc').querySelector('[data-adp]');
    ap.hidden=!ap.hidden;
    q.classList.toggle('on',!ap.hidden);
    if(!ap.hidden){var ai=ap.querySelector('input:not([type=hidden])');if(ai)ai.focus()}
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
    form.setAttribute('data-m',q.getAttribute('data-mode'));
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

d.addEventListener('click',function(e){
  var b=e.target.closest&&e.target.closest('[data-confirm-btn]');
  if(b&&!confirm(b.getAttribute('data-confirm-btn')))e.preventDefault();
},true);

d.addEventListener('submit',function(e){
  var f=e.target,msg=f.getAttribute&&f.getAttribute('data-confirm');
  if(msg&&!confirm(msg)){e.preventDefault();return}
  setTimeout(function(){if(e.defaultPrevented)return;all('button',f).forEach(function(b){if(!b.disabled){b.disabled=true;b.setAttribute('data-busy','1')}})},0);
});
function unbusy(){all('button[data-busy]').forEach(function(b){b.disabled=false;b.removeAttribute('data-busy')})}
window.addEventListener('pageshow',function(e){if(e.persisted)unbusy()});

d.addEventListener('keydown',function(e){
  if(e.key!=='Enter'||e.shiftKey)return;
  var t=e.target;
  if(t.matches&&t.matches('[data-comp] textarea')){
    e.preventDefault();
    if(t.value.trim()){var f=t.closest('form');if(f.requestSubmit)f.requestSubmit();else f.submit()}
  }
});

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

function init(){
  all('.qk4:not([data-i])').forEach(function(g){g.setAttribute('data-i','1');var first=g.querySelector('[data-q]');if(first)pick(first,false)});
  all('details[data-keep-open]:not([data-i])').forEach(function(x){x.setAttribute('data-i','1');var k=x.getAttribute('data-keep-open');if(k in open)x.open=!!open[k]});
  all('[data-bg-custom]:not([data-i])').forEach(function(el){
    el.setAttribute('data-i','1');
    var u=el.getAttribute('data-bg-custom');
    if(u){var im=new Image();im.onerror=function(){el.classList.add('bg-fallback-auto')};im.src=u}
  });
}

function toast(m){
  var t=d.createElement('div');
  t.className='toast';t.setAttribute('role','status');t.textContent=m;
  d.body.appendChild(t);
  setTimeout(function(){t.classList.add('out')},2800);
  setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t)},3300);
}

var timer=0,guard=0,dest=null;
function bar(){return d.querySelector('.nb')}
function start(){
  clearTimeout(timer);clearTimeout(guard);
  timer=setTimeout(function(){
    if(!nav.transition)return;
    var b=bar();
    if(b){b.classList.remove('done');void b.offsetWidth;b.classList.add('on')}
    r.setAttribute('data-nav','busy');
  },120);
  guard=setTimeout(finish,20000);
}
function finish(){
  clearTimeout(timer);clearTimeout(guard);
  var b=bar();
  if(b&&b.classList.contains('on')){
    b.classList.remove('on');b.classList.add('done');
    setTimeout(function(){b.classList.remove('done')},700);
  }
  r.removeAttribute('data-nav');
}
function settle(){init();tails();unbusy()}

if(nav&&nav.addEventListener){
  nav.addEventListener('navigate',function(e){
    if(!e.canIntercept||e.hashChange||e.downloadRequest)return;
    dest={url:e.destination.url,post:!!e.formData};
    start();
  });
  nav.addEventListener('navigatesuccess',function(){finish();setTimeout(settle,0)});
  nav.addEventListener('navigateerror',function(e){
    finish();unbusy();
    var err=e.error,u=dest;
    if(err&&err.name==='AbortError')return;
    if(u&&!u.post){location.assign(u.url);return}
    toast('That did not go through. Check your connection and try again.');
  });
}

var queued=0;
new MutationObserver(function(){
  if(queued)return;
  queued=1;
  requestAnimationFrame(function(){queued=0;init()});
}).observe(r,{childList:true,subtree:true});

settle();
})();
__EOF_MT__
mkdir -p "app"
cat > app/commands.ts << '__EOF_MT__'
/**
 * Every change the app can make, in one table. The form posts in `controllers/commands.ts` and
 * the JSON endpoint in `controllers/api.ts` both run these, so a command is written once.
 *
 * `run` returns an error message (a non-empty string) or nothing. `to` is where a form post goes
 * afterwards; unless `back` is false it goes to the page the form came from instead.
 */
import * as act from "./lib/actions.ts";
import { toMinor } from "./lib/money.ts";
import * as trading from "./lib/trading.ts";
import { setTheme, updatePrefs, updateProfile, type User } from "./lib/users.ts";

export type Command = {
	run: (user: User, f: FormData) => Promise<unknown>;
	to: string;
	back?: boolean;
	fail?: string;
	empty?: boolean;
};

const text = (f: FormData, key: string) => String(f.get(key) ?? "");

/** For commands whose result is never shown as an error. */
const quiet = (fn: (u: User, f: FormData) => Promise<unknown>) => async (u: User, f: FormData) => {
	await fn(u, f);
};

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
	addSource: { run: (u, f) => act.addSource(u.id, f), to: "/income" },
	addIncome: { run: (u, f) => act.addIncome(u.id, f), to: "/income" },
	deleteIncome: { run: (u, f) => act.deleteIncome(u.id, f), to: "/income" },
	toggleSource: { run: (u, f) => act.toggleSource(u.id, f), to: "/income" },
	editSource: { run: (u, f) => act.editSource(u.id, f), to: "/income" },
	deleteSource: { run: (u, f) => act.deleteSource(u.id, f), to: "/income" },
	setHours: { run: (u, f) => act.setHours(u.id, f), to: "/home" },
	tradeDeposit: { run: (u) => trading.startTrade(u), to: "/trading" },
	tradeResult: { run: (u, f) => trading.saveResult(u.id, f), to: "/trading" },
	tradeUndo: { run: (u, f) => trading.undoResult(u.id, f), to: "/trading" },
	tradeFinish: { run: (u, f) => trading.finishTrade(u.id, f), to: "/trading" },
	tradeReopen: { run: (u, f) => trading.reopenTrade(u.id, f), to: "/trading" },
	addPlan: { run: async () => {}, to: "/plan" },
	saveProfile: { run: (u, f) => updateProfile(u.id, { name: text(f, "name"), email: text(f, "email") }), to: "/profile", back: false, fail: "/profile/edit" },
	saveSettings: { run: quiet((u, f) => updatePrefs(u.id, { currency: text(f, "currency"), run_at: text(f, "run_at"), week_start: text(f, "week"), usdt_rate_minor: toMinor(f.get("usdt")) })), to: "/settings" },
	quickBuy: { run: quiet((u, f) => act.quickOp(u.id, f)), to: "/settings" },
	setTheme: { run: quiet((u, f) => setTheme(u.id, text(f, "theme"))), to: "/settings", empty: true },
	setBackground: { run: (u, f) => act.validateAndSetBackground(u.id, text(f, "url")), to: "/settings", back: false },
	resetBackground: { run: quiet((u) => act.resetUserBackground(u.id)), to: "/settings", back: false },
} satisfies Record<string, Command>;

export type CommandName = keyof typeof commands;

export const isCommand = (name: string): name is CommandName => Object.hasOwn(commands, name);

export const errorOf = (r: unknown) => (typeof r === "string" && r ? r : "");
__EOF_MT__
mkdir -p "app/components"
cat > app/components/BottomBar.tsx << '__EOF_MT__'
import { Icon } from "./Icon.tsx";
import { view } from "./view.ts";

export type MobileTab = "home" | "notes" | "goals" | "income" | "trading" | "pad" | "history" | "profile" | "";

const TABS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "income", label: "Income", icon: "gear", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "profile", label: "Profile", icon: "user", href: "/profile" },
] as const;

/** Phone navigation, fixed to the bottom of the screen. */
export const BottomBar = view<{ active: MobileTab }>(({ active }) => (
	<nav class="bt" aria-label="Main">
		{TABS.map((t) => (
			<a key={t.key} href={t.href} class={active === t.key ? "on" : ""} aria-label={t.label}>
				<Icon name={t.icon} />
			</a>
		))}
	</nav>
));
__EOF_MT__
mkdir -p "app/components"
cat > app/components/Icon.tsx << '__EOF_MT__'
import { unsafeHTML } from "remix/component";
import { view } from "./view.ts";

/** Inner SVG markup of every icon (24x24 grid, stroke style comes from `.ic` in app.css). */
export const ICONS: Record<string, string> = {
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
};

/** <Icon name="plus" /> */
export const Icon = view<{ name: string }>(({ name }) => <svg class="ic" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS[name] ?? "")} />);

/** Both theme glyphs; the stylesheet shows the sun or the moon depending on the theme. */
export const ThemeIcons = view(() => (
	<>
		<svg class="ic t-sun" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.sun!)} />
		<svg class="ic t-moon" viewBox="0 0 24 24" innerHTML={unsafeHTML(ICONS.moon!)} />
	</>
));

const GOOGLE_INNER =
	'<path fill="#EA4335" d="M24 9.5c3.5 0 6.6 1.2 9.1 3.6l6.8-6.8C35.8 2.4 30.3 0 24 0 14.6 0 6.5 5.4 2.6 13.2l7.9 6.1C12.4 13.6 17.7 9.5 24 9.5z"/><path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v9h12.7c-.6 3-2.3 5.5-4.8 7.2l7.5 5.8c4.4-4.1 7.1-10.1 7.1-17.5z"/><path fill="#FBBC05" d="M10.5 28.7A14.5 14.5 0 0 1 9.5 24c0-1.6.3-3.2.8-4.7l-7.9-6.1A24 24 0 0 0 0 24c0 3.9.9 7.5 2.6 10.8l7.9-6.1z"/><path fill="#34A853" d="M24 48c6.5 0 11.9-2.1 15.9-5.8l-7.5-5.8c-2.1 1.4-4.8 2.3-8.4 2.3-6.3 0-11.6-4.1-13.5-9.8l-7.9 6.1C6.5 42.6 14.6 48 24 48z"/>';

export const GoogleMark = view(() => <svg width="18" height="18" viewBox="0 0 48 48" innerHTML={unsafeHTML(GOOGLE_INNER)} />);

const GOAT_INNER =
	'<rect width="24" height="24" fill="#000" stroke="#333" stroke-width=".6"/><path fill="#fff" d="M6.5 10C3.5 9 2.4 5.6 3.4 3.4c3 .9 5 2.7 6 5zM17.5 10c3-1 4.1-4.4 3.1-6.6-3 .9-5 2.7-6 5zM7.4 8.2h9.2l-1 7.3L12 21l-3.6-5.5z"/><path d="M9.2 11.4l2 1M14.8 11.4l-2 1" stroke="#000" stroke-width="1.5"/>';

export const GoatMark = view(() => <svg viewBox="0 0 24 24" innerHTML={unsafeHTML(GOAT_INNER)} />);

export const Logo = view<{ href: string }>(({ href }) => (
	<a class="logo" href={href}>
		<GoatMark />
		<span>moneytracker</span>
	</a>
));
__EOF_MT__
mkdir -p "app/components"
cat > app/components/Sidebar.tsx << '__EOF_MT__'
import { Icon, Logo, ThemeIcons } from "./Icon.tsx";
import { view } from "./view.ts";

export type DesktopTab = "home" | "notes" | "plan" | "income" | "trading" | "pad" | "history" | "settings" | "";

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
	{ key: "trading", label: "Trading", icon: "trade", href: "/trading" },
	{ key: "pad", label: "Pad", icon: "pad", href: "/pad" },
	{ key: "history", label: "History", icon: "hist", href: "/history" },
	{ key: "settings", label: "Settings", icon: "gear", href: "/settings" },
] as const;

/** Desktop navigation, shown on the left. */
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
		<form method="post" action="/logout" data-rmx-document>
			<button class="sbl">
				<Icon name="out" />
				<span class="neg">Log out</span>
			</button>
		</form>
	</aside>
));
__EOF_MT__
mkdir -p "app/components"
cat > app/components/history.tsx << '__EOF_MT__'
import type { DayRow, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { today } from "../lib/time.ts";
import { dayNet } from "../lib/view.ts";
import { buyName, SpendRow } from "./buys.tsx";
import { IncomeRow } from "./income.tsx";
import { Back, Card, ErrorBanner, PageHeader, Section } from "./ui.tsx";
import { view } from "./view.ts";

/** Everything that happened on one day: incomes first, then buys. */
const DayItems = view<{ s: State; d: DayRow }>(({ s, d }) => (
	<>
		{d.incomes.map((i) => (
			<IncomeRow key={i.id} s={s} i={i} />
		))}
		{d.buys.map((b) => (
			<SpendRow key={b.id} s={s} id={b.id} name={buyName(b)} sub={b.qty > 1 ? `${b.qty} × ${fmt(b.unit)}` : ""} amount={`−${fmt(b.total)}`} />
		))}
	</>
));

/** Forms that add a buy or an income to any past day. */
const DayForms = view<{ s: State; wide: boolean }>(({ s, wide }) => {
	const t = today();
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
	);
	return wide ? <Section title="Add to any day">{body}</Section> : <Card title="Add to any day">{body}</Card>;
});

/** Phone history: one card per day. */
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
));

/** Desktop history: a table of the last 30 days. */
export const HistoryDesktop = view<{ s: State }>(({ s }) => {
	const earned = s.days.reduce((a, d) => a + d.earned, 0);
	const bought = s.days.reduce((a, d) => a + d.bought, 0);
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
	);
});
__EOF_MT__
mkdir -p "app/components"
cat > app/components/income.tsx << '__EOF_MT__'
import type { Income, Source, State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { calc, gotToday, plain, sourceTag, srcAmount, srcRate } from "../lib/view.ts";
import { Icon } from "./Icon.tsx";
import { Back, Empty, ExpandCard, ListCard, NameChips } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };

const HOUR_CHOICES = [1, 2, 3, 4];

const Hid = view<{ s: State; id: string }>(({ s, id }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="id" value={id} />
	</>
));

export const IncomeRow = view<{ s: State; i: Income }>(({ s, i }) => (
	<div class="by">
		<div>
			<div>{i.source}</div>
			{i.hours ? <div class="lb">{`+${i.hours}h extra`}</div> : null}
		</div>
		<span class="rt">
			<b class="ea">+{fmt(i.amount)}</b>
			{i.locked ? null : (
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(i.amount)} from ${i.source}?`}>
					<Back s={s} />
					<input type="hidden" name="id" value={i.id} />
					<button class="ub" aria-label="Undo income">
						<Icon name="undo" />
					</button>
				</form>
			)}
		</span>
	</div>
));

const SourceMain = view<{ s: State; x: Source; toggle: boolean }>(({ s, x, toggle }) => {
	const got = gotToday(s, x);
	const sum = got.reduce((a, i) => a + i.amount, 0);
	const fixed = srcAmount(x);
	const auto = x.mode === "auto";

	if (toggle && !x.active) {
		return (
			<form method="post" action="/income/toggle" style={contents}>
				<Hid s={s} id={x.id} />
				<button class="btn xs o">Resume</button>
			</form>
		);
	}
	if (auto) {
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
		);
	}
	if (got.length) {
		return (
			<>
				<button class="btn xs" disabled>
					Added
				</button>
				<form method="post" action="/income/delete" style={contents} data-confirm={`Undo +${fmt(sum)} from ${x.name}?`}>
					<Hid s={s} id={got[0]!.id} />
					<button class="ub" aria-label={`Undo ${x.name}`}>
						<Icon name="undo" />
					</button>
				</form>
			</>
		);
	}
	if (fixed) {
		return (
			<form method="post" action="/income/add" style={contents}>
				<Back s={s} />
				<input type="hidden" name="source_id" value={x.id} />
				<button class="btn xs o">Add {fmt(fixed)}</button>
			</form>
		);
	}
	return (
		<form method="post" action="/income/add" class="ln" style={{ gap: "6px" }}>
			<Back s={s} />
			<input type="hidden" name="source_id" value={x.id} />
			<input class="in pr2" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs o">Add</button>
		</form>
	);
});

const DeleteSource = view<{ s: State; x: Source }>(({ s, x }) => (
	<form method="post" action="/income/source/delete" style={contents} data-confirm={`Delete ${x.name}? What it already paid stays in your balance.`}>
		<Hid s={s} id={x.id} />
		<button class="ub" aria-label={`Delete ${x.name}`}>
			<Icon name="trash" />
		</button>
	</form>
));

const HoursPanel = view<{ s: State; x: Source; got: Income }>(({ s, x, got }) => {
	const rate = srcRate(x);
	const now = got.hours;
	const summary = now ? `${now}h · +${fmt(Math.round(now * rate))}` : rate ? `${fmt(rate)} per hour` : "no hour price yet";
	return (
		<details class="hrs" data-keep-open={`hrs-${x.id}-${got.day}`} open={true}>
			<summary class="hrs-h">
				<span>Extra hours</span>
				<span class="lb">{summary}</span>
				<span class="hv">
					<Icon name="chev" />
				</span>
			</summary>
			<div class="hrs-b">
				{rate ? (
					<>
						<form method="post" action="/income/hours" class="chips hrc">
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							{HOUR_CHOICES.map((h) => (
								<button key={h} class={now === h ? "chip on" : "chip"} name="hours" value={String(h)}>
									{h}h
								</button>
							))}
							{now ? (
								<button class="chip n" name="hours" value="0">
									Clear
								</button>
							) : null}
						</form>
						<form method="post" action="/income/hours" class="ln hrx">
							<Back s={s} />
							<input type="hidden" name="source_id" value={x.id} />
							<input class="in" name="hours" placeholder="Other number of hours" inputmode="decimal" autocomplete="off" required />
							<button class="btn xs o">Add</button>
						</form>
					</>
				) : (
					<div class="lb">Tap the pencil on the Income page and type the price for one extra hour.</div>
				)}
			</div>
		</details>
	);
});

const noteOf = (x: Source, got: Income[]) => (x.type === "job" && got[0] ? (got[0].hours ? `${fmt(got[0].amount)} · ${got[0].hours}h extra` : `${fmt(got[0].amount)} · no extra hours`) : "");

const SourceRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x);
	const note = noteOf(x, got);
	return (
		<div class="srw">
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{sourceTag(x)}</span>
					</div>
					{note ? <div class="lb">{note}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle />
					<DeleteSource s={s} x={x} />
				</span>
			</div>
			{x.type === "job" && x.active && got[0] ? <HoursPanel s={s} x={x} got={got[0]} /> : null}
		</div>
	);
});

const QuickIncome = view<{ s: State }>(({ s }) => (
	<form method="post" action="/history/income" class="qi">
		<Back s={s} />
		<NameChips names={s.incomeNames} />
		<div class="ln">
			<input class="in" name="label" data-name placeholder="Other income name" autocomplete="off" />
			<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
			<button class="btn xs">Add</button>
		</div>
	</form>
));

const SourceList = view<{ s: State }>(({ s }) => {
	const others = s.incomesToday.filter((i) => !i.sourceId);
	return s.sources.length || others.length ? (
		<>
			{s.sources.map((x) => (
				<SourceRow key={x.id} s={s} x={x} />
			))}
			{others.map((i) => (
				<IncomeRow key={i.id} s={s} i={i} />
			))}
		</>
	) : (
		<Empty>No sources yet. Add one below.</Empty>
	);
});

const HomeRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const got = gotToday(s, x);
	const note = noteOf(x, got);
	return (
		<div class="srw">
			<div class="rw">
				<div>
					<div>{x.name}</div>
					{note ? <div class="lb">{note}</div> : null}
				</div>
				<span class="rt">
					<SourceMain s={s} x={x} toggle={false} />
				</span>
			</div>
			{x.type === "job" && got[0] ? <HoursPanel s={s} x={x} got={got[0]} /> : null}
		</div>
	);
});

const MODES = [
	{ key: "manual", label: "Manual" },
	{ key: "job", label: "Fixed + hours" },
	{ key: "daily", label: "Auto daily" },
	{ key: "monthly", label: "Monthly" },
];

const ModeChips = view(() => (
	<>
		<input type="hidden" name="mode" value="manual" data-mode-input />
		<div class="chips" style={{ margin: "10px 0 4px" }}>
			{MODES.map((m) => (
				<span key={m.key} class={m.key === "manual" ? "chip on" : "chip"} data-mode={m.key} style={{ cursor: "pointer" }}>
					{m.label}
				</span>
			))}
		</div>
		<div class="lb mh mh-manual" style={{ marginBottom: "2px" }}>
			Manual: you tap it once a day. Leave the amount empty if the number is different each day.
		</div>
		<div class="lb mh mh-job" style={{ marginBottom: "2px" }}>
			Fixed + hours: the same pay each day, plus a price for every extra hour. After you tap it on Home you pick the extra hours.
		</div>
		<div class="lb mh mh-daily" style={{ marginBottom: "2px" }}>
			Auto daily: the money is added for you every day.
		</div>
		<div class="lb mh mh-monthly" style={{ marginBottom: "2px" }}>
			Monthly: the money is added for you once a month.
		</div>
	</>
));

const SourceFields = view<{ s: State }>(({ s }) => (
	<>
		<Back s={s} />
		<div class="ln">
			<input class="in" name="name" placeholder="Source name (like Construction)" autocomplete="off" required />
			<input class="in pr src-amt" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
		</div>
		<div class="ln src-job">
			<input class="in" name="fixed" placeholder="Fixed per day" inputmode="decimal" autocomplete="off" />
			<input class="in" name="rate" placeholder="Price per hour" inputmode="decimal" autocomplete="off" />
		</div>
		<ModeChips />
		<button class="btn full">Add source</button>
	</>
));

const AddSourceForm = view<{ s: State; id: string }>(({ s, id }) => (
	<form method="post" action="/income" id={id} class="sc spf" data-adp data-m="manual" hidden>
		<SourceFields s={s} />
	</form>
));

const SourceForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/income" class="sf xfm" data-adp data-m="manual" hidden>
		<SourceFields s={s} />
	</form>
));

export const IncomeDesktop = view<{ s: State; title?: string; id?: string }>(({ s, title = "Income sources", id = "f-src-d" }) => (
	<>
		<AddSourceForm s={s} id={id} />
		<ListCard title={title} right={`+${fmt(calc(s).earned)} today`} target={id} label="Add source">
			<SourceList s={s} />
			<QuickIncome s={s} />
		</ListCard>
	</>
));

const ManageRow = view<{ s: State; x: Source }>(({ s, x }) => {
	const fixed = srcAmount(x);
	const rate = srcRate(x);
	const job = x.type === "job";
	return (
		<div class="dbw">
			<div class="rw">
				<div>
					<div>
						{x.name}
						<span class="tag">{sourceTag(x)}</span>
					</div>
					{fixed ? <div class="lb">{`${fmt(fixed)} ${s.user.currency}${job ? ` + ${rate ? fmt(rate) : "?"} per hour` : ""}`}</div> : null}
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
				{job ? (
					<>
						<div class="ln">
							<input class="in f" name="name" value={x.name} autocomplete="off" required />
						</div>
						<div class="ln" style={{ marginTop: "8px" }}>
							<input class="in" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Fixed per day" inputmode="decimal" autocomplete="off" />
							<input class="in" name="rate" value={rate ? plain(rate) : ""} placeholder="Price per hour" inputmode="decimal" autocomplete="off" />
							<button class="btn xs">Save</button>
						</div>
					</>
				) : (
					<div class="ln">
						<input class="in f" name="name" value={x.name} autocomplete="off" required />
						<input class="in pr2" name="amount" value={fixed ? plain(fixed) : ""} placeholder="Amount" inputmode="decimal" autocomplete="off" />
						<button class="btn xs">Save</button>
					</div>
				)}
			</form>
		</div>
	);
});

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
));

export const HomeIncome = view<{ s: State }>(({ s }) => {
	const c = calc(s);
	const sources = s.sources.filter((x) => x.active);
	const others = s.incomesToday.filter((i) => !i.sourceId);
	return (
		<ExpandCard
			storeKey="inc"
			open
			title="Income today"
			label="Add other income"
			head={
				<>
					<b class="big2">
						+{fmt(c.earned)} <small>{s.user.currency}</small>
					</b>
					<span class="lb">{c.earnedLine}</span>
				</>
			}
			form={
				<form method="post" action="/history/income" class="sf xfm" data-adp hidden>
					<Back s={s} />
					<NameChips names={s.incomeNames} />
					<div class="ln">
						<input class="in" name="label" data-name placeholder="Name (like Fiverr)" autocomplete="off" />
						<input class="in pr" name="amount" data-price placeholder="Amount" inputmode="decimal" autocomplete="off" required />
					</div>
					<button class="btn full">Add income</button>
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
				<Empty>No sources yet.</Empty>
			)}
		</ExpandCard>
	);
});
__EOF_MT__
mkdir -p "app/components"
cat > app/components/profile.tsx << '__EOF_MT__'
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { LANG, plain } from "../lib/view.ts";
import { Icon } from "./Icon.tsx";
import { Avatar, Back, Card, ErrorBanner, Field, PageHeader, Section, ThemeSwitch } from "./ui.tsx";
import { view } from "./view.ts";

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
));

/** Total balance, hidden behind dots until the eye is tapped. `edit` adds "Edit balance". */
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
));

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
));

const PrefsForm = view<{ s: State }>(({ s }) => (
	<form method="post" action="/settings">
		<Field label="Currency" value={s.user.currency} name="currency" />
		<Field label={`1 USDT costs (${s.user.currency})`} value={plain(s.user.usdt_rate)} name="usdt" />
		<Field label="Auto income runs at" value={s.user.run_at} name="run_at" />
		<Field label="Week starts" value={s.user.week_start} name="week" />
		<button class="btn" style={{ marginTop: "14px" }}>
			Save
		</button>
	</form>
));

const DataButtons = view(() => (
	<div style={{ display: "flex", gap: "10px", marginTop: "6px" }}>
		<a class="btn o" style={{ flex: "1" }} href="/export.csv" data-rmx-document>
			Export CSV
		</a>
		<form method="post" action="/account/delete" data-rmx-document style={{ flex: "1", display: "flex" }} data-confirm="Delete your account and all your data? This cannot be undone.">
			<button class="btn dng" style={{ flex: "1" }}>
				Delete account
			</button>
		</form>
	</div>
));

const LinkRow = view<{ href: string; label: string }>(({ href, label }) => (
	<a class="li" href={href}>
		<span>{label}</span>
		<span class="mu">›</span>
	</a>
));

/** Phone profile tab. */
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
			<form method="post" action="/logout" data-rmx-document>
				<button class="li">
					<span class="neg">Log out</span>
					<span class="mu">›</span>
				</button>
			</form>
		</Card>
	</>
));

/** Phone "Edit profile" page. */
export const EditProfileMobile = view<{ s: State }>(({ s }) => (
	<>
		<div style={{ display: "flex", justifyContent: "center", margin: "14px 0 0" }}>
			<Avatar avatar={s.avatar} name={s.user.name} />
		</div>
		<Card title="Profile">
			<ProfileForm s={s} cancel="/profile" showError />
		</Card>
	</>
));

/** Phone settings page. */
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
));

/** Desktop settings: used by the profile, edit-profile and settings routes. */
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
					<form method="post" action="/logout" data-rmx-document>
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
));
__EOF_MT__
mkdir -p "app/components"
cat > app/components/trading.tsx << '__EOF_MT__'
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";
import { dayLabel } from "../lib/time.ts";
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcLost,
	btcOf,
	DEPOSIT,
	PRED_COUNT,
	predOf,
	strip,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "../lib/trade-math.ts";
import { Icon } from "./Icon.tsx";
import { Back, Card } from "./ui.tsx";
import { view } from "./view.ts";

const contents = { display: "contents" };

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`;
const tone = (minor: number) => (minor < 0 ? "neg" : "pos");

type RowState = "result" | "active" | "wait" | "skip";

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
));

const PredictRow = view<{ s: State; t: TradeSession; game: Game; idx: number; r: TradeResult | undefined; state: RowState; canUndo: boolean }>(
	({ s, t, game, idx, r, state, canUndo }) => {
		if (r) {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
					</div>
					<span class="rt">
						<span class={`tbs ${r.won ? "pos" : "neg"}`}>{r.won ? "Win" : "Lost"}</span>
						<b class={tone(r.pnl)}>{sg(r.pnl)}</b>
						{canUndo ? (
							<form method="post" action="/trading/undo" style={contents} data-confirm={`Remove the result of predict ${idx}?`}>
								<SessionHid s={s} t={t} />
								<input type="hidden" name="result_id" value={r.id} />
								<button class="ub" aria-label={`Undo predict ${idx}`}>
									<Icon name="undo" />
								</button>
							</form>
						) : null}
					</span>
				</div>
			);
		}
		if (state === "active") {
			return (
				<div class="tbr">
					<div>
						<b>Predict {idx}</b>
					</div>
					<form method="post" action="/trading/result" class="tbf">
						<SessionHid s={s} t={t} />
						<input type="hidden" name="game" value={game} />
						<input type="hidden" name="idx" value={String(idx)} />
						<input class="in" name="pnl" placeholder="PnL USDT" inputmode="decimal" autocomplete="off" required />
						<button class="btn xs win" name="outcome" value="win">
							Win
						</button>
						<button class="btn xs lose" name="outcome" value="lost">
							Lost
						</button>
					</form>
				</div>
			);
		}
		return (
			<div class="tbr lock">
				<div>
					<b>Predict {idx}</b>
				</div>
				<span class="lb">{state === "skip" ? "skipped" : "waiting"}</span>
			</div>
		);
	},
);

const BtcCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = btcOf(t.results);
	const done = btcDone(t.results);
	const lost = btcLost(t.results);
	return (
		<Card title="Bitcoin · 5 minutes · up or down">
			<div class="lb tbn">1 USDT. Up to {BTC_ROUNDS} predicts. Win goes to the next one. Lost means finished.</div>
			{Array.from({ length: BTC_ROUNDS }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx);
				const state: RowState = r ? "result" : done ? "skip" : idx === list.length + 1 ? "active" : "wait";
				return <PredictRow key={idx} s={s} t={t} game="btc" idx={idx} r={r} state={state} canUndo={!!r && idx === list.length} />;
			})}
			{done ? <div class="lb tbn">{lost ? "Finished. You lost this one." : `Finished. You won all ${BTC_ROUNDS}.`}</div> : null}
		</Card>
	);
});

const PredCard = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const list = predOf(t.results);
	return (
		<Card title="3 predicts · lol or sport">
			<div class="lb tbn">3 USDT. Each predict is on its own. Pick Win or Lost and type the PnL.</div>
			{Array.from({ length: PRED_COUNT }, (_, i) => i + 1).map((idx) => {
				const r = list.find((x) => x.idx === idx);
				return <PredictRow key={idx} s={s} t={t} game="pred" idx={idx} r={r} state={r ? "result" : "active"} canUndo={!!r} />;
			})}
		</Card>
	);
});

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const cur = s.user.currency;
	const pnl = totalPnl(t.results);
	const back = backUsdt(t.deposit, pnl);
	const net = toMad(pnl, t.rate);
	return (
		<Card title="Open trade">
			<div class="ow" style={{ margin: "0 0 8px" }}>
				<b class={`big2 ${t.results.length ? tone(pnl) : ""}`}>
					{t.results.length ? sg(pnl) : "0"} <small>USDT PnL</small>
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
			{t.results.length && !allDone(t.results) ? (
				<form method="post" action="/trading/finish" data-confirm="Finish now and skip the predicts that are left?">
					<SessionHid s={s} t={t} />
					<button class="btn o full">Finish now</button>
				</form>
			) : null}
			<div class="lb tbn">When every predict has a result, the money is added to your balance by itself.</div>
		</Card>
	);
});

const StartCard = view<{ s: State }>(({ s }) => {
	const cur = s.user.currency;
	const rate = s.user.usdt_rate;
	const cost = toMad(DEPOSIT, rate);
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
			<div class="lb tbn">Then you do 4 Bitcoin predicts (1 USDT) and 3 more predicts (3 USDT).</div>
		</Card>
	);
});

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = t.returnMad - toMad(t.deposit, t.rate);
	const btc = strip(btcOf(t.results));
	const pred = strip(predOf(t.results));
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
	);
});

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null;
	const total = list.reduce((a, t) => a + (t.returnMad - toMad(t.deposit, t.rate)), 0);
	return (
		<Card title={`Past trades · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	);
});

export const TradingBody = view<{ s: State }>(({ s }) => {
	const open = s.trades.find((t) => t.status === "open");
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10);
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
	);
});
__EOF_MT__
mkdir -p "app/controllers"
cat > app/controllers/pages.tsx << '__EOF_MT__'
import { createController } from "remix/router";
import type { RemixNode } from "remix/component";
import * as act from "../lib/actions.ts";
import type { State } from "../lib/data.ts";
import { loadFrame, loadScreen, type ScreenKey } from "../loaders/index.ts";
import { NoteCard } from "../components/notes.tsx";
import {
	DebtsScreen,
	GoalsScreen,
	HistoryScreen,
	HomeScreen,
	IncomeScreen,
	NotesScreen,
	PadScreen,
	ProfileEditScreen,
	ProfileScreen,
	SettingsScreen,
	TradingScreen,
} from "../screens/index.ts";
import { routes } from "../routes.ts";
import { go, takeError, userOf, type Ctx } from "../utils/request.ts";

/**
 * The server-loader pattern: check who is asking, run the screen's loader on the server, then
 * render the screen component with the loaded state. No data fetching happens in the browser.
 */
const screen = (key: ScreenKey, render: (s: State) => RemixNode) => async (ctx: Ctx) => {
	const user = userOf(ctx);
	if (!user) return go("/login");
	const state = await loadScreen(user, key, takeError(ctx), true);
	return ctx.render(render(state));
};

export default createController(routes.pages, {
	actions: {
		root: (ctx: Ctx) => go(userOf(ctx) ? "/home" : "/login"),
		home: screen("home", (s) => <HomeScreen s={s} />),
		debts: screen("debts", (s) => <DebtsScreen s={s} />),
		notes: screen("notes", (s) => <NotesScreen s={s} />),
		goals: screen("goals", (s) => <GoalsScreen s={s} />),
		plan: screen("plan", (s) => <GoalsScreen s={s} />),
		income: screen("income", (s) => <IncomeScreen s={s} />),
		history: screen("history", (s) => <HistoryScreen s={s} />),
		profile: screen("profile", (s) => <ProfileScreen s={s} />),
		profileEdit: screen("profileEdit", (s) => <ProfileEditScreen s={s} />),
		settings: screen("settings", (s) => <SettingsScreen s={s} />),
		pad: screen("pad", (s) => <PadScreen s={s} />),
		trading: screen("trading", (s) => <TradingScreen s={s} />),

		async frameNotes(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return new Response(null, { status: 401 });
			return ctx.render(<NoteCard s={await loadFrame(user, "/home", ["notes"])} />);
		},

		async exportCsv(ctx: Ctx) {
			const user = userOf(ctx);
			if (!user) return go("/login");
			return new Response(await act.exportCsv(user.id), {
				headers: {
					"Content-Type": "text/csv; charset=utf-8",
					"Content-Disposition": 'attachment; filename="moneytracker.csv"',
				},
			});
		},
	},
});
__EOF_MT__
mkdir -p "app/db"
cat > app/db/tables.ts << '__EOF_MT__'
import { column as c, table } from "remix/data-table";

// Typed mirrors of database/schema.sql. Money is integer minor units, times are unix ms.

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
usdt_rate_minor: c.integer(),
created_at: c.integer(),
updated_at: c.integer(),
},
});

export const passwords = table({
name: "passwords",
columns: { user_id: c.varchar(36), hash: c.varchar(255), updated_at: c.integer() },
primaryKey: "user_id",
});

export const sessions = table({
name: "sessions",
columns: {
id: c.varchar(64),
user_id: c.varchar(36),
data: c.varchar(65535),
created_at: c.integer(),
expires_at: c.integer(),
},
});

export const oauthAccounts = table({
name: "oauth_accounts",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
provider: c.varchar(32),
provider_account_id: c.varchar(255),
created_at: c.integer(),
},
});

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
});

export const quickBuys = table({
name: "quick_buys",
columns: { id: c.varchar(36), user_id: c.varchar(36), name: c.varchar(60), icon: c.varchar(16), price_minor: c.integer(), sort: c.integer() },
});

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
});

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
},
});

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
});

export const people = table({
name: "people",
columns: { id: c.varchar(36), user_id: c.varchar(36), name: c.varchar(80) },
});

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
});

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
});

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
});

export const goalItems = table({
name: "goal_items",
columns: { id: c.varchar(36), user_id: c.varchar(36), goal_id: c.varchar(36), name: c.varchar(120), price_minor: c.integer(), done_at: c.integer(), created_at: c.integer() },
});

export const notes = table({
name: "notes",
columns: { id: c.varchar(36), user_id: c.varchar(36), body: c.varchar(5000), created_at: c.integer(), updated_at: c.integer() },
});

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
});

export const tradeResults = table({
name: "trade_results",
columns: {
id: c.varchar(36),
user_id: c.varchar(36),
session_id: c.varchar(36),
game: c.varchar(8),
idx: c.integer(),
won: c.integer(),
pnl_minor: c.integer(),
created_at: c.integer(),
},
});
__EOF_MT__
mkdir -p "app/lib"
cat > app/lib/actions.ts << '__EOF_MT__'
import { sql } from "remix/data-table";
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { balanceOf } from "./data.ts";
import { fmt, toMinor, toSigned } from "./money.ts";
import { extKey, parseJson, typeOf } from "./sources/index.ts";
import { today } from "./time.ts";
import { updateBg } from "./users.ts";
const id = () => crypto.randomUUID();
const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max);
const count = (v: unknown) => {
const n = Math.floor(parseFloat(String(v ?? "").replace(",", ".")));
return Number.isFinite(n) && n > 0 ? Math.min(n, 100000) : 0;
};
const realDay = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T12:00:00Z`)) && new Date(`${v}T12:00:00Z`).toISOString().slice(0, 10) === v;
const pickDay = (f: FormData) => {
const d = text(f.get("day"), 10) || today();
return realDay(d) && d <= today() ? d : null;
};
const ICON_KEYS = ["Smoke", "Coffee", "Bread", "Food", "Bus", "Phone", "Gift", "Cart", "Tag"];

export async function addBuy(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("label"), 120) || "Item";
const qty = count(f.get("qty")) || 1;
const unit = toMinor(f.get("price"));
if (!unit) return "Enter a price";
const day = pickDay(f);
if (!day) return "Pick a day that is not in the future";
await db.create(purchases, { id: id(), user_id: uid, name, qty, unit_minor: unit, total_minor: unit * qty, day, created_at: Date.now() });
}
export async function addDayIncome(uid: string, f: FormData): Promise<string | void> {
const amount = toMinor(f.get("amount"));
if (!amount) return "Enter an amount";
const day = pickDay(f);
if (!day) return "Pick a day that is not in the future";
const label = text(f.get("label"), 60);
await db.create(incomes, { id: id(), user_id: uid, amount_minor: amount, day, created_at: Date.now(), meta: JSON.stringify(label ? { manual: 1, name: label } : { manual: 1 }), ext_key: "" });
}
export async function setBalance(uid: string, f: FormData): Promise<string | void> {
const target = toSigned(f.get("balance"));
if (target === null) return "Enter your balance";
const diff = target - (await balanceOf(uid));
if (!diff) return;
const now = Date.now();
if (diff > 0) await db.create(incomes, { id: id(), user_id: uid, amount_minor: diff, day: today(), created_at: now, meta: '{"adjust":1}', ext_key: "" });
else await db.create(purchases, { id: id(), user_id: uid, name: "Balance adjustment", qty: 1, unit_minor: -diff, total_minor: -diff, day: today(), created_at: now });
}
export async function deleteBuy(uid: string, f: FormData): Promise<string | void> {
const p = await db.findOne(purchases, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!p) return;
await db.transaction(async (tx) => {
if (p.debt_id) {
const pays = await tx.findMany(debtPayments, { where: { purchase_id: p.id, user_id: uid } });
const back = pays.reduce((a, x) => a + x.amount_minor, 0) || p.total_minor;
const d = await tx.findOne(debts, { where: { id: p.debt_id, user_id: uid } });
if (d) await tx.update(debts, d.id, { amount_minor: d.amount_minor + back });
await tx.exec(sql`delete from debt_payments where purchase_id = ${p.id} and user_id = ${uid}`);
}
await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key in (select 'trade:' || id from trade_sessions where purchase_id = ${p.id} and user_id = ${uid})`);
await tx.exec(sql`delete from trade_results where user_id = ${uid} and session_id in (select id from trade_sessions where purchase_id = ${p.id} and user_id = ${uid})`);
await tx.exec(sql`delete from trade_sessions where purchase_id = ${p.id} and user_id = ${uid}`);
await tx.exec(sql`delete from purchases where id = ${p.id} and user_id = ${uid}`);
});
}
export async function addDebt(uid: string, f: FormData): Promise<string | void> {
const debtId = text(f.get("debt_id"), 36);
if (debtId) {
const d = await db.findOne(debts, { where: { id: debtId, user_id: uid } });
if (!d) return;
if (d.kind === "item") {
const n = count(f.get("amount"));
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) + n });
} else {
const m = toMinor(f.get("amount"));
if (!m) return "Enter an amount";
await db.update(debts, d.id, { amount_minor: d.amount_minor + m });
}
return;
}
const name = text(f.get("name"), 80);
const cig = count(f.get("cig"));
const money = toMinor(f.get("amount"));
if (!name) return "Enter a name";
if (!cig && !money) return "Enter an amount";
await db.transaction(async (tx) => {
const all = await tx.findMany(people, { where: { user_id: uid } });
let person = all.find((p) => p.name.toLowerCase() === name.toLowerCase());
if (!person) person = await tx.create(people, { id: id(), user_id: uid, name }, { returnRow: true });
const mine = await tx.findMany(debts, { where: { user_id: uid, person_id: person.id } });
if (money) {
const row = mine.find((d) => d.kind === "money");
if (row) await tx.update(debts, row.id, { amount_minor: row.amount_minor + money });
else await tx.create(debts, { id: id(), user_id: uid, person_id: person.id, kind: "money", amount_minor: money, created_at: Date.now() });
}
if (cig) {
const row = mine.find((d) => d.kind === "item");
if (row) await tx.update(debts, row.id, { item_qty: (row.item_qty ?? 0) + cig });
else
await tx.create(debts, {
id: id(),
user_id: uid,
person_id: person.id,
kind: "item",
item_name: "cig",
item_qty: cig,
amount_minor: 0,
created_at: Date.now(),
});
}
});
}
export async function clearDebt(uid: string, f: FormData) {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
await db.update(debts, d.id, d.kind === "item" ? { item_qty: 0 } : { amount_minor: 0 });
}
export async function payDebt(uid: string, f: FormData): Promise<string | void> {
const d = await db.findOne(debts, { where: { id: text(f.get("debt_id"), 36), user_id: uid } });
if (!d) return;
if (d.kind === "item") {
const n = Math.min(count(f.get("amount")), d.item_qty ?? 0);
if (!n) return "Enter an amount";
await db.update(debts, d.id, { item_qty: (d.item_qty ?? 0) - n });
return;
}
const pay = Math.min(toMinor(f.get("amount")), d.amount_minor);
if (!pay) return "Enter an amount";
const person = await db.find(people, d.person_id);
const purchaseId = id();
const now = Date.now();
await db.transaction(async (tx) => {
await tx.create(purchases, {
id: purchaseId,
user_id: uid,
name: `Paid ${person?.name ?? ""}`.trim(),
qty: 1,
unit_minor: pay,
total_minor: pay,
day: today(),
debt_id: d.id,
created_at: now,
});
await tx.create(debtPayments, { id: id(), debt_id: d.id, user_id: uid, amount_minor: pay, purchase_id: purchaseId, created_at: now });
await tx.update(debts, d.id, { amount_minor: d.amount_minor - pay });
});
}
export async function addGoal(uid: string, f: FormData): Promise<string | void> {
const title = text(f.get("name"), 120);
if (!title) return "Enter a goal name";
await db.create(goals, { id: id(), user_id: uid, title, target_minor: 0, saved_minor: 0, is_wish: 1, created_at: Date.now() });
}
export async function addGoalItem(uid: string, f: FormData): Promise<string | void> {
const g = await db.findOne(goals, { where: { id: text(f.get("goal_id"), 36), user_id: uid } });
if (!g) return "Goal not found";
const name = text(f.get("name"), 120);
if (!name) return "Enter an item";
const price = toMinor(f.get("price"));
if (!price) return "Enter a price";
await db.create(goalItems, { id: id(), user_id: uid, goal_id: g.id, name, price_minor: price, created_at: Date.now() });
}
export async function editGoal(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("name"), 120);
if (!name) return "Enter a goal name";
await db.exec(sql`update goals set title = ${name} where id = ${text(f.get("id"), 36)} and user_id = ${uid}`);
}
export async function editGoalItem(uid: string, f: FormData): Promise<string | void> {
const name = text(f.get("name"), 120);
if (!name) return "Enter an item";
const price = toMinor(f.get("price"));
if (!price) return "Enter a price";
await db.exec(sql`update goal_items set name = ${name}, price_minor = ${price} where id = ${text(f.get("id"), 36)} and user_id = ${uid} and done_at is null`);
}
export async function deleteGoalItem(uid: string, f: FormData) {
await db.exec(sql`delete from goal_items where id = ${text(f.get("id"), 36)} and user_id = ${uid}`);
}
export async function deleteWish(uid: string, f: FormData) {
const gid = text(f.get("id"), 36);
await db.exec(sql`delete from goal_items where goal_id = ${gid} and user_id = ${uid}`);
await db.exec(sql`delete from goals where id = ${gid} and user_id = ${uid}`);
}
export async function buyWish(uid: string, f: FormData): Promise<string | void> {
const it = await db.findOne(goalItems, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!it || it.done_at) return;
const bal = await balanceOf(uid);
if (it.price_minor > bal) return `Not enough balance for ${it.name}. You have ${fmt(Math.max(0, bal))}`;
await db.transaction(async (tx) => {
await tx.create(purchases, { id: id(), user_id: uid, name: it.name, qty: 1, unit_minor: it.price_minor, total_minor: it.price_minor, day: today(), created_at: Date.now() });
await tx.update(goalItems, it.id, { done_at: Date.now() });
});
}
export async function addSource(uid: string, f: FormData) {
const name = text(f.get("name"), 80);
if (!name) return "Enter a name";
const mode = text(f.get("mode"), 10);
const kind = typeOf(mode === "job" ? "job" : text(f.get("type"), 16));
const config = kind.parseConfig(f);
if (typeof config === "string") return config;
const amount = toMinor(f.get("amount"));
if ((mode === "daily" || mode === "monthly") && !amount) return "Enter how much it pays";
const taken = await db.findMany(incomeSources, { where: { user_id: uid } });
if (taken.some((x) => x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`;
const last = await db.findOne(incomeSources, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(incomeSources, {
id: id(),
user_id: uid,
name,
mode: mode === "daily" || mode === "monthly" ? "auto" : "manual",
amount_minor: amount,
every: mode === "daily" ? "day" : mode === "monthly" ? "month" : "",
created_at: Date.now(),
type: kind.key,
config: JSON.stringify(config),
currency: text(f.get("currency"), 8).toUpperCase() || "MAD",
active: 1,
sort: (last?.sort ?? -1) + 1,
});
}
export async function saveDay(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = text(f.get("day"), 10) || today();
if (!realDay(day) || day > today()) return "Pick a day that is not in the future";
const kind = typeOf(s.type);
const key = extKey(s.id, day);
if (text(f.get("op"), 10) === "delete") {
const rowId = text(f.get("income_id"), 80);
if (rowId) await db.deleteMany(incomes, { where: { id: rowId, user_id: uid, source_id: s.id } });
else if (kind.keyed) await db.deleteMany(incomes, { where: { user_id: uid, ext_key: key } });
return;
}
let last: ReturnType<typeof parseJson> | null = null;
if (!kind.keyed) {
const rows = await db.findMany(incomes, { where: { user_id: uid, source_id: s.id }, orderBy: ["day", "desc"], limit: 200 });
const prev = rows.filter((r) => r.day <= day).sort((a, b) => (a.day === b.day ? b.created_at - a.created_at : a.day < b.day ? 1 : -1))[0];
last = prev ? parseJson(prev.meta) : null;
}
const entry = kind.entry({ config: parseJson(s.config), form: f, fallback: s.amount_minor, last });
if (typeof entry === "string") return entry;
const values = { amount_minor: entry.amount, meta: JSON.stringify(entry.meta) };
if (kind.keyed) {
const existing = await db.findOne(incomes, { where: { user_id: uid, ext_key: key } });
if (existing) {
await db.update(incomes, existing.id, values);
return;
}
}
await db.create(incomes, { id: id(), user_id: uid, source_id: s.id, day, created_at: Date.now(), ext_key: kind.keyed ? key : "", ...values });
}
export async function addIncome(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const day = today();
if (typeOf(s.type).keyed) {
const done = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, day) } });
if (done) return `${s.name} is already added today`;
}
f.set("day", day);
return saveDay(uid, f);
}
export async function editSource(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (!s) return "Unknown source";
const name = text(f.get("name"), 80);
if (!name) return "Enter a name";
const taken = await db.findMany(incomeSources, { where: { user_id: uid } });
if (taken.some((x) => x.id !== s.id && x.name.toLowerCase() === name.toLowerCase())) return `You already have a source called ${name}`;
const amount = toMinor(f.get("amount"));
if (s.type === "job") {
const rate = toMinor(f.get("rate"));
await db.update(incomeSources, s.id, {
name,
config: JSON.stringify({ ...parseJson(s.config), ...(amount ? { fixed_minor: amount } : {}), ...(rate ? { rate_minor: rate } : {}) }),
});
return;
}
if (s.type && s.type !== "manual") {
await db.update(incomeSources, s.id, { name });
return;
}
if (s.mode === "auto" && !amount) return "Enter how much it pays";
await db.update(incomeSources, s.id, { name, amount_minor: amount });
}
export async function setHours(uid: string, f: FormData): Promise<string | void> {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("source_id"), 36), user_id: uid } });
if (!s || s.type !== "job") return "Unknown source";
const cfg = parseJson(s.config);
const row = await db.findOne(incomes, { where: { user_id: uid, ext_key: extKey(s.id, today()) } });
if (!row) return "Add the fixed pay first";
const hours = Number(String(f.get("hours") ?? "").trim().replace(",", "."));
if (!Number.isFinite(hours) || hours < 0 || hours > 24) return "Extra hours must be between 0 and 24";
if (hours > 0 && !(Number(cfg.rate_minor) > 0)) return "Set the price per hour first. Tap the pencil on the Income page";
const fixed = Number(parseJson(row.meta).fixed_minor) || Number(cfg.fixed_minor) || 0;
const entry = typeOf("job").entry({ config: { ...cfg, fixed_minor: fixed }, form: f, fallback: 0, last: null });
if (typeof entry === "string") return entry;
await db.update(incomes, row.id, { amount_minor: entry.amount, meta: JSON.stringify(entry.meta) });
}
export async function toggleSource(uid: string, f: FormData) {
const s = await db.findOne(incomeSources, { where: { id: text(f.get("id"), 36), user_id: uid } });
if (s) await db.update(incomeSources, s.id, { active: s.active === 0 ? 1 : 0 });
}
export async function deleteSource(uid: string, f: FormData) {
const sid = text(f.get("id"), 36);
const s = await db.findOne(incomeSources, { where: { id: sid, user_id: uid } });
if (!s) return;
await db.transaction(async (tx) => {
await tx.exec(sql`update incomes set source_id = null where source_id = ${s.id} and user_id = ${uid}`);
await tx.exec(sql`delete from income_sources where id = ${s.id} and user_id = ${uid}`);
});
}
export async function deleteIncome(uid: string, f: FormData): Promise<string | void> {
const row = await db.findOne(incomes, { where: { id: text(f.get("id"), 80), user_id: uid } });
if (!row) return;
if (row.ext_key.startsWith("trade:")) return "Undo this from the Trading page";
if (row.ext_key) {
const src = row.source_id ? await db.findOne(incomeSources, { where: { id: row.source_id, user_id: uid } }) : null;
if (src?.mode === "auto") return "Auto income can't be undone. Pause the source instead";
}
await db.deleteMany(incomes, { where: { id: row.id, user_id: uid } });
}
export async function quickOp(uid: string, f: FormData) {
const op = text(f.get("op"), 10);
const qid = text(f.get("id"), 36);
const name = text(f.get("name"), 60);
const icon = ICON_KEYS.includes(String(f.get("icon"))) ? String(f.get("icon")) : "Tag";
const price = toMinor(f.get("price"));
if (op === "delete" && qid) {
await db.deleteMany(quickBuys, { where: { id: qid, user_id: uid } });
} else if (op === "save" && qid && name) {
await db.updateMany(quickBuys, { name, icon, price_minor: price }, { where: { id: qid, user_id: uid } });
} else if (op === "add" && name) {
const last = await db.findOne(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "desc"] });
await db.create(quickBuys, { id: id(), user_id: uid, name, icon, price_minor: price, sort: (last?.sort ?? -1) + 1 });
}
}
export async function saveNote(uid: string, f: FormData) {
const body = text(f.get("text"), 5000);
if (!body) return;
const noteId = text(f.get("id"), 36);
const now = Date.now();
if (noteId) await db.updateMany(notes, { body, updated_at: now }, { where: { id: noteId, user_id: uid } });
else await db.create(notes, { id: id(), user_id: uid, body, created_at: now, updated_at: now });
}
export async function deleteNote(uid: string, f: FormData) {
await db.deleteMany(notes, { where: { id: text(f.get("id"), 36), user_id: uid } });
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
await tx.exec(stmt);
});
}
const cell = (v: string | number) => {
let s = String(v);
if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
export async function exportCsv(uid: string) {
const [bs, is, ss] = await Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "asc"] }),
db.findMany(incomeSources, { where: { user_id: uid } }),
]);
const names = new Map(ss.map((s) => [s.id, s.name]));
const lines = ["date,type,name,qty,amount"];
for (const i of is) lines.push([i.day, "income", cell(names.get(i.source_id ?? "") ?? (String(parseJson(i.meta).name ?? "").trim() || "Other")), 1, fmt(i.amount_minor).replace(/,/g, "")].join(","));
for (const b of bs) lines.push([b.day, "buy", cell(b.name), b.qty, fmt(b.total_minor).replace(/,/g, "")].join(","));
return lines.join("\n");
}
export async function validateAndSetBackground(uid: string, rawUrl: string): Promise<string | null> {
	const trimmed = rawUrl.trim();
	if (!trimmed) return "Please enter an image URL.";
	let parsed: URL;
	try {
		parsed = new URL(trimmed);
	} catch {
		return "Invalid address.";
	}
	if (parsed.protocol !== "https:") {
		return "URL must use https.";
	}
	const host = parsed.hostname.toLowerCase();
	if (
		host === "localhost" ||
		host === "127.0.0.1" ||
		host === "::1" ||
		host === "0.0.0.0" ||
		host.endsWith(".local") ||
		host.endsWith(".internal") ||
		host.startsWith("10.") ||
		host.startsWith("192.168.") ||
		/^172\.(1[6-9]|2\d|3[01])\./.test(host) ||
		host.startsWith("169.254.")
	) {
		return "Invalid address.";
	}
	let res: Response;
	try {
		const controller = new AbortController();
		const timeoutId = setTimeout(() => controller.abort(), 6000);
		res = await fetch(parsed.toString(), {
			signal: controller.signal,
			headers: { "User-Agent": "Moneytracker/1.0" },
		});
		clearTimeout(timeoutId);
	} catch {
		return "Cannot download.";
	}
	if (!res.ok) {
		return "Cannot download.";
	}
	const cl = res.headers.get("content-length");
	if (cl && parseInt(cl, 10) > 5 * 1024 * 1024) {
		return "Too large.";
	}
	const ct = (res.headers.get("content-type") || "").toLowerCase().trim();
	if (!ct.startsWith("image/png") && !ct.startsWith("image/jpeg") && !ct.startsWith("image/jpg")) {
		return "Not a PNG or JPEG.";
	}
	let buffer: ArrayBuffer;
	try {
		buffer = await res.arrayBuffer();
	} catch {
		return "Cannot download.";
	}
	if (buffer.byteLength > 5 * 1024 * 1024) {
		return "Too large.";
	}
	if (buffer.byteLength < 8) {
		return "Not a PNG or JPEG.";
	}
	const bytes = new Uint8Array(buffer.slice(0, 8));
	const isPng = bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47;
	const isJpg = bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
	if (!isPng && !isJpg) {
		return "Not a PNG or JPEG.";
	}
	await updateBg(uid, { mode: "url", url: trimmed });
	return null;
}
export async function resetUserBackground(uid: string) {
	await updateBg(uid, { mode: "auto", url: "" });
}
__EOF_MT__
mkdir -p "app/lib"
cat > app/lib/data.ts << '__EOF_MT__'
import { sql } from "remix/data-table";
import { db, debtPayments, debts, goalItems, goals, incomes, incomeSources, notes, people, purchases, quickBuys } from "../db/index.ts";
import { settleAuto } from "./auto.ts";
import type { TradeSession } from "./trade-math.ts";
import { loadTrades } from "./trading.ts";
import { parseJson, type Json } from "./sources/index.ts";
import { addDays, dayLabel, today } from "./time.ts";
import { getActiveAvatar, type User } from "./users.ts";
export type Quick = { id: string; name: string; icon: string; price: number };
export type Buy = { id: string; name: string; qty: number; unit: number; total: number; day: string; at: number };
export type Income = { id: string; sourceId: string; source: string; amount: number; day: string; hours: number; locked: boolean };
export type Source = { id: string; name: string; mode: string; every: string; amount: number; created: number; type: string; config: Json; currency: string; active: boolean; sort: number };
export type DebtView = { id: string; person: string; kind: "money" | "item"; item: string; owed: number; paid: number };
export type GoalItem = { id: string; name: string; price: number; done: boolean };
export type Goal = { id: string; title: string; target: number; saved: number; done: boolean; items: GoalItem[] };
export type Note = { id: string; body: string; at: number; edited: boolean };
export type DayRow = { day: string; label: string; earned: number; bought: number; buys: Buy[]; incomes: Income[] };
export type Part = "quick" | "today" | "sources" | "debts" | "goals" | "notes" | "history" | "balance" | "avatar" | "names" | "trading";
export type State = {
user: User;
back: string;
error: string;
avatar: string | null;
quick: Quick[];
names: string[];
incomeNames: string[];
trades: TradeSession[];
buys: Buy[];
incomesToday: Income[];
sources: Source[];
debts: DebtView[];
goals: Goal[];
notes: Note[];
days: DayRow[];
balance: number;
};
const rowsOf = (r: unknown): any[] => (Array.isArray(r) ? r : ((r as any)?.rows ?? []));
const scalar = (r: unknown) => {
const row = rowsOf(r)[0];
return Number(row?.s ?? row?.[0] ?? 0) || 0;
};
export async function balanceOf(uid: string): Promise<number> {
await settleAuto(uid);
const [i, p] = await Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]);
return scalar(i) - scalar(p);
}
export async function loadState(user: User, parts: Part[], extra: { back: string; error?: string }): Promise<State> {
const need = new Set(parts);
const uid = user.id;
const t = today();
const s: State = {
user,
back: extra.back,
error: extra.error ?? "",
avatar: null,
quick: [],
names: [],
incomeNames: [],
trades: [],
buys: [],
incomesToday: [],
sources: [],
debts: [],
goals: [],
notes: [],
days: [],
balance: 0,
};
if (need.has("today") || need.has("sources") || need.has("history") || need.has("balance")) await settleAuto(uid);
const jobs: Promise<void>[] = [];
if (need.has("avatar")) jobs.push(getActiveAvatar(uid).then((a) => void (s.avatar = a)));
if (need.has("quick"))
jobs.push(
db.findMany(quickBuys, { where: { user_id: uid }, orderBy: ["sort", "asc"] }).then((rows) => {
s.quick = rows.map((r) => ({ id: r.id, name: r.name, icon: r.icon, price: r.price_minor }));
}),
);
const needSources = need.has("sources") || need.has("today") || need.has("history");
let sourceRows: Source[] = [];
if (needSources) {
const rows = await db.findMany(incomeSources, { where: { user_id: uid }, orderBy: ["created_at", "asc"] });
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
.sort((a, b) => a.sort - b.sort);
s.sources = sourceRows;
}
const byId = new Map(sourceRows.map((x) => [x.id, x.name]));
const toIncome = (r: { id: string; source_id: string | null; amount_minor: number; day: string; meta: string }): Income => {
const m = parseJson(r.meta);
return {
id: r.id,
sourceId: r.source_id ?? "",
source: byId.get(r.source_id ?? "") ?? (String(m.name ?? "").trim() || "Other"),
amount: r.amount_minor,
day: r.day,
hours: Number(m.hours) || 0,
locked: !!m.trade,
};
};
if (need.has("today")) {
jobs.push(
db.findMany(purchases, { where: { user_id: uid, day: t }, orderBy: ["created_at", "desc"] }).then((rows) => {
s.buys = rows.map(toBuy);
}),
db.findMany(incomes, { where: { user_id: uid, day: t } }).then((rows) => {
s.incomesToday = rows.map(toIncome);
}),
);
}
if (need.has("names"))
jobs.push(
db
.exec(sql`select min(name) as n, count(*) as c from purchases where user_id = ${uid} and debt_id is null and name not like 'Deposit % USDT' group by lower(name) order by c desc, max(created_at) desc`)
.then((r) => void (s.names = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
db
.exec(sql`select min(json_extract(meta, '$.name')) as n, count(*) as c from incomes where user_id = ${uid} and source_id is null and ext_key = '' and coalesce(json_extract(meta, '$.name'), '') <> '' group by lower(json_extract(meta, '$.name')) order by c desc, max(created_at) desc limit 30`)
.then((r) => void (s.incomeNames = rowsOf(r).map((x) => String(x.n ?? x[0] ?? "")).filter(Boolean))),
);
if (need.has("debts")) jobs.push(loadDebts(uid).then((d) => void (s.debts = d)));
if (need.has("trading")) jobs.push(loadTrades(uid).then((t) => void (s.trades = t)));
if (need.has("goals"))
jobs.push(
Promise.all([
db.findMany(goals, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
db.findMany(goalItems, { where: { user_id: uid }, orderBy: ["created_at", "asc"] }),
]).then(([rows, its]) => {
s.goals = rows.map((g) => {
const items: GoalItem[] = its.filter((i) => i.goal_id === g.id).map((i) => ({ id: i.id, name: i.name, price: i.price_minor, done: !!i.done_at }));
const left = items.filter((i) => !i.done);
return { id: g.id, title: g.title, target: left.reduce((a, i) => a + i.price, 0), saved: g.saved_minor, done: items.length > 0 && left.length === 0, items };
});
}),
);
if (need.has("notes"))
jobs.push(
db.findMany(notes, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 }).then((rows) => {
s.notes = rows.reverse().map((n) => ({ id: n.id, body: n.body, at: n.created_at, edited: n.updated_at - n.created_at > 1000 }));
}),
);
if (need.has("history")) {
jobs.push(
Promise.all([
db.findMany(purchases, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
db.findMany(incomes, { where: { user_id: uid }, orderBy: ["day", "desc"], limit: 2000 }),
]).then(([bs, is]) => {
s.days = Array.from({ length: 30 }, (_, i) => {
const day = addDays(t, -i);
const b = bs.filter((x) => x.day === day);
const inc = is.filter((x) => x.day === day);
return {
day,
label: dayLabel(day),
earned: inc.reduce((a, x) => a + x.amount_minor, 0),
bought: b.reduce((a, x) => a + x.total_minor, 0),
buys: b.map(toBuy),
incomes: inc.map(toIncome),
};
}).filter((d, i) => i === 0 || d.buys.length || d.incomes.length);
}),
);
}
if (need.has("balance"))
jobs.push(
Promise.all([
db.exec(sql`select coalesce(sum(amount_minor), 0) as s from incomes where user_id = ${uid}`),
db.exec(sql`select coalesce(sum(total_minor), 0) as s from purchases where user_id = ${uid}`),
]).then(([i, p]) => void (s.balance = scalar(i) - scalar(p))),
);
await Promise.all(jobs);
return s;
}
const toBuy = (r: { id: string; name: string; qty: number; unit_minor: number; total_minor: number; day: string; created_at: number }): Buy => ({
id: r.id,
name: r.name,
qty: r.qty,
unit: r.unit_minor,
total: r.total_minor,
day: r.day,
at: r.created_at,
});
async function loadDebts(uid: string): Promise<DebtView[]> {
const [pe, de, pay] = await Promise.all([
db.findMany(people, { where: { user_id: uid } }),
db.findMany(debts, { where: { user_id: uid } }),
db.findMany(debtPayments, { where: { user_id: uid } }),
]);
const names = new Map(pe.map((p) => [p.id, p.name]));
const paid = new Map<string, number>();
for (const p of pay) paid.set(p.debt_id, (paid.get(p.debt_id) ?? 0) + p.amount_minor);
return de
.map((d): DebtView => {
const kind = d.kind === "item" ? "item" : "money";
return {
id: d.id,
person: names.get(d.person_id) ?? "?",
kind,
item: d.item_name || "cig",
owed: kind === "item" ? (d.item_qty ?? 0) : d.amount_minor,
paid: paid.get(d.id) ?? 0,
};
})
.filter((d) => d.owed > 0)
.sort((a, b) => (a.kind === b.kind ? b.owed - a.owed : a.kind === "money" ? -1 : 1));
}
__EOF_MT__
mkdir -p "app/lib"
cat > app/lib/trade-math.ts << '__EOF_MT__'
export const DEPOSIT = 400;
export const BTC_STAKE = 100;
export const PRED_STAKE = 300;
export const BTC_ROUNDS = 4;
export const PRED_COUNT = 3;

export type Game = "btc" | "pred";
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number };
export type TradeSession = {
	id: string;
	day: string;
	deposit: number;
	rate: number;
	status: "open" | "settled";
	pnl: number;
	returnUsdt: number;
	returnMad: number;
	at: number;
	results: TradeResult[];
};

export const btcOf = (r: TradeResult[]) => r.filter((x) => x.game === "btc").sort((a, b) => a.idx - b.idx);
export const predOf = (r: TradeResult[]) => r.filter((x) => x.game === "pred").sort((a, b) => a.idx - b.idx);
export const btcLost = (r: TradeResult[]) => btcOf(r).some((x) => !x.won);
export const btcDone = (r: TradeResult[]) => btcLost(r) || btcOf(r).length >= BTC_ROUNDS;
export const predDone = (r: TradeResult[]) => predOf(r).length >= PRED_COUNT;
export const allDone = (r: TradeResult[]) => btcDone(r) && predDone(r);
export const totalPnl = (r: TradeResult[]) => r.reduce((a, x) => a + x.pnl, 0);
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl);
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100);
export const strip = (r: TradeResult[]) => r.map((x) => (x.won ? "W" : "L")).join(" ");
__EOF_MT__
mkdir -p "app/lib"
cat > app/lib/trading.ts << '__EOF_MT__'
import { sql } from "remix/data-table";
import { db, incomes, purchases, tradeResults, tradeSessions } from "../db/index.ts";
import { today } from "./time.ts";
import {
	allDone,
	backUsdt,
	BTC_ROUNDS,
	btcDone,
	btcOf,
	DEPOSIT,
	PRED_COUNT,
	toMad,
	totalPnl,
	type Game,
	type TradeResult,
	type TradeSession,
} from "./trade-math.ts";
import type { User } from "./users.ts";

const id = () => crypto.randomUUID();
const text = (v: unknown, max: number) => String(v ?? "").trim().slice(0, max);

const usdtMinor = (v: unknown) => {
	const raw = String(v ?? "").trim().replace(",", ".");
	if (!raw) return null;
	const n = Math.abs(Number(raw));
	return Number.isFinite(n) && n <= 100000 ? Math.round(n * 100) : null;
};

const toResult = (r: { id: string; game: string; idx: number; won: number; pnl_minor: number }): TradeResult => ({
	id: r.id,
	game: r.game === "pred" ? "pred" : "btc",
	idx: r.idx,
	won: r.won !== 0,
	pnl: r.pnl_minor,
});

async function resultsOf(uid: string, sessionId: string): Promise<TradeResult[]> {
	const rows = await db.findMany(tradeResults, { where: { user_id: uid, session_id: sessionId }, orderBy: ["created_at", "asc"] });
	return rows.map(toResult);
}

export async function loadTrades(uid: string): Promise<TradeSession[]> {
	const rows = await db.findMany(tradeSessions, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 30 });
	if (!rows.length) return [];
	const res = await db.findMany(tradeResults, { where: { user_id: uid }, orderBy: ["created_at", "desc"], limit: 500 });
	const by = new Map<string, TradeResult[]>();
	for (const r of res) {
		const list = by.get(r.session_id) ?? [];
		list.push(toResult(r));
		by.set(r.session_id, list);
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
	);
}

export async function startTrade(user: User): Promise<string | void> {
	const uid = user.id;
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } });
	if (open) return "Finish your open trade first";
	const cost = toMad(DEPOSIT, user.usdt_rate);
	if (!cost) return "Set the USDT price in Settings first";
	const now = Date.now();
	const day = today();
	const sessionId = id();
	const purchaseId = id();
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
		});
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
		});
	});
}

async function settle(uid: string, s: { id: string; deposit_minor: number; rate_minor: number }, results: TradeResult[]) {
	const pnl = totalPnl(results);
	const back = backUsdt(s.deposit_minor, pnl);
	const mad = toMad(back, s.rate_minor);
	const now = Date.now();
	const incomeId = mad > 0 ? id() : "";
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
			});
		}
		await tx.update(tradeSessions, s.id, {
			status: "settled",
			pnl_minor: pnl,
			return_usdt_minor: back,
			return_mad_minor: mad,
			income_id: incomeId,
			settled_at: now,
		});
	});
}

export async function saveResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const game: Game = f.get("game") === "pred" ? "pred" : "btc";
	const idx = Math.floor(Number(f.get("idx")));
	const max = game === "btc" ? BTC_ROUNDS : PRED_COUNT;
	if (!Number.isInteger(idx) || idx < 1 || idx > max) return "Unknown predict";
	const outcome = text(f.get("outcome"), 4);
	if (outcome !== "win" && outcome !== "lost") return "Pick Win or Lost";
	const amount = usdtMinor(f.get("pnl"));
	if (amount === null) return "Enter the PnL in USDT";
	const rows = await resultsOf(uid, s.id);
	if (rows.some((r) => r.game === game && r.idx === idx)) return "That predict already has a result";
	if (game === "btc") {
		if (btcDone(rows)) return "The Bitcoin predicts are finished";
		if (idx !== btcOf(rows).length + 1) return "Do the Bitcoin predicts in order";
	}
	const won = outcome === "win";
	const row = { id: id(), user_id: uid, session_id: s.id, game, idx, won: won ? 1 : 0, pnl_minor: won ? amount : -amount, created_at: Date.now() };
	await db.create(tradeResults, row);
	const next = [...rows, toResult(row)];
	if (allDone(next)) await settle(uid, s, next);
}

export async function undoResult(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const r = await db.findOne(tradeResults, { where: { id: text(f.get("result_id"), 36), session_id: s.id, user_id: uid } });
	if (!r) return;
	if (r.game === "btc") {
		const last = btcOf(await resultsOf(uid, s.id)).at(-1);
		if (last?.id !== r.id) return "Undo the latest Bitcoin predict first";
	}
	await db.deleteMany(tradeResults, { where: { id: r.id, user_id: uid } });
}

export async function finishTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s) return "Trade not found";
	if (s.status !== "open") return "This trade is already settled";
	const rows = await resultsOf(uid, s.id);
	if (!rows.length) return "Add at least one result first";
	await settle(uid, s, rows);
}

export async function reopenTrade(uid: string, f: FormData): Promise<string | void> {
	const s = await db.findOne(tradeSessions, { where: { id: text(f.get("session_id"), 36), user_id: uid } });
	if (!s || s.status !== "settled") return;
	const open = await db.findOne(tradeSessions, { where: { user_id: uid, status: "open" } });
	if (open) return "Finish your open trade first";
	const key = `trade:${s.id}`;
	await db.transaction(async (tx) => {
		await tx.exec(sql`delete from incomes where user_id = ${uid} and ext_key = ${key}`);
		await tx.exec(
			sql`update trade_sessions set status = 'open', income_id = '', settled_at = null, pnl_minor = 0, return_usdt_minor = 0, return_mad_minor = 0 where id = ${s.id} and user_id = ${uid}`,
		);
	});
}
__EOF_MT__
mkdir -p "app/lib"
cat > app/lib/users.ts << '__EOF_MT__'
import { db, oauthAccounts, passwords, quickBuys, userImages, users } from "../db/index.ts";
import { fakeVerify, hashPassword, verifyPassword } from "./password.ts";

export type User = {
	id: string;
	email: string;
	name: string;
	currency: string;
	theme: string;
	phone: string;
	bio: string;
	run_at: string;
	week_start: string;
	bg_mode: string;
	bg_url: string;
	usdt_rate: number;
};

const normEmail = (e: string) => e.trim().toLowerCase();
const toUser = (r: any): User => ({
	id: r.id,
	email: r.email,
	name: r.name,
	currency: r.currency || "MAD",
	theme: r.theme || "dark",
	phone: r.phone ?? "",
	bio: r.bio ?? "",
	run_at: r.run_at || "06:00",
	week_start: r.week_start || "Monday",
	bg_mode: r.bg_mode || "auto",
	bg_url: r.bg_url ?? "",
	usdt_rate: Number(r.usdt_rate_minor) > 0 ? Number(r.usdt_rate_minor) : 1100,
});

export async function getUserById(id: string): Promise<User | null> {
	const row = await db.find(users, id);
	return row ? toUser(row) : null;
}

const newUserRow = (id: string, email: string, name: string, verified: number, now: number) => ({
	id,
	email,
	name: name || email.split("@")[0]!,
	email_verified: verified,
	currency: "MAD",
	theme: "dark",
	phone: "",
	bio: "",
	run_at: "06:00",
	week_start: "Monday",
	bg_mode: "auto",
	bg_url: "",
	usdt_rate_minor: 1100,
	created_at: now,
	updated_at: now,
});

const DEFAULT_QUICK = [
	{ name: "Smoke", icon: "Smoke", price_minor: 200 },
	{ name: "Coffee", icon: "Coffee", price_minor: 1200 },
	{ name: "Bread", icon: "Bread", price_minor: 400 },
];

type Tx = Parameters<Parameters<typeof db.transaction>[0]>[0];
const seedQuick = (tx: Tx, userId: string) =>
	tx.createMany(
		quickBuys,
		DEFAULT_QUICK.map((q, i) => ({ id: crypto.randomUUID(), user_id: userId, ...q, sort: i })),
	);

export type SignUpResult = { ok: true; user: User } | { ok: false; error: string };

export async function signUpWithPassword(input: { name: string; email: string; password: string }): Promise<SignUpResult> {
	const email = normEmail(input.email);
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return { ok: false, error: "Enter a valid email." };
	if (input.password.length < 8) return { ok: false, error: "Password needs at least 8 characters." };
	if (input.password.length > 200) return { ok: false, error: "Password is too long." };
	if (await db.findOne(users, { where: { email } })) return { ok: false, error: "That email already has an account." };

	const hash = await hashPassword(input.password);
	const now = Date.now();
	const id = crypto.randomUUID();
	const row = newUserRow(id, email, input.name.trim().slice(0, 80), 0, now);

	try {
		await db.transaction(async (tx) => {
			await tx.create(users, row);
			await tx.create(passwords, { user_id: id, hash, updated_at: now });
			await seedQuick(tx, id);
		});
	} catch {
		// Two signups with the same email at the same moment hit the UNIQUE index.
		return { ok: false, error: "That email already has an account." };
	}
	return { ok: true, user: toUser(row) };
}

export async function signInWithPassword(emailRaw: string, password: string): Promise<User | null> {
	const user = await db.findOne(users, { where: { email: normEmail(emailRaw) } });
	const pw = user ? await db.findOne(passwords, { where: { user_id: user.id } }) : null;
	if (!user || !pw) {
		await fakeVerify(password);
		return null;
	}
	return (await verifyPassword(password, pw.hash)) ? toUser(user) : null;
}

type GoogleProfile = { id?: string; email?: string | null; name?: string | null; picture?: string | null };

/** Finds the user for this Google account, links it to an existing email, or creates a new user. */
export async function upsertFromGoogle(account: { providerAccountId: string }, profile: GoogleProfile): Promise<User> {
	const link = await db.findOne(oauthAccounts, { where: { provider: "google", provider_account_id: account.providerAccountId } });
	if (link) {
		const existing = await db.find(users, link.user_id);
		if (existing) return toUser(existing);
	}

	const email = normEmail(profile.email ?? "");
	if (!email) throw new Error("Google did not return an email.");
	const now = Date.now();

	return db.transaction(async (tx) => {
		let user = await tx.findOne(users, { where: { email } });
		if (!user) {
			user = await tx.create(users, newUserRow(crypto.randomUUID(), email, profile.name?.trim() ?? "", 1, now), { returnRow: true });
			await seedQuick(tx, user.id);
		}
		await tx.create(oauthAccounts, {
			id: crypto.randomUUID(),
			user_id: user.id,
			provider: "google",
			provider_account_id: account.providerAccountId,
			created_at: now,
		});
		if (profile.picture) {
			const hasAvatar = await tx.findOne(userImages, { where: { user_id: user.id, kind: "avatar", is_active: 1 } });
			if (!hasAvatar) {
				await tx.create(userImages, {
					id: crypto.randomUUID(),
					user_id: user.id,
					kind: "avatar",
					source: "google",
					url: profile.picture,
					mime: "",
					size_bytes: 0,
					is_active: 1,
					created_at: now,
				});
			}
		}
		return toUser(user);
	});
}

export async function getActiveAvatar(userId: string): Promise<string | null> {
	const img = await db.findOne(userImages, {
		where: { user_id: userId, kind: "avatar", is_active: 1 },
		orderBy: ["created_at", "desc"],
	});
	return img?.url ?? null;
}

export async function updateProfile(userId: string, input: { name: string; email: string }) {
	const email = normEmail(input.email);
	if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return "Enter a valid email.";
	const clash = await db.findOne(users, { where: { email } });
	if (clash && clash.id !== userId) return "That email belongs to another account.";
	await db.update(users, userId, {
		name: input.name.trim().slice(0, 80) || email.split("@")[0]!,
		email,
		updated_at: Date.now(),
	});
	return null;
}

export async function updatePrefs(userId: string, input: { currency: string; run_at: string; week_start: string; usdt_rate_minor: number }) {
	await db.update(users, userId, {
		currency: input.currency.trim().toUpperCase().slice(0, 8) || "MAD",
		run_at: /^([01]?\d|2[0-3]):[0-5]\d$/.test(input.run_at.trim()) ? input.run_at.trim().padStart(5, "0") : "06:00",
		week_start: input.week_start.trim().slice(0, 16) || "Monday",
		...(input.usdt_rate_minor > 0 && input.usdt_rate_minor <= 100000000 ? { usdt_rate_minor: input.usdt_rate_minor } : {}),
		updated_at: Date.now(),
	});
}

export async function setTheme(userId: string, theme: string) {
	if (theme !== "dark" && theme !== "light") return;
	await db.update(users, userId, { theme, updated_at: Date.now() });
}

export async function updateBg(userId: string, input: { mode: "auto" | "url"; url?: string }) {
	await db.update(users, userId, {
		bg_mode: input.mode,
		bg_url: input.mode === "url" ? (input.url ?? "").trim() : "",
		updated_at: Date.now(),
	});
}
__EOF_MT__
mkdir -p "app/lib"
cat > app/lib/view.ts << '__EOF_MT__'
/** Pure view helpers: numbers and labels derived from `State`. No markup in here. */
import type { DebtView, Goal, GoalItem, Source, State } from "./data.ts";
import { fmt } from "./money.ts";

export const LANG = "English";

/** 1250 (minor units) -> "12.5", for filling an input. */
export const plain = (n: number) => (n / 100).toFixed(2).replace(/\.00$/, "");

export function calc(s: State) {
	const earned = s.incomesToday.reduce((a, i) => a + i.amount, 0);
	const bought = s.buys.reduce((a, b) => a + b.total, 0);
	const bySource = new Map<string, number>();
	for (const i of s.incomesToday) bySource.set(i.source, (bySource.get(i.source) ?? 0) + i.amount);
	const earnedLine = [...bySource].map(([n, a]) => `${n} ${fmt(a)}`).join(" · ");
	const money = s.debts.filter((d) => d.kind === "money");
	const oweMoney = money.reduce((a, d) => a + d.owed, 0);
	const oweItems = s.debts.filter((d) => d.kind === "item").reduce((a, d) => a + d.owed, 0);
	const oweExtra = oweItems ? `+ ${oweItems} cig` : "";
	const wishTarget = s.goals.reduce((a, g) => a + g.target, 0);
	const wishSaved = Math.min(Math.max(0, s.balance), wishTarget);
	const debtPaid = money.reduce((a, d) => a + d.paid, 0);
	const total = wishTarget + oweMoney + debtPaid;
	const done = wishSaved + debtPaid;
	const pct = total ? Math.min(100, Math.round((done / total) * 100)) : 0;
	return { earned, bought, earnedLine, oweMoney, oweExtra, pct, toGo: Math.max(0, total - done) };
}

// ---------- goals ----------

export const covered = (s: State, g: Goal) => Math.min(Math.max(0, s.balance), g.target);
export const pctOf = (s: State, g: Goal) => (g.done ? 100 : g.target ? Math.min(100, Math.round((covered(s, g) / g.target) * 100)) : 0);
export const canBuy = (s: State, g: Goal) => g.target > 0 && s.balance >= g.target;

export const goalLeft = (s: State, g: Goal) =>
	g.done ? "all bought" : !g.items.length ? "no items yet" : canBuy(s, g) ? `${fmt(g.target)} ${s.user.currency} · ready` : `${fmt(g.target - covered(s, g))} to go`;

export function goalStat(s: State) {
	const target = s.goals.reduce((a, g) => a + g.target, 0);
	const saved = Math.min(Math.max(0, s.balance), target);
	const pct = target ? Math.min(100, Math.round((saved / target) * 100)) : s.goals.length && s.goals.every((g) => g.done) ? 100 : 0;
	return { target, pct, toGo: Math.max(0, target - saved) };
}

export const canAfford = (s: State, it: GoalItem) => s.balance >= it.price;

// ---------- debts ----------

export const debtPct = (d: DebtView) => (d.kind === "money" && d.paid + d.owed ? Math.round((d.paid / (d.paid + d.owed)) * 100) : 0);

export const peopleCount = (s: State) => new Set(s.debts.map((d) => d.person)).size;

// ---------- income ----------

export const srcAmount = (x: Source) => (x.type === "job" ? Number(x.config.fixed_minor) || 0 : x.amount);
export const srcRate = (x: Source) => (x.type === "job" ? Number(x.config.rate_minor) || 0 : 0);
export const gotToday = (s: State, x: Source) => s.incomesToday.filter((i) => i.sourceId === x.id);
export const sourceTag = (x: Source) => (!x.active ? "paused" : x.type === "job" ? "hours" : x.mode === "auto" ? (x.every === "month" ? "monthly" : "auto") : "manual");

// ---------- history ----------

export const dayNet = (earned: number, bought: number) => `${earned - bought < 0 ? "−" : "+"}${fmt(Math.abs(earned - bought))}`;
__EOF_MT__
mkdir -p "app/loaders"
cat > app/loaders/index.ts << '__EOF_MT__'
/**
 * Server loaders. Every screen declares which slices of the user's data it needs and one loader
 * fetches exactly those, on the server, before the page is rendered. Controllers call
 * `loadScreen()`, screens receive the finished `State` as a prop, and the JSON API reuses the
 * same loaders so the HTML and the JSON can never drift apart.
 */
import { loadState, type Part, type State } from "../lib/data.ts";
import type { User } from "../lib/users.ts";

export type ScreenKey = "home" | "debts" | "notes" | "goals" | "plan" | "income" | "history" | "profile" | "profileEdit" | "settings" | "pad" | "trading";

type ScreenDef = { path: string; parts: Part[]; first?: Part[] };

export const screenDefs: Record<ScreenKey, ScreenDef> = {
	home: { path: "/home", parts: ["today", "sources", "names", "debts", "goals", "notes", "balance"], first: ["today", "sources", "names", "debts", "goals", "balance"] },
	debts: { path: "/debts", parts: ["debts", "goals", "balance"] },
	notes: { path: "/notes", parts: ["notes"] },
	goals: { path: "/goals", parts: ["goals", "debts", "balance"] },
	plan: { path: "/plan", parts: ["goals", "debts", "sources", "today", "balance"] },
	income: { path: "/income", parts: ["sources", "today"] },
	history: { path: "/history", parts: ["history"] },
	profile: { path: "/profile", parts: ["avatar", "balance"] },
	profileEdit: { path: "/profile/edit", parts: ["avatar", "balance"] },
	settings: { path: "/settings", parts: ["balance"] },
	pad: { path: "/pad", parts: [] },
	trading: { path: "/trading", parts: ["trading"] },
};

export const isScreen = (key: string): key is ScreenKey => Object.hasOwn(screenDefs, key);

export function loadScreen(user: User, key: ScreenKey, error = "", first = false): Promise<State> {
	const def = screenDefs[key];
	return loadState(user, first && def.first ? def.first : def.parts, { back: def.path, error });
}

export const loadFrame = (user: User, back: string, parts: Part[]): Promise<State> => loadState(user, parts, { back });
__EOF_MT__
mkdir -p "app"
cat > app/routes.ts << '__EOF_MT__'
/**
 * Every URL the app answers, grouped by what it is for. Each group is handled by exactly one
 * controller in `controllers/`:
 *
 *   pages     server-rendered screens (GET)            -> controllers/pages.tsx
 *   auth      login, signup, logout, Google, delete    -> controllers/auth.tsx
 *   commands  form posts that change data              -> controllers/commands.ts
 *   api       the same data as JSON                    -> controllers/api.ts
 *   assets    manifest, icons, service worker, css, js -> controllers/assets.ts
 */
import { get, post, route } from "remix/routes";

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
		frameNotes: get("/frames/notes"),
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
		deleteIncome: post("/income/delete"),
		toggleSource: post("/income/toggle"),
		editSource: post("/income/edit"),
		deleteSource: post("/income/source/delete"),
		setHours: post("/income/hours"),
		tradeDeposit: post("/trading/deposit"),
		tradeResult: post("/trading/result"),
		tradeUndo: post("/trading/undo"),
		tradeFinish: post("/trading/finish"),
		tradeReopen: post("/trading/reopen"),
		addPlan: post("/plan"),
		saveProfile: post("/profile/edit"),
		saveSettings: post("/settings"),
		quickBuy: post("/settings/quick"),
		setTheme: post("/settings/theme"),
		setBackground: post("/settings/background"),
		resetBackground: post("/settings/background/reset"),
	},

	api: route("/api", {
		me: get("/me"),
		screen: get("/screens/:screen"),
		command: post("/commands/:name"),
	}),

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
		theme: get("/assets/theme.js"),
		entry: get("/assets/entry.js"),
	},
});
__EOF_MT__
mkdir -p "app/screens"
cat > app/screens/index.ts << '__EOF_MT__'
/** Every screen, in one place. A screen is a route-level component: it lays out one page. */
export { DebtsScreen } from "./debts.tsx";
export { GoalsScreen } from "./goals.tsx";
export { HistoryScreen } from "./history.tsx";
export { HomeScreen } from "./home.tsx";
export { IncomeScreen } from "./income.tsx";
export { NotesScreen } from "./notes.tsx";
export { PadScreen } from "./pad.tsx";
export { TradingScreen } from "./trading.tsx";
export { ProfileEditScreen, ProfileScreen, SettingsScreen } from "./profile.tsx";
export { LoginScreen, SignupScreen } from "./auth.tsx";
__EOF_MT__
mkdir -p "app/screens"
cat > app/screens/trading.tsx << '__EOF_MT__'
import { AppLayout } from "../components/Layout.tsx";
import { TradingBody } from "../components/trading.tsx";
import { ErrorBanner, PageHeader } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";
import { fmt } from "../lib/money.ts";

export const TradingScreen = view<{ s: State }>(({ s }) => {
	const right = `1 USDT = ${fmt(s.user.usdt_rate)} ${s.user.currency}`;
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
	);
});
__EOF_MT__
mkdir -p "database"
cat > database/schema.sql << '__EOF_MT__'
-- moneytracker schema (SQLite / Turso). Safe to run many times.
-- Run with: npm run db:migrate
-- Money is stored as integer minor units (MAD * 100). Times are unix ms.

PRAGMA foreign_keys = ON;

-- ---------- auth ----------

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE,          -- always lowercase
  name          TEXT NOT NULL DEFAULT '',
  email_verified INTEGER NOT NULL DEFAULT 0,
  currency      TEXT NOT NULL DEFAULT 'MAD',
  theme         TEXT NOT NULL DEFAULT 'dark',  -- dark | light
  phone         TEXT NOT NULL DEFAULT '',
  bio           TEXT NOT NULL DEFAULT '',
  run_at        TEXT NOT NULL DEFAULT '06:00',
  week_start    TEXT NOT NULL DEFAULT 'Monday',
  bg_mode       TEXT NOT NULL DEFAULT 'auto',
  bg_url        TEXT NOT NULL DEFAULT '',
  usdt_rate_minor INTEGER NOT NULL DEFAULT 1100,
  created_at    INTEGER NOT NULL,
  updated_at    INTEGER NOT NULL
);

-- Password hashes live apart from users. Google-only users have no row here.
CREATE TABLE IF NOT EXISTS passwords (
  user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  hash          TEXT NOT NULL,                 -- pbkdf2$iterations$salt$hash
  updated_at    INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  id            TEXT PRIMARY KEY,
  user_id       TEXT REFERENCES users(id) ON DELETE CASCADE,  -- null until signed in
  data          TEXT NOT NULL,                 -- JSON from remix session
  created_at    INTEGER NOT NULL,
  expires_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user_idx    ON sessions(user_id);
CREATE INDEX IF NOT EXISTS sessions_expires_idx ON sessions(expires_at);

-- Linked login providers (Google today).
CREATE TABLE IF NOT EXISTS oauth_accounts (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider      TEXT NOT NULL,
  provider_account_id TEXT NOT NULL,
  created_at    INTEGER NOT NULL,
  UNIQUE (provider, provider_account_id)
);
CREATE INDEX IF NOT EXISTS oauth_user_idx ON oauth_accounts(user_id);

-- ---------- images ----------

CREATE TABLE IF NOT EXISTS user_images (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kind          TEXT NOT NULL DEFAULT 'avatar',   -- avatar | cover | other
  source        TEXT NOT NULL DEFAULT 'upload',   -- upload | google
  url           TEXT NOT NULL,                    -- remote url or your storage key
  mime          TEXT,
  size_bytes    INTEGER,
  is_active     INTEGER NOT NULL DEFAULT 1,
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS user_images_user_idx ON user_images(user_id, kind, is_active);

-- ---------- app data ----------

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
  mode          TEXT NOT NULL DEFAULT 'manual',   -- auto | manual
  amount_minor  INTEGER NOT NULL DEFAULT 0,       -- for auto sources
  every         TEXT,                             -- day | week | month (auto)
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
  day           TEXT NOT NULL,                    -- YYYY-MM-DD
  created_at    INTEGER NOT NULL,
  meta          TEXT NOT NULL DEFAULT '{}',
  ext_key       TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS incomes_day_idx ON incomes(user_id, day);
-- one payout per source per day (auto income and once-a-day manual sources)
CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_uq ON incomes(user_id, ext_key) WHERE ext_key <> '';

CREATE TABLE IF NOT EXISTS purchases (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  qty           INTEGER NOT NULL DEFAULT 1,
  unit_minor    INTEGER NOT NULL,                 -- price each
  total_minor   INTEGER NOT NULL,
  day           TEXT NOT NULL,                    -- YYYY-MM-DD
  debt_id       TEXT,                             -- set when it is a debt payment
  created_at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS purchases_day_idx ON purchases(user_id, day);

-- People are never deleted; paid ones are just hidden from the picker.
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
  kind          TEXT NOT NULL DEFAULT 'money',    -- money | item
  item_name     TEXT,                             -- e.g. cigarette
  item_qty      INTEGER,
  amount_minor  INTEGER NOT NULL DEFAULT 0,       -- owed now
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

-- ---------- trading ----------

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
  created_at    INTEGER NOT NULL,
  UNIQUE (session_id, game, idx)
);
CREATE INDEX IF NOT EXISTS trade_results_user_idx ON trade_results(user_id, created_at);
__EOF_MT__
mkdir -p "scripts"
cat > scripts/migrate.ts << '__EOF_MT__'
/**
 * Applies database/schema.sql to the Turso database named in your env.
 *   npm run db:migrate
 * Same database for local dev and Cloudflare, so run it once. Safe to run again.
 */
import { createClient } from "@libsql/client";
import { readFileSync } from "node:fs";

const url = process.env.TURSO_DATABASE_URL;
const authToken = process.env.TURSO_AUTH_TOKEN;
if (!url) throw new Error("TURSO_DATABASE_URL is not set (put it in .dev.vars)");

const client = createClient({ url, authToken });
const schema = readFileSync(new URL("../database/schema.sql", import.meta.url), "utf8");

await client.executeMultiple(schema);

// Columns added after the first version. A database created earlier gets them here.
const addColumns = [
"ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT ''",
"ALTER TABLE users ADD COLUMN bio TEXT NOT NULL DEFAULT ''",
"ALTER TABLE users ADD COLUMN run_at TEXT NOT NULL DEFAULT '06:00'",
"ALTER TABLE users ADD COLUMN week_start TEXT NOT NULL DEFAULT 'Monday'",
"ALTER TABLE quick_buys ADD COLUMN price_minor INTEGER NOT NULL DEFAULT 0",
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
];
for (const statement of addColumns) {
try {
await client.execute(statement);
console.log("added:", statement);
} catch (err) {
if (!/duplicate column/i.test(String(err))) throw err;
}
}

await client.execute("CREATE UNIQUE INDEX IF NOT EXISTS incomes_ext_key_idx ON incomes(ext_key) WHERE ext_key <> ''");
await client.execute("INSERT INTO goal_items (id, user_id, goal_id, name, price_minor, done_at, created_at) SELECT lower(hex(randomblob(16))), user_id, id, title, target_minor, NULL, created_at FROM goals g WHERE target_minor > 0 AND NOT EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = g.id)");
await client.execute("UPDATE goals SET target_minor = 0 WHERE target_minor > 0 AND EXISTS (SELECT 1 FROM goal_items i WHERE i.goal_id = goals.id)");

const { rows } = await client.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
console.log("tables:", rows.map((r) => r.name).join(", "));
client.close();
__EOF_MT__
if [ -f .dev.vars ] && command -v bun >/dev/null 2>&1; then
bun run db:migrate
else
echo "Now run: bun run db:migrate"
fi
echo "file6 done"
