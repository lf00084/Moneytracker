import { css, type Handle, type RemixNode } from "remix/component";

import { categories, fmt, type Category } from "../data/sample.ts";
import { routes } from "../routes.ts";

import * as s from "./styles.ts";

type Children = { children?: RemixNode };

export function Icon(handle: Handle<{ name: keyof typeof s.icons; size?: string }>) {
	return () => {
		let { name, size = "22px" } = handle.props;
		return (
			<span
				aria-hidden="true"
				mix={css({
					display: "block",
					flex: "none",
					width: size,
					height: size,
					backgroundColor: "currentColor",
					maskImage: s.icons[name],
					maskRepeat: "no-repeat",
					maskPosition: "center",
					maskSize: "contain",
				})}
			/>
		);
	};
}

export function Section(handle: Handle<Children>) {
	return () => (
		<section mix={css({ ...s.card, display: "flex", flexDirection: "column", gap: "10px" })}>
			{handle.props.children}
		</section>
	);
}

export function SectionHead(
	handle: Handle<{ title: string; sub?: string; href?: string; action?: string; id?: string }>,
) {
	return () => {
		let { title, sub, href, action, id } = handle.props;
		return (
			<div id={id} mix={css({ ...s.row, alignItems: "flex-start" })}>
				<div>
					<h2 mix={css({ ...s.h2 })}>{title}</h2>
					{sub ? <div mix={css({ ...s.small })}>{sub}</div> : null}
				</div>
				{href && action ? (
					<a href={href} mix={css({ ...s.accentText })}>
						{action}
					</a>
				) : null}
			</div>
		);
	};
}

export function Bar(handle: Handle<{ percent: number }>) {
	return () => {
		let percent = Math.max(0, Math.min(100, handle.props.percent));
		return (
			<div role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={percent} mix={css({ ...s.track })}>
				<div
					mix={css({
						height: "100%",
						borderRadius: "99px",
						background: "var(--accent)",
						width: `${percent}%`,
					})}
				/>
			</div>
		);
	};
}

export function TodayAmount(handle: Handle<{ amount: number }>) {
	return () => {
		let { amount } = handle.props;
		return (
			<div mix={css({ textAlign: "right", whiteSpace: "nowrap", ...(amount > 0 ? s.pos : s.muted) })}>
				{amount > 0 ? `+${fmt(amount)}` : "0"}{" "}
				<span mix={css({ ...s.small, fontWeight: 400 })}>today</span>
			</div>
		);
	};
}

export function LinkButton(handle: Handle<{ href: string; primary?: boolean } & Children>) {
	return () => {
		let { href, primary, children } = handle.props;
		return (
			<a href={href} mix={css({ ...(primary ? s.btnPrimary : s.btn) })}>
				{children}
			</a>
		);
	};
}

export function SubmitButton(
	handle: Handle<{ primary?: boolean; large?: boolean; label?: string } & Children>,
) {
	return () => {
		let { primary, large, label, children } = handle.props;
		return (
			<button
				type="submit"
				aria-label={label}
				mix={css({ ...(primary ? s.btnPrimary : s.btn), ...(large ? s.btnLarge : {}) })}
			>
				{children}
			</button>
		);
	};
}

export function Field(
	handle: Handle<{
		name: string;
		label: string;
		placeholder?: string;
		type?: string;
		value?: string | number;
		decimal?: boolean;
		required?: boolean;
	}>,
) {
	return () => {
		let { name, label, placeholder, type = "text", value, decimal, required } = handle.props;
		return (
			<label mix={css({ display: "flex", flexDirection: "column", gap: "4px", ...s.grow })}>
				<span mix={css({ ...s.small })}>{label}</span>
				<input
					name={name}
					type={type}
					value={value}
					placeholder={placeholder}
					inputMode={decimal ? "decimal" : undefined}
					autoComplete="off"
					required={required}
				/>
			</label>
		);
	};
}

export function Empty(handle: Handle<Children>) {
	return () => (
		<div mix={css({ ...s.hair, ...s.small })}>{handle.props.children}</div>
	);
}

export function QuickBuy(handle: Handle<{ path: string; selected: Category | null }>) {
	return () => {
		let { path, selected } = handle.props;
		return (
			<>
				<div mix={css({ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "8px" })}>
					{categories.map((name) => (
						<a
							key={name}
							data-quick=""
							href={`${path}?buy=${name}`}
							aria-current={selected === name ? "true" : undefined}
							mix={css({ ...s.quick })}
						>
							<Icon name={name} />
							<span>{name}</span>
						</a>
					))}
				</div>
				{selected ? (
					<form method="post" action={routes.createPurchase.href()} mix={css({ ...s.formRow })}>
						<input type="hidden" name="category" value={selected} />
						{selected === "Other" ? (
							<input name="label" placeholder="What" maxLength={40} autoComplete="off" aria-label="What" />
						) : null}
						<input
							name="amount"
							placeholder="Amount"
							inputMode="decimal"
							autoComplete="off"
							aria-label={`${selected} amount`}
						/>
						<SubmitButton primary large>
							Add
						</SubmitButton>
					</form>
				) : null}
			</>
		);
	};
}
