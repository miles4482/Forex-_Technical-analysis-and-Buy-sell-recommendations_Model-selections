//+------------------------------------------------------------------+
//|                                             XAUUSD_Rules_EA.mq5 |
//| XAUUSD rules robot for MetaTrader 5.                            |
//|                                                                  |
//| This expert applies the written XAUUSD method. It is not a chat  |
//| model and it does not connect to one.                            |
//|                                                                  |
//| Install                                                           |
//| 1. In MetaTrader 5 open File -> Open Data Folder -> MQL5/Experts.|
//| 2. Copy this file into that Experts folder.                      |
//| 3. Open it in MetaEditor and press Compile. Result: 0 errors.    |
//| 4. Open XAUUSD and set the chart to M5.                          |
//| 5. Drag XAUUSD rules robot onto the chart.                       |
//| 6. Turn on Algo Trading. Start on a demo account.                |
//|                                                                  |
//| What it waits for                                                 |
//| A 5-minute close back through the block, then a 15-minute close  |
//| on the same side. A wick is not an entry. The signal bar must    |
//| lead on order flow (75% or more on that side) and must clear the |
//| volume line. One position. No grid and no martingale.            |
//|                                                                  |
//| Volume                                                            |
//| On spot XAUUSD the bar volume is broker ticks, not COMEX         |
//| contracts. The 1,000 / 2,000 / 5,000 lines are GC=F contract     |
//| counts. Leave "Volume is contracts" off on a spot chart and keep |
//| relative volume on. Turn it on only on a futures symbol.         |
//|                                                                  |
//| Clock                                                             |
//| The 4-hour clock used by the plan closes at 03:00, 07:00, 11:00, |
//| 15:00, 19:00, and 23:00 Bangladesh. That matches native H2/H4    |
//| when the broker server is UTC+3. The chart comment warns you     |
//| when it does not. Entries still use the 5-minute and 15-minute   |
//| closes.                                                           |
//|                                                                  |
//| Higher timeframe                                                  |
//| A 30-minute or higher block, and 4-hour, daily, weekly, and      |
//| monthly support and resistance, gate the trade. A buy inside a   |
//| higher-timeframe sell block waits. A sell inside a higher-       |
//| timeframe buy block waits. A 1-hour, 2-hour, 4-hour, or daily    |
//| close through the cancel keeps the trade off. The first target   |
//| is the nearer higher-timeframe level.                            |
//|                                                                  |
//| Default blocks are the 26 October 2026 plan. They go stale.      |
//| Edit the inputs when a newer check replaces them.                |
//+------------------------------------------------------------------+
#property copyright "XAUUSD rules"
#property version   "1.00"
#property description "XAUUSD rules robot. 5-minute close, 15-minute close, order flow, order blocks."
#property description "Not a chat model. Attach to XAUUSD on M5. Demo first. Default lot 0.01. One position."
#property description "Spot volume is broker ticks, not COMEX contracts, unless Volume is contracts is on."

#include <Trade\Trade.mqh>

//====================================================================
// Inputs
//====================================================================
input group "Main"
input bool   InpAllowNewTrades = true;       // Allow new trades
input ulong  InpMagic          = 261026;     // Magic number
input double InpLots           = 0.01;       // Lot size
input int    InpSlippagePoints = 50;         // Slippage, points
input double InpMaxSpread      = 0.50;       // Max spread, price
input bool   InpAllowAnySymbol = false;      // Allow a symbol that is not XAU or GOLD

input group "Volume and order flow"
input bool   InpVolumeIsContracts   = false; // Volume is COMEX contracts (off = broker ticks)
input bool   InpUseRelativeVolume   = true;  // Also accept a bar that is large versus its average
input double InpMinVolume           = 1000;  // Quiet line when volume is contracts, or when relative volume is off
input double InpDecisionVolume      = 2000;  // Decision line when volume is contracts, or when relative volume is off
input double InpHeavyVolume         = 5000;  // Heavy line when volume is contracts, or when relative volume is off
input double InpRelativeMultiple    = 1.5;   // Decision bar versus the last 20 closed bars
input double InpAsiaRelativeMultiple= 2.5;   // Asia session bar versus that average
input bool   InpAsiaNeedsHeavy      = true;  // Asia 03:00-13:00 Bangladesh needs a heavy bar
input int    InpFlowLeadPercent     = 75;    // Side leads at this percent of the bar

input group "Manual buy 3982-3987"
input bool   InpTradeBuy1      = true;       // Trade the strong 3982 buy
input double InpBuy1Low        = 3982.0;     // Zone low
input double InpBuy1High       = 3987.0;     // Zone high
input double InpBuy1Entry      = 3982.0;     // 5m and 15m close back above
input double InpBuy1Stop       = 3975.5;     // 15m close under this cancels
input double InpBuy1Tp         = 4002.0;     // First target
input double InpBuy1Tp2        = 4012.0;     // Second target
input double InpBuy1ArmAbove   = 3975.5;     // This buy is on only while the 15m close is above

input group "Manual buy 3943-3959"
input bool   InpTradeBuy2      = true;       // Trade the deeper strong buy after 3975.5 breaks
input double InpBuy2Low        = 3943.0;
input double InpBuy2High       = 3959.0;
input double InpBuy2Entry      = 3943.0;     // 5m and 15m close back above
input double InpBuy2Stop       = 3936.5;
input double InpBuy2Tp         = 3975.0;
input double InpBuy2Tp2        = 3982.0;
input double InpBuy2ArmBelow   = 3975.5;     // On only after a 15m close under this

input group "Manual sell 4024-4032"
input bool   InpTradeSell1     = true;       // Trade the 4024 sell
input double InpSell1Low       = 4024.0;
input double InpSell1High      = 4032.0;
input double InpSell1Entry     = 4024.0;     // 5m and 15m close back under
input double InpSell1Stop      = 4034.2;     // 15m close above this cancels
input double InpSell1Tp        = 4012.0;
input double InpSell1Tp2       = 4002.0;

input group "Shelf sell 4002-4006"
input bool   InpTradeShelf     = true;       // Trade the nearer 4002 shelf at half size
input double InpShelfLow       = 4002.0;
input double InpShelfHigh      = 4006.0;
input double InpShelfEntry     = 4002.0;     // 5m then 15m close back under
input double InpShelfStop      = 4006.5;
input double InpShelfTp        = 3987.0;
input double InpShelfTp2       = 3982.0;

input group "Other blocks from the 26 Oct check"
input bool   InpDrawOther          = true;   // Draw the other blocks
input bool   InpTradeMildZones     = false;  // Trade mild blocks (off until you turn it on)
input bool   InpTradeFarSell       = true;   // Trade the strong 4088-4103 sell
input double InpMildBuyLow         = 4003.0;
input double InpMildBuyHigh        = 4007.0;
input double InpMildBuyEntry       = 4003.0;
input double InpMildBuyStop        = 3998.0;
input double InpMildBuyTp          = 4012.0;
input double InpSell4009Low        = 4009.0;
input double InpSell4009High       = 4012.0;
input double InpSell4009Entry      = 4009.0;
input double InpSell4009Stop       = 4013.0;
input double InpSell4009Tp         = 4003.0;
input double InpSell4015Low        = 4015.0;
input double InpSell4015High       = 4019.0;
input double InpSell4015Entry      = 4015.0;
input double InpSell4015Stop       = 4022.0;
input double InpSell4015Tp         = 4009.0;
input double InpFarLow             = 4088.0;
input double InpFarHigh            = 4103.0;
input double InpFarEntry           = 4088.0;
input double InpFarStop            = 4110.0;
input double InpFarTp              = 4034.0;
input double InpFarTp2             = 4024.0;

input group "Detected order blocks"
input bool   InpDetectBlocks         = true;  // Find and draw blocks on 15m, 30m, 1h, 2h, 4h, daily
input bool   InpTradeDetectedBlocks  = false; // Trade a detected block. Higher-timeframe blocks still gate trades when this is off
input int    InpAtrPeriod            = 14;
input double InpImpulseAtr           = 1.5;   // Impulse range versus ATR
input double InpStrongAtr            = 2.5;   // Strong when the impulse is this many ATR, or on 4h/daily
input double InpImpulseClose        = 0.60;   // Close in the outer part of the impulse bar
input int    InpObLookback           = 120;
input int    InpObScan               = 6;     // Opposite candle within this many bars
input int    InpMaxDetected          = 12;
input bool   InpTradeDetectedMild    = false;

