import { AppLayout } from "../components/Layout.tsx";
import { ChatHead, Composer, NoteList } from "../components/notes.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";

/** Message-yourself chat. On phones the composer is pinned above the bottom bar. */
export const NotesScreen = view<{ s: State }>(({ s }) => (
	<AppLayout
		title="Notes"
		theme={s.user.theme}
		mobileTab="notes"
		desktopTab="notes"
		mobile={
			<>
				<ChatHead />
				<NoteList s={s} listKey="m" />
			</>
		}
		dock={<Composer s={s} listKey="m" />}
		desktop={
			<div class="chat" data-x>
				<ChatHead />
				<NoteList s={s} listKey="d" />
				<div style={{ margin: "30px 0 0" }}>
					<Composer s={s} listKey="d" />
				</div>
			</div>
		}
	/>
));
