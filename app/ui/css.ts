/** Global stylesheet. Same tokens, type and components as the design file, made responsive. */
export const css = String.raw`
html{--bg:#121212;--s1:#181818;--s2:#202020;--ln:rgba(255,255,255,0.12);--ink:#f5f5f5;--mu:#8c8c8c;--pos:#3ddc84;--neg:#ff5a4d;--sh:#000;--bub:rgba(255,255,255,0.08);--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;--font-sys:-apple-system,BlinkMacSystemFont,"SF Pro Text","SF Pro Display","SF Pro",system-ui,sans-serif;--glass-bg:rgba(24,24,30,0.68);--glass-border:rgba(255,255,255,0.13);--glass-shadow:0 12px 36px -4px rgba(0,0,0,0.45),0 4px 14px -2px rgba(0,0,0,0.25),inset 0 1px 0 rgba(255,255,255,0.18);--glass-radius:20px;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#fff;--s1:#fafafa;--s2:#f1f1f1;--ln:rgba(0,0,0,0.08);--ink:#000;--mu:#6e6e6e;--pos:#12a150;--neg:#e0382b;--sh:#cfcfcf;--bub:rgba(0,0,0,0.05);--glass-bg:rgba(255,255,255,0.76);--glass-border:rgba(255,255,255,0.75);--glass-shadow:0 12px 36px -4px rgba(0,0,0,0.08),0 4px 14px -2px rgba(0,0,0,0.04),inset 0 1px 0 rgba(255,255,255,0.9)}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ink);outline-offset:2px}
::selection{background:var(--ink);color:var(--bg)}
[hidden]{display:none!important}

/* Auto background gradients (iPhone 17 aesthetic) */
body{color:var(--ink);font:14px/1.45 var(--font-sys);font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh;background-color:#0c0d12;background-attachment:fixed;background-size:cover;background-position:center;transition:background 0.3s ease}
html[data-period="morning"] body{background:radial-gradient(circle at 85% 15%,rgba(255,145,100,0.32),transparent 45%),radial-gradient(circle at 15% 30%,rgba(240,90,160,0.22),transparent 40%),radial-gradient(circle at 50% 85%,rgba(65,50,120,0.42),transparent 60%),linear-gradient(180deg,#161024 0%,#0c0915 100%)}
html[data-period="morning"][data-theme="light"] body{background:radial-gradient(circle at 85% 15%,rgba(255,185,150,0.65),transparent 50%),radial-gradient(circle at 20% 35%,rgba(255,205,225,0.55),transparent 45%),radial-gradient(circle at 60% 85%,rgba(195,215,255,0.45),transparent 55%),linear-gradient(180deg,#fcf3ee 0%,#e9e5f4 100%)}
html[data-period="day"] body{background:radial-gradient(circle at 80% 20%,rgba(0,160,255,0.3),transparent 45%),radial-gradient(circle at 15% 45%,rgba(95,45,230,0.32),transparent 50%),radial-gradient(circle at 70% 90%,rgba(0,220,190,0.18),transparent 40%),linear-gradient(180deg,#0c1326 0%,#050813 100%)}
html[data-period="day"][data-theme="light"] body{background:radial-gradient(circle at 80% 15%,rgba(160,220,255,0.6),transparent 45%),radial-gradient(circle at 15% 40%,rgba(190,185,255,0.55),transparent 45%),radial-gradient(circle at 75% 85%,rgba(175,240,230,0.45),transparent 50%),linear-gradient(180deg,#eff6ff 0%,#e7ecf7 100%)}
html[data-period="evening"] body{background:radial-gradient(circle at 80% 25%,rgba(255,110,60,0.35),transparent 45%),radial-gradient(circle at 20% 40%,rgba(190,30,110,0.32),transparent 45%),radial-gradient(circle at 50% 80%,rgba(60,25,100,0.45),transparent 55%),linear-gradient(180deg,#190b18 0%,#09030c 100%)}
html[data-period="evening"][data-theme="light"] body{background:radial-gradient(circle at 80% 20%,rgba(255,175,130,0.65),transparent 45%),radial-gradient(circle at 15% 45%,rgba(250,170,205,0.55),transparent 45%),radial-gradient(circle at 60% 85%,rgba(200,170,230,0.45),transparent 50%),linear-gradient(180deg,#fff1ea 0%,#ede0ef 100%)}
html[data-period="night"] body{background:radial-gradient(circle at 85% 20%,rgba(90,45,175,0.28),transparent 45%),radial-gradient(circle at 15% 65%,rgba(20,80,130,0.25),transparent 45%),radial-gradient(circle at 60% 90%,rgba(10,110,95,0.18),transparent 40%),linear-gradient(180deg,#080810 0%,#020204 100%)}
html[data-period="night"][data-theme="light"] body{background:radial-gradient(circle at 85% 20%,rgba(190,185,235,0.5),transparent 45%),radial-gradient(circle at 15% 60%,rgba(170,205,230,0.45),transparent 45%),radial-gradient(circle at 60% 90%,rgba(175,215,210,0.4),transparent 45%),linear-gradient(180deg,#f1f2f8 0%,#e1e4ed 100%)}

/* Custom background URL with readable overlay */
body[data-bg-mode="url"]{background-image:linear-gradient(rgba(0,0,0,0.68),rgba(0,0,0,0.68)),var(--user-bg-url)!important;background-size:cover!important;background-position:center!important;background-attachment:fixed!important}
html[data-theme="light"] body[data-bg-mode="url"]{background-image:linear-gradient(rgba(255,255,255,0.72),rgba(255,255,255,0.72)),var(--user-bg-url)!important}
body.bg-fallback-auto{background-image:none!important}

a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}button{cursor:pointer}
.mu,.lb{color:var(--mu)}.lb{font-size:11px;font-family:var(--mono)}.pos{color:var(--pos)!important}.neg{color:var(--neg)!important}.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}summary::-webkit-details-marker{display:none}

/* Smooth press effect */
button,input[type=button],input[type=submit],.btn,.sbl,.qk button,.qk4 button,.chip,.ib{transition:transform .12s cubic-bezier(0.2,0.8,0.2,1),opacity .12s ease}
button:active,.btn:active,.sbl:active,.qk button:active,.qk4 button:active,.chip:active,.ib:active{transform:scale(.965);opacity:.88}

/* live clock */
.top-status-bar{display:flex;justify-content:flex-end;align-items:center;padding:12px 16px 2px}
.live-clock{display:flex;flex-direction:column;align-items:flex-end;text-align:right;user-select:none}
.clock-time{font-size:28px;font-weight:700;letter-spacing:-0.03em;line-height:1;font-family:var(--font-sys)}
.clock-date{font-size:13px;font-weight:600;opacity:.88;margin-top:3px;letter-spacing:-0.01em;font-family:var(--font-sys)}
.clock-subdate{font-size:12px;font-weight:600;opacity:.82;margin-top:3px;letter-spacing:0.02em;direction:ltr;unicode-bidi:isolate;display:inline-flex;align-items:center;justify-content:flex-end;gap:5px}
.clock-num{font-family:var(--font-sys);font-variant-numeric:tabular-nums;font-weight:600}
.clock-dot{opacity:.5}
.clock-ar{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI Arabic","Noto Sans Arabic","Geeza Pro",system-ui,sans-serif;font-weight:600;font-size:12px}
.tf-clock{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:14px;z-index:30;display:flex;align-items:center;gap:12px}

/* Centered middle auth */
.auth-viewport{min-height:100dvh;width:100%;display:flex;align-items:center;justify-content:center;padding:24px 16px;box-sizing:border-box}
.auth-center-wrap{width:100%;max-width:440px;margin:auto;display:flex;flex-direction:column;align-items:center;justify-content:center}
.auth-glass-box{width:100%;background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:28px;padding:38px 32px 34px;box-shadow:var(--glass-shadow);-webkit-backdrop-filter:blur(32px) saturate(190%);backdrop-filter:blur(32px) saturate(190%)}
@media(max-width:480px){.auth-glass-box{padding:30px 20px 26px;border-radius:24px}}
.auth-logo-center{display:flex;justify-content:center;margin-bottom:16px}
.auth-title{text-align:center;font-size:38px;font-weight:700;letter-spacing:-0.04em;line-height:1.15;margin-bottom:8px;font-family:var(--font-sys);color:var(--ink)}
.auth-sub{text-align:center;color:var(--mu);font-size:14px;margin-bottom:22px;letter-spacing:-0.01em}
.auth-err-banner{background:rgba(255,90,77,0.15);border:1px solid rgba(255,90,77,0.35);border-radius:12px;padding:10px 14px;color:var(--neg);font-size:13px;font-weight:500;text-align:center;margin:12px 0}
.auth-switch-wrap{display:flex;justify-content:center;margin-top:22px;text-align:center}
.lnk-switch{font-size:14px;color:var(--mu);text-decoration:none;transition:color .15s}
.lnk-switch b{color:var(--ink);text-decoration:underline;text-underline-offset:3px}
.lnk-switch:hover{color:var(--ink)}

/* responsive switch: .m = mobile only, .d = desktop only */
@media(min-width:900px){.m{display:none!important}}
@media(max-width:899px){.d{display:none!important}}

/* app frame */
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
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--glass-bg);-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib.sm{width:28px;height:28px}.ib.hi{background:var(--ink);color:var(--bg);border-color:var(--ink)}

/* bottom bar (phone), iPhone glass style */
.bt{display:flex;align-items:center;height:55px;border-top:1px solid var(--glass-border);background:var(--glass-bg);-webkit-backdrop-filter:blur(28px) saturate(190%);backdrop-filter:blur(28px) saturate(190%);box-shadow:var(--glass-shadow);border-radius:24px 24px 0 0;padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{width:26px;height:26px}
.bt .on{color:var(--ink)}.bt .on svg.ic{stroke-width:2.4}
.bt .lg svg{opacity:.55;width:26px;height:26px;border-radius:7px}.bt .lg.on svg{opacity:1}

/* sidebar (desktop), iPhone glass style */
.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--glass-border);background:color-mix(in srgb,var(--glass-bg) 85%,transparent);-webkit-backdrop-filter:blur(28px) saturate(180%);backdrop-filter:blur(28px) saturate(180%);padding:14px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:30px;font-size:17px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
.sbl:hover{background:var(--s2)}.sbl.on{font-weight:700}.sbl.on svg.ic{stroke-width:2.4}
.sbl svg.ic{width:26px;height:26px}
.sp{flex:1}

/* type */
h1.t{font-size:28px;font-weight:700;letter-spacing:-.05em;line-height:1}
.hd{display:flex;justify-content:space-between;align-items:center;margin:16px 0 2px;min-height:34px}
.hd h1.t,.hd .lb{font-size:14px;line-height:1.45}.hd h1.t{font-weight:600;letter-spacing:-.01em}
.back{display:flex;align-items:center;gap:6px;background:none;border:0;color:var(--ink)}
.big{font-size:48px;font-weight:600;letter-spacing:-.06em;line-height:.95}.big small{font-size:14px;color:var(--mu);font-weight:400;letter-spacing:0}
.big2{font-size:28px;font-weight:600;letter-spacing:-.05em;line-height:1}.big2 small{font-size:12px;color:var(--mu);font-weight:400;letter-spacing:0}

/* iPhone 17 translucent glass cards */
.cd{background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:var(--glass-radius);-webkit-backdrop-filter:blur(28px) saturate(190%);backdrop-filter:blur(28px) saturate(190%);box-shadow:var(--glass-shadow);margin-top:14px}
@supports not ((-webkit-backdrop-filter:blur(20px)) or (backdrop-filter:blur(20px))){.cd{background:var(--s1)}}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}.two .cb{padding:3px 12px 10px}.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--ln);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ink);border-radius:4px}
.mt.n i{background:var(--neg)}.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:12px}
.chip{border:1px solid var(--glass-border);border-radius:24px;padding:6px 14px;font-size:12px;background:rgba(255,255,255,0.06);color:var(--mu);font-family:var(--font-sys);font-weight:500;letter-spacing:-.01em;cursor:pointer;-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);transition:all .15s ease}
html[data-theme=light] .chip{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.1)}
.chip:hover{background:rgba(255,255,255,0.12);color:var(--ink)}
.chip.on{background:var(--ink);color:var(--bg);border-color:var(--ink);box-shadow:0 3px 10px rgba(0,0,0,0.25)}
.chip.n{color:var(--neg);border-color:rgba(255,90,77,0.3)}

/* iPhone 17 controls */
.btn{font-weight:600;font-size:14px;background:var(--ink);color:var(--bg);border:1px solid var(--ink);border-radius:14px;padding:11px 20px;flex:none;transition:all .15s cubic-bezier(0.2,0.8,0.2,1);display:inline-flex;align-items:center;justify-content:center;gap:8px;text-align:center;box-shadow:0 4px 14px -2px rgba(0,0,0,0.32),inset 0 1px 0 rgba(255,255,255,0.25)}
.btn:hover{filter:brightness(1.08)}
.btn.o{background:rgba(255,255,255,0.06);color:var(--ink);border:1px solid var(--glass-border);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);box-shadow:0 2px 8px rgba(0,0,0,0.15),inset 0 1px 0 rgba(255,255,255,0.12)}
html[data-theme=light] .btn.o{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.12);box-shadow:0 2px 8px rgba(0,0,0,0.04),inset 0 1px 0 rgba(255,255,255,0.8)}
.btn.dng{background:rgba(255,90,77,0.14);color:var(--neg);border:1px solid rgba(255,90,77,0.38);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);box-shadow:0 2px 8px rgba(255,90,77,0.12)}
.btn.xs{padding:6px 14px;font-size:12px;border-radius:10px;font-weight:600}
.btn.full{width:100%;padding:13px;border-radius:14px;margin-top:16px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;font-weight:500;color:var(--mu);margin-bottom:6px;letter-spacing:-.01em}

/* iPhone 17 glass inputs */
.in{width:100%;min-width:0;background:rgba(255,255,255,0.06);border:1px solid var(--glass-border);border-radius:14px;padding:10px 14px;outline:0;color:var(--ink);font-size:15px;font-family:inherit;transition:all .18s cubic-bezier(0.2,0.8,0.2,1);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px)}
html[data-theme=light] .in{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.1)}
.in:focus,.in.f:focus{border-color:var(--ink);background:rgba(255,255,255,0.12);box-shadow:0 0 0 3px rgba(255,255,255,0.1)}
html[data-theme=light] .in:focus{background:rgba(0,0,0,0.06);box-shadow:0 0 0 3px rgba(0,0,0,0.08)}
.in::placeholder{color:var(--mu);opacity:.55}
.ln{display:flex;gap:10px;align-items:center}

.stp{display:flex;align-items:center;gap:8px}.stp .in{text-align:center;width:56px;padding:8px 6px;border-radius:12px}
.stp button{width:34px;height:34px;border:1px solid var(--glass-border);background:rgba(255,255,255,0.08);border-radius:50%;font-size:17px;font-weight:600;display:inline-flex;align-items:center;justify-content:center;flex:none;-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);color:var(--ink)}
html[data-theme=light] .stp button{background:rgba(0,0,0,0.05);border-color:rgba(0,0,0,0.1)}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:12px 16px;border-radius:14px;border:1px solid var(--glass-border);background:var(--glass-bg);-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px);box-shadow:var(--glass-shadow);font-weight:600;font-size:14px;color:var(--ink)}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ink);text-decoration:underline;text-underline-offset:3px;padding:0;font-size:13px;font-weight:500}

/* iOS segmented control */
.sg{display:flex;border:1px solid var(--glass-border);background:rgba(255,255,255,0.06);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);border-radius:14px;padding:4px;gap:4px}
html[data-theme=light] .sg{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.1)}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:8px 12px;color:var(--mu);font-weight:600;font-size:13px;border-radius:10px;transition:all .15s ease}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--ink);color:var(--bg);box-shadow:0 2px 8px rgba(0,0,0,0.25)}

/* quick buys iPhone tiles */
.qk{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:12px}
.qk button{display:flex;flex-direction:column;align-items:center;gap:6px;padding:14px 6px 12px;border:1px solid var(--glass-border);background:var(--glass-bg);border-radius:18px;-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px);box-shadow:0 4px 14px rgba(0,0,0,0.18),inset 0 1px 0 rgba(255,255,255,0.15);color:var(--ink)}
html[data-theme=light] .qk button{background:rgba(255,255,255,0.7);box-shadow:0 4px 14px rgba(0,0,0,0.05),inset 0 1px 0 rgba(255,255,255,0.9)}
.qk button.on{background:var(--ink);color:var(--bg);border-color:var(--ink);box-shadow:0 6px 20px rgba(0,0,0,0.32)}.qk button.on small{color:var(--bg);opacity:.7}
.qk span{font-weight:600;font-size:13px}.qk small{font-size:11px;color:var(--mu);font-family:var(--mono)}
.pn{display:flex;gap:16px;align-items:flex-end;flex-wrap:wrap}
.tt{display:flex;align-items:center;gap:12px;margin-top:16px}.tt b{flex:1;font-size:26px;letter-spacing:-.04em}

/* rows */
.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--glass-border);background:rgba(255,255,255,0.06);border-radius:12px;padding:2px 8px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:rgba(255,255,255,0.06);border:1px solid var(--glass-border);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);border-radius:16px;padding:12px 14px;margin:4px 0 10px}.ad label{font-size:12px;color:var(--mu);display:block;margin-bottom:6px}.ad .ln{margin:2px 0 4px}
html[data-theme=light] .ad{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.1)}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ln3{display:flex;gap:12px;align-items:center}.n3{width:76px;flex:none}

/* notes = message yourself */
.ch{display:flex;gap:12px;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln);margin-bottom:6px}
.ch b{font-size:16px;letter-spacing:-.02em}
.av{width:72px;height:72px;border-radius:50%;background:var(--ink);color:var(--bg);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:700}
.av.s{width:40px;height:40px;font-size:16px}
.day{text-align:center;margin:14px 0 8px}.day span{font-size:12px;color:var(--mu);background:var(--s2);border-radius:10px;padding:3px 11px}
.msg{display:flex;flex-direction:column;align-items:flex-end;margin:4px 0}
.bub{max-width:82%;background:var(--bub);border-radius:16px 16px 4px 16px;padding:9px 13px;white-space:pre-wrap;cursor:pointer}.bub.sel{outline:1.5px solid var(--ink)}
.meta{font-size:11px;color:var(--mu);margin-top:3px;font-family:var(--mono)}
.acts{display:flex;gap:6px;margin-top:6px}
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:transparent}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}.cm .eb b{font-weight:600}.cm .eb button{background:none;border:0;color:var(--mu)}
.cin{display:flex;gap:8px;align-items:center}.cin textarea{flex:1;background:rgba(255,255,255,0.08);border:1px solid var(--glass-border);border-radius:24px;padding:12px 18px;resize:none;outline:0;font-size:15px;color:var(--ink);-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);transition:all .15s}
html[data-theme=light] .cin textarea{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.1)}
.cin textarea:focus{border-color:var(--ink);background:rgba(255,255,255,0.12)}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ink);color:var(--bg);display:flex;align-items:center;justify-content:center;box-shadow:0 4px 14px rgba(0,0,0,0.3)}
.chat{max-width:640px;margin:0 auto}

/* profile */
.li{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;border-radius:14px;background:none;border:0;width:100%;text-align:left;color:var(--ink);transition:background .15s}.li:hover{background:var(--s2)}.li:last-child{border:0}.li:first-child{padding-top:14px}

/* desktop sections */
.hero{display:grid;grid-template-columns:repeat(4,1fr);border:1px solid var(--glass-border);border-radius:var(--glass-radius);background:var(--glass-bg);-webkit-backdrop-filter:blur(28px) saturate(190%);backdrop-filter:blur(28px) saturate(190%);box-shadow:var(--glass-shadow);margin:20px 0 16px;overflow:hidden}
.hero>div{padding:24px 26px;border-left:1px solid var(--glass-border)}.hero>div:first-child{border:0;padding-left:26px}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:36px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:36px}
.sc{margin-top:24px;background:var(--glass-bg);border:1px solid var(--glass-border);border-radius:var(--glass-radius);padding:18px 22px 20px;-webkit-backdrop-filter:blur(28px) saturate(190%);backdrop-filter:blur(28px) saturate(190%);box-shadow:var(--glass-shadow)}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:12px;border-bottom:1px solid var(--glass-border);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:16px}
.qk4 button{display:flex;align-items:center;gap:12px;padding:14px 16px;border:1px solid var(--glass-border);background:var(--glass-bg);border-radius:18px;color:var(--ink);text-align:left;-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px);box-shadow:0 4px 14px rgba(0,0,0,0.18)}
html[data-theme=light] .qk4 button{background:rgba(255,255,255,0.7);box-shadow:0 4px 14px rgba(0,0,0,0.05)}
.qk4 button.on{background:var(--ink);color:var(--bg);border-color:var(--ink);box-shadow:0 6px 20px rgba(0,0,0,0.32)}
.qk4 b{display:block;font-size:14px}.qk4 small{font-size:12px;opacity:.65;font-family:var(--mono)}
.qrow{display:flex;align-items:center;gap:16px;margin-top:16px;padding:16px 18px;border:1px solid var(--glass-border);background:var(--glass-bg);border-radius:18px;-webkit-backdrop-filter:blur(20px);backdrop-filter:blur(20px);box-shadow:var(--glass-shadow);flex-wrap:wrap}
.qrow .eq{font-size:22px;font-weight:600;letter-spacing:-.04em}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
.sl{background:var(--ink);color:var(--bg);padding:48px;display:flex;flex-direction:column;justify-content:space-between}
.sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
.sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
.wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.au .in{background:rgba(255,255,255,0.08);border:1px solid var(--glass-border);border-radius:14px;padding:13px 16px;font-size:15px;transition:all .18s;-webkit-backdrop-filter:blur(16px);backdrop-filter:blur(16px);box-shadow:inset 0 1px 0 rgba(255,255,255,0.06)}
html[data-theme=light] .au .in{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.12);box-shadow:inset 0 1px 0 rgba(0,0,0,0.02)}
.au .in:focus{border-color:var(--ink);background:rgba(255,255,255,0.14);box-shadow:0 0 0 3px rgba(255,255,255,0.12)}
html[data-theme=light] .au .in:focus{background:rgba(0,0,0,0.06);box-shadow:0 0 0 3px rgba(0,0,0,0.08)}
.au .fl{margin-top:14px}.au .fl label{margin-bottom:6px;font-weight:600;font-size:12px;letter-spacing:0.02em}
.au .btn.full{padding:14px 20px;font-size:16px;border-radius:14px;margin-top:20px;font-weight:700;box-shadow:0 4px 16px -2px rgba(0,0,0,0.35),inset 0 1px 0 rgba(255,255,255,0.25)}
.au .gbtn{padding:13px 18px;font-size:14px;border-radius:14px;font-weight:600;transition:all .15s ease}
.au .gbtn:hover{background:rgba(255,255,255,0.12)}
html[data-theme=light] .au .gbtn:hover{background:rgba(0,0,0,0.06)}
.au .or{margin:18px 0 6px}

/* collapsible "I owe" */
details.cd>summary{padding:14px 16px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .18s cubic-bezier(0.2,0.8,0.2,1)}
details.cd .chev{position:absolute;right:16px;top:14px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}

/* quick buy editor */
.in.sel{width:104px;flex:none;font-size:14px;padding:9px 12px;border-radius:12px;background:rgba(255,255,255,0.08);border:1px solid var(--glass-border);color:var(--ink);-webkit-backdrop-filter:blur(12px);backdrop-filter:blur(12px)}
html[data-theme=light] .in.sel{background:rgba(0,0,0,0.04);border-color:rgba(0,0,0,0.1)}
.qe{display:flex;gap:10px;align-items:center;padding:10px 0;border-bottom:1px solid var(--ln)}
.qe .in{font-size:14px;padding:8px 12px}
.qadd{display:flex;gap:10px;align-items:center;margin-top:14px}
.qadd .in{font-size:14px;padding:8px 12px}
`;
