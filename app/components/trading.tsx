import { Frame } from "remix/component"
import type { State } from "../lib/data.ts"
import { routes } from "../routes.ts"
import { fmt } from "../lib/money.ts"
import { showUsdt } from "../lib/usdt.ts"
import { dayLabel, timeAgo, today } from "../lib/time.ts"
import { allDone, backUsdt, DEPOSIT, FIVE, flowOf, GAME, gameOf, gamesStrip, hasGames, isDone, letter, resOf, stakesFor, toMad, totalPnl, TRIES, word, type Flow, type GameKey, type TradeSession } from "../lib/trade-math.ts"
import { Back, BankIcon, Card, FlowBadge, Icon, Submit, view } from "./ui.tsx"

const contents = { display: "contents" }

const sg = (minor: number) => `${minor < 0 ? "−" : "+"}${fmt(Math.abs(minor))}`
const tone = (minor: number) => (minor < 0 ? "neg" : "pos")

const SessionHid = view<{ s: State; t: TradeSession }>(({ s, t }) => (
	<>
		<Back s={s} />
		<input type="hidden" name="session_id" value={t.id} />
	</>
))

const PnlField = view(() => (
	<div class="fld">
		<div class="ferr" role="alert" hidden></div>
		<input class="in" name="pnl" placeholder="PnL in USDT" inputmode="decimal" autocomplete="off" />
	</div>
))

const Outcomes = view(() => (
	<div class="pbt p3">
		<Submit  name="outcome" value="win">
			Won
		</Submit>
		<Submit class="secondary" name="outcome" value="lose">
			Lost
		</Submit>
		<Submit class="outline" name="outcome" value="miss" formnovalidate>
			Miss
		</Submit>
	</div>
))

const Strategy = view<{ base: number; note?: string }>(({ base, note }) => {
	const st = stakesFor(base)
	return (
		<div class="stb">
			<div class="stt">
				<b>Strategy</b>
				<span>{`5 min · BTC or ETH · ${fmt(base)} USDT`}</span>
			</div>
			<ol class="stl">
				<li>
					<i>1</i>
					<span>Follow the indicator. Pick Up or Down</span>
					<b>{fmt(st[0]!)}</b>
				</li>
				<li>
					<i>2</i>
					<span>Instantly, same side</span>
					<b>{fmt(st[1]!)}</b>
				</li>
				<li>
					<i>3</i>
					<span>Won: same side. Lost: other side</span>
					<b>{fmt(st[2]!)}</b>
				</li>
			</ol>
			<div class="stn">{note ?? "Lost with some left: one more try with the rest. Miss or a second loss: stop for the day."}</div>
		</div>
	)
})

