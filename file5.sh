#!/usr/bin/env bash
set -e
cd "${1:-.}"
cat > package.json << '__EOF_MT__'
{
	"name": "moneytracker",
	"version": "1.0.0",
	"private": true,
	"type": "module",
	"scripts": {
		"typecheck": "tsc --noEmit",
		"dev": "vite build --config vite.client.config.ts && vite dev",
		"build": "vite build --config vite.client.config.ts && vite build",
		"build:client": "vite build --config vite.client.config.ts",
		"preview": "vite preview",
		"deploy": "vite build --config vite.client.config.ts && vite build && wrangler deploy",
		"cf:typegen": "wrangler types",
		"format": "oxfmt --check .",
		"format:fix": "oxfmt .",
		"lint": "oxlint",
		"lint:fix": "oxlint --fix",
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
		"oxfmt": "latest",
		"oxlint": "latest",
		"typescript": "^6.0.3",
		"vite": "^8.3.4",
		"wrangler": "^4.149.0"
	}
}
__EOF_MT__
cat > vite.client.config.ts << '__EOF_MT__'
import { defineConfig } from "vite"
export default defineConfig({
publicDir: false,
build: {
outDir: "app/client/dist",
emptyOutDir: true,
target: "es2022",
minify: true,
lib: { entry: "app/client/entry.ts", formats: ["es"], fileName: () => "entry.js" },
},
})
__EOF_MT__
mkdir -p app/client
cat > app/client/entry.ts << '__EOF_MT__'
import { run } from "remix/component"
const app = run({
async loadModule(moduleUrl, exportName) {
const mod = await import(moduleUrl)
return mod[exportName]
},
})
app.addEventListener("error", (e) => console.error(e))
app.ready().catch((e) => console.error(e))
__EOF_MT__
mkdir -p app/client
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
mkdir -p app/client
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
__EOF_MT__
mkdir -p app/components
cat > app/components/Document.tsx << '__EOF_MT__'
import type { RemixNode } from "remix/component";
import { env } from "../env.ts";
import { SITE } from "../lib/assets.ts";
import { V } from "../lib/versions.ts";
import { view } from "./view.ts";

export type DocumentProps = {
	title: string;
	/** Signed-in pages are private (noindex); guest pages (login, signup) are indexable. */
	user?: boolean;
	theme?: string;
	desc?: string;
	/** Canonical path, only used on guest pages. */
	path?: string;
	children?: RemixNode;
};

const THEME_BOOT = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;
const REGISTER_SW = `if("serviceWorker"in navigator)addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}))`;
const FONTS = "https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Noto+Sans+Arabic:wght@500;600&display=swap";

/** The whole HTML page: head, meta tags, stylesheet, scripts. Pages put their content inside it. */
export const Document = view<DocumentProps>(({ title, user = true, theme, desc, path, children }) => {
	const description = desc ?? SITE.desc;
	const origin = env.APP_ORIGIN.replace(/\/$/, "");
	const fullTitle = `${title} · ${SITE.name}`;
	const ld = JSON.stringify({
		"@context": "https://schema.org",
		"@type": "WebApplication",
		name: SITE.name,
		url: origin,
		description: SITE.desc,
		applicationCategory: "FinanceApplication",
		operatingSystem: "Any",
	}).replace(/</g, "\\u003c");

	return (
		<html lang="en" data-theme={theme === "light" ? "light" : "dark"} data-rmx-preserve-attrs="data-theme">
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
				<link rel="stylesheet" href={`/assets/app.css?v=${V.css}`} />
				{theme ? null : <script>{THEME_BOOT}</script>}
				{import.meta.env.DEV ? <script type="module" src="/@vite/client"></script> : null}
			</head>
			<body>
				<div class="nb" aria-hidden="true" data-rmx-preserve-dom></div>
				{children}
				<script src={`/assets/app.js?v=${V.js}`} defer></script>
				{user ? <script type="module" src={`/assets/entry.js?v=${V.entry}`}></script> : null}
				<script>{REGISTER_SW}</script>
			</body>
		</html>
	);
});
__EOF_MT__
mkdir -p app/components
cat > app/components/Lazy.tsx << '__EOF_MT__'
import { Frame } from "remix/component"
import { view } from "./view.ts"
export const Skeleton = view<{ lines?: number; title?: string }>(({ lines = 3, title }) => (
<div class="sc skc" aria-busy="true" aria-label="Loading">
{title ? (
<div class="sh">
<span>{title}</span>
</div>
) : (
<div class="sk skt"></div>
)}
{Array.from({ length: lines }, (_, i) => (
<div key={i} class="sk" style={{ width: `${92 - i * 14}%` }}></div>
))}
</div>
))
export const Lazy = view<{ src: string; name?: string; lines?: number; title?: string }>(({ src, name, lines, title }) => <Frame name={name} src={src} fallback={<Skeleton lines={lines} title={title} />} />)
__EOF_MT__
mkdir -p app/screens
cat > app/screens/home.tsx << '__EOF_MT__'
import { BuysDesktop, BuysExpand, Hero, TodayCards } from "../components/buys.tsx";
import { GoalsExpand } from "../components/goals.tsx";
import { Lazy } from "../components/Lazy.tsx";
import { HomeIncome, IncomeDesktop } from "../components/income.tsx";
import { AppLayout } from "../components/Layout.tsx";
import { BalanceCard } from "../components/profile.tsx";
import { OweDesktop, OweMobile } from "../components/debts.tsx";
import { ErrorBanner } from "../components/ui.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";
import { routes } from "../routes.ts";

