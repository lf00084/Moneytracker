import { ICON_KEYS, P, QUICK_DEF } from "./parts.ts";

/**
 * Tiny inline script. Everything the user changes is kept in the browser (localStorage, keys start
 * with "mt:") so it survives reloads: theme, quick buys, notes, today's buys, profile fields,
 * and whether "I owe" is open. There is no server state and no account.
 */
export const themeBoot = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;

const data = `var ICONS=${JSON.stringify(P)},KEYS=${JSON.stringify(ICON_KEYS)},QDEF=${JSON.stringify(QUICK_DEF)};`;

const NOTES_DEF = [
	{ d: "Yesterday", t: 'Laptop: Lenovo 15"\n6,000 MAD — wait for Black Friday', tm: "21:14" },
	{ d: "Today", t: "Call Youssef about the 800 on Friday", tm: "09:02" },
	{ d: "Today", t: "Bread 4 · Coffee 12 · Smoke 6", tm: "13:05", ed: 1 },
];

export const script =
	data +
	`var NDEF=${JSON.stringify(NOTES_DEF)};` +
	String.raw`
(function(){
var d=document,r=d.documentElement;
var S={
  get:function(k,def){try{var v=localStorage.getItem('mt:'+k);return v===null?def:JSON.parse(v)}catch(e){return def}},
  set:function(k,v){try{localStorage.setItem('mt:'+k,JSON.stringify(v))}catch(e){}}
};
var MAP={'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'};
function h(s){return String(s).replace(/[&<>"]/g,function(c){return MAP[c]})}
function svg(k){return '<svg class="ic" viewBox="0 0 24 24">'+(ICONS[k]||ICONS.Tag)+'</svg>'}
function money(n){return (Math.round(n*100)/100).toLocaleString('en-US')}
function now(){var n=new Date();return ('0'+n.getHours()).slice(-2)+':'+('0'+n.getMinutes()).slice(-2)}
function all(sel){return [].slice.call(d.querySelectorAll(sel))}
function setTheme(t){r.setAttribute('data-theme',t);try{localStorage.setItem('mtheme',t)}catch(e){}}

/* ---------- state ---------- */
var quick=S.get('quick',QDEF),notes=S.get('notes',NDEF),buys=S.get('buys',[]),form=S.get('form',{}),open=S.get('open',{});

/* ---------- quick buys ---------- */
function renderQuick(){
  all('[data-qb]').forEach(function(w){
    var g=w.querySelector('[data-qgrid]');if(!g)return;
    var cur=g.querySelector('.on'),curN=cur?cur.getAttribute('data-q'):null,desk=g.classList.contains('qk4');
    var items=quick.concat([{n:'Other',p:'',i:'Other',o:1}]),html='';
    items.forEach(function(k,i){
      var sub=k.o?'custom':(k.p+' each'),on=curN!==null?curN===k.n:(desk&&i===0);
      var a=' data-q="'+h(k.n)+'" data-p="'+h(k.p)+'"'+(k.o?' data-o="1"':'');
      html+=desk
        ?'<button type="button" class="'+(on?'on':'')+'"'+a+'>'+svg(k.i)+'<span><b>'+h(k.n)+'</b><small>'+h(sub)+'</small></span></button>'
        :'<button type="button" class="'+(on?'on':'')+'"'+a+'>'+svg(k.i)+'<span>'+h(k.n)+'</span><small>'+h(sub)+'</small></button>';
    });
    g.innerHTML=html;
    var first=g.querySelector('.on');if(first&&desk)pick(first,true);
  });
}
function renderQEdit(){
  all('[data-qedit]').forEach(function(c){
    c.innerHTML=quick.map(function(k,i){
      return '<div class="qe" data-i="'+i+'"><select class="in sel" data-f="i" aria-label="Icon">'+KEYS.map(function(x){return '<option value="'+x+'"'+(x===k.i?' selected':'')+'>'+x+'</option>'}).join('')+'</select><input class="in" data-f="n" value="'+h(k.n)+'" aria-label="Name" autocomplete="off"><input class="in n3" data-f="p" value="'+h(k.p)+'" inputmode="decimal" aria-label="Price" autocomplete="off"><button type="button" class="ib sm" data-qdel aria-label="Remove">×</button></div>';
    }).join('')||'<div class="lb" style="padding:8px 0">No quick buys yet. Add one below.</div>';
  });
}
function calc(f){
  var q=parseFloat(f.querySelector('[data-qty]').value)||0,p=parseFloat(f.querySelector('[data-price]').value)||0;
  var t=Math.round(q*p*100)/100,o=f.querySelector('[data-tot]');
  o.textContent=(o.getAttribute('data-pre')||'')+(t?'−':'')+money(t);
}
function pick(q,keep){
  var w=q.closest('[data-qb]'),f=w.querySelector('[data-qp]'),n=q.getAttribute('data-q');
  all('[data-q]').forEach(function(b){if(b.closest('[data-qb]')===w)b.classList.toggle('on',b===q)});
  f.hidden=false;
  f.querySelector('[data-cat]').value=n;
  var ti=f.querySelector('[data-qt]');if(ti)ti.textContent=n;
  var lw=f.querySelector('[data-labelwrap]');if(lw)lw.hidden=!q.hasAttribute('data-o');
  if(!keep)f.querySelector('[data-qty]').value=1;
  f.querySelector('[data-price]').value=q.getAttribute('data-p')||'';
  calc(f);
}

/* ---------- today's buys ---------- */
function renderBuys(){
  all('[data-buys]').forEach(function(c){
    all('[data-added]').forEach(function(x){if(c.contains(x))x.remove()});
    var first=c.querySelector('.by');if(!first)return;
    buys.forEach(function(b){
      first.insertAdjacentHTML('beforebegin','<div class="by" data-added><div><div>'+h(b.n)+'</div><div class="lb">'+h(b.s)+'</div></div><b class="neg">−'+money(b.a)+'</b></div>');
    });
  });
  var sum=buys.reduce(function(a,b){return a+b.a},0);
  all('[data-bought]').forEach(function(e){e.textContent=money(46+sum)});
  all('[data-nbuys]').forEach(function(e){e.textContent=4+buys.length});
}

/* ---------- notes ---------- */
var ACTS='<div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button><button type="button" class="btn xs dng" data-act="del">Delete</button></div>';
function renderNotes(){
  all('[data-list]').forEach(function(L){
    var k=L.getAttribute('data-list'),html='';
    if(k==='dash'){
      notes.slice(-2).reverse().forEach(function(n){html+='<div class="rw"><span>'+h(n.t)+'</span><span class="lb">'+h(n.tm)+'</span></div>'});
    }else{
      var last='';
      notes.forEach(function(n,i){
        if(n.d!==last){html+='<div class="day"><span>'+h(n.d)+'</span></div>';last=n.d}
        html+='<div class="msg" data-i="'+i+'"><div class="bub">'+h(n.t)+'</div><div class="meta">'+(n.ed?'edited · ':'')+h(n.tm)+'</div>'+ACTS+'</div>';
      });
    }
    L.innerHTML=html;
  });
  all('[data-nnotes]').forEach(function(e){e.textContent=notes.length});
}
function endEdit(c){c._edit=null;var eb=c.querySelector('.eb');if(eb)eb.hidden=true;c.querySelector('textarea').value=''}

/* ---------- saved fields + open/closed state ---------- */
function bind(){
  all('[data-bind]').forEach(function(e){
    if(!e.hasAttribute('data-def'))e.setAttribute('data-def',e.textContent);
    var v=form[e.getAttribute('data-bind')];e.textContent=v?v:e.getAttribute('data-def');
  });
  all('[data-bind-init]').forEach(function(e){
    if(!e.hasAttribute('data-def'))e.setAttribute('data-def',e.textContent);
    var v=form[e.getAttribute('data-bind-init')];e.textContent=v?v.trim().charAt(0).toUpperCase():e.getAttribute('data-def');
  });
}
all('[data-keep]').forEach(function(i){var v=form[i.getAttribute('data-keep')];if(v!==undefined)i.value=v});
all('details[data-keep-open]').forEach(function(x){var k=x.getAttribute('data-keep-open');if(k in open)x.open=!!open[k]});

renderQuick();renderQEdit();renderBuys();renderNotes();bind();

/* ---------- events ---------- */
d.addEventListener('toggle',function(e){
  var x=e.target;
  if(x.matches&&x.matches('details[data-keep-open]')){open[x.getAttribute('data-keep-open')]=x.open;S.set('open',open)}
},true);

d.addEventListener('click',function(e){
  var t=e.target,q;
  if(t.closest('[data-theme-toggle]')){setTheme(r.getAttribute('data-theme')==='dark'?'light':'dark');return}
  if((q=t.closest('[data-set-theme]'))){setTheme(q.getAttribute('data-set-theme'));return}
  if((q=t.closest('[data-eye]'))){
    var v=q.parentNode.firstChild,hide=q.getAttribute('data-s')!=='1';
    q.setAttribute('data-s',hide?'1':'0');v.innerHTML=hide?'12,480 <small>MAD</small>':'••••••';return
  }
  if((q=t.closest('[data-tg]'))){var p=q.closest('.dbw').querySelector('.ad');p.hidden=!p.hidden;return}
  if((q=t.closest('[data-q]'))){pick(q,false);return}
  if((q=t.closest('[data-step]'))){
    var f2=q.closest('[data-qp]'),i=f2.querySelector('[data-qty]');
    i.value=Math.max(1,(parseFloat(i.value)||0)+parseInt(q.getAttribute('data-step'),10));calc(f2);return
  }
  if((q=t.closest('[data-qdel]'))){
    quick.splice(+q.closest('.qe').getAttribute('data-i'),1);S.set('quick',quick);renderQEdit();renderQuick();return
  }
  if((q=t.closest('[data-qaddbtn]'))){
    var ad=q.closest('[data-qadd]'),nm=ad.querySelector('[data-an]'),pr=ad.querySelector('[data-ap]'),ico=ad.querySelector('[data-ai]');
    var name=nm.value.trim();if(!name){nm.focus();return}
    quick.push({n:name,p:String(parseFloat(pr.value)||0),i:ico.value});S.set('quick',quick);
    nm.value='';pr.value='';renderQEdit();renderQuick();nm.focus();return
  }
  if((q=t.closest('.bub'))){
    q.classList.toggle('sel');var a=q.parentNode.querySelector('.acts');a.hidden=!a.hidden;return
  }
  if((q=t.closest('[data-act]'))){
    var m=q.closest('.msg'),act=q.getAttribute('data-act'),idx=+m.getAttribute('data-i'),key=m.parentNode.getAttribute('data-list');
    if(act==='copy'){try{navigator.clipboard.writeText(notes[idx].t)}catch(x){}return}
    if(act==='del'){notes.splice(idx,1);S.set('notes',notes);renderNotes();return}
    var c=d.querySelector('[data-comp="'+key+'"]');
    c._edit=idx;c.querySelector('.eb').hidden=false;var ta=c.querySelector('textarea');ta.value=notes[idx].t;ta.focus();return
  }
  if((q=t.closest('[data-cancel]'))){endEdit(q.closest('[data-comp]'));return}
});

d.addEventListener('input',function(e){
  var el=e.target,f=el.closest&&el.closest('[data-qp]');
  if(f)calc(f);
  var kp=el.getAttribute&&el.getAttribute('data-keep');
  if(kp){form[kp]=el.value;S.set('form',form);bind()}
  var row=el.closest&&el.closest('.qe');
  if(row&&el.hasAttribute('data-f')){
    quick[+row.getAttribute('data-i')][el.getAttribute('data-f')]=el.value;S.set('quick',quick);renderQuick();
  }
});

d.addEventListener('submit',function(e){
  var f=e.target;
  var c=f.closest&&f.closest('[data-comp]');
  if(c){
    e.preventDefault();
    var ta=c.querySelector('textarea'),text=ta.value.trim();if(!text)return;
    if(c._edit!=null){var n=notes[c._edit];n.t=text;n.tm=now();n.ed=1;endEdit(c)}
    else{notes.push({d:'Today',t:text,tm:now()});ta.value=''}
    S.set('notes',notes);renderNotes();
    var lst=d.querySelector('[data-list="'+c.getAttribute('data-comp')+'"]');
    if(lst&&lst.lastChild&&lst.lastChild.scrollIntoView&&c.getAttribute('data-comp')!=='dash')lst.lastChild.scrollIntoView({block:'end'});
    return
  }
  if(f.hasAttribute&&f.hasAttribute('data-qp')){
    e.preventDefault();
    var cat=f.querySelector('[data-cat]').value,qty=parseFloat(f.querySelector('[data-qty]').value)||1,pr=parseFloat(f.querySelector('[data-price]').value)||0,tot=Math.round(qty*pr*100)/100;
    if(!tot)return;
    var lab=f.querySelector('[data-label]'),name=cat==='Other'?((lab&&lab.value.trim())||'Other'):cat;
    buys.unshift({n:qty>1?name+' ×'+qty:name,s:now()+(qty>1?' · '+qty+' × '+pr:''),a:tot});
    S.set('buys',buys);renderBuys();
    if(lab)lab.value='';
    if(f.closest('.m')){f.hidden=true;all('[data-q].on').forEach(function(b){if(b.closest('.m'))b.classList.remove('on')})}
  }
});

d.addEventListener('keydown',function(e){
  if(e.key!=='Enter'||e.shiftKey)return;
  var t=e.target;
  if(t.matches&&t.matches('[data-comp] textarea')){
    e.preventDefault();var f=t.closest('form');
    if(f.requestSubmit)f.requestSubmit();else f.dispatchEvent(new Event('submit',{cancelable:true,bubbles:true}));
    return
  }
  if(t.closest&&t.closest('[data-qadd]')){e.preventDefault();t.closest('[data-qadd]').querySelector('[data-qaddbtn]').click();return}
  if(t.closest&&t.closest('[data-qedit]')){e.preventDefault();t.blur()}
});
})();
`;
