import { get, route } from "remix/routes";

/** The app's route table. Add a pattern here, then map it in bootstrap/app.tsx. */
export default route({
	home: get("/"),
	about: get("/about"),
});
