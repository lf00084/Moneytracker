/**
 * Tiny inline script. Theme toggle, balance eye, quick-buy panel, debt "+" panels and the notes
 * chat are purely visual: nothing is saved anywhere except the chosen theme in localStorage.
 */
export const themeBoot = `try{var t=localStorage.getItem('mtheme');if(t)document.documentElement.setAttribute('data-theme',t)}catch(e){}`;

export const script = String.raw`
(function(){
var d=document,r=d.documentElement;
function setTheme(t){r.setAttribute('data-theme',t);try{localStorage.setItem('mtheme',t)}catch(e){}}
function calc(f){
  var q=parseFloat(f.querySelector('[data-qty]').value)||0,p=parseFloat(f.querySelector('[data-price]').value)||0;
  var t=Math.round(q*p*100)/100,o=f.querySelector('[data-tot]');
  o.textContent=(o.getAttribute('data-pre')||'')+(t?'−':'')+t;
}
function msgEl(text,time,edited){
  var m=d.createElement('div');m.className='msg';
  m.innerHTML='<div class="bub"></div><div class="meta"></div><div class="acts" hidden><button type="button" class="btn xs o" data-act="copy">Copy</button><button type="button" class="btn xs o" data-act="edit">Edit</button><button type="button" class="btn xs dng" data-act="del">Delete</button></div>';
  m.firstChild.textContent=text;m.children[1].textContent=(edited?'edited · ':'')+time;return m;
}
function now(){var n=new Date();return ('0'+n.getHours()).slice(-2)+':'+('0'+n.getMinutes()).slice(-2)}
function endEdit(c){c._edit=null;c.querySelector('.eb').hidden=true;c.querySelector('textarea').value=''}

d.addEventListener('click',function(e){
  var t=e.target,q;
  if(!t.closest('details.mw')){[].forEach.call(d.querySelectorAll('details.mw[open]'),function(x){x.removeAttribute('open')})}
  if(t.closest('[data-theme-toggle]')){setTheme(r.getAttribute('data-theme')==='dark'?'light':'dark');return}
  if((q=t.closest('[data-set-theme]'))){setTheme(q.getAttribute('data-set-theme'));return}
  if((q=t.closest('[data-eye]'))){
    var v=q.parentNode.firstChild,h=q.getAttribute('data-s')!=='1';
    q.setAttribute('data-s',h?'1':'0');v.innerHTML=h?'12,480 <small>MAD</small>':'••••••';return
  }
  if((q=t.closest('[data-tg]'))){var p=q.closest('.dbw').querySelector('.ad');p.hidden=!p.hidden;return}
  if((q=t.closest('[data-q]'))){
    var w=q.closest('[data-qb]');
    [].forEach.call(w.querySelectorAll('[data-q]'),function(b){b.classList.toggle('on',b===q)});
    var f=w.querySelector('[data-qp]');f.hidden=false;
    var n=q.getAttribute('data-q');
    f.querySelector('[data-cat]').value=n;
    var ti=f.querySelector('[data-qt]');if(ti)ti.textContent=n;
    f.querySelector('[data-qty]').value=1;f.querySelector('[data-price]').value=q.getAttribute('data-p')||'';
    calc(f);return
  }
  if((q=t.closest('[data-step]'))){
    var f2=q.closest('[data-qp]'),i=f2.querySelector('[data-qty]');
    i.value=Math.max(1,(parseFloat(i.value)||0)+parseInt(q.getAttribute('data-step'),10));calc(f2);return
  }
  if((q=t.closest('.bub'))){
    q.classList.toggle('sel');var a=q.parentNode.querySelector('.acts');a.hidden=!a.hidden;return
  }
  if((q=t.closest('[data-act]'))){
    var m=q.closest('.msg'),act=q.getAttribute('data-act'),txt=m.querySelector('.bub').textContent;
    if(act==='del'){m.remove();return}
    if(act==='copy'){try{navigator.clipboard.writeText(txt)}catch(x){}return}
    var k=m.parentNode.getAttribute('data-list'),c=d.querySelector('[data-comp="'+k+'"]');
    c._edit=m;c.querySelector('.eb').hidden=false;var ta=c.querySelector('textarea');ta.value=txt;ta.focus();return
  }
  if((q=t.closest('[data-cancel]'))){endEdit(q.closest('[data-comp]'));return}
});
d.addEventListener('input',function(e){var f=e.target.closest&&e.target.closest('[data-qp]');if(f)calc(f)});
d.addEventListener('submit',function(e){
  var c=e.target.closest&&e.target.closest('[data-comp]');
  if(c){
    e.preventDefault();
    var ta=c.querySelector('textarea'),text=ta.value.trim();if(!text)return;
    if(c._edit){c._edit.querySelector('.bub').textContent=text;c._edit.children[1].textContent='edited · '+now();endEdit(c);return}
    var list=d.querySelector('[data-list="'+c.getAttribute('data-comp')+'"]');
    list.appendChild(msgEl(text,now(),false));ta.value='';
    return
  }
  /* demo only: purchases and money forms don't save, just stay on the page */
  var f=e.target;
  if(f.getAttribute&&f.getAttribute('data-demo')!==null){e.preventDefault()}
});
d.addEventListener('keydown',function(e){
  if(e.key==='Enter'&&!e.shiftKey&&e.target.matches&&e.target.matches('[data-comp] textarea')){
    e.preventDefault();var f=e.target.closest('form');
    if(f.requestSubmit)f.requestSubmit();else f.dispatchEvent(new Event('submit',{cancelable:true,bubbles:true}));
  }
});
})();
`;
