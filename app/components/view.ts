import type { Handle, RemixNode } from "remix/component";

/**
 * Defines a server-rendered component from a plain render function.
 *
 * Remix components are a setup function that returns a render function. Most of this app's
 * components have no state of their own (the server loader already fetched everything), so
 * `view()` writes that shape once:
 *
 *   export const Logo = view<{ href: string }>(({ href }) => <a href={href}>moneytracker</a>);
 *
 * It is exactly equivalent to:
 *
 *   function Logo(handle: Handle<{ href: string }>) {
 *     return () => <a href={handle.props.href}>moneytracker</a>;
 *   }
 */
export function view<P extends Record<string, any> = {}>(render: (props: P) => RemixNode) {
	return function View(handle: Handle<P>) {
		return () => render(handle.props);
	};
}
