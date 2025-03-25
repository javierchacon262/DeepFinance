//+------------------------------------------------------------------+
//|                                                         Zeus.mq4 |
//|                                                    Javier Chacon |
//|                               https://github.com/javierchacon262 |
//+------------------------------------------------------------------+
#property copyright "Javier Chacon"
#property link      "https://github.com/javierchacon262"
#property version   "1.00"
#property strict

//--- input parameters
input int             ema5_purple  = 5;
input int             ema13_red    = 13;
input int             ema50_aqua   = 50;
input int             ema200_grey  = 200;
input int             ema800_blue  = 800;
input int             macd1_fast   = 12;
input int             macd1_slow   = 26;
input int             macd1_signal = 9;
input int             rsi_period   = 14;
input double          ttresh       = 0.1;
input double          gthresh      = 0.5;

input double          epsilon      = 0.3;
input double          sr_epsilon   = 0.5;
input double          dr_epsilon   = 1.0;
input int             sr_confirm   = 2;

// SR levels input parameters
// SR levels input parameters
input int             max_period    = 200;
input int             maxnumsr      = 70;
input int             maxnumcl      = 7;
input int             maxnumpp      = 150;
input int             prd           = 10;
input int             channel_width = 10;
input int             min_strength  = 2;
input int             interval      = 1000;
input ENUM_LINE_STYLE style         = STYLE_DASH;
input int             width         = 2;
input bool            background    = false;
input int             min_fonts     = 1;

//--- SR Global variables
int            Strength[], New_Strength[];
double         SR_Levels[], Clusters[], Norm_Strength[];
color          clr;

//--- Global variables
int                   weigth, srnum, SR_Num, sells, buys, label_id, label_id2;
double                ema5, ema13, ema50, ema200, ema800, macd, macd_main, macd_sign, macd_hist, rsi, over, macd_rsi, SR_Temp;
bool                  cross_d1, cross_u1, cross_d2, cross_u2, cross_d3, cross_u3, cross_d4, cross_u4, cross_d5, cross_u5, flag_draw;
string                notification;

int OnInit()
  {   
      label_id     = 0;
      label_id2    = 0;
      sells        = 0;
      buys         = 0;
      flag_draw    = false;
      cross_d1     = false;
      cross_u1     = false;
      cross_d2     = false;
      cross_u2     = false;
      cross_d3     = false;
      cross_u3     = false;
      cross_d4     = false;
      cross_u4     = false;
      cross_d5     = false;
      cross_u5     = false;
      notification = StringConcatenate("Zeus is Angry:\n\n",
                                       "Buy Strength:  ", IntegerToString(buys), "\n\n",
                                       "Sell Strength: ", IntegerToString(sells), "\n\n",
                                       "Time:          ", string(TimeCurrent()), ".");
      return(INIT_SUCCEEDED);
  }
  
void OnDeinit()
  {
      ObjectsDeleteAll();
  }
  
//+------------------------------------------------------------------+
//| Array Sum Function                                               |
//+------------------------------------------------------------------+
int ArraySum(int &array[])
  {
      int summation = 0;
      for(int i = ArraySize(array) - 1; i >= 0; i--)
        {
            summation += array[i];
        }
      return summation;
  }
  
//+------------------------------------------------------------------+
//| Clean Zeros Function INT                                         |
//+------------------------------------------------------------------+
void ClearNum(int &array[], int num, int &new_ar[])
  {
      int ars    = ArraySize(array);
      int new_si;
      int offset = 0;
      for(int x=0; x<ars; x++)
        {
            if(array[x]==num)
               offset++;
            else
               array[x-offset]=array[x];
        }
      new_si = ars-offset;
      ArrayResize(new_ar, new_si);
      for(int i=0; i<new_si; i++)
        {
            new_ar[i] = array[i];
        }
  }

//+------------------------------------------------------------------+
//| Clean Zeros Function DOUBLE                                      |
//+------------------------------------------------------------------+
void ClearNumD(double &array[], double num, double &new_ar[])
  {
      int ars = ArraySize(array);
      int new_si;
      int offset = 0;
      for(int x = 0; x < ars; x++)
        {
            if(array[x] == num)
               offset++;
            else
               array[x-offset] = array[x];
        }
      new_si = ars - offset;
      ArrayResize(new_ar, new_si);
      for(int i = 0; i < new_si; i++)
        {
            new_ar[i] = array[i];
        }
  }

