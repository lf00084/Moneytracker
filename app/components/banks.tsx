import type { BankView, MoneyView, PendingView } from "../lib/banks.ts"
import type { State } from "../lib/data.ts"
import { fmt, plain } from "../lib/money.ts"
import { dayLabel, today } from "../lib/time.ts"
import { AppLayout } from "./layout.tsx"
import { Back, BankIcon, Card, ErrorBanner, FlowBadge, Icon, PageHeader, Submit, view } from "./ui.tsx"

const col = { display: "flex", flexDirection: "column", gap: "8px" } as const
const contents = { display: "contents" }

export const BankSelect = view<{ list: BankView[]; pick: string; name?: string }>(({ list, pick, name = "bank" }) => (
	<select class="in" name={name}>
		{list.map((b) => (
			<option key={b.id} value={b.id} selected={b.id === pick ? true : undefined}>
				{b.name}
			</option>
		))}
	</select>
))

const Setup = view<{ s: State }>(({ s }) => (
	<Card title="Set up banks">
		<form method="post" action="/banks/setup" style={col} novalidate>
			<Back s={s} />
			<div class="wkn">{`Your balance now is ${fmt(s.balance)} ${s.user.currency}. Split it between your banks and your cash. Money you earn waits as pending until you mark it paid, unless the source is set to instant.`}</div>
			{[1, 2, 3].map((i) => (
				<div key={i} class="wmi bank-setup-item">
					<input class="in" name={`name${i}`} value={i === 1 ? "CIH" : i === 2 ? "BMCE" : ""} placeholder="Bank name" autocomplete="off" />
					<input class="in" name={`amount${i}`} placeholder="Balance now" inputmode="decimal" autocomplete="off" />
					<input class="in" name={`icon${i}`} placeholder="Icon URL (e.g. https://...)" autocomplete="off" />
				</div>
			))}
			<div class="wmi">
				<input class="in" value="Cash" disabled />
				<input class="in" name="cash" placeholder="Cash now" inputmode="decimal" autocomplete="off" />
			</div>
			<Submit >Start</Submit>
		</form>
	</Card>
))

const Total = view<{ s: State; m: MoneyView }>(({ s, m }) => (
	<div class="wh">
		<div class="whm">
			<div class="whb">
				<b>{fmt(m.total)}</b>
				<small>{s.user.currency}</small>
			</div>
			<span class="lb">Money + USDT. Pending is on hold.</span>
		</div>
		<div class="whs">
			<div>
				<span>Cash</span>
				<b>{fmt(m.cash)}</b>
			</div>
			<div>
				<span>Banks</span>
				<b>{fmt(m.banksTotal - m.cash)}</b>
			</div>
			<div>
				<span>USDT</span>
				<b>{fmt(m.usdtMad)}</b>
			</div>
		</div>
		{m.unmatchedCount > 0 ? (
			<div class="hm-needs-chip warn" style={{ marginTop: "10px" }}>
				<span>{m.unmatchedCount} unmatched P2P order{m.unmatchedCount > 1 ? "s" : ""} waiting for bank assignment</span>
			</div>
		) : null}
	</div>
))