input group "Stops, targets, chase"
input bool   InpUseHardStop    = false;      // Broker stop on the cancel price (a wick can exit)
input double InpDisasterExtra  = 15.0;       // Emergency stop beyond the 15m cancel, price
input double InpStrongBuffer   = 6.5;        // Detected strong stop beyond the block
input double InpMildBuffer     = 2.0;        // Detected mild stop beyond the block
input double InpRewardRisk     = 2.0;        // Detected target when no opposite block is closer
input double InpMaxChase       = 15.0;       // Close must be this close to the entry, price
input int    InpTouchBars      = 12;         // Touch of the block within this many closed 5m bars
input double InpMinTarget      = 2.0;        // Skip a target closer than this

input group "Higher timeframe"
input bool   InpUseHtfStructure = true;      // Gate trades with higher-timeframe support, resistance, and blocks
input double InpHtfRoom         = 6.0;       // A strong 4h, daily, weekly, or monthly level this close blocks a trade into it
input double InpPlanSupport     = 3975.5;    // Strong support, daily and weekly low
input double InpPlanResistance  = 4034.2;    // Strong resistance, weekly high

input group "Clock"
input int    InpServerUtcOffset = 3;         // Broker server UTC offset. 3 matches the Bangladesh 4h clock

//====================================================================
// Types
//====================================================================
struct Zone
{
   bool     enabled;
   bool     bull;
   bool     strong;
   bool     manual;
   bool     plan;
   bool     halfLot;
   bool     mild;
   double   low;
   double   high;
   double   entry;
   double   stop;
   double   tp;
   double   tp2;
   double   armAbove;   // armed only while the 15m close is above this. 0 = unused
   double   armBelow;   // armed only while the 15m close is under this. 0 = unused
   datetime time;
   string   name;
   string   tfName;
   int      tfRank;     // 1=15m, 2=30m, 3=1h, 4=2h, 5=4h, 6=daily, 7=weekly, 8=monthly
};

struct Level
{
   bool   support;
   bool   strong;
   double price;
   int    rank;
   string name;
};

//====================================================================
// State
//====================================================================
CTrade   g_trade;
Zone     g_zone[];
int      g_zoneCount = 0;
Level    g_level[];
int      g_levelCount = 0;
int      g_atrHandle[6] = {-1, -1, -1, -1, -1, -1};
ENUM_TIMEFRAMES g_tf[6];
bool     g_atrWait = true;

datetime g_lastM5  = 0;
datetime g_lastM15 = 0;
datetime g_exitM15 = 0;

string   g_buyLine  = "Buy now: waiting for the first 5-minute close.";
string   g_sellLine = "Sell now: waiting for the first 5-minute close.";
string   g_actLine  = "No order yet.";
bool     g_h4Ok     = true;

//====================================================================
// Small helpers
//====================================================================
string MonthShort(const int month)
{
   switch(month)
   {
      case 1:  return "Jan";
      case 2:  return "Feb";
      case 3:  return "Mar";
      case 4:  return "Apr";
      case 5:  return "May";
      case 6:  return "Jun";
      case 7:  return "Jul";
      case 8:  return "Aug";
      case 9:  return "Sep";
      case 10: return "Oct";
      case 11: return "Nov";
      case 12: return "Dec";
   }
   return "";
}

datetime BangladeshNow()
{
   datetime gmt = TimeGMT();
   if(gmt > 0)
      return gmt + 6 * 3600;
   return TimeCurrent() + (6 - InpServerUtcOffset) * 3600;
}

datetime ToBangladesh(const datetime serverTime)
{
   datetime gmtNow = TimeGMT();
   datetime serverNow = TimeCurrent();
   if(gmtNow > 0 && serverNow > 0)
   {
      long skew = (long)serverNow - (long)gmtNow;
      return (datetime)((long)serverTime - skew + 6 * 3600);
   }
   return serverTime + (6 - InpServerUtcOffset) * 3600;
}

string FormatBd(const datetime bd)
{
   MqlDateTime dt;
   TimeToStruct(bd, dt);
   return StringFormat("%02d:%02d Bangladesh, %d %s %d",
                       dt.hour, dt.min, dt.day, MonthShort(dt.mon), dt.year);
}

bool AsiaThin(const datetime serverBarOpen, const ENUM_TIMEFRAMES tf)
{
   datetime closeBd = ToBangladesh(serverBarOpen + PeriodSeconds(tf));
   MqlDateTime dt;
   TimeToStruct(closeBd, dt);
   return (dt.hour >= 3 && dt.hour < 13);
}

double NormPrice(const double price)
{
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double out = price;
   if(tick > 0.0)
      out = MathRound(price / tick) * tick;
   return NormalizeDouble(out, digits);
}

double MinStopDistance()
{
   long stops = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freeze = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double dist = (double)MathMax(stops, freeze) * _Point;
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(dist < tick)
      dist = tick;
   return dist;
}

string GvName(const string tail)
{
   return "XAU" + IntegerToString((long)InpMagic) + "_" + tail;
}

void GvSet(const string tail, const double value)
{
   GlobalVariableSet(GvName(tail), value);
}

double GvGet(const string tail, const double fallback)
{
   string name = GvName(tail);
   if(!GlobalVariableCheck(name))
      return fallback;
   return GlobalVariableGet(name);
}

double VolumeOf(const MqlRates &bar)
{
   if(InpVolumeIsContracts && bar.real_volume > 0)
      return (double)bar.real_volume;
   return (double)bar.tick_volume;
}

void SplitFlow(const MqlRates &bar, double &buyVol, double &sellVol, double &total)
{
   total = VolumeOf(bar);
   double range = bar.high - bar.low;
   if(range <= 0.0 || total <= 0.0)
   {
      buyVol = 0.0;
      sellVol = 0.0;
      return;
   }
   buyVol = total * (bar.close - bar.low) / range;
   sellVol = total - buyVol;
}

bool SideLeads(const bool bull, const double buyVol, const double sellVol)
{
   double side = bull ? buyVol : sellVol;
   double other = bull ? sellVol : buyVol;
   double total = side + other;
   if(total <= 0.0)
      return false;
   if(100.0 * side / total + 1e-6 >= (double)InpFlowLeadPercent)
      return true;
   if(other > 0.0 && side + 1e-6 >= other * 3.0)
      return true;
   return false;
}

bool ClosedThrough(const bool bull, const double close, const double entry)
{
   if(bull)
      return (close > entry);
   return (close < entry);
}

bool WithinChase(const bool bull, const double close, const double entry)
{
   if(bull)
      return (close > entry && (close - entry) <= InpMaxChase);
   return (close < entry && (entry - close) <= InpMaxChase);
}

double AverageVolume(const MqlRates &rates[], const int count)
{
   // rates[0] is the signal bar. The average is the 20 closed bars behind it.
   double sum = 0.0;
   int n = 0;
   for(int i = 1; i < count && n < 20; i++)
   {
      double v = VolumeOf(rates[i]);
      if(v <= 0.0)
         continue;
      sum += v;
      n++;
   }
   if(n == 0)
      return 0.0;
   return sum / n;
}

bool UseAbsoluteVolume()
{
   return (InpVolumeIsContracts || !InpUseRelativeVolume);
}

bool VolumePasses(const double volume, const double average, const bool heavy)
{
   if(volume <= 0.0)
      return false;
   if(UseAbsoluteVolume())
   {
      if(volume < InpMinVolume)
         return false;
      double need = heavy ? InpHeavyVolume : InpDecisionVolume;
      return (volume >= need);
   }
   if(average <= 0.0)
      return false;
   double multiple = heavy ? InpAsiaRelativeMultiple : InpRelativeMultiple;
   return (volume >= average * multiple);
}

string VolUnit()
{
   if(InpVolumeIsContracts)
      return "contracts";
   return "ticks";
}

string FlowText(const string label, const MqlRates &bar)
{
   double buyVol = 0.0, sellVol = 0.0, total = 0.0;
   SplitFlow(bar, buyVol, sellVol, total);
   double pct = (total > 0.0) ? (100.0 * buyVol / total) : 0.0;
   return StringFormat("%s: %s %s, buy %s, sell %s (%s%% buy)",
                       label,
                       DoubleToString(total, 0),
                       VolUnit(),
                       DoubleToString(buyVol, 0),
                       DoubleToString(sellVol, 0),
                       DoubleToString(pct, 0));
}

//====================================================================
// Positions
//====================================================================
ulong OurPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      return ticket;
   }
   return 0;
}

bool AnyPositionOnSymbol()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         return true;
   }
   return false;
}

double LotStep()
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(step <= 0.0)
      step = 0.01;
   return step;
}

int LotDigits()
{
   double step = LotStep();
   for(int digits = 0; digits <= 8; digits++)
   {
      if(MathAbs(step - NormalizeDouble(step, digits)) < step * 0.001)
         return digits;
   }
   return 2;
}

