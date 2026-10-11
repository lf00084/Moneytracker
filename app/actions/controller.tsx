import { createController } from "remix/router";

import { routes } from "../routes.ts";
import { getMessageLimit } from "../utils/message-limit.ts";

import { HomePage } from "./home.tsx";

export default createController(routes, {
	actions: {
		home({ render, url }) {
			const limit = getMessageLimit(url);
			return render(<HomePage limit={limit} />);
		},
		messages({ request, url }) {
			const limit = getMessageLimit(url);
			const encoder = new TextEncoder();

			const stream = new ReadableStream({
				start(controller) {
					let count = 0;

					const interval = setInterval(() => {
						try {
							count++;
							const text = `Message #${count} at ${new Date().toLocaleTimeString()}`;
							controller.enqueue(encoder.encode("event: message\n"));
							controller.enqueue(
								encoder.encode(`data: ${JSON.stringify({ count, message: text })}\n\n`),
							);

							if (limit && count >= limit) {
								clearInterval(interval);
								controller.close();
							}
						} catch (error) {
							console.error("Error enqueuing message:", error);
							clearInterval(interval);
						}
					}, 1000);

					request.signal.addEventListener("abort", () => {
						clearInterval(interval);
						try {
							controller.close();
						} catch {}
					});
				},
			});

			return new Response(stream, {
				headers: {
					"Content-Type": "text/event-stream",
					"Cache-Control": "no-cache",
				},
			});
		},
	},
});
