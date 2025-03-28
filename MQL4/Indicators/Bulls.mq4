//+------------------------------------------------------------------+
//|                                                        Bulls.mq4 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2000-2025, MetaQuotes Ltd."
#property link        "https://www.mql5.com"
#property description "Bulls Power"
#property strict

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 Silver
//--- input parameter
input int InpBullsPeriod=13;
//--- buffers
double ExtBullsBuffer[];
double ExtTempBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit(void)
  {
   string short_name;
//--- 1 additional buffer used for counting.
   IndicatorBuffers(2);
   IndicatorDigits(Digits);
//--- indicator line
   SetIndexStyle(0,DRAW_HISTOGRAM);
   SetIndexBuffer(0,ExtBullsBuffer);
   SetIndexBuffer(1,ExtTempBuffer);
//--- name for DataWindow and indicator subwindow label
   short_name="Bulls("+IntegerToString(InpBullsPeriod)+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
  }
//+------------------------------------------------------------------+
//| Bulls Power                                                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int limit=rates_total-prev_calculated;
//---
   if(rates_total<=InpBullsPeriod)
      return(0);
//---
   if(prev_calculated>0)
      limit++;
   for(int i=0; i<limit; i++)
     {
      ExtTempBuffer[i]=iMA(NULL,0,InpBullsPeriod,0,MODE_EMA,PRICE_CLOSE,i);
      ExtBullsBuffer[i]=high[i]-ExtTempBuffer[i];
     }
//---
   return(rates_total);
  }
//+------------------------------------------------------------------+