double NormalizeLot(const double requested)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = LotStep();
   double lot = MathFloor(requested / step + 1e-8) * step;
   if(lot < minLot)
      lot = minLot;
   if(maxLot > 0.0 && lot > maxLot)
      lot = maxLot;
   return NormalizeDouble(lot, LotDigits());
}

bool CanSplit(const double lots)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step = LotStep();
   double half = MathFloor((lots * 0.5) / step + 1e-8) * step;
   if(half < minLot)
      return false;
   if((lots - half) + 1e-8 < minLot)
      return false;
   return true;
}

//====================================================================
// Zones
//====================================================================
void PushZone(const Zone &zone)
{
   if(g_zoneCount >= 64)
      return;
   ArrayResize(g_zone, g_zoneCount + 1);
   g_zone[g_zoneCount] = zone;
   g_zoneCount++;
}

void AddManual(const bool enabled, const bool bull, const bool strong, const bool plan,
               const bool halfLot, const bool mild,
               const double low, const double high, const double entry,
               const double stop, const double tp, const double tp2,
               const double armAbove, const double armBelow, const string name,
               const string tfName, const int tfRank)
{
   if(low <= 0.0 || high <= 0.0)
      return;
   Zone zone;
   zone.enabled  = enabled;
   zone.bull     = bull;
   zone.strong   = strong;
   zone.manual   = true;
   zone.plan     = plan;
   zone.halfLot  = halfLot;
   zone.mild     = mild;
   zone.low      = low;
   zone.high     = high;
   zone.entry    = entry;
   zone.stop     = stop;
   zone.tp       = tp;
   zone.tp2      = tp2;
   zone.armAbove = armAbove;
   zone.armBelow = armBelow;
   zone.time     = TimeCurrent() - 2 * 24 * 3600;
   zone.name     = name;
   zone.tfName   = tfName;
   zone.tfRank   = tfRank;
   if(zone.high < zone.low)
   {
      double swap = zone.high;
      zone.high = zone.low;
      zone.low = swap;
   }
   PushZone(zone);
}

bool RangesOverlap(const double aLow, const double aHigh, const double bLow, const double bHigh)
{
   return (aLow <= bHigh && aHigh >= bLow);
}

bool OverlapsManual(const bool bull, const double low, const double high)
{
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(!g_zone[i].manual || g_zone[i].bull != bull)
         continue;
      if(RangesOverlap(low, high, g_zone[i].low, g_zone[i].high))
         return true;
   }
   return false;
}

void FinalizeDetected(Zone &zone)
{
   double buffer = zone.strong ? InpStrongBuffer : InpMildBuffer;
   if(zone.bull)
   {
      zone.entry = zone.high;
      zone.stop  = zone.low - buffer;
      double risk = zone.entry - zone.stop;
      zone.tp = (risk > 0.0) ? zone.entry + risk * InpRewardRisk : 0.0;
      zone.tp2 = 0.0;
   }
   else
   {
      zone.entry = zone.low;
      zone.stop  = zone.high + buffer;
      double risk = zone.stop - zone.entry;
      zone.tp = (risk > 0.0) ? zone.entry - risk * InpRewardRisk : 0.0;
      zone.tp2 = 0.0;
   }
}

void AddDetected(const bool bull, const bool strong, const double low, const double high,
                 const datetime barTime, const string tfName)
{
   if(high <= low)
      return;
   if(OverlapsManual(bull, low, high))
      return;
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zone[i].manual || g_zone[i].bull != bull)
         continue;
      double overlap = MathMin(high, g_zone[i].high) - MathMax(low, g_zone[i].low);
      double smaller = MathMin(high - low, g_zone[i].high - g_zone[i].low);
      if(overlap <= 0.0 || smaller <= 0.0 || overlap < smaller * 0.5)
         continue;
      if(low < g_zone[i].low)
         g_zone[i].low = low;
      if(high > g_zone[i].high)
         g_zone[i].high = high;
      if(strong)
         g_zone[i].strong = true;
      g_zone[i].mild = !g_zone[i].strong;
      if(barTime > g_zone[i].time)
         g_zone[i].time = barTime;
      int rank = RankOfTimeframe(tfName);
      if(rank > g_zone[i].tfRank)
      {
         g_zone[i].tfRank = rank;
         g_zone[i].tfName = tfName;
         g_zone[i].name = (g_zone[i].strong ? "Strong " : "Mild ")
                          + (g_zone[i].bull ? "+OB " : "-OB ")
                          + tfName + " "
                          + DoubleToString(g_zone[i].low, 1) + "-"
                          + DoubleToString(g_zone[i].high, 1);
      }
      FinalizeDetected(g_zone[i]);
      return;
   }
   Zone zone;
   zone.enabled  = true;
   zone.bull     = bull;
   zone.strong   = strong;
   zone.manual   = false;
   zone.plan     = false;
   zone.halfLot  = false;
   zone.mild     = !strong;
   zone.low      = low;
   zone.high     = high;
   zone.armAbove = 0.0;
   zone.armBelow = 0.0;
   zone.time     = barTime;
   zone.tfName   = tfName;
   zone.tfRank   = RankOfTimeframe(tfName);
   zone.name     = (strong ? "Strong " : "Mild ") + (bull ? "+OB " : "-OB ")
                   + tfName + " " + DoubleToString(low, 1) + "-" + DoubleToString(high, 1);
   FinalizeDetected(zone);
   PushZone(zone);
}

void DetectTimeframe(const ENUM_TIMEFRAMES tf, const int handle, const string tfName)
{
   if(handle == INVALID_HANDLE)
      return;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int bars = InpObLookback + InpObScan + 2;
   int got = CopyRates(_Symbol, tf, 1, bars, rates);
   if(got < 30)
      return;

   double atr[];
   ArraySetAsSeries(atr, true);
   if(CopyBuffer(handle, 0, 1, got, atr) < 30)
      return;

   int last = MathMin(got, InpObLookback) - 1;
   for(int i = 0; i <= last; i++)
   {
      double range = rates[i].high - rates[i].low;
      if(range <= 0.0 || atr[i] <= 0.0)
         continue;
      if(range < atr[i] * InpImpulseAtr)
         continue;
      double pos = (rates[i].close - rates[i].low) / range;
      bool bullImpulse = (pos >= InpImpulseClose);
      bool bearImpulse = (pos <= (1.0 - InpImpulseClose));
      if(!bullImpulse && !bearImpulse)
         continue;

      int scanEnd = MathMin(i + InpObScan, got - 1);
      for(int j = i + 1; j <= scanEnd; j++)
      {
         bool down = (rates[j].close < rates[j].open);
         bool up = (rates[j].close > rates[j].open);
         if(bullImpulse && down)
         {
            bool strong = (tf == PERIOD_H4 || tf == PERIOD_D1 || range > atr[i] * InpStrongAtr);
            AddDetected(true, strong, rates[j].low, rates[j].high, rates[j].time, tfName);
            break;
         }
         if(bearImpulse && up)
         {
            bool strong = (tf == PERIOD_H4 || tf == PERIOD_D1 || range > atr[i] * InpStrongAtr);
            AddDetected(false, strong, rates[j].low, rates[j].high, rates[j].time, tfName);
            break;
         }
      }
   }
}

void PullTargetsToOpposite()
{
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zone[i].manual)
         continue;
      double best = g_zone[i].tp;
      for(int k = 0; k < g_zoneCount; k++)
      {
         if(k == i || g_zone[k].bull == g_zone[i].bull)
            continue;
         if(g_zone[i].bull)
         {
            double level = g_zone[k].low;
            if(level - g_zone[i].entry < InpMinTarget)
               continue;
            if(best <= g_zone[i].entry || level < best)
               best = level;
         }
         else
         {
            double level = g_zone[k].high;
            if(g_zone[i].entry - level < InpMinTarget)
               continue;
            if(best >= g_zone[i].entry || level > best)
               best = level;
         }
      }
      if(g_zone[i].bull && best > g_zone[i].entry)
         g_zone[i].tp = best;
      if(!g_zone[i].bull && best < g_zone[i].entry)
         g_zone[i].tp = best;
   }
}

void KeepClosestDetected()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int detected = 0;
   for(int i = 0; i < g_zoneCount; i++)
      if(!g_zone[i].manual)
         detected++;
   while(detected > InpMaxDetected)
   {
      int drop = -1;
      double far = -1.0;
      for(int i = 0; i < g_zoneCount; i++)
      {
         if(g_zone[i].manual)
            continue;
         double mid = (g_zone[i].low + g_zone[i].high) * 0.5;
         double dist = MathAbs(mid - bid);
         if(dist > far)
         {
            far = dist;
            drop = i;
         }
      }
      if(drop < 0)
         break;
      for(int j = drop; j < g_zoneCount - 1; j++)
         g_zone[j] = g_zone[j + 1];
      g_zoneCount--;
      detected--;
   }
   ArrayResize(g_zone, g_zoneCount);
}

