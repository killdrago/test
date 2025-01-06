//+------------------------------------------------------------------+
//|                                                        MonEA.mq5 |
//|                              Copyright 2024 Votre Nom            |
//|                              https://www.votre-site.com          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Votre Nom"
#property link      "https://www.votre-site.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Arrays\ArrayInt.mqh>

// Définitions des objets pour l'affichage
#define TRIGGER_OBJECT_NAME "TS_Trigger_Level"
#define FOLLOWER_OBJECT_NAME "TS_Follower_Level"

// Définitions des labels pour l'affichage des informations
#define LABEL_RESPIRATION_STATUS  "LBL_RespirationStatus"
#define LABEL_SEUIL_DECLENCHEMENT "LBL_SeuilDeclenchement"
#define LABEL_SL_A                "LBL_SLA"
#define LABEL_SL_SUIVEUR          "LBL_SLSuiveur"
#define LABEL_NOUVEAUX_SL         "LBL_NouveauxSL"

// Structure pour stocker les informations de trade
struct TradeInfo {
    ulong       ticket;
    string      symbol;
    ENUM_POSITION_TYPE type;
    double      openPrice;
    double      lotSize;
    double      sl;          // Prix du Stop Loss
    double      tp;          // Prix du Take Profit
    double      slPoints;    // Nombre de points pour le SL
    double      tpPoints;    // Nombre de points pour le TP
    double      slPercentage; // Pourcentage d'équité pour le SL
    double      tpPercentage; // Pourcentage d'équité pour le TP
    bool        trailingSLActivated;
    double      trailingSL_Level;
};

TradeInfo openTrades[];

CTrade trade;
CPositionInfo position;

//--- Paramètres d'entrée
input string  magic_settings          = "=== Gestion du Magic Number ===";
input bool    UseMagicNumber          = true;             // False = Manuel + Tous magic
input int     MagicNumber             = 123456;           // Magic Number

input string  display_settings        = "=== Paramètres d'affichage ===";
input bool    DisplayTable            = true; // Afficher le tableau d'informations
input int     TextPosition            = 4;               // 1=Haut gauche, 2=Haut Droite, 3=Bas Gauche, 4=Bas Droite
input color   TextColor               = clrBlack;        // Couleur de tous les textes
input color   TableFondColor        = clrYellow;       // Couleur de fond du tableau

input string  martingale_settings     = "=== Paramètres des lots et martingale ===";
enum LotType {LotFixe, Martingale};
input LotType LotSizeType             = LotFixe;        // Type de gestion du volume
input double  FixedLotSize            = 0.01;            // Taille de lot fixe
input double  MartingaleStartLot      = 0.01;           // Lot de départ pour la martingale
input double  MartingaleMultiplier    = 2.0;            // Multiplicateur de la martingale

input string  spreadslippage          = "=== Spread et slippage ===";
input bool    UseMaxSpreadFilter      = true;            // Utiliser le filtre de spread maximum
input long    MaxSpreadPoints         = 20;              // Spread maximum autorisé en points
input long    MaxSlippagePoints       = 3;               // Slippage maximum autorisé en points

input string  trend_settings          = "=== Méthode de détermination de la tendance ===";
enum TrendMethod {Ichimoku, MA};
input TrendMethod TrendMethodChoice   = Ichimoku;  // Choix de la méthode de tendance
input ENUM_TIMEFRAMES TrendTimeframe  = PERIOD_D1;       // Unité de temps pour la tendance
input int     TrendMA_Period          = 200;             // Période de la MM pour la tendance
input bool    DisplayOnChart          = true;            // Afficher les indicateurs sur le graphique

input string  strategy_settings       = "=== Stratégie de trading ===";
enum StrategyType {MA_Crossover, RSI_OSOB, FVG_Strategy};
input StrategyType Strategy           = MA_Crossover;    // Choix de la stratégie

//--- Paramètres pour la stratégie de croisement de MM
input string  ma_settings             = "--- Paramètres des Moyennes Mobiles ---";
input int     MA_Period1              = 50;              // Période de la première MM
input int     MA_Period2              = 200;             // Période de la deuxième MM
input ENUM_MA_METHOD MA_Method        = MODE_SMA;        // Méthode de calcul des MM
input ENUM_APPLIED_PRICE MA_Price     = PRICE_CLOSE;     // Prix appliqué pour les MM

//--- Paramètres pour la stratégie RSI
input string  rsi_settings            = "--- Paramètres RSI ---";
input int     RSI_Period              = 14;              // Période du RSI
input double  RSI_OverboughtLevel    = 70.0;            // Niveau de surachat
input double  RSI_OversoldLevel      = 30.0;            // Niveau de survente

//--- Paramètres pour la stratégie FVG
input string  fvg_settings            = "--- Paramètres FVG ---";
input int     FVG_CandleLength        = 5;               // Longueur du rectangle en bougies
input double  FVG_MinAmplitudePoints  = 50;              // Amplitude minimale du FVG en points
enum FVG_Action {Breakout, Rebound};
input FVG_Action FVG_TradeAction      = Breakout;        // Action à entreprendre (Breakout ou Rebond)

input string  symbol_settings         = "=== Symboles à trader ===";
input bool    TradeAllForexPairs      = false;            // Trader toutes les paires Forex
input bool    TradeAllIndices         = false;           // Trader tous les indices
input string  CustomSymbols           = "";             // Liste personnalisée de symboles, séparés par des virgules

input string  news_settings           = "=== Gestion des actualités ===";
input bool    UseNewsFilter           = true;            // Utiliser le filtre des actualités
input int     NewsFilterMinutesBefore = 60;              // Minutes avant les actualités pour éviter le trading
input int     NewsFilterMinutesAfter  = 60;              // Minutes après les actualités pour éviter le trading
input uint    NewsImportance          = 3;               // Niveau d'importance des actualités (1=Faible, 2=Moyen, 3=Fort)

input string  stoploss_settings       = "=== Paramètres de Stop Loss ===";
enum StopType {SL_Classique, SL_Suiveur, GridTrading};
input StopType StopLossType           = SL_Classique;    // Type de Stop Loss

input string  sl_classique_settings   = "--- Paramètres SL Classique ---";
input double  StopLossCurrency        = 1.0;             // Stop Loss en devise (0 pour aucun SL)
input double  TakeProfitCurrency      = 10.0;            // Take Profit en devise (0 pour aucun TP)

input string  sl_suiveur_settings     = "=== Paramètres du SL suiveur ===";
input string  reglageslsuiveur        = "--- réglage SLsuiveur ---";
input double  InpSeuilDeclenchement   = 1.5;             // Seuil de déclenchement en devise
input bool    InpActivationRespiration = true;           // Activation de la respiration
input double  InpRespiration          = 1.0;             // Respiration pour le seuil de déclenchement en devise
input double  InpRespirationSL        = 0.5;             // Respiration pour le SL suiveur en devise
input double  InpSLsuiveur            = 30.0;            // Distance du SL suiveur en devises

//--- Paramètres pour le Grid Trading
input string  grid_settings           = "--- Paramètres du Grid Trading ---";
input double  GridTakeProfitPoints    = 100;             // Take Profit en devise
input double  GridDistancePoints      = 50;              // Distance nouvelle position du grid en devise
input int     GridMaxOrders           = 5;               // Nombre maximum de positions dans le grid

//--- Variables pour le SL suiveur
bool seuil_declenche_actif = false;
double sl_level = 0.0;
double position_price_open = 0.0;
double trailingSL = 0.0;
double adjusted_InpSeuilDeclenchement = 0.0;
double adjusted_InpRespiration = 0.0;
double adjusted_InpRespirationSL = 0.0;
double adjusted_InpSLsuiveur = 0.0;

//--- Constantes pour Ichimoku (tendance)
const int Ichimoku_Tenkan = 9;   // Période Tenkan-sen pour la tendance (fixe)
const int Ichimoku_Kijun  = 26;  // Période Kijun-sen pour la tendance (fixe)
const int Ichimoku_Senkou = 52;  // Période Senkou Span B pour la tendance (fixe)

//--- Variables globales pour la martingale
int MartingaleAttempts[]; // Tableau pour suivre les tentatives de martingale par symbole

//--- Variables globales
datetime      LastTradeTime     = 0;
string        ActiveSymbols[];          // Tableau des symboles actifs
bool          isNewMinute       = false;
datetime      lastMinuteChecked = 0;
ulong         current_ticket    = 0;    // Pour suivre le ticket de la position courante

//--- Variables pour les handles des indicateurs
int           MA_Handle1[];    // Handles pour les moyennes mobiles
int           MA_Handle2[];
int           MACD_Handle[];   // Handles pour le MACD
int           Ichimoku_Handle[]; // Handles pour l'Ichimoku

//--- Enumérations personnalisées
enum MarketTrend { TrendHaussiere, TrendBaissiere, Indecis };
enum CrossSignal { Achat, Vente, Aucun };

//+------------------------------------------------------------------+
//| Fonction d'initialisation de l'expert                            |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialisation des handles pour Ichimoku
    int ichimokuHandle = iIchimoku(Symbol(), TrendTimeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);
    if (ichimokuHandle == INVALID_HANDLE)
    {
        Print("Erreur lors de l'initialisation de Ichimoku pour ", Symbol());
        return INIT_FAILED;
    }
    
    ArrayResize(Ichimoku_Handle, 1);
    Ichimoku_Handle[0] = ichimokuHandle;

    // Initialisation des handles pour les moyennes mobiles
    ArrayResize(MA_Handle1, 1);
    ArrayResize(MA_Handle2, 1);
    
    MA_Handle1[0] = iMA(Symbol(), TrendTimeframe, MA_Period1, 0, MA_Method, MA_Price);
    MA_Handle2[0] = iMA(Symbol(), TrendTimeframe, MA_Period2, 0, MA_Method, MA_Price);

    if (MA_Handle1[0] == INVALID_HANDLE || MA_Handle2[0] == INVALID_HANDLE)
    {
        Print("Erreur lors de l'initialisation des moyennes mobiles pour ", Symbol());
        return INIT_FAILED;
    }

    Print("Handles initialisés avec succès");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Fonction de déinitialisation de l'expert                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Nettoyer les objets graphiques
   CleanupLabels(); // Appel à la fonction de nettoyage des labels

   // Supprimer d'autres objets spécifiques si nécessaire
   ObjectDelete(0, TRIGGER_OBJECT_NAME);
   ObjectDelete(0, FOLLOWER_OBJECT_NAME);

   // Supprimer le commentaire du graphique
   Comment("");

   // Afficher le message de déinitialisation
   Print("Expert Advisor déinitialisé");
}

