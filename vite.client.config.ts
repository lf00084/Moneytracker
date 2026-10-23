import { defineConfig } from "vite"
export default defineConfig({
publicDir: false,
build: {
outDir: "app/client/dist",
emptyOutDir: true,
target: "es2022",
minify: true,
lib: { entry: "app/client/entry.ts", formats: ["es"], fileName: () => "entry.js" },
},
})
