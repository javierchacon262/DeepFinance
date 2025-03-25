//+------------------------------------------------------------------+
//|                                                    CustomSR3.mq4 |
//|                                                    Javier Chacon |
//|                               https://github.com/javierchacon262 |
//+------------------------------------------------------------------+
#property copyright "Javier Chacon"
#property link      "https://github.com/javierchacon262"
#property version   "1.00"
#property strict

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

//--- Global variables
int            Strength[], New_Strength[];
double         SR_Levels[], Clusters[], Norm_Strength[];
color          clr;
int OnInit()
  {   
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit()
  {
      ObjectsDeleteAll();
  }
  
//+------------------------------------------------------------------+
//| Array Sum Function                              |
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
      //ArrayResize(Levels, ArraySize(SRD));
      //ArrayCopy(Levels, SRD);
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
        
      //for(int i = 0; i < maxnumcl; i++)
      //  {
      //      clusters[i] = clusters[i] / conts[i];
      //  }
  }

void OnTick()
  {        
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
   }