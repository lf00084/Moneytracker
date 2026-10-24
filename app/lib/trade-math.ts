export const DEPOSIT = 400;
export const BTC_STAKE = 100;
export const PRED_STAKE = 300;
export const BTC_ROUNDS = 4;
export const PRED_COUNT = 3;

export type Game = "btc" | "pred";
export type TradeResult = { id: string; game: Game; idx: number; won: boolean; pnl: number };
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

export const btcOf = (r: TradeResult[]) => r.filter((x) => x.game === "btc").sort((a, b) => a.idx - b.idx);
export const predOf = (r: TradeResult[]) => r.filter((x) => x.game === "pred").sort((a, b) => a.idx - b.idx);
export const btcLost = (r: TradeResult[]) => btcOf(r).some((x) => !x.won);
export const btcDone = (r: TradeResult[]) => btcLost(r) || btcOf(r).length >= BTC_ROUNDS;
export const predDone = (r: TradeResult[]) => predOf(r).length >= PRED_COUNT;
export const allDone = (r: TradeResult[]) => btcDone(r) && predDone(r);
export const totalPnl = (r: TradeResult[]) => r.reduce((a, x) => a + x.pnl, 0);
export const backUsdt = (deposit: number, pnl: number) => Math.max(0, deposit + pnl);
export const toMad = (usdtMinor: number, rateMinor: number) => Math.round((usdtMinor * rateMinor) / 100);
export const strip = (r: TradeResult[]) => r.map((x) => (x.won ? "W" : "L")).join(" ");
