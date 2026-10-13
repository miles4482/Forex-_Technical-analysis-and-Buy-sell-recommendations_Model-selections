# XAUUSD analysis rules

These are the rules used for the running XAUUSD commentary in this repo. This is market commentary, not personal financial advice. Price levels go stale. The method below does not.

Last updated: **2:08 AM New York, Tuesday 13 October 2026**.

## How a candle is read

- Candle times are the **New York close** (`America/New_York`). In October, New York is EDT (UTC−4).
- Yahoo Finance bars are stamped at the **bar start**. A 15-minute bar stamped 1:45 closed at 2:00. Name the candle by the close.
- A flat, zero-range last bar is an unfinished stub. Ignore it. A bar that already has a real range and has not reached its close time is still forming. Do not treat it as closed.
- A wick is not a trigger. Buy and sell levels need a **close** through the level.
- When a 15-minute candle and an hourly candle close together, the hour is the lead candle. The 15-minute candle is the entry check.
- 4-hour candles close at 01:00, 05:00, 09:00, 13:00, 17:00, and 21:00 UTC. In EDT that is **9:00 PM, 1:00 AM, 5:00 AM, 9:00 AM, 1:00 PM, and 5:00 PM** New York.

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

Set at the **2:00 AM New York** close on Tuesday 13 October 2026. Spot was about 4194. The 10-year note was 104.88, above 104.70.

The 1:00 AM 4-hour candle had closed up at about 4198, above 4180. The 2:00 AM hour then failed at 4200 and held 4190. Direction is up. This is the dip buy, not the breakout.

| Trade | Rule |
|---|---|
| Buy | **4194**, the 15-minute close back above 4190 |
| Stop | **4178** |
| Targets | **4200**, then **4219** |
| Breakout, if not already in | A later 15-minute close above **4200**. Stop **4190**. Target **4219**. |
| Note | The buy stays valid while `ZN=F` holds above **104.70**. |

Cancel the dip buy if a 15-minute candle closes under **4178**. Do not sell 4194 while the note is above 104.70 and the 4-hour close is above 4180.
