import { css, type Handle, type RemixNode } from "remix/component";

import { routes } from "../routes.ts";

import { Document } from "./layout.tsx";
import { Icon } from "./kit.tsx";
import * as s from "./styles.ts";

export type NavKey = "home" | "stats" | "add" | "goals" | "settings";

export function TopBar() {
	return () => (
		<header
			mix={css({
				display: "flex",
				alignItems: "center",
				justifyContent: "space-between",
				padding: "12px 16px",
				borderBottom: "1px solid var(--line)",
			})}
		>
			<a href={routes.home.href()} mix={css({ ...s.formRow, gap: "9px", fontWeight: 700, fontSize: "20px", letterSpacing: "-0.04em" })}>
				<span
					aria-hidden="true"
					mix={css({
						display: "block",
						width: "28px",
						height: "28px",
						borderRadius: "8px",
						backgroundImage: s.goat,
						backgroundSize: "cover",
					})}
				/>
				moneytracker
			</a>
		</header>
	);
}

export function BottomNav(handle: Handle<{ active?: NavKey }>) {
	return () => {
		let { active } = handle.props;
		let items = [
			{ key: "home", label: "Home", href: routes.home.href(), icon: "home" },
			{ key: "stats", label: "Stats", href: routes.stats.href(), icon: "stats" },
			{ key: "add", label: "Add", href: routes.add.href(), icon: "plus" },
			{ key: "goals", label: "Goals", href: routes.goals.href(), icon: "goals" },
			{ key: "settings", label: "Settings", href: routes.settings.href(), icon: "settings" },
		] as const;

		return (
			<nav
				aria-label="Main"
				mix={css({
					position: "sticky",
					bottom: "0",
					display: "flex",
					padding: "0 0 env(safe-area-inset-bottom, 0px)",
					background: "var(--bg)",
					borderTop: "1px solid var(--line)",
				})}
			>
				{items.map((item) => (
					<a
						key={item.key}
						href={item.href}
						aria-label={item.label}
						aria-current={active === item.key ? "page" : undefined}
						mix={css({
							position: "relative",
							flex: "1",
							display: "flex",
							flexDirection: "column",
							alignItems: "center",
							gap: "3px",
							padding: "9px 0 8px",
							fontFamily: "var(--mono)",
							fontSize: "10px",
							color: active === item.key ? "var(--fg)" : "var(--fg2)",
						})}
					>
						{active === item.key ? (
							<span
								aria-hidden="true"
								mix={css({
									position: "absolute",
									top: "-1px",
									left: "30%",
									right: "30%",
									height: "2px",
									background: "var(--fg)",
								})}
							/>
						) : null}
						<Icon name={item.icon} />
						{item.label}
					</a>
				))}
			</nav>
		);
	};
}

export function Screen(
	handle: Handle<{
		title: string;
		active?: NavKey;
		heading?: string;
		back?: { href: string; label: string };
		children?: RemixNode;
	}>,
) {
	return () => {
		let { title, active, heading, back, children } = handle.props;
		return (
			<Document title={`${title} · moneytracker`}>
				<div
					mix={css({
						display: "flex",
						flexDirection: "column",
						minHeight: "100dvh",
						width: "100%",
						maxWidth: "480px",
						margin: "0 auto",
					})}
				>
					<TopBar />
					<main
						mix={css({
							flex: "1",
							display: "flex",
							flexDirection: "column",
							gap: "4px",
							padding: "16px 16px 28px",
						})}
					>
						{back ? (
							<a href={back.href} mix={css({ ...s.formRow, gap: "4px", ...s.small, ...s.mono, width: "fit-content" })}>
								<Icon name="back" size="14px" />
								{back.label}
							</a>
						) : null}
						{heading ? (
							<h1
								mix={css({
									fontSize: "28px",
									fontWeight: 700,
									letterSpacing: "-0.05em",
									lineHeight: 1,
									margin: back ? "6px 0 4px" : "4px 0 4px",
								})}
							>
								{heading}
							</h1>
						) : null}
						<div mix={css({ display: "flex", flexDirection: "column", gap: "12px" })}>{children}</div>
					</main>
					<BottomNav active={active} />
				</div>
			</Document>
		);
	};
}
