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

	function endEdit(c) {
		var id = c.querySelector("[data-eid]")
		if (id) id.value = ""
		var eb = c.querySelector(".eb")
		if (eb) eb.hidden = true
		c.querySelector("textarea").value = ""
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
		if ((q = t.closest("[data-pw]"))) {
			var pwi = q.parentNode.querySelector("input")
			if (pwi) {
				var pwShow = pwi.type === "password"
				pwi.type = pwShow ? "text" : "password"
				q.setAttribute("aria-pressed", pwShow ? "true" : "false")
				q.setAttribute("aria-label", pwShow ? "Hide password" : "Show password")
			}
			return
		}
		if ((q = t.closest("[data-eye]"))) {
			var v = q.closest(".hm-bal").querySelector(".hm-dots")
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
		if ((q = t.closest(".bub"))) {
			q.classList.toggle("sel")
			var a = q.parentNode.querySelector(".acts")
			a.hidden = !a.hidden
			return
		}
		if ((q = t.closest("[data-act]"))) {
			var m = q.closest(".msg")
			var act = q.getAttribute("data-act")
			var body = m.querySelector(".bub").textContent
			if (act === "copy") {
				try {
					navigator.clipboard.writeText(body)
				} catch (x) {}
			} else if (act === "edit") {
				var c = d.querySelector('[data-comp="' + m.parentNode.getAttribute("data-list") + '"]')
				c.querySelector("[data-eid]").value = m.getAttribute("data-id")
				c.querySelector(".eb").hidden = false
				var ta = c.querySelector("textarea")
				ta.value = body
				ta.focus()
			}
			return
		}
		if ((q = t.closest("[data-cancel]"))) endEdit(q.closest("[data-comp]"))
	})

	d.addEventListener(
		"click",
		function (e) {
			var b = e.target.closest && e.target.closest("[data-confirm-btn]")
			if (b && !confirm(b.getAttribute("data-confirm-btn"))) e.preventDefault()
		},
		true,
	)

	// Fallback spinner for any submit button that is not the shared Submit component.
	var SPIN = '<span class="sb-i" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/></svg></span>'
	d.addEventListener("submit", function (e) {
		var f = e.target
		var msg = f.getAttribute && f.getAttribute("data-confirm")
		if (msg && !confirm(msg)) return e.preventDefault()
		var sub = e.submitter
		setTimeout(function () {
			if (e.defaultPrevented) return
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

	d.addEventListener("keydown", function (e) {
		var t = e.target
		if (e.key !== "Enter" || e.shiftKey || !(t.matches && t.matches("[data-comp] textarea"))) return
		e.preventDefault()
		if (t.value.trim()) t.closest("form").requestSubmit()
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
		var v = q.parentNode.firstChild
		v.innerHTML = v.getAttribute("data-bal") + " <small>" + v.getAttribute("data-cur") + "</small>"
	})

	all("[data-list]").forEach(function (L) {
		var last = L.lastElementChild
		if (L.getAttribute("data-list") !== "dash" && last && last.scrollIntoView) last.scrollIntoView({ block: "end" })
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
	var K = "mt:pad:v1"
	var TABS = {
		projects: { space: "project", entry: "note", head: "Projects", add: "New project", ph: "Write a note", empty: "No projects yet. Add your first one above.", noun: "notes" },
		people: { space: "person", entry: "quote", head: "People", add: "Add a person", ph: "What did they say?", empty: "No one yet. Add a person, then what they said.", noun: "things said" },
		books: { space: "book", entry: "lesson", head: "Books", add: "Book name", sub: "Author (optional)", ref: "Chapter or page (optional)", ph: "What did you learn?", empty: "No books yet. Add a book, then what you learned from it.", noun: "lessons" },
		tips: { entry: "tip", flat: true, ph: "Something useful to remember", ref: "Where from (optional)", empty: "Nothing saved yet." },
	}
	var data = { spaces: [], entries: [] }
	var load = function () {
		try {
			var v = JSON.parse(localStorage.getItem(K) || "null")
			if (v && v.spaces && v.entries) data = v
		} catch (e) {}
	}
	var save = function () {
		try {
			localStorage.setItem(K, JSON.stringify(data))
		} catch (e) {}
	}
	var uid = function () {
		return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
	}
	var esc = function (s) {
		return String(s).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
		})
	}
	var when = function (t) {
		return new Date(t).toLocaleDateString("en-GB", { day: "numeric", month: "short" })
	}
	var spaceOf = function (id) {
		return data.spaces.filter(function (s) {
			return s.id === id
		})[0]
	}
	var entriesOf = function (fn) {
		return data.entries
			.filter(fn)
			.sort(function (a, b) {
				return b.at - a.at
			})
	}
	var entryHtml = function (e, label) {
		return (
			'<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + "</div>" +
			'<div class="pdm"><span class="lb">' + (label ? esc(label) + " · " : "") + (e.ref ? esc(e.ref) + " · " : "") + when(e.at) + "</span>" +
			'<span class="pda"><button type="button" class="chip' + (e.home ? " on" : "") + '" data-pd="home">Home</button>' +
			'<button type="button" class="chip" data-pd="edit">Edit</button>' +
			'<button type="button" class="chip" data-pd="del">Delete</button></span></div></div>'
		)
	}
	var composer = function (c, spaceId) {
		return (
			'<form class="pdf" data-pd="entry" data-space="' + (spaceId || "") + '">' +
			'<textarea class="pdi" name="body" rows="3" placeholder="' + esc(c.ph) + '" required></textarea>' +
			(c.ref ? '<input class="pdi" name="ref" placeholder="' + esc(c.ref) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>'
		)
	}
	var tabHtml = function (key) {
		var c = TABS[key]
		var id = decodeURIComponent(location.hash.slice(1))
		if (c.flat) return composer(c, "") + (entriesOf(function (e) { return e.kind === c.entry }).map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">' + c.empty + "</div>")
		var sp = id && spaceOf(id)
		if (sp && sp.kind === c.space) {
			var list = entriesOf(function (e) { return e.space === sp.id })
			return (
				'<div class="pdhd"><a class="chip" href="#" data-pd="back">‹ ' + c.head + "</a>" +
				'<button type="button" class="chip" data-pd="delspace" data-id="' + sp.id + '">Delete</button></div>' +
				'<h2 class="pdtt">' + esc(sp.title) + "</h2>" + (sp.sub ? '<div class="lb">' + esc(sp.sub) + "</div>" : "") +
				composer(c, sp.id) +
				(list.map(function (e) { return entryHtml(e, "") }).join("") || '<div class="lb pde">Nothing here yet.</div>')
			)
		}
		var spaces = data.spaces
			.filter(function (s) { return s.kind === c.space })
			.sort(function (a, b) { return b.at - a.at })
		return (
			'<form class="pdf" data-pd="space"><input class="pdi" name="title" placeholder="' + esc(c.add) + '" autocomplete="off" required>' +
			(c.sub ? '<input class="pdi" name="sub" placeholder="' + esc(c.sub) + '" autocomplete="off">' : "") +
			'<button class="btn xs">Add</button></form>' +
			(spaces.map(function (s) {
				var n = data.entries.filter(function (e) { return e.space === s.id }).length
				return '<a class="pdc" href="#' + encodeURIComponent(s.id) + '"><span><b>' + esc(s.title) + '</b><span class="lb">' + (s.sub ? esc(s.sub) + " · " : "") + n + " " + c.noun + '</span></span><span class="mu">›</span></a>'
			}).join("") || '<div class="lb pde">' + c.empty + "</div>")
		)
	}
	var homeHtml = function () {
		var list = entriesOf(function (e) { return e.home }).slice(0, 6)
		return (
			'<div class="sh"><span>Pinned notes</span><span class="lb">' + list.length + "</span></div>" +
			'<form class="pdf" data-pd="entry" data-space="" data-home="1"><input class="pdi" name="body" placeholder="Add a note to home" autocomplete="off" required><button class="btn xs">Add</button></form>' +
			(list.map(function (e) {
				var s = e.space && spaceOf(e.space)
				return '<div class="pdn" data-id="' + e.id + '"><div class="pdt">' + esc(e.body) + '</div><div class="pdm"><span class="lb">' + (s ? esc(s.title) + " · " : "") + when(e.at) + '</span><span class="pda"><button type="button" class="chip" data-pd="home">Unpin</button></span></div></div>'
			}).join("") || '<div class="lb pde">Pin any note with the Home button.</div>')
		)
	}
	var paint = function () {
		[].slice.call(d.querySelectorAll("[data-pad]")).forEach(function (r) {
			var a = d.activeElement
			if (a && r.contains(a) && a.value) return
			r.innerHTML = tabHtml(r.getAttribute("data-pad"))
		})
		var h = d.activeElement
		;[].slice.call(d.querySelectorAll("[data-pad-home]")).forEach(function (r) {
			if (h && r.contains(h) && h.value) return
			r.innerHTML = homeHtml()
		})
	}
	var repaint = function () {
		save()
		;[].slice.call(d.querySelectorAll("[data-pad],[data-pad-home]")).forEach(function (r) {
			r.innerHTML = r.hasAttribute("data-pad") ? tabHtml(r.getAttribute("data-pad")) : homeHtml()
		})
	}
	d.addEventListener("submit", function (e) {
		var f = e.target
		var kind = f.getAttribute && f.getAttribute("data-pd")
		if (kind !== "space" && kind !== "entry") return
		e.preventDefault()
		var root = f.closest("[data-pad]")
		var tab = root && root.getAttribute("data-pad")
		var c = tab && TABS[tab]
		var v = function (n) {
			var i = f.elements[n]
			return i ? i.value.trim() : ""
		}
		var now = Date.now()
		if (kind === "space" && c) {
			if (!v("title")) return
			data.spaces.push({ id: uid(), kind: c.space, title: v("title").slice(0, 120), sub: v("sub").slice(0, 120), at: now })
		} else if (kind === "entry") {
			if (!v("body")) return
			var home = f.getAttribute("data-home") === "1"
			data.entries.push({ id: uid(), space: f.getAttribute("data-space") || null, kind: c ? c.entry : "note", body: v("body").slice(0, 4000), ref: v("ref").slice(0, 120), home: home, at: now })
		}
		repaint()
	})
	d.addEventListener("click", function (e) {
		var b = e.target.closest && e.target.closest("[data-pd]")
		if (!b || b.tagName === "FORM") return
		var act = b.getAttribute("data-pd")
		var row = b.closest("[data-id]")
		var id = row ? row.getAttribute("data-id") : b.getAttribute("data-id")
		var en = id && data.entries.filter(function (x) { return x.id === id })[0]
		if (act === "back") {
			e.preventDefault()
			history.pushState("", "", location.pathname)
			return repaint()
		}
		if (act === "home" && en) en.home = !en.home
		else if (act === "edit" && en) {
			var t = prompt("Edit", en.body)
			if (t === null || !t.trim()) return
			en.body = t.trim().slice(0, 4000)
		} else if (act === "del" && en) {
			if (!confirm("Delete this?")) return
			data.entries = data.entries.filter(function (x) { return x.id !== id })
		} else if (act === "delspace" && id) {
			if (!confirm("Delete this and everything inside it?")) return
			data.spaces = data.spaces.filter(function (x) { return x.id !== id })
			data.entries = data.entries.filter(function (x) { return x.space !== id })
			history.pushState("", "", location.pathname)
		} else return
		repaint()
	})
	addEventListener("hashchange", paint)
	addEventListener("storage", function (e) {
		if (e.key !== K) return
		load()
		paint()
	})
	load()
	paint()
})()

/* file20 */
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
	var edit = function (it) {
		var f = it && it.querySelector("[data-edit]")
		var b = it && it.querySelector("[data-copy]")
		if (!f || !b) return
		f.hidden = false
		b.hidden = true
		var mn = it.querySelector(".nt-mn")
		if (mn) mn.hidden = true
		var ta = f.querySelector("input[name=body],textarea")
		if (!ta.value) ta.value = ta.defaultValue || it.querySelector("[data-copy] p").textContent.trim()
		ta.focus()
		ta.setSelectionRange(ta.value.length, ta.value.length)
		it.scrollIntoView({ block: "center", behavior: "smooth" })
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

// Notes list: scroll to the newest (bottom) on load.
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