int RankOfTimeframe(const string tfName)
{
   if(tfName == "30m")
      return 2;
   if(tfName == "1h")
      return 3;
   if(tfName == "2h")
      return 4;
   if(tfName == "4h")
      return 5;
   if(tfName == "1d")
      return 6;
   if(tfName == "1w")
      return 7;
   if(tfName == "1mo")
      return 8;
   return 1;
}

void BuildManual()
{
   AddManual(InpTradeBuy1, true, true, true, false, false,
             InpBuy1Low, InpBuy1High, InpBuy1Entry, InpBuy1Stop, InpBuy1Tp, InpBuy1Tp2,
             InpBuy1ArmAbove, 0.0, "Strong +OB 3982-3987, 1h 2h 4h daily", "4h", 6);
   AddManual(InpTradeBuy2, true, true, true, false, false,
             InpBuy2Low, InpBuy2High, InpBuy2Entry, InpBuy2Stop, InpBuy2Tp, InpBuy2Tp2,
             0.0, InpBuy2ArmBelow, "Strong +OB 3943-3959, 4h daily", "1d", 6);
   AddManual(InpTradeSell1, false, false, true, false, true,
             InpSell1Low, InpSell1High, InpSell1Entry, InpSell1Stop, InpSell1Tp, InpSell1Tp2,
             0.0, 0.0, "Mild -OB 4024-4032, 15m 4h", "4h", 5);
   AddManual(InpTradeShelf, false, false, true, true, true,
             InpShelfLow, InpShelfHigh, InpShelfEntry, InpShelfStop, InpShelfTp, InpShelfTp2,
             0.0, 0.0, "Shelf sell 4002-4006, 15m", "15m", 1);
   AddManual(InpTradeMildZones, true, false, false, false, true,
             InpMildBuyLow, InpMildBuyHigh, InpMildBuyEntry, InpMildBuyStop, InpMildBuyTp, 0.0,
             0.0, 0.0, "Mild +OB 4003-4007, 15m 30m", "30m", 2);
   AddManual(InpTradeMildZones, false, false, false, false, true,
             InpSell4009Low, InpSell4009High, InpSell4009Entry, InpSell4009Stop, InpSell4009Tp, 0.0,
             0.0, 0.0, "Mild -OB 4009-4012, 15m 30m 1h", "1h", 3);
   AddManual(InpTradeMildZones, false, false, false, false, true,
             InpSell4015Low, InpSell4015High, InpSell4015Entry, InpSell4015Stop, InpSell4015Tp, 0.0,
             0.0, 0.0, "Mild -OB 4015-4019, 15m 30m 1h 2h", "2h", 4);
   AddManual(InpTradeFarSell, false, true, true, false, false,
             InpFarLow, InpFarHigh, InpFarEntry, InpFarStop, InpFarTp, InpFarTp2,
             0.0, 0.0, "Strong -OB 4088-4103, 4h daily", "1d", 6);
}

bool ZoneGeometryOk(const Zone &zone)
{
   if(zone.high <= zone.low)
      return false;
   if(zone.entry < zone.low - InpMaxChase || zone.entry > zone.high + InpMaxChase)
      return false;
   if(zone.bull)
   {
      if(!(zone.stop < zone.entry))
         return false;
      if(zone.tp > 0.0 && zone.tp <= zone.entry)
         return false;
      if(zone.tp2 > 0.0 && zone.tp > 0.0 && zone.tp2 <= zone.tp)
         return false;
   }
   else
   {
      if(!(zone.stop > zone.entry))
         return false;
      if(zone.tp > 0.0 && zone.tp >= zone.entry)
         return false;
      if(zone.tp2 > 0.0 && zone.tp > 0.0 && zone.tp2 >= zone.tp)
         return false;
   }
   return true;
}

bool ZoneArmed(const Zone &zone, const double m15Close)
{
   if(!zone.enabled)
      return false;
   if(!ZoneGeometryOk(zone))
      return false;
   // A 15-minute close under the cancel hands the upper buy to the deeper buy.
   if(zone.armAbove > 0.0 && m15Close < zone.armAbove)
      return false;
   if(zone.armBelow > 0.0 && m15Close >= zone.armBelow)
      return false;
   if(zone.manual)
   {
      if(zone.mild && !zone.plan && !InpTradeMildZones)
         return false;
      return true;
   }
   if(!InpTradeDetectedBlocks)
      return false;
   if(zone.mild && !InpTradeDetectedMild)
      return false;
   return true;
}

void DeleteDrawings()
{
   for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, "XAUOB_") == 0)
         ObjectDelete(0, name);
   }
}

color ZoneColor(const Zone &zone)
{
   if(zone.bull)
      return zone.strong ? clrDodgerBlue : clrDeepSkyBlue;
   return zone.strong ? clrCrimson : clrOrangeRed;
}

void AddLevel(const bool support, const bool strong, const double price,
             const int rank, const string name)
{
   if(price <= 0.0 || g_levelCount >= 64)
      return;
   for(int i = 0; i < g_levelCount; i++)
   {
      if(g_level[i].support != support)
         continue;
      if(MathAbs(g_level[i].price - price) > 1.0)
         continue;
      if((strong && !g_level[i].strong) || rank > g_level[i].rank)
      {
         g_level[i].strong = g_level[i].strong || strong;
         g_level[i].rank = rank;
         g_level[i].name = name;
         g_level[i].price = price;
      }
      return;
   }
   ArrayResize(g_level, g_levelCount + 1);
   g_level[g_levelCount].support = support;
   g_level[g_levelCount].strong = strong;
   g_level[g_levelCount].price = price;
   g_level[g_levelCount].rank = rank;
   g_level[g_levelCount].name = name;
   g_levelCount++;
}

void AddClosedExtremes(const ENUM_TIMEFRAMES tf, const int rank, const string tfName)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, tf, 1, 1, rates) < 1)
      return;
   bool strong = (rank >= 5);
   AddLevel(false, strong, rates[0].high, rank, tfName + " high " + DoubleToString(rates[0].high, 1));
   AddLevel(true, strong, rates[0].low, rank, tfName + " low " + DoubleToString(rates[0].low, 1));
}

void AddOpenExtremes(const ENUM_TIMEFRAMES tf, const int rank, const string tfName)
{
   double hi = iHigh(_Symbol, tf, 0);
   double lo = iLow(_Symbol, tf, 0);
   bool strong = (rank >= 5);
   if(hi > 0.0)
      AddLevel(false, strong, hi, rank, tfName + " high " + DoubleToString(hi, 1));
   if(lo > 0.0)
      AddLevel(true, strong, lo, rank, tfName + " low " + DoubleToString(lo, 1));
}

void AddSwings(const ENUM_TIMEFRAMES tf, const int rank, const string tfName)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int got = CopyRates(_Symbol, tf, 1, 80, rates);
   if(got < 6)
      return;
   bool strong = (rank >= 5);
   bool foundHigh = false;
   bool foundLow = false;
   int last = got - 3;
   for(int i = 2; i <= last; i++)
   {
      if(!foundHigh
         && rates[i].high > rates[i - 1].high && rates[i].high > rates[i - 2].high
         && rates[i].high > rates[i + 1].high && rates[i].high > rates[i + 2].high)
      {
         AddLevel(false, strong, rates[i].high, rank, tfName + " swing high " + DoubleToString(rates[i].high, 1));
         foundHigh = true;
      }
      if(!foundLow
         && rates[i].low < rates[i - 1].low && rates[i].low < rates[i - 2].low
         && rates[i].low < rates[i + 1].low && rates[i].low < rates[i + 2].low)
      {
         AddLevel(true, strong, rates[i].low, rank, tfName + " swing low " + DoubleToString(rates[i].low, 1));
         foundLow = true;
      }
      if(foundHigh && foundLow)
         break;
   }
}

