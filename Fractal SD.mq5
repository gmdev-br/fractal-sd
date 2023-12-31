//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Fractal Supply & Demand"

#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   2

enum enum_hhll {
   enableAll,
   enableUp,
   enableDown
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES         inputPeriodo = PERIOD_CURRENT;
input string                  inputAtivo = "";
input int                     LevDP = 2;       // Fractal Period or Levels Demar Pint
input int                     qSteps = 1000;     // Number  Trendlines per UpTrend or DownTrend
input int                     BackStep = 0;  // Number of Steps Back
input int                     ArrowCodeUp = 233;
input int                     ArrowCodeDown = 234;
input bool                    plotMarkers = true;

input color                   buyFractalColor = clrLime;
input color                   sellFractalColor = clrRed;

input string                  UniqueID  = "fractal_sd"; // Indicator unique ID
input int                     WaitMilliseconds = 1000;  // Timer (milliseconds) for recalculation
input bool                    useHL = true;
input double                  zone_factor = 0.25;
input int offset = 1;

input datetime                   DefaultInitialDate              = "2023.8.29 15:00:00";          // Data inicial padrão
input datetime                   DefaultFinalDate                = -1;                             // Data final padrão
input bool                       EnableEvents                    = false;                          // Ativa os eventos de teclado
input color                      TimeFromColor                   = clrLime;                        // ESQUERDO: cor
input int                        TimeFromWidth                   = 1;                              // ESQUERDO: largura
input ENUM_LINE_STYLE            TimeFromStyle                   = STYLE_DASH;                     // ESQUERDO: estilo
input color                      TimeToColor                     = clrRed;                         // DIREITO: cor
input int                        TimeToWidth                     = 1;                              // DIREITO: largura
input ENUM_LINE_STYLE            TimeToStyle                     = STYLE_DASH;                     // DIREITO: estilo
//input bool                       AutoLimitLines                  = true;                           // Automatic limit left and right lines
input bool                       FitToLines                      = true;                           // Automatic fit histogram inside lines
input bool                       KeepRightLineUpdated            = true;                           // Automatic update of the rightmost line
input int                        ShiftCandles                    = 6;                              // Distance in candles to adjust on automatic
input bool                       fill = true;

input bool     shortMode = true;
input int      shortStart = 1;
input int      shortEnd = 4;
input bool     enable5m = true;
input bool     enable15m = true;
input bool     enable30m = true;
input bool     enable60m = false;
input bool     enable120m = false;
input bool     enable240m = false;
input bool     enableD = false;
input bool     enableW = false;
input bool     enableMN = false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double bufferRes[], Fractal1[];
double bufferSup[], Fractal2[];
double arrayClose[];
double precoAtual;

string ativo;
ENUM_TIMEFRAMES periodo;
int somaPeriodos = -1;

datetime       data_inicial;         // Data inicial para mostrar as linhas
datetime       data_final;         // Data final para mostrar as linhas
datetime       timeFrom;
datetime       timeTo;
datetime       minimumDate;
datetime       maximumDate;

int            barFrom, barTo;
int            indiceFinal, indiceInicial;

int resCount = 0, supCount = 0;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {

   ativo = inputAtivo;
   StringToUpper(ativo);
   if (ativo == "")
      ativo = _Symbol;

   periodo = inputPeriodo;
   _lastOK = false;

   _timeFromLine = UniqueID + "-from";
   _timeToLine = UniqueID + "-to";

   if (inputAtivo != "")
      ativo = inputAtivo;

   data_inicial = DefaultInitialDate;
   if (KeepRightLineUpdated && ((DefaultFinalDate == -1) || (DefaultFinalDate > iTime(ativo, PERIOD_CURRENT, 0))))
      data_final = iTime(ativo, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   _timeToColor = TimeToColor;
   _timeFromColor = TimeFromColor;
   _timeToWidth = TimeToWidth;
   _timeFromWidth = TimeFromWidth;
   _lastOK = false;

//SetIndexBuffer(0, Fractal1, INDICATOR_DATA);
   ArraySetAsSeries(Fractal1, true);

//SetIndexBuffer(1, Fractal2, INDICATOR_DATA);
   ArraySetAsSeries(Fractal2, true);

//SetIndexBuffer(2, bufferRes, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(bufferRes, true);

//SetIndexBuffer(3, bufferSup, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(bufferSup, true);

//if (plotMarkers) {
//   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
//   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
//} else {
//   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
//   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
//}

//   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
//   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
//
//   PlotIndexSetInteger(0, PLOT_LINE_COLOR, sellFractalColor);
//   PlotIndexSetInteger(1, PLOT_LINE_COLOR, buyFractalColor);
//
//   PlotIndexSetInteger(0, PLOT_ARROW, ArrowCodeDown);
//   PlotIndexSetInteger(1, PLOT_ARROW, ArrowCodeUp);

   if (shortMode) {
      if (enable5m) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_M5, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enable15m) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_M15, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enable30m) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_M30, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enable60m) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_H1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enable120m) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_H2, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enable240m) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_H4, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enableD) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_D1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enableW) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_W1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
      if (enableMN) {
         somaPeriodos++;
         _lastOK = Update(PERIOD_MN1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
      }
   } else {
      _lastOK = Update(PERIOD_CURRENT, LevDP, shortStart, shortEnd);
   }

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);
//Update();

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {

   delete(_updateTimer);
   ObjectsDeleteAll(0, UniqueID);
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update(ENUM_TIMEFRAMES p_tf, int fractal_period, int start, int end) {

   verifyDates();

   supCount = 0;
   resCount = 0;

   barFrom = iBarShift(NULL, p_tf, timeFrom);
   barTo = iBarShift(NULL, p_tf, timeTo);

   ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, timeFrom);
   ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, timeTo);

   if(timeFrom > timeTo)
      Swap(timeFrom, timeTo);

   int primeiroCandle = WindowFirstVisibleBar();
   int ultimoCandle = WindowFirstVisibleBar() - WindowBarsPerChart();
   int lineFromPosition = 0, lineToPosition = 0;
   if (FitToLines == true) {
      lineFromPosition = iBarShift(ativo, p_tf, GetObjectTime1(_timeFromLine), 0);
      lineToPosition = iBarShift(ativo, p_tf, GetObjectTime1(_timeToLine), 0);
   }

   string tf_name = GetTimeFrame(p_tf);
   string line_up = UniqueID + "_res_" + tf_name + "_";
   string line_down = UniqueID + "_sup_" + tf_name + "_";

   ObjectsDeleteAll(0, line_up);
   ObjectsDeleteAll(0, line_down);

   long totalRates = SeriesInfoInteger(ativo, p_tf, SERIES_BARS_COUNT);
