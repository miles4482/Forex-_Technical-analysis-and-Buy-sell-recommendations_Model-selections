# XAUUSD analysis rules

These are the rules used for the running XAUUSD commentary in this repo. This is market commentary, not personal financial advice. Price levels go stale. The method below does not.

Last updated: **9:36 AM Bangladesh, Monday 26 October 2026**.

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

When the user says **“Please check now”** or **“Please check”**, answer with **one updated table** and the live suggestions. Fetch a new spot quote, `GC=F` contracts, `^TNX`, and `ZN=F`, and read the 5-minute, 15-minute, 30-minute, 1-hour, 2-hour, and 4-hour bars before writing. Use the user’s 4-hour clock. Fill **Buy now**, **Sell now**, and **Confidence** from the closes that actually changed. Share the potential and the scope. Do not repeat a distant zone that price has not reached.

Deliver the check as **one table**. Do not add a second table for the candles. Every row, including the yield rows and each buy or sell setup, carries:

- **5-minute close and condition.** The latest 5-minute close, its tick count, its futures contracts, and the buy-side and sell-side split, plus the close that would trigger that row. A 5-minute close through the planned level is the immediate buy or sell. A quiet bar, under about **1,000** contracts, does not trigger the row. Asia, **3:00 AM–1:00 PM Bangladesh**, can print a thin 5-minute close. The row stays a wait unless the contracts are heavy.
- **15-minute close status.** The latest 15-minute close and whether it has confirmed that row. A 15-minute close on the same side confirms the 5-minute trade. A 15-minute close back through the other side finishes it. The 15-minute close is the lead of the two.
- **Higher timeframe, when required.** Add the 30-minute, 1-hour, and 4-hour close on the same row when that close changes the suggestion. Keep the strong support and resistance in the table and name the timeframe that made each one: 30-minute, 1-hour, 4-hour, or daily, and whether the block is mild or strong. A higher-timeframe close is the structure. The 5-minute close remains the immediate entry.

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
