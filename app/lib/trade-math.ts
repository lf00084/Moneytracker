export const DEPOSIT = 1600
export const TRIES = 2
export const PARTS = 3

export type Game = "step" | "res"
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
	steps: TradeResult[]
	staked: number
	won: boolean
	over: boolean
}

export const isDone = (x: TradeResult) => x.state === "done"
export const doneOf = (r: TradeResult[]) => r.filter(isDone)
export const resOf = (r: TradeResult[]) => r.filter((x) => x.game === "res" && isDone(x)).sort((a, b) => a.idx - b.idx)
export const stepsOf = (r: TradeResult[], t: number) => r.filter((x) => x.game === "step" && Math.ceil(x.idx / PARTS) === t).sort((a, b) => a.idx - b.idx)
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0)
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl)
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100)
export const strip = (r: TradeResult[]) => doneOf(r).map((x) => (x.won ? "W" : "M")).join(" ")

export const stakesFor = (base: number) => {
	const a = Math.round(base / 4)
	return [a, a, base - 2 * a]
}

export function flowOf(deposit: number, rows: TradeResult[]): Flow {
	const res = resOf(rows)
	const won = res.some((x) => x.won)
	const left = deposit + res.reduce((a, x) => a + x.pnl, 0)
	const over = won || res.length >= TRIES || (res.length > 0 && left <= 0)
	const tryNo = Math.min(res.length + 1, TRIES)
	const steps = stepsOf(rows, tryNo)
	return {
		tryNo,
		base: left,
		left,
		stakes: stakesFor(left),
		steps,
		staked: steps.reduce((a, x) => a + x.tf, 0),
		won,
		over,
	}
}
