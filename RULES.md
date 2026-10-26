# XAUUSD analysis rules

These are the rules used for the running XAUUSD commentary in this repo. This is market commentary, not personal financial advice. Price levels go stale. The method below does not.

Last updated: **2:19 PM Bangladesh, Monday 26 October 2026**.

## How a candle is read

- Candle times are the **New York close** (`America/New_York`). In October, New York is EDT (UTC−4).
- Yahoo Finance bars are stamped at the **bar start**. A 15-minute bar stamped 1:45 closed at 2:00. Name the candle by the close.
- A flat, zero-range last bar is an unfinished stub. Ignore it. A bar that already has a real range and has not reached its close time is still forming. Do not treat it as closed.
- A wick is not a trigger. Buy and sell levels need a **close** through the level.
- The **5-minute close** is the immediate decision. The **15-minute close** confirms it. When a 15-minute candle and an hourly candle close together, the hour is the lead candle.
- The check is adaptive. Read the **5-minute**, **15-minute**, **30-minute**, **1-hour**, **2-hour**, and **4-hour** candles, and the **daily** when price is inside a daily range or near a daily block. Report the timeframes that change the trade. A quiet higher-timeframe candle with nothing at a level does not need its own row.
- The user’s 4-hour clock is the one used for calls. In Bangladesh those candles change at **3:00 AM, 7:00 AM, 11:00 AM, 3:00 PM, 7:00 PM, and 11:00 PM**. The live biquote feed is one hour earlier, at 2:00, 6:00, 10:00, 2:00 PM, 6:00 PM, and 10:00 PM. Name a feed candle by its own time, and do not call that the user’s 4-hour close.

## Price feeds

- Quote spot from gold-api and Swissquote. If they disagree by more than about a dollar, quote both.
- Do not call a level “closed through” when the two spot feeds straddle it.
- COMEX gold futures (`GC=F`) are converted to spot with the **live** basis only: futures minus the current spot. Do not remap an older high or low with a new basis. Basis moves by many dollars during a session.
- Do not put on a full position at the price being printed. The entry is a close, a hold, or a planned pullback.

## 10-year yield and the note future

Every gold call is checked against both:

| Instrument | What it is |
|---|---|
| `ZN=F` | 10-year Treasury note future. On TradingView: `ZN1!` or `CBOT:ZN1!`. |
| `^TNX` | 10-year cash yield, in percent. A print of 5.24 means 5.24%. |

- Note price up means yield down, and that supports gold. Note price down means yield up, and that pressures gold.
- The cash yield and the note must agree before a call is treated as confirmed. One of them is not enough.
- Cash `^TNX` prints in the New York session, about **8:30 AM to 3:00 PM** New York. Outside that window the cash number is frozen. `ZN=F` is the live yield.

## What “a candle holds” means

A pullback to a level **holds** when the 15-minute candle closes back on the safe side of that level.

- For a dip buy at 4190, price may trade under 4190 during the candle. The buy is a **close back above 4190**.
- A close under 4190 did not hold. No buy.

## Tick count, contracts, and order flow

Every check includes the latest **closed 5-minute** bar and the latest **closed 15-minute** bar, plus the regular checkpoints (real yield, expected inflation, `^TNX`, `ZN=F`, the dollar, and the strong or mild order block).

| Field | What to read |
|---|---|
| Tick count | Spot `tickVolume` on that candle. The spot `volume` field stays 0. |
| Contracts | COMEX gold futures `GC=F` volume for the same candle. One contract is 100 ounces. |
| Tick size | Spot **$0.01**. Futures **$0.10**, worth **$10** per contract. |
| Order flow | Buy-side contracts = contracts × (close − low) / (high − low). Sell-side contracts are the rest. |

Friday 23 October is the size benchmark. A quiet 5-minute bar was about **500–1,000** contracts. A bar that carried a decision was above **2,000** contracts. The fall itself was above **5,000** contracts. A side leads when it is about three times the other side, or more than **75%** of the bar.

When the user says **“Please check now”** or **“Please check”**, answer with **three tables**, in this order. Fetch a new spot quote, `GC=F` contracts, `^TNX`, `ZN=F`, and the dollar, and read the 5-minute, 15-minute, 30-minute, 1-hour, 2-hour, and 4-hour bars before writing. Use the user’s 4-hour clock. Fill **Buy now**, **Sell now**, and **Confidence** from the closes that actually changed. Share the potential and the scope. Do not repeat a distant zone that price has not reached. Every condition states the futures **contract** count that confirms it, or a note gives the latest printed contract count when that bar has no print yet. Buy-side or sell-side leading is not a condition without the contract number. The major-highlights row names the **Bangladesh time** of that bar and the time of the check.

