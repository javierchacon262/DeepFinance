//+------------------------------------------------------------------+
//|                                                    CustomSR2.mq4 |
//|                                                    Javier Chacon |
//|                               https://github.com/javierchacon262 |
//+------------------------------------------------------------------+

#property copyright "Javier Chacon"
#property link      "https://github.com/javierchacon262"
#property version   "1.00"
#property strict

// SR levels input parameters
input int             prd           = 10;
input int             maxnumpp      = 25;
input int             channelw      = 10;
input int             maxnumsr      = 8;
input int             min_strength  = 2;
input int             interval      = 1000;
input ENUM_LINE_STYLE style         = STYLE_DASH;
input int             width         = 2;
input bool            background    = false;

// SR Levels global variables
double Hs, Ls, Pivotvals[], sr_up_level[], sr_dn_level[], sr_strength[], cwidth;
datetime bTime;

int OnInit()
  {   
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Integer Array Sum Function                                       |
//+------------------------------------------------------------------+
int IntArraySum(int &array[])
  {
   int summation = 0;
   for(int i = ArraySize(array) - 1; i >= 0; i--)
     {
      summation += array[i];
     }
   return summation;
  }

//+------------------------------------------------------------------+
//| Double Array Sum Function                              |
//+------------------------------------------------------------------+
double DoubleArraySum(double &array[])
  {
   double summation = 0;
   for(int i = ArraySize(array) - 1; i >= 0; i--)
     {
      summation += array[i];
     }
   return summation;
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
//| Round number to the nearest upside integer                       |
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
//| Find location function                                           |
//+------------------------------------------------------------------+
int Find_Loc(int strength)                    // find_loc(strength)=>
  {
      double ret = DoubleArraySum(sr_strength);      //    ret = array.size(sr_strength)
      if(ret > 0)                                    //    if ret > 0
        {
            for(int i=ArraySize(sr_strength)-1;i>=0;i--)                //    for i = array.size(sr_strength) - 1 to 0
              {
                  if(double(strength) <= sr_strength[i])     //       if strength <= array.get(sr_strength, i)
                    {
                        break;                       //            break
                    }
                  ret = i;                           //       ret := i
              }
        }
      return int(ret);
  }

//+------------------------------------------------------------------+
//| Remove item from array function                                  |
//+------------------------------------------------------------------+
void Remove(double &src[], double &dstn[], int idx)
  {
      int size, j=0;
      size = ArraySize(src);
      ArrayResize(dstn, size-1);
      for(int i=0;i<size;i++)
        {
            if(i!=idx)
              {
                  dstn[j] = src[i];
                  j++;
              }
        }
  }

//+------------------------------------------------------------------+
//| Check SR levels function                                         |
//+------------------------------------------------------------------+
bool Check_SR(double hi, double lo, double strength)
  {
      bool ret      = true;                                   //ret = true
      int  size_up  = ArraySize(sr_up_level);
      double sr_sum = DoubleArraySum(sr_up_level);
      if(sr_sum)                                             //if array.size(sr_up_level) > 0
        {
            for(int i=0;i<size_up;i++)                       //for i = 0 to array.size(sr_up_level) - 1
              {
                                                             //if array.get(sr_up_level, i) >= lo and array.get(sr_up_level, i) <= hi  or 
                                                             //array.get(sr_dn_level, i) >= lo and array.get(sr_dn_level, i) <= hi
                  if(((sr_up_level[i] >= lo) && (sr_up_level[i] <= hi)) || ((sr_dn_level[i] >= lo) && (sr_dn_level[i] <= hi)))
                    {
                        if(strength >= sr_strength[i])       //if strength >= array.get(sr_strength, i)
                          {
                              //double sr_s[], sr_u[], sr_d[];
                              //Remove(sr_strength, sr_s, i);        //array.remove(sr_strength, i)
                              //Remove(sr_up_level, sr_u, i);        //array.remove(sr_up_level, i)
                              //Remove(sr_dn_level, sr_d, i);        //array.remove(sr_dn_level, i)
                              //ArrayResize(sr_strength, ArraySize(sr_s));
                              //ArrayResize(sr_up_level, ArraySize(sr_u));
                              //ArrayResize(sr_dn_level, ArraySize(sr_d));
                              //ArrayCopy(sr_strength, sr_s);
                              //ArrayCopy(sr_up_level, sr_u);
                              //ArrayCopy(sr_dn_level, sr_d);
                              //sr_strength[i] = 0.0;
                              //sr_up_level[i] = 0.0;
                              //sr_dn_level[i] = 0.0;
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
//| Select SR Levels                                                 |
//+------------------------------------------------------------------+
void Get_SR_Vals(int idx, double &lo, double &hi, int &numpp)
  {
      int size, i;
      double cpp, wdth;
      lo    = Pivotvals[idx];
      hi    = lo;
      numpp = 0;
      size  = ArraySize(Pivotvals);
      for(i = 0; i < size; i++)
        {
            cpp = Pivotvals[i];
            if(cpp <= lo)
              {
                  wdth = hi - cpp;
              }
            else
              {
                  wdth = cpp - lo;
              }
            if(wdth <= cwidth)
              {
                  if(cpp <= lo)
                    {
                        lo = cpp;
                    }
                  if(cpp > lo)
                    {
                        hi = cpp;
                    }
                  numpp++;
              }
        }
  }

//+------------------------------------------------------------------+
//| Main SR calculation function                                     |
//+------------------------------------------------------------------+
void Calculate_SR_Levels()
  {
      int i, j, strength, loc;
      double hi, lo;
      //+--------------------------------------------------------------------------+
      //+ SR levels clean up because of new calculation
      //+--------------------------------------------------------------------------+
      ArrayResize(sr_up_level, maxnumsr);
      ArrayResize(sr_dn_level, maxnumsr);
      ArrayResize(sr_strength, maxnumsr);
      ArrayInitialize(sr_up_level, 0.0);
      ArrayInitialize(sr_dn_level, 0.0);
      ArrayInitialize(sr_strength, 0.0);
      //+--------------------------------------------------------------------------+
      //+--------------------------------------------------------------------------+
      bTime = TimeCurrent();
      if(!MathIsValidNumber(bTime))
        {
            MathMin(bTime, Time[0] - Time[1]);
        }
      //+--------------------------------------------------------------------------+
      //+--------------------------------------------------------------------------+
      bool opened       = bTime > Time[0] && bTime < Time[0]+(_Period*60);
      //+--------------------------------------------------------------------------+
      //+--------------------------------------------------------------------------+
      double prdhighest = High[iHighest(_Symbol, _Period, MODE_HIGH, 300, 0)];
      double prdlowest  = Low[iLowest(_Symbol, _Period, MODE_LOW, 300, 0)];
      cwidth            = (prdhighest - prdlowest) * channelw / 100;
      //+--------------------------------------------------------------------------+
      //+ Find Pivots
      //+--------------------------------------------------------------------------+      
      ArrayResize(Pivotvals, maxnumpp);
      j = 0;
      i = 0;
      
      while(j < maxnumpp) // i has no limit, no max period
        {
            Ls = iCustom(_Symbol, _Period, "../Indicators/ZigZag", MODE_HIGH, i);
            Hs = iCustom(_Symbol, _Period, "../Indicators/ZigZag", MODE_LOW, i);
            
            if(Hs > 0)
              {
                  Pivotvals[j] = Hs;
                  j++;
              }
            if(Ls > 0)
              {
                  Pivotvals[j] = Ls;
                  j++;
              }
            
            i++;
        }
      //+--------------------------------------------------------------------------+
      //+ Find SR Zones
      //+--------------------------------------------------------------------------+
      j = 0;
      for(i=0;i<maxnumpp;i++)
        {
            Get_SR_Vals(i, lo, hi, strength);
            if(Check_SR(hi, lo, strength))
              {
                  loc = Find_Loc(strength);
                  if(loc < maxnumsr && strength >= min_strength && j < maxnumsr)
                    {
                        sr_strength[loc] = double(strength);
                        sr_up_level[loc] = hi;
                        sr_dn_level[loc] = lo;
                        j++;
                    }
              }
        }
      //+--------------------------------------------------------------------------+
      //+--------------------------------------------------------------------------+
  }


void OnTick()
  {       
      //Support Ressistance calculations
      Calculate_SR_Levels();
      bool flag_sr = false;
      int i = 0;
      while(i < maxnumsr && !flag_sr)
        {
            if(sr_up_level[i] || sr_dn_level[i])
              {
                  if(sr_up_level[i])
                    {
                        ObjectDelete(0, string(i));
                        ObjectCreate(0, string(i), OBJ_HLINE, 0, TimeCurrent(), sr_up_level[i]);
                        ObjectSetInteger(0, string(i), OBJPROP_STYLE, STYLE_DASH);
                        ObjectSetInteger(0, string(i), OBJPROP_WIDTH, 2);
                        ObjectSetInteger(0, string(i), OBJPROP_BACK, false);
                        if(Ask < sr_up_level[i])
                          {
                              ObjectSetInteger(0, string(i), OBJPROP_COLOR, clrRed);
                          }
                        else
                          {
                              ObjectSetInteger(0, string(i), OBJPROP_COLOR, clrLimeGreen);
                          }
                    }
                  if(sr_dn_level[i])
                    {
                        ObjectDelete(0, string(i));
                        ObjectCreate(0, string(i), OBJ_HLINE, 0, TimeCurrent(), sr_dn_level[i]);
                        ObjectSetInteger(0, string(i), OBJPROP_STYLE, STYLE_DASH);
                        ObjectSetInteger(0, string(i), OBJPROP_WIDTH, 2);
                        ObjectSetInteger(0, string(i), OBJPROP_BACK, false);
                        if(Ask < sr_dn_level[i])
                          {
                              ObjectSetInteger(0, string(i), OBJPROP_COLOR, clrRed);
                          }
                        else
                          {
                              ObjectSetInteger(0, string(i), OBJPROP_COLOR, clrLimeGreen);
                          }
                    }
                  i++;
              }
            else
              {
                  break;
              }
        }
  }