//if (MathAbs(barFrom - barTo) < totalRates)
//   totalRates = MathAbs(barFrom - barTo) + 1;
   double onetick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   ArrayResize(bufferRes, totalRates);
   ArrayResize(bufferSup, totalRates);
   ArrayResize(Fractal1, totalRates);
   ArrayResize(Fractal2, totalRates);

   ArrayInitialize(bufferRes, 0.0);
   ArrayInitialize(bufferSup, 0.0);
   ArrayInitialize(Fractal1, 0.0);
   ArrayInitialize(Fractal2, 0.0);

   static datetime prevTime = 0;
   int cnt = 0;

   for(cnt = barFrom; cnt > barTo; cnt--) {
      bufferRes[cnt] = DemHigh(p_tf, cnt, fractal_period);
      bufferSup[cnt] = DemLow(p_tf, cnt, fractal_period);
      Fractal1[cnt] =  bufferRes[cnt];
      Fractal2[cnt] =  bufferSup[cnt];
   }

// logic for resistance points
   for(cnt = 1; cnt <= resCount; cnt++) {
      double nextSup;
      int res = GetTD(cnt, bufferRes);
      if (res < 0)
         break;

      double origem = bufferRes[res];
      bool valid = true;
      for(int j = res - 1; j > barTo; j--) {
         double atual = iHigh(NULL, p_tf, j);
         if (atual > origem)
            valid = false;
         int a = 0;
      }

      for(int k = res; k > barTo; k--) {
         if (bufferSup[k] > 0) {
            nextSup = bufferSup[k];
            break;
         }
      }

      double interMin = 999999999999999999999;
      for(int k = res; k > barTo; k--) {
         if (bufferSup[k] > 0 && bufferSup[k] <= interMin) {
            interMin = bufferSup[k];
         } else if(bufferSup[k] > 0 && bufferSup[k] > interMin) {
            break;
         }
      }

      if ((MathAbs(origem - interMin) < zone_factor / 100 * origem) || interMin == 999999999999999999999)
         valid = false;

      double range = MathAbs(origem - interMin);
      if (range == 0 || zone_factor * range <= 0.15 / 100 * origem)
         range = 0.15 / 100 * origem * 4;

      if (valid) {
         datetime start_time = shortMode ? iTime(NULL, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * start : iTime(NULL, p_tf, res);
         datetime end_time = shortMode ? iTime(NULL, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * end : iTime(NULL, p_tf, barTo);
         ObjectCreate(0, line_up + cnt, OBJ_RECTANGLE, 0, start_time, origem, end_time, origem - zone_factor * range);
         ObjectSetInteger(0, line_up + cnt, OBJPROP_COLOR, clrRed);
         //ObjectSetInteger(0, UniqueID + "_res_" + cnt, OBJPROP_FILL, fill);
      }
   }

// logic for support points
   for(cnt = 1; cnt <= supCount; cnt++) {
      double nextRes, nextSup;
      //int indexNextSup, indexNextRes;
      int sup = GetTD(cnt, bufferSup);
      if (sup < 0)
         break;

      double origem = bufferSup[sup];
      bool valid = true;
      for(int j = sup - 1; j > barTo; j--) {
         double atual = iLow(NULL, p_tf, j);
         if (atual < origem)
            valid = false;
         int a = 0;
      }

      for(int k = sup; k > barTo; k--) {
         if (bufferRes[k] > 0) {
            //indexNextRes = k;
            nextRes = bufferRes[k];
            break;
         }
      }

      double interMax = 0;
      for(int k = sup; k > barTo; k--) {
         if (bufferRes[k] > 0 && bufferRes[k] >= interMax) {
            interMax = bufferRes[k];
         } else if(bufferRes[k] > 0 && bufferRes[k] < interMax) {
            break;
         }
      }

      if ((MathAbs(origem - interMax) < zone_factor / 100 * origem) || interMax == 0)
         valid = false;

      double range = MathAbs(origem - interMax);
      if (range == 0 || zone_factor * range <= 0.15 / 100 * origem)
         range = 0.15 / 100 * origem * 4;

      if (valid) {
         datetime start_time = shortMode ? iTime(NULL, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * start : iTime(NULL, p_tf, sup);
         datetime end_time = shortMode ? iTime(NULL, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * end : iTime(NULL, p_tf, barTo);
         ObjectCreate(0, line_down + cnt, OBJ_RECTANGLE, 0, start_time, origem, end_time, origem + zone_factor * range);
         ObjectSetInteger(0, line_down + cnt, OBJPROP_COLOR, clrLime);
         //ObjectSetInteger(0, UniqueID + "_sup_" + cnt, OBJPROP_FILL, fill);
         //ObjectSetInteger(0, UniqueID + "_sup_" + cnt, OBJPROP_BACK, fill);
      }
   }

   ChartRedraw();

   return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double & price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   somaPeriodos = -1;
   if(_updateTimer.Check() || !_lastOK) {
      if (shortMode) {
         if (enable5m) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_M5, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enable15m) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_M15, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enable30m) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_M30, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enable60m) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_H1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enable120m) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_H2, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enable240m) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_H4, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enableD) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_D1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enableW) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_W1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
         if (enableMN) {
            somaPeriodos++;
            _lastOK = Update(PERIOD_MN1, LevDP, shortStart + somaPeriodos * (shortEnd - shortStart) + 1, shortEnd + somaPeriodos * (shortEnd - shortStart));
         }
      } else {
         _lastOK = Update(PERIOD_CURRENT, LevDP, shortStart, shortEnd);
      }
      //Print("Trendlines " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//| Returns the name of the day of the week                          |