//+------------------------------------------------------------------+
//| Seek value in array function                                     |
//+------------------------------------------------------------------+
bool SeekIn(int &array[], int val)
  {
      int sa = ArraySize(array);
      for(int i=0; i<sa; i++)
        {
            if(val == array[i])
              {
                  return false;
              }
        }
      return true;
  }
  
//+------------------------------------------------------------------+
//| Select SR Levels from general Histogram                          |
//+------------------------------------------------------------------+
void SelectSR(int &array[], int &SR[], double &SRD[], int min)
  {
      int i = 0, max_idx, temp_max, temp_vec[];
      bool flag;
      int svec                   = ArraySum(array);
      while(i < maxnumsr && svec)
        {
            max_idx              = ArrayMaximum(array, WHOLE_ARRAY, 0);
            temp_max             = array[max_idx];
            flag                 = SeekIn(SR, max_idx+min);
            svec                 = ArraySum(array);
            if(flag)
              {
                  SR[i]          = max_idx + min;
                  SRD[i]         = double(max_idx + min) / double(interval);
                  if(ArraySize(New_Strength))
                    {
                        ArrayCopy(temp_vec, New_Strength);
                        ArrayResize(New_Strength, ArraySize(temp_vec)+1);
                        for(int j = 0; j < ArraySize(temp_vec); j++)
                          {
                              New_Strength[j] = temp_vec[j];
                          }
                    }
                  else
                    {
                        ArrayResize(New_Strength, 1);
                    }
                  New_Strength[ArraySize(temp_vec)] = array[max_idx];
                  array[max_idx] = 0;
                  i++;
              }
        }
  }
  
//+------------------------------------------------------------------+
//| SR Levels Main Calculation Function                              |
//+------------------------------------------------------------------+  
void CalculateSRLevels(double &Levels[], int &strength[])
  {
      //---
      int i,limit;
      double Hs, Ls, PivotsBuffer1[], PivotsBuffer2[], SRD[], CleanSR[], NumSRClean[];
      int NewHs[], NewLs[], SR[];
      //--- last counted bar will be recounted
      limit = max_period;
   
      int HsInt[], LsInt[];
      
      ArrayResize(HsInt, limit);
      ArrayResize(LsInt, limit);
      ArrayResize(PivotsBuffer1, limit);
      ArrayResize(PivotsBuffer2, limit);
      ArrayResize(SR, maxnumsr);
      ArrayResize(SRD, maxnumsr);
   
      for(i=0; i<limit; i++)
        {
            Ls = iCustom(_Symbol, _Period, "../Indicators/ZigZag", MODE_HIGH, i);
            Hs = iCustom(_Symbol, _Period, "../Indicators/ZigZag", MODE_LOW, i);
      
            if(Hs > 0)
              {
                  PivotsBuffer1[i] = Hs;
                  HsInt[i]         = int(Hs * interval);
              }
      
            if(Ls > 0)
              {
                  PivotsBuffer2[i] = Ls;
                  LsInt[i]         = int(Ls * interval);
              }
        }
      int HsIntSum                 = ArraySum(HsInt);
      int LsIntSum                 = ArraySum(LsInt);
   
      ClearNum(HsInt, 0, NewHs);
      ClearNum(LsInt, 0, NewLs);
   
      int min_ls                   = NewLs[ArrayMinimum(NewLs, WHOLE_ARRAY, 0)];
      int max_ls                   = NewLs[ArrayMaximum(NewLs, WHOLE_ARRAY, 0)];
      int max_hs                   = NewHs[ArrayMaximum(NewHs, WHOLE_ARRAY, 0)];
      int min_hs                   = NewHs[ArrayMinimum(NewHs, WHOLE_ARRAY, 0)];
      int max                      = MathMax(max_ls, max_hs);
      int min                      = MathMin(min_ls, min_hs);
      int HistSize                 = max - min;
      int NewHSize                 = ArraySize(NewHs);
      int NewLSize                 = ArraySize(NewLs);
      ArrayResize(strength, HistSize);
   
      for(i=0; i<NewHSize; i++)
         strength[NewHs[i] - min - 1]++;
   
      for(i=0; i<NewLSize; i++)
         strength[NewLs[i] - min]++;
   
      //Select what are going to be the SR levels
      SelectSR(strength, SR, SRD, min);
      ClearNumD(SRD, 0.0, Levels);
  }