//+------------------------------------------------------------------+
//| Fonction principale de l'expert                                  |
//+------------------------------------------------------------------+
void OnTick()
{

      // Afficher les indicateurs sur le graphique si demandé
   if (DisplayOnChart)
   {
      if (TrendMethodChoice == Ichimoku)
      {
         DisplayIchimokuOnChart();
      }
      else if (TrendMethodChoice == MA)
      {
         DisplayMAOnChart();
      }
   }
   // Mettre à jour l'affichage (tableau d'informations, lignes horizontales, etc.)
   if (DisplayTable)
   {
      DrawDisplayFrame();
   }
   
   // Vérifier les conditions de marché
   if (!IsMarketConditionsSuitable())
   {
      Print("Conditions de marché non favorables.");
      return;
   }

   // Vérifier si nous sommes sur une nouvelle minute
   datetime currentTime = TimeCurrent();
   if (currentTime > lastMinuteChecked + 60)
   {
      isNewMinute = true;
      lastMinuteChecked = currentTime;
   }
   else
   {
      isNewMinute = false;
   }

   // Mettre à jour les positions existantes (gestion des stops, etc.)
   UpdateExistingPositions();

   // Si ce n'est pas une nouvelle minute, ne pas vérifier les signaux
   if (!isNewMinute)
   {
      return; // Ne pas afficher de message, simplement sortir de la fonction
   }

   // Vérifier les actualités importantes
   if (UseNewsFilter && IsThereNews(Symbol()))
   {
      Print("Actualités importantes détectées, trading évité.");
      return;
   }
   
   // Vérifier les signaux et ouvrir des positions si nécessaire
   CheckForNewSignals();
   
    
   
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si les conditions de marché sont bonnes    |
//+------------------------------------------------------------------+
bool IsMarketConditionsSuitable()
{
   // Vérifier si c'est le week-end
   if (IsWeekend())
      return false;

   // Vérifier le spread si le filtre est activé
   if (UseMaxSpreadFilter)
   {
      long currentSpread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
      if (currentSpread > MaxSpreadPoints)
      {
         Print("Spread trop élevé: ", currentSpread);
         return false;
      }
   }

   // Vérifier si le trading est autorisé
   long tradeMode = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE);
   if (tradeMode == SYMBOL_TRADE_MODE_DISABLED)
   {
      Print("Trading non autorisé sur ce symbole");
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si c'est le week-end                      |
//+------------------------------------------------------------------+
bool IsWeekend()
{
   MqlDateTime currentDateTime;
   TimeToStruct(TimeCurrent(), currentDateTime);

   // Vérifier si c'est samedi (6) ou dimanche (0)
   return (currentDateTime.day_of_week == 0 || currentDateTime.day_of_week == 6);
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier s'il y a des actualités importantes        |
//+------------------------------------------------------------------+
bool IsThereNews(string symbol)
{
   if (!UseNewsFilter)
      return false;

   datetime currentTime = TimeCurrent();

   // Cette fonction nécessite une intégration avec un calendrier économique
   // Vous devrez implémenter votre propre logique de vérification des actualités
   // en fonction de votre source de données

   return false; // Par défaut, pas d'actualités
}

//+------------------------------------------------------------------+
//| Fonction pour construire la liste des symboles actifs            |
//+------------------------------------------------------------------+
void BuildActiveSymbolList()
{
   // Réinitialiser la liste
   ArrayResize(ActiveSymbols, 0);

   // Si TradeAllForexPairs et TradeAllIndices sont false, trader seulement le symbole actuel
   if (!TradeAllForexPairs && !TradeAllIndices && StringLen(CustomSymbols) == 0)
   {
      string currentSymbol = Symbol();
      if (SymbolInfoInteger(currentSymbol, SYMBOL_SELECT))
      {
         AddSymbolToList(currentSymbol);
      }
      else
      {
         Print("Erreur: Le symbole actuel ", currentSymbol, " n'existe pas ou n'est pas disponible.");
         return;
      }
   }

   // Liste des paires Forex principales
   string ForexPairs[] = {
      "EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD",
      "NZDUSD", "EURGBP", "EURJPY", "GBPJPY"
   };

   // Liste des indices
   string Indices[] = {
      "US30", "US500", "USTEC", "GER40", "UK100", "FRA40"
   };

   // Ajouter les paires Forex si activé
   if (TradeAllForexPairs)
   {
      for (int i = 0; i < ArraySize(ForexPairs); i++)
      {
         if (SymbolInfoInteger(ForexPairs[i], SYMBOL_SELECT))
            AddSymbolToList(ForexPairs[i]);
         else
            Print("Erreur: La paire Forex ", ForexPairs[i], " n'existe pas ou n'est pas disponible.");
      }
   }

   // Ajouter les indices si activé
   if (TradeAllIndices)
   {
      for (int i = 0; i < ArraySize(Indices); i++)
      {
         if (SymbolInfoInteger(Indices[i], SYMBOL_SELECT))
            AddSymbolToList(Indices[i]);
         else
            Print("Erreur: L'indice ", Indices[i], " n'existe pas ou n'est pas disponible.");
      }
   }

   // Ajouter les symboles personnalisés
   if (StringLen(CustomSymbols) > 0)
   {
      string customSymbolsArray[];
      StringSplit(CustomSymbols, ',', customSymbolsArray);

      for (int i = 0; i < ArraySize(customSymbolsArray); i++)
      {
         string symbol = customSymbolsArray[i];
         StringTrimRight(symbol);
         StringTrimLeft(symbol);

         if (StringLen(symbol) == 0)
         {
            Print("Erreur: Symbole vide dans CustomSymbols.");
            continue;
         }

         if (SymbolInfoInteger(symbol, SYMBOL_SELECT))
            AddSymbolToList(symbol);
         else
            Print("Erreur: Le symbole personnalisé ", symbol, " n'existe pas ou n'est pas disponible.");
      }
   }

   // Vérifier si au moins un symbole a été ajouté
   if (ArraySize(ActiveSymbols) == 0)
   {
      Print("Erreur: Aucun symbole actif trouvé. Vérifiez les paramètres de configuration.");
      return;
   }
}

//+------------------------------------------------------------------+
//| Fonction pour ajouter un symbole à la liste active              |
//+------------------------------------------------------------------+
void AddSymbolToList(string symbol)
{
   int size = ArraySize(ActiveSymbols);
   ArrayResize(ActiveSymbols, size + 1);
   ActiveSymbols[size] = symbol;
}

//+------------------------------------------------------------------+
//| Fonction pour initialiser les handles des indicateurs            |
//+------------------------------------------------------------------+
void InitializeIndicatorHandles()
{
   if (!TradeAllForexPairs && !TradeAllIndices && StringLen(CustomSymbols) == 0)
   {
      string symbol = Symbol();

      // Redimensionner les tableaux pour un seul symbole
      ArrayResize(MA_Handle1, 1);
      ArrayResize(MA_Handle2, 1);
      ArrayResize(Ichimoku_Handle, 1);

      // Initialiser les handles en fonction de la stratégie choisie
      if (Strategy == MA_Crossover || Strategy == RSI_OSOB)
      {
         MA_Handle1[0] = iMA(symbol, _Period, MA_Period1, 0, MA_Method, MA_Price);
         MA_Handle2[0] = iMA(symbol, _Period, MA_Period2, 0, MA_Method, MA_Price);

         if (MA_Handle1[0] == INVALID_HANDLE)
         {
            Print("Erreur d'initialisation du handle MA1 pour ", symbol);
            MA_Handle1[0] = INVALID_HANDLE;
         }

         if (MA_Handle2[0] == INVALID_HANDLE)
         {
            Print("Erreur d'initialisation du handle MA2 pour ", symbol);
            MA_Handle2[0] = INVALID_HANDLE;
         }
      }

      // Initialiser le handle pour la tendance
      if (TrendMethodChoice == Ichimoku)
      {
         Ichimoku_Handle[0] = iIchimoku(symbol, TrendTimeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);
         if (Ichimoku_Handle[0] == INVALID_HANDLE)
         {
            Print("Erreur d'initialisation du handle Ichimoku pour la tendance sur ", symbol);
            Ichimoku_Handle[0] = INVALID_HANDLE;
         }
      }
   }
   else
   {
      int totalSymbols = ArraySize(ActiveSymbols);
      if (totalSymbols > 0)
      {
         ArrayResize(MA_Handle1, totalSymbols);
         ArrayResize(MA_Handle2, totalSymbols);
         ArrayResize(Ichimoku_Handle, totalSymbols);

         for (int i = 0; i < totalSymbols; i++)
         {
            string symbol = ActiveSymbols[i];

            // Initialiser les handles en fonction de la stratégie sélectionnée
            if (Strategy == MA_Crossover || Strategy == RSI_OSOB)
            {
               MA_Handle1[i] = iMA(symbol, _Period, MA_Period1, 0, MA_Method, MA_Price);
               MA_Handle2[i] = iMA(symbol, _Period, MA_Period2, 0, MA_Method, MA_Price);

               if (MA_Handle1[i] == INVALID_HANDLE)
               {
                  Print("Erreur d'initialisation du handle MA1 pour ", symbol);
                  MA_Handle1[i] = INVALID_HANDLE;
               }

               if (MA_Handle2[i] == INVALID_HANDLE)
               {
                  Print("Erreur d'initialisation du handle MA2 pour ", symbol);
                  MA_Handle2[i] = INVALID_HANDLE;
               }
            }

            // Initialiser le handle pour la tendance
            if (TrendMethodChoice == Ichimoku)
            {
               Ichimoku_Handle[i] = iIchimoku(symbol, TrendTimeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);
               if (Ichimoku_Handle[i] == INVALID_HANDLE)
               {
                  Print("Erreur d'initialisation du handle Ichimoku pour la tendance sur ", symbol);
                  Ichimoku_Handle[i] = INVALID_HANDLE;
               }
            }
            else if (TrendMethodChoice == MA)
            {
               MA_Handle1[i] = iMA(symbol, TrendTimeframe, TrendMA_Period, 0, MODE_SMA, PRICE_CLOSE);
               if (MA_Handle1[i] == INVALID_HANDLE)
               {
                  Print("Erreur d'initialisation du handle MA pour la tendance sur ", symbol);
                  MA_Handle1[i] = INVALID_HANDLE;
               }
            }
         }
      }
      else
      {
         Print("Erreur: Aucun symbole actif trouvé pour initialiser les handles des indicateurs.");
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour libérer les handles des indicateurs                |
//+------------------------------------------------------------------+
void ReleaseIndicatorHandles()
{
   if (!TradeAllForexPairs && !TradeAllIndices && StringLen(CustomSymbols) == 0)
   {
      if (MA_Handle1[0] != INVALID_HANDLE) IndicatorRelease(MA_Handle1[0]);
      if (MA_Handle2[0] != INVALID_HANDLE) IndicatorRelease(MA_Handle2[0]);
      if (Ichimoku_Handle[0] != INVALID_HANDLE) IndicatorRelease(Ichimoku_Handle[0]);
   }
   else
   {
      for (int i = 0; i < ArraySize(ActiveSymbols); i++)
      {
         if (MA_Handle1[i] != INVALID_HANDLE) IndicatorRelease(MA_Handle1[i]);
         if (MA_Handle2[i] != INVALID_HANDLE) IndicatorRelease(MA_Handle2[i]);
         if (Ichimoku_Handle[i] != INVALID_HANDLE) IndicatorRelease(Ichimoku_Handle[i]);
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier les nouveaux signaux                      |
//+------------------------------------------------------------------+
void CheckForNewSignals()
{
   Print("Début de CheckForNewSignals");

   // Vérifier les conditions de trading
   if (!IsMarketConditionsSuitable())
   {
      Print("Conditions de marché non favorables.");
      return;
   }

   // Vérifier les actualités importantes
   if (UseNewsFilter && IsThereNews(Symbol()))
   {
      Print("Actualités importantes détectées, trading évité.");
      return;
   }

   // Obtenir la tendance
   MarketTrend trend = GetMarketTrend(Symbol(), 0);

   // Vérifier le signal selon la stratégie choisie
   CrossSignal signal = CheckStrategySignal(Symbol(), 0);

   if (signal != Aucun)
   {
      Print("Signal détecté : ", EnumToString(signal));

      // Calculer le volume
      double volume = CalculateVolume(Symbol());
      if (volume <= 0)
      {
         Print("Volume invalide pour ", Symbol());
         return;
      }

      // Ouvrir la position en fonction du type de Stop Loss
      if (StopLossType == SL_Classique)
      {
         if (OpenPositionWithClassicSL(Symbol(), signal, volume))
         {
            Print("Position ouverte avec Stop Loss Classique pour ", Symbol());
         }
      }
      else if (StopLossType == SL_Suiveur)
      {
         if (OpenPositionWithTrailingSL(Symbol(), signal, volume))
         {
            Print("Position ouverte avec Stop Loss Suiveur pour ", Symbol());
         }
      }
      else if (StopLossType == GridTrading)
      {
         if (OpenPositionWithGridTrading(Symbol(), signal, volume))
         {
            Print("Position ouverte avec Grid Trading pour ", Symbol());
         }
      }
      else
      {
         Print("Type de Stop Loss non reconnu.");
      }
   }

   Print("Fin de CheckForNewSignals");
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier les nouveaux signaux pour le symbole actuel |
//+------------------------------------------------------------------+
void CheckForNewSignalsForCurrentSymbol()
{
   string currentSymbol = Symbol(); // Symbole du graphique actuel

   // Vérifier les conditions de trading
   if (!CanTrade(currentSymbol))
      return;

   // Obtenir la tendance
   MarketTrend trend = GetMarketTrend(currentSymbol, 0); // Utilisez 0 car il n'y a qu'un seul symbole

   // Vérifier le signal selon la stratégie choisie
   CrossSignal signal = CheckStrategySignal(currentSymbol, 0); // Utilisez 0 car il n'y a qu'un seul symbole

   if (signal != Aucun)
   {
      // Calculer le volume
      double volume = CalculateVolume(currentSymbol);
      if (volume <= 0)
         return;

      // Calculer les niveaux de SL et TP
      double sl = 0.0, tp = 0.0;
      double slPercentage = 0.0, tpPercentage = 0.0;
      double slPoints = 0.0, tpPoints = 0.0;

      if (StopLossType == SL_Classique)
      {
         CalculateClassicSLTP(currentSymbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);
      }
      else if (StopLossType == SL_Suiveur)
      {
         CalculateTrailingSLTP(currentSymbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp);
      }
      else if (StopLossType == GridTrading)
      {
         CalculateGridSLTP(currentSymbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);
      }

      // Ouvrir la position
      if (signal == Achat && (trend == TrendHaussiere || trend == Indecis))
      {
         if (OpenPosition(currentSymbol, ORDER_TYPE_BUY, volume, sl, tp))
         {
            Print("Position ACHAT ouverte pour ", currentSymbol, " avec succès.");
         }
      }
      else if (signal == Vente && (trend == TrendBaissiere || trend == Indecis))
      {
         if (OpenPosition(currentSymbol, ORDER_TYPE_SELL, volume, sl, tp))
         {
            Print("Position VENTE ouverte pour ", currentSymbol, " avec succès.");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si le trading est autorisé sur un symbole  |
//+------------------------------------------------------------------+
bool CanTrade(string symbol)
{
   // Vérifier s'il y a des actualités
   if (IsThereNews(symbol))
      return false;

   // Vérifier le spread si le filtre est activé
   if (UseMaxSpreadFilter)
   {
      double currentSpread = (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      if (currentSpread > MaxSpreadPoints)
      {
         Print("Spread trop élevé pour ", symbol, ": ", currentSpread);
         return false;
      }
   }

   // Vérifier s'il y a déjà une position ouverte
   if (IsPositionOpen(symbol))
      return false;

   // Vérifier si le trading est autorisé sur ce symbole
   long tradeMode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   if (tradeMode == SYMBOL_TRADE_MODE_DISABLED)
   {
      Print("Trading non autorisé sur ", symbol);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Fonction pour déterminer la tendance du marché                   |
//+------------------------------------------------------------------+
MarketTrend GetMarketTrend(string symbol, int index = 0)
{
   if (TrendMethodChoice == Ichimoku)
   {
      double tenkanSen[], kijunSen[], senkouSpanA[], senkouSpanB[];

      ArraySetAsSeries(tenkanSen, true);
      ArraySetAsSeries(kijunSen, true);
      ArraySetAsSeries(senkouSpanA, true);
      ArraySetAsSeries(senkouSpanB, true);

      // Vérifier si l'index est valide pour Ichimoku_Handle
      if (index < 0 || index >= ArraySize(Ichimoku_Handle))
      {
         Print("Erreur: L'index pour Ichimoku_Handle est hors limites.");
         return Indecis;
      }

      // Copier les données avec vérification de la réussite
      if (CopyBuffer(Ichimoku_Handle[index], 0, 0, 2, tenkanSen) <= 0 ||
          CopyBuffer(Ichimoku_Handle[index], 1, 0, 2, kijunSen) <= 0 ||
          CopyBuffer(Ichimoku_Handle[index], 2, 0, 2, senkouSpanA) <= 0 ||
          CopyBuffer(Ichimoku_Handle[index], 3, 0, 2, senkouSpanB) <= 0)
      {
         Print("Erreur lors de la copie des données Ichimoku pour ", symbol);
         return Indecis;
      }

      double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);

      // Déterminer la tendance avec Ichimoku
      if (currentPrice > senkouSpanA[0] && currentPrice > senkouSpanB[0] &&
          tenkanSen[0] > kijunSen[0])
      {
         return TrendHaussiere;
      }
      else if (currentPrice < senkouSpanA[0] && currentPrice < senkouSpanB[0] &&
               tenkanSen[0] < kijunSen[0])
      {
         return TrendBaissiere;
      }

      return Indecis;
   }
   else if (TrendMethodChoice == MA)
   {
      double maTrend[];

      ArraySetAsSeries(maTrend, true);

      int maTrendHandle = iMA(symbol, TrendTimeframe, TrendMA_Period, 0, MODE_SMA, PRICE_CLOSE);

      // Vérifier si le handle est valide
      if (maTrendHandle == INVALID_HANDLE)
      {
         Print("Erreur lors de l'initialisation de la MA pour ", symbol);
         return Indecis;
      }

      // Copier les données avec vérification de la réussite
      if (CopyBuffer(maTrendHandle, 0, 0, 1, maTrend) <= 0)
      {
         Print("Erreur lors de la copie des données MA pour ", symbol);
         return Indecis;
      }

      double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);

      // Déterminer la tendance avec la MM
      if (currentPrice > maTrend[0])
      {
         return TrendHaussiere;
      }
      else if (currentPrice < maTrend[0])
      {
         return TrendBaissiere;
      }

      return Indecis;
   }

   return Indecis; // Cas par défaut si aucune méthode n'est définie
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier les signaux selon la stratégie            |
//+------------------------------------------------------------------+
CrossSignal CheckStrategySignal(string symbol, int index = 0)
{
   switch (Strategy)
   {
      case MA_Crossover:
         return CheckMACrossover(symbol, index);

      case RSI_OSOB:
         return CheckRSISignal(symbol, index);

      case FVG_Strategy:
         return CheckFVGSignal(symbol);

      default:
         return Aucun;
   }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal RSI                             |
//+------------------------------------------------------------------+
CrossSignal CheckRSISignal(string symbol, int index = 0)
{
   double rsi[];

   ArraySetAsSeries(rsi, true);

   // Obtenir le handle RSI
   int rsiHandle = iRSI(symbol, _Period, RSI_Period, PRICE_CLOSE);
   if (rsiHandle == INVALID_HANDLE)
   {
      Print("Erreur: Impossible de créer le handle RSI pour ", symbol);
      return Aucun;
   }

   // Copier les données RSI
   if (CopyBuffer(rsiHandle, 0, 0, 2, rsi) <= 0)
   {
      Print("Erreur lors de la copie des données RSI pour ", symbol);
      return Aucun;
   }

   // Vérifier les conditions de surachat et survente
   if (rsi[0] < RSI_OversoldLevel && rsi[1] >= RSI_OversoldLevel)
   {
      return Achat;
   }
   else if (rsi[0] > RSI_OverboughtLevel && rsi[1] <= RSI_OverboughtLevel)
   {
      return Vente;
   }

   return Aucun;
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal de croisement des MM            |
//+------------------------------------------------------------------+
CrossSignal CheckMACrossover(string symbol, int index = 0)
{
   double ma1[], ma2[];

   ArraySetAsSeries(ma1, true);
   ArraySetAsSeries(ma2, true);

   // Copier les données des moyennes mobiles
   if (CopyBuffer(MA_Handle1[index], 0, 0, 2, ma1) <= 0 ||
       CopyBuffer(MA_Handle2[index], 0, 0, 2, ma2) <= 0)
   {
      Print("Erreur lors de la copie des données MA pour ", symbol);
      return Aucun;
   }

   // Vérifier le croisement des moyennes mobiles
   if (ma1[0] > ma2[0] && ma1[1] <= ma2[1])
   {
      return Achat;
   }
   else if (ma1[0] < ma2[0] && ma1[1] >= ma2[1])
   {
      return Vente;
   }

   return Aucun;
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal FVG                             |
//+------------------------------------------------------------------+
CrossSignal CheckFVGSignal(string symbol)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if (CopyRates(symbol, _Period, 0, FVG_CandleLength + 2, rates) <= 0)
   {
      Print("Erreur lors de la copie des données de prix pour ", symbol);
      return Aucun;
   }

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);

   // Détecter les Fair Value Gaps
   for (int i = 1; i < FVG_CandleLength; i++)
   {
      // FVG haussier
      if (rates[i].low > rates[i - 1].high)
      {
         double gapSize = rates[i].low - rates[i - 1].high;
         if (gapSize >= FVG_MinAmplitudePoints * point)
         {
            if (FVG_TradeAction == Breakout && currentPrice > rates[i].high)
               return Achat;
            else if (FVG_TradeAction == Rebound && currentPrice < rates[i].low)
               return Vente;
         }
      }
      // FVG baissier
      else if (rates[i].high < rates[i - 1].low)
      {
         double gapSize = rates[i - 1].low - rates[i].high;
         if (gapSize >= FVG_MinAmplitudePoints * point)
         {
            if (FVG_TradeAction == Breakout && currentPrice < rates[i].low)
               return Vente;
            else if (FVG_TradeAction == Rebound && currentPrice > rates[i].high)
               return Achat;
         }
      }
   }

   return Aucun;
}

//+------------------------------------------------------------------+
//| Fonction de vérification de validité d'une position               |
//+------------------------------------------------------------------+
bool IsValidPosition(ulong ticket)
{
    if(!position.SelectByTicket(ticket))
        return false;
        
    if(UseMagicNumber)
    {
        return (position.Magic() == MagicNumber);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Fonction de comptage des positions                                |
//+------------------------------------------------------------------+
int CountPositions(string symbol)
{
    int count = 0; // Initialiser le compteur à 0

    for (int i = 0; i < PositionsTotal(); i++) // Parcourir toutes les positions ouvertes
    {
        if (PositionSelect(Symbol())) // Sélectionner la position pour le symbole actuel
        {
            if (PositionGetString(POSITION_SYMBOL) == symbol) // Vérifier si le symbole correspond
            {
                count++; // Incrémenter si le symbole correspond
            }
        }
    }
    return count; // Retourner le nombre total de positions pour le symbole donné
}

//+------------------------------------------------------------------+
//| Fonction pour ouvrir une nouvelle position                      |
//+------------------------------------------------------------------+
void OpenNewPosition(string symbol, CrossSignal signal, MarketTrend trend)
{
   double volume = CalculateVolume(symbol);
   if (volume <= 0)
   {
      Print("Erreur: Taille de lot invalide pour ", symbol);
      return;
   }

   ENUM_ORDER_TYPE orderType = (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   // Calculer les niveaux de Stop Loss et Take Profit
   double sl = 0.0, tp = 0.0, slPercentage = 0.0, tpPercentage = 0.0, slPoints = 0.0, tpPoints = 0.0;
   if (StopLossType == SL_Classique)
   {
      CalculateClassicSLTP(symbol, orderType, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);
   }
   else if (StopLossType == SL_Suiveur)
   {
      // Pour le SL suiveur, les calculs sont effectués dans UpdateTrailingStop
      CalculateTrailingSLTP(symbol, orderType, sl, tp);
   }

   // Ouvrir la position
   if (trade.PositionOpen(symbol, orderType, volume, 0, sl, tp))
   {
      Print("Position ouverte pour ", symbol, " - Type: ", EnumToString(orderType), " - Volume: ", volume);
      Print("SL: ", sl, " - TP: ", tp);
      Print("SL en pourcentage de l'équité: ", slPercentage, "%");
      Print("TP en pourcentage de l'équité: ", tpPercentage, "%");
      Print("SL en points: ", slPoints);
      Print("TP en points: ", tpPoints);
   }
   else
   {
      Print("Erreur lors de l'ouverture de la position pour ", symbol, " - Erreur: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si une position est ouverte                |
//+------------------------------------------------------------------+
bool IsPositionOpen(string symbol)
{
    int totalPositions = PositionsTotal();
    Print("Nombre total de positions : ", totalPositions);

    for (int i = totalPositions - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0)
        {
            Print("Erreur : Impossible de récupérer le ticket de la position à l'index ", i);
            continue;
        }

        if (!PositionSelectByTicket(ticket))
        {
            Print("Erreur : Impossible de sélectionner la position avec le ticket ", ticket);
            continue;
        }

        string positionSymbol = PositionGetString(POSITION_SYMBOL);
        ulong positionMagic = PositionGetInteger(POSITION_MAGIC);

        Print("Position trouvée : Symbole = ", positionSymbol, ", Magic = ", positionMagic);

        // Vérifier le symbole et le Magic Number (si activé)
        if (positionSymbol == symbol && (!UseMagicNumber || positionMagic == MagicNumber))
        {
            Print("Une position est déjà ouverte pour ", symbol);
            return true; // Une position est ouverte pour ce symbole
        }
    }

    Print("Aucune position ouverte pour ", symbol);
    return false; // Aucune position ouverte pour ce symbole
}

//+------------------------------------------------------------------+
//| Fonction pour mettre à jour les positions existantes             |
//+------------------------------------------------------------------+
void UpdateExistingPositions()
{
   for (int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if (ticket <= 0)
      {
         Print("Erreur lors de la récupération du ticket de position");
         continue;
      }

      if (!PositionSelectByTicket(ticket))
      {
         Print("Erreur lors de la sélection de la position par ticket: ", ticket);
         continue;
      }

      string symbol = PositionGetString(POSITION_SYMBOL);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double lotSize = PositionGetDouble(POSITION_VOLUME);

      // Vérifier si le Magic Number doit être utilisé
      if (UseMagicNumber && position.Magic() != MagicNumber)
      {
         // Ignorer les positions avec un Magic Number différent
         continue;
      }

      // Mettre à jour le Stop Loss suiveur si activé
      if (StopLossType == SL_Suiveur)
      {
         double seuilDeclenchementPercentage = 0.0, respirationPercentage = 0.0, slSuiveurPercentage = 0.0;
         double seuilDeclenchementPoints = 0.0, respirationPoints = 0.0, slSuiveurPoints = 0.0;
         UpdateTrailingStop(symbol, ticket, type, openPrice, currentPrice, sl,
                            seuilDeclenchementPercentage, respirationPercentage, slSuiveurPercentage,
                            seuilDeclenchementPoints, respirationPoints, slSuiveurPoints);

         Print("Seuil de déclenchement en pourcentage de l'équité: ", seuilDeclenchementPercentage, "%");
         Print("Respiration en pourcentage de l'équité: ", respirationPercentage, "%");
         Print("SL suiveur en pourcentage de l'équité: ", slSuiveurPercentage, "%");
         Print("Seuil de déclenchement en points: ", seuilDeclenchementPoints);
         Print("Respiration en points: ", respirationPoints);
         Print("SL suiveur en points: ", slSuiveurPoints);
      }

      // Vérifier si le Take Profit ou le Stop Loss a été atteint
      CheckTakeProfitStopLoss(symbol, ticket, type, currentPrice, sl, tp);
   }
}

//+------------------------------------------------------------------+
//| Fonction de modification de position                              |
//+------------------------------------------------------------------+
bool ModifyPosition(ulong ticket, double sl, double tp)
{
   if (!position.SelectByTicket(ticket))
   {
      Print("Erreur de sélection du ticket : ", ticket);
      return false;
   }
   
   // Vérifier si le Magic Number doit être utilisé
   if (UseMagicNumber && position.Magic() != MagicNumber)
   {
      Print("Magic number invalide pour le ticket : ", ticket);
      return false;
   }
   
   // Normalisation des niveaux SL et TP
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   
   // Vérification si la modification est nécessaire
   if (position.StopLoss() == sl && position.TakeProfit() == tp)
      return true;
      
   return trade.PositionModify(ticket, sl, tp);
}

//+------------------------------------------------------------------+
//| Fonction de fermeture de position                                 |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket)
{
   if (!position.SelectByTicket(ticket))
   {
      Print("Erreur de sélection du ticket : ", ticket);
      return false;
   }
   
   // Vérifier si le Magic Number doit être utilisé
   if (UseMagicNumber && position.Magic() != MagicNumber)
   {
      Print("Magic number invalide pour le ticket : ", ticket);
      return false;
   }
   
   return trade.PositionClose(ticket);
}

//+------------------------------------------------------------------+
//| Fonction de fermeture de toutes les positions                     |
//+------------------------------------------------------------------+
void CloseAllPositions(string symbol = "")
{
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (!position.SelectByIndex(i))
         continue;
         
      if (symbol != "" && position.Symbol() != symbol)
         continue;
         
      // Vérifier si le Magic Number doit être utilisé
      if (UseMagicNumber && position.Magic() != MagicNumber)
         continue;
         
      if (!trade.PositionClose(position.Ticket()))
      {
         Print("Erreur de fermeture de la position : ", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction de gestion du SL classique                               |
//+------------------------------------------------------------------+
void ManageClassicSL(string symbol)
{
   if (!position.Select(symbol))
      return;

   // Vérifier si le Magic Number doit être utilisé
   if (UseMagicNumber && position.Magic() != MagicNumber)
      return;

   double lotSize = position.Volume(); // Utiliser le volume de la position existante
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Calculer les niveaux de SL et TP en pips
   double slPips = NormalizeDouble(StopLossCurrency / (lotSize * pointValue), digits);
   double tpPips = NormalizeDouble(TakeProfitCurrency / (lotSize * pointValue), digits);

   // Récupérer le prix d'ouverture de la position
   double openPrice = position.PriceOpen();

   // Calculer les niveaux de SL et TP en prix
   double slPrice = 0.0;
   double tpPrice = 0.0;

   if (position.PositionType() == POSITION_TYPE_BUY)
   {
      slPrice = NormalizeDouble(openPrice - slPips * point, digits);
      tpPrice = NormalizeDouble(openPrice + tpPips * point, digits);
   }
   else if (position.PositionType() == POSITION_TYPE_SELL)
   {
      slPrice = NormalizeDouble(openPrice + slPips * point, digits);
      tpPrice = NormalizeDouble(openPrice - tpPips * point, digits);
   }

   // Modifier la position si nécessaire
   if (!ModifyPosition(position.Ticket(), slPrice, tpPrice))
   {
      Print("Erreur lors de la modification du SL classique pour ", symbol, ": ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Fonction pour gérer le Grid Trading                               |
//+------------------------------------------------------------------+
void ManageGridTrading(CPositionInfo &pos, double &gridDistancePercentage, double &gridDistancePoints)
{
   string symbol = pos.Symbol();
   double lotSize = pos.Volume();

   // Compter le nombre de positions ouvertes pour ce symbole
   int posCount = CountPositions(symbol);

   // Vérifier si le nombre de positions est inférieur à la limite maximale
   if (posCount < GridMaxOrders)
   {
      double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

      // Convertir la distance de grille en points (à partir de la devise)
      double gridDistanceInPoints = NormalizeDouble(GridDistancePoints / (lotSize * pointValue), digits);

      // Calculer la distance de grille en pourcentage de l'équité
      gridDistancePercentage = ConvertToEquityPercentage(GridDistancePoints);

      // Vérifier les conditions pour ouvrir une nouvelle position
      double currentPrice = (pos.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
      double openPrice = pos.PriceOpen();

      if (pos.PositionType() == POSITION_TYPE_BUY)
      {
         if (currentPrice <= openPrice - gridDistanceInPoints * point)
         {
            double volume = CalculateVolume(symbol);
            double sl, tp, slPercentage, tpPercentage, slPoints, tpPoints;
            CalculateGridSLTP(symbol, ORDER_TYPE_BUY, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);

            if (OpenPosition(symbol, ORDER_TYPE_BUY, volume, 0, tp)) // Pas de SL, uniquement TP
            {
               Print("Nouvelle position BUY ouverte dans le Grid Trading pour ", symbol);
            }
         }
      }
      else if (pos.PositionType() == POSITION_TYPE_SELL)
      {
         if (currentPrice >= openPrice + gridDistanceInPoints * point)
         {
            double volume = CalculateVolume(symbol);
            double sl, tp, slPercentage, tpPercentage, slPoints, tpPoints;
            CalculateGridSLTP(symbol, ORDER_TYPE_SELL, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);

            if (OpenPosition(symbol, ORDER_TYPE_SELL, volume, 0, tp)) // Pas de SL, uniquement TP
            {
               Print("Nouvelle position SELL ouverte dans le Grid Trading pour ", symbol);
            }
         }
      }
   }
   else
   {
      Print("Nombre maximum de positions atteint pour ", symbol, " (", GridMaxOrders, "). Pas de nouvelle position ouverte.");
   }
}

//+------------------------------------------------------------------+
//| Fonction pour afficher le nuage Ichimoku sur le graphique         |
//+------------------------------------------------------------------+
void DisplayIchimokuOnChart()
{
   string symbol = Symbol();
   ENUM_TIMEFRAMES timeframe = TrendTimeframe;

   // Supprimer les objets existants pour éviter les doublons
   ObjectsDeleteAll(0, "Ichimoku*");

   // Obtenir les buffers Ichimoku (uniquement Senkou Span A et B)
   double senkouSpanA[], senkouSpanB[];

   ArraySetAsSeries(senkouSpanA, true);
   ArraySetAsSeries(senkouSpanB, true);

   int ichimokuHandle = iIchimoku(symbol, timeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);

   if (CopyBuffer(ichimokuHandle, 2, 0, 100, senkouSpanA) <= 0 ||
       CopyBuffer(ichimokuHandle, 3, 0, 100, senkouSpanB) <= 0)
   {
       Print("Erreur lors de la copie des données Ichimoku pour l'affichage sur le graphique");
      return;
   }

   // Afficher le nuage Ichimoku (Senkou Span A et B)
   for (int i = 0; i < ArraySize(senkouSpanA) - 1; i++)
   {
      if (senkouSpanA[i] != EMPTY_VALUE && senkouSpanA[i + 1] != EMPTY_VALUE &&
          senkouSpanB[i] != EMPTY_VALUE && senkouSpanB[i + 1] != EMPTY_VALUE)
      {
         ObjectCreate(0, "Ichimoku_Cloud_" + (string)i, OBJ_RECTANGLE, 0, iTime(symbol, timeframe, i), MathMin(senkouSpanA[i], senkouSpanB[i]), iTime(symbol, timeframe, i + 1), MathMax(senkouSpanA[i + 1], senkouSpanB[i + 1]));
         ObjectSetInteger(0, "Ichimoku_Cloud_" + (string)i, OBJPROP_COLOR, (senkouSpanA[i] > senkouSpanB[i]) ? clrLimeGreen : clrRed);
         ObjectSetInteger(0, "Ichimoku_Cloud_" + (string)i, OBJPROP_FILL, true);
         ObjectSetInteger(0, "Ichimoku_Cloud_" + (string)i, OBJPROP_BACK, true);
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour afficher les Moyennes Mobiles sur le graphique     |
//+------------------------------------------------------------------+
void DisplayMAOnChart()
{
   string symbol = Symbol();
   ENUM_TIMEFRAMES timeframe = TrendTimeframe;

   // Supprimer les objets existants pour éviter les doublons
   ObjectsDeleteAll(0, "MA*");

   // Obtenir les buffers de la Moyenne Mobile de tendance
   double maTrend[];

   ArraySetAsSeries(maTrend, true);

   int maTrendHandle = iMA(symbol, timeframe, TrendMA_Period, 0, MODE_SMA, PRICE_CLOSE);

   if (CopyBuffer(maTrendHandle, 0, 0, 100, maTrend) <= 0)
   {
      Print("Erreur lors de la copie des données MA pour l'affichage sur le graphique");
      return;
   }

   // Afficher la Moyenne Mobile de tendance
   for (int i = 0; i < ArraySize(maTrend) - 1; i++)
   {
      if (maTrend[i] != EMPTY_VALUE && maTrend[i + 1] != EMPTY_VALUE)
      {
         ObjectCreate(0, "MA_Trend_" + (string)i, OBJ_TREND, 0, iTime(symbol, timeframe, i), maTrend[i], iTime(symbol, timeframe, i + 1), maTrend[i + 1]);
         ObjectSetInteger(0, "MA_Trend_" + (string)i, OBJPROP_COLOR, clrBlue);
         ObjectSetInteger(0, "MA_Trend_" + (string)i, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, "MA_Trend_" + (string)i, OBJPROP_STYLE, STYLE_SOLID);
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour calculer la taille de lot                          |
//+------------------------------------------------------------------+
double CalculateVolume(string symbol)
{
   double lotSize = 0.0;

   if (LotSizeType == LotFixe)
   {
      lotSize = FixedLotSize; // Utiliser directement la taille fixe configurée
   }
   else if (LotSizeType == Martingale)
   {
      int symbolIndex = -1;
      for (int i = 0; i < ArraySize(ActiveSymbols); i++)
      {
         if (ActiveSymbols[i] == symbol)
         {
            symbolIndex = i;
            break;
         }
      }

      if (symbolIndex >= 0)
      {
         int attempts = MartingaleAttempts[symbolIndex];
         lotSize = MartingaleStartLot * MathPow(MartingaleMultiplier, attempts);
      }
   }

   // Vérifier les limites de lot
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   // Arrondir au pas de lot
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lotSize = NormalizeDouble(MathRound(lotSize / lotStep) * lotStep, 2);

   // Afficher dans le journal pour le débogage
   Print("Lot calculé pour ", symbol, " : ", lotSize, " (Méthode : ", EnumToString(LotSizeType), ")");

   return lotSize;
}

//+------------------------------------------------------------------+
//| Fonction pour envoyer des notifications                           |
//+------------------------------------------------------------------+
void SendNotifications(string symbol, ENUM_ORDER_TYPE orderType, double volume, double price, double sl, double tp)
{
   string direction = (orderType == ORDER_TYPE_BUY) ? "ACHAT" : "VENTE";
   double lotSize = volume;

   // Convertir SL et TP en devise
   double slInCurrency = ConvertPointsToCurrency(symbol, (price - sl) / SymbolInfoDouble(symbol, SYMBOL_POINT), lotSize);
   double tpInCurrency = ConvertPointsToCurrency(symbol, (tp - price) / SymbolInfoDouble(symbol, SYMBOL_POINT), lotSize);

   // Calculer SL et TP en pourcentage de l'équité
   double slPercentage = ConvertToEquityPercentage(slInCurrency);
   double tpPercentage = ConvertToEquityPercentage(tpInCurrency);

   // Calculer SL et TP en points
   double slPoints = CalculatePriceDifferenceInPoints(symbol, price, sl);
   double tpPoints = CalculatePriceDifferenceInPoints(symbol, price, tp);

   string message = StringFormat("🔔 %s: Nouvelle position %s ouverte\nVolume: %.2f\nPrix: %.5f\nSL: %.2f %s (%.2f%%, %.2f points)\nTP: %.2f %s (%.2f%%, %.2f points)", 
                                 symbol, direction, volume, price, 
                                 slInCurrency, AccountInfoString(ACCOUNT_CURRENCY), slPercentage, slPoints,
                                 tpInCurrency, AccountInfoString(ACCOUNT_CURRENCY), tpPercentage, tpPoints);

   // Notification push sur le mobile
   if (!SendNotification(message))
      Print("Erreur lors de l'envoi de la notification push: ", GetLastError());

   // Notification sonore
   PlaySound("alert.wav");

   // Email notification (optionnel)
   if (!SendMail("Signal de Trading", message))
      Print("Erreur lors de l'envoi de l'email: ", GetLastError());

   // Afficher dans le journal
   Print(message);

   // Afficher sur le graphique uniquement si le symbole correspond au graphique actuel
   string currentSymbol = Symbol();
   if (symbol == currentSymbol)
   {
      Comment(message);
   }
}

//+------------------------------------------------------------------+
//| Fonction pour les notifications d'erreur                          |
//+------------------------------------------------------------------+
void SendErrorNotification(string symbol, string errorMessage)
{
   string message = "❌ ERREUR: " + errorMessage;
   
   // Notification push sur le mobile
   if (!SendNotification(message))
      Print("Erreur lors de l'envoi de la notification push: ", GetLastError());
      
   // Notification sonore
   PlaySound("alert3.wav"); // Son différent pour les erreurs
   
   // Alerte visuelle
   Alert(message);

   // Afficher sur le graphique uniquement si le symbole correspond au graphique actuel
   string currentSymbol = Symbol();
   if (symbol == currentSymbol)
   {
      Comment(message);
   }
}

//+------------------------------------------------------------------+
//| Fonction pour les notifications de fermeture                      |
//+------------------------------------------------------------------+
void SendCloseNotifications(string symbol, double profit)
{
   string message = StringFormat("✅ %s: Position fermée\nProfit: %.2f", symbol, profit);
   
   // Notification push sur le mobile
   if (!SendNotification(message))
      Print("Erreur lors de l'envoi de la notification push: ", GetLastError());
      
   // Notification sonore
   PlaySound("alert2.wav"); // Son différent pour la fermeture
   
   // Alerte visuelle
   Alert(message);

   // Afficher sur le graphique uniquement si le symbole correspond au graphique actuel
   string currentSymbol = Symbol();
   if (symbol == currentSymbol)
   {
      Comment(message);
   }
}

//+------------------------------------------------------------------+
//| Fonction pour déplacer le tableau                                |
//+------------------------------------------------------------------+
void MoveInfoTable(string symbol, int xDistance, int yDistance)
{
   string tableName = "InfoTable_" + symbol;

   if (ObjectFind(0, tableName) != INVALID_HANDLE)
   {
      ObjectSetInteger(0, tableName, OBJPROP_XDISTANCE, xDistance);
      ObjectSetInteger(0, tableName, OBJPROP_YDISTANCE, yDistance);
   }
   else
   {
      Print("Tableau non trouvé pour ", symbol);
   }
}

//+------------------------------------------------------------------+
//| Fonction pour dessiner le cadre d'affichage                     |
//+------------------------------------------------------------------+
void DrawDisplayFrame()
{
    // Récupérer la taille de la fenêtre du graphique
    long chartWidth  = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
    long chartHeight = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

    // Définir les coordonnées X et Y en fonction de TextPosition
    int xPos = 10;
    int yPos = 10;

    switch (TextPosition)
    {
        case 1: xPos = 10;                    yPos = 10;                     break; // Haut gauche
        case 2: xPos = (int)chartWidth - 320; yPos = 10;                     break; // Haut droit
        case 3: xPos = 10;                    yPos = (int)chartHeight - 410; break; // Bas gauche
        case 4: xPos = (int)chartWidth - 320; yPos = (int)chartHeight - 410; break; // Bas droit
    }

    // Espacement vertical entre les lignes
    int lineSpacing = 20;

    // Tableau dynamique pour stocker les lignes de texte
    string lines[];
    int lineIndex = 0;

    // -------------------------------------------------------
    // SECTION 1 : Informations du compte
    // -------------------------------------------------------
    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Compte : %s", AccountInfoString(ACCOUNT_NAME));

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Solde : %.2f", AccountInfoDouble(ACCOUNT_EQUITY));

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("G/P : %.2f", AccountInfoDouble(ACCOUNT_PROFIT));

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Valeur du point : %.2f", SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE));

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Marge utilisée : %.2f", AccountInfoDouble(ACCOUNT_MARGIN));

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Marge restante : %.2f", AccountInfoDouble(ACCOUNT_FREEMARGIN));

    int totalPositions = CountPositions(Symbol());
    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Position total : %d", totalPositions);

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = "-------------------------------------------";

    // -------------------------------------------------------
    // SECTION 2 : SL classique et TP
    // -------------------------------------------------------
    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("SL classique : (%s)", (StopLossType == SL_Classique) ? "True" : "False");

    // Récupération du SL / TP / prix d'ouverture / lot t
    double sl        = GetCurrentSL(Symbol());
    double tp        = GetCurrentTP(Symbol());
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double lotSize   = PositionGetDouble(POSITION_VOLUME);

    // Calcul pour le SL
    double slPoints     = PointsDifference(Symbol(), openPrice, sl); 
    double slCurrency   = ConvertPointsToCurrency(Symbol(), slPoints, lotSize);
    double slPercentage = EquityPercentage(slCurrency);

    // Calcul pour le TP
    double tpPoints     = PointsDifference(Symbol(), openPrice, tp);
    double tpCurrency   = ConvertPointsToCurrency(Symbol(), tpPoints, lotSize);
    double tpPercentage = EquityPercentage(tpCurrency);

    // Affichage du SL classique
    if (sl > 0.0)
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat(
            "SL placé à : %.5f || %.0f points || %.2f%% || %.2f%s",
            sl, slPoints, slPercentage,
            slCurrency, AccountInfoString(ACCOUNT_CURRENCY)
        );
    }
    else
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "SL placé à : 0.0 || 0 points || 0% || 0.00";
    }

    // Affichage du TP classique uniquement si SL_Classique est utilisé
    if (StopLossType == SL_Classique)
    {
        if (tp > 0.0)
        {
            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = StringFormat(
                "TP placé à : %.5f || %.0f points || %.2f%% || %.2f%s",
                tp, tpPoints, tpPercentage,
                tpCurrency, AccountInfoString(ACCOUNT_CURRENCY)
            );
        }
        else
        {
            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = "TP placé à : 0.0 || 0 points || 0% || 0.00";
        }
    }
    else
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "TP placé à : 0.0 || 0 points || 0% || 0.00";
    }

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = "-------------------------------------------";

    // -------------------------------------------------------
    // SECTION 3 : Grid trading
    // -------------------------------------------------------
    if (StopLossType == GridTrading)
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat("Grid trading : (%s)", (StopLossType == GridTrading) ? "True" : "False");

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat("Prochaine POS en point : %.2f", GridDistancePoints);

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat("Nb max de POS : %d", GridMaxOrders);
    }
    else
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat("Grid trading : (%s)", (StopLossType == GridTrading) ? "True" : "False");
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Grid trading non utilisé";
    }

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = "-------------------------------------------";

    // -------------------------------------------------------
    // SECTION 4 : SL suiveur
    // -------------------------------------------------------
    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("SL suiveur : (%s)", (StopLossType == SL_Suiveur) ? "True" : "False");

    if (StopLossType != SL_Suiveur)
    {
        // SL suiveur non utilisé => tout à zéro
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Seuil de déclenchement : 0.00000";

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Respiration pour seuil : 0.00000";

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "SL placé à : 0.00000 || 0 points || 0% || 0.00";
    }
    else
    {
        // SL suiveur activé
        if (!seuil_declenche_actif)
        {
            // Pas encore déclenché
            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = StringFormat("Seuil de déclenchement : %.5f", InpSeuilDeclenchement);

            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = StringFormat("Respiration pour seuil : %.5f", InpRespiration);

            // Calcul comme SL classique => prix / points / % / €
            double slSuiveur = GetCurrentSL(Symbol());
            double openSuiv  = PositionGetDouble(POSITION_PRICE_OPEN);
            double lotSuiv   = PositionGetDouble(POSITION_VOLUME);

            double sPoints   = PointsDifference(Symbol(), openSuiv, slSuiveur);
            double sCurr     = ConvertPointsToCurrency(Symbol(), sPoints, lotSuiv);
            double sPct      = EquityPercentage(sCurr);

if (slSuiveur > 0.0)
            {
                ArrayResize(lines, lineIndex + 1);
                lines[lineIndex++] = StringFormat(
                    "SL placé à : %.5f || %.0f points || %.2f%% || %.2f%s",
                    slSuiveur, sPoints, sPct, sCurr,
                    AccountInfoString(ACCOUNT_CURRENCY)
                );
            }
            else
            {
                ArrayResize(lines, lineIndex + 1);
                lines[lineIndex++] = "SL placé à : 0.00000 || 0 points || 0% || 0.00";
            }
        }
        else
        {
            // SL suiveur déclenché
            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = StringFormat("SL suiveur déclenché à : %.5f", trailingSL);

            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = StringFormat("Respiration pour SL suiveur : %.5f", InpRespirationSL);

            // De la même façon, on calcule le SL suiveur, etc.
            double slSuiveur = GetCurrentSL(Symbol()); // ou trailingSL
            double openSuiv  = PositionGetDouble(POSITION_PRICE_OPEN);
            double lotSuiv   = PositionGetDouble(POSITION_VOLUME);

            double sPoints   = PointsDifference(Symbol(), openSuiv, slSuiveur);
            double sCurr     = ConvertPointsToCurrency(Symbol(), sPoints, lotSuiv);
            double sPct      = EquityPercentage(sCurr);

            if (slSuiveur > 0.0)
            {
                ArrayResize(lines, lineIndex + 1);
                lines[lineIndex++] = StringFormat(
                    "SL suiveur placé à : %.5f || %.0f points || %.2f%% || %.2f%s",
                    slSuiveur, sPoints, sPct, sCurr,
                    AccountInfoString(ACCOUNT_CURRENCY)
                );
            }
            else
            {
                ArrayResize(lines, lineIndex + 1);
                lines[lineIndex++] = "SL suiveur placé à : 0.00000 || 0 points || 0% || 0.00";
            }
        }
    }

    // -------------------------------------------------------
    // Création du rectangle + étiquettes
    // -------------------------------------------------------
    string rectangleName = "DisplayRectangle_" + Symbol();

    if (ObjectFind(0, rectangleName) < 0)
    {
        if (!ObjectCreate(0, rectangleName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
        {
            Print("Erreur création du rectangle ", rectangleName, ": ", GetLastError());
            return;
        }
    }

    // Largeur fixe par défaut (290). Si vous voulez l'ajuster 
    // dynamiquement selon la longueur du texte, calculez-le ici.
    ObjectSetInteger(0, rectangleName, OBJPROP_BGCOLOR, TableFondColor);
    ObjectSetInteger(0, rectangleName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, rectangleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, rectangleName, OBJPROP_XDISTANCE, xPos);
    ObjectSetInteger(0, rectangleName, OBJPROP_YDISTANCE, yPos);
    ObjectSetInteger(0, rectangleName, OBJPROP_XSIZE, 320);
    ObjectSetInteger(0, rectangleName, OBJPROP_YSIZE, lineIndex * lineSpacing + 20);
    ObjectSetInteger(0, rectangleName, OBJPROP_BACK, false);

    // Créer ou mettre à jour chaque ligne (OBJ_LABEL)
    for (int i = 0; i < lineIndex; i++)
    {
        string labelName = "TableLabel_" + Symbol() + "_Line_" + IntegerToString(i);

        if (ObjectFind(0, labelName) < 0)
        {
            if (!ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0))
            {
                Print("Erreur création label #", i, ": ", GetLastError());
                continue;
            }
        }

        ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, xPos + 10);
        ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, yPos + i * lineSpacing + 10);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, TextColor);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
        ObjectSetString(0, labelName, OBJPROP_TEXT, lines[i]);
        ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
    }

    // Supprimer toutes les anciennes lignes (si plus utilisées)
    for (int i = lineIndex; i < 16; i++)
    {
        string labelName = "TableLabel_" + Symbol() + "_Line_" + IntegerToString(i);
        ObjectDelete(0, labelName);
    }
}

//+------------------------------------------------------------------+
//| Fonction pour dessiner un label unique                           |
//+------------------------------------------------------------------+
void DrawSingleLabel(string labelName, string text, color clr, int line, int yPos)
{
    // Supprimer le label existant s'il existe
    ObjectDelete(0, labelName);

    // Créer le label
    if (!ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0))
    {
        Print("Erreur création de l'objet ", labelName, ": ", GetLastError());
        return;
    }

    // Déterminer le coin en fonction de TextPosition
    int corner = CORNER_RIGHT_LOWER; // Valeur par défaut

    switch (TextPosition)
    {
        case 1: corner = CORNER_LEFT_UPPER; break;
        case 2: corner = CORNER_RIGHT_UPPER; break;
        case 3: corner = CORNER_LEFT_LOWER; break;
        case 4: corner = CORNER_RIGHT_LOWER; break;
    }

    // Définir la position du label
    int xDistance = 250; // Ajustez selon vos besoins

    // Configurer les propriétés du label
    ObjectSetInteger(0, labelName, OBJPROP_CORNER, corner);
    ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, xDistance);
    ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, yPos);
    ObjectSetString(0, labelName, OBJPROP_TEXT, text);
    ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Fonction pour nettoyer tous les labels                           |
//+------------------------------------------------------------------+
void CleanupLabels()
{
   string currentSymbol = Symbol(); // Symbole du graphique actuel

   if (StringFind(TRIGGER_OBJECT_NAME, currentSymbol + "_") != -1)
      ObjectDelete(0, TRIGGER_OBJECT_NAME);
   if (StringFind(FOLLOWER_OBJECT_NAME, currentSymbol + "_") != -1)
      ObjectDelete(0, FOLLOWER_OBJECT_NAME);
   if (StringFind(LABEL_RESPIRATION_STATUS, currentSymbol + "_") != -1)
      ObjectDelete(0, LABEL_RESPIRATION_STATUS);
   if (StringFind(LABEL_SEUIL_DECLENCHEMENT, currentSymbol + "_") != -1)
      ObjectDelete(0, LABEL_SEUIL_DECLENCHEMENT);
   if (StringFind(LABEL_SL_A, currentSymbol + "_") != -1)
      ObjectDelete(0, LABEL_SL_A);
   if (StringFind(LABEL_NOUVEAUX_SL, currentSymbol + "_") != -1)
      ObjectDelete(0, LABEL_NOUVEAUX_SL);
   if (StringFind(LABEL_SL_SUIVEUR, currentSymbol + "_") != -1)
      ObjectDelete(0, LABEL_SL_SUIVEUR);
}

//+------------------------------------------------------------------+
//| Fonction pour nettoyer les objets graphiques du cadre             |
//+------------------------------------------------------------------+
void CleanupDisplayFrame()
{
   string currentSymbol = Symbol();
   string frameName = "DisplayFrame_" + currentSymbol;
   ObjectDelete(0, frameName);
}
                           
//+------------------------------------------------------------------+
//| Fonction pour mettre à jour l'affichage du SL                    |
//+------------------------------------------------------------------+
void UpdateSLDisplay(bool isActivated, double seuil_activation = 0.0, double seuil_declenchement = 0.0, 
                     double sl_suiveur_level = 0.0, double nouveau_sl = 0.0)
{
   string currentSymbol = Symbol(); // Symbole du graphique actuel

   // Vérifier si le symbole de la position correspond au symbole du graphique actuel
   if (position.Symbol() != currentSymbol)
   {
      // Ne pas afficher les niveaux de SL pour les positions sur d'autres symboles
      return;
   }

   double lotSize = FixedLotSize; // Utilisez la taille de lot fixe par défaut

   if (StopLossType == SL_Classique)
   {
      // Convertir le SL en devise
      double slInCurrency = ConvertPointsToCurrency(currentSymbol, StopLossCurrency, lotSize);
      string message_sl = "SL placé à: " + DoubleToString(slInCurrency, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
      DrawSingleLabel(LABEL_SL_A, message_sl, TextColor, 2, 20);
   }
   else if (StopLossType == SL_Suiveur)
   {
      // Convertir les niveaux en devise
      double seuil_activation_currency = ConvertPointsToCurrency(currentSymbol, seuil_activation / SymbolInfoDouble(currentSymbol, SYMBOL_POINT), lotSize);
      double seuil_declenchement_currency = ConvertPointsToCurrency(currentSymbol, seuil_declenchement / SymbolInfoDouble(currentSymbol, SYMBOL_POINT), lotSize);
      double sl_suiveur_currency = ConvertPointsToCurrency(currentSymbol, sl_suiveur_level / SymbolInfoDouble(currentSymbol, SYMBOL_POINT), lotSize);
      double nouveau_sl_currency = ConvertPointsToCurrency(currentSymbol, nouveau_sl / SymbolInfoDouble(currentSymbol, SYMBOL_POINT), lotSize);

      string respiration_status = InpActivationRespiration ? "Respiration activée" : "Respiration désactivée";
      DrawSingleLabel(LABEL_RESPIRATION_STATUS, respiration_status, TextColor, 0, 50);

      if (!isActivated)
      {
         string message_trigger = "Seuil de déclenchement à: " + DoubleToString(seuil_activation_currency, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
         DrawSingleLabel(LABEL_SEUIL_DECLENCHEMENT, message_trigger, TextColor, 1, 35);

         string message_sl = "SL placé à: " + DoubleToString(seuil_declenchement_currency, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
         DrawSingleLabel(LABEL_SL_A, message_sl, TextColor, 2, 20);

         ObjectDelete(0, LABEL_SL_SUIVEUR);
         ObjectDelete(0, LABEL_NOUVEAUX_SL);
      }
      else
      {
         ObjectDelete(0, LABEL_SEUIL_DECLENCHEMENT);
         ObjectDelete(0, LABEL_SL_A);

         string message_sl_suiveur = "SL suiveur déclenché à: " + DoubleToString(sl_suiveur_currency, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
         DrawSingleLabel(LABEL_SL_SUIVEUR, message_sl_suiveur, TextColor, 2, 35);

         string message_nouveaux_sl = "Nouveau SL: " + DoubleToString(nouveau_sl_currency, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
         DrawSingleLabel(LABEL_NOUVEAUX_SL, message_nouveaux_sl, TextColor, 3, 20);
      }
   }
}
//+------------------------------------------------------------------+
//| Fonction pour ajuster les valeurs de respiration et seuils       |
//+------------------------------------------------------------------+
double AdjustRespirationValue(double value, string parameterType)
{
    double adjustedValue;
    string unit = (parameterType == "SL suiveur" || parameterType == "Seuil de déclenchement") ? " points" : "";
    
    if (value <= 0.00009)
    {
        adjustedValue = 0.0001;
        Print(parameterType, " ajusté à 0.0001", unit);
    }
    else if (value <= 0.009)
    {
        adjustedValue = 0.01;
        Print(parameterType, " ajusté à 0.01", unit);
    }
    else if (value <= 0.09)
    {
        adjustedValue = 0.1;
        Print(parameterType, " ajusté à 0.1", unit);
    }
    else
    {
        adjustedValue = value;
    }
    
    return adjustedValue;
}

//+------------------------------------------------------------------+
//| Fonction pour normaliser le volume en fonction des contraintes   |
//+------------------------------------------------------------------+
double NormalizeVolume(string symbol, double volume)
{
   double minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   long volumeDigitsValue; // Variable pour stocker la valeur retournée par SymbolInfoInteger
   if (!SymbolInfoInteger(symbol, SYMBOL_DIGITS, volumeDigitsValue)) // Utiliser SYMBOL_DIGITS au lieu de SYMBOL_VOLUME_DIGITS
   {
       Print("Erreur: Impossible de récupérer le nombre de décimales pour le symbole ", symbol);
       return 0.0;
   }
   int volumeDigits = (int)volumeDigitsValue; // Convertir en int

   // Arrondir le volume au pas de volume
   volume = NormalizeDouble(volume, volumeDigits);

   // Ajuster le volume au pas de volume
   double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if (volumeStep > 0)
   {
       volume = MathFloor(volume / volumeStep) * volumeStep;
   }
   
   // Vérifier les limites min et max
   if (volume < minVolume)
      volume = minVolume;
   else if (volume > maxVolume)
      volume = maxVolume;

   return volume;
}

//+------------------------------------------------------------------+
//| Fonction de gestion de la martingale après une perte             |
//+------------------------------------------------------------------+
void ManageMartingale(string symbol, bool isWin)
{
   if (LotSizeType != Martingale)
      return;

   // Trouver l'index du symbole
   int symbolIndex = -1;
   for (int i = 0; i < ArraySize(ActiveSymbols); i++)
   {
      if (ActiveSymbols[i] == symbol)
      {
         symbolIndex = i;
         break;
      }
   }

   if (symbolIndex == -1)
      return;

   if (isWin)
   {
      // Réinitialiser les tentatives après un gain
      MartingaleAttempts[symbolIndex] = 0;
   }
   else
   {
      // Augmenter le compteur de tentatives après une perte
      MartingaleAttempts[symbolIndex]++;

      // Vérifier et afficher le nouveau volume
      double nextVolume = MartingaleStartLot * MathPow(MartingaleMultiplier, MartingaleAttempts[symbolIndex]);
      nextVolume = NormalizeVolume(symbol, nextVolume); // Utilisation de la fonction personnalisée
      Print("Martingale sur ", symbol, " - Prochaine tentative: ", MartingaleAttempts[symbolIndex],
            " - Prochain volume: ", nextVolume);
   }
}

//+------------------------------------------------------------------+
//| Fonction de réinitialisation de la martingale                     |
//+------------------------------------------------------------------+
void ResetMartingale(string symbol = "")
{
    if(symbol == "")
    {
        // Réinitialiser pour tous les symboles
        ArrayInitialize(MartingaleAttempts, 0);
    }
    else
    {
        // Réinitialiser pour un symbole spécifique
        for(int i = 0; i < ArraySize(ActiveSymbols); i++)
        {
            if(ActiveSymbols[i] == symbol)
            {
                MartingaleAttempts[i] = 0;
                break;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Fonction de mise à jour des statistiques                          |
//+------------------------------------------------------------------+
void UpdateTradingStats(string symbol, double profit, double volume)
{
   static double totalProfit = 0.0;
   static int totalTrades = 0;

   totalProfit += profit;
   totalTrades++;

   Print("Statistiques pour ", symbol, ":");
   Print("Profit total: ", totalProfit);
   Print("Nombre total de trades: ", totalTrades);
   Print("Profit moyen par trade: ", totalProfit / totalTrades);
}

//+------------------------------------------------------------------+
//| Fonction de nettoyage des objets du graphique                     |
//+------------------------------------------------------------------+
void CleanupChartObjects(string symbol)
{
   string currentSymbol = Symbol(); // Symbole du graphique actuel

   if (symbol != currentSymbol)
   {
      // Ne pas nettoyer les objets graphiques pour les positions sur d'autres symboles
      return;
   }

   // Supprimer tous les objets graphiques pour le symbole donné
   ObjectsDeleteAll(0, symbol + "_*");
}

//+------------------------------------------------------------------+
//| Fonction pour convertir les points en devise                    |
//+------------------------------------------------------------------+
double ConvertPointsToCurrency(string symbol, double points, double lotSize)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE); // Valeur d'un tick
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);               // Taille d'un point
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);  // Taille d'un tick

    // Calculer la valeur monétaire
    return (points * point * lotSize * tickValue) / tickSize;
}

//+------------------------------------------------------------------+
//| Fonction pour calculer les niveaux de TP pour le Grid Trading    |
//+------------------------------------------------------------------+
void CalculateGridSLTP(string symbol, ENUM_ORDER_TYPE orderType, double &sl, double &tp, double &slPercentage, double &tpPercentage, double &slPoints, double &tpPoints)
{
   double lotSize = CalculateVolume(symbol);
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Calculer le niveau de TP en pips (pas de SL dans le Grid Trading)
   tpPoints = NormalizeDouble(GridTakeProfitPoints / (lotSize * pointValue), digits);

   // Récupérer le prix d'ouverture (ASK pour BUY, BID pour SELL)
   double openPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

   // Calculer le niveau de TP en prix
   if (orderType == ORDER_TYPE_BUY)
   {
      tp = NormalizeDouble(openPrice + tpPoints * point, digits);
   }
   else if (orderType == ORDER_TYPE_SELL)
   {
      tp = NormalizeDouble(openPrice - tpPoints * point, digits);
   }

   // Convertir le niveau de TP en devise
   double tpCurrency = ConvertPointsToCurrency(symbol, tpPoints, lotSize);

   // Convertir le niveau de TP en pourcentage de l'équité
   tpPercentage = ConvertToEquityPercentage(tpCurrency);

   // Afficher les informations pour le débogage
   Print("TP Grid calculé :");
   Print("TP en pips : ", tpPoints);
   Print("TP en devise : ", tpCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("TP en pourcentage de l'équité : ", tpPercentage, "%");
   Print("TP en prix : ", tp);
}

//+------------------------------------------------------------------+
//| Fonction pour calculer le pourcentage de variation               |
//+------------------------------------------------------------------+
double CalculatePercentageChange(double openPrice, double currentPrice, ENUM_POSITION_TYPE type)
{
    double percentageChange = ((currentPrice - openPrice) / openPrice) * 100.0;

    // Ajuster le signe en fonction du type de position
    if (type == POSITION_TYPE_SELL)
    {
        percentageChange = -percentageChange;
    }

    return percentageChange;
}

//+------------------------------------------------------------------+
//| Fonction pour calculer les niveaux de SL et TP classiques         |
//+------------------------------------------------------------------+
void CalculateClassicSLTP(string symbol, ENUM_ORDER_TYPE orderType, double &sl, double &tp, double &slPercentage, double &tpPercentage, double &slPoints, double &tpPoints)
{
   double lotSize = CalculateVolume(symbol);
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   // Calculer les niveaux de SL et TP en pips
   slPoints = NormalizeDouble(StopLossCurrency / (lotSize * pointValue), digits);
   tpPoints = NormalizeDouble(TakeProfitCurrency / (lotSize * pointValue), digits);

   // Récupérer le prix d'ouverture (ASK pour BUY, BID pour SELL)
   double openPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

   // Calculer les niveaux de SL et TP en prix
   if (orderType == ORDER_TYPE_BUY)
   {
      sl = NormalizeDouble(openPrice - slPoints * point, digits);
      tp = NormalizeDouble(openPrice + tpPoints * point, digits);
   }
   else if (orderType == ORDER_TYPE_SELL)
   {
      sl = NormalizeDouble(openPrice + slPoints * point, digits);
      tp = NormalizeDouble(openPrice - tpPoints * point, digits);
   }

   // Convertir les niveaux de SL et TP en devise
   double slCurrency = ConvertPointsToCurrency(symbol, slPoints, lotSize);
   double tpCurrency = ConvertPointsToCurrency(symbol, tpPoints, lotSize);

   // Convertir les niveaux de SL et TP en pourcentage de l'équité
   slPercentage = ConvertToEquityPercentage(slCurrency);
   tpPercentage = ConvertToEquityPercentage(tpCurrency);

   // Afficher les informations pour le débogage
   Print("SL classique calculé :");
   Print("SL en pips : ", slPoints);
   Print("SL en devise : ", slCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("SL en pourcentage de l'équité : ", slPercentage, "%");
   Print("SL en prix : ", sl);

   Print("TP classique calculé :");
   Print("TP en pips : ", tpPoints);
   Print("TP en devise : ", tpCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY));
   Print("TP en pourcentage de l'équité : ", tpPercentage, "%");
   Print("TP en prix : ", tp);
}

//+------------------------------------------------------------------+
//| Fonction pour calculer les niveaux de SL et TP suiveurs          |
//+------------------------------------------------------------------+
void CalculateTrailingSLTP(string symbol, ENUM_ORDER_TYPE orderType, double &sl, double &tp)
{
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double lotSize = FixedLotSize; // Utilisez la taille de lot fixe par défaut

   // Calculer les niveaux en points à partir des valeurs en devise
   double slPoints = (orderType == ORDER_TYPE_BUY) ?
                     adjusted_InpSLsuiveur / (tickValue * lotSize) / point :
                     -adjusted_InpSLsuiveur / (tickValue * lotSize) / point;

   double tpPoints = (orderType == ORDER_TYPE_BUY) ?
                     TakeProfitCurrency / (tickValue * lotSize) / point :
                     -TakeProfitCurrency / (tickValue * lotSize) / point;

   // Calculer les niveaux de prix
   double currentPrice = (orderType == ORDER_TYPE_BUY) ?
                         SymbolInfoDouble(symbol, SYMBOL_ASK) :
                         SymbolInfoDouble(symbol, SYMBOL_BID);

   sl = NormalizeDouble(currentPrice - slPoints * point, _Digits);
   tp = NormalizeDouble(currentPrice + tpPoints * point, _Digits);
}

//+------------------------------------------------------------------+
//| Fonction pour mettre à jour le Stop Loss suiveur                 |
//+------------------------------------------------------------------+
void UpdateTrailingStop(string symbol, ulong ticket, ENUM_POSITION_TYPE type, double openPrice, double currentPrice, double currentSL,
                        double &seuilDeclenchementPercentage, double &respirationPercentage, double &slSuiveurPercentage,
                        double &seuilDeclenchementPoints, double &respirationPoints, double &slSuiveurPoints)
{
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double lotSize = position.Volume();
   double newSL = currentSL;

   // Convertir les valeurs en devise
   double adjustedSeuilDeclenchement = adjusted_InpSeuilDeclenchement / tickValue / lotSize;
   double adjustedSLsuiveur = adjusted_InpSLsuiveur / tickValue / lotSize;
   double adjustedRespiration = adjusted_InpRespiration / tickValue / lotSize;
   double adjustedRespirationSL = adjusted_InpRespirationSL / tickValue / lotSize;

   // Calculer les valeurs en pourcentage de l'équité
   seuilDeclenchementPercentage = ConvertToEquityPercentage(adjusted_InpSeuilDeclenchement);
   respirationPercentage = ConvertToEquityPercentage(adjusted_InpRespiration);
   slSuiveurPercentage = ConvertToEquityPercentage(adjusted_InpSLsuiveur);

   // Calculer les valeurs en points
   seuilDeclenchementPoints = adjustedSeuilDeclenchement * point;
   respirationPoints = adjustedRespiration * point;
   slSuiveurPoints = adjustedSLsuiveur * point;

   // Vérifier si le seuil de déclenchement est atteint
   if (!seuil_declenche_actif)
   {
      if ((type == POSITION_TYPE_BUY && (currentPrice - openPrice) >= (adjustedSeuilDeclenchement + adjustedRespiration) * point) ||
          (type == POSITION_TYPE_SELL && (openPrice - currentPrice) >= (adjustedSeuilDeclenchement + adjustedRespiration) * point))
      {
         seuil_declenche_actif = true;
         sl_level = openPrice;
      }
   }

   if (seuil_declenche_actif)
   {
      // Calculer le nouveau SL suiveur avec respiration
      if (type == POSITION_TYPE_BUY)
      {
         newSL = MathMax(currentPrice - (adjustedSLsuiveur + adjustedRespirationSL) * point, sl_level);
      }
      else if (type == POSITION_TYPE_SELL)
      {
         newSL = MathMin(currentPrice + (adjustedSLsuiveur + adjustedRespirationSL) * point, sl_level);
      }

      // Mettre à jour le SL si nécessaire
      if (newSL != currentSL)
      {
         if (trade.PositionModify(ticket, newSL, position.TakeProfit()))
         {
            Print("SL suiveur mis à jour pour ", symbol, " à ", newSL);
            // Convertir le nouveau SL en devise pour l'affichage ou les logs
            double newSLInCurrency = ConvertPointsToCurrency(symbol, (currentPrice - newSL) / point, lotSize);
            Print("Nouveau SL en devise: ", newSLInCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY));
            // Calculer la différence en points entre le prix actuel et le nouveau SL
            double newSLPoints = CalculatePriceDifferenceInPoints(symbol, currentPrice, newSL);
            Print("Nouveau SL en points: ", newSLPoints);
            // Calculer le pourcentage de l'équité pour le nouveau SL
            double newSLPercentage = ConvertToEquityPercentage(newSLInCurrency);
            Print("Nouveau SL en pourcentage de l'équité: ", newSLPercentage, "%");
         }
         else
         {
            Print("Erreur lors de la modification du SL suiveur pour ", symbol, ": ", GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si le TP ou SL a été atteint               |
//+------------------------------------------------------------------+
void CheckTakeProfitStopLoss(string symbol, ulong ticket, ENUM_POSITION_TYPE type, double currentPrice, double sl, double tp)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double lotSize = position.Volume();

   // Vérifier si le Take Profit a été atteint
   if (tp > 0 && ((type == POSITION_TYPE_BUY && currentPrice >= tp) || (type == POSITION_TYPE_SELL && currentPrice <= tp)))
   {
      if (trade.PositionClose(ticket))
      {
         Print("Take Profit atteint pour ", symbol);
         double tpPoints = CalculatePriceDifferenceInPoints(symbol, position.PriceOpen(), tp);
         double tpInCurrency = ConvertPointsToCurrency(symbol, tpPoints, lotSize);
         double tpPercentage = ConvertToEquityPercentage(tpInCurrency);
         Print("TP en devise: ", tpInCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY));
         Print("TP en pourcentage de l'équité: ", tpPercentage, "%");
         Print("TP en points: ", tpPoints);
      }
      else
      {
         Print("Erreur lors de la fermeture de la position pour ", symbol, " (TP atteint): ", GetLastError());
      }
   }

   // Vérifier si le Stop Loss a été atteint
   if (sl > 0 && ((type == POSITION_TYPE_BUY && currentPrice <= sl) || (type == POSITION_TYPE_SELL && currentPrice >= sl)))
   {
      if (trade.PositionClose(ticket))
      {
         Print("Stop Loss atteint pour ", symbol);
         double slPoints = CalculatePriceDifferenceInPoints(symbol, position.PriceOpen(), sl);
         double slInCurrency = ConvertPointsToCurrency(symbol, slPoints, lotSize);
         double slPercentage = ConvertToEquityPercentage(slInCurrency);
         Print("SL en devise: ", slInCurrency, " ", AccountInfoString(ACCOUNT_CURRENCY));
         Print("SL en pourcentage de l'équité: ", slPercentage, "%");
         Print("SL en points: ", slPoints);
      }
      else
      {
         Print("Erreur lors de la fermeture de la position pour ", symbol, " (SL atteint): ", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour convertir une valeur en devise en pourcentage de l'équité |
//+------------------------------------------------------------------+
double ConvertToEquityPercentage(double valueInCurrency)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if (equity <= 0)
   {
      Print("Erreur: Équité du compte invalide ou nulle");
      return 0.0;
   }
   return (valueInCurrency / equity) * 100.0;
}

//+------------------------------------------------------------------+
//| Fonction pour calculer la différence en points                   |
//+------------------------------------------------------------------+
double CalculatePriceDifferenceInPoints(string symbol, double initialPrice, double finalPrice)
{
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   return (finalPrice - initialPrice) / point;
}

//+------------------------------------------------------------------+
//| Fonction pour ouvrir une nouvelle position                       |
//+------------------------------------------------------------------+
bool OpenPosition(string symbol, ENUM_ORDER_TYPE orderType, double volume, double sl, double tp, string comment = "")
{
   double slPercentage = 0.0, tpPercentage = 0.0, slPoints = 0.0, tpPoints = 0.0;

   if (StopLossType == SL_Classique)
   {
      CalculateClassicSLTP(symbol, orderType, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);
   }
   else if (StopLossType == SL_Suiveur)
   {
      CalculateTrailingSLTP(symbol, orderType, sl, tp);
      // Pour le SL suiveur, sl et tp sont déjà calculés
   }
   else if (StopLossType == GridTrading)
   {
      CalculateGridSLTP(symbol, orderType, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);
   }

   // Ouvrir la position
   if (trade.PositionOpen(symbol, orderType, volume, 0, sl, tp, comment))
   {
      Print("Position ouverte pour ", symbol, " - Type: ", EnumToString(orderType), " - Volume: ", volume);
      Print("SL: ", sl, " - TP: ", tp);
      Print("SL en pourcentage de l'équité: ", slPercentage, "%");
      Print("TP en pourcentage de l'équité: ", tpPercentage, "%");
      Print("SL en points: ", slPoints);
      Print("TP en points: ", tpPoints);

      // Envoyer des notifications
      SendNotifications(symbol, orderType, volume, (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID), sl, tp);

      // Mettre à jour l'affichage des niveaux de SL si nécessaire
      UpdateSLDisplay(StopLossType == SL_Suiveur, InpSeuilDeclenchement, trailingSL, sl);

      return true;
   }
   else
   {
      Print("Erreur lors de l'ouverture de la position pour ", symbol, " - Erreur: ", GetLastError());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Récupérer le Stop Loss actuel pour un symbole donné              |
//+------------------------------------------------------------------+
double GetCurrentSL(string symbol)
{
    if (PositionSelect(symbol))
    {
        return PositionGetDouble(POSITION_SL); // Retourne le Stop Loss actuel
    }
    return 0.0; // Retourne 0 si aucune position n'est ouverte
}

//+------------------------------------------------------------------+
//| Récupérer le Take Profit actuel pour un symbole donné            |
//+------------------------------------------------------------------+
double GetCurrentTP(string symbol)
{
    if (PositionSelect(symbol))
    {
        return PositionGetDouble(POSITION_TP); // Retourne le Take Profit actuel
    }
    return 0.0; // Retourne 0 si aucune position n'est ouverte
}

//+------------------------------------------------------------------+
//| Fonction pour calculer le nombre de points entre deux prix       |
//+------------------------------------------------------------------+
double PointsDifference(string symbol, double price1, double price2)
{
   double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
   // On prend la valeur absolue
   return MathAbs(price2 - price1) / pointValue;
}

//+------------------------------------------------------------------+
//| Fonction pour calculer le pourcentage d'une valeur par rapport à l'équité |
//+------------------------------------------------------------------+
double EquityPercentage(double value)
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY); // Équité du compte
    if (equity <= 0)
    {
        Print("Erreur : L'équité du compte est nulle ou négative.");
        return 0.0; // Retourne 0 pour éviter des divisions par zéro
    }
    return (value / equity) * 100.0; // Retourne le pourcentage
}

//+------------------------------------------------------------------+
//| Fonction utilitaire pour trouver l'index du trade par symbole.   |
//+------------------------------------------------------------------+
int FindTradeIndexBySymbol(string symbol) {
    for(int i = 0; i < ArraySize(openTrades); i++) {
        if(openTrades[i].symbol == symbol) return i;
    }
    return -1;
}
//+------------------------------------------------------------------+
//| Fonction de condition d'ouverture de position sur le grid        |
//+------------------------------------------------------------------+
bool OpenPositionWithGridTrading(string symbol, CrossSignal signal, double volume)
{
   int currentPositions = CountPositions(symbol);
   if (currentPositions < GridMaxOrders)
   {
      Print("Nombre maximum de positions atteint pour ", symbol, " (", GridMaxOrders, "). Pas de nouvelle position ouverte.");
      return false;
   }

   double sl = 0.0, tp = 0.0;
   double slPercentage = 0.0, tpPercentage = 0.0, slPoints = 0.0, tpPoints = 0.0;

   CalculateGridSLTP(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);

   if (OpenPosition(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, volume, sl, tp))
   {
      Print("Position ouverte avec Grid Trading pour ", symbol);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Fonction de condition d'ouverture de position sur le SLsuiveur   |
//+------------------------------------------------------------------+
bool OpenPositionWithTrailingSL(string symbol, CrossSignal signal, double volume)
{
   if (IsPositionOpen(symbol))
   {
      Print("Une position est déjà ouverte pour ", symbol, ". Aucune nouvelle position ne sera ouverte.");
      return false;
   }

   double sl = 0.0, tp = 0.0;

   CalculateTrailingSLTP(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp);

   if (OpenPosition(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, volume, sl, tp))
   {
      Print("Position ouverte avec Stop Loss Suiveur pour ", symbol);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Fonction de condition d'ouverture de position sur le SLclassique |
//+------------------------------------------------------------------+
bool OpenPositionWithClassicSL(string symbol, CrossSignal signal, double volume)
{
   if (PositionSelect(_Symbol) == true)
   {
      Print("Une position est déjà ouverte pour ", symbol, ". Aucune nouvelle position ne sera ouverte.");
      return false;
   }
   else
   {
   double sl = 0.0, tp = 0.0;
   double slPercentage = 0.0, tpPercentage = 0.0, slPoints = 0.0, tpPoints = 0.0;

   CalculateClassicSLTP(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);

   if (OpenPosition(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, volume, sl, tp))
   {
      Print("Position ouverte avec Stop Loss Classique pour ", symbol);
      return true;
   }
   }
   return false;
}
//+------------------------------------------------------------------+
//| Fin du code                                                      |
//+------------------------------------------------------------------+ 
