import type { Env } from "./app";
import application from "./app";

export default {
  async fetch(request: Request, env: Env) {
    return await application(env).fetch(request);
  },
};
