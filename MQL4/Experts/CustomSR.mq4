//+------------------------------------------------------------------+
//|                                                     CustomSR.mq4 |
//|                                       Javier Alexi Chacon Suarez |
//|                               https://github.com/javierchacon262 |
//+------------------------------------------------------------------+
#property copyright "Javier Alexi Chacon Suarez"
#property link      "https://github.com/javierchacon262"
#property version   "1.00"
#property strict

input int prd            = 10;
input int channelW       = 10;
input int max_num_SR     = 5;
input int min_strength   = 2;
input int max_min_number = 300;
input int max_num_pp     = 20;
//input STYLE line_style     = STYLE_DASH;
//Global variables
double Ls, Hs, Lst, Hst, Highest, Lowest, Pivots[], sr_up_level[], sr_dn_level[], sr_strength[];
int High_Idx, Low_Idx, cWidth, pCont;
datetime bTime;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
      Ls    = 0;
      Hs    = 0;
      Lst   = 0;
      Hst   = 0;
      pCont = 0;
      ArrayResize(Pivots, max_num_pp);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }

//+------------------------------------------------------------------+
//| Perform shift on array values                                    |
//+------------------------------------------------------------------+
void Shift(double &array[], int pos)
  {
      int size = ArraySize(array);
      if(pos < size-1)
        {
            for(int i=pos+1;i<size;i++)
              {
                  array[i-1] = array[i];
                  array[i]   = 0;
              }
        }
  }

//+------------------------------------------------------------------+
//| Count non zero values and return them from an array              |
//+------------------------------------------------------------------+

void NNZ(double &array[], double &out[])
  {
      int size = ArraySize(array);
      int cont = 0;
      for(int i=0;i<size;i++)
        {
            if(array[i])
              {
                  cont++;
              }
        }
      ArrayResize(out, cont);
      int j = 0;
      for(int i=0;i<size;i++)
        {
            if(array[i])
              {
                  out[j] = array[i];
                  j++;
              }
        }
  }

//+------------------------------------------------------------------+
//| Get SR values                                                    |
//+------------------------------------------------------------------+
void Get_SR_values(double &array[], double &hi, double &lo, int &numpp, int idx)
  {
      lo = array[idx];              //float lo = array.get(pivotvals, ind)
      hi = lo;                      //float hi = lo
      numpp = 0;                    //int numpp = 0
      double cpp, wdth;
      int size = ArraySize(array);
      for(int i=0;i<size;i++)       //for y = 0 to array.size(pivotvals) - 1
        {
            cpp = array[i];         //  float cpp = array.get(pivotvals, y)
            if(cpp <= lo)           //  float wdth = cpp <= lo ? hi - cpp : cpp - lo
              {
                  wdth = hi - cpp;  
              }
            else
              {
                  wdth = cpp - lo;
              }
            
            if(wdth <= cWidth)      //  if wdth <= cwidth // fits the max channel width?
              {
                  if(cpp <= lo)     //      lo := cpp <= lo ? cpp : lo
                    {
                        lo = cpp;
                    }
                  else              //      hi := cpp > lo ? cpp : hi
                    {
                        hi = cpp;
                    }
                  numpp++;          //      numpp := numpp + 1
              }
        }
      //[hi, lo, numpp]
  }
  
//+------------------------------------------------------------------+
//| Find location                                                    |
//+------------------------------------------------------------------+
int Find_Loc(double strength)                           // find_loc(strength)=>
  {
      int ret = ArraySize(sr_strength);          //    ret = array.size(sr_strength)
      if(ret)                                    //    if ret > 0
        {
            for(int i=ret-1;i>=0;i--)            //    for i = array.size(sr_strength) - 1 to 0
              {
                  if(strength <= sr_strength[i]) //       if strength <= array.get(sr_strength, i)
                    {
                        ret = i;                 //          ret := i
                        break;
                    }
              }
        }
      return ret;
  }
  
//+------------------------------------------------------------------+
//| Check SR levels                                                  |
//+------------------------------------------------------------------+
bool Check_SR(double hi, double lo, double strength)
  {
      bool ret     = true;                                   //ret = true
      int  size_up = ArraySize(sr_up_level);
      if(size_up)                                            //if array.size(sr_up_level) > 0
        {
            for(int i=0;i<size_up;i++)                       //for i = 0 to array.size(sr_up_level) - 1
              {
                                                             //if array.get(sr_up_level, i) >= lo and array.get(sr_up_level, i) <= hi  or 
                                                             //array.get(sr_dn_level, i) >= lo and array.get(sr_dn_level, i) <= hi
                  if(((sr_up_level[i] >= lo) && (sr_up_level[i] <= hi)) || ((sr_dn_level[i] >= lo) && (sr_dn_level[i] <= hi)))
                    {
                        if(strength >= sr_strength[i])       //if strength >= array.get(sr_strength, i)
                          {
                              double sr_s[], sr_u[], sr_d[];
                              NNZ(sr_strength, sr_s);        //array.remove(sr_strength, i)
                              NNZ(sr_up_level, sr_u);        //array.remove(sr_up_level, i)
                              NNZ(sr_dn_level, sr_d);        //array.remove(sr_dn_level, i)
                              ArrayCopy(sr_strength, sr_s);
                              ArrayCopy(sr_up_level, sr_u);
                              ArrayCopy(sr_dn_level, sr_d);
                              return ret;                    //ret
                          }
                        else
                          {
                              ret = false;                   //ret := false
                          }
                        break;
                    }
              }
        }
      return ret;                                            //ret
  }
  
