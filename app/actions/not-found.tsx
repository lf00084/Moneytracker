import { css, type Handle } from "remix/component";

import { routes } from "../routes.ts";
import { LinkButton } from "../ui/kit.tsx";
import { Screen } from "../ui/screen.tsx";
import * as s from "../ui/styles.ts";

/** Shown when a source id in the URL matches nothing. */
export function NotFoundPage(handle: Handle) {
	return () => (
		<Screen title="Not found" active="home" heading="Not found">
			<div mix={css({ ...s.small })}>That page does not exist. It may have been removed.</div>
			<div>
				<LinkButton href={routes.home.href()} primary>
					Back to home
				</LinkButton>
			</div>
		</Screen>
	);
}
