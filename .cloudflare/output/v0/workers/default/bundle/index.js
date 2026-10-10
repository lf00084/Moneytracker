import manifest from "./__pitlane_assets_manifest.js";
//#region node_modules/@remix-run/component/dist/runtime/typed-event-target.js
/**
* An `EventTarget` subclass with typed event maps.
*/
var TypedEventTarget = class extends EventTarget {};
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/component.js
/**
* Creates the internal runtime wrapper for a component instance.
*
* @param config Component runtime configuration.
* @returns Component runtime helpers used by the reconciler.
*/
function createComponent(config) {
	return new ComponentRuntime(config);
}
var ComponentRuntime = class {
	frame;
	#config;
	#connectedController;
	#contextValue;
	#handle;
	#props = {};
	#renderController;
	#renderFn;
	#removed = false;
	#phase = "idle";
	#updateQueue;
	#updateVNode;
	#updateDomParent;
	#scheduleUpdate = () => {
		let queue = this.#updateQueue;
		if (!queue) throw new Error("scheduleUpdate not implemented");
		let vnode = this.#updateVNode;
		let domParent = this.#updateDomParent;
		if (!vnode || !domParent) throw new Error("scheduleUpdate target not initialized");
		queue.enqueue(vnode, domParent);
	};
	#tasks = [];
	constructor(config) {
		this.#config = config;
		this.frame = config.frame;
		this.#handle = this.#createHandle();
	}
	render = (nextProps) => {
		if (this.#removed) {
			console.warn("render called after component was removed, potential application memory leak");
			return [null, []];
		}
		this.#abortRenderSignal();
		syncProps(this.#props, nextProps);
		let renderFn = this.#renderFn;
		if (renderFn === void 0) {
			let initialize = this.#config.type;
			let result;
			this.#phase = "setup";
			try {
				result = initialize(this.#handle);
			} finally {
				this.#phase = "idle";
			}
			if (!isRenderFn(result)) {
				let name = this.#config.type.name || "Anonymous";
				throw new Error(`${name} must return a render function, received ${typeof result}`);
			}
			renderFn = result;
			this.#renderFn = renderFn;
		}
		let element;
		this.#phase = "render";
		try {
			element = renderFn();
		} finally {
			this.#phase = "idle";
		}
		return [element, this.#dequeueTasks()];
	};
	remove = () => {
		if (this.#removed) return EMPTY_TASKS;
		this.#removed = true;
		this.#connectedController?.abort();
		this.#abortRenderSignal();
		if (this.#tasks.length === 0) return EMPTY_TASKS;
		return this.#dequeueTasks(sharedAbortedSignal ??= AbortSignal.abort());
	};
	setScheduleUpdate = (queue, vnode, domParent) => {
		this.#updateQueue = queue;
		this.#updateVNode = vnode;
		this.#updateDomParent = domParent;
	};
	getContextValue = () => this.#contextValue;
	isRemoved = () => this.#removed;
	#createHandle() {
		let component = this;
		return {
			id: this.#config.id,
			props: this.#props,
			update: () => {
				if (component.#removed) return Promise.resolve(AbortSignal.abort());
				let name = component.#config.type.name || "Anonymous";
				if (component.#phase === "setup") {
					console.warn(`Ignored handle.update() while ${name} is running its setup function. The initial render includes setup changes.`);
					return new Promise((resolve) => {
						this.#tasks.push((signal) => resolve(signal));
					});
				}
				if (component.#phase !== "idle") throw new Error(`Cannot call handle.update() while ${name} is running its ${component.#phase} function. Call it from an event handler or handle.queueTask() instead.`);
				if (component.#updateQueue === void 0) throw new Error(`Cannot call handle.update() before ${name}'s initial render commits. Call it from an event handler or handle.queueTask() instead.`);
				return new Promise((resolve) => {
					this.#tasks.push((signal) => resolve(signal));
					this.#scheduleUpdate();
				});
			},
			queueTask: (task) => {
				this.#tasks.push(task);
			},
			frame: this.#config.frame,
			frames: {
				get top() {
					return component.#config.getTopFrame?.() ?? component.#config.frame;
				},
				get(name) {
					return component.#config.getFrameByName(name);
				}
			},
			context: {
				set: (value) => {
					this.#contextValue = value;
				},
				get: (type) => isElementFunction$1(type) ? this.#config.getContext(type) : void 0
			},
			get signal() {
				return component.#config.signal ?? component.#connectedSignal();
			}
		};
	}
	#connectedSignal() {
		this.#connectedController ??= new AbortController();
		return this.#connectedController.signal;
	}
	#abortRenderSignal() {
		this.#renderController?.abort();
		this.#renderController = void 0;
	}
	#dequeueTasks(signal) {
		if (this.#tasks.length === 0) return EMPTY_TASKS;
		if (signal === void 0 && this.#tasks.some((task) => task.length >= 1)) this.#renderController ??= new AbortController();
		signal ??= this.#renderController?.signal;
		signal ??= sharedAbortedSignal ??= AbortSignal.abort();
		return this.#tasks.splice(0, this.#tasks.length).map((task) => () => task(signal));
	}
};
function isRenderFn(value) {
	return typeof value === "function";
}
function isElementFunction$1(value) {
	return typeof value === "function";
}
var EMPTY_TASKS = [];
var sharedAbortedSignal;
function syncProps(target, next) {
	for (let key in target) if (!(key in next)) delete target[key];
	for (let key in next) target[key] = next[key];
}
/**
* Built-in component used to render nested frame content.
*
* @param handle Component handle for the frame instance.
* @returns A placeholder render function handled by the reconciler.
*/
function Frame(handle) {
	return () => null;
}
/**
* Built-in component used to group children without adding a host element.
*
* @param handle Component handle for the fragment instance.
* @returns A placeholder render function handled by the reconciler.
*/
function Fragment(handle) {
	return () => null;
}
/**
* Creates a frame handle with default no-op implementations for testing and internal wiring.
*
* @param def Partial frame-handle implementation to merge with the defaults.
* @returns A frame handle object.
*/
function createFrameHandle(def) {
	return Object.assign(new TypedEventTarget(), {
		src: "/",
		replace: notImplemented("replace not implemented"),
		reload: notImplemented("reload not implemented")
	}, def);
}
function notImplemented(msg) {
	return () => {
		throw new Error(msg);
	};
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/client-entries.js
/**
* Type guard to check if a component is an entry component
*
* @param component The component to check
* @returns True if the component has entry metadata
*/
function isEntry(component) {
	return Boolean(component && typeof component === "function" && component.$entry === true);
}
//#endregion
//#region node_modules/@remix-run/component/dist/style/style.js
var CAMEL_TO_KEBAB_CACHE_LIMIT = 256;
var camelToKebabCache = /* @__PURE__ */ new Map();
function camelToKebab$1(str) {
	let cached = camelToKebabCache.get(str);
	if (cached === void 0) {
		cached = str.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`);
		if (camelToKebabCache.size >= CAMEL_TO_KEBAB_CACHE_LIMIT) {
			let oldest = camelToKebabCache.keys().next();
			if (!oldest.done) camelToKebabCache.delete(oldest.value);
		}
		camelToKebabCache.set(str, cached);
	}
	return cached;
}
var NUMERIC_CSS_PROPS = /* @__PURE__ */ new Set([
	"aspect-ratio",
	"z-index",
	"opacity",
	"flex-grow",
	"flex-shrink",
	"flex-order",
	"grid-area",
	"grid-row",
	"grid-column",
	"font-weight",
	"line-height",
	"order",
	"orphans",
	"widows",
	"zoom",
	"columns",
	"column-count"
]);
function normalizeCssValue(key, value) {
	if (value == null) return String(value);
	if (typeof value === "number" && value !== 0) {
		let cssKey = camelToKebab$1(key);
		if (!NUMERIC_CSS_PROPS.has(cssKey) && !cssKey.startsWith("--")) return `${value}px`;
	}
	return String(value);
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/svg-attributes.js
var XLINK_NS = "http://www.w3.org/1999/xlink";
var XML_NS = "http://www.w3.org/XML/1998/namespace";
var CANONICAL_CAMEL_SVG_ATTRS = /* @__PURE__ */ new Set([
	"accentHeight",
	"attributeName",
	"attributeType",
	"autoReverse",
	"baseFrequency",
	"baseProfile",
	"calcMode",
	"viewBox",
	"preserveAspectRatio",
	"externalResourcesRequired",
	"filterRes",
	"gradientUnits",
	"gradientTransform",
	"glyphRef",
	"kernelMatrix",
	"kernelUnitLength",
	"keyPoints",
	"keySplines",
	"keyTimes",
	"lengthAdjust",
	"limitingConeAngle",
	"markerHeight",
	"patternUnits",
	"patternContentUnits",
	"patternTransform",
	"markerWidth",
	"numOctaves",
	"pathLength",
	"pointsAtX",
	"pointsAtY",
	"pointsAtZ",
	"preserveAlpha",
	"clipPathUnits",
	"maskUnits",
	"maskContentUnits",
	"filterUnits",
	"primitiveUnits",
	"refX",
	"refY",
	"requiredExtensions",
	"requiredFeatures",
	"specularConstant",
	"specularExponent",
	"spreadMethod",
	"startOffset",
	"stdDeviation",
	"stitchTiles",
	"surfaceScale",
	"systemLanguage",
	"tableValues",
	"targetX",
	"targetY",
	"textLength",
	"viewTarget",
	"xChannelSelector",
	"yChannelSelector",
	"zoomAndPan",
	"edgeMode",
	"diffuseConstant",
	"markerUnits"
]);
var SVG_ATTR_ALIASES = /* @__PURE__ */ new Map();
for (let attr of CANONICAL_CAMEL_SVG_ATTRS) SVG_ATTR_ALIASES.set(camelToKebab(attr), attr);
var NAMESPACED_SVG_ALIASES = /* @__PURE__ */ new Map([
	["xlinkHref", {
		ns: XLINK_NS,
		attr: "xlink:href"
	}],
	["xlink:href", {
		ns: XLINK_NS,
		attr: "xlink:href"
	}],
	["xlink-href", {
		ns: XLINK_NS,
		attr: "xlink:href"
	}],
	["xlinkActuate", {
		ns: XLINK_NS,
		attr: "xlink:actuate"
	}],
	["xlink:actuate", {
		ns: XLINK_NS,
		attr: "xlink:actuate"
	}],
	["xlink-actuate", {
		ns: XLINK_NS,
		attr: "xlink:actuate"
	}],
	["xlinkArcrole", {
		ns: XLINK_NS,
		attr: "xlink:arcrole"
	}],
	["xlink:arcrole", {
		ns: XLINK_NS,
		attr: "xlink:arcrole"
	}],
	["xlink-arcrole", {
		ns: XLINK_NS,
		attr: "xlink:arcrole"
	}],
	["xlinkRole", {
		ns: XLINK_NS,
		attr: "xlink:role"
	}],
	["xlink:role", {
		ns: XLINK_NS,
		attr: "xlink:role"
	}],
	["xlink-role", {
		ns: XLINK_NS,
		attr: "xlink:role"
	}],
	["xlinkShow", {
		ns: XLINK_NS,
		attr: "xlink:show"
	}],
	["xlink:show", {
		ns: XLINK_NS,
		attr: "xlink:show"
	}],
	["xlink-show", {
		ns: XLINK_NS,
		attr: "xlink:show"
	}],
	["xlinkTitle", {
		ns: XLINK_NS,
		attr: "xlink:title"
	}],
	["xlink:title", {
		ns: XLINK_NS,
		attr: "xlink:title"
	}],
	["xlink-title", {
		ns: XLINK_NS,
		attr: "xlink:title"
	}],
	["xlinkType", {
		ns: XLINK_NS,
		attr: "xlink:type"
	}],
	["xlink:type", {
		ns: XLINK_NS,
		attr: "xlink:type"
	}],
	["xlink-type", {
		ns: XLINK_NS,
		attr: "xlink:type"
	}],
	["xmlBase", {
		ns: XML_NS,
		attr: "xml:base"
	}],
	["xml:base", {
		ns: XML_NS,
		attr: "xml:base"
	}],
	["xml-base", {
		ns: XML_NS,
		attr: "xml:base"
	}],
	["xmlLang", {
		ns: XML_NS,
		attr: "xml:lang"
	}],
	["xml:lang", {
		ns: XML_NS,
		attr: "xml:lang"
	}],
	["xml-lang", {
		ns: XML_NS,
		attr: "xml:lang"
	}],
	["xmlSpace", {
		ns: XML_NS,
		attr: "xml:space"
	}],
	["xml:space", {
		ns: XML_NS,
		attr: "xml:space"
	}],
	["xml-space", {
		ns: XML_NS,
		attr: "xml:space"
	}],
	["xmlnsXlink", { attr: "xmlns:xlink" }],
	["xmlns:xlink", { attr: "xmlns:xlink" }],
	["xmlns-xlink", { attr: "xmlns:xlink" }]
]);
function normalizeSvgAttributeName(name) {
	let alias = SVG_ATTR_ALIASES.get(name);
	if (alias) return alias;
	if (CANONICAL_CAMEL_SVG_ATTRS.has(name)) return name;
	return camelToKebab(name);
}
function normalizeSvgAttribute(name) {
	let namespaced = NAMESPACED_SVG_ALIASES.get(name);
	if (namespaced) return namespaced;
	return { attr: normalizeSvgAttributeName(name) };
}
function camelToKebab(input) {
	return input.replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/_/g, "-").toLowerCase();
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/core/attributes.js
var BOOLEANISH_STRING_ATTRIBUTES = /* @__PURE__ */ new Set([
	"autoReverse",
	"contenteditable",
	"draggable",
	"externalResourcesRequired",
	"focusable",
	"preserveAlpha",
	"spellcheck"
]);
var BLOCKED_HOST_PROP_NAMES = /* @__PURE__ */ new Set(["__proto__", "outerHTML"]);
var INVALID_HOST_PROP_NAME_CHARACTER = /[\u0000\t\n\f\r "'/>=]/;
var EXECUTABLE_URL_ATTRIBUTES = /* @__PURE__ */ new Set([
	"href",
	"src",
	"action",
	"formaction",
	"xlink:href"
]);
var JAVASCRIPT_PROTOCOL = /^[\u0000-\u001F ]*j[\r\n\t]*a[\r\n\t]*v[\r\n\t]*a[\r\n\t]*s[\r\n\t]*c[\r\n\t]*r[\r\n\t]*i[\r\n\t]*p[\r\n\t]*t[\r\n\t]*:/i;
var BLOCKED_JAVASCRIPT_URL = "javascript:throw new Error('Remix has blocked a javascript: URL as a security precaution.')";
var FRAMEWORK_PROPS = /* @__PURE__ */ new Set([
	"children",
	"mix",
	"key",
	"animate",
	"innerHTML",
	"on"
]);
var SELF_CLOSING_TAGS = /* @__PURE__ */ new Set([
	"area",
	"base",
	"br",
	"col",
	"embed",
	"hr",
	"img",
	"input",
	"link",
	"meta",
	"param",
	"source",
	"track",
	"wbr"
]);
function isAllowedHostPropName(name) {
	if (name.length === 0 || INVALID_HOST_PROP_NAME_CHARACTER.test(name)) return false;
	return !name.toLowerCase().startsWith("on") && !BLOCKED_HOST_PROP_NAMES.has(name);
}
function sanitizeUrlAttribute(tagName, attrName, value) {
	if (!(EXECUTABLE_URL_ATTRIBUTES.has(attrName) || attrName === "data" && tagName.toLowerCase() === "object")) return value;
	return JAVASCRIPT_PROTOCOL.test(String(value)) ? BLOCKED_JAVASCRIPT_URL : value;
}
var NORMALIZATION_CACHE_LIMIT = 256;
var htmlAttributeNameCache = /* @__PURE__ */ new Map();
var svgAttributeNameCache = /* @__PURE__ */ new Map();
function normalizeAttributeName(name, isSvg) {
	let cache = isSvg ? svgAttributeNameCache : htmlAttributeNameCache;
	let cached = cache.get(name);
	if (cached === void 0) {
		cached = computeAttributeName(name, isSvg);
		if (cache.size >= NORMALIZATION_CACHE_LIMIT) {
			let oldest = cache.keys().next();
			if (!oldest.done) cache.delete(oldest.value);
		}
		cache.set(name, cached);
	}
	return cached;
}
function computeAttributeName(name, isSvg) {
	if (name.startsWith("aria-") || name.startsWith("data-")) return { attr: name };
	if (name === "className") return { attr: "class" };
	if (!isSvg) {
		if (name === "htmlFor") return { attr: "for" };
		if (name === "tabIndex") return { attr: "tabindex" };
		if (name === "acceptCharset") return { attr: "accept-charset" };
		if (name === "httpEquiv") return { attr: "http-equiv" };
		return { attr: name.toLowerCase() };
	}
	return normalizeSvgAttribute(name);
}
function isBooleanishStringAttribute(name) {
	return BOOLEANISH_STRING_ATTRIBUTES.has(name);
}
function shouldStringifyBooleanAttribute(name) {
	return isBooleanishStringAttribute(name) || name === "value";
}
function serializeStyleObject(style) {
	let parts = [];
	for (let [key, value] of Object.entries(style)) {
		if (value == null) continue;
		if (typeof value === "boolean") continue;
		if (typeof value === "number" && !Number.isFinite(value)) continue;
		let cssKey = toKebabCase(key);
		let cssValue = Array.isArray(value) ? value.join(", ") : normalizeCssValue(key, value);
		parts.push(`${cssKey}: ${cssValue};`);
	}
	return parts.join(" ");
}
var kebabCaseCache = /* @__PURE__ */ new Map();
function toKebabCase(value) {
	let cached = kebabCaseCache.get(value);
	if (cached === void 0) {
		cached = value.replace(/[A-Z]/g, (match) => `-${match.toLowerCase()}`);
		if (kebabCaseCache.size >= NORMALIZATION_CACHE_LIMIT) {
			let oldest = kebabCaseCache.keys().next();
			if (!oldest.done) kebabCaseCache.delete(oldest.value);
		}
		kebabCaseCache.set(value, cached);
	}
	return cached;
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/stream-protocol.js
var FLUSH_MARKER_PATTERN = /<!--\s*rmx:flush\s+(document|fragment)\s*-->/g;
function appendFlushMarker(html, kind) {
	return `${html}<!-- rmx:flush ${kind} -->`;
}
function stripFlushMarkers(html) {
	FLUSH_MARKER_PATTERN.lastIndex = 0;
	return html.replace(FLUSH_MARKER_PATTERN, "");
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/core/mix.js
var MAX_MIX_DESCRIPTORS = 1024;
/**
* Composes an element's `mix` descriptors into its final props.
*
* @param hostType Host element tag name the mixins are composed for.
* @param props Original element props, including `mix`.
* @param runDescriptor Runs each mixin using the caller's state and error handling.
* @returns The composed props.
*/
function composeMixedProps(hostType, props, runDescriptor) {
	let descriptors = resolveMixDescriptors(props);
	let composedProps = withoutMix(props);
	let mixinProps = withoutMixinContentProps(composedProps);
	for (let index = 0; index < descriptors.length && index < MAX_MIX_DESCRIPTORS; index++) {
		let result = runDescriptor(descriptors[index], index, mixinProps);
		if (!result) continue;
		if (isMixinElementFunction(result)) continue;
		let returnedDescriptors = resolveReturnedMixDescriptors(result);
		if (returnedDescriptors) {
			for (let returned of returnedDescriptors) descriptors.push(returned);
			continue;
		}
		if (!isRemixElementResult(result)) {
			console.error(/* @__PURE__ */ new Error("mixins must return a remix element"));
			continue;
		}
		if ((typeof result.type === "string" ? result.type : isMixinElementFunction(result.type) ? result.type.__rmxMixinElementType : null) !== hostType) {
			console.error(/* @__PURE__ */ new Error("mixins must return an element with the same host type"));
			continue;
		}
		let nextProps = sanitizeReturnedMixinProps(result.props);
		for (let nested of resolveMixDescriptors(nextProps)) descriptors.push(nested);
		composedProps = {
			...composedProps,
			...withoutMix(nextProps)
		};
		mixinProps = withoutMixinContentProps(composedProps);
	}
	let nextMix = props.mix;
	return {
		...composedProps,
		...nextMix === void 0 ? {} : { mix: nextMix }
	};
}
function resolveMixDescriptors(props) {
	let mix = props.mix;
	if (!mix) return [];
	if (Array.isArray(mix)) {
		if (mix.length === 0) return [];
		return mix.filter(Boolean);
	}
	return [mix];
}
function withoutMix(props) {
	if (!("mix" in props)) return props;
	let output = { ...props };
	delete output.mix;
	return output;
}
function withoutMixinContentProps(props) {
	if (!hasMixinContentProps(props)) return props;
	let output = { ...props };
	delete output.children;
	delete output.innerHTML;
	delete output.srcDoc;
	delete output.srcdoc;
	delete output.outerHTML;
	return output;
}
function sanitizeReturnedMixinProps(props) {
	if (!hasMixinContentProps(props)) return props;
	console.error(/* @__PURE__ */ new Error("mixins must not return children or raw HTML props"));
	return withoutMixinContentProps(props);
}
function hasMixinContentProps(props) {
	return "children" in props || "innerHTML" in props || "srcDoc" in props || "srcdoc" in props || "outerHTML" in props;
}
function isMixinDescriptor(value) {
	if (!value || typeof value !== "object" || isRemixElementResult(value)) return false;
	let descriptor = value;
	return typeof descriptor.type === "function" && Array.isArray(descriptor.args);
}
function isMixinElementFunction(value) {
	if (typeof value !== "function") return false;
	return "__rmxMixinElementType" in value;
}
function isRemixElementResult(value) {
	if (!value || typeof value !== "object") return false;
	return value.$rmx === true;
}
function resolveReturnedMixDescriptors(value) {
	let descriptors = [];
	if (!collectReturnedMixDescriptors(value, descriptors)) return null;
	return descriptors;
}
function collectReturnedMixDescriptors(value, output) {
	if (!value) return true;
	if (Array.isArray(value)) {
		for (let item of value) if (!collectReturnedMixDescriptors(item, output)) return false;
		return true;
	}
	if (!isMixinDescriptor(value)) return false;
	output.push(value);
	return true;
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/invariant.js
/**
* Use this when framework code is incorrect, indicating an internal bug rather
* than application code error.
*
* @param assertion The value to check for truthiness
* @param message Optional message to include in the error
*/
function invariant(assertion, message) {
	let prefix = "Framework invariant";
	if (assertion) return;
	throw new Error(message ? `${prefix}: ${message}` : prefix);
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/unsafe-html.js
var UnsafeHTMLValue = class {
	#value;
	constructor(value) {
		this.#value = value;
	}
	static read(value) {
		return value.#value;
	}
};
/**
* Reads the string from a value created by {@link unsafeHTML}.
*
* @param value The value to inspect.
* @returns The raw HTML string, or `undefined` when the value is not an `UnsafeHTML` instance.
* @internal
*/
function readUnsafeHTML(value) {
	return value instanceof UnsafeHTMLValue ? UnsafeHTMLValue.read(value) : void 0;
}
/**
* Validates and unwraps every host prop that can cause the browser to parse raw HTML.
*
* @param props The authored host props to normalize.
* @returns Host props with opaque raw-HTML values replaced by their strings.
* @internal
*/
function normalizeUnsafeHTMLProps(props) {
	let innerHTML = readUnsafeHTML(props.innerHTML);
	invariant(props.innerHTML === void 0 || innerHTML !== void 0, "Invalid innerHTML prop");
	let srcDoc = readUnsafeHTML(props.srcDoc);
	invariant(props.srcDoc === void 0 || srcDoc !== void 0, "Invalid srcDoc prop");
	let srcdoc = readUnsafeHTML(props.srcdoc);
	invariant(props.srcdoc === void 0 || srcdoc !== void 0, "Invalid srcdoc prop");
	invariant(props.outerHTML === void 0, "Invalid outerHTML prop");
	if (innerHTML === void 0 && srcDoc === void 0 && srcdoc === void 0) return props;
	return {
		...props,
		...innerHTML === void 0 ? {} : { innerHTML },
		...srcDoc === void 0 ? {} : { srcDoc },
		...srcdoc === void 0 ? {} : { srcdoc }
	};
}
//#endregion
//#region node_modules/@remix-run/component/dist/server/stream.js
/**
* Creates a server renderer node record from an element type and props.
*
* Application components normally use JSX or `createElement` from `remix/component` instead.
*
* @param type Host tag, component, or fragment to render.
* @param props Props passed to the element.
* @param key Optional reconciliation key.
* @returns A node record used by the server renderer.
*/
function createVNode(type, props, key) {
	return {
		type,
		props,
		key
	};
}
/**
* Renders the document import map and merges maps from server-resolved client entries.
*
* @param handle Server component handle containing the initial import map and script attributes.
* @returns This component is handled directly by the server renderer.
*/
function ImportMap(handle) {
	return () => null;
}
var TEXTAREA_VALUE_PROPS = /* @__PURE__ */ new Set(["value", "defaultValue"]);
var INPUT_DEFAULT_PROPS = /* @__PURE__ */ new Set(["defaultValue", "defaultChecked"]);
var DOCTYPE_PATTERN = /<!doctype(?:\s[^>]*)?>/gi;
function stripDoctypeMarkup(html) {
	return html.replace(DOCTYPE_PATTERN, "");
}
function hasRenderableHtml(html) {
	return stripDoctypeMarkup(html).trim() !== "";
}
function emptyReadableStream() {
	return new ReadableStream({ start(controller) {
		controller.close();
	} });
}
function getStyleLayerName(selector, layer = "rmx") {
	return `${layer}.${selector}`;
}
var SSR_OMITTED_PROPS = FRAMEWORK_PROPS;
var ssrSignal = Object.freeze({
	get aborted() {
		return false;
	},
	get reason() {},
	get onabort() {
		return null;
	},
	set onabort(_) {},
	addEventListener(_type, _listener, _options) {},
	removeEventListener(_type, _listener, _options) {},
	dispatchEvent(_event) {
		return true;
	},
	throwIfAborted() {}
});
/**
* Renders a node tree to a streaming HTML response body.
*
* @param node Node tree to render.
* @param options Stream rendering options.
* @returns A readable byte stream of HTML.
*/
function renderToStream(node, options) {
	let encoder = new TextEncoder();
	let onError = options?.onError ?? ((error) => console.error(error));
	let currentFrameSrc = normalizeFrameSrc(options?.frameSrc ?? options?.topFrameSrc);
	let rootFrameState = createSsrFrameState(currentFrameSrc, normalizeFrameSrc(options?.topFrameSrc ?? currentFrameSrc));
	let renderAbortController = new AbortController();
	let context = {
		insideSvg: false,
		insideHead: false,
		onError,
		resolveFrame: options?.resolveFrame ?? defaultResolveFrame,
		styleCache: /* @__PURE__ */ new Map(),
		pendingFrames: [],
		hydrationData: /* @__PURE__ */ new Map(),
		unresolvedHydrationData: /* @__PURE__ */ new Map(),
		authoredImportMapImports: /* @__PURE__ */ new Map(),
		authoredImportMapScopes: /* @__PURE__ */ new Map(),
		authoredImportMapIntegrity: /* @__PURE__ */ new Map(),
		managedImportMaps: [],
		frameData: /* @__PURE__ */ new Map(),
		clientEntryHeadResources: { modulePreloadTags: /* @__PURE__ */ new Set() },
		blockingFrameTails: [],
		signal: renderAbortController.signal,
		flushKind: "fragment",
		serverIdScope: crypto.randomUUID().slice(0, 8),
		serverIdCounter: 0
	};
	function cancel(reason) {
		if (!renderAbortController.signal.aborted) renderAbortController.abort(reason);
	}
	let signal = options?.signal;
	if (signal?.aborted) cancel(signal.reason);
	else signal?.addEventListener("abort", () => cancel(signal.reason), { once: true });
	return new ReadableStream({
		async start(controller) {
			try {
				let root = buildSegment(node, context, rootFrameState);
				await resolveBlocking(root);
				if (closeIfCancelled(controller, context)) return;
				await resolveClientEntries(context, options?.resolveClientEntry);
				if (closeIfCancelled(controller, context)) return;
				validateClientEntriesForHydration(context);
				finalizeManagedImportMap(context);
				let finalHtml = finalizeHtml(serializeSegment(root), context);
				let bytes = encoder.encode(appendFlushMarker(finalHtml, context.flushKind));
				if (closeIfCancelled(controller, context)) return;
				controller.enqueue(bytes);
				let tailPromise = context.blockingFrameTails.length > 0 ? streamByteStreams(context.blockingFrameTails, controller, context) : Promise.resolve();
				let pendingPromise = context.pendingFrames.length > 0 ? streamPendingFrames(context, controller, encoder) : Promise.resolve();
				await Promise.all([tailPromise, pendingPromise]);
				if (closeIfCancelled(controller, context)) return;
				controller.close();
			} catch (error) {
				if (isSignalAbortError(context.signal, error)) {
					closeStream(controller);
					return;
				}
				onError(error);
				controller.error(error);
			}
		},
		cancel(reason) {
			cancel(reason);
		}
	});
}
function isSignalAbortError(signal, error) {
	return signal.aborted && error === signal.reason;
}
function closeIfCancelled(controller, context) {
	if (!context.signal.aborted) return false;
	closeStream(controller);
	return true;
}
function closeStream(controller) {
	try {
		controller.close();
	} catch {}
}
function defaultResolveFrame() {
	throw new Error("No resolveFrame provided");
}
function normalizeFrameSrc(value) {
	return value == null ? "" : String(value);
}
function createSsrFrameState(frameSrc, topFrameSrc = frameSrc) {
	let topFrame = createFrameHandle({ src: topFrameSrc });
	return {
		frame: frameSrc === topFrameSrc ? topFrame : createFrameHandle({ src: frameSrc }),
		topFrame
	};
}
function getResolveFrameContext(frameState) {
	return {
		currentFrameSrc: frameState.frame.src,
		topFrameSrc: frameState.topFrame.src
	};
}
function randomId(prefix) {
	return prefix + crypto.randomUUID().slice(0, 8);
}
function createServerComponentId(context) {
	context.serverIdCounter++;
	return `s${context.serverIdScope}-${context.serverIdCounter}`;
}
async function splitFirstChunk(stream) {
	let reader = stream.getReader();
	let decoder = new TextDecoder();
	let first;
	while (true) {
		let { value, done } = await reader.read();
		if (done || !value) break;
		if (hasRenderableHtml(decoder.decode(value, { stream: true }))) {
			first = value;
			break;
		}
	}
	if (!first) {
		decoder.decode();
		reader.releaseLock();
		return {
			html: "",
			tail: emptyReadableStream()
		};
	}
	let released = false;
	function release() {
		if (released) return;
		released = true;
		try {
			reader.releaseLock();
		} catch {}
	}
	let tail = new ReadableStream({
		async pull(controller) {
			let next = await reader.read();
			if (next.done) {
				controller.close();
				release();
				return;
			}
			controller.enqueue(next.value);
		},
		cancel(reason) {
			release();
			return reader.cancel(reason);
		}
	});
	return {
		html: stripFlushMarkers(stripDoctypeMarkup(decoder.decode(first))),
		tail
	};
}
async function resolveFrameHtml(input) {
	if (typeof input === "string") return { html: stripFlushMarkers(stripDoctypeMarkup(input)) };
	return splitFirstChunk(input);
}
function isRemixElement(node) {
	return typeof node === "object" && node !== null && "$rmx" in node;
}
function staticSeg(html) {
	return {
		kind: "static",
		html
	};
}
function compositeSeg(parts) {
	return {
		kind: "composite",
		parts
	};
}
function buildSegment(node, context, frameState) {
	if (typeof node === "string" || typeof node === "number" || typeof node === "bigint") return staticSeg(escapeTextContent(String(node)));
	if (node === null || node === void 0 || typeof node === "boolean") return staticSeg("");
	if (Array.isArray(node)) return compositeSeg(node.map((child) => buildSegment(child, context, frameState)));
	if (isRemixElement(node)) {
		let type = node.type;
		let props = node.props;
		if (type === Fragment) {
			let children = props.children;
			return children != null ? buildSegment(children, context, frameState) : staticSeg("");
		}
		if (typeof type === "string") {
			let tag = type;
			if (tag === "html") {
				context.flushKind = "document";
				return buildElementSegment(tag, props, context, frameState);
			}
			if (tag === "head") return buildHeadElementSegment(tag, props, context, frameState);
			return buildElementSegment(tag, props, context, frameState);
		}
		if (isElementFunction(type)) {
			if (type === ImportMap) return buildImportMapSegment(props, context);
			if (type === Frame) return buildFrameSegment(node, context, frameState);
			if (isEntry(type)) return buildEntrySegment(type, props, context, frameState);
			return buildComponentSegment(type, props, context, createServerComponentId(context), frameState);
		}
	}
	return staticSeg("");
}
function buildFrameSegment(node, context, frameState) {
	let props = node.props;
	let frameId = randomId("f");
	context.frameData.set(frameId, {
		status: props.fallback ? "pending" : "resolved",
		name: props.name,
		src: props.src
	});
	let seg = {
		kind: "frame",
		frameId,
		content: null
	};
	let resolveFrameContext = getResolveFrameContext(frameState);
	if (!!props.fallback) {
		seg.content = buildSegment(props.fallback, context, frameState);
		let framePromise = Promise.resolve(context.resolveFrame(props.src, props.name, resolveFrameContext)).then(async (resolved) => resolveFrameHtml(resolved));
		framePromise.catch(() => {});
		context.pendingFrames.push({
			frameId,
			promise: framePromise
		});
	} else {
		let framePromise = Promise.resolve(context.resolveFrame(props.src, props.name, resolveFrameContext)).then(async (resolved) => {
			let { html, tail } = await resolveFrameHtml(resolved);
			html = hoistClientEntryResourcesFromFrameHead(html, context.clientEntryHeadResources);
			seg.content = staticSeg(html);
			if (tail) context.blockingFrameTails.push(tail);
		});
		framePromise.catch(() => {});
		seg.pending = framePromise;
	}
	return seg;
}
function buildElementSegment(tag, props, context, frameState) {
	let normalizedProps = normalizeUnsafeHTMLProps(props);
	let innerHTML = normalizedProps.innerHTML;
	let processedProps = processStyleProps(resolveSsrMixedProps(tag, normalizedProps, context, frameState));
	let currentIsSvg = context.insideSvg || tag === "svg";
	if (!currentIsSvg && tag === "textarea") return buildTextareaElementSegment(tag, processedProps);
	let attrs = !currentIsSvg && tag === "input" ? renderInputAttributes(processedProps) : renderAttributes(tag, processedProps, currentIsSvg);
	if (SELF_CLOSING_TAGS.has(tag)) return staticSeg(`<${tag}${attrs} />`);
	if (innerHTML !== void 0) return staticSeg(`<${tag}${attrs}>${innerHTML}</${tag}>`);
	if (tag === "script") {
		if (typeof props.children === "string") {
			if (context.insideHead) collectAuthoredImportMap(context, tag, processedProps, props.children);
			return staticSeg(`<${tag}${attrs}>${escapeScriptTextContent(props.children)}</${tag}>`);
		}
		if (props.children != null) console.error(/* @__PURE__ */ new Error("script elements with children must have a single string child"));
		return staticSeg(`<${tag}${attrs}></${tag}>`);
	}
	let open = staticSeg(`<${tag}${attrs}>`);
	let previousInsideSvg = context.insideSvg;
	context.insideSvg = tag === "foreignObject" ? false : currentIsSvg;
	let children = props.children != null ? buildSegment(props.children, context, frameState) : staticSeg("");
	context.insideSvg = previousInsideSvg;
	return compositeSeg([
		open,
		children,
		staticSeg(`</${tag}>`)
	]);
}
function buildTextareaElementSegment(tag, props) {
	let attrs = renderAttributes(tag, props, false, TEXTAREA_VALUE_PROPS);
	let value = props.value ?? props.defaultValue ?? "";
	return staticSeg(`<${tag}${attrs}>${escapeTextContent(String(value))}</${tag}>`);
}
function collectAuthoredImportMap(context, tag, props, children) {
	if (tag !== "script" || typeof props.type !== "string" || props.type.toLowerCase() !== "importmap" || props.src !== void 0 && props.src !== null && props.src !== false || typeof children !== "string") return;
	let importMap = parseAuthoredImportMap(children);
	if (!importMap) return;
	if (importMap.imports) collectAuthoredImportMapEntries(context.authoredImportMapImports, importMap.imports);
	if (importMap.scopes) for (let [scope, imports] of Object.entries(importMap.scopes)) {
		let authoredScope = context.authoredImportMapScopes.get(scope);
		if (!authoredScope) {
			authoredScope = { imports: /* @__PURE__ */ new Map() };
			context.authoredImportMapScopes.set(scope, authoredScope);
		}
		collectAuthoredImportMapEntries(authoredScope.imports, imports);
	}
	if (importMap.integrity) {
		for (let [url, integrity] of Object.entries(importMap.integrity)) if (!context.authoredImportMapIntegrity.has(url)) context.authoredImportMapIntegrity.set(url, integrity);
	}
}
function collectAuthoredImportMapEntries(target, source) {
	for (let [specifier, address] of Object.entries(source)) if (!target.has(specifier)) target.set(specifier, address);
}
function buildImportMapSegment(props, context) {
	if (context.flushKind !== "document" || !context.insideHead) throw new Error("ImportMap must be rendered inside a document head");
	if (context.managedImportMaps.length > 0) throw new Error("Only one ImportMap can be rendered per document");
	let value = props.value;
	if (!isImportMap(value)) throw new TypeError("ImportMap value must be a valid import map");
	let { value: _value, ...scriptProps } = props;
	let attrs = renderAttributes("script", scriptProps, false);
	let segment = staticSeg("");
	context.managedImportMaps.push({
		attrs,
		segment,
		value
	});
	return segment;
}
function renderInputAttributes(props) {
	let value = props.value === void 0 && props.defaultValue !== void 0 ? props.defaultValue : props.value;
	let checked = props.checked === void 0 && props.defaultChecked !== void 0 ? props.defaultChecked : props.checked;
	return renderAttributes("input", {
		...props,
		...value === void 0 ? {} : { value },
		...checked === void 0 ? {} : { checked }
	}, false, INPUT_DEFAULT_PROPS);
}
function buildHeadElementSegment(tag, props, context, frameState) {
	let open = staticSeg(`<${tag}${renderAttributes(tag, processStyleProps(props), false)}>`);
	let previousInsideHead = context.insideHead;
	context.insideHead = true;
	let children = props.children != null ? buildSegment(props.children, context, frameState) : staticSeg("");
	context.insideHead = previousInsideHead;
	return compositeSeg([
		open,
		children,
		staticSeg(`</${tag}>`)
	]);
}
function renderAttributes(tag, props, isSvg, excludedProps) {
	let attrs = "";
	for (let key in props) {
		if (SSR_OMITTED_PROPS.has(key)) continue;
		if (excludedProps?.has(key)) continue;
		if (!isAllowedHostPropName(key)) continue;
		let value = props[key];
		let attrName = transformAttributeName(key, isSvg);
		let shouldStringifyBoolean = shouldStringifyBooleanAttribute(attrName);
		if (value === void 0 || value === null || value === false && !shouldStringifyBoolean) continue;
		value = sanitizeUrlAttribute(tag, attrName, value);
		if (typeof value === "boolean" && shouldStringifyBoolean) attrs += ` ${attrName}="${escapeHtml$1(String(value))}"`;
		else if (value === true) attrs += ` ${attrName}`;
		else attrs += ` ${attrName}="${escapeHtml$1(String(value))}"`;
	}
	return attrs;
}
function resolveSsrMixedProps(hostType, initialProps, context, frameState) {
	if (resolveMixDescriptors(initialProps).length === 0) return initialProps;
	return composeMixedProps(hostType, initialProps, (descriptor, _index, mixinProps) => {
		let runner = resolveSsrMixinRunner(hostType, descriptor, context, frameState);
		if (!runner) return void 0;
		try {
			return runner(...descriptor.args, mixinProps);
		} catch (error) {
			console.error(error);
			return;
		}
	});
}
function resolveSsrMixinRunner(hostType, descriptor, context, frameState) {
	if (typeof descriptor.type !== "function") return null;
	try {
		let handle = createSsrMixinHandle(hostType, descriptor, context, frameState);
		let runner = descriptor.type(handle, hostType);
		if (typeof runner !== "function") return null;
		return runner;
	} catch (error) {
		console.error(error);
		return null;
	}
}
function createSsrMixinHandle(hostType, _descriptor, context, frameState) {
	let element = ((handle) => () => ({
		$rmx: true,
		type: hostType,
		key: null,
		props: handle.props
	}));
	element.__rmxMixinElementType = hostType;
	return {
		id: "ssr-mixin",
		context: { get(providerType) {
			if (typeof providerType !== "function") return;
			let current = context.parentVNode;
			while (current) {
				if (current.type === providerType) {
					let providerHandle = current._handle;
					if (providerHandle) return providerHandle.getContextValue();
				}
				current = current._parent;
			}
		} },
		frame: createFrameHandle({
			src: frameState.frame.src,
			$runtime: { styleCache: context.styleCache }
		}),
		element,
		signal: ssrSignal,
		update: () => {
			throw new Error("handle.update() is not available during SSR.");
		},
		queueTask: () => {},
		on: () => {},
		addEventListener: () => {},
		removeEventListener: () => {},
		dispatchEvent: () => true
	};
}
function isElementFunction(value) {
	return typeof value === "function";
}
function buildComponentSegment(type, props, context, componentId, frameState) {
	let vnode = createVNode(type, props);
	if (context.parentVNode) vnode._parent = context.parentVNode;
	let handle = createComponent({
		id: componentId,
		type,
		frame: frameState.frame,
		signal: ssrSignal,
		getContext(providerType) {
			let current = vnode._parent;
			while (current) {
				if (current.type === providerType) {
					let providerHandle = current._handle;
					if (providerHandle) return providerHandle.getContextValue();
				}
				current = current._parent;
			}
		},
		getFrameByName() {},
		getTopFrame() {
			return frameState.topFrame;
		}
	});
	vnode._handle = handle;
	let [renderedNode] = handle.render(props);
	let childContext = {
		...context,
		parentVNode: vnode
	};
	let rendered = buildSegment(renderedNode, childContext, frameState);
	if (childContext.flushKind === "document") context.flushKind = "document";
	return rendered;
}
function createHydrationPropsReplacer(context, frameState) {
	function unwrapNode(node) {
		if (node === null || node === void 0 || typeof node === "boolean") return node;
		if (typeof node === "string" || typeof node === "number" || typeof node === "bigint") return node;
		if (Array.isArray(node)) return node.map((child) => unwrapNode(child));
		if (isRemixElement(node)) return unwrapElement(node);
		return node;
	}
	function unwrapElement(element) {
		let type = element.type;
		let props = element.props;
		if (type === Frame) return {
			$rmxFrame: true,
			props: transformProps(props),
			key: element.key
		};
		if (typeof type === "string") return {
			$rmx: true,
			type,
			props: transformProps(props)
		};
		if (isElementFunction(type)) {
			let vnode = createVNode(type, props);
			if (context.parentVNode) vnode._parent = context.parentVNode;
			let handle = createComponent({
				id: "SERIALIZED",
				type,
				frame: frameState.frame,
				signal: ssrSignal,
				getContext(providerType) {
					let current = vnode._parent;
					while (current) {
						if (current.type === providerType) {
							let providerHandle = current._handle;
							if (providerHandle) return providerHandle.getContextValue();
						}
						current = current._parent;
					}
				},
				getFrameByName() {},
				getTopFrame() {
					return frameState.topFrame;
				}
			});
			vnode._handle = handle;
			let [renderedNode] = handle.render(props);
			return unwrapNode(renderedNode);
		}
		return null;
	}
	function transformProps(input) {
		let out = {};
		for (let key in input) {
			let value = input[key];
			if (key === "children") out[key] = unwrapNode(value);
			else if (isRemixElement(value)) out[key] = unwrapNode(value);
			else if (Array.isArray(value)) out[key] = value.map((v) => unwrapNode(v));
			else out[key] = value;
		}
		return out;
	}
	return function replacer(_key, value) {
		if (isRemixElement(value)) return unwrapElement(value);
		if (Array.isArray(value)) return value.map((v) => unwrapNode(v));
		return value;
	};
}
function buildEntrySegment(type, props, context, frameState) {
	let instanceId = randomId("h");
	let rendered = buildComponentSegment(type, props, context, instanceId, frameState);
	let replacer = createHydrationPropsReplacer(context, frameState);
	context.unresolvedHydrationData.set(instanceId, {
		entryId: type.$entryId,
		component: type,
		props: JSON.parse(JSON.stringify(props, replacer))
	});
	return compositeSeg([
		staticSeg(`<!-- rmx:h:${instanceId} -->`),
		rendered,
		staticSeg("<!-- /rmx:h -->")
	]);
}
function resolveDefaultClientEntry(entryId, component) {
	let fallbackExportName = component.name || "";
	let hashIndex = entryId.lastIndexOf("#");
	if (hashIndex === -1 && fallbackExportName) return {
		exportName: fallbackExportName,
		href: entryId
	};
	if (hashIndex !== -1) {
		let exportName = entryId.slice(hashIndex + 1) || fallbackExportName;
		if (exportName) return {
			exportName,
			href: entryId.slice(0, hashIndex)
		};
	}
	throw new Error(`clientEntry() requires either an export name in the entry ID (e.g., "/js/module.js#ComponentName"), a named component function, or a resolveClientEntry hook that resolves one. Received "${entryId}".`);
}
async function resolveClientEntries(context, resolveClientEntry) {
	if (context.unresolvedHydrationData.size === 0) return;
	let resolvedEntries = /* @__PURE__ */ new Map();
	for (let [hydrationId, unresolvedHydrationData] of context.unresolvedHydrationData) {
		let { entryId, component, props } = unresolvedHydrationData;
		let resolvedEntry = resolvedEntries.get(component);
		if (!resolvedEntry) {
			resolvedEntry = resolveClientEntry ? await Promise.resolve(resolveClientEntry(entryId, component)) : resolveDefaultClientEntry(entryId, component);
			validateResolvedClientEntry(entryId, resolvedEntry);
			resolvedEntries.set(component, resolvedEntry);
			collectResolvedClientEntryResources(context.clientEntryHeadResources, resolvedEntry);
		}
		context.hydrationData.set(hydrationId, {
			exportName: resolvedEntry.exportName,
			moduleUrl: resolvedEntry.href,
			props
		});
	}
	context.unresolvedHydrationData.clear();
}
function collectResolvedClientEntryResources(resources, resolvedEntry) {
	for (let preload of resolvedEntry.preloads ?? []) resources.modulePreloadTags.add(createModulePreloadTag(preload));
	if (resolvedEntry.importMap) mergeImportMap(resources, resolvedEntry.importMap);
}
function validateResolvedClientEntry(entryId, resolvedEntry) {
	if (!resolvedEntry || typeof resolvedEntry !== "object") throw new Error(`resolveClientEntry must return an object with href and exportName. Received "${entryId}".`);
	if (!resolvedEntry.href) throw new Error(`resolveClientEntry must return a non-empty href. Received "${entryId}".`);
	if (!resolvedEntry.exportName) throw new Error(`resolveClientEntry must return a non-empty exportName. Received "${entryId}".`);
	if (resolvedEntry.preloads !== void 0) {
		if (!Array.isArray(resolvedEntry.preloads)) throw new Error(`resolveClientEntry preloads must be an array. Received "${entryId}".`);
		for (let preload of resolvedEntry.preloads) if (typeof preload !== "string" || preload.length === 0) throw new Error(`resolveClientEntry preloads must contain non-empty strings. Received "${entryId}".`);
	}
	if (resolvedEntry.importMap !== void 0 && !isImportMap(resolvedEntry.importMap)) throw new Error(`resolveClientEntry importMap must be a valid import map. Received "${entryId}".`);
}
function validateClientEntriesForHydration(context) {
	if (context.unresolvedHydrationData.size > 0) {
		let [hydrationId, unresolvedHydrationData] = context.unresolvedHydrationData.entries().next().value;
		throw new Error(`Client entry was not resolved for hydration. Received "${unresolvedHydrationData.entryId}" (${hydrationId}).`);
	}
}
async function resolveBlocking(segment) {
	if (segment.kind === "frame") {
		if (segment.pending) {
			await segment.pending;
			segment.pending = void 0;
		}
		if (segment.content) await resolveBlocking(segment.content);
		return;
	}
	if (segment.kind === "composite") for (let part of segment.parts) await resolveBlocking(part);
}
function serializeSegment(seg) {
	if (seg.kind === "static") return seg.html;
	if (seg.kind === "composite") return seg.parts.map(serializeSegment).join("");
	let inner = seg.content ? serializeSegment(seg.content) : "";
	return `<!-- rmx:f:${seg.frameId} -->` + inner + `<!-- /rmx:f -->`;
}
function escapeHtml$1(str) {
	return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}
function escapeTextContent(str) {
	return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
function escapeTemplateContent(html) {
	return html.replace(/<\/template/gi, "<\\/template");
}
var SCRIPT_TAG_PATTERN = /(<\/|<)(s)(cript)/gi;
function escapeScriptTextContent(value) {
	return value.replace(SCRIPT_TAG_PATTERN, (_match, prefix, firstLetter, suffix) => `${prefix}${firstLetter === "s" ? "\\u0073" : "\\u0053"}${suffix}`);
}
function transformAttributeName(name, isSvg) {
	return normalizeAttributeName(name, isSvg).attr;
}
function finalizeHtml(html, context) {
	let hasHtmlRoot = context.flushKind === "document";
	let preloads = collectModulePreloadTags(context.clientEntryHeadResources);
	let styles = collectStyleTags(context);
	let headContent = collectImportMapScript(context, context.clientEntryHeadResources) + preloads + styles;
	if (hasHtmlRoot && headContent) {
		let headCloseIndex = html.indexOf("</head>");
		if (headCloseIndex !== -1) html = html.slice(0, headCloseIndex) + headContent + html.slice(headCloseIndex);
		else {
			let htmlOpenMatch = html.match(/<html[^>]*>/);
			if (htmlOpenMatch) {
				let insertIndex = htmlOpenMatch.index + htmlOpenMatch[0].length;
				html = html.slice(0, insertIndex) + `<head>${headContent}</head>` + html.slice(insertIndex);
			} else html = headContent + html;
		}
	}
	if (!hasHtmlRoot && headContent) html = `<head>${headContent}</head>${html}`;
	let rmxData = buildRmxDataScript(context);
	if (rmxData) {
		if (hasHtmlRoot) {
			let bodyCloseIndex = html.indexOf("</body>");
			if (bodyCloseIndex !== -1) html = html.slice(0, bodyCloseIndex) + rmxData + html.slice(bodyCloseIndex);
			else {
				let htmlCloseIndex = html.indexOf("</html>");
				if (htmlCloseIndex !== -1) html = html.slice(0, htmlCloseIndex) + rmxData + html.slice(htmlCloseIndex);
				else html += rmxData;
			}
		} else html += rmxData;
	}
	return html;
}
var FRAME_HEAD_OPEN_TAG = "<head>";
var FRAME_HEAD_CLOSE_TAG = "</head>";
var MARKED_MODULE_PRELOAD_START = "<link data-rmx-module-preload rel=\"modulepreload\" href=\"";
var MODULE_PRELOAD_END = "\" />";
var MANAGED_IMPORT_MAP_START = "<script data-rmx-import-map type=\"importmap\">";
var IMPORT_MAP_SCRIPT_END = "<\/script>";
function createModulePreloadTag(href) {
	return `${MARKED_MODULE_PRELOAD_START}${escapeHtml$1(href)}${MODULE_PRELOAD_END}`;
}
function collectModulePreloadTags(resources) {
	return Array.from(resources.modulePreloadTags).join("");
}
function hoistClientEntryResourcesFromFrameHead(html, resources) {
	if (!html.startsWith(FRAME_HEAD_OPEN_TAG)) return html;
	let headClose = html.indexOf(FRAME_HEAD_CLOSE_TAG, 6);
	if (headClose === -1) return html;
	let preloadTags = [];
	let importMaps = [];
	let cursor = 6;
	if (html.startsWith(MANAGED_IMPORT_MAP_START, cursor)) {
		let contentStart = cursor + 45;
		let scriptEnd = html.indexOf(IMPORT_MAP_SCRIPT_END, contentStart);
		if (scriptEnd === -1 || scriptEnd >= headClose) return html;
		importMaps.push(parseFrameworkImportMap(html.slice(contentStart, scriptEnd)));
		cursor = scriptEnd + 9;
	}
	while (html.startsWith(MARKED_MODULE_PRELOAD_START, cursor)) {
		let tagEnd = html.indexOf(MODULE_PRELOAD_END, cursor + 56);
		if (tagEnd === -1 || tagEnd >= headClose) return html;
		tagEnd += 4;
		preloadTags.push(html.slice(cursor, tagEnd));
		cursor = tagEnd;
	}
	if (preloadTags.length === 0 && importMaps.length === 0) return html;
	for (let tag of preloadTags) resources.modulePreloadTags.add(tag);
	for (let importMap of importMaps) mergeImportMap(resources, importMap);
	let remainingHeadHtml = html.slice(cursor, headClose);
	let contentAfterHead = html.slice(headClose + 7);
	if (!remainingHeadHtml) return contentAfterHead;
	return `${FRAME_HEAD_OPEN_TAG}${remainingHeadHtml}${FRAME_HEAD_CLOSE_TAG}${contentAfterHead}`;
}
function processStyleProps(props) {
	let processedProps = { ...props };
	let mergedClassName = [typeof props.class === "string" ? props.class : "", typeof props.className === "string" ? props.className : ""].filter(Boolean).join(" ");
	if (mergedClassName) {
		processedProps.className = mergedClassName;
		delete processedProps.class;
	}
	if (typeof props.style === "object") processedProps.style = serializeStyleObject(props.style);
	return processedProps;
}
function collectStyleTags(context) {
	if (context.styleCache.size === 0) return "";
	let tags = [];
	for (let { selector, css } of context.styleCache.values()) {
		let tag = renderStyleTag(selector, css);
		if (tag) tags.push(tag);
	}
	return tags.join("");
}
function wrapStyleForLayer(selector, css, layer = "rmx") {
	let trimmed = css.trim();
	if (!trimmed) return "";
	return `@layer ${getStyleLayerName(selector, layer)} { ${trimmed} }`;
}
function renderStyleTag(selector, css, layer = "rmx") {
	let wrappedCss = wrapStyleForLayer(selector, css, layer);
	if (!wrappedCss) return "";
	return `<style data-rmx-style="${escapeHtml$1(selector)}">${escapeStyleText(wrappedCss)}</style>`;
}
function escapeStyleText(css) {
	return css.replace(/<\/style/gi, "\\3C/style");
}
function buildRmxDataScript(context) {
	if (context.hydrationData.size === 0 && context.frameData.size === 0) return "";
	let data = {};
	if (context.hydrationData.size > 0) data.h = Object.fromEntries(context.hydrationData);
	if (context.frameData.size > 0) data.f = Object.fromEntries(context.frameData);
	return `<script type="application/json" id="rmx-data">${escapeScriptJson(JSON.stringify(data))}<\/script>`;
}
function buildImportMapScript(importMap, attrs = "") {
	return `<script data-rmx-import-map type="importmap"${attrs}>${escapeScriptJson(JSON.stringify(importMap))}<\/script>`;
}
function collectImportMapScript(context, resources) {
	let importMap = getImportMapDelta(context, resources.importMap);
	return importMap ? buildImportMapScript(importMap) : "";
}
function finalizeManagedImportMap(context) {
	let managed = context.managedImportMaps[0];
	if (!managed) return;
	let resources = { modulePreloadTags: /* @__PURE__ */ new Set() };
	mergeImportMap(resources, managed.value);
	if (context.clientEntryHeadResources.importMap) mergeImportMap(resources, context.clientEntryHeadResources.importMap);
	managed.segment.html = buildImportMapScript(resources.importMap ?? {}, managed.attrs);
	context.clientEntryHeadResources.importMap = void 0;
}
function getImportMapDelta(context, importMap) {
	if (!importMap) return null;
	let imports = importMap.imports ? getImportMapImportsDelta(context.authoredImportMapImports, importMap.imports) : void 0;
	let scopes = {};
	for (let [scope, scopedImports] of Object.entries(importMap.scopes ?? {})) {
		let importsDelta = getImportMapImportsDelta(context.authoredImportMapScopes.get(scope)?.imports ?? /* @__PURE__ */ new Map(), scopedImports, scope);
		if (importsDelta) scopes[scope] = importsDelta;
	}
	let integrity = importMap.integrity ? getImportMapIntegrityDelta(context.authoredImportMapIntegrity, importMap.integrity) : void 0;
	if (!imports && Object.keys(scopes).length === 0 && !integrity) return null;
	return {
		...imports ? { imports } : null,
		...Object.keys(scopes).length > 0 ? { scopes } : null,
		...integrity ? { integrity } : null
	};
}
function getImportMapImportsDelta(authoredImports, discoveredImports, scope) {
	let delta = {};
	for (let [specifier, address] of Object.entries(discoveredImports)) {
		if (!authoredImports.has(specifier)) {
			delta[specifier] = address;
			continue;
		}
		let authoredAddress = authoredImports.get(specifier);
		if (authoredAddress === address) continue;
		let scopeDescription = scope ? ` in scope "${scope}"` : "";
		console.warn(`[remix] Ignoring conflicting import map entry for "${specifier}"${scopeDescription}: ${formatImportMapAddress(authoredAddress)} is already authored, but the discovered map points to ${formatImportMapAddress(address)}`);
	}
	return Object.keys(delta).length > 0 ? delta : void 0;
}
function getImportMapIntegrityDelta(authoredIntegrity, discoveredIntegrity) {
	let delta = {};
	for (let [url, integrity] of Object.entries(discoveredIntegrity)) {
		if (!authoredIntegrity.has(url)) {
			delta[url] = integrity;
			continue;
		}
		let authoredIntegrityValue = authoredIntegrity.get(url);
		if (authoredIntegrityValue === integrity) continue;
		console.warn(`[remix] Ignoring conflicting import map integrity entry for "${url}": "${authoredIntegrityValue}" is already authored, but the discovered map points to "${integrity}"`);
	}
	return Object.keys(delta).length > 0 ? delta : void 0;
}
function parseAuthoredImportMap(json) {
	let value;
	try {
		value = JSON.parse(json);
	} catch {
		return null;
	}
	if (!isObjectRecord(value)) return null;
	let importMap = {};
	if (value.imports !== void 0) {
		if (!isObjectRecord(value.imports)) return null;
		importMap.imports = parseAuthoredImportMapImports(value.imports);
	}
	if (value.scopes !== void 0) {
		if (!isObjectRecord(value.scopes)) return null;
		let scopes = [];
		for (let [scope, imports] of Object.entries(value.scopes)) {
			if (!isObjectRecord(imports)) continue;
			scopes.push([scope, parseAuthoredImportMapImports(imports)]);
		}
		importMap.scopes = Object.fromEntries(scopes);
	}
	if (value.integrity !== void 0) {
		if (!isObjectRecord(value.integrity)) return null;
		importMap.integrity = Object.fromEntries(Object.entries(value.integrity).filter((entry) => typeof entry[1] === "string"));
	}
	return importMap;
}
function parseAuthoredImportMapImports(value) {
	return Object.fromEntries(Object.entries(value).map(([specifier, address]) => [specifier, address === null || typeof address === "string" ? address : null]));
}
function parseFrameworkImportMap(json) {
	let value;
	try {
		value = JSON.parse(json);
	} catch {
		throw new Error("Invalid framework-owned import map in frame head");
	}
	if (!isImportMap(value)) throw new Error("Invalid framework-owned import map in frame head");
	return value;
}
function isImportMap(value) {
	if (!isObjectRecord(value)) return false;
	if (value.imports !== void 0 && !isImportMapImports(value.imports)) return false;
	if (value.scopes !== void 0) {
		if (!isObjectRecord(value.scopes)) return false;
		for (let imports of Object.values(value.scopes)) if (!isImportMapImports(imports)) return false;
	}
	if (value.integrity !== void 0 && !isImportMapIntegrity(value.integrity)) return false;
	return true;
}
function isImportMapImports(value) {
	if (!isObjectRecord(value)) return false;
	return Object.values(value).every((address) => address === null || typeof address === "string");
}
function isImportMapIntegrity(value) {
	if (!isObjectRecord(value)) return false;
	return Object.values(value).every((integrity) => typeof integrity === "string");
}
function isObjectRecord(value) {
	return value !== null && typeof value === "object" && !Array.isArray(value);
}
function mergeImportMap(resources, source) {
	let target = resources.importMap ??= {};
	if (source.imports) {
		target.imports ??= {};
		mergeImportMapImports(target.imports, source.imports);
	}
	if (source.scopes) {
		target.scopes ??= {};
		for (let [scope, imports] of Object.entries(source.scopes)) mergeImportMapImports(target.scopes[scope] ??= {}, imports, scope);
	}
	if (source.integrity) {
		target.integrity ??= {};
		mergeImportMapIntegrity(target.integrity, source.integrity);
	}
}
function mergeImportMapImports(target, source, scope) {
	for (let [specifier, address] of Object.entries(source)) {
		if (!Object.hasOwn(target, specifier)) {
			target[specifier] = address;
			continue;
		}
		if (target[specifier] !== address) {
			let scopeDescription = scope ? ` in scope "${scope}"` : "";
			throw new Error(`Conflicting framework import map entry for "${specifier}"${scopeDescription}`);
		}
	}
}
function mergeImportMapIntegrity(target, source) {
	for (let [url, integrity] of Object.entries(source)) {
		if (!Object.hasOwn(target, url)) {
			target[url] = integrity;
			continue;
		}
		if (target[url] !== integrity) throw new Error(`Conflicting framework import map integrity entry for "${url}"`);
	}
}
function escapeScriptJson(json) {
	return json.replace(/</g, "\\u003c");
}
function formatImportMapAddress(address) {
	return address === null ? "null" : `"${address}"`;
}
async function streamPendingFrames(context, controller, encoder) {
	let processedFrames = /* @__PURE__ */ new Set();
	while (true) {
		if (context.signal.aborted) break;
		let batch = context.pendingFrames.filter(({ frameId }) => !processedFrames.has(frameId));
		if (batch.length === 0) break;
		await Promise.all(batch.map(async ({ frameId, promise }) => {
			if (context.signal.aborted) return;
			processedFrames.add(frameId);
			try {
				let { html, tail } = await promise;
				if (context.signal.aborted) return;
				let templateHtml = `<template id="${frameId}">${escapeTemplateContent(html)}</template>`;
				if (context.signal.aborted) return;
				controller.enqueue(encoder.encode(templateHtml));
				if (tail) await streamByteStreams([tail], controller, context);
			} catch (error) {
				if (!isSignalAbortError(context.signal, error)) context.onError(error);
			}
		}));
	}
}
async function streamByteStreams(streams, controller, context) {
	await Promise.all(streams.map(async (stream) => {
		let reader = stream.getReader();
		try {
			while (true) {
				if (context.signal.aborted) break;
				let { done, value } = await reader.read();
				if (done) break;
				if (context.signal.aborted) break;
				controller.enqueue(value);
			}
		} catch (error) {
			if (!isSignalAbortError(context.signal, error)) context.onError(error);
		} finally {
			reader.releaseLock();
		}
	}));
}
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/request-context.js
function createContextKey(defaultValue) {
	return arguments.length === 0 ? {} : { defaultValue };
}
/**
* A context object that contains information about the current request. Every request
* handler or middleware in the lifecycle of a request receives the same context object.
*/
var RequestContext = class {
	/**
	* @param request The incoming request
	*/
	constructor(request) {
		this.method = request.method.toUpperCase();
		this.params = {};
		this.request = request;
		this.url = new URL(request.url);
	}
	#headers;
	/**
	* A mutable copy of the request headers.
	*/
	get headers() {
		return this.#headers ??= new Headers(this.request.headers);
	}
	set headers(headers) {
		this.#headers = headers;
	}
	/**
	* The request method. This may differ from `request.method` when using the `methodOverride`
	* middleware, which allows HTML forms to simulate RESTful API request methods like `PUT` and
	* `DELETE` using a hidden input field.
	*/
	method;
	/**
	* Params that were parsed from the URL.
	*/
	params;
	/**
	* The original request that was dispatched to the router.
	*
	* Note: Various properties of the original request may not be available or may have been
	* modified by middleware. For example, the request's body may already have been consumed by the
	* `formData` middleware (available as `context.get(FormData)`), or its method may have been
	* overridden by the `methodOverride` middleware (available as `context.method`). You should
	* default to using properties of the `context` object instead of the original request.
	* However, the original request is made available in case you need it for some edge case.
	*/
	request;
	#contextMap = /* @__PURE__ */ new Map();
	#contextProperties = /* @__PURE__ */ new Map();
	#contextPropertyKeys = /* @__PURE__ */ new Map();
	/**
	* Get a value from request context.
	*
	* @param key The key to read
	* @returns The value for the given key, or `undefined` if the value is not available
	*/
	get = (key) => {
		if (!this.#contextMap.has(key)) {
			let contextKey = key;
			if (!Object.hasOwn(contextKey, "defaultValue")) return;
			return contextKey.defaultValue;
		}
		return this.#contextMap.get(key);
	};
	/**
	* Check whether a value exists in request context.
	*
	* @param key The key to check
	* @returns `true` if a value has been set for the key
	*/
	has = (key) => this.#contextMap.has(key);
	/**
	* Set a value in request context.
	*
	* @param key The key to write
	* @param value The value to write
	* @param options Options for installing the value as a direct context property
	*/
	set = (key, value, options) => {
		if (options != null) this.#installContextProperty(key, options.property);
		this.#contextMap.set(key, value);
	};
	#installContextProperty(key, property) {
		if (typeof property !== "string") throw new Error("Context property name must be a string.");
		if (property.length === 0) throw new Error("Cannot install an empty context property name.");
		let formattedProperty = JSON.stringify(property);
		let existingProperty = this.#contextPropertyKeys.get(key);
		if (existingProperty != null && existingProperty !== property) throw new Error(`Cannot install context property ${formattedProperty} because this context key already uses ${JSON.stringify(existingProperty)}.`);
		let existingKey = this.#contextProperties.get(property);
		if (existingKey != null) {
			if (existingKey !== key) throw new Error(`Cannot install context property ${formattedProperty} because another context key already uses it.`);
			return;
		}
		if (property in this) throw new Error(`Cannot install context property ${formattedProperty} because it already exists on RequestContext.`);
		this.#contextProperties.set(property, key);
		this.#contextPropertyKeys.set(key, property);
		Object.defineProperty(this, property, { get: () => this.get(key) });
	}
	#router;
	/**
	* The router handling this request.
	*/
	get router() {
		if (this.#router == null) throw new Error("No router found in request context.");
		return this.#router;
	}
	set router(router) {
		this.#router = router;
	}
	/**
	* The URL of the current request.
	*/
	url;
};
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/controller.js
function isRequestHandler(object) {
	return typeof object === "function";
}
/**
* Defines a route handler with route-aware params and the default router context.
*
* This helper returns the action unchanged while giving TypeScript the route pattern it needs to
* type `context.params`. If action middleware adds context values, those values are available to
* the action handler.
*
* @param route The route pattern or route object this action handles.
* @param action The handler function or action object to type-check.
* @returns The same action value.
*/
function createAction(route, action) {
	return action;
}
function isActionObject(obj) {
	return isRecord(obj) && typeof obj.handler === "function";
}
function isController(obj) {
	return isRecord(obj) && isRecord(obj.actions);
}
function isRecord(obj) {
	return typeof obj === "object" && obj != null && !Array.isArray(obj);
}
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/request-abort.js
function raceRequestAbort(promise, request) {
	let signal = request.signal;
	if (signal.aborted) throw signal.reason;
	return new Promise((resolve, reject) => {
		let onAbort = () => reject(signal.reason);
		signal.addEventListener("abort", onAbort, { once: true });
		promise.then((value) => {
			signal.removeEventListener("abort", onAbort);
			resolve(value);
		}, (error) => {
			signal.removeEventListener("abort", onAbort);
			reject(error);
		});
	});
}
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/middleware.js
function runMiddleware(middleware, context, handler) {
	let index = -1;
	let dispatch = async (i) => {
		if (i <= index) throw new Error("next() called multiple times");
		index = i;
		if (context.request.signal.aborted) throw context.request.signal.reason;
		let fn = middleware[i];
		if (!fn) return await raceRequestAbort(Promise.resolve(handler(context)), context.request);
		let nextPromise;
		let next = () => {
			nextPromise = dispatch(i + 1);
			return nextPromise;
		};
		let response = await raceRequestAbort(Promise.resolve(fn(context, next)), context.request);
		if (response instanceof Response) return response;
		if (nextPromise != null) return nextPromise;
		throw new Error("Middleware must return a Response or call next()");
	};
	return dispatch(0);
}
/**
* All HTTP request methods that are supported by the router.
*/
var RequestMethods = [
	"GET",
	"HEAD",
	...[
		"POST",
		"PUT",
		"PATCH",
		"DELETE",
		"OPTIONS"
	]
];
new Set(RequestMethods);
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/route-pattern/split.js
/**
* Split a route pattern into protocol, hostname, port, pathname, and search
* spans delimited as `protocol://hostname:port/pathname?search`.
*
* Delimiters are not included in the spans with the exception of the leading `/` for pathname.
* Spans are [begin (inclusive), end (exclusive)].
*
* @param source the route pattern string to split
* @returns an object containing spans for each URL component
*/
function split(source) {
	let result = {
		protocol: null,
		hostname: null,
		port: null,
		pathname: null,
		search: null
	};
	let questionMarkIndex = source.indexOf("?");
	if (questionMarkIndex !== -1) {
		result.search = span(questionMarkIndex + 1, source.length);
		source = source.slice(0, questionMarkIndex);
	}
	let solidusIndex = source.indexOf("://");
	if (solidusIndex === -1) {
		result.pathname = pathnameSpan(source, 0, source.length);
		return result;
	}
	let slashIndex = source.indexOf("/");
	if (slashIndex === solidusIndex + 1) slashIndex = source.indexOf("/", solidusIndex + 3);
	if (slashIndex === -1) {
		result.protocol = span(0, solidusIndex);
		let host = span(solidusIndex + 3, source.length);
		if (host) {
			let { hostname, port } = hostSpans(source, host);
			result.hostname = hostname;
			result.port = port;
		}
		return result;
	}
	if (slashIndex < solidusIndex) {
		result.pathname = pathnameSpan(source, 0, source.length);
		return result;
	}
	result.protocol = span(0, solidusIndex);
	let host = span(solidusIndex + 3, slashIndex);
	if (host) {
		let { hostname, port } = hostSpans(source, host);
		result.hostname = hostname;
		result.port = port;
	}
	result.pathname = pathnameSpan(source, slashIndex, source.length);
	return result;
}
function span(start, end) {
	if (start === end) return null;
	return [start, end];
}
function hostSpans(source, host) {
	let lastColonIndex = source.slice(0, host[1]).lastIndexOf(":");
	if (lastColonIndex === -1 || lastColonIndex < host[0]) return {
		hostname: host,
		port: null
	};
	if (source.slice(lastColonIndex + 1, host[1]).match(/^\d+$/)) return {
		hostname: span(host[0], lastColonIndex),
		port: span(lastColonIndex + 1, host[1])
	};
	return {
		hostname: host,
		port: null
	};
}
function pathnameSpan(source, begin, end) {
	if (source[begin] === "/") begin += 1;
	return span(begin, end);
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/route-pattern/parse.js
var IDENTIFIER_RE = /^[a-zA-Z_$][a-zA-Z_$0-9]*/;
/**
* Parse a route pattern source string
*
* @param source The pattern source, e.g. `'/users/:id'` or `'https://:tenant.example.com/dashboard?tab'`.
* @returns The parsed pattern.
* @throws {ParseError} When the source is malformed.
*/
function parsePattern(source) {
	let spans = split(source);
	if (spans.port && !spans.hostname) throw new ParseError("missing hostname", source, spans.port[0] - 1);
	return createRoutePattern({
		protocol: parseProtocol(source, spans.protocol),
		hostname: parseHostname(source, spans.hostname),
		port: spans.port ? source.slice(...spans.port) : null,
		pathname: spans.pathname ? parsePart(source, {
			span: spans.pathname,
			type: "pathname"
		}) : parsePart("", {
			span: [0, 0],
			type: "pathname"
		}),
		search: spans.search ? parseSearch(source.slice(...spans.search)) : /* @__PURE__ */ new Map()
	});
}
/**
* Parse a single URL part (hostname or pathname).
*
* @private
*/
function parsePart(source, options) {
	let span = options.span ?? [0, source.length];
	let separator = options.type === "hostname" ? "." : "/";
	let tokens = [];
	let tokenIndices = [];
	let optionals = /* @__PURE__ */ new Map();
	let appendText = (text) => {
		let currentToken = tokens.at(-1);
		if (currentToken?.type === "text") currentToken.text += text;
		else {
			tokens.push({
				type: "text",
				text
			});
			tokenIndices.push(i);
		}
	};
	let i = span[0];
	let optionalStack = [];
	let emptyOptionals = [];
	while (i < span[1]) {
		let char = source[i];
		if (char === "(") {
			optionalStack.push({
				tokenIndex: tokens.length,
				sourceIndex: i
			});
			tokens.push({ type: char });
			tokenIndices.push(i);
			i += 1;
			continue;
		}
		if (char === ")") {
			let optional = optionalStack.pop();
			if (optional === void 0) throw new ParseError("unmatched )", source, i);
			if (optional.tokenIndex === tokens.length - 1) emptyOptionals.push(optional.sourceIndex);
			optionals.set(optional.tokenIndex, tokens.length);
			tokens.push({ type: char });
			tokenIndices.push(i);
			i += 1;
			continue;
		}
		if (char === ":") {
			i += 1;
			let name = IDENTIFIER_RE.exec(source.slice(i, span[1]))?.[0];
			if (!name) throw new ParseError("missing variable name", source, i - 1);
			tokens.push({
				type: ":",
				name
			});
			tokenIndices.push(i - 1);
			i += name.length;
			continue;
		}
		if (char === "*") {
			i += 1;
			let name = IDENTIFIER_RE.exec(source.slice(i, span[1]))?.[0];
			tokens.push({
				type: "*",
				name: name ?? "*"
			});
			tokenIndices.push(i - 1);
			i += name?.length ?? 0;
			continue;
		}
		if (char === separator) {
			tokens.push({ type: "separator" });
			tokenIndices.push(i);
			i += 1;
			continue;
		}
		if (char === "\\") {
			if (i + 1 === span[1]) throw new ParseError("dangling escape", source, i);
			appendText(source.slice(i + 1, i + 2));
			i += 2;
			continue;
		}
		appendText(char);
		i += 1;
	}
	let unmatchedOptional = optionalStack.at(-1);
	if (unmatchedOptional !== void 0) throw new ParseError("unmatched (", source, unmatchedOptional.sourceIndex);
	if (emptyOptionals.length > 0) throw new ParseError("empty optional", source, emptyOptionals[0]);
	validateTokenGrammar(source, tokens, optionals, tokenIndices);
	validateOptionalCaptureSchemas(source, tokens, optionals, tokenIndices);
	return {
		tokens,
		optionals,
		type: options.type
	};
}
function validateTokenGrammar(source, tokens, optionals, tokenIndices) {
	for (let [index, token] of tokens.entries()) {
		if (token.type !== ":" && token.type !== "*") continue;
		for (let next of nextConsumingTokenIndices(tokens, optionals, index + 1)) {
			if (next === tokens.length) continue;
			let nextToken = tokens[next];
			if (token.type === "*") {
				if (nextToken.type === "*") throw new ParseError("adjacent wildcards", source, tokenIndices[next]);
				continue;
			}
			if (nextToken.type === "separator" || nextToken.type === "*" || nextToken.type === "text" && nextToken.text.startsWith(".")) continue;
			throw new ParseError("invalid param delimiter", source, tokenIndices[next]);
		}
	}
}
function nextConsumingTokenIndices(tokens, optionals, start) {
	let result = /* @__PURE__ */ new Set();
	let pending = [start];
	let visited = /* @__PURE__ */ new Set();
	while (pending.length > 0) {
		let index = pending.pop();
		if (index === void 0) break;
		if (visited.has(index)) continue;
		visited.add(index);
		let token = tokens[index];
		if (token === void 0) result.add(tokens.length);
		else if (token.type === "(") {
			let end = optionals.get(index);
			if (end === void 0) throw new Error("missing optional end");
			pending.push(index + 1, end + 1);
		} else if (token.type === ")") pending.push(index + 1);
		else result.add(index);
	}
	return result;
}
function validateOptionalCaptureSchemas(source, tokens, optionals, tokenIndices) {
	for (let [begin, end] of optionals) {
		let nextBegin = end + 1;
		if (tokens[nextBegin]?.type !== "(") continue;
		let nextEnd = optionals.get(nextBegin);
		if (nextEnd === void 0) continue;
		let first = optionalStructure(tokens, begin + 1, end);
		let second = optionalStructure(tokens, nextBegin + 1, nextEnd);
		if (first.structure === second.structure && first.captures !== second.captures) throw new ParseError("ambiguous optional captures", source, tokenIndices[nextBegin]);
	}
}
function optionalStructure(tokens, begin, end) {
	let structure = "";
	let captures = "";
	for (let i = begin; i < end; i++) {
		let token = tokens[i];
		if (token.type === ":" || token.type === "*") {
			structure += token.type;
			captures += `${token.type}:${token.name}|`;
		} else if (token.type === "text") structure += `t:${token.text}|`;
		else structure += `${token.type}|`;
	}
	return {
		structure,
		captures
	};
}
function parseProtocol(source, span) {
	if (!span) return null;
	let protocol = source.slice(...span);
	if (protocol === "" || protocol === "http" || protocol === "https" || protocol === "http(s)") return protocol === "" ? null : protocol;
	throw new ParseError("invalid protocol", source, span[0]);
}
function parseHostname(source, span) {
	if (!span) return null;
	let part = parsePart(source, {
		span,
		type: "hostname"
	});
	if (isNamelessWildcard(part)) return null;
	return part;
}
function isNamelessWildcard(part) {
	if (part.tokens.length !== 1) return false;
	let token = part.tokens[0];
	if (token.type !== "*") return false;
	return token.name === "*";
}
function parseSearch(source) {
	let constraints = /* @__PURE__ */ new Map();
	let searchParams = new URLSearchParams(source);
	for (let [key, value] of searchParams) {
		let requiredValues = constraints.get(key);
		if (!requiredValues) {
			requiredValues = /* @__PURE__ */ new Set();
			constraints.set(key, requiredValues);
		}
		if (value === "") continue;
		requiredValues.add(value);
	}
	return constraints;
}
/** Error thrown when a route pattern cannot be parsed. */
var ParseError = class extends Error {
	/** The parse failure category. */
	type;
	/** Original pattern source being parsed. */
	source;
	/** Character index where parsing failed. */
	index;
	constructor(type, source, index) {
		let message = `${type}\n\n${source}\n${" ".repeat(index) + "^"}`;
		super(message);
		this.name = "ParseError";
		this.type = type;
		this.source = source;
		this.index = index;
	}
};
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/unreachable.js
/**
* An internal error that should never happen.
*
* @param value Typed as `never` to ensure exhaustiveness for discriminated unions.
*/
function unreachable(value) {
	let message = value === void 0 ? "Unreachable" : `Unreachable: ${value}`;
	throw new Error(message);
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/route-pattern/serialize.js
function serializePattern(pattern) {
	let protocol = serializeProtocol(pattern);
	let hostname = serializeHostname(pattern);
	let port = serializePort(pattern);
	let pathname = serializePathname(pattern);
	let search = serializeSearch(pattern);
	let result = "";
	if (protocol || hostname || port) result += `${protocol}://${hostname}${port === "" ? "" : `:${port}`}`;
	result += "/" + pathname;
	if (search) result += `?${search}`;
	return result;
}
function serializePatternParts(pattern) {
	return {
		protocol: serializeProtocol(pattern),
		hostname: serializeHostname(pattern),
		port: serializePort(pattern),
		pathname: serializePathname(pattern),
		search: serializeSearch(pattern)
	};
}
function serializeProtocol(pattern) {
	return pattern.protocol ?? "";
}
function serializeHostname(pattern) {
	return pattern.hostname ? serializePart(pattern.hostname) : "";
}
function serializePort(pattern) {
	return pattern.port ?? "";
}
function serializePathname(pattern) {
	return serializePart(pattern.pathname);
}
function serializeSearch(pattern) {
	if (pattern.search.size === 0) return "";
	let searchParams = new URLSearchParams();
	for (let [key, constraint] of pattern.search) if (constraint.size === 0) searchParams.append(key, "");
	else for (let value of constraint) searchParams.append(key, value);
	return searchParams.toString();
}
function escapeText(text) {
	return text.replaceAll(/[:*()\\]/g, "\\$&");
}
function serializePart(part) {
	let separator = part.type === "hostname" ? "." : "/";
	let result = "";
	for (let token of part.tokens) {
		if (token.type === "(" || token.type === ")") {
			result += token.type;
			continue;
		}
		if (token.type === "text") {
			result += escapeText(token.text);
			continue;
		}
		if (token.type === ":" || token.type === "*") {
			let name = token.name === "*" ? "" : token.name;
			result += `${token.type}${name}`;
			continue;
		}
		if (token.type === "separator") {
			result += separator;
			continue;
		}
		unreachable(token.type);
	}
	return result;
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/route-pattern.js
/**
* A parsed route pattern.
*
* Create one with the {@link RoutePattern} `parse` method. The constructor is public but takes a parsed
* representation that is not part of the public API; prefer `RoutePattern.parse` instead. Use
* `source`, `toString()`, `toJSON()`, and {@link getRoutePatternCaptures} for inspection.
*/
var RoutePattern = class {
	/** Parsed parts of this pattern. Internal; not part of the public API. */
	_parts;
	/**
	* Create a new `RoutePattern` from its parsed parts.
	*
	* The parts are not part of the public API. Use the {@link RoutePattern} `parse` method to create a pattern
	* from a source string.
	*
	* @param parts The parsed parts of the pattern.
	*/
	constructor(parts) {
		this._parts = parts;
	}
	/**
	* Create a new `RoutePattern` by parsing a source string.
	*
	* @param source The route pattern source string.
	* @returns The parsed route pattern.
	*/
	static parse(source) {
		return parsePattern(source);
	}
	/** Normalized string representation of this pattern. */
	get source() {
		return serializePattern(this._parts);
	}
	/**
	* Returns a string representing this route pattern.
	*
	* @returns The same normalized pattern string as `RoutePattern.source`.
	*/
	toString() {
		return this.source;
	}
	/**
	* Returns a JSON-serializable object containing each serialized part of this route pattern.
	*
	* @returns The serialized protocol, hostname, port, pathname, and search.
	*/
	toJSON() {
		return serializePatternParts(this._parts);
	}
};
function createRoutePattern(parts) {
	return new RoutePattern(parts);
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/join.js
/**
* Join two route patterns.
*
* Origin parts (`protocol`, `hostname`, `port`) from `next` override `base` when present.
* Pathnames are concatenated with a separator inserted between them as needed.
* Search constraints from both patterns are merged.
*
* @param base The base pattern.
* @param next The next pattern to join onto `base`.
* @returns The joined route pattern.
*/
function joinPatterns(base, next) {
	let basePattern = typeof base === "string" ? RoutePattern.parse(base) : base;
	let nextPattern = typeof next === "string" ? RoutePattern.parse(next) : next;
	let baseParts = basePattern._parts;
	let nextParts = nextPattern._parts;
	return createRoutePattern({
		protocol: nextParts.protocol ?? baseParts.protocol,
		hostname: nextParts.hostname ?? baseParts.hostname,
		port: nextParts.port ?? baseParts.port,
		pathname: joinPathname(baseParts.pathname, nextParts.pathname),
		search: joinSearch(baseParts.search, nextParts.search)
	});
}
/**
* Join two pathname parts, inserting a separator between them as needed.
*
* Trailing separator is stripped from `base`; leading separator is added to `next` if absent.
*
* ```text
* 'a'   + 'b'   -> 'a/b'
* 'a/'  + 'b'   -> 'a/b'
* 'a'   + '/b'  -> 'a/b'
* 'a/'  + '/b'  -> 'a/b'
* '(a)' + '(b)' -> '(a)/(b)'
* '(a/)'+ '(b)' -> '(a)/(b)'
* '(a)' +'(/b)' -> '(a)(/b)'
* '(a/)'+'(/b)' -> '(a)(/b)'
* ```
*
* @private
*/
function joinPathname(base, next) {
	if (base.tokens.length === 0) return next;
	if (next.tokens.length === 0) return base;
	let tokens = [];
	let baseLastNonOptionalIndex = base.tokens.findLastIndex((token) => token.type !== "(" && token.type !== ")");
	let baseHasTrailingSeparator = base.tokens[baseLastNonOptionalIndex]?.type === "separator";
	base.tokens.forEach((token, index) => {
		if (index === baseLastNonOptionalIndex && token.type === "separator") return;
		tokens.push(token);
	});
	let nextFirstNonOptional = next.tokens.find((token) => token.type !== "(" && token.type !== ")");
	if (nextFirstNonOptional === void 0 || nextFirstNonOptional.type !== "separator") tokens.push({ type: "separator" });
	let tokenOffset = tokens.length;
	next.tokens.forEach((token) => tokens.push(token));
	let optionals = /* @__PURE__ */ new Map();
	for (let [begin, end] of base.optionals) {
		if (baseHasTrailingSeparator) {
			if (begin > baseLastNonOptionalIndex) begin -= 1;
			if (end > baseLastNonOptionalIndex) end -= 1;
		}
		optionals.set(begin, end);
	}
	for (let [begin, end] of next.optionals) optionals.set(tokenOffset + begin, tokenOffset + end);
	return {
		tokens,
		optionals,
		type: "pathname"
	};
}
/**
* Merge two search constraint maps.
*
* ```text
* '?a'   + '?b'   -> '?a&b'
* '?a=1' + '?a=2' -> '?a=1&a=2'
* '?a=1' + '?b=2' -> '?a=1&b=2'
* ''     + '?a'   -> '?a'
* ```
*
* @private
*/
function joinSearch(base, next) {
	let result = /* @__PURE__ */ new Map();
	for (let [name, values] of base) result.set(name, new Set(values));
	for (let [name, values] of next) {
		let current = result.get(name);
		if (current === void 0) {
			result.set(name, new Set(values));
			continue;
		}
		for (let value of values) current.add(value);
	}
	return result;
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/match/punycode.js
/** Highest positive signed 32-bit float value */
var maxInt = 2147483647;
/** Bootstring parameters */
var base = 36;
var tMin = 1;
var tMax = 26;
var skew = 38;
var damp = 700;
var initialBias = 72;
var initialN = 128;
var delimiter = "-";
/** Regular expressions */
var regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g;
/** Error messages */
var errors = {
	overflow: "Overflow: input needs wider integers to process",
	"not-basic": "Illegal input >= 0x80 (not a basic code point)",
	"invalid-input": "Invalid input"
};
var baseMinusTMin = 35;
/**
* A generic error utility function.
* @param type The error type.
*/
function error(type) {
	throw new RangeError(errors[type]);
}
/**
* A simple `Array#map`-like wrapper to work with domain name strings or email
* addresses.
* @param domain The domain name or email address.
* @param callback The function that gets called for every character.
* @returns A new string of characters returned by the callback function.
*/
function mapDomain(domain, callback) {
	let parts = domain.split("@");
	let result = "";
	if (parts.length > 1) {
		result = parts[0] + "@";
		domain = parts[1];
	}
	domain = domain.replace(regexSeparators, ".");
	let encoded = domain.split(".").map(callback).join(".");
	return result + encoded;
}
/**
* Converts a basic code point into a digit/integer.
* @see `digitToBasic()`
* @param codePoint The basic numeric code point value.
* @returns The numeric value of a basic code point in the range `0` to
* `base - 1`, or `base` if the code point does not represent a value.
*/
function basicToDigit(codePoint) {
	if (codePoint >= 48 && codePoint < 58) return 26 + (codePoint - 48);
	if (codePoint >= 65 && codePoint < 91) return codePoint - 65;
	if (codePoint >= 97 && codePoint < 123) return codePoint - 97;
	return base;
}
/**
* Bias adaptation function as per section 3.4 of RFC 3492.
* https://tools.ietf.org/html/rfc3492#section-3.4
* @param delta The current delta.
* @param numPoints The number of code points handled.
* @param firstTime Whether this is the first adaptation.
* @returns The adapted bias.
*/
function adapt(delta, numPoints, firstTime) {
	let k = 0;
	delta = firstTime ? Math.floor(delta / damp) : delta >> 1;
	delta += Math.floor(delta / numPoints);
	for (; delta > 455; k += base) delta = Math.floor(delta / baseMinusTMin);
	return Math.floor(k + 36 * delta / (delta + skew));
}
/**
* Converts a Punycode string of ASCII-only symbols to a string of Unicode
* symbols.
* @param input The Punycode string of ASCII-only symbols.
* @returns The resulting string of Unicode symbols.
*/
function decode(input) {
	let output = [];
	let inputLength = input.length;
	let i = 0;
	let n = initialN;
	let bias = initialBias;
	let basic = input.lastIndexOf(delimiter);
	if (basic < 0) basic = 0;
	for (let j = 0; j < basic; ++j) {
		if (input.charCodeAt(j) >= 128) error("not-basic");
		output.push(input.charCodeAt(j));
	}
	for (let index = basic > 0 ? basic + 1 : 0; index < inputLength;) {
		let oldi = i;
		for (let w = 1, k = base;; k += base) {
			if (index >= inputLength) error("invalid-input");
			let digit = basicToDigit(input.charCodeAt(index++));
			if (digit >= base) error("invalid-input");
			if (digit > Math.floor((maxInt - i) / w)) error("overflow");
			i += digit * w;
			let t = k <= bias ? tMin : k >= bias + tMax ? tMax : k - bias;
			if (digit < t) break;
			let baseMinusT = base - t;
			if (w > Math.floor(maxInt / baseMinusT)) error("overflow");
			w *= baseMinusT;
		}
		let out = output.length + 1;
		bias = adapt(i - oldi, out, oldi === 0);
		if (Math.floor(i / out) > maxInt - n) error("overflow");
		n += Math.floor(i / out);
		i %= out;
		output.splice(i++, 0, n);
	}
	return String.fromCodePoint(...output);
}
/**
* Converts a Punycode string representing a domain name or an email address
* to Unicode. Only the Punycoded parts of the input will be converted, i.e.
* it doesn't matter if you call it on a string that has already been
* converted to Unicode.
* @param input The Punycoded domain name or email address to convert to
* Unicode.
* @returns The Unicode representation of the given Punycode string.
*/
var toUnicode = function(input) {
	if (!input.includes("xn--")) return input;
	return mapDomain(input, function(string) {
		return string.startsWith("xn--") ? decode(string.slice(4).toLowerCase()) : string;
	});
};
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/match/limits.js
/** Error thrown when matcher compilation or matching exceeds a configured resource limit. */
var MatcherResourceError = class extends Error {
	/** Structured information about the exceeded limit. */
	details;
	/**
	* Creates a matcher resource error.
	*
	* @param details Information about the exceeded limit.
	*/
	constructor(details) {
		super(`${details.limit} exceeded: ${details.actual} > ${details.maximum}`);
		this.name = "MatcherResourceError";
		this.details = details;
	}
};
var defaultMatcherLimits = {
	maxPatternSize: 65536,
	maxMatcherSize: 16777216,
	maxMatchWork: 1e6
};
function createMatchWorkBudget(maximum) {
	return {
		maximum,
		actual: 0
	};
}
function consumeMatchWork(budget, count) {
	let actual = budget.actual + count;
	if (!Number.isSafeInteger(actual)) actual = Number.MAX_SAFE_INTEGER;
	checkMatcherLimit("maxMatchWork", budget.maximum, actual);
	budget.actual = actual;
}
function resolveMatcherLimits(limits) {
	let result = {
		...defaultMatcherLimits,
		...limits
	};
	for (let [limit, maximum] of Object.entries(result)) if (!Number.isSafeInteger(maximum) || maximum < 0) throw new RangeError(`${limit} must be a non-negative safe integer`);
	return result;
}
function checkMatcherLimit(limit, maximum, actual) {
	if (actual > maximum) throw new MatcherResourceError({
		limit,
		maximum,
		actual
	});
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/match/program.js
var emptySolution = {
	captures: null,
	captureCount: 0
};
function compilePart(part, options) {
	let tokens = [];
	let optionals = /* @__PURE__ */ new Map();
	let optionalStack = [];
	let captureNames = /* @__PURE__ */ new Set();
	for (let token of part.tokens) if (token.type === "text") for (let unit of canonicalizePatternText(token.text, part.type, options).units) tokens.push({
		type: "text",
		unit
	});
	else if (token.type === "separator") {
		let value = part.type === "hostname" ? "." : "/";
		tokens.push({
			type: "separator",
			unit: {
				value,
				structural: true,
				begin: 0,
				end: value.length
			}
		});
	} else {
		if (token.type === "(") optionalStack.push(tokens.length);
		if (token.type === ")") {
			let begin = optionalStack.pop();
			if (begin === void 0) throw new Error("missing optional begin");
			optionals.set(begin, tokens.length);
		}
		tokens.push(token);
		if ((token.type === ":" || token.type === "*") && token.name !== "*") captureNames.add(token.name);
	}
	let staticPrefix = [];
	for (let token of tokens) if (token.type === "text" || token.type === "separator") staticPrefix.push(token.unit);
	else break;
	let staticSuffix = [];
	for (let i = tokens.length - 1; i >= 0; i--) {
		let token = tokens[i];
		if (token.type === "text" || token.type === "separator") staticSuffix.push(token.unit);
		else break;
	}
	staticSuffix.reverse();
	let staticAnchor = [];
	let staticRun = [];
	let optionalDepth = 0;
	for (let token of tokens) if (token.type === "(") {
		if (staticRun.length > staticAnchor.length) staticAnchor = staticRun;
		staticRun = [];
		optionalDepth += 1;
	} else if (token.type === ")") optionalDepth -= 1;
	else if ((token.type === "text" || token.type === "separator") && optionalDepth === 0) staticRun.push(token.unit);
	else if (optionalDepth === 0) {
		if (staticRun.length > staticAnchor.length) staticAnchor = staticRun;
		staticRun = [];
	}
	if (staticRun.length > staticAnchor.length) staticAnchor = staticRun;
	return {
		type: part.type,
		tokens,
		optionals,
		captureNames,
		matchKind: getMatchKind(tokens),
		staticPrefix,
		staticSuffix,
		staticAnchor
	};
}
function getMatchKind(tokens) {
	let result = "static";
	for (let token of tokens) {
		if (token.type === "*" || token.type === "(" || token.type === ")") return "state";
		if (token.type === ":") result = "linear";
	}
	return result;
}
function hasStaticSuffix(program, input, budget) {
	let offset = input.units.length - program.staticSuffix.length;
	if (offset < 0) return false;
	consumeMatchWork(budget, program.staticSuffix.length);
	for (let i = 0; i < program.staticSuffix.length; i++) if (!unitsEqual(input.units[offset + i], program.staticSuffix[i])) return false;
	return true;
}
function hasStaticPrefix(program, input, budget) {
	if (program.staticPrefix.length > input.units.length) return false;
	consumeMatchWork(budget, program.staticPrefix.length);
	for (let i = 0; i < program.staticPrefix.length; i++) if (!unitsEqual(input.units[i], program.staticPrefix[i])) return false;
	return true;
}
function hasStaticAnchor(program, input, budget) {
	if (program.staticAnchor.length === 0) return true;
	for (let position = 0; position + program.staticAnchor.length <= input.units.length; position++) {
		consumeMatchWork(budget, program.staticAnchor.length);
		if (matchUnits(input.units, position, program.staticAnchor) !== null) return true;
	}
	return false;
}
function canonicalizeUrlPart(text, type, options) {
	consumeMatchWork(options.budget, text.length);
	return canonicalizeText(text, type, {
		ignoreCase: options.ignoreCase,
		strict: true,
		pattern: false
	});
}
function canonicalizePatternText(text, type, options) {
	let result = canonicalizeText(text, type, {
		...options,
		strict: false,
		pattern: true
	});
	if (result === null) throw new Error("pattern text canonicalization failed");
	return result;
}
function canonicalizeText(text, type, options) {
	let units = [];
	let offset = 0;
	let chunk = "";
	let appendChunk = () => {
		if (chunk === "") return true;
		let decoded;
		try {
			decoded = decodeURIComponent(chunk);
		} catch (error) {
			if (!(error instanceof URIError)) throw error;
			if (options.strict) return false;
			decoded = chunk;
		}
		if (options.ignoreCase) decoded = decoded.toLowerCase();
		for (let value of decoded) {
			let encoded = encodeDataUnit(value, type);
			units.push({
				value,
				structural: false,
				begin: offset,
				end: offset + encoded.length
			});
			offset += encoded.length;
		}
		chunk = "";
		return true;
	};
	for (let char of text) {
		if (!(char === "." || type === "pathname" && !options.pattern && char === "/")) {
			chunk += char;
			continue;
		}
		if (!appendChunk()) return null;
		units.push({
			value: char,
			structural: true,
			begin: offset,
			end: offset + char.length
		});
		offset += char.length;
	}
	if (!appendChunk()) return null;
	return {
		units,
		length: offset
	};
}
function encodeDataUnit(value, type) {
	if (type === "pathname" && value === ".") return "%2E";
	if (type === "pathname" && value === "/") return "%2F";
	return type === "pathname" ? encodeURIComponent(value) : value;
}
function matchPart(program, input, budget) {
	let stateCount = program.tokens.length + 1;
	let inputLength = input.units.length;
	if (program.matchKind === "static") {
		consumeMatchWork(budget, stateCount + inputLength);
		if (program.tokens.length !== inputLength) return null;
		for (let position = 0; position < inputLength; position++) {
			let token = program.tokens[position];
			if (token.type !== "text" && token.type !== "separator" || !unitsEqual(input.units[position], token.unit)) return null;
		}
		return [];
	}
	if (program.matchKind === "linear") {
		consumeMatchWork(budget, stateCount + inputLength);
		return matchLinearPart(program, input);
	}
	consumeMatchWork(budget, stateCount * (inputLength + 1));
	let hostnameOrder = program.type === "hostname" ? hostnamePositions(input.units) : null;
	let solutions = Array.from({ length: stateCount }, () => Array.from({ length: inputLength + 1 }, () => null));
	for (let position = inputLength; position >= 0; position--) {
		solutions[program.tokens.length][position] = position === inputLength ? emptySolution : null;
		for (let state = program.tokens.length - 1; state >= 0; state--) {
			let token = program.tokens[state];
			if (token.type === ")") {
				solutions[state][position] = solutions[state + 1][position];
				continue;
			}
			if (token.type === "(") {
				let end = program.optionals.get(state);
				if (end === void 0) throw new Error("missing optional end");
				let omitted = solutions[end + 1][position];
				let included = solutions[state + 1][position];
				solutions[state][position] = betterSolution(inputLength, hostnameOrder, omitted, included, budget);
				continue;
			}
			if (token.type === "text") {
				solutions[state][position] = input.units[position] !== void 0 && unitsEqual(input.units[position], token.unit) ? solutions[state + 1][position + 1] : null;
				continue;
			}
			if (token.type === "separator") {
				let unit = input.units[position];
				solutions[state][position] = unit !== void 0 && unitsEqual(unit, token.unit) ? solutions[state + 1][position + 1] : null;
				continue;
			}
			if (token.type === ":") {
				let end = position;
				while (end < inputLength && !input.units[end].structural) {
					consumeMatchWork(budget, 1);
					end += 1;
				}
				let suffix = end === position ? null : solutions[state + 1][end];
				solutions[state][position] = prependCapture(suffix, {
					type: token.type,
					name: token.name,
					begin: position,
					end
				});
				continue;
			}
			if (token.type !== "*") throw new Error(`unexpected token: ${token.type}`);
			let consumed = null;
			if (position < inputLength) {
				let next = solutions[state][position + 1];
				if (next !== null) {
					let capture = next.captures;
					if (capture === null || capture.type !== "*" || capture.name !== token.name) throw new Error("invalid wildcard continuation");
					consumed = {
						captures: {
							...capture,
							begin: position
						},
						captureCount: next.captureCount
					};
				}
			}
			let exited = prependCapture(solutions[state + 1][position], {
				type: token.type,
				name: token.name,
				begin: position,
				end: position
			});
			solutions[state][position] = betterSolution(inputLength, hostnameOrder, consumed, exited, budget);
		}
	}
	let solution = solutions[0][0];
	if (solution === null) return null;
	let result = [];
	for (let capture = solution.captures; capture !== null; capture = capture.next) result.push(toMatchParamMeta(input, capture));
	return result;
}
function matchLinearPart(program, input) {
	let captures = [];
	let position = 0;
	for (let token of program.tokens) {
		if (token.type === "text" || token.type === "separator") {
			let unit = input.units[position];
			if (unit === void 0 || !unitsEqual(unit, token.unit)) return null;
			position += 1;
			continue;
		}
		if (token.type !== ":") throw new Error(`unexpected linear token: ${token.type}`);
		let begin = position;
		while (position < input.units.length && !input.units[position].structural) position += 1;
		if (position === begin) return null;
		captures.push(toMatchParamMeta(input, {
			type: token.type,
			name: token.name,
			begin,
			end: position,
			next: null
		}));
	}
	return position === input.units.length ? captures : null;
}
function toMatchParamMeta(input, capture) {
	let value = "";
	for (let position = capture.begin; position < capture.end; position++) value += input.units[position].value;
	return {
		type: capture.type,
		name: capture.name,
		value,
		begin: offsetAt(input, capture.begin),
		end: offsetAt(input, capture.end)
	};
}
function matchUnits(input, position, expected) {
	if (position + expected.length > input.length) return null;
	for (let i = 0; i < expected.length; i++) if (!unitsEqual(input[position + i], expected[i])) return null;
	return position + expected.length;
}
function unitsEqual(a, b) {
	return a.value === b.value && a.structural === b.structural;
}
function prependCapture(solution, capture) {
	return solution === null ? null : {
		captures: {
			...capture,
			next: solution.captures
		},
		captureCount: solution.captureCount + 1
	};
}
function betterSolution(inputLength, hostnameOrder, preferred, alternative, budget) {
	if (preferred === null) return alternative;
	if (alternative === null) return preferred;
	return compareSolutions(inputLength, hostnameOrder, preferred, alternative, budget) >= 0 ? preferred : alternative;
}
function compareSolutions(inputLength, hostnameOrder, a, b, budget) {
	if (hostnameOrder === null) {
		let aCapture = a.captures;
		let bCapture = b.captures;
		for (let position = 0; position < inputLength; position++) {
			consumeMatchWork(budget, 1);
			while (aCapture !== null && aCapture.end <= position) {
				consumeMatchWork(budget, 1);
				aCapture = aCapture.next;
			}
			while (bCapture !== null && bCapture.end <= position) {
				consumeMatchWork(budget, 1);
				bCapture = bCapture.next;
			}
			let aSpecificity = captureSpecificityAt(aCapture, position);
			let bSpecificity = captureSpecificityAt(bCapture, position);
			if (aSpecificity < bSpecificity) return 1;
			if (aSpecificity > bSpecificity) return -1;
		}
	} else {
		let aEncoding = encodeSpecificity(inputLength, a.captures, budget);
		let bEncoding = encodeSpecificity(inputLength, b.captures, budget);
		for (let position of hostnameOrder) {
			consumeMatchWork(budget, 1);
			if (aEncoding[position] < bEncoding[position]) return 1;
			if (aEncoding[position] > bEncoding[position]) return -1;
		}
	}
	if (a.captureCount < b.captureCount) return 1;
	if (a.captureCount > b.captureCount) return -1;
	return 0;
}
function captureSpecificityAt(capture, position) {
	if (capture === null || capture.begin > position) return 0;
	return capture.type === ":" ? 1 : 2;
}
function encodeSpecificity(length, captures, budget) {
	consumeMatchWork(budget, length);
	let encoding = new Uint8Array(length);
	for (let capture = captures; capture !== null; capture = capture.next) {
		consumeMatchWork(budget, 1 + capture.end - capture.begin);
		encoding.fill(capture.type === ":" ? 1 : 2, capture.begin, capture.end);
	}
	return encoding;
}
function hostnamePositions(input) {
	let result = [];
	let end = input.length;
	for (let i = input.length - 1; i >= 0; i--) if (input[i].structural && input[i].value === ".") {
		for (let j = i + 1; j < end; j++) result.push(j);
		end = i;
	}
	for (let i = 0; i < end; i++) result.push(i);
	return result;
}
function offsetAt(input, position) {
	if (position === input.units.length) return input.length;
	return input.units[position].begin;
}
function unitKey(unit) {
	return `${unit.structural ? "s" : "d"}:${unit.value}`;
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/match/trie.js
var maxCandidatesBeforeSecondaryIndex = 32;
var Trie = class {
	ignoreCase;
	#pathnamePrefixIndex = createPathnameIndexNode();
	#pathnameSuffixIndex = createPathnameIndexNode();
	#pathnameAnchorIndex = createPathnameIndexNode();
	#insertion = 0;
	#limits;
	#size = 0;
	constructor(options) {
		this.ignoreCase = options?.ignoreCase ?? false;
		this.#limits = resolveMatcherLimits(options?.limits);
	}
	insert(pattern, data) {
		let patternSize;
		if (typeof pattern === "string") {
			let source = pattern;
			patternSize = this.#checkSizeLimits(source);
			pattern = parsePattern(pattern);
			if (pattern.source !== source) patternSize = this.#checkSizeLimits(pattern.source);
		} else patternSize = this.#checkSizeLimits(pattern.source);
		let patternParts = pattern._parts;
		let hostname = patternParts.hostname ? compilePart(patternParts.hostname, { ignoreCase: true }) : null;
		let pathname = compilePart(patternParts.pathname, { ignoreCase: this.ignoreCase });
		let entry = {
			pattern,
			patternParts,
			data,
			hostname,
			pathname,
			insertion: this.#insertion++
		};
		let node = this.#pathnamePrefixIndex;
		for (let unit of pathname.staticPrefix) {
			let key = unitKey(unit);
			let next = node.static.get(key);
			if (next === void 0) {
				next = createPathnameIndexNode();
				node.static.set(key, next);
			}
			node = next;
		}
		node.entries.push(entry);
		node = this.#pathnameAnchorIndex;
		for (let unit of pathname.staticAnchor) {
			let key = unitKey(unit);
			let next = node.static.get(key);
			if (next === void 0) {
				next = createPathnameIndexNode();
				node.static.set(key, next);
			}
			node = next;
		}
		node.entries.push(entry);
		node = this.#pathnameSuffixIndex;
		for (let i = pathname.staticSuffix.length - 1; i >= 0; i--) {
			let key = unitKey(pathname.staticSuffix[i]);
			let next = node.static.get(key);
			if (next === void 0) {
				next = createPathnameIndexNode();
				node.static.set(key, next);
			}
			node = next;
		}
		node.entries.push(entry);
		this.#size += patternSize;
	}
	#checkSizeLimits(source) {
		let size = utf8Size(source);
		checkMatcherLimit("maxPatternSize", this.#limits.maxPatternSize, size);
		checkMatcherLimit("maxMatcherSize", this.#limits.maxMatcherSize, this.#size + size);
		return size;
	}
	search(url) {
		let protocol = url.protocol.slice(0, -1);
		if (protocol !== "http" && protocol !== "https") return [];
		if (this.#insertion === 0) return [];
		let matchWorkBudget = createMatchWorkBudget(this.#limits.maxMatchWork);
		let pathname = canonicalizeUrlPart(url.pathname.slice(1), "pathname", {
			budget: matchWorkBudget,
			ignoreCase: this.ignoreCase
		});
		if (pathname === null) return [];
		let candidates = [];
		let needsHostnameProgram = false;
		for (let entry of this.#findCandidates(pathname, matchWorkBudget)) {
			consumeMatchWork(matchWorkBudget, 1);
			if (!matchesProtocol(entry.patternParts.protocol, protocol)) continue;
			if (!matchesPort(entry.patternParts, protocol, url.port)) continue;
			if (!matchSearch(url.searchParams, entry.patternParts.search, matchWorkBudget)) continue;
			candidates.push(entry);
			if (entry.hostname !== null) needsHostnameProgram = true;
		}
		if (candidates.length === 0) return [];
		candidates.sort((a, b) => a.insertion - b.insertion);
		let decodedHostname = toUnicode(url.hostname);
		let hostname;
		if (needsHostnameProgram) {
			let canonicalHostname = canonicalizeUrlPart(decodedHostname, "hostname", {
				budget: matchWorkBudget,
				ignoreCase: true
			});
			if (canonicalHostname === null) return [];
			hostname = canonicalHostname;
		}
		let results = [];
		for (let entry of candidates) {
			let hostnameMatch;
			if (entry.hostname === null) hostnameMatch = [{
				type: "*",
				name: "*",
				value: decodedHostname,
				begin: 0,
				end: decodedHostname.length
			}];
			else {
				if (hostname === void 0) throw new Error("missing canonical hostname");
				let match = matchPart(entry.hostname, hostname, matchWorkBudget);
				if (match === null) continue;
				hostnameMatch = match;
			}
			let pathnameMatch = matchPart(entry.pathname, pathname, matchWorkBudget);
			if (pathnameMatch === null) continue;
			let params = {};
			for (let name of entry.hostname?.captureNames ?? []) params[name] = void 0;
			for (let name of entry.pathname.captureNames) params[name] = void 0;
			for (let capture of hostnameMatch) if (capture.name !== "*") params[capture.name] = capture.value;
			for (let capture of pathnameMatch) if (capture.name !== "*") params[capture.name] = capture.value;
			results.push({
				url,
				pattern: entry.pattern,
				data: entry.data,
				params,
				paramsMeta: {
					hostname: hostnameMatch.slice(),
					pathname: pathnameMatch.slice()
				}
			});
		}
		return results;
	}
	#findCandidates(pathname, budget) {
		let result = collectCandidates(this.#pathnamePrefixIndex, pathname.units, budget);
		if (result.length > maxCandidatesBeforeSecondaryIndex) {
			let suffix = collectCandidates(this.#pathnameSuffixIndex, pathname.units.toReversed(), budget);
			if (suffix.length < result.length) result = suffix;
		}
		if (result.length > maxCandidatesBeforeSecondaryIndex) {
			let anchor = collectAnchorCandidates(this.#pathnameAnchorIndex, pathname.units, budget);
			if (anchor.length < result.length) result = anchor;
		}
		let filtered = [];
		for (let entry of result) {
			if (!hasStaticPrefix(entry.pathname, pathname, budget)) continue;
			if (!hasStaticSuffix(entry.pathname, pathname, budget)) continue;
			if (!hasStaticAnchor(entry.pathname, pathname, budget)) continue;
			filtered.push(entry);
		}
		return filtered;
	}
};
function utf8Size(value) {
	let result = 0;
	for (let char of value) {
		let code = char.charCodeAt(0);
		result += char.length === 2 ? 4 : code <= 127 ? 1 : code <= 2047 ? 2 : 3;
	}
	return result;
}
function collectCandidates(index, units, budget) {
	let result = [];
	let node = index;
	appendEntries(result, node.entries, budget);
	for (let unit of units) {
		consumeMatchWork(budget, 1);
		node = node.static.get(unitKey(unit));
		if (node === void 0) break;
		appendEntries(result, node.entries, budget);
	}
	return result;
}
function collectAnchorCandidates(index, units, budget) {
	let result = /* @__PURE__ */ new Set();
	addEntries(result, index.entries, budget);
	for (let position = 0; position < units.length; position++) {
		let node = index;
		for (let i = position; i < units.length; i++) {
			consumeMatchWork(budget, 1);
			node = node.static.get(unitKey(units[i]));
			if (node === void 0) break;
			addEntries(result, node.entries, budget);
		}
	}
	return Array.from(result);
}
function appendEntries(target, entries, budget) {
	consumeMatchWork(budget, entries.length);
	for (let entry of entries) target.push(entry);
}
function addEntries(target, entries, budget) {
	consumeMatchWork(budget, entries.length);
	for (let entry of entries) target.add(entry);
}
function matchesProtocol(expected, actual) {
	return expected === null || expected === "http(s)" || expected === actual;
}
function matchesPort(pattern, protocol, actual) {
	if (pattern.port === null) return pattern.hostname === null || actual === "";
	let expected = pattern.port;
	if (protocol === "http" && expected === "80" || protocol === "https" && expected === "443") expected = "";
	return expected === actual;
}
function matchSearch(params, constraints, budget) {
	for (let [name, requiredValues] of constraints) {
		consumeMatchWork(budget, params.size + requiredValues.size + 1);
		if (requiredValues.size === 0) {
			if (!params.has(name)) return false;
			continue;
		}
		let values = new Set(params.getAll(name));
		for (let requiredValue of requiredValues) if (!values.has(requiredValue)) return false;
	}
	return true;
}
function createPathnameIndexNode() {
	return {
		static: /* @__PURE__ */ new Map(),
		entries: []
	};
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/specificity.js
/**
* Returns true if match `a` is more specific than match `b`.
*
* @param a the first match to compare
* @param b the second match to compare
* @returns true if `a` is more specific than `b`
*/
function greaterThan(a, b) {
	return compare(a, b) === 1;
}
/**
* Returns true if matches `a` and `b` have equal specificity.
*
* @param a the first match to compare
* @param b the second match to compare
* @returns true if `a` and `b` have equal specificity
*/
function equal(a, b) {
	return compare(a, b) === 0;
}
/**
* Comparator function for sorting matches from most specific to least specific.
*
* @param a the first match to compare
* @param b the second match to compare
* @returns positive if `a` is less specific, negative if more specific, 0 if equal
*/
var descending = (a, b) => compare(a, b) * -1;
/**
* Compare two matches by specificity.
* Passing to `.sort()` will sort matches from least specific to most specific.
*
* @param a the first match to compare
* @param b the second match to compare
* @returns -1 if `a` is less specific, 1 if `a` is more specific, 0 if tied.
*/
function compare(a, b) {
	if (a.url.href !== b.url.href) throw new Error(`Cannot compare matches for different URLs: ${a.url.href} vs ${b.url.href}`);
	let aParts = a.pattern._parts;
	let bParts = b.pattern._parts;
	let protocolResult = compareProtocol(aParts.protocol, bParts.protocol);
	if (protocolResult !== 0) return protocolResult;
	let portResult = comparePort(aParts.port, bParts.port);
	if (portResult !== 0) return portResult;
	let hostnameResult = compareHostname(toUnicode(a.url.hostname), a.paramsMeta.hostname, b.paramsMeta.hostname);
	if (hostnameResult !== 0) return hostnameResult;
	let pathnameResult = comparePathname(a.paramsMeta.pathname, b.paramsMeta.pathname);
	if (pathnameResult !== 0) return pathnameResult;
	let searchResult = compareSearch(aParts.search, bParts.search);
	if (searchResult !== 0) return searchResult;
	return 0;
}
function compareProtocol(a, b) {
	let aSpecificity = a === "http" || a === "https" ? 1 : 0;
	let bSpecificity = b === "http" || b === "https" ? 1 : 0;
	if (aSpecificity > bSpecificity) return 1;
	if (aSpecificity < bSpecificity) return -1;
	return 0;
}
function comparePort(a, b) {
	if (a !== null && b === null) return 1;
	if (a === null && b !== null) return -1;
	return 0;
}
function compareHostname(hostname, a, b) {
	if (a.length === 0 && b.length === 0) return 0;
	if (a.length === 0 && b.length > 0) return 1;
	if (a.length > 0 && b.length === 0) return -1;
	let aEncoding = new Int8Array(hostname.length);
	for (let range of a) aEncoding.fill(range.type === ":" ? 1 : 2, range.begin, range.end);
	let bEncoding = new Int8Array(hostname.length);
	for (let range of b) bEncoding.fill(range.type === ":" ? 1 : 2, range.begin, range.end);
	let segments = [];
	let end = hostname.length;
	for (let i = hostname.length - 1; i >= 0; i--) if (hostname[i] === ".") {
		segments.push({
			begin: i + 1,
			end
		});
		end = i;
	}
	segments.push({
		begin: 0,
		end
	});
	for (let segment of segments) for (let j = segment.begin; j < segment.end; j++) {
		if (aEncoding[j] < bEncoding[j]) return 1;
		if (aEncoding[j] > bEncoding[j]) return -1;
	}
	return 0;
}
function comparePathname(a, b) {
	if (a.length === 0 && b.length === 0) return 0;
	if (a.length === 0 && b.length > 0) return 1;
	if (a.length > 0 && b.length === 0) return -1;
	let i = 0;
	let aIndex = 0;
	let bIndex = 0;
	while (aIndex < a.length || bIndex < b.length) {
		let aRange = a[aIndex];
		let bRange = b[bIndex];
		if (aRange === void 0) return 1;
		if (bRange === void 0) return -1;
		i = Math.min(aRange.begin, bRange.begin);
		if (i < aRange.begin) return 1;
		if (i < bRange.begin) return -1;
		if (aRange.type === ":" && bRange.type === "*") return 1;
		if (aRange.type === "*" && bRange.type === ":") return -1;
		i = Math.min(aRange.end, bRange.end);
		if (i >= aRange.end) aIndex += 1;
		if (i >= bRange.end) bIndex += 1;
	}
	return 0;
}
function compareSearch(a, b) {
	let aSpecificity = searchSpecificity(a);
	let bSpecificity = searchSpecificity(b);
	if (aSpecificity.keyValue > bSpecificity.keyValue) return 1;
	if (aSpecificity.keyValue < bSpecificity.keyValue) return -1;
	if (aSpecificity.key > bSpecificity.key) return 1;
	if (aSpecificity.key < bSpecificity.key) return -1;
	return 0;
}
function searchSpecificity(constraints) {
	let specificity = {
		key: 0,
		keyValue: 0
	};
	for (let constraint of constraints.values()) {
		if (constraint.size === 0) {
			specificity.key += 1;
			continue;
		}
		specificity.keyValue += constraint.size;
	}
	return specificity;
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/match.js
/**
* Create a matcher for multiple route patterns.
*
* @param options Options for matching URLs
* @returns A matcher that can register multiple patterns with associated data
*/
function createMultiMatcher(options) {
	return new TrieMatcher(options);
}
var TrieMatcher = class {
	ignoreCase;
	#trie;
	constructor(options) {
		this.ignoreCase = options?.ignoreCase ?? false;
		this.#trie = new Trie(options);
	}
	add(pattern, data) {
		this.#trie.insert(pattern, data);
	}
	match(url, options) {
		let parsedUrl = resolveURL(url, options);
		let best = null;
		for (let match of this.#trie.search(parsedUrl)) if (best === null || greaterThan(match, best)) best = match;
		return best;
	}
	matchAll(url, options) {
		let parsedUrl = resolveURL(url, options);
		let matches = [];
		for (let match of this.#trie.search(parsedUrl)) matches.push(match);
		return matches.sort(descending);
	}
};
function resolveURL(url, options) {
	let baseURL = options?.baseURL === void 0 ? void 0 : new URL(options.baseURL);
	return typeof url === "string" ? new URL(url, baseURL) : url;
}
//#endregion
//#region node_modules/@remix-run/route-pattern/dist/lib/href.js
/**
* Generate an href from a route pattern and the supplied params.
*
* Pathname wildcards reject `.` and `..` segments. Generated pathnames have one leading
* slash; internal and trailing slashes are preserved.
*
* @param pattern The parsed route pattern.
* @param args Path params and href options.
* @returns The generated href string.
* @throws {CreateHrefError} When the pattern requires a hostname, contains a nameless wildcard,
* is missing required params, or receives invalid params.
* @throws {TypeError} When `baseURL` is not absolute or cannot resolve a same-origin target.
*/
function createHref(pattern, ...args) {
	pattern = typeof pattern === "string" ? RoutePattern.parse(pattern) : pattern;
	let patternParts = pattern._parts;
	let [params, options] = args;
	let hasOrigin = patternParts.protocol !== null || patternParts.hostname !== null || patternParts.port !== null;
	let result = "";
	let targetOrigin;
	if (hasOrigin) {
		let protocol = patternParts.protocol === null || patternParts.protocol === "http(s)" ? "https" : patternParts.protocol;
		if (patternParts.hostname === null) throw new CreateHrefError({
			type: "missing-hostname",
			pattern
		});
		targetOrigin = `${protocol}://${hrefPart(pattern, patternParts.hostname, params ?? {})}${patternParts.port === null ? "" : `:${patternParts.port}`}`;
		result += targetOrigin;
	}
	let pathname = hrefPart(pattern, patternParts.pathname, params ?? {});
	pathname = "/" + pathname.replace(/^\/+/, "");
	result += pathname;
	let search = hrefSearch(patternParts.search, options?.searchParams);
	let searchSuffix = search === void 0 ? "" : `?${search}`;
	result += searchSuffix;
	if (options?.baseURL !== void 0) {
		let baseURL = new URL(options.baseURL);
		let baseOrigin = baseURL.origin;
		if ((targetOrigin === void 0 ? baseOrigin : new URL(targetOrigin).origin) === baseOrigin) {
			new URL("/", baseURL);
			return relativeHref(pathname, searchSuffix, baseURL);
		}
	}
	return result;
}
function relativeHref(pathname, search, baseURL) {
	let baseSegments = pathnameSegments(baseURL.pathname);
	if (!baseURL.pathname.endsWith("/")) baseSegments.pop();
	let targetSegments = pathnameSegments(pathname);
	let targetIsDirectory = pathname.endsWith("/");
	let targetFile = targetIsDirectory ? void 0 : targetSegments.pop();
	let common = 0;
	while (common < baseSegments.length && common < targetSegments.length && baseSegments[common] === targetSegments[common]) common += 1;
	let relativeSegments = [...Array.from({ length: baseSegments.length - common }, () => ".."), ...targetSegments.slice(common)];
	if (targetFile !== void 0) relativeSegments.push(targetFile);
	let result = relativeSegments.join("/");
	if (targetIsDirectory) result = result === "" ? "./" : `${result}/`;
	if (result === "") result = "./";
	if (/^[\\/]/.test(result) || /^[^/]*:/.test(result)) result = `./${result}`;
	return result + search;
}
function pathnameSegments(pathname) {
	let segments = pathname.slice(1).split("/");
	if (pathname.endsWith("/")) segments.pop();
	return segments;
}
function hrefPart(pattern, part, params) {
	let separator = part.type === "hostname" ? "." : "/";
	let missingParams = [];
	let stack = [{ href: "" }];
	let i = 0;
	while (i < part.tokens.length) {
		let token = part.tokens[i];
		if (token.type === "text") {
			stack[stack.length - 1].href += token.text;
			i += 1;
			continue;
		}
		if (token.type === "separator") {
			stack[stack.length - 1].href += separator;
			i += 1;
			continue;
		}
		if (token.type === "(") {
			stack.push({
				begin: i,
				href: ""
			});
			i += 1;
			continue;
		}
		if (token.type === ")") {
			let frame = stack.pop();
			stack[stack.length - 1].href += frame.href;
			i += 1;
			continue;
		}
		if (token.type === ":" || token.type === "*") {
			let value = params[token.name];
			if (value == null) {
				if (stack.length <= 1) {
					if (token.name === "*") throw new CreateHrefError({
						type: "nameless-wildcard",
						pattern
					});
					if (!missingParams.includes(token.name)) missingParams.push(token.name);
					i += 1;
					continue;
				}
				let frame = stack.pop();
				i = part.optionals.get(frame.begin) + 1;
				if (stack[stack.length - 1].href.endsWith(separator) && part.tokens[i]?.type === "separator") i += 1;
				continue;
			}
			stack[stack.length - 1].href += part.type === "pathname" && token.type === ":" ? encodePathnameVariableParam(pattern, token.name, value) : part.type === "pathname" && token.type === "*" ? encodePathnameWildcard(value) : part.type === "hostname" && token.type === ":" ? validateHostnameVariable(value) : part.type === "hostname" && token.type === "*" ? validateHostnameWildcard(value) : unreachable();
			i += 1;
			continue;
		}
		unreachable(token.type);
	}
	if (missingParams.length > 0) throw new CreateHrefError({
		type: "missing-params",
		pattern,
		missingParams,
		params
	});
	if (stack.length !== 1) unreachable();
	return stack[0].href;
}
function hrefSearch(constraints, searchParams) {
	let urlSearchParams = searchParams instanceof URLSearchParams ? new URLSearchParams(searchParams) : new URLSearchParams();
	if (searchParams !== void 0 && !(searchParams instanceof URLSearchParams)) {
		for (let [key, value] of Object.entries(searchParams)) if (Array.isArray(value)) {
			for (let v of value) if (v != null) urlSearchParams.append(key, String(v));
		} else if (value != null) urlSearchParams.append(key, String(value));
	}
	for (let [key, requiredValues] of constraints) if (requiredValues.size === 0) {
		if (urlSearchParams.has(key)) continue;
		urlSearchParams.append(key, "");
	} else for (let value of requiredValues) {
		if (urlSearchParams.getAll(key).includes(value)) continue;
		urlSearchParams.append(key, value);
	}
	return urlSearchParams.toString() || void 0;
}
/** Error thrown when a route pattern cannot generate an href from the supplied args. */
var CreateHrefError = class CreateHrefError extends Error {
	details;
	constructor(details) {
		super(CreateHrefError.message(details));
		this.name = "CreateHrefError";
		this.details = details;
	}
	static message(details) {
		if (details.type === "missing-hostname") return `pattern requires hostname\n\nPattern: ${details.pattern}`;
		if (details.type === "nameless-wildcard") return `pattern contains nameless wildcard\n\nPattern: ${details.pattern}`;
		if (details.type === "missing-params") return `missing param(s): ${details.missingParams.map((p) => `'${p}'`).join(", ")}\n\nPattern: ${details.pattern}\nParams: ${JSON.stringify(details.params)}`;
		if (details.type === "invalid-hostname-variable") return `invalid hostname variable param: ${JSON.stringify(details.value)} contains ${JSON.stringify(details.char)}`;
		if (details.type === "invalid-hostname-wildcard") return `invalid hostname wildcard param: ${JSON.stringify(details.value)} contains ${JSON.stringify(details.char)}`;
		if (details.type === "invalid-pathname-variable") return `invalid pathname variable param: '${details.paramName}' cannot be empty\n\nPattern: ${details.pattern}\nValue: ${JSON.stringify(details.value)}`;
		if (details.type === "invalid-pathname-wildcard") return `invalid pathname wildcard param: ${JSON.stringify(details.value)} contains dot segment ${JSON.stringify(details.segment)}`;
		unreachable(details);
	}
};
function encodePathnameVariableParam(pattern, paramName, value) {
	let serialized = String(value);
	if (serialized.length === 0) throw new CreateHrefError({
		type: "invalid-pathname-variable",
		pattern,
		paramName,
		value: serialized
	});
	return encodePathnameVariableSegment(serialized);
}
function encodePathnameWildcard(value) {
	let serialized = String(value);
	return serialized.split("/").map((segment) => {
		if (segment === "." || segment === "..") throw new CreateHrefError({
			type: "invalid-pathname-wildcard",
			value: serialized,
			segment
		});
		return encodePathnameSegment(segment);
	}).join("/");
}
function encodePathnameSegment(value) {
	return encodeURIComponent(value);
}
function encodePathnameVariableSegment(value) {
	return encodePathnameSegment(value).replaceAll(".", "%2E");
}
/**
* Keep hostname params from changing URL authority structure when parsed. `@` ends userinfo,
* `:` starts the port, and `/`, `?`, and `#` start the path, query, and fragment. A backslash
* also starts the path for special URL schemes such as HTTP and HTTPS. Hostname
* variables also reject `.` because dots separate host labels; hostname wildcards allow `.` to
* span labels intentionally.
*
* @see https://url.spec.whatwg.org/#authority-state
* @see https://url.spec.whatwg.org/#host-parsing
*/
var HOSTNAME_PARAM_STRUCTURAL_CHARS = [
	"@",
	":",
	"/",
	"\\",
	"?",
	"#",
	"%"
];
function validateHostnameVariable(value) {
	let serialized = String(value);
	for (let char of serialized) if (char === "." || isInvalidHostnameParamChar(char)) throw new CreateHrefError({
		type: "invalid-hostname-variable",
		value: serialized,
		char
	});
	return serialized;
}
function validateHostnameWildcard(value) {
	let serialized = String(value);
	for (let char of serialized) if (isInvalidHostnameParamChar(char)) throw new CreateHrefError({
		type: "invalid-hostname-wildcard",
		value: serialized,
		char
	});
	return serialized;
}
function isInvalidHostnameParamChar(char) {
	let code = char.charCodeAt(0);
	return code <= 31 || code === 127 || HOSTNAME_PARAM_STRUCTURAL_CHARS.includes(char);
}
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/route-map.js
/**
* A route definition that includes a request method and pattern.
*/
var Route = class {
	/**
	* The HTTP method this route matches.
	*/
	method;
	/**
	* The parsed route-pattern AST. Useful for advanced consumers (e.g. matchers) that want to skip
	* re-parsing the source string.
	*/
	pattern;
	/**
	* @param method The HTTP method this route matches
	* @param pattern The route-pattern source string or pre-parsed AST
	*/
	constructor(method, pattern) {
		this.method = method;
		this.pattern = typeof pattern === "string" ? RoutePattern.parse(pattern) : pattern;
	}
	/**
	* Build a URL href for this route using the given route params and href options.
	*
	* @param args Route params and href options
	* @returns The built URL href
	*/
	href(...args) {
		return createHref(this.pattern, ...args);
	}
};
function createRoutes(baseOrDefs, defs) {
	if (typeof baseOrDefs === "string" || baseOrDefs instanceof RoutePattern) return buildRouteMap(typeof baseOrDefs === "string" ? RoutePattern.parse(baseOrDefs) : baseOrDefs, defs);
	return buildRouteMap(RoutePattern.parse("/"), baseOrDefs);
}
function buildRouteMap(base, defs) {
	let routes = {};
	for (let key in defs) {
		let def = defs[key];
		if (def instanceof Route) routes[key] = new Route(def.method, joinPatterns(base, def.pattern));
		else if (typeof def === "string") routes[key] = new Route("ANY", joinPatterns(base, RoutePattern.parse(def)));
		else if (def instanceof RoutePattern) routes[key] = new Route("ANY", joinPatterns(base, def));
		else if (typeof def === "object" && def != null && "pattern" in def) {
			let defPattern = typeof def.pattern === "string" ? RoutePattern.parse(def.pattern) : def.pattern;
			routes[key] = new Route(def.method ?? "ANY", joinPatterns(base, defPattern));
		} else routes[key] = buildRouteMap(base, def);
	}
	return routes;
}
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/router.js
function noMatchHandler({ url }) {
	return new Response(`Not Found: ${url.pathname}`, { status: 404 });
}
function noMethodMatchHandler({ method }, allowedMethods) {
	return new Response(`Method Not Allowed: ${method}`, {
		status: 405,
		headers: { Allow: allowedMethods.join(", ") }
	});
}
function headResponse(response) {
	if (response.body === null) return response;
	response.body.cancel().catch(() => {});
	return new Response(null, {
		status: response.status,
		statusText: response.statusText,
		headers: response.headers
	});
}
function normalizeMiddleware(middleware) {
	return middleware == null || middleware.length === 0 ? void 0 : [...middleware];
}
function normalizeAction(action) {
	if (isRequestHandler(action)) return {
		handler: action,
		middleware: void 0
	};
	if (!isActionObject(action)) throw new TypeError("Expected a request handler function or action object with a function `handler` property");
	return {
		handler: action.handler,
		middleware: normalizeMiddleware(action.middleware)
	};
}
function mergeMiddleware(upstream, downstream) {
	if (!upstream || upstream.length === 0) return downstream;
	if (!downstream || downstream.length === 0) return upstream;
	return upstream.concat(downstream);
}
function isRouteTarget(target) {
	return typeof target === "string" || target instanceof Route || target instanceof RoutePattern;
}
function createRequestContext(input, init) {
	let request = input instanceof Request && init == null ? input : new Request(input, init);
	if (request.signal.aborted) throw request.signal.reason;
	return new RequestContext(request);
}
function getRoutePattern(target) {
	if (target instanceof Route) return target.pattern;
	if (typeof target === "string") return RoutePattern.parse(target);
	return target;
}
function getMappedRouteMethod(target) {
	return target instanceof Route ? target.method : "ANY";
}
function getPrefixedRoutePattern(target, state) {
	let pattern = getRoutePattern(target);
	return state.prefix ? joinPatterns(state.prefix, pattern) : pattern;
}
/**
* Create a new router.
*
* @param options Options to configure the router
* @returns The new router
*/
function createRouter(options) {
	let defaultHandler = options?.defaultHandler ?? noMatchHandler;
	let matcher = options?.matcher ?? createMultiMatcher();
	let routerMiddleware = normalizeMiddleware(options?.middleware);
	async function dispatchRouter(context) {
		let dispatch = () => dispatchMatches(context);
		if (routerMiddleware) return runMiddleware(routerMiddleware, context, dispatch);
		return dispatch();
	}
	async function dispatchMatches(context) {
		let headFallback = null;
		let allowedMethods = null;
		for (let match of matcher.matchAll(context.url)) {
			if (headFallback !== null && !equal(match, headFallback)) break;
			let route = match.data;
			if (route.method !== context.method && route.method !== "ANY") {
				if (context.method === "HEAD" && route.method === "GET") headFallback ??= match;
				else {
					allowedMethods ??= /* @__PURE__ */ new Set();
					allowedMethods.add(route.method);
				}
				continue;
			}
			return dispatchMatch(match, context);
		}
		if (headFallback !== null) return headResponse(await dispatchMatch(headFallback, context));
		if (allowedMethods !== null) {
			let methods = allowedMethods;
			let allow = RequestMethods.filter((method) => methods.has(method) || method === "HEAD" && methods.has("GET"));
			return raceRequestAbort(Promise.resolve(noMethodMatchHandler(context, allow)), context.request);
		}
		return raceRequestAbort(Promise.resolve(defaultHandler(context)), context.request);
	}
	function dispatchMatch(match, context) {
		let route = match.data;
		context.params = {
			...context.params,
			...match.params
		};
		if (route.middleware) return runMiddleware(route.middleware, context, route.handler);
		return raceRequestAbort(Promise.resolve(route.handler(context)), context.request);
	}
	function registerRoute(method, route, action, state) {
		let pattern = getPrefixedRoutePattern(route, state);
		let entry = {
			pattern,
			handler: action.handler,
			method,
			middleware: action.middleware
		};
		matcher.add(pattern, entry);
	}
	function addRoute(method, route, action, state) {
		registerRoute(method, route, normalizeAction(action), state);
	}
	function mapRoutes(target, handler, state) {
		if (isRouteTarget(target)) {
			mapSingleRoute(target, handler, state);
			return;
		}
		if (!isController(handler)) throw new TypeError("Expected a controller with an object `actions` property");
		mapController(target, handler, state);
	}
	function mapSingleRoute(target, handler, state) {
		registerRoute(getMappedRouteMethod(target), target, normalizeAction(handler), state);
	}
	function mapController(routes, controller, state) {
		let controllerMiddleware = normalizeMiddleware(controller.middleware);
		for (let key in controller.actions) {
			if (!(key in routes)) throw new TypeError(`Unknown action \`${key}\` in controller`);
			if (!(routes[key] instanceof Route)) throw new TypeError(`Cannot map nested route map key \`${key}\` in controller actions; call router.map() for that route map separately`);
		}
		for (let key in routes) {
			let route = routes[key];
			if (route instanceof Route) {
				if (!Object.hasOwn(controller.actions, key)) throw new TypeError(`Missing action \`${key}\` in controller`);
				let action = normalizeAction(controller.actions[key]);
				registerRoute(route.method, route, {
					handler: action.handler,
					middleware: mergeMiddleware(controllerMiddleware, action.middleware)
				}, state);
			}
		}
	}
	function createRouteBuilder(state) {
		function createVerbMethod(method) {
			return (route, action) => {
				addRoute(method, route, action, state);
			};
		}
		return {
			route(method, route, action) {
				addRoute(method, route, action, state);
			},
			map(target, handler) {
				mapRoutes(target, handler, state);
			},
			mount(prefix, installer) {
				let mountPrefix = typeof prefix === "string" ? RoutePattern.parse(prefix) : prefix;
				installer(createRouteBuilder({ prefix: state.prefix ? joinPatterns(state.prefix, mountPrefix) : mountPrefix }));
			},
			get: createVerbMethod("GET"),
			head: createVerbMethod("HEAD"),
			post: createVerbMethod("POST"),
			put: createVerbMethod("PUT"),
			patch: createVerbMethod("PATCH"),
			delete: createVerbMethod("DELETE"),
			options: createVerbMethod("OPTIONS")
		};
	}
	let router = {
		...createRouteBuilder({ prefix: void 0 }),
		fetch(input, ...args) {
			let [init] = args;
			let context = createRequestContext(input, init);
			context.router = router;
			return dispatchRouter(context);
		}
	};
	return router;
}
//#endregion
//#region node_modules/@remix-run/render-middleware/dist/lib/render.js
/**
* Context key used to read the current request renderer with `context.get(Renderer)`.
* Both `render()` and `renderWith()` also install the renderer as `context.render`.
*/
var Renderer = createContextKey();
/**
* Adds a renderer to request context.
*
* @param createRenderer A function that creates a renderer for each request.
* @returns Middleware that stores the renderer in request context.
*/
function renderWith(createRenderer) {
	return (context, next) => {
		context.set(Renderer, createRenderer(context), { property: "render" });
		return next();
	};
}
//#endregion
//#region node_modules/@remix-run/html-template/dist/lib/safe-html.js
var kSafeHtml = Symbol("safeHtml");
function createSafeHtml(value) {
	let s = new String(value);
	s[kSafeHtml] = true;
	return s;
}
/**
* Checks if a value is a {@link SafeHtml} string.
*
* @param value The value to check
* @returns `true` if the value is a {@link SafeHtml} string
*/
function isSafeHtml(value) {
	return typeof value === "object" && value != null && value[kSafeHtml] === true;
}
var escapeRe = /[&<>"']/g;
var escapeMap = {
	"&": "&amp;",
	"<": "&lt;",
	">": "&gt;",
	"\"": "&quot;",
	"'": "&#39;"
};
function escapeHtml(text) {
	return text.replace(escapeRe, (c) => escapeMap[c]);
}
function stringifyInterpolation(value) {
	if (value == null) return "";
	if (Array.isArray(value)) return value.map(stringifyInterpolation).join("");
	if (isSafeHtml(value)) return String(value);
	if (typeof value === "string") return escapeHtml(value);
	if (typeof value === "number" || typeof value === "boolean") return escapeHtml(String(value));
	return escapeHtml(String(value));
}
function stringifyRawInterpolation(value) {
	if (value == null) return "";
	if (Array.isArray(value)) return value.map(stringifyRawInterpolation).join("");
	if (isSafeHtml(value)) return String(value);
	if (typeof value === "string") return value;
	if (typeof value === "number" || typeof value === "boolean") return String(value);
	return String(value);
}
function isTemplateStringsArray(obj) {
	return Array.isArray(obj) && "raw" in obj;
}
function htmlHelper(strings, ...values) {
	if (!isTemplateStringsArray(strings)) throw new TypeError("html must be used as a template tag");
	let out = "";
	for (let i = 0; i < strings.length; i++) {
		out += strings[i];
		if (i < values.length) out += stringifyInterpolation(values[i]);
	}
	return createSafeHtml(out);
}
Object.assign(htmlHelper, { raw(strings, ...values) {
	if (!isTemplateStringsArray(strings)) throw new TypeError("html.raw must be used as a template tag");
	let out = "";
	for (let i = 0; i < strings.length; i++) {
		out += strings[i];
		if (i < values.length) out += stringifyRawInterpolation(values[i]);
	}
	return createSafeHtml(out);
} });
//#endregion
//#region node_modules/@remix-run/response/dist/lib/html.js
var DOCTYPE = "<!DOCTYPE html>";
/**
* Creates an HTML [`Response`](https://developer.mozilla.org/en-US/docs/Web/API/Response)
* that ensures the response has a valid DOCTYPE and appropriate `Content-Type` header.
*
* @param body The body of the response
* @param init The `ResponseInit` object for the response
* @returns A `Response` object with a HTML body and the appropriate `Content-Type` header
*/
function createHtmlResponse(body, init) {
	let payload = ensureDoctype(body);
	let headers = new Headers(init?.headers);
	if (!headers.has("Content-Type")) headers.set("Content-Type", "text/html; charset=UTF-8");
	return new Response(payload, {
		...init,
		headers
	});
}
function ensureDoctype(body) {
	if (isSafeHtml(body)) {
		let str = String(body);
		return startsWithDoctype(str) ? str : DOCTYPE + str;
	}
	if (typeof body === "string") return startsWithDoctype(body) ? body : DOCTYPE + body;
	if (body instanceof Blob) return prependDoctypeToStream(body.stream());
	if (body instanceof ArrayBuffer || ArrayBuffer.isView(body)) {
		let text = new TextDecoder().decode(body);
		return startsWithDoctype(text) ? text : DOCTYPE + text;
	}
	if (body instanceof ReadableStream) return prependDoctypeToStream(body);
	return body;
}
function startsWithDoctype(str) {
	return /^\s*<!doctype html/i.test(str);
}
function prependDoctypeToStream(stream) {
	let doctypeBytes = new TextEncoder().encode(DOCTYPE);
	let reader = stream.getReader();
	return new ReadableStream({ async start(controller) {
		try {
			let firstChunk = await reader.read();
			if (firstChunk.done) {
				controller.enqueue(doctypeBytes);
				controller.close();
				return;
			}
			if (startsWithDoctype(new TextDecoder().decode(firstChunk.value, { stream: true }))) controller.enqueue(firstChunk.value);
			else {
				controller.enqueue(doctypeBytes);
				controller.enqueue(firstChunk.value);
			}
			while (true) {
				let result = await reader.read();
				if (result.done) break;
				controller.enqueue(result.value);
			}
			controller.close();
		} catch (error) {
			controller.error(error);
		}
	} });
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/core/vnode.js
function createRemixElement(type, props, key) {
	return {
		$rmx: true,
		key,
		props: normalizeElementProps(props),
		type
	};
}
function normalizeElementProps(props) {
	if (!props) return {};
	if (!("mix" in props)) return props;
	if (isNormalizedMix(props.mix)) return props;
	let { mix, ...rest } = props;
	let normalizedMix = normalizeMixValue(mix);
	return normalizedMix === void 0 ? rest : {
		...rest,
		mix: normalizedMix
	};
}
function isNormalizedMix(mix) {
	if (!Array.isArray(mix) || mix.length === 0) return false;
	for (let i = 0; i < mix.length; i++) {
		let item = mix[i];
		if (!item || Array.isArray(item)) return false;
	}
	return true;
}
function normalizeMixValue(mix) {
	if (!mix) return void 0;
	let normalizedMix = [];
	flattenMixValue(mix, normalizedMix);
	return normalizedMix.length === 0 ? void 0 : normalizedMix;
}
function flattenMixValue(mix, out) {
	if (!mix) return;
	if (!Array.isArray(mix)) {
		out.push(mix);
		return;
	}
	for (let item of mix) flattenMixValue(item, out);
}
//#endregion
//#region node_modules/@remix-run/component/dist/runtime/jsx.js
function jsx(type, props, key) {
	return createRemixElement(type, props, key);
}
//#endregion
//#region resources/layouts/document.tsx
/** Hands the renderer's looked-up assets to the layout through context. */
function DocumentAssets(handle) {
	handle.context.set(handle.props.value);
	return () => handle.props.children;
}
function DocumentLayout(handle) {
	return () => {
		let { children, hydrates = false, title } = handle.props;
		let { script, stylesheets } = handle.context.get(DocumentAssets);
		return /* @__PURE__ */ jsx("html", {
			lang: "en",
			children: [/* @__PURE__ */ jsx("head", { children: [
				/* @__PURE__ */ jsx("meta", {
					charSet: "utf-8",
					"data-rmx-key": "charset"
				}),
				/* @__PURE__ */ jsx("meta", {
					name: "viewport",
					content: "width=device-width, initial-scale=1",
					"data-rmx-key": "viewport"
				}),
				/* @__PURE__ */ jsx("title", {
					"data-rmx-key": "title",
					children: title
				}),
				stylesheets.map((href) => /* @__PURE__ */ jsx("link", {
					rel: "stylesheet",
					href,
					"data-rmx-key": href
				}, href)),
				hydrates ? /* @__PURE__ */ jsx(Fragment, { children: [/* @__PURE__ */ jsx(ImportMap, { value: script.importMap }), script.preloads.map((href) => /* @__PURE__ */ jsx("link", {
					rel: "modulepreload",
					href,
					"data-rmx-key": href
				}, href))] }) : null
			] }), /* @__PURE__ */ jsx("body", { children: [
				/* @__PURE__ */ jsx("nav", { children: [/* @__PURE__ */ jsx("a", {
					href: "/",
					children: "Home"
				}), /* @__PURE__ */ jsx("a", {
					href: "/about",
					children: "About"
				})] }),
				/* @__PURE__ */ jsx("main", { children }),
				hydrates ? /* @__PURE__ */ jsx("script", {
					type: "module",
					src: script.href
				}) : null
			] })]
		});
	};
}
//#endregion
//#region node_modules/@remix-run/fetch-router/dist/lib/route-helpers/method.js
/**
* Shorthand for a GET route.
*
* @alias get
* @param pattern The route pattern string or pre-parsed AST
* @returns A Route configured for GET requests
*/
function createGetRoute(pattern) {
	return new Route("GET", pattern);
}
//#endregion
//#region routes/web.ts
/** The app's route table. Add a pattern here, then map it in bootstrap/app.tsx. */
var web_default = createRoutes({
	home: createGetRoute("/"),
	about: createGetRoute("/about")
});
//#endregion
//#region app/http/controllers/about.tsx
/** GET /about */
var about_default = createAction(web_default.about, (ctx) => {
	return ctx.render(/* @__PURE__ */ jsx(DocumentLayout, {
		title: "About",
		children: [/* @__PURE__ */ jsx("h1", { children: "About" }), /* @__PURE__ */ jsx("p", { children: "A second route, to show how routes, controllers and the layout fit together." })]
	}));
});
//#endregion
//#region app/http/controllers/default-handler.tsx
/** Renders the 404 page for any URL that matches no route. */
function defaultHandler(ctx) {
	return ctx.render(/* @__PURE__ */ jsx(DocumentLayout, {
		title: "Not found",
		children: [/* @__PURE__ */ jsx("h1", { children: "404" }), /* @__PURE__ */ jsx("p", { children: [
			"Nothing here. ",
			/* @__PURE__ */ jsx("a", {
				href: "/",
				children: "Go home"
			}),
			"."
		] })]
	}), { status: 404 });
}
//#endregion
//#region app/http/controllers/home.tsx
/** GET / */
var home_default = createAction(web_default.home, (ctx) => {
	return ctx.render(/* @__PURE__ */ jsx(DocumentLayout, {
		title: "Remix starter",
		children: [/* @__PURE__ */ jsx("h1", { children: "Remix + Vite + Cloudflare" }), /* @__PURE__ */ jsx("p", { children: [
			"Edit ",
			/* @__PURE__ */ jsx("code", { children: "app/http/controllers/home.tsx" }),
			" and refresh."
		] })]
	}));
});
//#endregion
//#region node_modules/@pitlane/assets/dist/specifier-DLC81sXY.mjs
/**
* Reduces any accepted spelling of a source module to its portable key: the
* slash-separated path from the project root, such as `app/counter.tsx` or,
* for a linked module outside the root, `../shared/widget.ts`.
*
* `./`, a leading `/` (a project-root marker), `file:`, and an `#export`
* fragment are dropped, and dot segments collapse lexically. Returns `null`
* for an absolute file URL, whose meaning depends on the machine that wrote
* it.
*/
function normalizeSourceKey(path) {
	let key = path;
	let fragment = key.indexOf("#");
	if (fragment !== -1) key = key.slice(0, fragment);
	if (key.startsWith("file:")) {
		key = key.slice(5);
		if (key.startsWith("/")) return null;
	}
	let segments = [];
	for (let segment of key.split("/")) {
		if (segment === "" || segment === ".") continue;
		if (segment === ".." && segments.length > 0 && segments.at(-1) !== "..") segments.pop();
		else segments.push(segment);
	}
	return segments.join("/");
}
/**
* Each module of the `pitlane` umbrella adds the package it re-exports to
* this set when it loads, so a package can name itself the way the app
* imports it. An app that installed only `pitlane` cannot import
* `@pitlane/assets/vite-plugin` under a strict package manager.
*/
var UMBRELLA_PACKAGES = Symbol.for("pitlane.umbrella.packages");
/** The specifier the app imports `subpath` of this package by, for error messages. */
function assetsSpecifier(subpath) {
	return `${globalThis[UMBRELLA_PACKAGES]?.has("@pitlane/assets") ? "pitlane/assets" : "@pitlane/assets"}/${subpath}`;
}
/** Quotes and joins names for a message: `"a"`, `"a" and "b"`, `"a", "b", and "c"`. */
function quotedList(names, type) {
	let quoted = names.map((name) => `"${name}"`);
	return new Intl.ListFormat("en", { type }).format(quoted);
}
//#endregion
//#region node_modules/@pitlane/assets/dist/index.mjs
/**
* Constructs the resolver for a manifest, usually the default export of
* `@pitlane/assets/manifest`. Construct it once, in a module of the app's own.
*/
function createAssetResolver(manifest) {
	if (manifest.mode === "unavailable") return unavailableResolver();
	return manifestResolver(manifest);
}
function unavailableResolver() {
	let fail = (method) => async (path) => {
		throw new Error(`${call(method, path)} has no asset manifest to read: ${assetsSpecifier("manifest")} was not supplied by a build integration. Add assets() from ${assetsSpecifier("vite-plugin")} to your Vite config, or pass createAssetResolver() a manifest from createAssetManifest() in ${assetsSpecifier("build")}.`);
	};
	return {
		getScriptEntry: fail("getScriptEntry"),
		getHref: fail("getHref"),
		getPreloads: fail("getPreloads"),
		getStylesheets: fail("getStylesheets"),
		getImportMap: fail("getImportMap")
	};
}
function manifestResolver(manifest) {
	let { environments, entries, assets } = manifest;
	let clientName = Object.keys(environments).find((name) => environments[name].role === "client") ?? "client";
	let stylesheetEnvironments = [.../* @__PURE__ */ new Set([clientName, manifest.serverEnvironment ?? clientName])];
	/** The client graph's metadata for a key, which a registered entry always has. */
	function clientMetadata(key) {
		let metadata = own(environments[clientName]?.modules ?? {}, key);
		if (metadata) return metadata;
		let href = own(entries, key);
		return href === void 0 ? void 0 : {
			preloads: [href],
			stylesheets: []
		};
	}
	function requireClientMetadata(method, path, key) {
		let metadata = clientMetadata(key);
		if (metadata) return metadata;
		throw new Error(`${call(method, path)} found no module "${key}" in the "${clientName}" environment's graph.`);
	}
	function missingRegistration(method, path, key, what) {
		let observedIn = Object.keys(environments).find((name) => Object.hasOwn(environments[name].modules, key));
		let observation = observedIn ? `The module is in the "${observedIn}" graph but is not registered as a browser entry.` : "No environment's graph contains the module.";
		return /* @__PURE__ */ new Error(`${call(method, path)} found no ${what} "${key}" in the "${clientName}" environment. ${observation} Pass the key to ${method}() as a string literal in server code, or list it in assets({ include }) from ${assetsSpecifier("vite-plugin")}.`);
	}
	return {
		async getScriptEntry(path) {
			let key = sourceKey("getScriptEntry", path);
			let href = own(entries, key);
			if (href === void 0) throw missingRegistration("getScriptEntry", path, key, "browser entry");
			if (manifest.mode === "dev") return {
				href,
				preloads: [],
				importMap: { imports: {} }
			};
			return {
				href,
				preloads: [...clientMetadata(key).preloads],
				importMap: copyImportMap(manifest.importMap)
			};
		},
		async getHref(path) {
			let key = sourceKey("getHref", path);
			let href = own(entries, key) ?? own(assets, key);
			if (href === void 0) throw missingRegistration("getHref", path, key, "browser entry or asset");
			return href;
		},
		async getPreloads(paths) {
			let preloads = /* @__PURE__ */ new Set();
			for (let path of asList(paths)) {
				let key = sourceKey("getPreloads", path);
				let stylesheet = own(assets, key);
				if (stylesheet !== void 0 && /\.css(?:[?#]|$)/.test(stylesheet)) {
					preloads.add(stylesheet);
					continue;
				}
				for (let href of requireClientMetadata("getPreloads", path, key).preloads) preloads.add(href);
			}
			return manifest.mode === "dev" ? [] : [...preloads];
		},
		async getStylesheets(paths) {
			let stylesheets = /* @__PURE__ */ new Set();
			for (let path of asList(paths)) {
				let key = sourceKey("getStylesheets", path);
				let found = stylesheetEnvironments.flatMap((name) => {
					let graph = own(environments, name);
					return (graph && own(graph.modules, key)) ?? [];
				});
				if (found.length === 0) throw new Error(`${call("getStylesheets", path)} found no module "${key}" in the ${quotedList(stylesheetEnvironments, "disjunction")} environment's graph.`);
				for (let href of found.flatMap((metadata) => metadata.stylesheets)) stylesheets.add(href);
			}
			return [...stylesheets];
		},
		async getImportMap(paths) {
			let list = asList(paths);
			for (let path of list) requireClientMetadata("getImportMap", path, sourceKey("getImportMap", path));
			if (list.length === 0 || manifest.mode === "dev") return { imports: {} };
			return copyImportMap(manifest.importMap);
		}
	};
}
/** Reads a source key's record without reaching `Object.prototype` members such as `constructor`. */
function own(record, key) {
	return Object.hasOwn(record, key) ? record[key] : void 0;
}
/** Callers merge their own mappings into the returned map; the manifest's stays intact. */
function copyImportMap(map) {
	return structuredClone(map);
}
function sourceKey(method, path) {
	let key = normalizeSourceKey(path);
	if (key !== null) return key;
	throw new Error(`${call(method, path)} received an absolute file URL. Pass the source key relative to the project root instead, such as "file:app/counter.tsx" or "app/counter.tsx".`);
}
function asList(paths) {
	return typeof paths === "string" ? [paths] : paths;
}
/** How a message names the call that failed, such as `assets.getHref("app/logo.svg")`. */
function call(method, path) {
	return `assets.${method}(${JSON.stringify(path)})`;
}
//#endregion
//#region app/lib/assets.ts
var assets = createAssetResolver(manifest);
/** Looks up the hashed CSS and the client entry from the manifest the Vite plugin writes. */
async function documentAssets() {
	let [stylesheets, script] = await Promise.all([assets.getStylesheets("resources/layouts/document.tsx"), assets.getScriptEntry("bootstrap/browser.ts")]);
	return {
		stylesheets,
		script
	};
}
//#endregion
//#region bootstrap/app.tsx
/** Builds the router. Both the worker and any tests call this. */
function application() {
	let router = createRouter({
		middleware: [renderWith(createHtmlRenderer)],
		defaultHandler
	});
	router.map(web_default.home, home_default);
	router.map(web_default.about, about_default);
	return router;
}
/** `ctx.render(<jsx />)`: streams the page and prepends the doctype. */
function createHtmlRenderer() {
	return async function render(node, init) {
		let headers = new Headers(init?.headers);
		headers.set("content-type", "text/html; charset=utf-8");
		return createHtmlResponse(renderToStream(/* @__PURE__ */ jsx(DocumentAssets, {
			value: await documentAssets(),
			children: node
		})), {
			...init,
			headers
		});
	};
}
//#endregion
//#region \0virtual:cloudflare/worker-entry
var worker_entry_default = { async fetch(request) {
	return await application().fetch(request);
} };
//#endregion
export { worker_entry_default as default };