**Table 1, parameters, comes first and keeps this column order:** **Parameter**, **Status**, **Value**, **Previous Day**, **Yesterday**, **Line**, **Gold**. The rows are real yield, expected inflation, the 10-year yield, the note future, and the dollar. Status is **Open**, **Frozen**, or **Fixed for the last day**. The lines are **5.22%** for the 10-year yield, **105.17** for the note future, and the last daily dollar close for the dollar. Real yield and expected inflation are the last daily Treasury posts and have no intraday line. For a daily post, **Yesterday** is the prior post and **Previous Day** is the post before that. For the note and the dollar, **Yesterday** is the last daily close and **Previous Day** is the close before that. Do not change this table’s columns.

The **Gold** column is one of five grades. The change versus yesterday sets the grade. The line is the other consideration: a break through the line the wrong way makes the grade **Strong pressure**, and a hold of the line stops a large adverse day from being read on its own.

| Grade | 10-year yield and real yield | Expected inflation | Note future | Dollar |
|---|---|---|---|---|
| **Strong support** | Down more than **5 bp**, and the 10-year is under **5.22%** | Up more than **5 bp** | Up more than **0.25**, and above **105.17** | Down more than **0.30** |
| **Mild support** | Down **1–5 bp**, and the 10-year is under **5.22%** | Up **1–5 bp** | Up **0.03–0.25**, and above **105.17** | Down **0.05–0.30** |
| **Neutral** | Change under **1 bp**, and the 10-year is under **5.22%** | Change under **1 bp** | Change under **0.03**, and above **105.17** | Change under **0.05** |
| **Mild pressure** | Up **1–5 bp**, while the 10-year is under **5.22%** | Down **1–5 bp** | Down **0.03–0.25**, while above **105.17** | Up **0.05–0.30** |
| **Strong pressure** | Up more than **5 bp**, or the 10-year is above **5.22%** | Down more than **5 bp** | Down more than **0.25**, or below **105.17** | Up more than **0.30** |

A higher real yield pressures gold. A higher 10-year yield pressures gold. A higher note price supports gold. A higher dollar pressures gold. Higher expected inflation supports gold.

**Table 2 is the buy plan. Table 3 is the sell plan.** Each uses two columns only, **Plan** and **Detail**, so Detail has the width on a phone. The contract grade is the last words of the Detail cell: **Contracts: Strong**, **Mild**, **Neutral**, or **No**, from the futures count and the buy-side or sell-side split on that row. Every row that has a candle or a trade condition states the order flow where a print exists: the contract count, the buy-side contracts, and the sell-side contracts. A buy-side or sell-side lead is not stated without those three numbers. Every row that has a contract count also states the order flow: the buy-side contracts and the sell-side contracts. A row with no printed contracts says the print is not out. Do not add a third column. Do not repeat Real yield, Expected inflation, 10-year yield, Note future, or Dollar in these tables. Those grades stay in Table 1.

Rows, in order: **Scope now**, **Entry**, **Confirmation**, **Stop**, **Targets**, **5-minute**, **15-minute**, **30-minute**, **1-hour**, **2-hour**, **4-hour**, **Supports**, **Resistances**, **+OB**, **−OB**, **Confidence**, **Major highlights**. The **+OB** and **−OB** rows name every timeframe that has a block: 5-minute, 15-minute, 30-minute, 1-hour, 2-hour, 4-hour, and daily. Say whether it is mild or strong. A timeframe with no block of its own is left out. Supports and resistances name the strong level, the mild level, the low level, and the daily, weekly, and monthly level, with the range and the timeframe. Confidence is stated against the price where the suggestion applies. Major highlights carry the Bangladesh time, the contract count, and the flow. The candle rows carry:

- **5-minute close and condition.** The latest 5-minute close, its tick count, its futures contracts, and the buy-side and sell-side split, plus the close that would trigger that row. A 5-minute close through the planned level is the immediate buy or sell. A quiet bar, under about **1,000** contracts, does not trigger the row. Asia, **3:00 AM–1:00 PM Bangladesh**, can print a thin 5-minute close. The row stays a wait unless the contracts are heavy.
- **15-minute close status.** The latest 15-minute close and whether it has confirmed that row. A 15-minute close on the same side confirms the 5-minute trade. A 15-minute close back through the other side finishes it. The 15-minute close is the lead of the two.
- **Higher timeframe, when required.** Add the 30-minute, 1-hour, 2-hour, and 4-hour close on the same row when that close changes the suggestion. Keep the strong support and resistance in the table and name the timeframe that made each one: 30-minute, 1-hour, 2-hour, 4-hour, or daily, and whether the block is mild or strong. A higher-timeframe close is the structure. The 5-minute close remains the immediate entry.
- **Closed higher-timeframe contracts.** When a 30-minute, 1-hour, 2-hour, or 4-hour candle has closed, the buy table and the sell table carry that candle’s futures contract count and the buy-side and sell-side split. Sum the `GC=F` 5-minute bars inside the candle. The 4-hour uses the Bangladesh clock and closes at **3:00, 7:00, 11:00, 15:00, 19:00, and 23:00**. The 2-hour on that same clock closes at **1:00, 3:00, 5:00, 7:00, 9:00, 11:00, 13:00, 15:00, 17:00, 19:00, 21:00, and 23:00**. The 30-minute and 1-hour close on the Bangladesh clock. A higher-timeframe close still needs more than **2,000** contracts before it confirms a buy or a sell. The summary names each closed candle, its Bangladesh close time, and its contract count.

## One plan

Use one working plan: direction, the entry, the stop, and the targets. Do not publish a menu of dip buy, deeper dip, strong buy, tactical sell, and strong sell in the same update unless that menu is explicitly requested.

## Session clock

Bangladesh is UTC+6, with no daylight saving. In October:

| Session | Bangladesh time |
|---|---|
| Forex open | 3:00 AM Monday |
| Tokyo | 6:00 AM–3:00 PM |
| London | 1:00 PM–10:00 PM, while London is on BST (UTC+1) |
| New York | 6:00 PM–3:00 AM |
| London and New York overlap | 6:00 PM–10:00 PM |

Asia before London is thin. A level can break and fail there.

## Plan in force

Set from the Friday 23 October 2026 close for Monday 26 October. Spot closed **3996.2**. Futures `GC=F` closed **4007.9**. The cash 10-year yield was **4.988%**, under **5.22%**. The note future was **106.16**, above **105.17**. Those two agree, so the buy is at demand. Real yield was **2.66%**. Expected inflation was **2.34%**. The dollar closed **101.81**.

There is no trade at **3996**. Price sits between **3987** and **4002**.

| Trade | Rule |
|---|---|
| Buy | **3982–3987**, Strong +OB, daily and 4-hour. A 5-minute close back above **3982** is the immediate buy. The 15-minute close back above **3982** confirms it. |
| Confidence | **70%** |
| Stop | A 15-minute close under **3975.5** |
| Targets | **4002**, then **4012** |
| Order flow | Buy-side contracts larger than sell-side, on a bar above **2,000** contracts |
| Sell | **4024–4032**, Mild −OB, 15-minute and 4-hour. A 5-minute close back under **4024** is the immediate sell. The 15-minute close confirms it. |
| Confidence | **55%** |
| Stop | A 15-minute close above **4034.2** |
| Targets | **4012**, then **4002** |
| Note | The buy stays valid while `ZN=F` holds above **105.17** and `^TNX` holds under **5.22%**. |

The nearer supply at **4002–4006** is a **50%** sell only after a 5-minute, then 15-minute, close back under **4002**. A 15-minute close under **3975.5** cancels the 3982 buy and hands the plan to the deeper Strong +OB at **3943–3959**.

## MetaTrader 5 robot

The robot is `mt5/XAUUSD_Rules_EA.mq5`. It applies this method on an XAUUSD chart. A trade needs a 5-minute close back through the block, a 15-minute close on the same side, and order flow leading on that 5-minute bar. A wick does not open a trade. Higher-timeframe support, resistance, and order blocks gate that trade. A buy inside a 30-minute or higher sell block waits. A sell inside a 30-minute or higher buy block waits. A 1-hour, 2-hour, 4-hour, or daily close through the cancel keeps the trade off. A strong 4-hour, daily, weekly, or monthly level within **6** dollars blocks a trade into it. The first target is the nearer of the plan target and that higher-timeframe level. The order-flow split is the one in the checks: buy side is volume × (close − low) / (high − low), and the sell side is the rest. A side leads at **75%** of the bar. The robot holds one position. The default lot is **0.01**. There is no grid and no adding to a loser.