void BuildLevels()
{
   ArrayResize(g_level, 0);
   g_levelCount = 0;
   AddClosedExtremes(PERIOD_M30, 2, "30m");
   AddClosedExtremes(PERIOD_H1, 3, "1h");
   AddClosedExtremes(PERIOD_H2, 4, "2h");
   AddClosedExtremes(PERIOD_H4, 5, "4h");
   AddClosedExtremes(PERIOD_D1, 6, "daily");
   AddClosedExtremes(PERIOD_W1, 7, "weekly");
   AddClosedExtremes(PERIOD_MN1, 8, "monthly");
   AddOpenExtremes(PERIOD_W1, 7, "weekly");
   AddOpenExtremes(PERIOD_MN1, 8, "monthly");
   AddSwings(PERIOD_H4, 5, "4h");
   AddSwings(PERIOD_D1, 6, "daily");
   AddSwings(PERIOD_W1, 7, "weekly");
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zone[i].tfRank < 2 || g_zone[i].high <= g_zone[i].low)
         continue;
      bool strong = (g_zone[i].strong || g_zone[i].tfRank >= 5);
      if(g_zone[i].bull)
         AddLevel(true, strong, g_zone[i].low, g_zone[i].tfRank, g_zone[i].name);
      else
         AddLevel(false, strong, g_zone[i].high, g_zone[i].tfRank, g_zone[i].name);
   }
   if(InpPlanSupport > 0.0)
      AddLevel(true, true, InpPlanSupport, 8, "Strong support " + DoubleToString(InpPlanSupport, 1) + ", daily and weekly");
   if(InpPlanResistance > 0.0)
      AddLevel(false, true, InpPlanResistance, 8, "Strong resistance " + DoubleToString(InpPlanResistance, 1) + ", weekly");
}

bool PriceInside(const double price, const double low, const double high)
{
   return (price >= low && price <= high);
}

string HtfGate(const Zone &zone, const double close)
{
   if(!InpUseHtfStructure)
      return "";

   string inside = "";
   int insideRank = -1;
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zone[i].bull == zone.bull || g_zone[i].high <= g_zone[i].low)
         continue;
      if(MathAbs(g_zone[i].low - zone.low) < 0.05 && MathAbs(g_zone[i].high - zone.high) < 0.05)
         continue;
      bool higher = g_zone[i].manual ? (g_zone[i].tfRank >= 2) : (g_zone[i].tfRank >= 3);
      if(!higher)
         continue;
      if(!PriceInside(close, g_zone[i].low, g_zone[i].high))
         continue;
      if(g_zone[i].tfRank > insideRank)
      {
         insideRank = g_zone[i].tfRank;
         inside = "5m close is inside " + g_zone[i].name;
      }
   }
   if(StringLen(inside) > 0)
      return inside;

   for(int i = 0; i < g_levelCount; i++)
   {
      if(!g_level[i].strong || g_level[i].rank < 5)
         continue;
      if(zone.bull && !g_level[i].support)
      {
         double gap = g_level[i].price - close;
         if(gap < 0.0 || gap > InpHtfRoom || g_level[i].price <= zone.high)
            continue;
         return "strong resistance " + g_level[i].name + " is within " + DoubleToString(InpHtfRoom, 1);
      }
      if(!zone.bull && g_level[i].support)
      {
         double gap = close - g_level[i].price;
         if(gap < 0.0 || gap > InpHtfRoom || g_level[i].price >= zone.low)
            continue;
         return "strong support " + g_level[i].name + " is within " + DoubleToString(InpHtfRoom, 1);
      }
   }

   ENUM_TIMEFRAMES tfs[4];
   string names[4];
   tfs[0] = PERIOD_H1;
   tfs[1] = PERIOD_H2;
   tfs[2] = PERIOD_H4;
   tfs[3] = PERIOD_D1;
   names[0] = "1h";
   names[1] = "2h";
   names[2] = "4h";
   names[3] = "daily";
   string broke = "";
   for(int i = 0; i < 4; i++)
   {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(_Symbol, tfs[i], 1, 1, rates) < 1)
         continue;
      bool against = zone.bull ? (rates[0].close < zone.stop) : (rates[0].close > zone.stop);
      if(!against)
         continue;
      broke = names[i] + " close " + DoubleToString(rates[0].close, _Digits)
              + (zone.bull ? " is under the cancel " : " is above the cancel ")
              + DoubleToString(zone.stop, _Digits);
   }
   return broke;
}

double StructureTarget(const Zone &zone)
{
   double tp = zone.tp;
   double best = 0.0;
   for(int i = 0; i < g_levelCount; i++)
   {
      if(g_level[i].rank < 5 && !g_level[i].strong)
         continue;
      if(zone.bull && !g_level[i].support)
      {
         if(g_level[i].price <= zone.high)
            continue;
         if(g_level[i].price - zone.entry < InpMinTarget)
            continue;
         if(best <= 0.0 || g_level[i].price < best)
            best = g_level[i].price;
      }
      if(!zone.bull && g_level[i].support)
      {
         if(g_level[i].price >= zone.low)
            continue;
         if(zone.entry - g_level[i].price < InpMinTarget)
            continue;
         if(best <= 0.0 || g_level[i].price > best)
            best = g_level[i].price;
      }
   }
   if(best <= 0.0)
      return tp;
   if(zone.bull && (tp <= 0.0 || best < tp))
      return best;
   if(!zone.bull && (tp <= 0.0 || best > tp))
      return best;
   return tp;
}

void DrawLevels()
{
   for(int i = 0; i < g_levelCount; i++)
   {
      if(!g_level[i].strong)
         continue;
      string name = "XAUOB_LV_" + IntegerToString(i);
      if(!ObjectCreate(0, name, OBJ_HLINE, 0, 0, g_level[i].price))
         continue;
      color clr = g_level[i].support ? clrDodgerBlue : clrCrimson;
      ObjectSetInteger(0, name, OBJPROP_COLOR, (long)clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, g_level[i].rank >= 7 ? 2 : 1);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, g_level[i].name);
   }
}

void DrawZones()
{
   DeleteDrawings();
   datetime left = TimeCurrent() - 2 * 24 * 3600;
   datetime right = TimeCurrent() + 12 * 3600;
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zone[i].manual && !g_zone[i].plan && !g_zone[i].enabled && !InpDrawOther)
         continue;
      if(!g_zone[i].manual && !InpDetectBlocks)
         continue;
      string name = "XAUOB_" + IntegerToString(i);
      datetime t1 = g_zone[i].manual ? left : g_zone[i].time;
      if(t1 <= 0)
         t1 = left;
      double top = g_zone[i].high;
      double bottom = g_zone[i].low;
      if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, top, right, bottom))
         continue;
      color clr = ZoneColor(g_zone[i]);
      ObjectSetInteger(0, name, OBJPROP_COLOR, (long)clr);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, (long)clr);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, g_zone[i].strong ? 2 : 1);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetString(0, name, OBJPROP_TOOLTIP, g_zone[i].name);

      string label = name + "L";
      double labelPrice = g_zone[i].bull ? g_zone[i].low : g_zone[i].high;
      if(ObjectCreate(0, label, OBJ_TEXT, 0, TimeCurrent(), labelPrice))
      {
         ObjectSetString(0, label, OBJPROP_TEXT, g_zone[i].name);
         ObjectSetString(0, label, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, label, OBJPROP_COLOR, (long)clr);
         ObjectSetInteger(0, label, OBJPROP_ANCHOR, ANCHOR_LEFT);
         ObjectSetInteger(0, label, OBJPROP_SELECTABLE, false);
      }
   }
   DrawLevels();
   ChartRedraw(0);
}

void RefreshZones()
{
   ArrayResize(g_zone, 0);
   g_zoneCount = 0;
   BuildManual();
   if(InpDetectBlocks)
   {
      DetectTimeframe(PERIOD_M15, g_atrHandle[0], "15m");
      DetectTimeframe(PERIOD_M30, g_atrHandle[1], "30m");
      DetectTimeframe(PERIOD_H1,  g_atrHandle[2], "1h");
      DetectTimeframe(PERIOD_H2,  g_atrHandle[3], "2h");
      DetectTimeframe(PERIOD_H4,  g_atrHandle[4], "4h");
      DetectTimeframe(PERIOD_D1,  g_atrHandle[5], "1d");
      PullTargetsToOpposite();
      KeepClosestDetected();
   }
   BuildLevels();
   DrawZones();
}

bool H4MatchesPlan()
{
   datetime t = iTime(_Symbol, PERIOD_H4, 0);
   if(t <= 0)
      return false;
   datetime closeBd = ToBangladesh(t + PeriodSeconds(PERIOD_H4));
   MqlDateTime dt;
   TimeToStruct(closeBd, dt);
   int hour = dt.hour;
   return (hour == 3 || hour == 7 || hour == 11 || hour == 15 || hour == 19 || hour == 23);
}

//====================================================================
// Signal
//====================================================================
bool CopyClosed(const ENUM_TIMEFRAMES tf, const int count, MqlRates &rates[])
{
   ArraySetAsSeries(rates, true);
   int got = CopyRates(_Symbol, tf, 1, count, rates);
   return (got >= count);
}

bool BarTouched(const MqlRates &bar, const Zone &zone)
{
   if(bar.low <= zone.high && bar.high >= zone.low)
      return true;
   if(zone.bull && bar.low <= zone.entry)
      return true;
   if(!zone.bull && bar.high >= zone.entry)
      return true;
   return false;
}

