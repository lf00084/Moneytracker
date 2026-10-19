import { createController } from "remix/router";

import { categories, sources, type Category } from "../data/sample.ts";
import { routes } from "../routes.ts";

import { AddPage } from "./add.tsx";
import { DebtsPage } from "./debts.tsx";
import { GoalsPage } from "./goals.tsx";
import { HomePage } from "./home.tsx";
import { NotFoundPage } from "./not-found.tsx";
import { PurchasesPage } from "./purchases.tsx";
import { SettingsPage } from "./settings.tsx";
import { SourcePage } from "./source.tsx";
import { SourcesPage } from "./sources.tsx";
import { StatsPage } from "./stats.tsx";
import { WishesPage } from "./wishes.tsx";

/** Reads `?buy=Coffee` so the "I bought" chips can open their form without a script. */
function readCategory(url: URL): Category | null {
	let value = url.searchParams.get("buy");
	return categories.find((category) => category === value) ?? null;
}

/** Form handlers have no logic yet. They send you back to the page that holds the form. */
function redirectTo(href: string): Response {
	return new Response(null, { status: 303, headers: { Location: href } });
}

export default createController(routes, {
	actions: {
		// Pages. Everything shown comes from `app/data/sample.ts`.
		home({ render, url }) {
			return render(<HomePage buy={readCategory(url)} />);
		},
		stats({ render }) {
			return render(<StatsPage />);
		},
		purchases({ render }) {
			return render(<PurchasesPage />);
		},
		add({ render, url }) {
			return render(<AddPage buy={readCategory(url)} />);
		},
		goals({ render }) {
			return render(<GoalsPage />);
		},
		wishes({ render }) {
			return render(<WishesPage />);
		},
		debts({ render }) {
			return render(<DebtsPage />);
		},
		sources({ render }) {
			return render(<SourcesPage />);
		},
		source({ render, params }) {
			let source = sources.find((item) => item.id === params.id);
			if (!source) return render(<NotFoundPage />, { status: 404 });
			return render(<SourcePage source={source} />);
		},
		settings({ render }) {
			return render(<SettingsPage />);
		},

		// Form handlers. Empty on purpose.
		saveBalance() {
			return redirectTo(routes.home.href());
		},
		createPurchase() {
			return redirectTo(routes.home.href());
		},
		createEntry({ params }) {
			return redirectTo(routes.source.href({ id: params.id }));
		},
		deleteEntry({ params }) {
			return redirectTo(routes.source.href({ id: params.id }));
		},
		saveRate({ params }) {
			return redirectTo(routes.source.href({ id: params.id }));
		},
		createSource() {
			return redirectTo(routes.sources.href());
		},
		createWish() {
			return redirectTo(routes.wishes.href());
		},
		buyWish() {
			return redirectTo(routes.wishes.href());
		},
		createDebt() {
			return redirectTo(routes.debts.href());
		},
		payDebt() {
			return redirectTo(routes.debts.href());
		},
		saveSettings() {
			return redirectTo(routes.settings.href());
		},
		signOut() {
			return redirectTo(routes.home.href());
		},
	},
});