/** Dashboard: today at a glance. */
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
						<Lazy name="notes" src={routes.pages.frameNotes.href()} title="Note to yourself" lines={3} />
					</div>
				</div>
			</>
		}
	/>
));
__EOF_MT__
mkdir -p app/components
cat > app/components/Sidebar.tsx << '__EOF_MT__'
import { Icon, Logo, ThemeIcons } from "./Icon.tsx";
import { view } from "./view.ts";

export type DesktopTab = "home" | "notes" | "plan" | "income" | "pad" | "history" | "settings" | "";

const LINKS = [
	{ key: "home", label: "Home", icon: "home", href: "/home" },
	{ key: "notes", label: "Notes", icon: "notes", href: "/notes" },
	{ key: "plan", label: "Plan", icon: "goal", href: "/plan" },
	{ key: "income", label: "Income", icon: "coin", href: "/income" },
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
mkdir -p app/components
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
mkdir -p app/screens
cat > app/screens/auth.tsx << '__EOF_MT__'
import { AuthLayout } from "../components/Layout.tsx";
import { GoogleMark, Logo } from "../components/Icon.tsx";
import { Field } from "../components/ui.tsx";
import { view } from "../components/view.ts";

/** Shared card for sign in and sign up. */
const AuthCard = view<{ up: boolean; error: string }>(({ up, error }) => (
	<div class="auth-center-wrap">
		<div class="auth-glass-box">
			<div class="auth-logo-center">
				<Logo href="/login" />
			</div>
			<h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1>
			<div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div>
			<form class="au" method="post" action={up ? "/signup" : "/login"} data-rmx-document>
				<a class="gbtn" href="/login/google" data-rmx-document>
					<GoogleMark />
					<span>{up ? "Sign up with Google" : "Continue with Google"}</span>
				</a>
				<div class="or">or</div>
				{error ? (
					<div class="auth-err-banner" role="alert">
						{error}
					</div>
				) : null}
				{up ? <Field label="Name" name="name" placeholder="Your name" /> : null}
				<Field label="Email" type="email" name="email" placeholder="you@email.com" />
				<Field label="Password" type="password" name="password" placeholder="••••••••" />
				<button class="btn full">{up ? "Create account" : "Sign in"}</button>
				<div class="auth-switch-wrap">
					<a class="lnk-switch" href={up ? "/login" : "/signup"} data-rmx-document>
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
));

export const LoginScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker.">
		<AuthCard up={false} error={error} />
	</AuthLayout>
));

export const SignupScreen = view<{ error?: string }>(({ error = "" }) => (
	<AuthLayout title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals.">
		<AuthCard up error={error} />
	</AuthLayout>
));
__EOF_MT__
mkdir -p app
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
mkdir -p app/controllers
cat > app/controllers/assets.ts << '__EOF_MT__'
import { createController } from "remix/router";
import appCss from "../client/app.css?raw";
import appJs from "../client/app.js?raw";
import themeJs from "../client/theme.js?raw";
import entryJs from "../client/dist/entry.js?raw";
import { assets } from "../lib/assets.ts";
import { hash } from "../lib/versions.ts";
import { routes } from "../routes.ts";

/** Serves a text file from memory. Links carrying ?v=<hash> are saved on the user's device for a year; plain links are re-checked with an ETag. */
const file = (body: string, type: string) => {
	const etag = `"${hash(body)}"`;
	return (ctx: { request: Request }) => {
		const pinned = new URL(ctx.request.url).searchParams.has("v");
		const headers = { "Cache-Control": pinned ? "public, max-age=31536000, immutable" : "no-cache", ETag: etag };
		return ctx.request.headers.get("if-none-match") === etag ? new Response(null, { status: 304, headers }) : new Response(body, { headers: { ...headers, "Content-Type": type } });
	};
};

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
		css: file(appCss, "text/css; charset=utf-8"),
		js: file(appJs, "application/javascript; charset=utf-8"),
		theme: file(themeJs, "application/javascript; charset=utf-8"),
		entry: file(entryJs, "application/javascript; charset=utf-8"),
	},
});
__EOF_MT__
mkdir -p app/lib
cat > app/lib/versions.ts << '__EOF_MT__'
import appCss from "../client/app.css?raw";
import appJs from "../client/app.js?raw";
import themeJs from "../client/theme.js?raw";
import entryJs from "../client/dist/entry.js?raw";

export const hash = (s: string) => {
	let h = 5381;
	for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0;
	return (h >>> 0).toString(36);
};

export const V = { css: hash(appCss), js: hash(appJs), theme: hash(themeJs), entry: hash(entryJs) };
__EOF_MT__
mkdir -p app/client/dist
[ -f app/client/dist/entry.js ] || echo "export{}" > app/client/dist/entry.js
if [ -x node_modules/.bin/vite ]; then node_modules/.bin/vite build --config vite.client.config.ts || echo "client build failed: soft navigation stays off until bun run build:client works"; else echo "run bun install, then bun run build:client"; fi
echo done