bool ReasonIsReady(const string reason)
{
   return (StringFind(reason, "ready") == 0);
}

string ZoneWaitReason(const Zone &zone, const MqlRates &m5[], const int m5Count,
                      const MqlRates &m15[], const int m15Count)
{
   if(!ZoneGeometryOk(zone))
      return "prices need a check";
   if(m5Count < 2)
      return "5m rates have not arrived";

   bool touched = false;
   int touchCount = MathMin(m5Count, InpTouchBars);
   for(int i = 0; i < touchCount; i++)
   {
      if(BarTouched(m5[i], zone))
      {
         touched = true;
         break;
      }
   }
   if(!touched)
      return "price has not touched it";

   if(!ClosedThrough(zone.bull, m5[0].close, zone.entry))
      return "5m close is not back through " + DoubleToString(zone.entry, _Digits);
   if(m15Count < 1 || !ClosedThrough(zone.bull, m15[0].close, zone.entry))
      return "15m close has not confirmed";
   string htfEarly = HtfGate(zone, m5[0].close);
   if(StringLen(htfEarly) > 0)
      return htfEarly;
   if(!WithinChase(zone.bull, m5[0].close, zone.entry))
      return "5m close is more than " + DoubleToString(InpMaxChase, 1) + " from the entry";

   bool prevM5 = ClosedThrough(zone.bull, m5[1].close, zone.entry);
   bool prevM15 = (m15Count > 1 && ClosedThrough(zone.bull, m15[1].close, zone.entry));
   if(prevM5 && prevM15)
      return "this reclaim is already old";

   double buyVol = 0.0, sellVol = 0.0, total = 0.0;
   SplitFlow(m5[0], buyVol, sellVol, total);
   double avg = AverageVolume(m5, m5Count);
   bool heavy = (InpAsiaNeedsHeavy && AsiaThin(m5[0].time, PERIOD_M5));
   if(UseAbsoluteVolume() && total < InpMinVolume)
      return "5m " + VolUnit() + " are under " + DoubleToString(InpMinVolume, 0);
   if(!VolumePasses(total, avg, heavy))
   {
      if(heavy)
         return "Asia session, and the 5m bar is not heavy";
      if(!UseAbsoluteVolume())
         return "5m ticks are under " + DoubleToString(InpRelativeMultiple, 1) + "x the average";
      return "5m " + VolUnit() + " are under the decision line";
   }
   if(!SideLeads(zone.bull, buyVol, sellVol))
      return "5m order flow does not lead";

   double b15 = 0.0, s15 = 0.0, t15 = 0.0;
   SplitFlow(m15[0], b15, s15, t15);
   double avg15 = AverageVolume(m15, m15Count);
   bool heavy15 = (InpAsiaNeedsHeavy && AsiaThin(m15[0].time, PERIOD_M15));
   if(!VolumePasses(t15, avg15, heavy15))
   {
      if(heavy15)
         return "Asia session, and the 15m bar is not heavy";
      if(!UseAbsoluteVolume())
         return "15m ticks are under " + DoubleToString(InpRelativeMultiple, 1) + "x the average";
      return "15m " + VolUnit() + " are under the decision line";
   }
   if(SideLeads(!zone.bull, b15, s15))
      return "15m order flow leads the other way";

   double target = StructureTarget(zone);
   return StringFormat("ready. 5m %s %s, buy %s, sell %s. 15m %s %s, buy %s, sell %s. Stop %s, target %s.",
                       DoubleToString(total, 0), VolUnit(),
                       DoubleToString(buyVol, 0), DoubleToString(sellVol, 0),
                       DoubleToString(t15, 0), VolUnit(),
                       DoubleToString(b15, 0), DoubleToString(s15, 0),
                       DoubleToString(zone.stop, _Digits),
                       DoubleToString(target, _Digits));
}

int PickZone(const bool bull, const MqlRates &m5[], const int m5Count,
             const MqlRates &m15[], const int m15Count,
             string &why, bool &ready)
{
   int best = -1;
   int bestScore = -1000000;
   double bestDist = 1e12;
   why = "";
   ready = false;
   double m15Close = (m15Count >= 1) ? m15[0].close : 0.0;
   for(int i = 0; i < g_zoneCount; i++)
   {
      if(g_zone[i].bull != bull)
         continue;
      if((g_zone[i].armAbove > 0.0 || g_zone[i].armBelow > 0.0) && m15Count < 1)
         continue;
      if(!ZoneArmed(g_zone[i], m15Close))
         continue;
      string reason = ZoneWaitReason(g_zone[i], m5, m5Count, m15, m15Count);
      bool thisReady = ReasonIsReady(reason);
      int score = 0;
      if(thisReady)
      {
         score = 1000;
         if(g_zone[i].strong)
            score += 100;
         if(g_zone[i].plan)
            score += 40;
         if(g_zone[i].manual)
            score += 10;
      }
      double dist = MathAbs(m5[0].close - g_zone[i].entry);
      if(score > bestScore || (score == bestScore && dist < bestDist))
      {
         best = i;
         bestScore = score;
         bestDist = dist;
         ready = thisReady;
         why = g_zone[i].name + ": " + reason;
      }
   }
   if(best < 0)
      why = bull ? "no buy block is armed" : "no sell block is armed";
   return best;
}

void Evaluate(const bool sendOrder)
{
   MqlRates m5[];
   MqlRates m15[];
   ArraySetAsSeries(m5, true);
   ArraySetAsSeries(m15, true);
   int m5Count = CopyRates(_Symbol, PERIOD_M5, 1, 22, m5);
   int m15Count = CopyRates(_Symbol, PERIOD_M15, 1, 22, m15);
   if(m5Count < 2)
   {
      g_buyLine = "Buy now: 5-minute rates are not ready.";
      g_sellLine = "Sell now: 5-minute rates are not ready.";
      return;
   }
   if(m15Count < 0)
      m15Count = 0;

   string buyWhy, sellWhy;
   bool buyReady = false, sellReady = false;
   int buyIndex = PickZone(true, m5, m5Count, m15, m15Count, buyWhy, buyReady);
   int sellIndex = PickZone(false, m5, m5Count, m15, m15Count, sellWhy, sellReady);

   g_buyLine = "Buy now: " + (buyReady ? "Yes. " : "No. ") + buyWhy;
   g_sellLine = "Sell now: " + (sellReady ? "Yes. " : "No. ") + sellWhy;

   if(buyReady && sellReady)
   {
      g_actLine = "Buy and sell are both fresh. No new order.";
      return;
   }
   if(!InpAllowNewTrades)
   {
      g_actLine = "New trades are off.";
      return;
   }
   if(OurPosition() != 0)
   {
      g_actLine = "A rules position is already open.";
      return;
   }
   if(AnyPositionOnSymbol())
   {
      g_actLine = "Another " + _Symbol + " position is open. No second order.";
      return;
   }

   int index = buyReady ? buyIndex : (sellReady ? sellIndex : -1);
   if(index < 0)
   {
      g_actLine = "Waiting for a fresh 5m and 15m close.";
      return;
   }
   if(!sendOrder)
   {
      g_actLine = "This reclaim closed before the robot was attached, so it is left. The next new reclaim can trade.";
      return;
   }
   TryOpen(g_zone[index], m5[0]);
}

