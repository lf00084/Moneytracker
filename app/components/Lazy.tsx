import { Frame } from "remix/component"
import { view } from "./view.ts"
export const Skeleton = view<{ lines?: number; title?: string }>(({ lines = 3, title }) => (
<div class="sc skc" aria-busy="true" aria-label="Loading">
{title ? (
<div class="sh">
<span>{title}</span>
</div>
) : (
<div class="sk skt"></div>
)}
{Array.from({ length: lines }, (_, i) => (
<div key={i} class="sk" style={{ width: `${92 - i * 14}%` }}></div>
))}
</div>
))
export const Lazy = view<{ src: string; name?: string; lines?: number; title?: string }>(({ src, name, lines, title }) => <Frame name={name} src={src} fallback={<Skeleton lines={lines} title={title} />} />)
