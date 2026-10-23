import { AppLayout } from "../components/Layout.tsx";
import { view } from "../components/view.ts";
import type { State } from "../lib/data.ts";

/** Placeholder for the pad tab. Nothing to show yet. */
export const PadScreen = view<{ s: State }>(({ s }) => <AppLayout title="Pad" theme={s.user.theme} mobileTab="pad" desktopTab="pad" mobile={null} desktop={null} />);