const Steps = view<{ s: State; t: TradeSession; f: Flow }>(({ s, t, f }) => (
	<Card title={`5 min · try ${f.tryNo} of ${TRIES}`}>
		<Strategy base={f.base} note={f.tryNo > 1 ? `First try lost. ${fmt(f.left)} USDT is left. This is the last try today.` : undefined} />
		<form method="post" action="/trading/result" class="pres" data-pnl novalidate>
			<SessionHid s={s} t={t} />
			<PnlField />
			<Outcomes />
		</form>
		{t.results.length > 0 ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last entry?">
				<SessionHid s={s} t={t} />
				<Submit class="xs outline">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const StopCard = view<{ f: Flow; games: boolean }>(({ f, games }) => (
	<div class="tstop" role="alert">
		<b>Stop trading now</b>
		<span>{`${fmt(f.left)} USDT is left from the 5 min. Do not predict again today.${games ? " Finish the 2 games and close." : ""}`}</span>
	</div>
))

const GameRow = view<{ s: State; t: TradeSession; g: GameKey; n: number }>(({ s, t, g, n }) => {
	const x = gameOf(t.results, g)
	if (x) {
		return (
			<div class="rw gdn">
				<span>{`Game ${n}`}</span>
				<span class="rt">
					<b class={tone(x.pnl)}>{`${sg(x.pnl)} USDT`}</b>
					<span class="mu">{x.won ? "Won" : "Lost"}</span>
				</span>
			</div>
		)
	}
	return (
		<form method="post" action="/trading/game" class="rw" data-pnl novalidate>
			<SessionHid s={s} t={t} />
			<input type="hidden" name="game" value={g} />
			<span>{`Game ${n} · ${fmt(GAME)} USDT`}</span>
			<span class="rt">
				<PnlField />
				<Submit class="xs" name="won" value="1">
					Won
				</Submit>
				<Submit class="xs secondary" name="won" value="0">
					Lost
				</Submit>
			</span>
		</form>
	)
})

const GamesCard = view<{ s: State; t: TradeSession; undo: boolean }>(({ s, t, undo }) => (
	<Card title="2 Games">
		<GameRow s={s} t={t} g="ga" n={1} />
		<GameRow s={s} t={t} g="gb" n={2} />
		{undo && (gameOf(t.results, "ga") || gameOf(t.results, "gb")) ? (
			<form method="post" action="/trading/undo" style={contents} data-confirm="Undo the last game?">
				<SessionHid s={s} t={t} />
				<Submit class="xs outline">Undo last</Submit>
			</form>
		) : null}
	</Card>
))

const OpenSummary = view<{ s: State; t: TradeSession }>(({ s, t }) => {
	const pnl = totalPnl(t.results)
	const ret = backUsdt(t.deposit, pnl)
	const cur = s.user.currency
	const mad = toMad(pnl, t.rate)
	return (
		<article class="tsum">
			<div class="gl">
				<div>
					<div class="tg">Running PnL</div>
					<b class={`big ${tone(pnl)}`}>{`${sg(pnl)} USDT`}</b>
					<div class="lb">{`≈ ${sg(mad)} ${cur} · 1 USDT = ${fmt(t.rate)} ${cur}`}</div>
				</div>
				<div class="tsr">
					<div class="lb">Started with</div>
					<b>{`${fmt(t.deposit)} USDT`}</b>
					<div class="lb">{`Returns ≈ ${fmt(ret)} USDT`}</div>
				</div>
			</div>
			{allDone(t.deposit, t.results) ? (
				<form method="post" action="/trading/finish" style={contents}>
					<SessionHid s={s} t={t} />
					<Submit class="full pos">Finish & save</Submit>
				</form>
			) : t.results.length > 0 ? (
				<form method="post" action="/trading/finish" style={contents} data-confirm="Finish now before all steps are done?">
					<SessionHid s={s} t={t} />
					<Submit class="xs outline">Finish now</Submit>
				</form>
			) : null}
		</article>
	)
})

const LockedCard = view<{ s: State }>(({ s }) => (
	<div class="pdn">{`Done for today. The next predict opens at ${String(s.user.day_start).padStart(2, "0")}:00.`}</div>
))

const Balance = view<{ s: State; ready: boolean }>(({ s, ready }) => {
	const w = s.wallet
	const have = w?.connected ? (w.predictUsdt ?? w.usdt) : 0
	return (
		<div class={ready ? "pbal ok" : "pbal no"}>
			<div class="pbn">
				<span>Predict wallet balance</span>
				<b>{`${fmt(have)} USDT`}</b>
			</div>
			<div class="pbn r">
				<span>Needed to start</span>
				<b>{`${fmt(DEPOSIT)} USDT`}</b>
			</div>
			{ready ? (
				<span class="pbi">
					<Icon name="check" />
				</span>
			) : (
				<span class="pba">Needs {fmt(DEPOSIT)} USDT</span>
			)}
		</div>
	)
})

const StartCard = view<{ s: State; ready: boolean }>(({ s, ready }) => {
	const w = s.wallet
	const cur = s.user.currency
	const miss = w?.connected ? `You need ${fmt(Math.max(0, DEPOSIT - (w.predictUsdt ?? w.usdt)))} USDT more in Predict wallet. Move it from Funding below.` : "Connect Binance in API connections first."
	return (
		<>
			<Balance s={s} ready={ready} />
			{ready ? (
				<form method="post" action="/trading/deposit" style={contents}>
					<Back s={s} />
					<Submit class="full">Start predict</Submit>
				</form>
			) : (
				<div class="pdn">{miss}</div>
			)}
			<div class="pdn">{`Uses ${fmt(FIVE)} for the 5 min and ${fmt(GAME)} + ${fmt(GAME)} for the 2 games. Checked against Predict wallet.`}</div>
			<Strategy base={FIVE} />
		</>
	)
})

const PastRow = view<{ s: State; t: TradeSession; reopen: boolean }>(({ s, t, reopen }) => {
	const net = toMad(t.pnl, t.rate)
	const five = resOf(t.results).map((x) => `${letter(x)}${x.asset ? ` ${x.asset.toUpperCase()}` : ""}`).join(" · ")
	const games = hasGames(t.deposit) ? gamesStrip(t.results) : ""
	const label = `${five ? `5 min ${five}` : ""}${five && games ? " · " : ""}${games ? `Games ${games}` : ""}`
	return (
		<div class="tbr">
			<div>
				<b>{dayLabel(t.day)}</b>
				<div class="lb">{label}</div>
			</div>
			<span class="rt">
				<span class="lb">{`${sg(t.pnl)} USDT`}</span>
				<b class={tone(net)}>{sg(net)}</b>
				{reopen ? (
					<form method="post" action="/trading/reopen" style={contents} data-confirm="Open this predict again?">
						<SessionHid s={s} t={t} />
						<Submit class="ub" aria-label="Open this predict again">
							<Icon name="undo" />
						</Submit>
					</form>
				) : null}
			</span>
		</div>
	)
})

const PastCard = view<{ s: State; list: TradeSession[]; canReopen: boolean }>(({ s, list, canReopen }) => {
	if (!list.length) return null
	const total = list.reduce((a, t) => a + toMad(t.pnl, t.rate), 0)
	return (
		<Card title={`Past Predicts · ${sg(total)} ${s.user.currency}`}>
			{list.map((t, i) => (
				<PastRow key={t.id} s={s} t={t} reopen={canReopen && i === 0} />
			))}
		</Card>
	)
})

const Status = view<{ ok: boolean; title: string; sub: string }>(({ ok, title, sub }) => (
	<div class={ok ? "tsl ok" : "tsl no"} role="status">
		<i></i>
		<b>{title}</b>
		<span>{sub}</span>
	</div>
))

const PickBankSection = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const m = s.money
	if (!w || !m) return null
	const loose = w.moves.filter((x) => (x.kind === "buy" || x.kind === "sell") && !x.bankId)
	if (!loose.length) return null
	const lastBank = m.banks.find((b) => b.isDefault)?.id ?? m.banks[0]?.id ?? ""

	return (
		<article id="unmatched">
			<div class="cb">
				<div class="gl">
					<div>
						<div class="tg warn">Pick bank for P2P orders</div>
						<b class="big2">{loose.length}</b>
					</div>
					<span class="lb">Links your bank to order payments</span>
				</div>
				{loose.map((o) => (
					<form key={o.id} method="post" action="/wallet/bank" class="p2p-pick-row">
						<Back s={s} />
						<input type="hidden" name="id" value={o.id} />
						<div>
							<b>{o.kind === "buy" ? "P2P Buy" : "P2P Sell"} {fmt(o.usdt)} USDT</b>
							<div class="lb">{fmt(o.mad)} {s.user.currency}{o.pay ? ` · ${o.pay}` : ""} · {o.day}</div>
						</div>
						<div class="p2p-pick-bank">
							<select class="in sm" name="bank">
								{m.banks.map((b) => (
									<option key={b.id} value={b.id} selected={b.id === lastBank ? true : undefined}>{b.name}</option>
								))}
							</select>
							<label class="remember-label">
								<input type="checkbox" name="remember" value="1" defaultChecked />
								<span class="lb">remember</span>
							</label>
							<Submit class="xs">Assign</Submit>
						</div>
					</form>
				))}
			</div>
		</article>
	)
})

const P2PBlock = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const m = s.money
	if (!w) return null
	const cur = s.user.currency
	const bankMap = new Map((m?.banks ?? []).map((b) => [b.id, b.name]))

	const p2pMoves = w.moves.filter((x) => x.kind === "buy" || x.kind === "sell")

	return (
		<div class="p2p-block">
			<article>
				<div class="cb">
					<div class="gl">
						<div>
							<div class="tg">P2P Trading</div>
							<b class={`big ${tone(w.p2pToday)}`}>{sg(w.p2pToday)} <small>{cur}</small></b>
							<div class="lb">Total profit: {sg(w.p2pTotal)} {cur} (after fees)</div>
						</div>
						<div class="tsr">
							<div class="lb">P2P Fees</div>
							<b>{fmt(w.fees)} {cur}</b>
						</div>
					</div>

					<div class="p2p-sync-banner">
						<div class="p2p-sync-status">
							<b>Auto-synced with Binance P2P</b>
							<span>Orders auto-detect bank (CIH, BMCE) and credit/deduct MAD automatically.</span>
						</div>
						<form method="post" action="/wallet/sync" style={contents}>
							<Back s={s} />
							<Submit class="xs">
								<Icon name="revert" /> Sync Binance
							</Submit>
						</form>
					</div>

					<div class="tg" style={{ marginTop: "16px", marginBottom: "8px" }}>Recent P2P Orders</div>
					{p2pMoves.length ? (
						<div class="p2p-orders-list">
							{p2pMoves.map((x) => {
								const bName = x.bankId ? bankMap.get(x.bankId) ?? "Cash" : "Unmatched"
								return (
									<div key={x.id} class="p2p-order-row">
										<div>
											<b>{x.kind === "buy" ? "Buy" : "Sell"} {fmt(x.usdt)} USDT</b>
											<div class="lb">
												{fmt(x.mad)} {cur} · fee {fmt(x.fee)} {cur} · <FlowBadge from={x.kind === "buy" ? bName : "Funding"} to={x.kind === "buy" ? "Funding" : bName} />
												{x.pay ? ` · ${x.pay}` : ""}
											</div>
										</div>
										<div class="p2p-order-rt">
											{x.profit !== undefined ? (
												<b class={tone(x.profit)}>{sg(x.profit)} <small>{cur}</small></b>
											) : null}
											<div class="lb">{x.day}</div>
											{!x.bankId && m ? (
												<form method="post" action="/wallet/bank" class="p2p-quick-assign" style={{ display: "flex", gap: "4px", marginTop: "4px" }}>
													<Back s={s} />
													<input type="hidden" name="id" value={x.id} />
													<input type="hidden" name="remember" value="1" />
													<select class="in sm" name="bank">
														<option value="">Assign bank...</option>
														{m.banks.map((b) => (
															<option key={b.id} value={b.id}>{b.name}</option>
														))}
													</select>
													<Submit class="xs">Save</Submit>
												</form>
											) : null}
										</div>
									</div>
								)
							})}
						</div>
					) : (
						<div class="lb">No P2P orders synced yet. Connect Binance in API connections or click Sync Binance.</div>
					)}
				</div>
			</article>
		</div>
	)
})

