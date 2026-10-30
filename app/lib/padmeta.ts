export const COLORS = ["#2f6f78", "#6a4fd1", "#8a5a00", "#b4435a", "#3b6fd1", "#4b5563"]
export const TYPES = ["mix", "notes", "tasks"] as const

export type Space = { id: string; title: string; color: string; type: string; bar: boolean }
export type Entry = { id: string; space: string; kind: string; body: string; who: string; tag: string; today: boolean; at: number }
export type PadData = { spaces: Space[]; space: Space | null; entries: Entry[]; done: boolean }
