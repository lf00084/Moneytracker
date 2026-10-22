const enc = new TextEncoder()
const html = (body: BodyInit, init: ResponseInit) => {
const headers = new Headers(init.headers)
headers.set("Content-Type", "text/html; charset=utf-8")
return new Response(body, { ...init, headers })
}
export async function render(node: unknown, init: ResponseInit = {}) {
const m: any = await import("remix/component/server")
if (typeof m.renderToStream === "function") {
const reader = m.renderToStream(node).getReader()
const body = new ReadableStream<Uint8Array>({
async start(c) {
try {
c.enqueue(enc.encode("<!DOCTYPE html>"))
for (;;) {
const { done, value } = await reader.read()
if (done) break
c.enqueue(typeof value === "string" ? enc.encode(value) : value)
}
c.close()
} catch (e) {
c.error(e)
}
},
})
return html(body, init)
}
if (typeof m.renderToString === "function") return html("<!DOCTYPE html>" + (await m.renderToString(node)), init)
throw new Error("remix/component/server exports neither renderToStream nor renderToString")
}
