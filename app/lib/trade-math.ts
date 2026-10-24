export const DEPOSIT = 400;
export const BTC_STAKE = 100;
export const PRED_STAKE = 300;
export const BTC_ROUNDS = 4;
export const PRED_COUNT = 3;
export const PICKS: [string, number][] = [
	["BTC", 5],
	["BTC", 15],
	["ETH", 5],
	["ETH", 15],
];

export type Game = "btc" | "pred";
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number; state: "set" | "done"; asset: string; tf: number };
export type TradeSession = {
	id: string;
	day: string;
	deposit: number;
	rate: number;
	status: "open" | "settled";
	pnl: number;
	returnUsdt: number;
	returnMad: number;
	at: number;
	results: TradeResult[];
};

export const isDone = (x: TradeResult) => x.state === "done";
export const doneOf = (r: TradeResult[]) => r.filter(isDone);
export const btcOf = (r: TradeResult[]) => r.filter((x) => x.game === "btc").sort((a, b) => a.idx - b.idx);
export const predOf = (r: TradeResult[]) => r.filter((x) => x.game === "pred").sort((a, b) => a.idx - b.idx);
export const btcLost = (r: TradeResult[]) => btcOf(r).some((x) => isDone(x) && !x.won);
export const btcDone = (r: TradeResult[]) => btcLost(r) || doneOf(btcOf(r)).length >= BTC_ROUNDS;
export const predDone = (r: TradeResult[]) => doneOf(predOf(r)).length >= PRED_COUNT;
export const allDone = (r: TradeResult[]) => btcDone(r) && predDone(r);
export const totalPnl = (r: TradeResult[]) => doneOf(r).reduce((a, x) => a + x.pnl, 0);
export const missAmount = (game: Game, r: TradeResult[]) => (game === "btc" ? BTC_STAKE + doneOf(btcOf(r)).reduce((a, x) => a + x.pnl, 0) : PRED_STAKE / PRED_COUNT);
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl);
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100);
export const strip = (r: TradeResult[]) => doneOf(r).map((x) => (x.won ? "W" : "M")).join(" ");
