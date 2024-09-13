#include <Trade/Trade.mqh>


input group "Trade Settings" ;
input double Lots = 0.1;
input int TpPoints = 150;
input int PartialClosePoints = 70;
input double PartialCloseFactor = 0.5; 
input int SlPoints = 300;

input group  "CCI" ;
input ENUM_TIMEFRAMES CciTimeframe = PERIOD_CURRENT;
input int CciPeriods =14;
input ENUM_APPLIED_PRICE CciAppPrice = PRICE_TYPICAL;
input double CciBuyLevel = -200;
input double CciSellLevel = 200;

input group "Moving Average Filter" ;
input bool IsMaFilter = true;
input ENUM_TIMEFRAMES MaTimeframe = PERIOD_H1;
input int MaPeriods = 50;
input ENUM_MA_METHOD MaMethod = MODE_SMA;
input ENUM_APPLIED_PRICE MaAppPrice =PRICE_CLOSE;


int handleCci;
int handleMa;
int barsTotal;

CTrade trade;

int OnInit()
  {
barsTotal = iBars(_Symbol,CciTimeframe);
handleCci = iCCI(_Symbol, CciTimeframe,CciPeriods,CciAppPrice);
handleMa = iMA(_Symbol, MaTimeframe,MaPeriods,0,MaMethod,MaAppPrice);


 OnTick();

   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {
  
  }

void OnTick()
{

 
    double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  ask = NormalizeDouble(ask,_Digits);

    double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
  bid = NormalizeDouble(bid,_Digits);

for(int i = PositionsTotal()-1; i>=0; i--){
ulong posTicket = PositionGetTicket(i);
if(PositionSelectByTicket(posTicket)){
double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
double posVolume = PositionGetDouble(POSITION_VOLUME);

ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);


      if(posVolume==Lots){
      
       double lotsToClose = posVolume * PartialCloseFactor;
                         lotsToClose = NormalizeDouble(lotsToClose,2);
                     
               if(posType == POSITION_TYPE_BUY) {
                  if(bid > posOpenPrice+PartialClosePoints * _Point){
                 
                        
                        if( trade.PositionClosePartial(posTicket, lotsToClose)){
                              Print("Pos", posTicket," was closed partially because we programmed it....");
                     }
               
            }
       }else if(posType == POSITION_TYPE_SELL) {
         if(ask< posOpenPrice- PartialClosePoints * _Point){ 
         double lotsToClose = posVolume * PartialCloseFactor;
         lotsToClose = NormalizeDouble(lotsToClose, 2);
         
         if(trade.PositionClosePartial(posTicket,lotsToClose)){
         Print("Pos", posTicket," was closed partially because we programmed it....");

              }
            }
        }
      }
   }
 } 
  
  int bars = iBars(_Symbol,CciTimeframe);
  if(barsTotal < bars){
  barsTotal = bars;
  }
  double cci[];
  CopyBuffer(handleCci,0,1,2,cci);
  
  double ma[];
  CopyBuffer(handleMa,0,0,1,ma);
  
  if(cci[1] < -CciBuyLevel && cci[0] > -CciBuyLevel){
  Print("There is a buy signal you should buy......"); 
 

  
  if(IsMaFilter == false|| ask > ma[0]){
  
  double tp = ask + TpPoints * _Point;
  tp = NormalizeDouble(tp, _Digits);
  
  double sl = ask - SlPoints * _Point;
  sl = NormalizeDouble(sl, _Digits);
   
  trade.Buy(Lots,_Symbol, ask,sl,tp,"CCI BUY");
  }
  
 }else if(cci[1] < CciSellLevel && cci[0] < CciSellLevel){
  Print("There is a sell signal you should sell....");
  
  
 if(!IsMaFilter || bid < ma[0]) {
  
     double tp = bid - TpPoints * _Point;
     tp = NormalizeDouble(tp, _Digits);
  
     double sl = bid + SlPoints * _Point;
     sl = NormalizeDouble(sl, _Digits);
   
     trade.Sell (Lots,_Symbol, bid,sl,tp,"CCI SELL");
  
  }
  
  }
      Comment(" \nCCI[0]: ",cci[0],
      "\nCCI[1]: ",cci[1], 
      "\nMA[0]:",ma[0]);
  }
