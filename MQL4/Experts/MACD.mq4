//+------------------------------------------------------------------+
//|                                                  Custom MACD.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Averages Convergence/Divergence"
#property strict

#include <MovingAverages.mqh>

//--- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 5
#property  indicator_color1  Silver  //Histogram
#property  indicator_color4  Aqua    //Histogram 2
#property  indicator_color5  Silver  //Histogram 2
#property  indicator_color2  Silver  //Signal line
#property  indicator_color3  Aqua    //MACD line
#property  indicator_width1  3
#property  indicator_width4  6
#property  indicator_width5  6
#property  indicator_width2  2
#property  indicator_width3  2
//--- indicator parameters
input int InpFastEMA   =12;   // Fast EMA Period
input int InpSlowEMA   =26;   // Slow EMA Period
input int InpFilterEMA =52; // Filter EMA Period
input int InpSignalSMA =9;  // Signal SMA Period
//--- indicator buffers
double    ExtHistBuffer[];
double    ExtHistBuffer2[];
double    ExtMacdBuffer[];
double    ExtSignalBuffer[];
double    ExtHistBuffer1[];
//--- right input parameters flag
bool      ExtParameters=false;
double    temp;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   IndicatorDigits(Digits+1);
//--- drawing settings
   SetIndexStyle(0, DRAW_NONE);
   SetIndexStyle(3, DRAW_HISTOGRAM);
   SetIndexStyle(1, DRAW_LINE);
   SetIndexStyle(2, DRAW_LINE);
   SetIndexStyle(4, DRAW_HISTOGRAM);
   SetIndexDrawBegin(1,InpSignalSMA);
   //SetIndexDrawBegin(2, 1);
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtHistBuffer);
   SetIndexBuffer(3,ExtHistBuffer2);
   SetIndexBuffer(4,ExtHistBuffer1);
   SetIndexBuffer(1,ExtSignalBuffer);
   SetIndexBuffer(2,ExtMacdBuffer);
//--- name for DataWindow and indicator subwindow label
   IndicatorShortName("Filtered MACD("+IntegerToString(InpFastEMA)+","+IntegerToString(InpSlowEMA)+","+IntegerToString(InpSignalSMA)+")");
   SetIndexLabel(0,"Histogram");
   SetIndexLabel(3,"Histogram2");
   SetIndexLabel(4,"Histogram1");
   SetIndexLabel(1,"Signal");
   SetIndexLabel(2,"MACD");
//--- check for input parameters
   if(InpFastEMA<=1 || InpSlowEMA<=1 || InpSignalSMA<=1 || InpFastEMA>=InpSlowEMA)
     {
      Print("Wrong input parameters");
      ExtParameters=false;
      return(INIT_FAILED);
     }
   else
      ExtParameters=true;
//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const datetime& time[],
                 const double& open[],
                 const double& high[],
                 const double& low[],
                 const double& close[],
                 const long& tick_volume[],
                 const long& volume[],
                 const int& spread[])
  {
   int i,limit;
//---
   if(rates_total<=InpSignalSMA || !ExtParameters)
      return(0);
      
//--- last counted bar will be recounted
   limit = rates_total - prev_calculated;
   
   if(prev_calculated>0)
      limit++;
      
//--- macd counted in the 1-st buffer
   for(i=0; i<limit; i++)
   {      
      ExtMacdBuffer[i] = iMA(NULL,0,InpFastEMA,0,MODE_EMA,PRICE_CLOSE,i) - iMA(NULL,0,InpSlowEMA,0,MODE_EMA,PRICE_CLOSE,i);
   }
//--- signal line counted in the 2-nd buffer
   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
   
//--- Histogram calculation
   for(i=0; i<limit; i++)
   {
      ExtHistBuffer[i] = ExtMacdBuffer[i] - ExtSignalBuffer[i];      
      if(i > 0)
        {
            if(ExtHistBuffer[i] < ExtHistBuffer[i-1])
              {
                  ExtHistBuffer2[i] = ExtHistBuffer[i];
                  ExtHistBuffer1[i]  = EMPTY_VALUE;
              }
            else
              {
                  ExtHistBuffer1[i]  = ExtHistBuffer[i];
                  ExtHistBuffer2[i] = EMPTY_VALUE;
              }
        }     
   }
   //SimpleMAOnBuffer(rates_total,prev_calculated,0,InpFilterEMA,ExtHistBuffer,ExtMacdBuffer);
//--- done
   return(rates_total);
  }
//+------------------------------------------------------------------+