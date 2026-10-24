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
  if((q=t.closest('button[name][value]'))&&q.form){
    var sh=q.form.querySelector('input[type=hidden][data-sub="'+q.name+'"]');
    if(!sh){sh=d.createElement('input');sh.type='hidden';sh.name=q.name;sh.setAttribute('data-sub',q.name);q.form.appendChild(sh)}
    sh.value=q.value;
  }
  if((q=t.closest('[data-close]'))){var cd=q.closest('details');if(cd)cd.open=false;return}
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
    form.setAttribute('data-kind',q.getAttribute('data-mode'));
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
var EXO_MS=240000,exoAt=Date.now(),rb=false;
try{rb=sessionStorage.getItem('mt:rb')==='1';sessionStorage.removeItem('mt:rb')}catch(e){}
function syncBal(){
  if(rb&&all('[data-eye]').length){rb=false;all('[data-eye]').forEach(function(q){q.setAttribute('data-s','1')})}
  all('[data-eye][data-s="1"]').forEach(function(q){
    var v=q.parentNode.firstChild,b=v.getAttribute('data-bal');
    if(v.getAttribute('data-sh')===b)return;
    v.setAttribute('data-sh',b);
    v.innerHTML=b+' <small>'+v.getAttribute('data-cur')+'</small>';
  });
}
function exoTick(){
  if(!d.querySelector('[data-exo]')||d.hidden||Date.now()-exoAt<EXO_MS)return;
  var a=d.activeElement;
  if(a&&a.matches&&a.matches('input,textarea,select'))return;
  if(d.querySelector('[data-adp]:not([hidden]),[data-addp]:not([hidden]),[data-pnl]:not([hidden])'))return;
  try{if(d.querySelector('[data-eye][data-s="1"]'))sessionStorage.setItem('mt:rb','1')}catch(e){}
  location.reload();
}
setInterval(exoTick,30000);
d.addEventListener('visibilitychange',exoTick);
function settle(){exoAt=Date.now();init();syncBal();tails();unbusy()}

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
  requestAnimationFrame(function(){queued=0;init();syncBal()});
}).observe(r,{childList:true,subtree:true});

settle();
})();