const DailyEarningsSection = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	if (!w) return null
	const cur = s.user.currency
	const netToday = w.netToday ?? 0
	const netTotal = w.netTotal ?? 0
	const days = w.days ?? []
	if (!days.length) return null
	const t = today(s.user.day_start)

	return (
		<article class="daily-earnings-card">
			<div class="cb">
				<div class="gl">
					<div>
						<div class="tg">Daily earnings</div>
						<b class={`big ${tone(netToday)}`}>{sg(netToday)} <small>{cur}</small></b>
						<div class="lb">Today, P2P + Predict after fees · all-time net {sg(netTotal)} {cur}</div>
					</div>
				</div>
				<div class="daily-earnings-list" style={{ marginTop: "12px" }}>
					{days.map((d) => {
						const totalMad = d.totalEarnedMad ?? 0
						const totalUsdt = d.totalEarnedUsdt ?? 0
						const p2pMad = d.p2pProfitMad ?? 0
						const predMad = d.predictProfitMad ?? 0
						const predUsdt = d.profit ?? 0
						const label = dayLabel(d.day, t)

						return (
							<div key={d.day} class="daily-earnings-row">
								<div class="de-left">
									<b class="de-date">{label}</b>
									<div class="de-badges">
										<span class="de-pill">P2P: <b class={tone(p2pMad)}>{sg(p2pMad)} {cur}</b></span>
										<span class="de-pill">Predict: <b class={tone(predMad)}>{sg(predMad)} {cur}</b> ({sg(predUsdt)} USDT)</span>
										<span class="de-pill mu">Bal: {fmt(d.balance)} USDT</span>
									</div>
								</div>
								<div class="de-right">
									<b class={`de-total ${tone(totalMad)}`}>{sg(totalMad)} <small>{cur}</small></b>
									<span class="lb">≈ {sg(totalUsdt)} USDT</span>
								</div>
							</div>
						)
					})}
				</div>
			</div>
		</article>
	)
})

