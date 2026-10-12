import { css, type Handle, type RemixNode } from "remix/component";

import { routes } from "../routes.ts";

import { Document } from "./layout.tsx";
import { Icon } from "./kit.tsx";
import * as s from "./styles.ts";

export type NavKey = "home" | "stats" | "add" | "goals" | "settings";

/**
 * The bottom bar: icons only. It has no box of its own. It uses the page color and a single
 * hairline on top, so it stays put at the bottom of the screen without looking like a panel.
 */
export function BottomNav(handle: Handle<{ active?: NavKey }>) {
	return () => {
		let { active } = handle.props;
		let items = [
			{ key: "home", label: "Home", href: routes.home.href(), icon: "home" },
			{ key: "stats", label: "Stats", href: routes.stats.href(), icon: "stats" },
			{ key: "add", label: "Add", href: routes.add.href(), icon: "plus" },
			{ key: "goals", label: "Goal", href: routes.goals.href(), icon: "goals" },
			{ key: "settings", label: "Settings", href: routes.settings.href(), icon: "settings" },
		] as const;

		return (
			<nav
				aria-label="Main"
				mix={css({
					position: "sticky",
					bottom: "0",
					display: "flex",
					justifyContent: "space-around",
					padding: "6px 0 calc(6px + env(safe-area-inset-bottom, 0px))",
					background: "var(--bg)",
					borderTop: "0.5px solid var(--line)",
				})}
			>
				{items.map((item) => (
					<a
						key={item.key}
						href={item.href}
						aria-label={item.label}
						aria-current={active === item.key ? "page" : undefined}
						mix={css({
							display: "flex",
							alignItems: "center",
							justifyContent: "center",
							padding: "10px 18px",
							color: active === item.key ? "var(--fg)" : "var(--fg2)",
						})}
					>
						<Icon name={item.icon} />
					</a>
				))}
			</nav>
		);
	};
}

/**
 * Every page goes through here: the document, one narrow column of content and the bottom bar.
 * Pages that sit under another page pass `back` to get a link above the heading.
 */
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
			<Document title={`${title} · Money tracker`}>
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
					<main
						mix={css({
							flex: "1",
							display: "flex",
							flexDirection: "column",
							gap: "24px",
							padding: "20px 16px 28px",
						})}
					>
						{back ? (
							<a href={back.href} mix={css({ ...s.formRow, gap: "4px", ...s.small, width: "fit-content" })}>
								<Icon name="back" size="14px" />
								{back.label}
							</a>
						) : null}
						{heading ? (
							<h1 mix={css({ fontSize: "18px", fontWeight: 500, marginTop: back ? "-12px" : "0" })}>{heading}</h1>
						) : null}
						{children}
					</main>
					<BottomNav active={active} />
				</div>
			</Document>
		);
	};
}
