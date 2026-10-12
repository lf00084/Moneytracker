import { get, post, route } from "remix/routes";

export const routes = route({
	home: get("/"),
	login: get("/login"),
	loginSubmit: post("/login"),
	signup: get("/signup"),
	signupSubmit: post("/signup"),
	logout: post("/logout"),
	googleStart: get("/auth/google"),
	googleCallback: get("/auth/google/callback"),
});