// Daily strategy check: confirm once a day, then today's predict earnings are
// shown and refreshed (the frame reloads every minute while the page is open).
export const TodayCard = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const cur = s.user.currency
	const checked = !!w?.checkedToday
	const rate = w?.rate ?? s.user.usdt_rate
	const predictUsdt = w?.today ?? 0
	const predictMad = toMad(predictUsdt, rate)
	return (
		<article class="today-card" data-tick>
			<div class="cb">
				<div class="gl">
					<div>
						<div class="tg">Today&apos;s strategy</div>
						{checked ? (
							<>
								<b class={`big ${tone(predictMad)}`}>{sg(predictMad)} <small>{cur}</small></b>
								<div class="lb">Predict earned today · {sg(predictUsdt)} USDT</div>
							</>
						) : (
							<div class="lb">Do your 5 min + 2 games, then confirm below.</div>
						)}
					</div>
					<div class="tsr">
						<form method="post" action="/trading/check" data-rmx-target="today" style={contents}>
							<Back s={s} />
							<Submit class={checked ? "xs outline" : ""}>{checked ? "Done ✓" : "I did it today"}</Submit>
						</form>
					</div>
				</div>
				<Strategy base={FIVE} />
			</div>
		</article>
	)
})

const TodayLoading = view(() => (
	<article class="today-card">
		<div class="cb">
			<div class="lb">Checking today…</div>
		</div>
	</article>
))