//+------------------------------------------------------------------+
//| Round number to the nearest upside integer                                             |
//+------------------------------------------------------------------+

int Round(double num)
  {
      if(MathIsValidNumber(num))
        {
            return int(num) + 1;
        }
      else
        {
            return 0;
        }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void Draw_Line(double yCoor, string name)
  {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, yCoor);
      if(yCoor <= Bid)
        {
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrLimeGreen);
        }
      else
        {
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
        }
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
  }
  
//+------------------------------------------------------------------+
//| Draw labels function                                             |
//+------------------------------------------------------------------+
void Draw_Label(double ycoor, string name, string text, bool opened, datetime bTime)
  {
      ObjectCreate(0, name, OBJ_TEXT, 0, 0, 0);
      datetime x;
      double y;
      if(opened)
        {
            x = Time[0] + (bTime * 30);
        }
      else
        {
            x = Time[100];
        }
      y = ycoor;
      ObjectMove(name, 0, x, y);
      if(ycoor <= Bid)
        {
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrLimeGreen);
        }
      else
        {
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
        }
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      // Pivot high and pivot low using zigzag indicator.
      Ls              = iCustom(_Symbol, _Period, "../Indicators/ZigZag", MODE_HIGH, 0);
      Hs              = iCustom(_Symbol, _Period, "../Indicators/ZigZag", MODE_LOW, 0);
      
      if(int(Ls) || int(Hs))
        {
         if(int(Hs))
           {
               Hst = Hs;
               Pivots[pCont] = Hst;
           }
         else
           {
               Lst = Ls;
               Pivots[pCont] = Lst;
           }
         pCont++;
         if(pCont == max_num_pp)
           {
               Shift(Pivots, 1);
               pCont = max_num_pp - 1;
           }
        }
      if(int(Hs)) Hst = Hs;
      
      // Channel width calculation
      High_Idx        = iHighest(_Symbol, _Period, MODE_HIGH, max_min_number, 0);
      Low_Idx         = iLowest(_Symbol, _Period, MODE_LOW, max_min_number, 0);
      Highest         = High[High_Idx];
      Lowest          = Low[Low_Idx];
      cWidth          = (Highest - Lowest) * channelW / 100;
      
      //get min time
      bTime = TimeCurrent();
      if(!MathIsValidNumber(bTime))
      
        {
            MathMin(bTime, Time[0] - Time[1]);
        }
      bool opened   = bTime > Time[0] && bTime < Time[0]+(_Period*60);
      
      double hi, lo;
      int numpp, loc;
      // New calculations
      if(int(Ls) || int(Hs))
        {
            ArrayResize(sr_up_level, max_num_SR);
            ArrayResize(sr_dn_level, max_num_SR);
            ArrayResize(sr_strength, max_num_SR);
            ArrayInitialize(sr_up_level, 0.0);
            ArrayInitialize(sr_dn_level, 0.0);
            ArrayInitialize(sr_strength, 0.0);
            for(int i=0;i<max_num_SR;i++)
              {
                  Get_SR_values(Pivots, hi, lo, numpp, i);
                  if(Check_SR(hi, lo, numpp))
                    {
                        loc = Find_Loc(numpp);
                        if(loc < max_num_SR && numpp >= min_strength)
                          {
                              sr_strength[loc] = numpp;
                              sr_up_level[loc] = hi;
                              sr_dn_level[loc] = lo;
                          }
                    }
              }
              
            for(int i=0;i<max_num_SR;i++)
              {
                  double mid = Round((sr_up_level[i] + sr_dn_level[i]) / 2);
                  Draw_Line(mid, string(i));
                  if(int(Hs))
                    {
                        Draw_Label(High[0]+5.0, string(max_num_SR+i), 'z', opened, bTime);
                    }
                  else
                    {
                        Draw_Label(Low[0]-5.0, string(max_num_SR+i), 'z', opened, bTime);
                    }
              }
        }
      
  }
//+------------------------------------------------------------------+