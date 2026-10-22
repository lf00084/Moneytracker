#!/usr/bin/env bash
set -e
cd "${1:-.}"
for f in app/pages/screens.ts app/lib/users.ts app/actions/controller.tsx app/ui/script.ts; do [ -f "$f" ] || { echo "missing $f, run this from the project root"; exit 1; }; done
command -v node >/dev/null || { echo "node is required"; exit 1; }
node - <<'MT_JS'
const fs = require("fs");
const pending = new Map();
const load = (f) => pending.get(f) ?? fs.readFileSync(f, "utf8");
const edit = (f, fn) => pending.set(f, fn(load(f)));
const once = (s, a, b) => {
  const n = s.split(a).length - 1;
  if (n !== 1) throw new Error(`expected 1 match, found ${n}: ${a.slice(0, 70)}`);
  return s.replace(a, () => b);
};
const rx = (s, r, b) => {
  if (!r.test(s)) throw new Error(`no match: ${r}`);
  return s.replace(r, typeof b === "function" ? b : () => b);
};
const dropLines = (s, needle) => {
  const lines = s.split("\n");
  const keep = lines.filter((l) => !l.includes(needle));
  if (keep.length !== lines.length - 1) throw new Error(`expected 1 line with: ${needle}`);
  return keep.join("\n");
};
try {
  edit("app/pages/screens.ts", (s) => {
    s = dropLines(s, 'fld("Phone"');
    s = dropLines(s, 'fld("Bio"');
    s = once(s, 'fld("Email", esc(s.user.email), { t: "email", name: "email" }) +', 'fld("Email", esc(s.user.email), { t: "email", name: "email" });');
    s = once(s, "const cur = (s: State) => esc(s.user.currency);", 'const cur = (s: State) => esc(s.user.currency);\nconst LANG = "English";');
    s = rx(
      s,
      /const balanceCard = [\s\S]*?(?=const plainBal)/,
      'const balanceCard = (s: State, edit = false) =>\n' +
        '\t`<div class="cd"><div class="tg">Total balance</div><div class="cb"><div class="ow" style="margin:0"><span style="display:flex;align-items:center;gap:10px"><b class="big2" data-bal="${s.balance < 0 ? "−" : ""}${fmt(Math.abs(s.balance))}" data-cur="${cur(s)}">••••••</b><button type="button" class="ib sm" data-eye aria-label="Show balance">${ic("eye")}</button></span>${edit ? \'<button type="button" class="lnk" data-edit-bal>Edit balance</button>\' : ""}</div>${edit ? `<div data-balf hidden>${balanceForm(s)}</div>` : ""}</div></div>`;\n',
    );
    s = rx(s, /\n(\s*)balanceCard\(s\) \+\n\s*tg\("Update balance", balanceForm\(s\)\) \+/, (m, ws) => `\n${ws}balanceCard(s, true) +`);
    s = once(
      s,
      '<div class="lb">${esc(s.user.email)}</div></div></div>',
      '<div class="lb">${esc(s.user.email)}</div><div class="chips" style="justify-content:center;margin-top:10px"><span class="chip" style="cursor:default">${cur(s)}</span><span class="chip" style="cursor:default">${LANG}</span></div></div></div>',
    );
    s = once(s, '${sec("Balance", "", balanceForm(s))}', "${balanceCard(s, true)}");
    s = once(s, '\'<div class="hd"><h1 class="t">Settings</h1><span></span></div>\'', '`<div class="hd"><h1 class="t">Settings</h1><span class="lb">${cur(s)} · ${LANG}</span></div>`');
    return s;
  });
  edit("app/lib/users.ts", (s) => {
    s = once(s, "input: { name: string; email: string; phone: string; bio: string }", "input: { name: string; email: string }");
    s = dropLines(s, "phone: input.phone.trim()");
    s = dropLines(s, "bio: input.bio.trim()");
    return s;
  });
  edit("app/actions/controller.tsx", (s) => {
    s = dropLines(s, 'phone: String(f.get("phone") ?? ""),');
    s = dropLines(s, 'bio: String(f.get("bio") ?? ""),');
    return s;
  });
  edit("app/ui/script.ts", (s) =>
    once(
      s,
      "if((q=t.closest('[data-all]'))){",
      "if((q=t.closest('[data-edit-bal]'))){var bf=q.closest('.cd,.sc').querySelector('[data-balf]');bf.hidden=!bf.hidden;q.textContent=bf.hidden?'Edit balance':'Cancel';if(!bf.hidden){var bi=bf.querySelector('input:not([type=hidden])');if(bi){bi.focus();bi.select()}}return}\n  if((q=t.closest('[data-all]'))){",
    ),
  );
} catch (e) {
  console.error("Part 1 not applied (nothing was changed):", e.message);
  console.error("Either it was already applied or your files differ from the zip.");
  process.exit(1);
}
for (const [f, s] of pending) fs.writeFileSync(f, s);
console.log("Part 1 applied:", [...pending.keys()].join(", "));
MT_JS
echo "Done. Next: Part 2 (money UI cleanup: items 5-9)."
