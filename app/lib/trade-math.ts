export const FIVE = 1600
export const GAME = 400
export const GAMES = 2
export const DEPOSIT = FIVE + GAME * GAMES
export const TRIES = 2

export type GameKey = "ga" | "gb"
export type Game = "step" | "res" | GameKey
export type Kind = "won" | "lost" | "miss" | "skip"
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number; state: "set" | "done"; asset: string; tf: number }
export type TradeSession = {
	id: string
	day: string
	deposit: number
	rate: number
	status: "open" | "settled"
	pnl: number
	returnUsdt: number
	returnMad: number
	at: number
	results: TradeResult[]
}

export type Flow = {
	tryNo: number
	base: number
	left: number
	stakes: number[]
	won: boolean
	over: boolean
	stop: boolean
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const resOf = (r: TradeResult[]) => r.filter((x) => x.game === "res" && isDone(x)).sort((a, b) => a.idx - b.idx)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const kindOf = (x: TradeResult): Kind => (x.asset === "skip" ? "skip" : x.won ? "won" : x.tf <= 0 || 0 - x.pnl >= x.tf ? "miss" : "lost")
export const letter = (x: TradeResult) => ({ won: "W", lost: "L", miss: "M", skip: "S" })[kindOf(x)]
export const word = (x: TradeResult) => ({ won: "Won", lost: "Lost", miss: "Miss", skip: "Skipped" })[kindOf(x)]
export const hasGames = (deposit: number) => deposit > FIVE
export const gameOf = (r: TradeResult[], g: GameKey) => r.find((x) => x.game === g && isDone(x))
export const gamesDone = (r: TradeResult[]) => !!gameOf(r, "ga") && !!gameOf(r, "gb")
export const gamesStrip = (r: TradeResult[]) => (["ga", "gb"] as const).map((g) => { const x = gameOf(r, g); return x ? letter(x) : "-" }).join(" ")

export const stakesFor = (base: number) => {
	const a = Math.round(base / 4)
	return [a, a, base - 2 * a]
}

export function flowOf(deposit: number, rows: TradeResult[]): Flow {
	const res = resOf(rows)
	const won = res.some((x) => x.won)
	const left = Math.min(deposit, FIVE) + res.reduce((a, x) => a + x.pnl, 0)
	const over = won || res.length >= TRIES || (res.length > 0 && left <= 0)
	const tryNo = Math.min(res.length + 1, TRIES)
	return {
		tryNo,
		base: left,
		left,
		stakes: stakesFor(left),
		won,
		over,
		stop: over && !won,
	}
}

export const allDone = (deposit: number, rows: TradeResult[]) => flowOf(deposit, rows).over && (!hasGames(deposit) || gamesDone(rows))