//+------------------------------------------------------------------+
string DayOfWeek(const datetime time) {
   MqlDateTime dt;
   string day = "";
   TimeToStruct(time, dt);

   return dt.day_of_week;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRandRange(double x, double y) {
   return(x + MathMod(MathRand(), MathAbs(x - (y + 1))));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTD(int P, const double & Arr[]) {
   int i = barFrom, j = 0;
   while(j < P) {
      i--;
      while(Arr[i] == 0) {
         i--;
         if(i < 2)
            return(-1);
      }
      j++;
   }
   return (i);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void verifyDates() {

   minimumDate = iTime(ativo, PERIOD_CURRENT, iBars(ativo, PERIOD_CURRENT) - 2);
   maximumDate = iTime(ativo, PERIOD_CURRENT, 0);

   timeFrom = GetObjectTime1(_timeFromLine);
   timeTo = GetObjectTime1(_timeToLine);

   data_inicial = DefaultInitialDate;
   data_final = DefaultFinalDate;
   if (KeepRightLineUpdated && ((DefaultFinalDate == -1) || (DefaultFinalDate > iTime(ativo, PERIOD_CURRENT, 0))))
      data_final = iTime(ativo, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   if ((timeFrom == 0) || (timeTo == 0)) {
      timeFrom = data_inicial;
      timeTo = data_final;
      DrawVLine(_timeFromLine, timeFrom, _timeFromColor, _timeFromWidth, TimeFromStyle, true, false, true, 1000);
      DrawVLine(_timeToLine, timeTo, _timeToColor, _timeToWidth, TimeToStyle, true, false, true, 1000);
   }

   if (ObjectGetInteger(0, _timeFromLine, OBJPROP_SELECTED) == false) {
      timeFrom = data_inicial;
   }

   if (ObjectGetInteger(0, _timeToLine, OBJPROP_SELECTED) == false) {
      timeTo = data_final;
   }

   if ((timeFrom < minimumDate) || (timeFrom > maximumDate))
      timeFrom = minimumDate;

   if ((timeTo >= maximumDate) || (timeTo < minimumDate))
      timeTo = maximumDate + PeriodSeconds(PERIOD_CURRENT) * ShiftCandles;

   ObjectSetInteger(0, _timeFromLine, OBJPROP_TIME, 0, timeFrom);
   ObjectSetInteger(0, _timeToLine, OBJPROP_TIME, 0, timeTo);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemHigh(ENUM_TIMEFRAMES p_tf, int cnt, int sh) {
   if(iHigh(ativo, p_tf, cnt) >= iHigh(ativo, p_tf, cnt + sh) && iHigh(ativo, p_tf, cnt) > iHigh(ativo, p_tf, cnt - sh)) {
      if(sh > 1) {
         resCount++;
         return(DemHigh(p_tf, cnt, sh - 1));
      } else {
         if (useHL)
            return(iHigh(ativo, p_tf, cnt));
         else
            return(MathMax(iClose(ativo, p_tf, cnt), iOpen(ativo, p_tf, cnt)));
      }
   } else
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemLow(ENUM_TIMEFRAMES p_tf, int cnt, int sh) {
   if(iLow(ativo, p_tf, cnt) <= iLow(ativo, p_tf, cnt + sh) && iLow(ativo, p_tf, cnt) < iLow(ativo, p_tf, cnt - sh)) {
      if(sh > 1) {
         supCount++;
         return(DemLow(p_tf, cnt, sh - 1));
      } else {
         if (useHL)
            return(iLow(ativo, p_tf, cnt));
         else
            return(MathMin(iClose(ativo, p_tf, cnt), iOpen(ativo, p_tf, cnt)));
      }
   } else
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long & lparam,
                  const double & dparam,
                  const string & sparam) {

//if(id == CHARTEVENT_CHART_CHANGE) {
//   _lastOK = false;
//   CheckTimer();
//}

   if(id == CHARTEVENT_OBJECT_DRAG) {
      if((sparam == _timeFromLine) || (sparam == _timeToLine)) {
         _lastOK = false;
         ChartRedraw();
         CheckTimer();
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime GetObjectTime1(const string name) {
   datetime time;

   if(!ObjectGetInteger(0, name, OBJPROP_TIME, 0, time))
      return(0);

   return(time);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRound(const double value, const double error) {
   return(error == 0 ? value : MathRound(value / error) * error);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void Swap(T & value1, T & value2) {
   T tmp = value1;
   value1 = value2;
   value2 = tmp;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime miTime(string symbol, ENUM_TIMEFRAMES timeframe, int index) {
   if(index < 0)
      return(-1);

   datetime arr[];

   if(CopyTime(symbol, timeframe, index, 1, arr) <= 0)
      return(-1);

   return(arr[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowBarsPerChart() {
   return((int)ChartGetInteger(0, CHART_WIDTH_IN_BARS));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int WindowFirstVisibleBar() {
   return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVLine(const string name, const datetime time1, const color lineColor, const int width, const int style, const bool back = true, const bool hidden = true, const bool selectable = true, const int zorder = 0) {
   ObjectDelete(0, name);

   ObjectCreate(0, name, OBJ_VLINE, 0, time1, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}

string _timeFromLine;
string _timeToLine;

color _timeToColor;
color _timeFromColor;
int _timeToWidth;
int _timeFromWidth;
//+------------------------------------------------------------------+
