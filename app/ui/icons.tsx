import { jsx } from "./jsx-runtime.ts"
export const P: Record<string, string> = {
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
coin: '<circle cx="12" cy="12" r="9"/><path d="M12 7v10M9.5 9.5h4a1.8 1.8 0 0 1 0 3.6h-3a1.8 1.8 0 0 0 0 3.6h4.5"/>',
out: '<path d="M10 4H5v16h5M15 8l4 4-4 4M19 12H9"/>',
plus: '<path d="M12 5v14M5 12h14"/>',
trash: '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>',
undo: '<path d="M9 14L4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
send: '<path d="M12 19V5M5 12l7-7 7 7"/>',
Smoke: '<rect x="2" y="15" width="14" height="4" rx="1"/><path d="M19 15v4M22 15v4M17 11c0-2 2-2 2-4"/>',
Coffee: '<path d="M4 9h12v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4z"/><path d="M16 11h2a2 2 0 0 1 0 4h-2M8 3v3M12 3v3"/>',
Bread: '<path d="M5 10a4 4 0 0 1 3-6.5h8A4 4 0 0 1 19 10v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2z"/>',
Other: '<path d="M12 5v14M5 12h14"/>',
back: '<path d="M15 5l-7 7 7 7"/>',
chev: '<path d="M6 9l6 6 6-6"/>',
Food: '<path d="M6 3v7a2 2 0 0 0 4 0V3M8 3v18M17 21V3c-2.5 1.5-3.5 4.5-3.5 8H17"/>',
Bus: '<rect x="4" y="3" width="16" height="15" rx="3"/><path d="M4 11h16M8 21v-3M16 21v-3"/><circle cx="8.5" cy="14.5" r=".6"/><circle cx="15.5" cy="14.5" r=".6"/>',
Phone: '<rect x="7" y="2" width="10" height="20" rx="2"/><path d="M11 18h2"/>',
Gift: '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M5 12v9h14v-9M12 8v13M12 8C10 8 8 7 8 5.5S10 3 12 8c2-5 4-3.5 4-2.5S14 8 12 8z"/>',
Cart: '<circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.5 12h11L21 7H6"/>',
Tag: '<path d="M3 12V4a1 1 0 0 1 1-1h8l9 9-9 9z"/><circle cx="7.5" cy="7.5" r="1"/>',
eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>',
}
export const ICON_KEYS = ["Smoke", "Coffee", "Bread", "Food", "Bus", "Phone", "Gift", "Cart", "Tag"]
const parse = (s: string) => [...s.matchAll(/<(\w+)([^>]*?)\/>/g)].map((m) => ({ tag: m[1]!, attrs: Object.fromEntries([...m[2]!.matchAll(/([\w-]+)="([^"]*)"/g)].map((a) => [a[1]!, a[2]!])) }))
export function Icon({ name, class: cls = "ic" }: { name: string; class?: string }) {
return <svg class={cls} viewBox="0 0 24 24">{parse(P[name] ?? "").map((n) => jsx(n.tag, n.attrs))}</svg>
}
