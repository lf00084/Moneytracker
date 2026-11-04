// @ts-nocheck
(function () {
	if (window.__mt) return
	window.__mt = 1
	var d = document
	var r = d.documentElement
	var all = function (sel, root) {
		return [].slice.call((root || d).querySelectorAll(sel))
	}
	var focusFirst = function (box) {
		var i = box.querySelector("input:not([type=hidden])")
		if (i) i.focus()
	}

	function setTheme(t) {
		r.setAttribute("data-theme", t)
		try {
			localStorage.setItem("mtheme", t)
		} catch (e) {}
		try {
			fetch("/settings/theme", { method: "POST", body: new URLSearchParams({ theme: t }), credentials: "same-origin", redirect: "manual" })
		} catch (e) {}
	}

	var open = {}
	try {
		open = JSON.parse(localStorage.getItem("mt:open") || "{}")
	} catch (e) {}

	d.addEventListener(
		"toggle",
		function (e) {
			var x = e.target
			if (x.matches && x.matches("details[data-keep-open]")) {
				open[x.getAttribute("data-keep-open")] = x.open
				try {
					localStorage.setItem("mt:open", JSON.stringify(open))
				} catch (err) {}
			}
			if (x.matches && x.matches(".xd") && !x.open) {
				var xf = x.querySelector("[data-adp]")
				var xb = x.parentNode.querySelector("[data-xplus]")
				if (xf) xf.hidden = true
				if (xb) xb.classList.remove("on")
			}
		},
		true,
	)

	d.addEventListener("click", function (e) {
		var t = e.target
		if (t.closest && !t.closest("[data-xplus]") && t.closest("details[data-fixed] > summary")) {
			e.preventDefault()
			return
		}
		var q = t.closest("button[name][value]")
		if (q && q.form) {
			var sh = q.form.querySelector('input[type=hidden][data-sub="' + q.name + '"]')
			if (!sh) {
				sh = d.createElement("input")
				sh.type = "hidden"
				sh.name = q.name
				sh.setAttribute("data-sub", q.name)
				q.form.appendChild(sh)
			}
			sh.value = q.value
		}
		if ((q = t.closest("[data-close]"))) {
			var cd = q.closest("details")
			if (cd) cd.open = false
			return
		}
		if (t.closest("[data-theme-toggle]")) return setTheme(r.getAttribute("data-theme") === "dark" ? "light" : "dark")
		if ((q = t.closest("[data-set-theme]"))) return setTheme(q.getAttribute("data-set-theme"))
		if ((q = t.closest("[data-eye]"))) {
			var card = q.closest(".hm-bal-card, .hm-bal, .hm-top-bal")
			var v = card ? card.querySelector(".hm-dots") : null
			if (!v) return
			var hide = q.getAttribute("data-s") !== "1"
			q.setAttribute("data-s", hide ? "1" : "0")
			v.innerHTML = hide ? v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>" : "••••••"
			return
		}
		if ((q = t.closest("[data-edit-bal]"))) {
			var bf = q.closest(".cd,.sc").querySelector("[data-balf]")
			bf.hidden = !bf.hidden
			q.setAttribute("aria-label", bf.hidden ? "Edit balance" : "Cancel")
			q.classList.toggle("hi", !bf.hidden)
			if (!bf.hidden) {
				var bi = bf.querySelector("input:not([type=hidden])")
				if (bi) {
					bi.focus()
					bi.select()
				}
			}
			return
		}
		if ((q = t.closest("[data-all]"))) {
			var af = q.closest(".iw").querySelector("input")
			af.value = q.getAttribute("data-all")
			af.focus()
			return
		}
		if ((q = t.closest("[data-tg],[data-pay]"))) {
			var add = q.hasAttribute("data-tg")
			var w = q.closest(".dbw")
			var p = w.querySelector(add ? "[data-addp]" : "[data-payp]")
			var o = w.querySelector(add ? "[data-payp]" : "[data-addp]")
			if (o) o.hidden = true
			p.hidden = !p.hidden
			if (!p.hidden) {
				var i = p.querySelector("input[name=amount]")
				if (i) i.focus()
			}
			return
		}
		if ((q = t.closest("[data-xplus]"))) {
			e.preventDefault()
			var xc = q.closest(".xc")
			var xd = xc.querySelector("details")
			var xm = xc.querySelector("[data-adp]")
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
		if ((q = t.closest("[data-nm]"))) {
			var nf = q.closest("form")
			nf.querySelector("[data-name]").value = q.getAttribute("data-nm")
			var pin = nf.querySelector("[data-price]")
			if (pin) pin.focus()
			return
		}
		if ((q = t.closest("[data-bigadd]"))) {
			var tf = q.getAttribute("data-for")
			var ap = tf ? d.getElementById(tf) : q.closest(".bgc").querySelector("[data-adp]")
			ap.hidden = !ap.hidden
			q.classList.toggle("on", !ap.hidden)
			if (!ap.hidden) focusFirst(ap)
			return
		}
		if ((q = t.closest("[data-mode]"))) {
			var form = q.closest("form")
			var mode = q.getAttribute("data-mode")
			all("[data-mode]", form).forEach(function (c) {
				c.classList.toggle("on", c === q)
			})
			form.querySelector("[data-mode-input]").value = mode
			form.setAttribute("data-kind", mode)
			form.setAttribute("data-m", mode)
			return
		}
	})

	d.addEventListener(
		"click",
		function (e) {
			var b = e.target.closest && e.target.closest("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn"))) e.preventDefault()
		},
		true,
	)

	var SPIN = '<span class="sb-i" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg></span>'
	d.addEventListener("submit", function (e) {
		var f = e.target
		var msg = f.getAttribute && f.getAttribute("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		if (f.getAttribute("data-submitted") === "1") {
			e.preventDefault()
			return
		}
		f.setAttribute("data-submitted", "1")
		var sub = e.submitter
		setTimeout(function () {
			if (e.defaultPrevented) {
				f.removeAttribute("data-submitted")
				return
			}
			all("button", f).forEach(function (b) {
				if (b.disabled) return
				b.disabled = true
				if (!sub || b === sub) {
					b.setAttribute("data-busy", "1")
					b.setAttribute("aria-busy", "true")
					if (!b.querySelector(".sb-i")) b.insertAdjacentHTML("beforeend", SPIN)
				} else b.setAttribute("data-lock", "1")
			})
		}, 0)
	})

	function unbusy() {
		all("form[data-submitted]").forEach(function (f) {
			f.removeAttribute("data-submitted")
		})
		all("button[data-busy],button[data-lock]").forEach(function (b) {
			b.disabled = false
			b.removeAttribute("data-busy")
			b.removeAttribute("data-lock")
			b.removeAttribute("aria-busy")
		})
	}
	window.addEventListener("pageshow", function (e) {
		if (e.persisted) unbusy()
	})

	var zone = "Africa/Casablanca"
	var fmt = function (loc, o) {
		o.timeZone = zone
		return new Intl.DateTimeFormat(loc, o)
	}
	var tf = fmt("en-GB", { hour: "2-digit", minute: "2-digit", hour12: false })
	var df = fmt("en-GB", { weekday: "long", day: "numeric", month: "long" })
	var nf = fmt("en-GB", { day: "2-digit", month: "2-digit", year: "numeric" })
	var af = fmt("ar-MA", { weekday: "long" })
	var wf = fmt("en-GB", { weekday: "short" })
	var yf = fmt("en-GB", { day: "numeric" })
	var mf = fmt("en-GB", { month: "short" })
	function tick() {
		var now = new Date()
		var sub = '<span class="clock-num">' + nf.format(now) + '</span> <span class="clock-dot">·</span> <span class="clock-ar">' + af.format(now) + "</span>"
		all("[data-clock-time]").forEach(function (el) {
			el.textContent = tf.format(now)
		})
		all("[data-clock-date]").forEach(function (el) {
			el.textContent = df.format(now)
		})
		all("[data-clock-subdate]").forEach(function (el) {
			el.innerHTML = sub
		})
		all("[data-d-wd]").forEach(function (el) {
			el.textContent = wf.format(now)
		})
		all("[data-d-ar]").forEach(function (el) {
			el.textContent = af.format(now)
		})
		all("[data-d-day]").forEach(function (el) {
			el.textContent = yf.format(now)
		})
		all("[data-d-mo]").forEach(function (el) {
			el.textContent = mf.format(now)
		})
	}
	setInterval(tick, 1000)

	all("details[data-keep-open]").forEach(function (x) {
		var k = x.getAttribute("data-keep-open")
		if (k in open) x.open = !!open[k]
	})

	var rb = false
	try {
		rb = sessionStorage.getItem("mt:rb") === "1"
		sessionStorage.removeItem("mt:rb")
	} catch (e) {}
	if (rb) all("[data-eye]").forEach(function (q) {
		q.setAttribute("data-s", "1")
		var card = q.closest(".hm-bal-card, .hm-bal, .hm-top-bal")
		var v = card ? card.querySelector(".hm-dots") : null
		if (v) v.innerHTML = v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>"
	})

	var loaded = Date.now()
	setInterval(function () {
		if (!d.querySelector("[data-exo]") || d.hidden || Date.now() - loaded < 240000) return
		var a = d.activeElement
		if (a && a.matches && a.matches("input,textarea,select")) return
		if (d.querySelector("[data-adp]:not([hidden]),[data-addp]:not([hidden])")) return
		try {
			if (d.querySelector('[data-eye][data-s="1"]')) sessionStorage.setItem("mt:rb", "1")
		} catch (e) {}
		location.reload()
	}, 30000)
})()
;(function () {
	var d = document
	var hold = 0
	var fired = false
	var sx = 0
	var sy = 0
	var toast = function (t) {
		var x = d.createElement("div")
		x.className = "nt-toast"
		x.textContent = t
		d.body.appendChild(x)
		setTimeout(function () {
			x.remove()
		}, 1100)
	}
	var copy = function (t) {
		try {
			if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(t)
		} catch (e) {}
		var a = d.createElement("textarea")
		a.value = t
		a.style.cssText = "position:fixed;opacity:0"
		d.body.appendChild(a)
		a.select()
		try {
			d.execCommand("copy")
		} catch (e) {}
		a.remove()
		return Promise.resolve()
	}
	var grow = function (ta) {
		if (!ta || ta.tagName !== "TEXTAREA") return
		ta.style.height = "auto"
		ta.style.height = Math.min(ta.scrollHeight, 132) + "px"
	}
	d.addEventListener("input", function (e) {
		if (e.target.matches && e.target.matches("textarea[data-grow]")) grow(e.target)
	})
	var edit = function (it) {
		var f = it && it.querySelector("[data-edit]")
		var b = it && it.querySelector("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		var mn = it.querySelector(".nt-mn")
		if (mn) mn.hidden = true
		var ta = f.querySelector("textarea,input[name=body]")
		if (!ta.value) ta.value = ta.defaultValue || it.querySelector("[data-copy] p").textContent.trim()
		grow(ta)
		ta.focus({ preventScroll: true })
		ta.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "nearest", behavior: "smooth" })
	}
	d.addEventListener("pointerdown", function (e) {
		var b = e.target.closest && e.target.closest("[data-copy]")
		if (!b) return
		fired = false
		sx = e.clientX
		sy = e.clientY
		clearTimeout(hold)
		hold = setTimeout(function () {
			fired = true
			if (navigator.vibrate) navigator.vibrate(15)
			edit(b.closest("[data-pad-item]"))
		}, 450)
	})
	d.addEventListener("pointermove", function (e) {
		if (hold && (Math.abs(e.clientX - sx) > 8 || Math.abs(e.clientY - sy) > 8)) clearTimeout(hold)
	})
	;["pointerup", "pointercancel", "pointerleave"].forEach(function (n) {
		d.addEventListener(n, function () {
			clearTimeout(hold)
		}, true)
	})
	d.addEventListener("contextmenu", function (e) {
		if (e.target.closest && e.target.closest("[data-copy]")) e.preventDefault()
	})
	var closeMenus = function () {
		[].slice.call(d.querySelectorAll(".nt-dd:not([hidden])")).forEach(function (m) {
			m.hidden = true
			var o = m.parentNode.querySelector("[data-menu]")
			if (o) o.setAttribute("aria-expanded", "false")
		})
	}
	d.addEventListener("keydown", function (e) {
		if (e.key === "Escape") closeMenus()
	})
	d.addEventListener("click", function (e) {
		var t = e.target
		var mb = t.closest && t.closest("[data-menu]")
		if (mb) {
			var dd = mb.parentNode.querySelector(".nt-dd")
			var was = !dd.hidden
			closeMenus()
			if (!was) {
				dd.classList.remove("up")
				dd.hidden = false
				mb.setAttribute("aria-expanded", "true")
				var box = mb.closest(".nt-scr")
				if (box) {
					var br = box.getBoundingClientRect()
					var dr = dd.getBoundingClientRect()
					if (dr.bottom > br.bottom) dd.classList.add("up")
				}
			}
			return
		}
		var me = t.closest && t.closest("[data-menu-edit]")
		if (me) {
			closeMenus()
			edit(me.closest("[data-pad-item]"))
			return
		}
		if (!(t.closest && t.closest(".nt-dd"))) closeMenus()
		var b = t.closest && t.closest("[data-copy]")
		if (b) {
			if (fired) {
				fired = false
				return
			}
			var p = b.querySelector("p")
			copy((p || b).textContent.trim()).then(function () {
				toast("Copied")
			})
			return
		}
		var x = t.closest && t.closest("[data-edit-x]")
		if (x) {
			var it = x.closest("[data-pad-item]")
			it.querySelector("[data-edit]").hidden = true
			it.querySelector("[data-copy]").hidden = false
			var mn2 = it.querySelector(".nt-mn")
			if (mn2) mn2.hidden = false
			return
		}
		var a = t.closest && t.closest("[data-xplus],[data-tg],[data-pay],[data-bigadd]")
		if (a) {
			setTimeout(function () {
				var box = a.closest(".xc,.dbw,.sc,.cd") || d
				var f = [].slice.call(box.querySelectorAll("[data-adp],[data-addp],[data-payp]")).filter(function (n) {
					return !n.hidden && n.offsetParent
				})[0]
				if (!f) return
				var i = f.querySelector("input:not([type=hidden]),textarea")
				if (i) i.focus({ preventScroll: true })
				f.scrollIntoView({ block: "center", behavior: "smooth" })
			}, 60)
		}
	})

	var dis = {}
	try {
		dis = JSON.parse(localStorage.getItem("mt:inv") || "{}")
	} catch (e) {}
	;[].slice.call(d.querySelectorAll("[data-inv]")).forEach(function (n) {
		if (dis[n.getAttribute("data-inv")]) n.hidden = true
	})
	d.addEventListener("click", function (e) {
		var x = e.target.closest && e.target.closest("[data-inv-x]")
		if (!x) return
		var n = x.closest("[data-inv]")
		dis[n.getAttribute("data-inv")] = 1
		try {
			localStorage.setItem("mt:inv", JSON.stringify(dis))
		} catch (err) {}
		n.hidden = true
	})
})()
;(function () {
	var run = function () {
		;[].slice.call(document.querySelectorAll("[data-bottom]")).forEach(function (l) {
			l.scrollTop = l.scrollHeight
		})
	}
	run()
	window.addEventListener("load", run)
	window.addEventListener("pageshow", run)
})()
;(function () {
	var MSG = { win: "Enter how much you won in USDT", lose: "Enter how much you lost in USDT" }
	var clear = function (f) {
		var i = f.querySelector("[name=pnl]")
		var e = f.querySelector(".ferr")
		if (i) i.classList.remove("bad")
		if (e) {
			e.hidden = true
			e.textContent = ""
		}
	}
	document.addEventListener(
		"submit",
		function (e) {
			var f = e.target
			if (!f.hasAttribute || !f.hasAttribute("data-pnl")) return
			var o = e.submitter && e.submitter.value
			if (o !== "win" && o !== "lose") return
			var i = f.querySelector("[name=pnl]")
			var n = parseFloat(String(i.value).replace(",", "."))
			if (isFinite(n) && n > 0) return
			e.preventDefault()
			e.stopImmediatePropagation()
			var er = f.querySelector(".ferr")
			i.classList.add("bad")
			er.textContent = MSG[o]
			er.hidden = false
			;(er.parentNode || i).scrollIntoView({ block: "center", behavior: "smooth" })
			i.focus({ preventScroll: true })
		},
		true,
	)
	document.addEventListener("input", function (e) {
		var f = e.target.closest && e.target.closest("[data-pnl]")
		if (f && e.target.name === "pnl") clear(f)
	})
})()
;(function () {
	var d = document
	var all = function (sel, root) {
		return [].slice.call((root || d).querySelectorAll(sel))
	}
	var SEL = ".nt-page form[method=post], form.nt-cmp"
	var seq = 0
	var CHECK = '<svg class="ic" viewBox="0 0 24 24"><path d="m5 12 5 5 9-9"/></svg>'

	function keep() {
		var open = {}
		all("details[data-keep-open]").forEach(function (x) {
			open[x.getAttribute("data-keep-open")] = x.open
		})
		return {
			open: open,
			win: window.scrollY,
			scr: all(".nt-scr").map(function (x) {
				return x.scrollTop
			}),
		}
	}

	function restore(k, bottom) {
		all("details[data-keep-open]").forEach(function (x) {
			var key = x.getAttribute("data-keep-open")
			if (key in k.open) x.open = k.open[key]
		})
		all(".nt-scr").forEach(function (x, i) {
			if (bottom) x.scrollTop = x.scrollHeight
			else if (k.scr[i] !== undefined) x.scrollTop = k.scr[i]
		})
		window.scrollTo(0, k.win)
	}

	function swap(html, k, bottom) {
		var doc = new DOMParser().parseFromString(html, "text/html")
		var next = doc.querySelector(".app")
		var cur = d.querySelector(".app")
		if (!next || !cur) return false
		cur.innerHTML = next.innerHTML
		restore(k, bottom)
		return true
	}

	function recount(scope) {
		var page = scope.closest(".nt-page") || d
		var chip = page.querySelector(".nt-pc.on [data-count]")
		if (chip) {
			var list = page.querySelector(".nt-scr")
			var open = 0
			if (list) {
				all("[data-pad-item]", list).forEach(function (r) {
					if (r.querySelector('form[action="/pad/toggle"]') && !r.classList.contains("dn")) open++
				})
			}
			chip.textContent = String(open)
		}
		var stat = page.querySelector("[data-home-stat]")
		if (stat) {
			var rows = all("[data-pad-item]", page)
			var done = rows.filter(function (r) {
				return r.classList.contains("dn")
			}).length
			stat.textContent = done + " of " + rows.length + " done"
			var bar = page.querySelector("[data-home-bar] i")
			if (bar) bar.style.width = (rows.length ? Math.round((done / rows.length) * 100) : 0) + "%"
		}
	}

	function post(action, body) {
		return fetch(action, { method: "POST", body: body, credentials: "same-origin", headers: { "X-Requested-With": "fetch" } }).then(function (r) {
			if (!r.ok) throw new Error("bad")
			return r
		})
	}

	function drop(item, list, req) {
		item.classList.add("gone")
		setTimeout(function () {
			var scope = item.closest(".nt-page") || d
			item.remove()
			recount(scope)
			if (list && !list.querySelector("[data-pad-item]")) (req || Promise.resolve()).then(function () {
				location.reload()
			})
		}, 170)
	}

	d.addEventListener("submit", function (e) {
		var f = e.target
		if (e.defaultPrevented || !f.matches || !f.matches(SEL) || f.target) return
		if (String(f.enctype).indexOf("multipart") === 0) return
		var sub = e.submitter
		var action = (sub && sub.getAttribute("formaction")) || f.getAttribute("action")
		if (!action) return
		e.preventDefault()

		var body = new URLSearchParams(new FormData(f))
		if (sub && sub.name) body.append(sub.name, sub.value)
		var item = f.closest("[data-pad-item]")
		var list = item && item.closest(".nt-scr")

		if (action === "/pad/toggle" && item) {
			var nowDone = !item.classList.contains("dn")
			item.classList.toggle("dn", nowDone)
			var ck = f.querySelector(".nt-ck")
			if (ck) {
				ck.classList.toggle("d", nowDone)
				ck.setAttribute("aria-label", nowDone ? "Mark as open" : "Mark as done")
				var lab = ck.querySelector(".sb-l")
				if (lab) lab.innerHTML = nowDone ? CHECK : ""
			}
			recount(item)
			var tr = post(action, body)
			tr.catch(function () {
				location.reload()
			})
			if (nowDone && list && list.hasAttribute("data-hide-done")) setTimeout(function () {
				drop(item, list, tr)
			}, 260)
			return
		}

		if (action === "/pad/delete" && item) {
			var dr = post(action, body)
			dr.catch(function () {
				location.reload()
			})
			drop(item, list, dr)
			return
		}

		if (action === "/pad/edit" && item) {
			var ta = f.querySelector("[name=body]")
			var val = ta ? ta.value.trim() : ""
			if (!val) return
			var p = item.querySelector("[data-copy] p")
			if (p) p.textContent = val
			if (ta) ta.defaultValue = val
			f.hidden = true
			var cp = item.querySelector("[data-copy]")
			if (cp) cp.hidden = false
			var mn = item.querySelector(".nt-mn")
			if (mn) mn.hidden = false
			post(action, body).catch(function () {
				location.reload()
			})
			return
		}

		var add = action === "/pad/add"
		var typing = add && d.activeElement && f.contains(d.activeElement)
		if (add && sub) {
			sub.disabled = true
			sub.setAttribute("data-busy", "1")
			sub.setAttribute("aria-busy", "true")
		}
		var mine = ++seq
		var k = keep()
		var dest = ""
		fetch(action, { method: "POST", body: body, credentials: "same-origin", headers: { "X-Requested-With": "fetch" } })
			.then(function (r) {
				if (!r.ok) throw new Error("bad")
				dest = r.url
				if (new URL(dest).pathname !== location.pathname) {
					location.assign(dest)
					return null
				}
				return r.text()
			})
			.then(function (html) {
				if (html === null || mine !== seq) return
				if (!swap(html, k, add)) throw new Error("swap")
				if (dest !== location.href) history.replaceState(null, "", dest)
				if (typing) {
					var i = d.querySelector(".nt-cmp input[name=body]")
					if (i) i.focus({ preventScroll: true })
				}
			})
			.catch(function () {
				HTMLFormElement.prototype.submit.call(f)
			})
	})
})()
;(function () {
	var d = document
	function openSheet(id) {
		var el = d.getElementById(id)
		if (el) {
			el.hidden = false
			var inp = el.querySelector("input:not([type=hidden])")
			if (inp) inp.focus()
		}
	}
	function closeSheets() {
		var list = d.querySelectorAll(".app-sheet-ov")
		for (var i = 0; i < list.length; i++) list[i].hidden = true
	}
	d.addEventListener("click", function (e) {
		var t = e.target
		if (t.closest && t.closest("[data-sheet-close]")) {
			closeSheets()
			return
		}
		if (t.classList && t.classList.contains("app-sheet-ov")) {
			closeSheets()
			return
		}
		var feeBtn = t.closest && t.closest("[data-set-fee]")
		if (feeBtn) {
			var form = feeBtn.closest("form")
			if (form) {
				var nameInput = form.querySelector("[data-name]")
				var priceInput = form.querySelector("[data-price]")
				if (nameInput) nameInput.value = "Bank fee"
				if (priceInput) priceInput.focus()
			}
			return
		}
		var st = t.closest && t.closest("[data-sheet-trigger]")
		if (st) {
			var kind = st.getAttribute("data-sheet-trigger")
			if (kind === "bought") openSheet("sheet-bought")
			else if (kind === "add-money") openSheet("sheet-add-money")
			else if (kind === "transfer") openSheet("sheet-transfer")
			else if (kind === "add-bank") openSheet("sheet-add-bank")
			else if (kind === "paid") {
				var sId = st.getAttribute("data-source-id") || ""
				var sName = st.getAttribute("data-source-name") || "Paid"
				var sAmt = st.getAttribute("data-source-amt") || ""
				var sUsd = st.getAttribute("data-source-usd") === "1"
				var pTitle = d.getElementById("sheet-paid-title")
				var pSelect = d.getElementById("sheet-paid-source-select")
				var pText = d.getElementById("sheet-paid-pending-text")
				var pAmt = d.getElementById("sheet-paid-amount")
				if (pSelect) {
					if (sId) {
						pSelect.value = sId
					} else if (pSelect.selectedIndex <= 0 && pSelect.options.length > 1) {
						for (var oi = 1; oi < pSelect.options.length; oi++) {
							if (Number(pSelect.options[oi].getAttribute("data-amt") || 0) > 0) {
								pSelect.selectedIndex = oi
								break
							}
						}
						if (pSelect.selectedIndex <= 0) pSelect.selectedIndex = 1
					}
					var opt = pSelect.options[pSelect.selectedIndex]
					if (opt && opt.value) {
						sId = opt.value
						sName = opt.getAttribute("data-name") || opt.text.split(" (")[0]
						sAmt = opt.getAttribute("data-amt") || sAmt
						sUsd = opt.getAttribute("data-usd") === "1" || sUsd
					}
				}
				if (pTitle) pTitle.textContent = sId ? "Mark " + sName + " paid" : "Mark paid"
				if (pAmt) {
					pAmt.value = ""
					pAmt.placeholder = sAmt ? "Amount (blank = all " + (sUsd ? "$" : "") + (Number(sAmt) / 100).toFixed(2) + ")" : "Amount (blank = all)"
				}
				if (pText) pText.textContent = sAmt ? "Pending on hold: " + (sUsd ? "$" : "") + (Number(sAmt) / 100).toFixed(2) : "Select source and amount received"
				openSheet("sheet-paid")
			} else if (kind === "adjust-pending") {
				var sId2 = st.getAttribute("data-source-id") || ""
				var sName2 = st.getAttribute("data-source-name") || "pending"
				var sAmt2 = st.getAttribute("data-source-amt") || ""
				var sUsd2 = st.getAttribute("data-source-usd") === "1"
				var aTitle = d.getElementById("sheet-adjust-title")
				var aSrc = d.getElementById("sheet-adjust-source-id")
				var aText = d.getElementById("sheet-adjust-current-text")
				var aAmt = d.getElementById("sheet-adjust-amount")
				if (aTitle) aTitle.textContent = "Adjust " + sName2 + " pending"
				if (aSrc) aSrc.value = sId2
				if (aAmt) aAmt.value = sAmt2 ? (Number(sAmt2) / 100).toFixed(2) : ""
				if (aText) aText.textContent = "Current pending: " + (sUsd2 ? "$" : "") + (Number(sAmt2) / 100).toFixed(2)
				openSheet("sheet-adjust")
			}
			return
		}
		var btile = t.closest && t.closest("[data-bank-tile]")
		if (btile) {
			var bId = btile.getAttribute("data-bank-tile")
			var bName = btile.getAttribute("data-bank-name")
			var bBal = btile.getAttribute("data-bank-bal")
			var bCash = btile.getAttribute("data-bank-cash") === "1"
			var bDef = btile.getAttribute("data-bank-default") === "1"
			var bIcon = btile.getAttribute("data-bank-icon") || ""

			var sbn = d.getElementById("sheet-bank-name")
			var sbb = d.getElementById("sheet-bank-bal")
			var sbIconId = d.getElementById("sheet-bank-icon-id")
			var sbIconInp = d.getElementById("sheet-bank-icon-input")
			var sbIconPrev = d.getElementById("sheet-bank-icon-preview")
			var sbDefId = d.getElementById("sheet-bank-default-id")
			var sbDefForm = d.getElementById("sheet-bank-default-form")
			var sbDelId = d.getElementById("sheet-bank-delete-id")
			var sbDelForm = d.getElementById("sheet-bank-delete-form")

			if (sbn) sbn.textContent = bName
			if (sbb) sbb.textContent = (Number(bBal) / 100).toFixed(2) + " MAD"
			if (sbIconId) sbIconId.value = bId
			if (sbIconInp) sbIconInp.value = bIcon
			if (sbIconPrev) {
				sbIconPrev.innerHTML = bIcon ? '<img src="' + bIcon + '" style="width:36px;height:36px;border-radius:8px;object-fit:cover" />' : ""
			}
			if (sbDefId) sbDefId.value = bId
			if (sbDefForm) sbDefForm.hidden = bDef || bCash
			if (sbDelId) sbDelId.value = bId
			if (sbDelForm) sbDelForm.hidden = bCash

			openSheet("sheet-bank-actions")
			return
		}
		var rad = t.closest && t.closest("[data-from-radio]")
		if (rad) {
			try {
				localStorage.setItem("mt:defbank", rad.value)
			} catch (err) {}
		}
	})

	d.addEventListener("input", function (e) {
		var inp = e.target
		if (inp.id === "sheet-bank-icon-input") {
			var prev = d.getElementById("sheet-bank-icon-preview")
			if (prev) {
				prev.innerHTML = inp.value ? '<img src="' + inp.value + '" style="width:36px;height:36px;border-radius:8px;object-fit:cover" />' : ""
			}
		}
		var form = inp.closest && inp.closest("form")
		if (form) {
			var live = form.querySelector("[data-live-total]")
			if (live) {
				var mode = live.getAttribute("data-live-total")
				if (mode === "none") {
					live.textContent = "Total: no change (inside my world)"
				} else {
					var raw = inp.value.replace(/,/g, ".").trim()
					var val = parseFloat(raw)
					if (!isNaN(val) && val > 0) {
						var sign = mode === "minus" ? "−" : "+"
						live.textContent = "Total: " + sign + val.toFixed(2) + " MAD"
					} else {
						live.textContent = "Total: no change"
					}
				}
			}
		}
	})

	d.addEventListener("change", function (e) {
		var sel = e.target && e.target.closest && e.target.closest("#sheet-paid-source-select")
		if (sel) {
			var opt = sel.options[sel.selectedIndex]
			var pTitle = d.getElementById("sheet-paid-title")
			var pText = d.getElementById("sheet-paid-pending-text")
			var pAmt = d.getElementById("sheet-paid-amount")
			if (opt && opt.value) {
				var sName = opt.getAttribute("data-name") || opt.text.split(" (")[0]
				var sAmt = opt.getAttribute("data-amt") || ""
				var sUsd = opt.getAttribute("data-usd") === "1"
				if (pTitle) pTitle.textContent = "Mark " + sName + " paid"
				if (pText) pText.textContent = sAmt ? "Pending on hold: " + (sUsd ? "$" : "") + (Number(sAmt) / 100).toFixed(2) : "Enter amount received"
				if (pAmt) pAmt.placeholder = sAmt ? "Amount (blank = all " + (sUsd ? "$" : "") + (Number(sAmt) / 100).toFixed(2) + ")" : "Amount (blank = all)"
			}
		}
	})

	d.addEventListener("keydown", function (e) {
		if (e.key === "Escape") closeSheets()
		if (e.key === "Enter") {
			var t = e.target
			var pf = t && t.closest && t.closest("#sheet-paid-form")
			if (pf && (t.tagName === "INPUT" || t.tagName === "SELECT")) {
				e.preventDefault()
				var pSel = pf.querySelector("#sheet-paid-source-select")
				if (pSel && !pSel.value && pSel.options.length > 1) {
					pSel.selectedIndex = 1
					pSel.dispatchEvent(new Event("change", { bubbles: true }))
				}
				var subBtn = pf.querySelector("button[type=submit]") || pf.querySelector("button")
				if (subBtn) subBtn.click()
				else if (typeof pf.requestSubmit === "function") pf.requestSubmit()
				else pf.submit()
				return
			}
			var tf = t && t.closest && t.closest("#sheet-transfer-form")
			if (tf && (t.tagName === "INPUT" || t.tagName === "SELECT")) {
				e.preventDefault()
				var tSub = tf.querySelector("button[type=submit]") || tf.querySelector("button")
				if (tSub) tSub.click()
				else if (typeof tf.requestSubmit === "function") tf.requestSubmit()
				else tf.submit()
				return
			}
		}
	})

	d.addEventListener("submit", function (e) {
		var tf = e.target && e.target.closest && e.target.closest("#sheet-transfer-form")
		if (tf) {
			var fromEl = tf.querySelector("[name=from]") || tf.querySelector("[name=from_bank]")
			var toEl = tf.querySelector("[name=to]") || tf.querySelector("[name=to_bank]")
			var amtEl = tf.querySelector("[name=amount]")
			var errEl = d.getElementById("transfer-error")
			if (fromEl && toEl && fromEl.value && toEl.value && fromEl.value === toEl.value) {
				e.preventDefault()
				if (errEl) {
					errEl.textContent = "From and To cannot be the same bank."
					errEl.style.display = "block"
				}
				return
			}
			var amt = parseFloat((amtEl ? amtEl.value : "").replace(/,/g, ".").trim())
			if (!isFinite(amt) || amt <= 0) {
				e.preventDefault()
				if (errEl) {
					errEl.textContent = "Please enter an amount to transfer."
					errEl.style.display = "block"
				}
				if (amtEl) amtEl.focus()
				return
			}
			if (errEl) errEl.style.display = "none"
		}
	})

	d.addEventListener("change", function (e) {
		var tf = e.target && e.target.closest && e.target.closest("#sheet-transfer-form")
		if (tf && (e.target.name === "from" || e.target.name === "to")) {
			var fromEl = tf.querySelector("[name=from]")
			var toEl = tf.querySelector("[name=to]")
			var errEl = d.getElementById("transfer-error")
			if (fromEl && toEl && fromEl.value && toEl.value && fromEl.value === toEl.value) {
				if (errEl) {
					errEl.textContent = "From and To cannot be the same bank."
					errEl.style.display = "block"
				}
			} else if (errEl) {
				errEl.style.display = "none"
			}
		}
	})

	try {
		var savedBank = localStorage.getItem("mt:defbank")
		if (savedBank !== null) {
			var radios = d.querySelectorAll("[data-from-radio]")
			for (var r = 0; r < radios.length; r++) {
				if (radios[r].value === savedBank) {
					radios[r].checked = true
					break
				}
			}
		}
	} catch (e) {}
})()