//+------------------------------------------------------------------+
//| Clean levels function - K-Means and Ponderate Average            |
//+------------------------------------------------------------------+
void Clean_Levels(double &levels[], double &clusters[])
  {
      
      double str_sum[];
      int conts[], labels[];
      
      ArrayResize(clusters, maxnumcl);
      ArrayResize(conts, maxnumcl);
      ArrayResize(str_sum, maxnumcl);
      ArrayInitialize(clusters, 0.0);
      ArrayInitialize(conts, 0);
      ArrayInitialize(str_sum, 0.0);
      
      double lmax = levels[ArrayMaximum(levels)];
      double lmin = levels[ArrayMinimum(levels)];
      double range = lmax - lmin;
      double cl_range = range / maxnumcl;
      int lsize = ArraySize(levels);
      ArrayResize(labels, lsize);
      ArrayResize(Norm_Strength, lsize);
      for(int i = 0; i < lsize; i++)
        {
            for(int j = 0; j < maxnumcl; j++)
              {
                  if(levels[i] >= (lmin + (j*cl_range)) && levels[i] <= (lmin + ((j+1)*cl_range)))
                    {
                        labels[i] = j;
                        conts[j]++;
                        str_sum[j] = str_sum[j] + New_Strength[i];
                        break;
                    }
              }
        }
      
      for(int i = 0; i < lsize; i++)
        {
            Norm_Strength[i] = double(New_Strength[i]) / double(str_sum[labels[i]]);
            clusters[labels[i]] = clusters[labels[i]] + (levels[i] * Norm_Strength[i]);
        }
  }

//+------------------------------------------------------------------+
//| Seek for the nearest SR levels to the price and see if it's close|
//+------------------------------------------------------------------+
bool NearestSRB()
  {
      int size = ArraySize(Clusters);
      double dist_vec[];
      ArrayResize(dist_vec, size);
      for(int i = 0; i < size; i++)
        {
            dist_vec[i] = MathAbs(((Bid+Ask)/2) - Clusters[i]);            
        }
      double min = dist_vec[ArrayMinimum(dist_vec)];
      if(min <= sr_epsilon)
         return true;
      return false;
  }
  
double NearestSRD()
  {
      int size = ArraySize(Clusters);
      double dist_vec[];
      ArrayResize(dist_vec, size);
      for(int i = 0; i < size; i++)
        {
            dist_vec[i] = MathAbs(((Bid+Ask)/2) - Clusters[i]);            
        }
      double min = dist_vec[ArrayMinimum(dist_vec)];
      return min;
  }
  
//+------------------------------------------------------------------+
//| Draw label fucntion                                              |
//+------------------------------------------------------------------+
void DrawLabel(string id, int subw, int num, datetime x1, double vPrice, double draw_epsilon, color vcolor)
  {
      // Label
      string label = id;
      string text = StringConcatenate("Z ", IntegerToString(num));
      ObjectCreate(label, OBJ_TEXT, subw, x1, vPrice+draw_epsilon);
      ObjectSetText(label, text, min_fonts+num, "Tahoma", vcolor);
      ObjectSet(label, OBJPROP_ANGLE, 90);
      ObjectSet(label, OBJPROP_BACK, false);
  }

