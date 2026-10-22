import * as base from "remix/component/jsx-runtime"
export type { JSX } from "remix/component/jsx-runtime"
const b = base as any
const wrap = (f: any) => (type: any, props: any, ...rest: any[]) => (typeof type === "function" ? type(props) : f(type, props, ...rest))
export const Fragment = b.Fragment
export const jsx = wrap(b.jsx)
export const jsxs = wrap(b.jsxs ?? b.jsx)
export const jsxDEV = wrap(b.jsxDEV ?? b.jsx)