const BankCard = view<{ s: State; m: MoneyView; b: BankView }>(({ s, m, b }) => (
	<details class="wk">
		<summary>
			<span style={{ display: "flex", alignItems: "center", gap: "8px" }}>
				<BankIcon name={b.name} url={b.iconUrl} size={22} />
				<span>{b.isDefault ? `${b.name} · default` : b.name}</span>
			</span>
			<span class="lb">
				{`${fmt(b.balance)} ${s.user.currency} `}
				<Icon name="chev" />
			</span>
		</summary>
		<div class="wkf">
			<form method="post" action="/banks/entry" style={col} novalidate>
				<Back s={s} />
				<input type="hidden" name="bank" value={b.id} />
				<div class="wmi">
					<input class="in" name="amount" inputmode="decimal" placeholder="Amount to add" data-live-price autocomplete="off" />
					<input class="in" name="note" placeholder="Note (Money added)" autocomplete="off" />
				</div>
				<div class="sheet-live-line" data-live-total="plus">
					Total: no change
				</div>
				<Submit >Add money</Submit>
			</form>

			<form method="post" action="/banks/set" style={col} novalidate>
				<Back s={s} />
				<input type="hidden" name="bank" value={b.id} />
				<input class="in" name="balance" inputmode="decimal" placeholder={`Real balance now (${plain(b.balance)})`} autocomplete="off" />
				<Submit class="outline">Set real balance</Submit>
			</form>

			<form method="post" action="/banks/transfer" style={col} novalidate>
				<Back s={s} />
				<input type="hidden" name="from" value={b.id} />
				<label class="lb">Move money from {b.name} to:</label>
				<div class="wmi">
					<select class="in" name="to">
						{m.banks.filter((x) => x.id !== b.id).map((x) => (
							<option key={x.id} value={x.id}>{x.name}</option>
						))}
					</select>
					<input class="in" name="amount" placeholder="Amount" inputmode="decimal" autocomplete="off" />
				</div>
				<div class="sheet-live-line">Total: no change</div>
				<Submit class="outline">Move money</Submit>
			</form>

			{b.cash ? null : (
				<>
					<form method="post" action="/banks/icon" style={col} novalidate>
						<Back s={s} />
						<input type="hidden" name="bank" value={b.id} />
						<input class="in" name="icon_url" value={b.iconUrl} placeholder="Icon URL (e.g. https://...)" autocomplete="off" />
						<Submit class="outline">Update icon</Submit>
					</form>

					<form method="post" action="/banks/rename" style={col} novalidate>
						<Back s={s} />
						<input type="hidden" name="bank" value={b.id} />
						<input class="in" name="name" value={b.name} autocomplete="off" />
						<Submit class="outline">Rename</Submit>
					</form>
				</>
			)}

			<div class="wkb">
				{b.isDefault ? null : (
					<form method="post" action="/banks/default" style={contents}>
						<Back s={s} />
						<input type="hidden" name="bank" value={b.id} />
						<Submit class="outline">Set as default</Submit>
					</form>
				)}
				{b.cash ? null : (
					<form method="post" action="/banks/delete" style={contents} data-confirm={`Delete ${b.name}? Its balance must be 0.`}>
						<Back s={s} />
						<input type="hidden" name="bank" value={b.id} />
						<Submit class="outline neg">Delete</Submit>
					</form>
				)}
			</div>
		</div>
	</details>
))

const AddBankForm = view<{ s: State }>(({ s }) => (
	<Card title="Add a bank">
		<form method="post" action="/banks" style={col} novalidate>
			<Back s={s} />
			<input class="in" name="name" placeholder="Bank name (e.g. Attijari)" autocomplete="off" required />
			<input class="in" name="amount" placeholder="Opening balance" inputmode="decimal" autocomplete="off" />
			<div class="bank-icon-preview-row">
				<input class="in" name="icon_url" data-icon-input placeholder="Icon URL (e.g. https://...)" autocomplete="off" />
				<div class="bank-icon-preview" data-icon-preview>
					<span class="bk-ico-char">?</span>
				</div>
			</div>
			<Submit >Add bank</Submit>
		</form>
	</Card>
))

export const BanksScreen = view<{ s: State }>(({ s }) => {
	const m = s.money
	if (!m)
		return (
			<AppLayout title="Banks" theme={s.user.theme} mobileTab="home" desktopTab="home" mobile={<Setup s={s} />} desktop={<Setup s={s} />} />
		)

	return (
		<AppLayout
			title="Banks"
			theme={s.user.theme}
			mobileTab="home"
			desktopTab="home"
			mobile={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Banks" back="/home" />
					<Total s={s} m={m} />
					<article>
						<div class="cb">
							<div class="tg" style={{ marginBottom: "8px" }}>Your banks and Cash</div>
							{m.banks.map((b) => (
								<BankCard key={b.id} s={s} m={m} b={b} />
							))}
						</div>
					</article>
					<AddBankForm s={s} />
				</>
			}
			desktop={
				<>
					<ErrorBanner s={s} />
					<PageHeader title="Banks" back="/home" />
					<Total s={s} m={m} />
					<div class="g2">
						<div>
							<article>
								<div class="cb">
									<div class="tg" style={{ marginBottom: "8px" }}>Your banks and Cash</div>
									{m.banks.map((b) => (
										<BankCard key={b.id} s={s} m={m} b={b} />
									))}
								</div>
							</article>
						</div>
						<div>
							<AddBankForm s={s} />
						</div>
					</div>
				</>
			}
		/>
	)
})
