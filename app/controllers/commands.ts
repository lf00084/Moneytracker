import { createController } from "remix/router";
import { commands, errorOf, type Command, type CommandName } from "../commands.ts";
import { routes } from "../routes.ts";
import { backTo, fail, formOf, go, userOf, type Ctx } from "../utils/request.ts";

/** One form-post action per entry in the command table. */
const form = (name: CommandName) => async (ctx: Ctx) => {
	const c: Command = commands[name];
	const user = userOf(ctx);
	if (!user) return c.empty ? new Response(null, { status: 401 }) : go("/login");
	const f = formOf(ctx);
	const error = errorOf(await c.run(user, f));
	if (c.empty) return new Response(null, { status: 204 });
	const to = c.back === false ? c.to : backTo(f, c.to);
	return error ? fail(ctx, c.fail ?? to, error) : go(to);
};

export default createController(routes.commands, {
	actions: Object.fromEntries((Object.keys(commands) as CommandName[]).map((name) => [name, form(name)])) as never,
});