Install it on the computer where MetaTrader 5 is installed:

1. In MetaTrader 5 open **File → Open Data Folder → MQL5 → Experts**.
2. Copy `XAUUSD_Rules_EA.mq5` into that Experts folder.
3. Open the file in MetaEditor and press **Compile**. The result needs **0 errors**.
4. Open **XAUUSD** and set the chart to **M5**.
5. Drag **XAUUSD rules robot** onto the chart.
6. Turn on **Algo Trading**.
7. Run it on a **demo** account first.

The chart comment shows **Buy now**, **Sell now**, the last 5-minute and 15-minute flow, the 1-hour, 2-hour, 4-hour, and daily closes, the nearest supports and resistances, and the higher-timeframe **+OB** and **−OB** rows. Blue rectangles are buy blocks. Red rectangles are sell blocks. The darker color is the strong block. Dotted lines are strong 4-hour, daily, weekly, and monthly support and resistance.

The default prices are the **26 October 2026** plan. They go stale. Change them in the inputs when a newer check replaces them.

| Block | Entry | 15-minute cancel | Targets | Default |
|---|---|---|---|---|
| Strong +OB **3982–3987** | 5-minute and 15-minute close back above **3982** | close under **3975.5** | **4002**, then **4012** | On, while the 15-minute close is above **3975.5** |
| Strong +OB **3943–3959** | close back above **3943** | close under **3936.5** | **3975**, then **3982** | On after a 15-minute close under **3975.5** |
| Mild −OB **4024–4032** | close back under **4024** | close above **4034.2** | **4012**, then **4002** | On |
| Shelf **4002–4006** | close back under **4002** | close above **4006.5** | **3987**, then **3982** | On, half size |
| Mild +OB **4003–4007** | close back above **4003** | close under **3998** | **4012** | Drawn. Trades when **Trade mild blocks** is on |
| Mild −OB **4009–4012** | close back under **4009** | close above **4013** | **4003** | Drawn. Trades when **Trade mild blocks** is on |
| Mild −OB **4015–4019** | close back under **4015** | close above **4022** | **4009** | Drawn. Trades when **Trade mild blocks** is on |
| Strong −OB **4088–4103** | close back under **4088** | close above **4110** | **4034**, then **4024** | On |

On a spot chart the bar volume is **broker ticks**. The **1,000 / 2,000 / 5,000** lines are COMEX `GC=F` contract counts. Leave **Volume is COMEX contracts** off on spot, and leave **Also accept a bar that is large versus its average** on. A decision bar is then **1.5×** the average of the last 20 closed bars of that timeframe. From **03:00 to 13:00 Bangladesh** the bar needs **2.5×** that average. Turn **Volume is COMEX contracts** on when the symbol is a futures contract. The 1,000, 2,000, and 5,000 lines then apply, and a quiet bar under 1,000 does not trade.

The plan stop is a **15-minute close** through the cancel price. The robot waits for that close. An emergency broker stop sits **15** dollars beyond the cancel. Turn on **Broker stop on the cancel price** when the exit should be a touch of that price.

The 4-hour clock in this plan closes at **03:00, 07:00, 11:00, 15:00, 19:00, and 23:00 Bangladesh**. The chart’s own 4-hour bars match that clock when the broker server is **UTC+3**. The comment says when they do not. Entries still use the 5-minute and 15-minute closes. Set **Broker server UTC offset** to the server’s offset.

The parameters table stays outside the robot. The buy plan still wants the note future above **105.17** and the 10-year yield under **5.22%**. A reclaim that closed before the robot was attached is left alone. The next fresh reclaim can trade.

Detected blocks are drawn from the 15-minute, 30-minute, 1-hour, 2-hour, 4-hour, and daily bars. A detected 1-hour or higher block gates a trade even while **Trade a detected block** is off. It trades after that input is turned on. A detected buy is a close back above the block. A detected sell is a close back under the block. A block the plan already has is kept as the plan block. The plan support **3975.5** and the plan resistance **4034.2** are inputs, with the weekly and monthly highs and lows taken from the chart.
