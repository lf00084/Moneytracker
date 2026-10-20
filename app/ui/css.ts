/** Global stylesheet. Same tokens, type and components as the design file, made responsive. */
export const css = String.raw`
html{--bg:#121212;--s1:#181818;--s2:#202020;--ln:#2c2c2c;--ink:#f5f5f5;--mu:#8c8c8c;--pos:#3ddc84;--neg:#ff5a4d;--sh:#000;--bub:#232323;--mono:'Geist Mono',ui-monospace,SFMono-Regular,Menlo,monospace;color-scheme:dark}
html[data-theme=light]{color-scheme:light;--bg:#fff;--s1:#fafafa;--s2:#f1f1f1;--ln:#e3e3e3;--ink:#000;--mu:#6e6e6e;--pos:#12a150;--neg:#e0382b;--sh:#cfcfcf;--bub:#efefef}
*{box-sizing:border-box;margin:0;-webkit-tap-highlight-color:transparent}
a,button,summary,select,label,.bub{-webkit-touch-callout:none;touch-action:manipulation}
button,summary,.bt,.sb,.qk,.qk4,.tg,.sh,.chip,.tag{-webkit-user-select:none;user-select:none}
:focus{outline:none}
a:focus-visible,button:focus-visible,summary:focus-visible{outline:2px solid var(--ink);outline-offset:2px}
::selection{background:var(--ink);color:var(--bg)}
[hidden]{display:none!important}
body{background:var(--bg);color:var(--ink);font:14px/1.45 Geist,Inter,system-ui,-apple-system,sans-serif;font-variant-numeric:tabular-nums;-webkit-font-smoothing:antialiased;min-height:100dvh}
a{color:inherit;text-decoration:none}
button,input,textarea{font:inherit;color:inherit}button{cursor:pointer}
.mu,.lb{color:var(--mu)}.lb{font-size:11px;font-family:var(--mono)}.pos{color:var(--pos)}.neg{color:var(--neg)}.sm{font-size:12px}
svg.ic{width:20px;height:20px;fill:none;stroke:currentColor;stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round;flex:none}
html[data-theme=dark] .t-moon,html[data-theme=light] .t-sun{display:none}
summary{list-style:none;cursor:pointer}summary::-webkit-details-marker{display:none}

/* responsive switch: .m = mobile only, .d = desktop only */
@media(min-width:900px){.m{display:none!important}}
@media(max-width:899px){.d{display:none!important}}

/* app frame */
.app{display:flex;min-height:100dvh}
@media(max-width:899px){.app{flex-direction:column}}
main{flex:1;min-width:0}
.mm{max-width:560px;margin:0 auto;padding:env(safe-area-inset-top,0px) 16px 24px}
.pg{max-width:980px;margin:0 auto;padding:8px 40px 56px}
.pg.full{max-width:none;padding:0}
.dock{position:sticky;bottom:0;z-index:10;background:var(--bg)}
.dock>*{max-width:560px;margin:0 auto}
.tf{position:fixed;top:calc(12px + env(safe-area-inset-top,0px));right:12px;z-index:30}

.logo{display:flex;align-items:center;gap:9px;font-weight:700;font-size:20px;letter-spacing:-.04em}
.logo svg,.bt .lg svg{width:28px;height:28px;border-radius:8px}
.ib{width:36px;height:36px;border-radius:50%;border:1px solid var(--ln);background:var(--s1);display:flex;align-items:center;justify-content:center;color:var(--ink);padding:0}
.ib.sm{width:28px;height:28px}.ib.hi{background:var(--ink);color:var(--bg);border-color:var(--ink)}

/* bottom bar (phone), like X: icons only */
.bt{display:flex;align-items:center;height:53px;border-top:1px solid var(--ln);background:color-mix(in srgb,var(--bg) 88%,transparent);-webkit-backdrop-filter:blur(14px);backdrop-filter:blur(14px);padding-bottom:env(safe-area-inset-bottom,0px);box-sizing:content-box}
.bt a,.bt button{flex:1;height:53px;display:flex;align-items:center;justify-content:center;color:var(--mu);background:none;border:0;padding:0}
.bt svg.ic{width:26px;height:26px}
.bt .on{color:var(--ink)}.bt .on svg.ic{stroke-width:2.4}
.bt .lg svg{opacity:.55;width:26px;height:26px;border-radius:7px}.bt .lg.on svg{opacity:1}
.bt button:active,.bt a:active{opacity:.6}

/* sidebar (desktop), like X */
.sb{position:sticky;top:0;height:100dvh;width:250px;flex:none;border-right:1px solid var(--ln);padding:12px;display:flex;flex-direction:column;gap:4px}
.sb .logo{padding:8px 14px 16px}
.sbl{display:flex;align-items:center;gap:16px;padding:12px 14px;border-radius:30px;font-size:18px;font-weight:500;color:var(--ink);background:none;border:0;width:100%;text-align:left}
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

/* mobile cards */
.cd{background:var(--s1);border:1px solid var(--ln);border-radius:16px;margin-top:12px}
.tg{padding:13px 14px 0;font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.cb{padding:8px 14px 14px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.two .tg{padding:9px 12px 0;font-size:12px}.two .cb{padding:3px 12px 10px}.two .big2{font-size:22px}
.gl{display:flex;justify-content:space-between;align-items:flex-end;margin-bottom:12px}
.mt{height:4px;background:var(--ln);border-radius:4px;overflow:hidden}
.mt i{display:block;height:100%;background:var(--ink);border-radius:4px}
.mt.n i{background:var(--neg)}.mt.s{height:3px}
.chips{display:flex;flex-wrap:wrap;gap:6px;margin-top:12px}
.chip{border:1px solid var(--ln);border-radius:20px;padding:3px 10px;font-size:11px;background:none;font-family:var(--mono);letter-spacing:-.01em}.chip.on{background:var(--ink);color:var(--bg);border-color:var(--ink)}.chip.n{color:var(--neg)}

/* controls */
.btn{font-weight:600;font-size:14px;background:var(--ink);color:var(--bg);border:1px solid var(--ink);border-radius:10px;padding:10px 18px;flex:none;transition:.1s;display:inline-block;text-align:center}
.btn:active{transform:scale(.97);opacity:.85}
.btn.o{background:transparent;color:var(--ink);border-color:var(--ln)}
.btn.dng{background:transparent;color:var(--neg);border-color:var(--neg)}
.btn.xs{padding:5px 12px;font-size:13px;border-radius:8px}
.btn.full{width:100%;padding:13px;margin-top:16px}
.fl{margin-top:14px}.fl label{display:block;font-size:12px;color:var(--mu);margin-bottom:2px}
.in{width:100%;min-width:0;background:transparent;border:0;border-bottom:1px solid var(--ln);border-radius:0;padding:8px 0;outline:0;color:var(--ink);font-size:16px}
.in.f,.in:focus{border-bottom:2px solid var(--ink)}.in::placeholder{color:var(--mu);opacity:.6}
.ln{display:flex;gap:12px;align-items:flex-end}
.stp{display:flex;align-items:flex-end;gap:6px}.stp .in{text-align:center;width:54px}
.stp button{width:30px;height:30px;border:1px solid var(--ln);background:none;border-radius:50%;font-size:16px;flex:none}
.gbtn{width:100%;display:flex;align-items:center;justify-content:center;gap:10px;padding:12px;border-radius:10px;border:1px solid var(--ln);background:var(--s1);font-weight:600}
.or{display:flex;align-items:center;gap:10px;margin:18px 0 0;color:var(--mu);font-size:12px;font-family:var(--mono)}.or:before,.or:after{content:"";flex:1;height:1px;background:var(--ln)}
.lnk{background:none;border:0;color:var(--ink);text-decoration:underline;text-underline-offset:3px;padding:0}
.sg{display:flex;border:1px solid var(--ln);border-radius:10px;overflow:hidden}
.sg button{flex:1;display:flex;gap:8px;align-items:center;justify-content:center;border:0;background:none;padding:10px;color:var(--mu);font-weight:600}
html[data-theme=dark] .sg [data-set-theme=dark],html[data-theme=light] .sg [data-set-theme=light]{background:var(--ink);color:var(--bg)}

/* quick buys */
.qk{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;margin-top:12px}
.qk button{display:flex;flex-direction:column;align-items:center;gap:6px;padding:13px 0 10px;border:1px solid var(--ln);background:var(--s1);border-radius:14px;color:var(--ink)}
.qk button.on{background:var(--ink);color:var(--bg);border-color:var(--ink)}.qk button.on small{color:var(--bg);opacity:.7}
.qk span{font-weight:600;font-size:13px}.qk small{font-size:11px;color:var(--mu);font-family:var(--mono)}
.pn{display:flex;gap:16px;align-items:flex-end;flex-wrap:wrap}
.tt{display:flex;align-items:center;gap:12px;margin-top:16px}.tt b{flex:1;font-size:26px;letter-spacing:-.04em}

/* rows */
.rw,.by{display:flex;justify-content:space-between;align-items:center;padding:12px 0;border-bottom:1px solid var(--ln)}
.rw:last-child,.by:last-child{border:0;padding-bottom:0}.rw:first-child,.by:first-child{padding-top:0}
.tag{font-size:11px;border:1px solid var(--ln);border-radius:10px;padding:0 7px;color:var(--mu);margin-left:6px;font-family:var(--mono)}
.db{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid var(--ln)}
.dn{flex:1}.l1{display:flex;justify-content:space-between;align-items:center;margin-bottom:7px}
.ad{background:var(--s2);border-radius:12px;padding:10px 12px;margin:2px 0 8px}.ad label{font-size:12px;color:var(--mu)}.ad .ln{margin:2px 0 4px}
.ow{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:6px}
.sub{font-size:12px;color:var(--mu);margin:18px 0 4px;font-family:var(--mono)}
.ln3{display:flex;gap:12px;align-items:flex-end}.n3{width:62px;flex:none}

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
.cm{border-top:1px solid var(--ln);padding:10px 12px;background:var(--bg)}
.cm .eb{display:flex;justify-content:space-between;font-size:12px;padding:0 6px 8px;font-family:var(--mono)}.cm .eb b{font-weight:600}.cm .eb button{background:none;border:0}
.cin{display:flex;gap:8px;align-items:flex-end}.cin textarea{flex:1;background:var(--s2);border:0;border-radius:22px;padding:11px 16px;resize:none;outline:0;font-size:15px}
.send{flex:none;width:44px;height:44px;border-radius:50%;border:0;background:var(--ink);color:var(--bg);display:flex;align-items:center;justify-content:center}
.chat{max-width:640px;margin:0 auto}

/* profile */
.li{display:flex;justify-content:space-between;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln);width:100%;background:none;border-left:0;border-right:0;border-top:0;text-align:left}.li:last-child{border:0;padding-bottom:0}.li:first-child{padding-top:0}

/* desktop sections (no boxes) */
.hero{display:grid;grid-template-columns:repeat(4,1fr);border-top:1px solid var(--ln);border-bottom:1px solid var(--ln);margin:20px 0 6px}
.hero>div{padding:24px 26px;border-left:1px solid var(--ln)}.hero>div:first-child{border:0;padding-left:0}
.hero .v{font-size:46px;font-weight:600;letter-spacing:-.06em;line-height:1;margin:8px 0 8px}
.g2{display:grid;grid-template-columns:1.35fr 1fr;gap:56px}
.g3{display:grid;grid-template-columns:1fr 1fr;gap:56px}
.sc{margin-top:30px}
.sh{display:flex;justify-content:space-between;align-items:baseline;padding-bottom:10px;border-bottom:1px solid var(--ink);font-weight:600;font-size:15px}.sh .lb{font-weight:400}
.sc .rw,.sc .by,.sc .db{padding:14px 0}
.qk4{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:16px}
.qk4 button{display:flex;align-items:center;gap:10px;padding:14px;border:1px solid var(--ln);background:none;border-radius:14px;color:var(--ink);text-align:left}
.qk4 button.on{background:var(--ink);color:var(--bg);border-color:var(--ink)}
.qk4 b{display:block;font-size:14px}.qk4 small{font-size:12px;opacity:.65;font-family:var(--mono)}
.qrow{display:flex;align-items:flex-end;gap:18px;margin-top:16px;padding:14px 16px;border:1px solid var(--ln);border-radius:14px;flex-wrap:wrap}
.qrow .eq{font-size:22px;font-weight:600;letter-spacing:-.04em;padding-bottom:4px}
.th,.tr{display:grid;grid-template-columns:130px 100px 100px 100px 1fr;gap:12px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.th{font-size:12px;color:var(--mu);padding-top:12px;font-family:var(--mono)}
.tr:last-child{border:0}
.split{display:grid;grid-template-columns:1fr 1fr;min-height:100dvh}
.sl{background:var(--ink);color:var(--bg);padding:48px;display:flex;flex-direction:column;justify-content:space-between}
.sl h2{font-size:92px;line-height:.9;letter-spacing:-.07em;font-weight:700}
.sr{padding:56px 90px;display:flex;flex-direction:column;justify-content:center}
.wr{display:flex;gap:16px;align-items:center;padding:14px 0;border-bottom:1px solid var(--ln)}
.au .in{background:var(--s2);border:1px solid transparent;border-radius:10px;padding:9px 12px;font-size:15px;transition:.15s}
.au .in:focus{border-color:var(--ink);background:var(--s1)}
.au .fl{margin-top:10px}.au .fl label{margin-bottom:4px}
.au .btn.full{padding:8px;font-size:13px;border-radius:10px;margin-top:14px}
.au .gbtn{padding:8px;font-size:13px;border-radius:10px}
.au .or{margin-top:14px}


/* collapsible "I owe" */
details.cd>summary{padding:13px 14px;display:block;position:relative}
details.cd[open]>summary{padding-bottom:4px}
details.cd>.cb{padding-top:6px}
.osum .tg0{font-size:12px;font-weight:500;color:var(--mu);font-family:var(--mono)}
.osum .ow{margin:8px 0 0}
.chev{display:flex;color:var(--mu);transition:transform .15s}
details.cd .chev{position:absolute;right:14px;top:12px}
details[open]>summary .chev{transform:rotate(180deg)}
details.sc>summary.sh{cursor:pointer}
.sh .rr{display:flex;gap:10px;align-items:center}

/* quick buy editor */
.in.sel{width:92px;flex:none;font-size:14px;padding:8px 4px;appearance:auto;background:transparent}
.qe{display:flex;gap:10px;align-items:flex-end;padding:8px 0;border-bottom:1px solid var(--ln)}
.qe .in{font-size:15px}
.qadd{display:flex;gap:10px;align-items:flex-end;margin-top:14px}
.qadd .in{font-size:15px}
`;