export const TradingBody = view<{ s: State }>(({ s }) => {
	const w = s.wallet
	const cur = s.user.currency
	const open = s.trades.find((t) => t.status === "open")
	const settled = s.trades.filter((t) => t.status === "settled").slice(0, 10)
	const day = today(s.user.day_start)
	const tradedToday = s.trades.some((t) => t.day === day)
	const at = `${String(s.user.day_start).padStart(2, "0")}:00`
	const f = open ? flowOf(open.deposit, open.results) : null
	const stop = !!f?.stop
	const ready = !!w?.connected && (w.predictUsdt ?? w.usdt) >= DEPOSIT
	const ok = !stop && (!!open || (!tradedToday && ready))
	const title = stop ? "Stop trading now" : open ? "Predict open" : tradedToday ? "Done for today" : ready ? "You can predict" : "Add balance first"
	const sub = open ? (f!.over ? "Finish the games" : `Try ${f!.tryNo} of ${TRIES}`) : tradedToday ? `Again at ${at}` : ready ? "Balance in Predict" : "Needs 16 USDT"

	return (
		<div class="trd">
			<Frame name="today" src={routes.pages.todayPanel.href()} fallback={<TodayLoading />}></Frame>
			<article class="ptop-hero">
				<div class="cb">
					<div class="gl">
						<div>
							<div class="tg">Binance balance · all wallets</div>
							<b class="big bal-big">
								{showUsdt(w?.totalText ?? 0)} <small>USDT</small>
							</b>
							<div class="lb">≈ {fmt(w?.valueMad ?? 0)} {cur}</div>
						</div>
						<div class="tsr">
							<form method="post" action="/wallet/sync" style={contents}>
								<Back s={s} />
								<Submit class="ib" aria-label="Refresh wallet">
									<Icon name="revert" />
								</Submit>
							</form>
						</div>
					</div>

					<div class="whs two">
						<div>
							<span>Funding</span>
							<b>{showUsdt(w?.fundingText ?? 0)} USDT</b>
							<span class="lb">≈ {fmt(w?.fundingMad ?? 0)} {cur}</span>
						</div>
						<div>
							<span>Predictions</span>
							<b>{showUsdt(w?.predictText ?? 0)} USDT</b>
							<span class="lb">≈ {fmt(w?.predictMad ?? 0)} {cur}</span>
						</div>
					</div>

					<div class="rate-indicator-line">
						1 USDT = {fmt(w?.rate ?? s.user.usdt_rate)} {cur} {w?.mineRate ? "(avg of my P2P sells)" : "(market)"}{w?.rateAt ? ` · ${timeAgo(w.rateAt)}` : ""}
					</div>
					{w?.connected && w.error ? (
						<div class="wer" role="alert">
							{w.error}
						</div>
					) : null}

									</div>
			</article>

			<PickBankSection s={s} />

			<article>
				<div class="cb">
					<div class="tg">Predict Games</div>
					<Status ok={ok} title={title} sub={sub} />
					{open && f ? (
						<>
							<OpenSummary s={s} t={open} />
							{f.stop ? <StopCard f={f} games={hasGames(open.deposit) && !allDone(open.deposit, open.results)} /> : null}
							{f.over ? null : <Steps s={s} t={open} f={f} />}
							{hasGames(open.deposit) ? <GamesCard s={s} t={open} undo={f.over} /> : null}
						</>
					) : tradedToday ? (
						<LockedCard s={s} />
					) : (
						<StartCard s={s} ready={ready} />
					)}
					<PastCard s={s} list={settled} canReopen={!open} />
				</div>
			</article>

			<DailyEarningsSection s={s} />

			<P2PBlock s={s} />
		</div>
	)
})
