import type { RemixNode } from "remix/component";
import type { State } from "../lib/data.ts";
import { dayLabel, dayOf, hhmm } from "../lib/time.ts";
import { Icon } from "./Icon.tsx";
import { Back, Empty, Section } from "./ui.tsx";
import { view } from "./view.ts";

/**
 * The note-to-yourself chat. `listKey` tells the browser script which list/composer pair belongs
 * together: "m" on phones, "d" on the notes page, "dash" on the dashboard card.
 */
export const NoteList = view<{ s: State; listKey: string }>(({ s, listKey }) => {
	if (listKey === "dash") {
		const latest = s.notes.slice(-2).reverse();
		return (
			<div data-list="dash">
				{latest.length ? (
					latest.map((n) => (
						<div key={n.id} class="rw">
							<span>{n.body}</span>
							<span class="lb">{hhmm(n.at)}</span>
						</div>
					))
				) : (
					<Empty>No notes yet.</Empty>
				)}
			</div>
		);
	}

	const items: RemixNode[] = [];
	let last = "";
	for (const n of s.notes) {
		const label = dayLabel(dayOf(n.at));
		if (label !== last) {
			items.push(
				<div key={`day-${n.id}`} class="day">
					<span>{label}</span>
				</div>,
			);
			last = label;
		}
		items.push(
			<div key={n.id} class="msg" data-id={n.id}>
				<div class="bub">{n.body}</div>
				<div class="meta">
					{n.edited ? "edited · " : ""}
					{hhmm(n.at)}
				</div>
				<div class="acts" hidden>
					<button type="button" class="btn xs o" data-act="copy">
						Copy
					</button>
					<button type="button" class="btn xs o" data-act="edit">
						Edit
					</button>
					<form method="post" action="/notes/delete" style={{ display: "contents" }} data-confirm="Delete this note?">
						<Back s={s} />
						<input type="hidden" name="id" value={n.id} />
						<button class="btn xs dng">Delete</button>
					</form>
				</div>
			</div>,
		);
	}
	return <div data-list={listKey}>{items}</div>;
});

export const ChatHead = view(() => (
	<div class="ch">
		<div class="av s">S</div>
		<div>
			<b>Message yourself</b>
			<div class="lb">only you can see this</div>
		</div>
	</div>
));

/** Message box. Editing a note re-uses it (the script fills the hidden id). */
export const Composer = view<{ s: State; listKey: string }>(({ s, listKey }) => (
	<form class="cm" data-comp={listKey} method="post" action="/notes">
		<Back s={s} />
		<input type="hidden" name="id" data-eid />
		<div class="eb" hidden>
			<span>
				<b>Editing</b> message
			</span>
			<button type="button" data-cancel>
				✕
			</button>
		</div>
		<div class="cin">
			<textarea rows="1" name="text" placeholder="Message yourself"></textarea>
			<button class="send" aria-label="Send">
				<Icon name="send" />
			</button>
		</div>
	</form>
));

/** Desktop dashboard card: quick composer plus the two latest notes. */
export const NoteCard = view<{ s: State }>(({ s }) => (
	<Section title="Note to yourself" right={`${s.notes.length} saved`}>
		<form class="cin" data-comp="dash" method="post" action="/notes" style={{ margin: "14px 0" }}>
			<Back s={s} />
			<input type="hidden" name="id" data-eid />
			<textarea rows="1" name="text" placeholder="Message yourself"></textarea>
			<button class="send" aria-label="Send">
				<Icon name="send" />
			</button>
		</form>
		<NoteList s={s} listKey="dash" />
	</Section>
));
