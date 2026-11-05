// Declarative progressive-enhancement behaviors for the Remix browser runtime.
// These mirror plain HTML attributes (data-confirm, data-keep-open, …) so the
// server-rendered markup works without JavaScript and upgrades once the
// runtime boots. Component-scoped state lives in clientEntry components
// instead — this module only owns document-level glue.

type App = {
	frames: {
		top: { reload: (opts?: { src?: string }) => Promise<unknown> }
		get?: (name: string) => { reload: (opts?: { src?: string }) => Promise<unknown> } | undefined
	}
}

const THEME_KEY = "mtheme"
const OPEN_KEY = "mt:open"

export function enhance(app: App) {
	const d = document
	const root = d.documentElement
	const all = <T extends Element = Element>(sel: string, scope?: Element) => Array.from((scope ?? d).querySelectorAll<T>(sel))
	// The mobile (.m) and desktop (.d) trees repeat the same element ids.
	// Resolve inside the caller's tree first so the visible copy is the one
	// that gets opened, filled or toggled.
	const byId = <T extends Element>(id: string, from?: Element | null): T | null => {
		const tree = from && from.closest ? (from.closest(".m") ?? from.closest(".d")) : null
		return (tree ? tree.querySelector<T>(`#${CSS.escape(id)}`) : null) ?? (d.getElementById(id) as T | null)
	}

	// ---- theme -------------------------------------------------------------
	const setTheme = (t: string) => {
		root.setAttribute("data-theme", t)
		try {
			localStorage.setItem(THEME_KEY, t)
		} catch {}
		try {
			fetch("/settings/theme", {
				method: "POST",
				body: new URLSearchParams({ theme: t }),
				credentials: "same-origin",
				redirect: "manual",
			})
		} catch {}
	}
	d.addEventListener("click", (e) => {
		const t = e.target as Element | null
		if (!t?.closest) return
		if (t.closest("[data-theme-toggle]")) return setTheme(root.getAttribute("data-theme") === "dark" ? "light" : "dark")
		const s = t.closest("[data-set-theme]")
		if (s) return setTheme(s.getAttribute("data-set-theme") || "dark")
	})

	// ---- details keep-open persistence ------------------------------------
	let open: Record<string, boolean> = {}
	try {
		open = JSON.parse(localStorage.getItem(OPEN_KEY) || "{}")
	} catch {}
	const persistOpen = () => {
		try {
			localStorage.setItem(OPEN_KEY, JSON.stringify(open))
		} catch {}
	}
	all("details[data-keep-open]").forEach((x) => {
		const k = x.getAttribute("data-keep-open") || ""
		if (k in open) (x as HTMLDetailsElement).open = !!open[k]
	})
	d.addEventListener(
		"toggle",
		(e) => {
			const x = e.target as Element
			if (x.matches?.("details[data-keep-open]")) {
				open[x.getAttribute("data-keep-open") || ""] = (x as HTMLDetailsElement).open
				persistOpen()
			}
			if (x.matches?.(".xd") && !(x as HTMLDetailsElement).open) {
				const xf = x.querySelector("[data-adp]") as HTMLElement | null
				const xb = x.parentNode?.querySelector("[data-xplus]") as HTMLElement | null
				if (xf) xf.hidden = true
				xb?.classList.remove("on")
			}
		},
		true,
	)

	// ---- confirmations -----------------------------------------------------
	d.addEventListener(
		"click",
		(e) => {
			const b = (e.target as Element).closest?.("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn") || "")) e.preventDefault()
		},
		true,
	)

	// ---- submitter values (button[name][value] → hidden input) ------------
	d.addEventListener("click", (e) => {
		const q = (e.target as Element).closest?.("button[name][value]") as HTMLButtonElement | null
		if (!q?.form) return
		let sh = q.form.querySelector<HTMLInputElement>(`input[type=hidden][data-sub="${q.name}"]`)
		if (!sh) {
			sh = d.createElement("input")
			sh.type = "hidden"
			sh.name = q.name
			sh.setAttribute("data-sub", q.name)
			q.form.appendChild(sh)
		}
		sh.value = q.value
	})

	// ---- busy state on submit ---------------------------------------------
	const SPIN =
		'<span class="sb-i" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg></span>'
	d.addEventListener("submit", (e) => {
		const f = e.target as HTMLFormElement
		const msg = f.getAttribute?.("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		if (f.getAttribute("data-submitted") === "1") return e.preventDefault()
		f.setAttribute("data-submitted", "1")
		const sub = (e as SubmitEvent).submitter as HTMLElement | null
		setTimeout(() => {
			if (e.defaultPrevented) {
				f.removeAttribute("data-submitted")
				return
			}
			all("button", f).forEach((b) => {
				const btn = b as HTMLButtonElement
				if (btn.disabled) return
				btn.disabled = true
				if (!sub || b === sub) {
					btn.setAttribute("data-busy", "1")
					btn.setAttribute("aria-busy", "true")
					if (!btn.querySelector(".sb-i")) btn.insertAdjacentHTML("beforeend", SPIN)
				} else btn.setAttribute("data-lock", "1")
			})
		}, 0)
	})
	const unbusy = () => {
		all("form[data-submitted]").forEach((f) => f.removeAttribute("data-submitted"))
		all("button[data-busy],button[data-lock]").forEach((b) => {
			const btn = b as HTMLButtonElement
			btn.disabled = false
			btn.removeAttribute("data-busy")
			btn.removeAttribute("data-lock")
			btn.removeAttribute("aria-busy")
		})
	}
	window.addEventListener("pageshow", (e) => {
		if ((e as PageTransitionEvent).persisted) unbusy()
	})

	// ---- expand/collapse panels -------------------------------------------
	const focusFirst = (box: Element) => {
		const i = box.querySelector<HTMLInputElement>("input:not([type=hidden])")
		i?.focus()
	}
	d.addEventListener("click", (e) => {
		const t = e.target as Element
		if (!t.closest) return
		let q: Element | null = null

		if (t.closest("[data-close]")) {
			const cd = t.closest("details") as HTMLDetailsElement | null
			if (cd) cd.open = false
			return
		}
		if ((q = t.closest("[data-xplus]"))) {
			e.preventDefault()
			const xc = q.closest(".xc")
			const xd = xc?.querySelector("details") as HTMLDetailsElement | null
			const xm = xc?.querySelector("[data-adp]") as HTMLElement | null
			if (xm) {
				if (xd && !xd.open) {
					xd.open = true
					xm.hidden = false
				} else xm.hidden = !xm.hidden
				q.classList.toggle("on", !xm.hidden)
				if (!xm.hidden) focusFirst(xm)
			}
			return
		}
		if ((q = t.closest("[data-tg],[data-pay]"))) {
			const add = q.hasAttribute("data-tg")
			const w = q.closest(".dbw")
			const p = w?.querySelector(add ? "[data-addp]" : "[data-payp]") as HTMLElement | null
			const o = w?.querySelector(add ? "[data-payp]" : "[data-addp]") as HTMLElement | null
			if (o) o.hidden = true
			if (p) {
				p.hidden = !p.hidden
				if (!p.hidden) focusFirst(p)
			}
			return
		}
		if ((q = t.closest("[data-nm]"))) {
			const nf = q.closest("form")
			const nameInp = nf?.querySelector<HTMLInputElement>("[data-name]")
			if (nameInp) nameInp.value = q.getAttribute("data-nm") || ""
			nf?.querySelector<HTMLInputElement>("[data-price]")?.focus()
			return
		}
		if ((q = t.closest("[data-bigadd]"))) {
			const tf = q.getAttribute("data-for")
			const ap = (tf ? byId<HTMLElement>(tf, q) : q.closest(".bgc")?.querySelector("[data-adp]")) as HTMLElement | null
			if (ap) {
				ap.hidden = !ap.hidden
				q.classList.toggle("on", !ap.hidden)
				if (!ap.hidden) focusFirst(ap)
			}
			return
		}
		if ((q = t.closest("[data-mode]"))) {
			const form = q.closest("form")
			const mode = q.getAttribute("data-mode") || ""
			all("[data-mode]", form as Element).forEach((c) => c.classList.toggle("on", c === q))
			const modeInp = form?.querySelector<HTMLInputElement>("[data-mode-input]")
			if (modeInp) modeInp.value = mode
			form?.setAttribute("data-kind", mode)
			form?.setAttribute("data-m", mode)
			return
		}
		if ((q = t.closest("[data-eye]"))) {
			const card = q.closest("article, .hm-bal-card, .hm-bal, .hm-top-bal, .hm-balc")
			const v = card?.querySelector("[data-bal]") as HTMLElement | null
			if (!v) return
			const hide = q.getAttribute("data-s") !== "1"
			q.setAttribute("data-s", hide ? "1" : "0")
			v.innerHTML = hide ? `${v.getAttribute("data-bal") || ""} <small>${v.getAttribute("data-cur") || ""}</small>` : "••••••"
			return
		}
		if ((q = t.closest("[data-edit-bal]"))) {
			const bf = q.closest("article")?.querySelector<HTMLElement>("[data-balf]")
			if (!bf) return
			bf.hidden = !bf.hidden
			q.setAttribute("aria-label", bf.hidden ? "Edit balance" : "Cancel")
			q.classList.toggle("hi", !bf.hidden)
			if (!bf.hidden) {
				const bi = bf.querySelector<HTMLInputElement>("input:not([type=hidden])")
				if (bi) {
					bi.focus()
					bi.select()
				}
			}
			return
		}
		if ((q = t.closest("[data-all]"))) {
			const af = q.closest(".iw")?.querySelector<HTMLInputElement>("input")
			if (af) {
				af.value = q.getAttribute("data-all") || ""
				af.focus()
			}
			return
		}
		// Focus the first field of a panel that just opened.
		if (t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")) {
			setTimeout(() => {
				const a = t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")
				const box = (a?.closest(".xc,.dbw,article") as Element) ?? d
				const f = all("[data-adp],[data-addp],[data-payp]", box).filter((n) => !(n as HTMLElement).hidden && (n as HTMLElement).offsetParent)[0]
				if (!f) return
				const i = f.querySelector<HTMLInputElement>("input:not([type=hidden]),textarea")
				i?.focus({ preventScroll: true })
				f.scrollIntoView({ block: "center", behavior: "smooth" })
			}, 60)
		}
	})

	// ---- PnL validation ---------------------------------------------------
	d.addEventListener(
		"submit",
		(e) => {
			const f = e.target as Element
			if (!f.hasAttribute?.("data-pnl")) return
			const sub = (e as SubmitEvent).submitter as HTMLElement | null
			const outcome = sub?.getAttribute("value")
			if (outcome !== "win" && outcome !== "lose") return
			const i = (f as HTMLFormElement).querySelector<HTMLInputElement>("[name=pnl]")
			if (!i) return
			const n = parseFloat(String(i.value).replace(",", "."))
			if (Number.isFinite(n) && n > 0) return
			e.preventDefault()
			e.stopImmediatePropagation()
			const er = (f as HTMLFormElement).querySelector<HTMLElement>(".ferr")
			i.classList.add("bad")
			if (er) {
				er.textContent = outcome === "win" ? "Enter how much you won in USDT" : "Enter how much you lost in USDT"
				er.hidden = false
				const scrollTarget = (er.parentNode as HTMLElement | null) || i
				scrollTarget.scrollIntoView({ block: "center", behavior: "smooth" })
			}
			i.focus({ preventScroll: true })
		},
		true,
	)
	d.addEventListener("input", (e) => {
		const t = e.target as HTMLElement
		const f = t.closest?.("[data-pnl]") as HTMLFormElement | null
		if (f && (t as HTMLInputElement).name === "pnl") {
			const i = f.querySelector<HTMLInputElement>("[name=pnl]")
			const er = f.querySelector<HTMLElement>(".ferr")
			i?.classList.remove("bad")
			if (er) {
				er.hidden = true
				er.textContent = ""
			}
		}
	})

	// ---- scroll [data-bottom] lists to the bottom --------------------------
	const scrollBottoms = () => all("[data-bottom]").forEach((l) => ((l as HTMLElement).scrollTop = (l as HTMLElement).scrollHeight))
	scrollBottoms()
	window.addEventListener("load", scrollBottoms)
	window.addEventListener("pageshow", scrollBottoms)

	// ---- textarea auto-grow ------------------------------------------------
	d.addEventListener("input", (e) => {
		const ta = e.target as HTMLTextAreaElement
		if (ta.matches?.("textarea[data-grow]")) {
			ta.style.height = "auto"
			ta.style.height = `${Math.min(ta.scrollHeight, 132)}px`
		}
	})

	// ---- dismissible notices ----------------------------------------------
	let dis: Record<string, number> = {}
	try {
		dis = JSON.parse(localStorage.getItem("mt:inv") || "{}")
	} catch {}
	all("[data-inv]").forEach((n) => {
		if (dis[n.getAttribute("data-inv") || ""]) (n as HTMLElement).hidden = true
	})
	d.addEventListener("click", (e) => {
		const x = (e.target as Element).closest?.("[data-inv-x]")
		if (!x) return
		const n = x.closest("[data-inv]") as HTMLElement | null
		if (!n) return
		dis[n.getAttribute("data-inv") || ""] = 1
		try {
			localStorage.setItem("mt:inv", JSON.stringify(dis))
		} catch {}
		n.hidden = true
	})

	// ---- bottom sheets -----------------------------------------------------
	const openSheet = (id: string, from?: Element | null) => {
		const el = byId<HTMLElement>(id, from)
		if (!el) return
		el.hidden = false
		el.querySelector<HTMLInputElement>("input:not([type=hidden])")?.focus()
	}
	const closeSheets = () => all(".app-sheet-ov").forEach((s) => ((s as HTMLElement).hidden = true))
	d.addEventListener("click", (e) => {
		const t = e.target as Element
		if (!t.closest) return
		if (t.closest("[data-sheet-close]") || t.classList?.contains("app-sheet-ov")) {
			closeSheets()
			return
		}
		const feeBtn = t.closest("[data-set-fee]")
		if (feeBtn) {
			const form = feeBtn.closest("form")
			const nameInp = form?.querySelector<HTMLInputElement>("[data-name]")
			const priceInp = form?.querySelector<HTMLInputElement>("[data-price]")
			if (nameInp) nameInp.value = "Bank fee"
			priceInp?.focus()
			return
		}
		const st = t.closest("[data-sheet-trigger]") as HTMLElement | null
		if (st) {
			const kind = st.getAttribute("data-sheet-trigger")
			if (kind === "bought") openSheet("sheet-bought", st)
			else if (kind === "add-money") openSheet("sheet-add-money", st)
			else if (kind === "transfer") openSheet("sheet-transfer", st)
			else if (kind === "add-bank") openSheet("sheet-add-bank", st)
			else if (kind === "paid") {
				const sId = st.getAttribute("data-source-id") || ""
				const sName = st.getAttribute("data-source-name") || "Paid"
				const sAmt = st.getAttribute("data-source-amt") || ""
				const sUsd = st.getAttribute("data-source-usd") === "1"
				const pTitle = byId("sheet-paid-title", st)
				const pSelect = byId("sheet-paid-source-select", st) as HTMLSelectElement | null
				const pText = byId("sheet-paid-pending-text", st)
				const pAmt = byId("sheet-paid-amount", st) as HTMLInputElement | null
				let id = sId
				let name = sName
				let amt = sAmt
				let usd = sUsd
				if (pSelect) {
					if (id) pSelect.value = id
					else if (pSelect.selectedIndex <= 0 && pSelect.options.length > 1) {
						for (let oi = 1; oi < pSelect.options.length; oi++) {
							if (Number(pSelect.options[oi]!.getAttribute("data-amt") || 0) > 0) {
								pSelect.selectedIndex = oi
								break
							}
						}
						if (pSelect.selectedIndex <= 0) pSelect.selectedIndex = 1
					}
					const opt = pSelect.options[pSelect.selectedIndex]
					if (opt && opt.value) {
						id = opt.value
						name = opt.getAttribute("data-name") || opt.text.split(" (")[0] || name
						amt = opt.getAttribute("data-amt") || amt
						usd = opt.getAttribute("data-usd") === "1" || usd
					}
				}
				if (pTitle) pTitle.textContent = id ? `Mark ${name} paid` : "Mark paid"
				if (pAmt) {
					pAmt.value = ""
					pAmt.placeholder = amt ? `Amount (blank = all ${usd ? "$" : ""}${(Number(amt) / 100).toFixed(2)})` : "Amount (blank = all)"
				}
				if (pText) pText.textContent = amt ? `Pending on hold: ${usd ? "$" : ""}${(Number(amt) / 100).toFixed(2)}` : "Select source and amount received"
				openSheet("sheet-paid", st)
			} else if (kind === "adjust-pending") {
				const sId = st.getAttribute("data-source-id") || ""
				const sName = st.getAttribute("data-source-name") || "pending"
				const sAmt = st.getAttribute("data-source-amt") || ""
				const sUsd = st.getAttribute("data-source-usd") === "1"
				const aTitle = byId("sheet-adjust-title", st)
				const aSrc = byId("sheet-adjust-source-id", st) as HTMLInputElement | null
				const aText = byId("sheet-adjust-current-text", st)
				const aAmt = byId("sheet-adjust-amount", st) as HTMLInputElement | null
				if (aTitle) aTitle.textContent = `Adjust ${sName} pending`
				if (aSrc) aSrc.value = sId
				if (aAmt) aAmt.value = sAmt ? (Number(sAmt) / 100).toFixed(2) : ""
				if (aText) aText.textContent = `Current pending: ${sUsd ? "$" : ""}${(Number(sAmt) / 100).toFixed(2)}`
				openSheet("sheet-adjust", st)
			}
			return
		}
		const btile = t.closest("[data-bank-tile]") as HTMLElement | null
		if (btile) {
			const bId = btile.getAttribute("data-bank-tile") || ""
			const bName = btile.getAttribute("data-bank-name") || ""
			const bBal = btile.getAttribute("data-bank-bal") || "0"
			const bCash = btile.getAttribute("data-bank-cash") === "1"
			const bDef = btile.getAttribute("data-bank-default") === "1"
			const bIcon = btile.getAttribute("data-bank-icon") || ""
			const set = (id: string, v: string) => {
				const el = byId<HTMLInputElement>(id, btile)
				if (el) el.value = v
			}
			const sbn = byId("sheet-bank-name", btile)
			const sbb = byId("sheet-bank-bal", btile)
			const sbIconPrev = byId("sheet-bank-icon-preview", btile)
			const sbDefForm = byId("sheet-bank-default-form", btile) as HTMLElement | null
			const sbDelForm = byId("sheet-bank-delete-form", btile) as HTMLElement | null
			if (sbn) sbn.textContent = bName
			if (sbb) sbb.textContent = `${(Number(bBal) / 100).toFixed(2)} MAD`
			set("sheet-bank-name", bName)
			set("sheet-bank-icon-id", bId)
			set("sheet-bank-icon-input", bIcon)
			set("sheet-bank-default-id", bId)
			set("sheet-bank-delete-id", bId)
			if (sbIconPrev) sbIconPrev.innerHTML = bIcon ? `<img src="${bIcon}" style="width:36px;height:36px;border-radius:8px;object-fit:cover" />` : ""
			if (sbDefForm) sbDefForm.hidden = bDef || bCash
			if (sbDelForm) sbDelForm.hidden = bCash
			openSheet("sheet-bank-actions", st)
			return
		}
		const rad = t.closest("[data-from-radio]") as HTMLInputElement | null
		if (rad) {
			try {
				localStorage.setItem("mt:defbank", rad.value)
			} catch {}
		}
	})
	d.addEventListener("keydown", (e) => {
		if (e.key === "Escape") closeSheets()
	})

	// ---- live totals + icon preview + source select ------------------------
	d.addEventListener("input", (e) => {
		const inp = e.target as HTMLElement
		if (inp.id === "sheet-bank-icon-input") {
			const prev = byId("sheet-bank-icon-preview", inp)
			if (prev) prev.innerHTML = (inp as HTMLInputElement).value ? `<img src="${(inp as HTMLInputElement).value}" style="width:36px;height:36px;border-radius:8px;object-fit:cover" />` : ""
		}
		const form = inp.closest?.("form")
		const live = form?.querySelector<HTMLElement>("[data-live-total]")
		if (live) {
			const mode = live.getAttribute("data-live-total")
			if (mode === "none") live.textContent = "Total: no change (inside my world)"
			else {
				const raw = (inp as HTMLInputElement).value.replace(/,/g, ".").trim()
				const val = parseFloat(raw)
				if (!Number.isNaN(val) && val > 0) live.textContent = `Total: ${mode === "minus" ? "−" : "+"}${val.toFixed(2)} MAD`
				else live.textContent = "Total: no change"
			}
		}
	})
	d.addEventListener("change", (e) => {
		const sel = (e.target as HTMLElement).closest?.("#sheet-paid-source-select") as HTMLSelectElement | null
		if (!sel) return
		const opt = sel.options[sel.selectedIndex]
		const pTitle = byId("sheet-paid-title", sel)
		const pText = byId("sheet-paid-pending-text", sel)
		const pAmt = byId<HTMLInputElement>("sheet-paid-amount", sel)
		if (opt && opt.value) {
			const sName = opt.getAttribute("data-name") || opt.text.split(" (")[0] || "paid"
			const sAmt = opt.getAttribute("data-amt") || ""
			const sUsd = opt.getAttribute("data-usd") === "1"
			if (pTitle) pTitle.textContent = `Mark ${sName} paid`
			if (pText) pText.textContent = sAmt ? `Pending on hold: ${sUsd ? "$" : ""}${(Number(sAmt) / 100).toFixed(2)}` : "Enter amount received"
			if (pAmt) pAmt.placeholder = sAmt ? `Amount (blank = all ${sUsd ? "$" : ""}${(Number(sAmt) / 100).toFixed(2)})` : "Amount (blank = all)"
		}
	})

	// ---- Enter submits the open sheet form ---------------------------------
	d.addEventListener("keydown", (e) => {
		if (e.key !== "Enter") return
		const t = e.target as HTMLElement
		if (!t.closest) return
		const pf = t.closest("#sheet-paid-form") as HTMLFormElement | null
		if (pf && (t.tagName === "INPUT" || t.tagName === "SELECT")) {
			e.preventDefault()
			const pSel = pf.querySelector<HTMLSelectElement>("#sheet-paid-source-select")
			if (pSel && !pSel.value && pSel.options.length > 1) {
				pSel.selectedIndex = 1
				pSel.dispatchEvent(new Event("change", { bubbles: true }))
			}
			;(pf.querySelector<HTMLButtonElement>("button[type=submit]") || pf.querySelector<HTMLButtonElement>("button"))?.click()
			return
		}
		const tf = t.closest("#sheet-transfer-form") as HTMLFormElement | null
		if (tf && (t.tagName === "INPUT" || t.tagName === "SELECT")) {
			e.preventDefault()
			;(tf.querySelector<HTMLButtonElement>("button[type=submit]") || tf.querySelector<HTMLButtonElement>("button"))?.click()
		}
	})

	// ---- transfer form validation ------------------------------------------
	const transferCheck = (tf: HTMLFormElement, show: boolean) => {
		const fromEl = tf.querySelector<HTMLInputElement>("[name=from],[name=from_bank]")
		const toEl = tf.querySelector<HTMLInputElement>("[name=to],[name=to_bank]")
		const errEl = byId<HTMLElement>("transfer-error", tf)
		if (!errEl) return
		if (fromEl && toEl && fromEl.value && fromEl.value === toEl.value) {
			errEl.textContent = "From and To cannot be the same bank."
			if (show) errEl.style.display = "block"
		} else if (show) errEl.style.display = "none"
	}
	d.addEventListener("submit", (e) => {
		const tf = (e.target as HTMLElement).closest?.("#sheet-transfer-form") as HTMLFormElement | null
		if (!tf) return
		const amtEl = tf.querySelector<HTMLInputElement>("[name=amount]")
		const errEl = byId<HTMLElement>("transfer-error", tf)
		const fromEl = tf.querySelector<HTMLInputElement>("[name=from],[name=from_bank]")
		const toEl = tf.querySelector<HTMLInputElement>("[name=to],[name=to_bank]")
		if (fromEl && toEl && fromEl.value && fromEl.value === toEl.value) {
			e.preventDefault()
			if (errEl) {
				errEl.textContent = "From and To cannot be the same bank."
				errEl.style.display = "block"
			}
			return
		}
		const amt = parseFloat((amtEl?.value || "").replace(/,/g, ".").trim())
		if (!Number.isFinite(amt) || amt <= 0) {
			e.preventDefault()
			if (errEl) {
				errEl.textContent = "Please enter an amount to transfer."
				errEl.style.display = "block"
			}
			amtEl?.focus()
			return
		}
		if (errEl) errEl.style.display = "none"
	})
	d.addEventListener("change", (e) => {
		const tf = (e.target as HTMLElement).closest?.("#sheet-transfer-form") as HTMLFormElement | null
		const t = e.target as HTMLInputElement
		if (tf && (t.name === "from" || t.name === "to")) transferCheck(tf, true)
	})

	// ---- remember the default bank radio -----------------------------------
	try {
		const savedBank = localStorage.getItem("mt:defbank")
		if (savedBank !== null) {
			all<HTMLInputElement>("[data-from-radio]").forEach((r) => {
				if (r.value === savedBank) r.checked = true
			})
		}
	} catch {}

	// ---- pad notes: copy, long-press, row menus ----------------------------
	const toast = (text: string) => {
		const x = d.createElement("div")
		x.className = "nt-toast"
		x.textContent = text
		d.body.appendChild(x)
		setTimeout(() => x.remove(), 1100)
	}
	const copy = (text: string): Promise<void> => {
		try {
			if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text)
		} catch {}
		const a = d.createElement("textarea")
		a.value = text
		a.style.cssText = "position:fixed;opacity:0"
		d.body.appendChild(a)
		a.select()
		try {
			d.execCommand("copy")
		} catch {}
		a.remove()
		return Promise.resolve()
	}
	const grow = (ta: HTMLElement | null) => {
		if (!ta || ta.tagName !== "TEXTAREA") return
		const el = ta as HTMLTextAreaElement
		el.style.height = "auto"
		el.style.height = `${Math.min(el.scrollHeight, 132)}px`
	}
	const editItem = (it: Element | null) => {
		if (!it) return
		const f = it.querySelector<HTMLElement>("[data-edit]")
		const b = it.querySelector<HTMLElement>("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		const mn = it.querySelector<HTMLElement>(".nt-mn")
		if (mn) mn.hidden = true
		const ta = f.querySelector<HTMLTextAreaElement>("textarea,input[name=body]")
		if (ta && !ta.value) ta.value = ta.defaultValue || (it.querySelector("[data-copy] p")?.textContent || "").trim()
		grow(ta)
		ta?.focus({ preventScroll: true })
		ta?.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "nearest", behavior: "smooth" })
	}
	let hold = 0
	let fired = false
	let sx = 0
	let sy = 0
	d.addEventListener(
		"pointerdown",
		(e) => {
			const b = (e.target as Element).closest?.("[data-copy]")
			if (!b) return
			fired = false
			sx = e.clientX
			sy = e.clientY
			clearTimeout(hold)
			hold = window.setTimeout(() => {
				fired = true
				if (navigator.vibrate) navigator.vibrate(15)
				editItem(b.closest("[data-pad-item]"))
			}, 450)
		},
		true,
	)
	d.addEventListener("pointermove", (e) => {
		if (hold && (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8)) clearTimeout(hold)
	})
	;(["pointerup", "pointercancel", "pointerleave"] as const).forEach((n) =>
		d.addEventListener(
			n,
			() => {
				clearTimeout(hold)
			},
			true,
		),
	)
	d.addEventListener("contextmenu", (e) => {
		if ((e.target as Element).closest?.("[data-copy]")) e.preventDefault()
	})
	const closeMenus = () => {
		all<HTMLElement>(".nt-dd:not([hidden])").forEach((m) => {
			m.hidden = true
			const o = m.parentNode?.querySelector("[data-menu]")
			o?.setAttribute("aria-expanded", "false")
		})
	}
	d.addEventListener("click", (e) => {
		const t = e.target as Element
		if (!t.closest) return
		const mb = t.closest("[data-menu]")
		if (mb) {
			const dd = mb.parentNode?.querySelector(".nt-dd") as HTMLElement | null
			if (!dd) return
			const was = !dd.hidden
			closeMenus()
			if (!was) {
				dd.classList.remove("up")
				dd.hidden = false
				mb.setAttribute("aria-expanded", "true")
				const box = mb.closest(".nt-scr")
				if (box) {
					const br = box.getBoundingClientRect()
					const dr = dd.getBoundingClientRect()
					if (dr.bottom > br.bottom) dd.classList.add("up")
				}
			}
			return
		}
		const me = t.closest("[data-menu-edit]")
		if (me) {
			closeMenus()
			editItem(me.closest("[data-pad-item]"))
			return
		}
		if (!t.closest(".nt-dd")) closeMenus()
		const b = t.closest("[data-copy]")
		if (b) {
			if (fired) {
				fired = false
				return
			}
			const p = b.querySelector("p")
			copy((p || b).textContent?.trim() || "").then(() => toast("Copied"))
			return
		}
		const x = t.closest("[data-edit-x]")
		if (x) {
			const it = x.closest("[data-pad-item]")
			const f = it?.querySelector<HTMLElement>("[data-edit]")
			const c = it?.querySelector<HTMLElement>("[data-copy]")
			if (f) f.hidden = true
			if (c) c.hidden = false
			const mn2 = it?.querySelector<HTMLElement>(".nt-mn")
			if (mn2) mn2.hidden = false
		}
	})
	d.addEventListener("keydown", (e) => {
		if (e.key === "Escape") closeMenus()
	})

	// ---- keep today's predict earnings fresh while the page is open --------
	setInterval(() => {
		if (d.hidden) return
		if (!d.querySelector("[data-tick]")) return
		const todayFrame = app.frames.get?.("today")
		if (todayFrame) void todayFrame.reload().catch(() => {})
	}, 60000)

	// ---- keep background data fresh via the frame runtime ------------------
	const loaded = Date.now()
	setInterval(() => {
		if (!d.querySelector("[data-exo]") || d.hidden || Date.now() - loaded < 240000) return
		const a = d.activeElement
		if (a && a.matches?.("input,textarea,select")) return
		if (d.querySelector("[data-adp]:not([hidden]),[data-addp]:not([hidden])")) return
		void app.frames.top.reload().catch(() => {})
	}, 30000)
}