//====================================================================
// Orders
//====================================================================
ENUM_ORDER_TYPE_FILLING FillingFromSymbol()
{
   long mode = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((mode & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   if((mode & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
}

bool SendMarket(const bool bull, const double lots, const double sl, const double tp, const string comment)
{
   ENUM_ORDER_TYPE_FILLING order[3];
   order[0] = FillingFromSymbol();
   order[1] = ORDER_FILLING_RETURN;
   order[2] = ORDER_FILLING_IOC;
   uint lastRet = 0;
   for(int i = 0; i < 3; i++)
   {
      if(i > 0 && order[i] == order[0])
         continue;
      g_trade.SetTypeFilling(order[i]);
      bool ok = bull ? g_trade.Buy(lots, _Symbol, 0.0, sl, tp, comment)
                     : g_trade.Sell(lots, _Symbol, 0.0, sl, tp, comment);
      if(ok)
         return true;
      lastRet = g_trade.ResultRetcode();
      if(lastRet != TRADE_RETCODE_INVALID_FILL)
      {
         g_actLine = "Order rejected: " + g_trade.ResultRetcodeDescription();
         Print(g_actLine, " retcode ", lastRet);
         return false;
      }
   }
   g_actLine = "Order rejected on filling mode.";
   Print(g_actLine, " retcode ", lastRet);
   return false;
}

bool TryOpen(const Zone &zone, const MqlRates &signalBar)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask <= 0.0 || bid <= 0.0)
   {
      g_actLine = "No quote.";
      return false;
   }
   if((ask - bid) > InpMaxSpread)
   {
      g_actLine = "Spread " + DoubleToString(ask - bid, _Digits) + " is over the max.";
      return false;
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      g_actLine = "Algo trading is off. The read above is still live.";
      return false;
   }

   double lots = NormalizeLot(zone.halfLot ? InpLots * 0.5 : InpLots);
   bool halfCollapsed = (zone.halfLot && lots + 1e-8 >= InpLots);
   double firstTarget = StructureTarget(zone);
   if(firstTarget <= 0.0)
      firstTarget = zone.tp;
   double secondTarget = 0.0;
   if(zone.tp2 > 0.0 && ((zone.bull && zone.tp2 > firstTarget) || (!zone.bull && zone.tp2 < firstTarget)))
      secondTarget = zone.tp2;
   else if(zone.tp > 0.0 && MathAbs(zone.tp - firstTarget) > 0.05
           && ((zone.bull && zone.tp > firstTarget) || (!zone.bull && zone.tp < firstTarget)))
      secondTarget = zone.tp;
   bool split = (secondTarget > 0.0 && CanSplit(lots));
   double sl = zone.stop;
   if(!InpUseHardStop)
      sl = zone.bull ? zone.stop - InpDisasterExtra : zone.stop + InpDisasterExtra;
   double tp = split ? secondTarget : firstTarget;
   if(tp <= 0.0)
      tp = firstTarget;
   sl = NormPrice(sl);
   tp = NormPrice(tp);

   double minDist = MinStopDistance();
   if(zone.bull)
   {
      if(sl >= bid - minDist)
      {
         g_actLine = "Buy stop is inside the broker minimum distance.";
         return false;
      }
      if(tp > 0.0 && tp <= ask + minDist)
      {
         g_actLine = "Buy target is inside the broker minimum distance.";
         return false;
      }
   }
   else
   {
      if(sl <= ask + minDist)
      {
         g_actLine = "Sell stop is inside the broker minimum distance.";
         return false;
      }
      if(tp > 0.0 && tp >= bid - minDist)
      {
         g_actLine = "Sell target is inside the broker minimum distance.";
         return false;
      }
   }

   double price = zone.bull ? ask : bid;
   double margin = 0.0;
   ENUM_ORDER_TYPE type = zone.bull ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(OrderCalcMargin(type, _Symbol, lots, price, margin))
   {
      if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) < margin)
      {
         g_actLine = "Free margin is not enough for " + DoubleToString(lots, 2) + " lots.";
         return false;
      }
   }

   string comment = zone.bull ? "XAU rules buy" : "XAU rules sell";
   if(!SendMarket(zone.bull, lots, sl, tp, comment))
      return false;

   GvSet("bull", zone.bull ? 1.0 : 0.0);
   GvSet("stop", zone.stop);
   GvSet("tp1", firstTarget);
   GvSet("tp2", secondTarget);
   GvSet("scaled", split ? 0.0 : 1.0);
   GvSet("entry", zone.entry);

   double buyVol = 0.0, sellVol = 0.0, total = 0.0;
   SplitFlow(signalBar, buyVol, sellVol, total);
   g_actLine = StringFormat("Opened %s %.2f lots. Stop %.2f. Target %.2f. Flow buy %s sell %s.",
                            zone.bull ? "buy" : "sell",
                            lots,
                            zone.stop,
                            (firstTarget > 0.0 ? firstTarget : tp),
                            DoubleToString(buyVol, 0),
                            DoubleToString(sellVol, 0));
   if(halfCollapsed)
      g_actLine += " Half size stayed at the minimum lot.";
   Print(g_actLine, " ", zone.name);
   return true;
}

void CloseOurs(const string reason)
{
   ulong ticket = OurPosition();
   if(ticket == 0)
      return;
   if(g_trade.PositionClose(ticket))
   {
      g_actLine = reason;
      Print(reason);
      GvSet("scaled", 1.0);
   }
   else
   {
      g_actLine = "Close failed: " + g_trade.ResultRetcodeDescription();
      Print(g_actLine);
   }
}

void ManageM15Exit()
{
   ulong ticket = OurPosition();
   if(ticket == 0)
      return;
   datetime closed = iTime(_Symbol, PERIOD_M15, 1);
   if(closed <= 0 || closed == g_exitM15)
      return;

   MqlRates m15[];
   if(!CopyClosed(PERIOD_M15, 1, m15))
      return;
   if(!PositionSelectByTicket(ticket))
      return;
   long posType = PositionGetInteger(POSITION_TYPE);
   bool bull = (GvGet("bull", posType == POSITION_TYPE_BUY ? 1.0 : 0.0) > 0.5);
   double planStop = GvGet("stop", 0.0);
   if(planStop <= 0.0)
   {
      g_exitM15 = closed;
      return;
   }
   bool hit = bull ? (m15[0].close < planStop) : (m15[0].close > planStop);
   if(!hit)
   {
      g_exitM15 = closed;
      return;
   }
   string reason = bull
                   ? "15m close " + DoubleToString(m15[0].close, _Digits) + " is under the cancel " + DoubleToString(planStop, _Digits) + "."
                   : "15m close " + DoubleToString(m15[0].close, _Digits) + " is above the cancel " + DoubleToString(planStop, _Digits) + ".";
   CloseOurs(reason);
   if(OurPosition() == 0)
      g_exitM15 = closed;
}

void ManageScale()
{
   ulong ticket = OurPosition();
   if(ticket == 0)
      return;
   if(GvGet("scaled", 1.0) > 0.5)
      return;
   double tp1 = GvGet("tp1", 0.0);
   if(tp1 <= 0.0)
      return;
   bool bull = (GvGet("bull", 0.0) > 0.5);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bool hit = bull ? (bid >= tp1) : (ask <= tp1);
   if(!hit)
      return;

   if(!PositionSelectByTicket(ticket))
      return;
   double volume = PositionGetDouble(POSITION_VOLUME);
   if(!CanSplit(volume))
   {
      GvSet("scaled", 1.0);
      return;
   }
   double step = LotStep();
   double half = NormalizeLot(MathFloor((volume * 0.5) / step + 1e-8) * step);
   if(half <= 0.0 || volume - half <= 0.0)
   {
      GvSet("scaled", 1.0);
      return;
   }
   if(!g_trade.PositionClosePartial(ticket, half))
   {
      Print("Partial close failed: ", g_trade.ResultRetcodeDescription());
      return;
   }
   GvSet("scaled", 1.0);
   g_actLine = "Closed half at the first target " + DoubleToString(tp1, _Digits) + ".";
   Print(g_actLine);

   if(!PositionSelectByTicket(ticket))
      return;
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double curSl = PositionGetDouble(POSITION_SL);
   double curTp = PositionGetDouble(POSITION_TP);
   double newSl = NormPrice(open);
   double minDist = MinStopDistance();
   bool slOk = bull ? (newSl <= bid - minDist && newSl > curSl) : (newSl >= ask + minDist && (curSl == 0.0 || newSl < curSl));
   if(slOk)
   {
      if(!g_trade.PositionModify(ticket, newSl, curTp))
         Print("Break-even modify failed: ", g_trade.ResultRetcodeDescription());
   }
}

//====================================================================
// Panel
//====================================================================
string ClipText(const string text, const int maxLen)
{
   if(StringLen(text) <= maxLen)
      return text;
   return StringSubstr(text, 0, maxLen - 3) + "...";
}

string NearLevels(const bool support, const double price)
{
   string text = support ? "Supports: " : "Resistances: ";
   bool used[];
   ArrayResize(used, g_levelCount);
   ArrayInitialize(used, false);
   int added = 0;
   for(int n = 0; n < 3; n++)
   {
      int pick = -1;
      double best = 1.0e12;
      for(int i = 0; i < g_levelCount; i++)
      {
         if(i >= ArraySize(used) || used[i] || g_level[i].support != support)
            continue;
         if(support && g_level[i].price > price + 0.5)
            continue;
         if(!support && g_level[i].price < price - 0.5)
            continue;
         double dist = MathAbs(price - g_level[i].price);
         if(dist < best)
         {
            best = dist;
            pick = i;
         }
      }
      if(pick < 0)
         break;
      used[pick] = true;
      if(added > 0)
         text += "; ";
      text += g_level[pick].name;
      added++;
   }
   if(added == 0)
      text += "none on this side";
   return ClipText(text, 220);
}

