import type { Handle, RemixNode } from "remix/component";

import { ImportMap } from "remix/component/server";

import type { DocumentAssets as Assets } from "~/app/lib/assets";

import "~/resources/css/app.css";

/** Hands the renderer's looked-up assets to the layout through context. */
export function DocumentAssets(handle: Handle<{ value: Assets; children: RemixNode }, Assets>) {
	handle.context.set(handle.props.value);
	return () => handle.props.children;
}

namespace DocumentLayout {
	export interface Props {
		children: RemixNode;
		title: string;
		/** Set true only on pages that carry a client island; otherwise no script is linked. */
		hydrates?: boolean;
	}
}

export default function DocumentLayout(handle: Handle<DocumentLayout.Props>) {
	return () => {
		let { children, hydrates = false, title } = handle.props;
		let { script, stylesheets } = handle.context.get(DocumentAssets);

		return (
			<html lang="en">
				<head>
					<meta charSet="utf-8" data-rmx-key="charset" />
					<meta
						name="viewport"
						content="width=device-width, initial-scale=1"
						data-rmx-key="viewport"
					/>
					<title data-rmx-key="title">{title}</title>
					{stylesheets.map((href) => (
						<link key={href} rel="stylesheet" href={href} data-rmx-key={href} />
					))}
					{hydrates ? (
						<>
							<ImportMap value={script.importMap} />
							{script.preloads.map((href) => (
								<link key={href} rel="modulepreload" href={href} data-rmx-key={href} />
							))}
						</>
					) : null}
				</head>
				<body>
					<nav>
						<a href="/">Home</a>
						<a href="/about">About</a>
					</nav>
					<main>{children}</main>
					{hydrates ? <script type="module" src={script.href}></script> : null}
				</body>
			</html>
		);
	};
}
