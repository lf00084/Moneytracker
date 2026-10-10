import application from "./app";

export default {
	async fetch(request: Request) {
		let app = application();
		return await app.fetch(request);
	},
} satisfies ExportedHandler<Cloudflare.Env>;
