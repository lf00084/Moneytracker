import { css, type Handle } from "remix/component";

import { CURRENCY, user } from "../data/sample.ts";
import { routes } from "../routes.ts";
import { Section, SectionHead, SubmitButton } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

const themes = [
	{ value: "system", label: "System" },
	{ value: "dark", label: "Dark" },
	{ value: "light", label: "Light" },
];

/** Account details, a few preferences, and sign out. */
export function SettingsPage(handle: Handle) {
	return () => (
		<Screen title="Settings" active="settings" heading="Settings">
			<Section>
				<SectionHead title="Account" />
				<div>
					<div mix={css({ ...s.row, ...s.hair })}>
						<span mix={css({ ...s.small })}>Name</span>
						<span>{user.name}</span>
					</div>
					<div mix={css({ ...s.row, ...s.hair })}>
						<span mix={css({ ...s.small })}>Email</span>
						<span>{user.email}</span>
					</div>
				</div>
			</Section>

			<form
				method="post"
				action={routes.saveSettings.href()}
				mix={css({ display: "flex", flexDirection: "column", gap: "24px" })}
			>
				<Section>
					<SectionHead title="Preferences" />
					<label mix={css({ display: "flex", flexDirection: "column", gap: "4px" })}>
						<span mix={css({ ...s.small })}>Currency</span>
						<select name="currency">
							<option value="MAD" selected>
								{CURRENCY}
							</option>
							<option value="EUR">EUR</option>
							<option value="USD">USD</option>
						</select>
					</label>

					<div mix={css({ display: "flex", flexDirection: "column", gap: "4px" })}>
						<span mix={css({ ...s.small })}>Theme</span>
						<div mix={css({ display: "flex", gap: "8px" })}>
							{themes.map((theme) => (
								<label key={theme.value} data-chip="">
									<input type="radio" name="theme" value={theme.value} checked={theme.value === "system"} />
									<span mix={css({ ...s.chip })}>{theme.label}</span>
								</label>
							))}
						</div>
					</div>

					<label mix={css({ ...s.row, ...s.hair, marginTop: "8px" })}>
						<div>
							<div>Daily reminder</div>
							<div mix={css({ ...s.small })}>A nudge in the evening to log what you earned and bought.</div>
						</div>
						<input type="checkbox" name="reminder" checked />
					</label>
				</Section>

				<div>
					<SubmitButton primary large>
						Save settings
					</SubmitButton>
				</div>
			</form>

			<Section>
				<SectionHead title="Session" />
				<form method="post" action={routes.signOut.href()}>
					<SubmitButton large>Sign out</SubmitButton>
				</form>
			</Section>
		</Screen>
	);
}