string ObLine(const bool bull)
{
   string text = bull ? "+OB: " : "-OB: ";
   bool used[];
   ArrayResize(used, g_zoneCount);
   ArrayInitialize(used, false);
   int added = 0;
   for(int n = 0; n < 4; n++)
   {
      int pick = -1;
      double best = 1.0e12;
      for(int i = 0; i < g_zoneCount; i++)
      {
         if(i >= ArraySize(used) || used[i] || g_zone[i].bull != bull || g_zone[i].tfRank < 2)
            continue;
         double mid = (g_zone[i].low + g_zone[i].high) * 0.5;
         double dist = MathAbs(mid - SymbolInfoDouble(_Symbol, SYMBOL_BID));
         dist -= g_zone[i].tfRank * 2.0;
         if(dist < best)
         {
            best = dist;
            pick = i;
         }
      }
      if(pick < 0)
         break;
      used[pick] = true;
      if(added > 0)
         text += "; ";
      text += g_zone[pick].name;
      added++;
   }
   if(added == 0)
      text += "none from 30m or higher";
   return ClipText(text, 220);
}

string HtfCloseLine()
{
   ENUM_TIMEFRAMES tfs[4];
   string names[4];
   tfs[0] = PERIOD_H1;
   tfs[1] = PERIOD_H2;
   tfs[2] = PERIOD_H4;
   tfs[3] = PERIOD_D1;
   names[0] = "1h";
   names[1] = "2h";
   names[2] = "4h";
   names[3] = "daily";
   string text = "Higher-timeframe closes:";
   for(int i = 0; i < 4; i++)
   {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(_Symbol, tfs[i], 1, 1, rates) < 1)
         continue;
      text += " " + names[i] + " " + DoubleToString(rates[0].close, _Digits);
   }
   return text;
}

void UpdatePanel()
{
   MqlRates m5[];
   MqlRates m15[];
   string flow5 = "5m: rates not ready";
   string flow15 = "15m: rates not ready";
   if(CopyClosed(PERIOD_M5, 1, m5))
      flow5 = FlowText("5m", m5[0]);
   if(CopyClosed(PERIOD_M15, 1, m15))
      flow15 = FlowText("15m", m15[0]);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   string spread = DoubleToString((ask > 0.0 && bid > 0.0) ? (ask - bid) : 0.0, _Digits);

   string posLine = "Position: flat";
   ulong ticket = OurPosition();
   if(ticket != 0 && PositionSelectByTicket(ticket))
   {
      bool bull = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      posLine = StringFormat("Position: %s %.2f at %s, stop %s, target %s",
                             bull ? "buy" : "sell",
                             PositionGetDouble(POSITION_VOLUME),
                             DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), _Digits),
                             DoubleToString(PositionGetDouble(POSITION_SL), _Digits),
                             DoubleToString(PositionGetDouble(POSITION_TP), _Digits));
   }
   else if(AnyPositionOnSymbol())
      posLine = "Position: another " + _Symbol + " trade is open.";

   string volWarn;
   if(InpVolumeIsContracts)
      volWarn = "Volume mode: COMEX contracts. Quiet " + DoubleToString(InpMinVolume, 0)
                + ", decision " + DoubleToString(InpDecisionVolume, 0)
                + ", heavy " + DoubleToString(InpHeavyVolume, 0) + ".";
   else if(InpUseRelativeVolume)
      volWarn = "Volume mode: broker ticks, not COMEX contracts. A decision bar is "
                + DoubleToString(InpRelativeMultiple, 1) + "x its last 20 bars, and "
                + DoubleToString(InpAsiaRelativeMultiple, 1) + "x from 03:00 to 13:00 Bangladesh.";
   else
      volWarn = "Volume mode: broker ticks, not COMEX contracts. Quiet "
                + DoubleToString(InpMinVolume, 0) + ", decision " + DoubleToString(InpDecisionVolume, 0)
                + ", heavy " + DoubleToString(InpHeavyVolume, 0) + ".";
   string clock = g_h4Ok
                  ? "4h clock: matches 03, 07, 11, 15, 19, 23 Bangladesh."
                  : "4h clock: this server does not match that Bangladesh grid. 5m and 15m entries still run.";
   string stopMode = InpUseHardStop
                     ? "Stop: broker stop is the cancel price, so a wick can exit."
                     : "Stop: waits for a 15m close. Emergency stop is "
                       + DoubleToString(InpDisasterExtra, 1) + " beyond it.";

   string text = "XAUUSD rules robot\n"
                 + FormatBd(BangladeshNow()) + "\n"
                 + _Symbol + "  " + DoubleToString(bid, _Digits) + "   spread " + spread + "\n"
                 + g_buyLine + "\n"
                 + g_sellLine + "\n"
                 + flow5 + "\n"
                 + flow15 + "\n"
                 + HtfCloseLine() + "\n"
                 + NearLevels(true, bid) + "\n"
                 + NearLevels(false, bid) + "\n"
                 + ObLine(true) + "\n"
                 + ObLine(false) + "\n"
                 + volWarn + "\n"
                 + posLine + "\n"
                 + g_actLine + "\n"
                 + stopMode + "\n"
                 + clock + "\n"
                 + "Yield filter is not in this robot. The plan still wants the note above 105.17 and the 10-year under 5.22.\n"
                 + "Demo first. Lot " + DoubleToString(InpLots, 2) + ". One position. Levels are inputs and they go stale.";
   Comment(text);
}

//====================================================================
// Events
//====================================================================
int OnInit()
{
   for(int i = 0; i < 6; i++)
      g_atrHandle[i] = INVALID_HANDLE;
   g_atrWait = true;

   string symbol = _Symbol;
   StringToUpper(symbol);
   if(!InpAllowAnySymbol && StringFind(symbol, "XAU") < 0 && StringFind(symbol, "GOLD") < 0)
   {
      Print("Attach this robot to XAUUSD or GOLD. This chart is ", _Symbol, ".");
      return INIT_FAILED;
   }

   g_tf[0] = PERIOD_M15;
   g_tf[1] = PERIOD_M30;
   g_tf[2] = PERIOD_H1;
   g_tf[3] = PERIOD_H2;
   g_tf[4] = PERIOD_H4;
   g_tf[5] = PERIOD_D1;
   for(int i = 0; i < 6; i++)
   {
      g_atrHandle[i] = iATR(_Symbol, g_tf[i], InpAtrPeriod);
      if(g_atrHandle[i] == INVALID_HANDLE)
         Print("ATR was not created for ", EnumToString(g_tf[i]), ". That timeframe will not draw blocks.");
   }

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippagePoints);
   g_trade.SetTypeFilling(FillingFromSymbol());
   g_trade.SetAsyncMode(false);

   g_h4Ok = H4MatchesPlan();
   g_lastM5 = iTime(_Symbol, PERIOD_M5, 0);
   g_lastM15 = iTime(_Symbol, PERIOD_M15, 0);
   g_exitM15 = iTime(_Symbol, PERIOD_M15, 1);

   RefreshZones();
   Evaluate(false);
   UpdatePanel();
   Print("XAUUSD rules robot ready on ", _Symbol, ". A new order waits for the next 5-minute close. ", vol_mode_print());
   return INIT_SUCCEEDED;
}

string vol_mode_print()
{
   if(InpVolumeIsContracts)
      return "Volume is contracts.";
   return "Volume is broker ticks.";
}

void OnDeinit(const int reason)
{
   for(int i = 0; i < 6; i++)
   {
      if(g_atrHandle[i] != INVALID_HANDLE)
      {
         IndicatorRelease(g_atrHandle[i]);
         g_atrHandle[i] = INVALID_HANDLE;
      }
   }
   DeleteDrawings();
   Comment("");
}

void OnTick()
{
   ManageScale();
   ManageM15Exit();

   bool atrReadyNow = false;
   if(g_atrWait && InpDetectBlocks && g_atrHandle[0] != INVALID_HANDLE)
   {
      double probe[];
      ArraySetAsSeries(probe, true);
      if(CopyBuffer(g_atrHandle[0], 0, 1, 1, probe) == 1)
      {
         g_atrWait = false;
         atrReadyNow = true;
         RefreshZones();
      }
   }

   datetime m15 = iTime(_Symbol, PERIOD_M15, 0);
   if(m15 > 0 && m15 != g_lastM15)
   {
      g_lastM15 = m15;
      g_h4Ok = H4MatchesPlan();
      RefreshZones();
   }

   datetime m5 = iTime(_Symbol, PERIOD_M5, 0);
   bool newM5 = (m5 > 0 && m5 != g_lastM5);
   if(newM5)
   {
      g_lastM5 = m5;
      Evaluate(true);
   }
   else if(atrReadyNow)
      Evaluate(false);
   UpdatePanel();
}
//+------------------------------------------------------------------+