//+------------------------------------------------------------------+
//| Main function executed on each price change                      |
//+------------------------------------------------------------------+
void OnTick()
  {
      if(buys > 7)
         buys   = 7;
      if(sells > 7)
         sells  = 7;
      ema5      = iMA(_Symbol, _Period, ema5_purple, 0, MODE_EMA, PRICE_CLOSE, 0);
      ema13     = iMA(_Symbol, _Period, ema13_red,   0, MODE_EMA, PRICE_CLOSE, 0);
      ema50     = iMA(_Symbol, _Period, ema50_aqua,  0, MODE_EMA, PRICE_CLOSE, 0);
      ema200    = iMA(_Symbol, _Period, ema200_grey, 0, MODE_EMA, PRICE_CLOSE, 0);
      ema800    = iMA(_Symbol, _Period, ema800_blue, 0, MODE_EMA, PRICE_CLOSE, 0);
      
      macd_hist = iCustom(_Symbol, _Period, "../Indicators/MACD", 0, 0);
      macd_sign = iCustom(_Symbol, _Period, "../Indicators/MACD", 1, 0);
      macd_main = iCustom(_Symbol, _Period, "../Indicators/MACD", 2, 0);
      
      rsi       = iRSI(_Symbol, _Period, rsi_period, PRICE_CLOSE, 0);
      
      //Support Ressistance calculations
      CalculateSRLevels(SR_Levels, Strength);
      Clean_Levels(SR_Levels, Clusters);
      int SR_Size = ArraySize(Clusters);
      char SuppId;
      //Draw the SR Levels
      for(int i=0;i<SR_Size;i++)
        {
            if(Bid <= Clusters[i]) // Compare the mean price between Bid and Ask with the Levels
                 {
                     clr = clrRed;
                 }
               else
                 {
                     clr = clrLimeGreen;
                 }
            SuppId = char(i);
            ObjectDelete(0, SuppId);
            ObjectCreate(0, SuppId, OBJ_HLINE, 0, 0, Clusters[i]);                  
            ObjectSetInteger(0, SuppId, OBJPROP_COLOR, clr);
            ObjectSetInteger(0, SuppId, OBJPROP_STYLE, style);
            ObjectSetInteger(0, SuppId, OBJPROP_WIDTH, width);
            ObjectSetInteger(0, SuppId, OBJPROP_BACK, background);
        }
      
      //+------------------------------------------------------------------+
      //| Lightning bolts                                                  |
      //+------------------------------------------------------------------+      
      if(ema5 > ema13+epsilon)
        {
            buys++;
            if(sells)
               sells--;
            cross_u1 = true;
            label_id++;
        }
      else
         cross_u1 = false;
         
      if(ema5 < ema13-epsilon)
        {
            sells++;
            if(buys)
               buys--;
            label_id++;
            cross_d1 = true;
        }
      else
         cross_d1 = false;
         
      if(ema5 > ema13+epsilon && ema13 > ema50+epsilon)
        {
            buys++;
            if(sells)
               sells--;
            label_id++;
            cross_u2 = true;
        }
      else
         cross_u2 = false;
      
      if(ema5 < ema13-epsilon && ema13 < ema50-epsilon)
        {
            sells++;
            if(buys)
               buys--;
            label_id++;
            cross_d2 = true;
        }
      else
         cross_d2 = false;
      
      if(ema5 > ema13+epsilon && ema13 > ema50+epsilon && ema50 > ema200+epsilon)
        {
            buys++;
            if(sells)
               sells--;
            label_id++;
            cross_u3 = true;
        }
      else
         cross_u3 = false;
      
      if(ema5 < ema13-epsilon && ema13 < ema50-epsilon && ema50 < ema200-epsilon)
        {
            sells++;
            if(buys)
               buys--;
            label_id++;
            cross_d3 = true;
        }
      else
         cross_d3 = false;
      
      if(ema5 > ema13+epsilon && ema13 > ema50+epsilon && ema50 > ema200+epsilon && ema200 > ema800+epsilon)
        {
            buys++;
            if(sells)
               sells--;
            label_id++;
            cross_u4 = true;
        }
      else
         cross_u4 = false;
      
      if(ema5 < ema13-epsilon && ema13 < ema50-epsilon && ema50 < ema200-epsilon && ema200 < ema800-epsilon)
        {
            sells++;
            if(buys)
               buys--;
            label_id++;
            cross_d4 = true;
        }
      else
         cross_d4 = false;
        
      
      // MACD decision making
      double macd_range = macd_main - int(macd_main);
      if(macd_sign > macd_main+macd_range)
        {
            buys++;
            if(sells)
               sells--;
            label_id++;
            cross_u5 = true;
        }
      else
         cross_u5 = false;
      
      if(macd_sign < macd_main-macd_range)
        {
            sells++;
            if(buys)
               buys--;
            label_id++;
            cross_d5 = true;
        }
      else
         cross_d5 = false;
      
      
      // RSI decision making 
      if(rsi >= 65)
        {
            buys++;
            if(sells)
               sells--;
        }
      if(rsi <= 35)
        {
            sells++;
            if(buys)
               buys--;
        }
      // SR Levels confirmation level
      if(NearestSRB() && !flag_draw)
        {
            if(sells > buys+sr_confirm)
              {
                  buys++;
                  if(sells)
                     sells--;
              }
            if(buys > sells+sr_confirm)
              {
                  sells++;
                  if(buys)
                     buys--;
              }
              
            notification = StringConcatenate("Zeus is Angry:\n\n",
                                       "Buy Strength:  ", IntegerToString(buys), "\n\n",
                                       "Sell Strength: ", IntegerToString(sells), "\n\n",
                                       "Time:          ", string(TimeCurrent()), ".");
                                       
            SendNotification(notification);
            flag_draw = true;
        }
      if(!NearestSRB() && flag_draw)
        {
            flag_draw = false;
        }
        
      //Print values on screen
      string values = StringConcatenate("\n\n", 
                                        "ema5   Purple:         ", DoubleToString(ema5), "\n",
                                        "ema13  Red:            ", DoubleToString(ema13), "\n",
                                        "ema50  Aqua:           ", DoubleToString(ema50), "\n",
                                        "ema200 Gray:           ", DoubleToString(ema200), "\n",
                                        "ema800 Blue:           ", DoubleToString(ema800), "\n\n",
                                        "abs(ema5-ema13):       ", DoubleToString(MathAbs(ema5 - ema13)), "\n",
                                        "abs(ema13-ema50):      ", DoubleToString(MathAbs(ema13 - ema50)), "\n",
                                        "abs(ema50-ema200):     ", DoubleToString(MathAbs(ema50 - ema200)), "\n",
                                        "abs(ema200-ema800):    ", DoubleToString(MathAbs(ema200 - ema800)), "\n\n",
                                        "MACD abs(signal-main): ", DoubleToString(MathAbs(macd_sign - macd_main)), "\n",
                                        "RSI:                   ", DoubleToString(rsi), "\n\n",
                                        "Buy Strength:          ", IntegerToString(buys), "\n",
                                        "Sell Strength:         ", IntegerToString(sells), "\n\n",
                                        "labels flags ema5:     ", string(cross_d1), " ", string(cross_u1), "\n",
                                        "labels flags ema13:    ", string(cross_d2), " ", string(cross_u2), "\n",
                                        "labels flags ema50:    ", string(cross_d3), " ", string(cross_u3), "\n",
                                        "labels flags ema200:   ", string(cross_d4), " ", string(cross_u4), "\n",
                                        "labels flags ema800:   ", string(cross_d5), " ", string(cross_u5));
                                        //"Nearest SR Level:      ", DoubleToString(NearestSRD())
                                        //"Nearest SR Flag:       ", string(NearestSRB())
      Comment(values);
      
      if(cross_d1)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      sells,
                                      Time[0],
                                      ema13,
                                      dr_epsilon,
                                      clrWhite);
        }
      if(cross_d2)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      sells,
                                      Time[0],
                                      ema50,
                                      dr_epsilon,
                                      clrWhite);
        }
      if(cross_d3)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      sells,
                                      Time[0],
                                      ema200,
                                      dr_epsilon,
                                      clrWhite);
        }
      if(cross_d4)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      sells,
                                      Time[0],
                                      ema800,
                                      dr_epsilon,
                                      clrWhite);
        }
      if(cross_d5)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      sells,
                                      Time[0],
                                      ema800,
                                      dr_epsilon+1.0,
                                      clrWhite);
        }
        
      if(cross_u1)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      buys,
                                      Time[0],
                                      ema13,
                                      -dr_epsilon,
                                      clrGold);
        }
      if(cross_u2)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      buys,
                                      Time[0],
                                      ema50,
                                      -dr_epsilon,
                                      clrGold);
        }
      if(cross_u3)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      buys,
                                      Time[0],
                                      ema200,
                                      -dr_epsilon,
                                      clrGold);
        }
      if(cross_u4)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      buys,
                                      Time[0],
                                      ema800,
                                      -dr_epsilon,
                                      clrGold);
        }
      if(cross_u5)
        {
            DrawLabel(IntegerToString(label_id),
                                      0,
                                      buys,
                                      Time[0],
                                      ema800,
                                      -dr_epsilon-1.0,
                                      clrGold);
        }
  }
  
  //DrawLabel(IntegerToString(label_id),
  //                          0,
  //                          buys,
  //                          Time[0],
  //                          ema13,
  //                          -dr_epsilon,
  //                          clrGold);
  
  //DrawLabel(IntegerToString(label_id),
  //                          0,
  //                          sells,
  //                          Time[0],
  //                          ema13,
  //                          dr_epsilon,
  //                          clrWhite);