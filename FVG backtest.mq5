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
#include <ChartObjects\ChartObject.mqh>
#include <Arrays\ArrayString.mqh>

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

// Structure pour stocker les informations de la news
struct NewsInfo {
    datetime time;
    string   name;
    string   currency;
    string   importance;
    string   previous;
    string   forecast;
    string   actual;
};

TradeInfo openTrades[];

CTrade trade;
CPositionInfo position;

//--- Paramètres d'entrée
input string  magic_settings          = "=== Gestion du Magic Number ===";
input bool    UseMagicNumber          = true;            // False = Manuel + Tous magic
input int     MagicNumber             = 123456;          // Magic Number
input string  ecart1                  = "";
input string  display_settings        = "=== Paramètres d'affichage ===";
input bool    DisplayTable            = true; // Afficher le tableau d'informations
input int     TextPosition            = 4;               // 1=Haut gauche, 2=Haut Droite, 3=Bas Gauche, 4=Bas Droite
input color   TextColor               = clrBlack;        // Couleur de tous les textes
input color   TableFondColor          = clrYellow;       // Couleur de fond du tableau
input string  ecart2                  = "";
input string  symbol_settings         = "=== Symboles à trader ===";
input bool    TradeAllForexPairs      = false;           // Trader toutes les paires Forex
input bool    TradeAllIndices         = false;           // Trader tous les indices
input string  ecart3                  = "";
input string  news_settings           = "=== Gestion des actualités ===";
input bool    UseNewsFilter           = true;            // Utiliser le filtre des actualités
input int     NewsFilterMinutesBefore = 60;              // Minutes avant les actualités pour éviter le trading
input int     NewsFilterMinutesAfter  = 60;              // Minutes après les actualités pour éviter le trading
enum Choiximportance {High, High_Medium, All};
input Choiximportance NewsImportance  = High;            // Choix importance news
input string  ecart4                  = "";
input string  notification            = "=== Notification ===";
input bool    EnablePushNotifications = false;           // Activer les notifications push
input bool    EnableAlerts            = false;           // Activer les alertes (fenêtre pop-up MT5)
input string  ecart5                  = "";
input string  risque                  = "=== Paramètres des lots ===";
enum LotType {LotFixe};
input LotType LotSizeType             = LotFixe;         // Type de gestion du volume
input double  FixedLotSize            = 0.01;            // Taille de lot fixe
input string  ecart6                  = "";
input string  spreadslippage          = "=== Spread et slippage ===";
input bool    UseMaxSpreadFilter      = false;           // Utiliser le filtre de spread maximum
input long    MaxSpreadPoints         = 20;              // Spread maximum autorisé en points
input long    MaxSlippagePoints       = 3;               // Slippage maximum autorisé en points
input string  ecart7                  = "";
input string trend_settings           = "=== Méthode de détermination de la tendance ===";
input bool DisplayOnChart             = true;            // Afficher les indicateurs de tendance sur le graphique
input bool UseTrendDetection          = true;            // activer ou désactiver la détection de tendance
enum TrendMethod {Ichimoku, MA};
input TrendMethod TrendMethodChoice   = Ichimoku;        // Choix de la méthode de tendance
input ENUM_TIMEFRAMES TrendTimeframe  = PERIOD_D1;       // Unité de temps pour la tendance
input int     Bougieichimokuaanalyser = 1000;            // Nombre de bougies à utiliser 1000 minimum
input int TrendMA_Period              = 200;             // Période de la MM pour la tendance
input int   BougieTendanalyser        = 1000;            // Nombre de bougies à utiliser 1000 minimum
input color TendanceH                 = clrBlue;
input color TendanceB                 = clrYellow;
input string  ecart8                  = "";
input string  strategy_settings       = "=== Stratégie de trading ===";
enum StrategyType {MA_Crossover, RSI_OSOB, FVG_Strategy};
input StrategyType Strategy           = MA_Crossover;    // Choix de la stratégie
input string  ecart9                  = "";
//--- Paramètres pour la stratégie de croisement de MM
input string  ma_settings             = "--- Paramètres des Moyennes Mobiles ---";
input int     MA_Period1              = 20;              // MM Rapide
input int     MA_Period2              = 50;              // MM Lente
input ENUM_MA_METHOD MA_Method        = MODE_SMA;        // Méthode de calcul des MM
input ENUM_APPLIED_PRICE MA_Price     = PRICE_CLOSE;     // Prix appliqué pour les MM
input color   couleurdoubleMM         = clrYellow;       // Couleur des deux MM
input int     BougieMMaanalyser       = 1000;            // Nombre de bougies à utiliser 1000 minimum
input string  ecart10                 = "";
//--- Paramètres pour la stratégie RSI
input string  rsi_settings            = "--- Paramètres RSI ---";
input int     RSI_Period              = 14;              // Période du RSI
input string  ecart11                = "";
//--- Paramètres pour la stratégie FVG
input string  fvg_settings            = "--- Paramètres FVG ---";
input int     FVG_CandleLength        = 5;               // Longueur du rectangle en bougies
input double  FVG_MinAmplitudePoints  = 50;              // Amplitude minimale du FVG en points
input color   RectangleFVG            = clrRed;          // Couleur du rectangle FVG
input string LabelBullish             = "FVG BISI";      // Texte pour les FVG haussiers
input string LabelBearish             = "FVG SIBI";      // Texte pour les FVG baissiers
input color  LabelColor               = clrWhite;        // Couleur du texte des labels
input color  FVGColorBullish          = clrGreen;        // Couleur des FVG haussiers
input color  FVGColorBearish          = clrRed;          // Couleur des FVG baissiers
enum FVG_Action {Breakout, Rebound};
input FVG_Action FVG_TradeAction      = Breakout;        // Action à entreprendre (Breakout ou Rebond)
input int     BougieFVGaanalyser      = 1000;            // Nombre de bougies à utiliser 1000 minimum
input string  ecart12                = "";
input string  stoploss_settings       = "=== Paramètres de Stop Loss ===";
enum StopType {SL_Classique, GridTrading, SL_Suiveur, low_medium_high};
input StopType StopLossType           = SL_Classique;    // Type de Stop Loss
input string  ecart13                = "";
input string  sl_classique_settings   = "--- Paramètres SL Classique ---";
input double  StopLossCurrency        = 1.0;             // Stop Loss en devise (0 pour aucun SL)
input double  TakeProfitCurrency      = 1.0;             // Take Profit en devise (0 pour aucun TP)
input string  ecart14                = "";
//--- Paramètres pour le Grid Trading
input string  grid_settings           = "--- Paramètres du Grid Trading ---";
input double  GridTakeProfitPoints    = 100;             // Take Profit en devise
input double  GridDistancePoints      = 50;              // Distance nouvelle position du grid en devise
input int     GridMaxOrders           = 5;               // Nombre maximum de positions dans le grid
input string  ecart15                 = "";
//--- Paramètres pour le type de risque
input string  typerisque              = "--- Paramètres Low, medium, high ---";
enum Typepourcentage {Low_risque, Medium_risque, High_risque};
input Typepourcentage Type_pourcentage= Low_risque;      // Low(TP1%,SL10%), Medium(Tp2%,SL20%), High(TP3%,SL30%)
input int     TPviser                 = 10;              // Tp visée
input string  ecart16                 = "";
input string  reglageslsuiveur        = "--- réglage SL suiveur ---";
input bool    activationsls           = false;            // Activation du SL suiveur
input double  InpSeuilDeclenchement   = 1.5;             // Seuil de déclenchement en devise
input bool    InpActivationRespiration = true;           // Activation de la respiration
input double  InpRespiration          = 1.0;             // Respiration pour le seuil de déclenchement en devise
input double  InpRespirationSL        = 0.5;             // Respiration pour le SL suiveur en devise
input double  InpSLsuiveur            = 30.0;            // Distance du SL suiveur en devises


//--- Variables pour le SL suiveur
bool seuil_declenche_actif = false;
double sl_level = 0.0;
double position_price_open = 0.0;
double trailingSL = 0.0;
double adjusted_InpSeuilDeclenchement = 0.0;
double adjusted_InpRespiration = 0.0;
double adjusted_InpRespirationSL = 0.0;
double adjusted_InpSLsuiveur = 0.0;

//--- Variables globales pour la martingale
int MartingaleAttempts[]; // Tableau pour suivre les tentatives de martingale par symbole

//--- Variables globales
datetime      LastTradeTime     = 0;
string        ActiveSymbols[];          // Tableau des symboles actifs
bool          isNewMinute       = false;
datetime      lastMinuteChecked = 0;
ulong         current_ticket    = 0;    // Pour suivre le ticket de la position courante
datetime lastBarTime = 0; // Heure de la dernière bougie traitée

// Variables globales pour suivre l'état du FVG
bool isTradeTaken = false; // Indique si une position a déjà été prise pour ce FVG
datetime fvgStartTime;     // Heure de début du FVG
datetime lastTradedFVGTime = 0; // FVG trader ou pas

// Variables globales pour les news
NewsInfo g_NextNews;
NewsInfo g_LastDisplayedNews; // Pour stocker la dernière news affichée
int      g_PreviousImportance = -1; // Initialisation avec une valeur impossible
bool     g_PreviousUseNewsFilter     = false;  // Pour UseNewsFilter
int      g_PreviousFilterMinutesBefore = -1;  // Pour NewsFilterMinutesBefore
int      g_PreviousFilterMinutesAfter  = -1;  // Pour NewsFilterMinutesAfter


//--- Variables pour les handles des indicateurs
int           MA_Handle1[];      // Handles pour les moyennes mobiles
int           MA_Handle2[];
int           Ichimoku_Handle[]; // Handles pour l'Ichimoku
int           RSIHandle;         // Handle pour le RSI

//--- Enumérations personnalisées
enum MarketTrend { TrendHaussiere, TrendBaissiere, Indecis };
enum CrossSignal { Achat, Vente, Aucun };
enum NewsImportanceLevel { LOW = 1, MEDIUM = 2, HIGH = 3 };

//--- Stockage indicateur de tendance
int currentTrendMethod = -1; // Stocke l'indicateur actuellement affiché (-1 = aucun au départ)
bool isIndicatorLoaded = false; // Indique si l'indicateur est déjà chargé

// Initialisation de la période précédente
int previous_RSI_Period = RSI_Period;
// Variable globale pour stocker la dernière valeur utilisée et détecter les changements
int lastBougieMMaanalyserEffective = 0;
// Variable globale pour stocker la dernière valeur utilisée et détecter les changements
int lastBougieTendanalyserEffective = -1;
// Variable globale pour stocker la dernière valeur utilisée et détecter les changements
int lastBougieIchimokuAnalyserEffective = -1;
// Variable globale pour stocker la dernière valeur utilisée et détecter les changements
int lastBougieFVGaanalyserEffective = 0;

//+------------------------------------------------------------------+
//| Fonction pour cacher les indicateurs tendance                    |
//+------------------------------------------------------------------+
void SetIndicatorVisibility()
{
   int totalObjects = ObjectsTotal(0, 0, -1);

   for (int i = 0; i < totalObjects; i++)
   {
      string objName = ObjectName(0, i);

      if (StringFind(objName, "Ichimoku_") >= 0 || StringFind(objName, "MA_") >= 0)
      {
         if (DisplayOnChart)
         {
            // Ne RIEN faire ici concernant la couleur pour les MA_ et Ichimoku_.
            // Laissez DisplayMAOnChart() et DisplayIchimokuOnChart() gérer la couleur.
         }
         else
         {
            ObjectSetInteger(0, objName, OBJPROP_COLOR, clrNONE); // ✅ Rendre invisible si DisplayOnChart est faux
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction de suppression indicateur tendance                      |
//+------------------------------------------------------------------+
void RemoveAllIndicators()
{
   ObjectsDeleteAll(0, 0); // Supprime tous les objets du graphique
   isIndicatorLoaded = false;
}

//+------------------------------------------------------------------+
//| Fonction d'initialisation de l'expert                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialiser la variable lastBarTime avec l'heure de la dernière bougie pour le FVG
    lastBarTime = iTime(Symbol(), Period(), 0);
   // Créer un indicateur RSI
   RSIHandle = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);

   // Ajouter une sous-fenêtre au graphique
   ChartSetInteger(0, CHART_WINDOWS_TOTAL, 2);

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

    // Préparer la liste des symboles actifs au démarrage
    BuildActiveSymbolList();
    // Initialiser les handles des indicateurs pour tous les symboles actifs
    InitializeIndicatorHandles();

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Fonction de déinitialisation de l'expert                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  // Libérer le handle de l'indicateur
   IndicatorRelease(RSIHandle);

   // Supprimer les objets
   ObjectDelete(0, "RSI_Ligne_70");
   ObjectDelete(0, "RSI_Ligne_30");

   // Nettoyer les objets graphiques
   CleanupLabels(); // Appel à la fonction de nettoyage des labels

   // Supprimer d'autres objets spécifiques si nécessaire
   ObjectDelete(0, TRIGGER_OBJECT_NAME);
   ObjectDelete(0, FOLLOWER_OBJECT_NAME);

   // Supprimer le commentaire du graphique
   Comment("");

   // Afficher le message de déinitialisation
   Print("Expert Advisor déinitialisé");

   // Libérer les handles des indicateurs multi-paires
   ReleaseIndicatorHandles(); 

}

//+------------------------------------------------------------------+
//| Fonction principale de l'expert                                  |
//+------------------------------------------------------------------+
void OnTick()
{
// appelle istherenews pour MAJ en temps reel et pas chaque minutes
string symbol = Symbol();
IsThereNews(symbol);

// Mettre à jour la liste des symboles actifs à chaque tick
    BuildActiveSymbolList();
    
    // Suppression indicateur selon strategie de signal
   switch(Strategy) {
      case MA_Crossover:
         if ((int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) > 0)
         { // Si une sous-fenêtre existe
            DeleteSubWindowIfExists(); // Supprime la sous-fenêtre
         }
         SupprimerObjetsAutresStrategies(MA_Crossover);
         DisplayMAsignal(); // Affiche la MA
         break;

      case RSI_OSOB:
         if(RSI_Period != previous_RSI_Period)
     {
      // Supprimer la sous-fenêtre existante si elle existe
      DeleteSubWindowIfExists();
      // Afficher le RSI dans une nouvelle sous-fenêtre
      DisplayRSIInSubWindow();
      // Mettre à jour la période précédente
      previous_RSI_Period = RSI_Period;
     }
   else
     {
      // Afficher simplement le RSI dans la sous-fenêtre existante
      SupprimerObjetsAutresStrategies(RSI_OSOB);
      DisplayRSIInSubWindow();
     }

         break;

      case FVG_Strategy:
      {
           SupprimerObjetsAutresStrategies(FVG_Strategy);
                 DisplayFVGsignal(); // Affiche le FVG
         if ((int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) > 0)
         { // Si une sous-fenêtre existe
            DeleteSubWindowIfExists(); // Supprime la sous-fenêtre
         }
         
          // Récupérer le timeframe actuel du graphique
         ENUM_TIMEFRAMES currentTF = (ENUM_TIMEFRAMES)Period();

         // Vérifier si une nouvelle bougie s'est formée
         datetime currentBarTime = iTime(Symbol(), currentTF, 0);
        if (currentBarTime != lastBarTime)
          {
          // Suppresion des FVG pour les recree apres
          SupprimerObjetsFVG();
          // Mettre à jour la variable lastBarTime
          lastBarTime = currentBarTime;
          // Appeler la fonction principale pour afficher les FVG
          DisplayFVGsignal(); // Affiche le FVG
          }
         break;
     }
   }


   static int localcurrentTrendMethod = -1;  // ou toute autre valeur

   // Gérer la visibilité des indicateurs en fonction de UseTrendDetection
   SetIndicatorVisibility();

   // Vérifier si l'indicateur sélectionné a changé et doit être mis à jour
   if (TrendMethodChoice != localcurrentTrendMethod)
   {
      RemoveAllIndicators(); // Supprimer les anciens indicateurs uniquement si on change
      localcurrentTrendMethod = TrendMethodChoice; // Mettre à jour l'indicateur affiché
      isIndicatorLoaded = false; // Indicateur doit être rechargé
   }

   // Charger l'indicateur uniquement si ce n'est pas déjà fait
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
      isIndicatorLoaded = true; // Indique que l'indicateur est chargé
   }

   // Toujours afficher le tableau si activé, indépendamment de UseTrendDetection
   if (DisplayTable)
   {
      DrawDisplayFrame();
   }

   // Vérifier si les conditions de marché sont favorables
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

   // Si ce n'est pas une nouvelle minute, ne pas vérifier les signaux
   if (!isNewMinute)
   {
      return;
   }

   //---  Début de la boucle ajoutée dans OnTick pour multi-paires ---
   for (int i = 0; i < ArraySize(ActiveSymbols); i++)
   {
      string symbol = ActiveSymbols[i];

      // Vérifier si les conditions de marché sont favorables pour ce symbole
      if (!IsMarketConditionsSuitableForSymbol(symbol)) // <--- Nouvelle fonction (étape 4)
      {
         Print("Conditions de marché non favorables pour ", symbol);
         continue; // Passer au symbole suivant
      }

      // Vérifier les signaux et ouvrir des positions si nécessaire pour ce symbole
      CheckForNewSignals(symbol, i); // <--- Fonction CheckForNewSignals modifiée (étape 6)
   }

    // Mettre à jour les positions existantes (gestion des stops, etc.) -  **MODIFICATION: Appelée APRES la boucle des symboles**
    UpdateExistingPositions(); // <--- Déplacé ici APRÈS la boucle multi-paires
}

bool IsMarketConditionsSuitableForSymbol(string symbol)
{
   // Vérifier si c'est le week-end (vérification globale, pas besoin par symbole)
   if (IsWeekend())
      return false;

   // Vérifier le spread si le filtre est activé
   if (UseMaxSpreadFilter)
   {
      long currentSpread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
      if (currentSpread > MaxSpreadPoints)
      {
         Print("Spread trop élevé pour ", symbol, ": ", currentSpread);
         return false;
      }
   }

   // Vérifier si le trading est autorisé pour ce symbole
   long tradeMode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
   if (tradeMode == SYMBOL_TRADE_MODE_DISABLED)
      {
      Print("Trading non autorisé sur le symbole ", symbol);
      return false;
      }

   return true; // Conditions de marché OK pour ce symbole
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

//+------------------------------------------------------------------------+
// Fonction pour convertir l'importance numérique en chaîne de caractères  |
//+------------------------------------------------------------------------+
string ImportanceToString(ENUM_CALENDAR_EVENT_IMPORTANCE importance) {
    switch(importance) {
        case CALENDAR_IMPORTANCE_LOW:      return "Low";
        case CALENDAR_IMPORTANCE_MODERATE: return "Moderate";
        case CALENDAR_IMPORTANCE_HIGH:     return "High";
        default:                           return "None";
    }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier s'il y a des actualités importantes       |
//+------------------------------------------------------------------+
bool IsThereNews(string symbol)
{
    // Vérification des changements de paramètres
    bool parametersChanged = false;
    if (NewsImportance != g_PreviousImportance ||
        NewsFilterMinutesBefore != g_PreviousFilterMinutesBefore ||
        NewsFilterMinutesAfter != g_PreviousFilterMinutesAfter)
    {
        parametersChanged = true;
        // Mettre à jour les valeurs précédentes
        g_PreviousImportance = NewsImportance;
        g_PreviousFilterMinutesBefore = NewsFilterMinutesBefore;
        g_PreviousFilterMinutesAfter = NewsFilterMinutesAfter;
        
        // Réinitialiser les données des actualités
        g_NextNews.time = 0;
        g_NextNews.name = "";
        g_NextNews.currency = "";
        g_NextNews.importance = "";
        g_NextNews.previous = "";
        g_NextNews.forecast = "";
        
        // Réinitialiser aussi les données de la dernière news
        g_LastDisplayedNews.time = 0;
        g_LastDisplayedNews.name = "";
        g_LastDisplayedNews.currency = "";
        g_LastDisplayedNews.importance = "";
        g_LastDisplayedNews.previous = "";
        g_LastDisplayedNews.forecast = "";
        g_LastDisplayedNews.actual = ""; // Nouvelle propriété pour la valeur actuelle
    }

    MqlCalendarCountry countries[];
    if(CalendarCountries(countries) == 0) {
        Print("Erreur : Impossible de récupérer les pays du calendrier.");
        return false;
    }

    datetime now = TimeCurrent();
    datetime nextNewsTime = 0;
    datetime lastNewsTime = 0;
    MqlCalendarEvent nextEvent, lastEvent;
    MqlCalendarValue nextValue, lastValue;
    string nextCountryCode = "", lastCountryCode = "";
    bool newsFound = false;
    bool lastNewsFound = false;

    for(int i = 0; i < ArraySize(countries); i++) {
        MqlCalendarValue values[];
        // Rechercher 24h avant et après
        int valueCount = CalendarValueHistory(values, now - 86400, now + 86400, countries[i].code);

        if(valueCount == 0) continue;

        for(int j = 0; j < valueCount; j++) {
            MqlCalendarEvent event;
            if(!CalendarEventById(values[j].event_id, event)) {
                Print("Erreur lors de la récupération des détails de l'événement ID ", values[j].event_id);
                continue;
            }

            // Filtrage par importance
            bool skip = false;
            switch(NewsImportance)
            {
                case All:
                    if(event.importance != CALENDAR_IMPORTANCE_LOW && event.importance != CALENDAR_IMPORTANCE_MODERATE) {
                        skip = true;
                    }
                    break;
                case High_Medium:
                    if(event.importance != CALENDAR_IMPORTANCE_MODERATE) {
                        skip = true;
                    }
                    break;
                case High:
                    if(event.importance != CALENDAR_IMPORTANCE_HIGH) {
                        skip = true;
                    }
                    break;
                default:
                    Print("Valeur de NewsImportance invalide : ", NewsImportance);
                    skip = true;
                    break;
            }
            if(skip) continue;

            // News futures
            if(values[j].time > now) {
                if(!newsFound || values[j].time < nextNewsTime) {
                    nextNewsTime = values[j].time;
                    nextEvent = event;
                    nextValue = values[j];
                    nextCountryCode = countries[i].code;
                    newsFound = true;
                }
            }
            // News passées
            else if(values[j].time <= now) {
                if(!lastNewsFound || values[j].time > lastNewsTime) {
                    lastNewsTime = values[j].time;
                    lastEvent = event;
                    lastValue = values[j];
                    lastCountryCode = countries[i].code;
                    lastNewsFound = true;
                }
            }
        }
    }

    // Mise à jour des news futures
    if(newsFound) {
        g_NextNews.time = nextNewsTime;
        g_NextNews.name = nextEvent.name;
        g_NextNews.currency = nextCountryCode;
        g_NextNews.importance = ImportanceToString(nextEvent.importance);
        
        double prev_value = (nextValue.prev_value == -9223372036854775808) ? 0 : nextValue.prev_value / 1000000.0;
        double forecast_value = (nextValue.forecast_value == -9223372036854775808) ? 0 : nextValue.forecast_value / 1000000.0;
        g_NextNews.previous = (nextValue.prev_value == -9223372036854775808) ? "N/A" : DoubleToString(prev_value, 2);
        g_NextNews.forecast = (nextValue.forecast_value == -9223372036854775808) ? "N/A" : DoubleToString(forecast_value, 2);
    }

    // Mise à jour des news passées
    if(lastNewsFound) {
        g_LastDisplayedNews.time = lastNewsTime;
        g_LastDisplayedNews.name = lastEvent.name;
        g_LastDisplayedNews.currency = lastCountryCode;
        g_LastDisplayedNews.importance = ImportanceToString(lastEvent.importance);
        
        double prev_value = (lastValue.prev_value == -9223372036854775808) ? 0 : lastValue.prev_value / 1000000.0;
        double forecast_value = (lastValue.forecast_value == -9223372036854775808) ? 0 : lastValue.forecast_value / 1000000.0;
        double actual_value = (lastValue.actual_value == -9223372036854775808) ? 0 : lastValue.actual_value / 1000000.0;
        
        g_LastDisplayedNews.previous = (lastValue.prev_value == -9223372036854775808) ? "N/A" : DoubleToString(prev_value, 2);
        g_LastDisplayedNews.forecast = (lastValue.forecast_value == -9223372036854775808) ? "N/A" : DoubleToString(forecast_value, 2);
        g_LastDisplayedNews.actual = (lastValue.actual_value == -9223372036854775808) ? "N/A" : DoubleToString(actual_value, 2);
    }

    return (newsFound || lastNewsFound);
}

//+------------------------------------------------------------------+
//| Fonction pour construire la liste des symboles actifs            |
//+------------------------------------------------------------------+
void BuildActiveSymbolList()
{
   // Réinitialiser la liste
   ArrayResize(ActiveSymbols, 0);

   // Si TradeAllForexPairs et TradeAllIndices sont false, trader seulement le symbole actuel
   if (!TradeAllForexPairs && !TradeAllIndices)
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
      "USDJPY", "USDCAD", "USDCHF", "EURUSD", "EURGBP", "EURAUD", "EURJPY", "EURCAD", "EURCHF", "EURNZD", "GBPUSD", "GBPNZD", "GBPCAD", "GBPCHF", "GBPJPY", "GBPAUD", "CADCHF", "CADJPY", "CHFJPY", "AUDCAD", "AUDCHF", "AUDUSD", "AUDJPY", "AUDNZD", "NZDCAD", "NZDCHF", "NZDJPY", "NZDUSD"
   };

   // Liste des indices
   string Indices[] = {
      "Esp35", "Euro50", "Ger40", "Fra40", "UK100" 
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
   if (!TradeAllForexPairs && !TradeAllIndices)
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
   if (!TradeAllForexPairs && !TradeAllIndices)
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
void CheckForNewSignals(string symbol, int symbolIndex)
{
   // Vérifier les conditions de trading
   if (!IsMarketConditionsSuitableForSymbol(symbol))
   {
      Print("Conditions de marché non favorables pour ", symbol);
      return;
   }
   
// Vérification des news          
if(UseNewsFilter && IsThereNews(symbol))
{
   datetime currentTime = TimeCurrent();
     
   // Vérifier les news passées
   bool isAfterLastNews = (g_LastDisplayedNews.time > 0) && 
                         (currentTime >= g_LastDisplayedNews.time) && 
                         (currentTime <= g_LastDisplayedNews.time + (NewsFilterMinutesAfter * 60));
                         
   // Vérifier les news à venir
   bool isBeforeNextNews = (g_NextNews.time > 0) && 
                          (currentTime >= g_NextNews.time - (NewsFilterMinutesBefore * 60)) && 
                          (currentTime <= g_NextNews.time + (NewsFilterMinutesAfter * 60));
                          
   // Déclaration de High pour comparaison sinon ca fonctionne pas comme pour les autres
   string HighStr = "High";
   if (isAfterLastNews || isBeforeNextNews)
   {
      switch(NewsImportance)
      {

         case High:

            if(g_LastDisplayedNews.importance == HighStr || g_NextNews.importance == HighStr)
            {
              // Print("Période avant/après une news High - Aucun trade ne sera pris sur ", symbol);
               return;
            }
            break;
         case High_Medium:
            if(g_LastDisplayedNews.importance >= (string)High_Medium || g_NextNews.importance >= (string)High_Medium)
            {
              // Print("Période avant/après une news Medium ou High - Aucun trade ne sera pris", symbol);
               return;
            }
            break;
         case All:
            if(g_LastDisplayedNews.importance >= (string)All || g_NextNews.importance >= (string)All)
            {
              // Print("Période avant/après une news Low, Medium ou High - Aucun trade ne sera pris ", symbol);
               return;
            }
            break;
      }
   }
}

 // Variable pour stocker la tendance
   MarketTrend trend = Indecis; // Assurez-vous que cette valeur par défaut est correcte

   // Vérifier si la détection de tendance est activée
   if (UseTrendDetection)
   {
      // Obtenir la tendance
      trend = GetMarketTrend(symbol, symbolIndex);

   }
   else
   {
      
   }

   // Vérifier le signal selon la stratégie choisie
   CrossSignal signal = CheckStrategySignal(symbol, symbolIndex);

   if (signal != Aucun)
   {

double volume = CalculateVolume(symbol);

if (LotSizeType == LotFixe && volume > FixedLotSize)
{
   Print("Volume calculé (", volume, ") supérieur à FixedLotSize (", FixedLotSize, ") pour ", symbol, ". Ordre annulé.");
   return;
}

if (volume <= 0)
{
   Print("Volume invalide (", volume, ") pour ", symbol);
   return;
}
      // Vérifier la tendance avant de prendre des décisions d'achat ou de vente
      if (signal == Achat && trend != TrendBaissiere)
      {
         // Ouvrir la position avec Stop Loss Classique
         if (StopLossType == SL_Classique)
         {
            if (OpenPositionWithClassicSL(symbol, signal, volume))
            {
               Print("Position ouverte avec Stop Loss Classique pour ", symbol);
            }
         }
          // ouvrir la position avec Type de risque low medium high
          else if (StopLossType == low_medium_high)
            {
            double slLevel, tpLevel;
            ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY;
            double volumeCalcule = CalculateLotAndRisk(symbol, orderType, Type_pourcentage, TPviser, slLevel, tpLevel);
      
            if (OpenPositionWithPercentageSL(symbol, signal, volumeCalcule, slLevel, tpLevel))
            {
               Print("Position ouverte avec Stop Loss Pourcentage pour ", symbol);
            }
         }
         // Ajoutez d'autres types de Stop Loss ici si nécessaire
      }
      else if (signal == Vente && trend != TrendHaussiere)
      {
         // Ouvrir la position avec Stop Loss Classique
         if (StopLossType == SL_Classique)
         {
            if (OpenPositionWithClassicSL(symbol, signal, volume))
            {
               Print("Position ouverte avec Stop Loss Classique pour ", symbol);
            }
         }
         // ouvrir la position avec Type de risque low medium high
         else if (StopLossType == low_medium_high)
         {
            double slLevel, tpLevel;
            ENUM_ORDER_TYPE orderType = ORDER_TYPE_SELL;
            double volumeCalcule = CalculateLotAndRisk(symbol, orderType, Type_pourcentage, TPviser, slLevel, tpLevel);
      
            if (OpenPositionWithPercentageSL(symbol, signal, volumeCalcule, slLevel, tpLevel))
            {
               Print("Position ouverte avec Stop Loss Pourcentage pour ", symbol);
            }
         }

         // Ajoutez d'autres types de Stop Loss ici si nécessaire
      }
      else
      {
         Print("Signal non pris en compte en raison de la tendance du marché.");
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
//| Fonction pour vérifier si le RSI et deja crée                    |
//+------------------------------------------------------------------+
bool IsRSIIndicatorPresent()
{
   int totalIndicators = ChartIndicatorsTotal(0, 1);
   
   for(int i = 0; i < totalIndicators; i++)
   {
      string indicatorName = ChartIndicatorName(0, 1, i);
      
      // Vérification plus stricte
      if(StringFind(indicatorName, "RSI") != -1 && 
         StringFind(indicatorName, "Custom RSI") != -1)
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Fonction pour afficher le RSI dans un sous-graphique séparé      |
//+------------------------------------------------------------------+
void DisplayRSIInSubWindow()
{
   // Tableau pour stocker la valeur du RSI
   double RSIBuffer[];
   ArraySetAsSeries(RSIBuffer, true);
   
   // Copier les données du RSI
   CopyBuffer(RSIHandle, 0, 0, 1, RSIBuffer);
   
   // Valeur du RSI
   double rsi = RSIBuffer[0];
   
   // Dessiner des lignes pour les zones de surachat et survente
   ChartIndicatorAdd(0, 1, RSIHandle);
   
   // Lignes pour les niveaux de surachat et survente
   ObjectCreate(0, "RSI_Ligne_Surachat", OBJ_HLINE, 1, 70, 70);
   ObjectSetInteger(0, "RSI_Ligne_Surachat", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "RSI_Ligne_Surachat", OBJPROP_STYLE, STYLE_DASH);
   
   ObjectCreate(0, "RSI_Ligne_Survente", OBJ_HLINE, 1, 30, 30);
   ObjectSetInteger(0, "RSI_Ligne_Survente", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "RSI_Ligne_Survente", OBJPROP_STYLE, STYLE_DASH);
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal RSI                             |
//+------------------------------------------------------------------+
CrossSignal CheckRSISignal(string symbol, int index = 0)
{
   double rsi[];
   static datetime lastCheckedTime = 0;
   datetime currentBarTime = iTime(symbol, _Period, 0);

   // Vérifier si nous sommes sur une nouvelle bougie
   if (currentBarTime == lastCheckedTime)
   {
      return Aucun;  // On ne fait rien tant qu'on n'est pas sur une nouvelle bougie
   }

   ArraySetAsSeries(rsi, true);

   // Obtenir le handle RSI
   int rsiHandle = iRSI(symbol, _Period, RSI_Period, PRICE_CLOSE);
   if (rsiHandle == INVALID_HANDLE)
   {
      Print("Erreur: Impossible de créer le handle RSI pour ", symbol);
      return Aucun;
   }

   // Copier les données RSI de la bougie précédente
   if (CopyBuffer(rsiHandle, 0, 1, 1, rsi) <= 0)
   {
      Print("Erreur lors de la copie des données RSI pour ", symbol);
      return Aucun;
   }

   // Mettre à jour le temps de la dernière vérification
   lastCheckedTime = currentBarTime;

   // Vérifier les conditions de surachat et survente sur la bougie précédente
   if (rsi[0] < 30)
   {
      return Achat;
   }
   else if (rsi[0] > 70)
   {
      return Vente;
   }

   return Aucun;
}

//+------------------------------------------------------------------+
//| Fonction pour calculer et afficher les MM de signal              |
//+------------------------------------------------------------------+
void DisplayMAsignal()
{
    int BougieMMaanalyserEffective = BougieMMaanalyser;  // Copie de la valeur d'entrée

    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;

    // Obtenir le nombre total de barres disponibles dans l'historique
    int totalBars = Bars(symbol, timeframe);

    // Vérification des conditions pour ajuster la valeur des bougies à analyser
    if (BougieMMaanalyserEffective < 1000)
    {
       BougieMMaanalyserEffective = 1000;
    }
    else if (BougieMMaanalyserEffective > totalBars)
    {
        BougieMMaanalyserEffective = totalBars;
    }

    // Détection du changement de valeur
    if (BougieMMaanalyserEffective != lastBougieMMaanalyserEffective)
    {
        // Supprimer les objets existants avant de recalculer les MM
        SupprimerObjetsMM();

        // Mettre à jour la valeur mémorisée
        lastBougieMMaanalyserEffective = BougieMMaanalyserEffective;
    }


    // --- Obtenir les données des moyennes mobiles ---
    double ma1[], ma2[];
    ArraySetAsSeries(ma1, true);
    ArraySetAsSeries(ma2, true);

    int ma1Handle = iMA(symbol, timeframe, MA_Period1, 0, MA_Method, MA_Price);
    int ma2Handle = iMA(symbol, timeframe, MA_Period2, 0, MA_Method, MA_Price);

    if (CopyBuffer(ma1Handle, 0, 0, BougieMMaanalyserEffective, ma1) <= 0)
    {
       return;
    }

    if (CopyBuffer(ma2Handle, 0, 0, BougieMMaanalyserEffective, ma2) <= 0)
    {
        return;
    }

    // --- Affichage des moyennes mobiles sur le graphique ---
    for (int i = 0; i < BougieMMaanalyserEffective - 1; i++)
    {
        string objName1 = "MA1_" + IntegerToString(i);

        if (ma1[i] != EMPTY_VALUE)
        {
            if (ObjectFind(0, objName1) < 0)
            {
                ObjectCreate(0, objName1, OBJ_TREND, 0, iTime(symbol, timeframe, i), ma1[i], iTime(symbol, timeframe, i + 1), ma1[i + 1]);
            }
            else
            {
                ObjectMove(0, objName1, 0, iTime(symbol, timeframe, i), ma1[i]);
                ObjectMove(0, objName1, 1, iTime(symbol, timeframe, i + 1), ma1[i + 1]);
            }

            ObjectSetInteger(0, objName1, OBJPROP_COLOR, couleurdoubleMM);
            ObjectSetInteger(0, objName1, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName1, OBJPROP_HIDDEN, !DisplayOnChart);
        }
    }

    for (int i = 0; i < BougieMMaanalyserEffective - 1; i++)
    {
        string objName2 = "MA2_" + IntegerToString(i);

        if (ma2[i] != EMPTY_VALUE)
        {
            if (ObjectFind(0, objName2) < 0)
            {
                ObjectCreate(0, objName2, OBJ_TREND, 0, iTime(symbol, timeframe, i), ma2[i], iTime(symbol, timeframe, i + 1), ma2[i + 1]);
            }
            else
            {
                ObjectMove(0, objName2, 0, iTime(symbol, timeframe, i), ma2[i]);
                ObjectMove(0, objName2, 1, iTime(symbol, timeframe, i + 1), ma2[i + 1]);
            }

            ObjectSetInteger(0, objName2, OBJPROP_COLOR, couleurdoubleMM);
            ObjectSetInteger(0, objName2, OBJPROP_WIDTH, 2);
            ObjectSetInteger(0, objName2, OBJPROP_HIDDEN, !DisplayOnChart);
        }
    }
}

//+------------------------------------------------------------------+
//| Fonction pour supprimer les objets des MM existants              |
//+------------------------------------------------------------------+
void SupprimerObjetsMM()
{
    for (int i = 0; i < lastBougieMMaanalyserEffective - 1; i++)
    {
        string objName1 = "MA1_" + IntegerToString(i);
        string objName2 = "MA2_" + IntegerToString(i);

        ObjectDelete(0, objName1);
        ObjectDelete(0, objName2);
    }
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal de croisement des MM            |
//+------------------------------------------------------------------+
CrossSignal CheckMACrossover(string symbol, int index = 0)
{
double maRapide[], maLente[];

// Initialiser les tableaux
ArrayResize(maRapide, 2);
ArrayResize(maLente, 2);

// Définir les tableaux pour être utilisés comme séries
ArraySetAsSeries(maRapide, true);
ArraySetAsSeries(maLente, true);

// Vérifier si les handles sont valides
if (index >= ArraySize(MA_Handle1) || index >= ArraySize(MA_Handle2))
{
Print("Index invalide pour ", symbol);
return Aucun;
}

// Copier les données des moyennes mobiles
int copieRapide = CopyBuffer(MA_Handle1[index], 0, 0, 2, maRapide);
int copieLente = CopyBuffer(MA_Handle2[index], 0, 0, 2, maLente);

if (copieRapide <= 0 || copieLente <= 0)
{
Print("Erreur lors de la copie des données MA pour ", symbol);
return Aucun;
}

// Vérifier le croisement des moyennes mobiles lente et rapide
if (maLente[0] < maRapide[0] && maLente[1] >= maRapide[1])
{
return Achat;
}
else if (maLente[0] > maRapide[0] && maLente[1] <= maRapide[1])
{
return Vente;
}

return Aucun;
}

//---------------------------------------------------------------------------
// Fonction de vérification du changement de paramètres 
// (les valeurs précédentes sont stockées dans des variables statiques)
//---------------------------------------------------------------------------
bool CheckParameterChange()
{
   static int    prev_FVG_CandleLength       = FVG_CandleLength;
   static double prev_FVG_MinAmplitudePoints = FVG_MinAmplitudePoints;
   static color  prev_RectangleFVG           = RectangleFVG;
   static string prev_LabelBullish           = LabelBullish;
   static string prev_LabelBearish           = LabelBearish;
   static color  prev_LabelColor             = LabelColor;
   static color  prev_FVGColorBullish        = FVGColorBullish;
   static color  prev_FVGColorBearish        = FVGColorBearish;
   static FVG_Action prev_FVG_TradeAction    = FVG_TradeAction;
   static int    prev_BougieFVGaanalyser     = BougieFVGaanalyser;
   
   if(prev_FVG_CandleLength       != FVG_CandleLength       ||
      prev_FVG_MinAmplitudePoints != FVG_MinAmplitudePoints ||
      prev_RectangleFVG           != RectangleFVG           ||
      prev_LabelBullish           != LabelBullish           ||
      prev_LabelBearish           != LabelBearish           ||
      prev_LabelColor             != LabelColor             ||
      prev_FVGColorBullish        != FVGColorBullish        ||
      prev_FVGColorBearish        != FVGColorBearish        ||
      prev_FVG_TradeAction        != FVG_TradeAction        ||
      prev_BougieFVGaanalyser     != BougieFVGaanalyser)
   {
      // Mettre à jour les valeurs enregistrées
      prev_FVG_CandleLength       = FVG_CandleLength;
      prev_FVG_MinAmplitudePoints = FVG_MinAmplitudePoints;
      prev_RectangleFVG           = RectangleFVG;
      prev_LabelBullish           = LabelBullish;
      prev_LabelBearish           = LabelBearish;
      prev_LabelColor             = LabelColor;
      prev_FVGColorBullish        = FVGColorBullish;
      prev_FVGColorBearish        = FVGColorBearish;
      prev_FVG_TradeAction        = FVG_TradeAction;
      prev_BougieFVGaanalyser     = BougieFVGaanalyser;
      return true;
   }
   return false;
}

//---------------------------------------------------------------------------
// Fonction pour afficher les FVG de signal
//---------------------------------------------------------------------------

void DisplayFVGsignal()
{
    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
    int totalBars = Bars(symbol, timeframe);
    
    // Vérifier si l'un des paramètres a changé
    if(CheckParameterChange())
    {
         Print("Modification des paramètres détectée, suppression des FVG existants...");
         SupprimerObjetsFVG();
         // On remet à zéro la variable de contrôle des bougies analysées
         lastBougieFVGaanalyserEffective = 0;
    }
    
    // Calculer le nombre effectif de bougies à analyser
    int bougieFVGaanalyserEffective = BougieFVGaanalyser;
    if(bougieFVGaanalyserEffective < 1000)
         bougieFVGaanalyserEffective = 1000;
    else if(bougieFVGaanalyserEffective > totalBars)
         bougieFVGaanalyserEffective = totalBars;
    
    // Si le nombre de bougies à analyser a changé par rapport à la dernière exécution, 
    // supprimer les anciens objets FVG
    if(bougieFVGaanalyserEffective != lastBougieFVGaanalyserEffective)
    {
         SupprimerObjetsFVG();
         lastBougieFVGaanalyserEffective = bougieFVGaanalyserEffective;
    }
    
    // Récupérer la taille du tick pour le symbole actuel (gère le nombre de décimales)
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Variables pour garder en mémoire le low/high extrêmes des bougies (optionnel)
    double _low  = iLow(symbol, timeframe, 0);
    double _high = iHigh(symbol, timeframe, 0);
    int c_bull = 0;
    int c_bear = 0;
    
    // IMPORTANT : on démarre la boucle à 1 pour utiliser les bougies clôturées  (groupes : indices (i+2,i+1,i))
    for (int i = 1; i < bougieFVGaanalyserEffective; i++)
    {
        // Récupérer les données des trois bougies nécessaires.
        // Bougie la plus ancienne (index i+2)
        double high1  = iHigh(symbol, timeframe, i + 2);
        double low1   = iLow(symbol, timeframe, i + 2);
        
        // Bougie intermédiaire (index i+1) : utilisée pour déterminer la couleur
        double open2  = iOpen(symbol, timeframe, i + 1);
        double close2 = iClose(symbol, timeframe, i + 1);
        
        // La 3ème bougie clôturée (index i)
        double high3  = iHigh(symbol, timeframe, i);
        double low3   = iLow(symbol, timeframe, i);
        
        // Calcul de l'amplitude du FVG en nombre de points (ticks)
        double fvgAmplitudeBullish = MathAbs(low3 - high1) / tickSize;
        double fvgAmplitudeBearish = MathAbs(high3 - low1) / tickSize;
        
        // Vérifier la couleur de la bougie intermédiaire
        bool isGreenCandle = (open2 < close2);
        bool isRedCandle   = !isGreenCandle;
        
        // Vérifier les conditions pour un FVG haussier :
        // - La 3ème bougie clôturée (index i) a un low supérieur au high de la bougie la plus ancienne (i+2)
        // - Amplitude suffisante et bougie intermédiaire verte
        if(low3 > high1 &&
           fvgAmplitudeBullish >= FVG_MinAmplitudePoints &&
           isGreenCandle)
        {
            string fvgName = "FVG_Bullish_" + IntegerToString(i);
            double levelHigh = high1; // Niveau supérieur du gap
            double levelLow  = low3;  // Niveau inférieur du gap
            color zoneColor  = FVGColorBullish;
            string labelText = LabelBullish;
    
            // Définir la durée d'affichage sur le graphique (ici, on retrace à partir de la bougie en question)
            int endBarIndex = i - FVG_CandleLength;
            if(endBarIndex < 0)
                endBarIndex = 0;
    
            // Remarque : Nous utilisons ici iTime(symbol, timeframe, i) 
            // qui correspond à la clôture de la 3ème bougie du groupe.
            CreateObjectInDisplayFVGsignal( fvgName, zoneColor, 
                                            iTime(symbol, timeframe, i), 
                                            iTime(symbol, timeframe, endBarIndex), 
                                            levelLow, levelHigh, labelText);
            c_bull++;
        }
        // Vérifier les conditions pour un FVG baissier :
        // - La 3ème bougie clôturée a un high inférieur au low de la bougie la plus ancienne,
        // - Amplitude suffisante et bougie intermédiaire rouge
        else if(high3 < low1 &&
                fvgAmplitudeBearish >= FVG_MinAmplitudePoints &&
                isRedCandle)
        {
            string fvgName = "FVG_Bearish_" + IntegerToString(i);
            double levelHigh = low1; // Niveau supérieur du gap
            double levelLow  = high3; // Niveau inférieur du gap
            color zoneColor  = FVGColorBearish;
            string labelText = LabelBearish;
    
            int endBarIndex = i - FVG_CandleLength;
            if(endBarIndex < 0)
                endBarIndex = 0;
    
            CreateObjectInDisplayFVGsignal( fvgName, zoneColor, 
                                            iTime(symbol, timeframe, i), 
                                            iTime(symbol, timeframe, endBarIndex), 
                                            levelLow, levelHigh, labelText);
            c_bear++;
        }
    
        // Mise à jour des extrêmes des bougies analysées (optionnel)
        _low  = (_low  < low1)  ? _low  : low1;
        _high = (_high > high1) ? _high : high1;
    }
}

//---------------------------------------------------------------------------
// Fonction pour créer et/ou mettre à jour un objet graphique (rectangle et texte)
//---------------------------------------------------------------------------

void CreateObjectInDisplayFVGsignal(string name, color clrColor, datetime time1, datetime time2, double low, double high, string labelText)
{
    // Vérifier si l'objet rectangle existe déjà
    if (ObjectFind(0, name) == -1)
    {
        // Créer un rectangle
        if (!ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, low, time2, high))
        {
            Print("Erreur lors de la création de l'objet ", name, " : ", GetLastError());
            return;
        }
        // Définir les propriétés du rectangle
        ObjectSetInteger(0, name, OBJPROP_COLOR, clrColor);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_FILL, true);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);  // Envoyer à l'arrière-plan
    }
    
    // Créer ou mettre à jour l'objet texte
    string textName = "Text_" + name;
    datetime midTime = (time1 + time2) / 2;
    double midPrice = (high + low) / 2;
    
    if (ObjectFind(0, textName) == -1)
    {
        if (!ObjectCreate(0, textName, OBJ_TEXT, 0, midTime, midPrice))
        {
            Print("Erreur lors de la création de l'objet texte ", textName, " : ", GetLastError());
            return;
        }
        ObjectSetString(0, textName, OBJPROP_TEXT, labelText);
        ObjectSetInteger(0, textName, OBJPROP_COLOR, LabelColor);
        ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, textName, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
        ObjectSetInteger(0, textName, OBJPROP_BACK, true);
    }
    else
    {
        ObjectSetString(0, textName, OBJPROP_TEXT, labelText);
        ObjectSetInteger(0, textName, OBJPROP_COLOR, LabelColor);
        ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, textName, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, textName, OBJPROP_ANCHOR, ANCHOR_CENTER);
        ObjectSetInteger(0, textName, OBJPROP_BACK, true);
        ObjectMove(0, textName, 0, midTime, midPrice);
    }
}


//+------------------------------------------------------------------+
//| Fonction pour vérifier si une bougie est verte                   |
//+------------------------------------------------------------------+
bool IsGreenCandle(double open, double close)
{
    return open < close;
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si une bougie est rouge                   |
//+------------------------------------------------------------------+
bool IsRedCandle(double open, double close)
{
    return !IsGreenCandle(open, close);
}

//+------------------------------------------------------------------+
//| Fonction pour supprimer les objets FVG                          |
//+------------------------------------------------------------------+
void SupprimerObjetsFVG()
{
    for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objName = ObjectName(0, i);
        if (StringFind(objName, "FVG_") == 0)
        {
            ObjectDelete(0, objName);
        }
         // Supprimer les textes associés aux FVG (commençant par "Text_FVG_")
        if (StringFind(objName, "Text_FVG_") == 0)
        {
            ObjectDelete(0, objName);
        }
    }
}


//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal FVG                             |
//+------------------------------------------------------------------+
// Structure pour stocker les informations d'un FVG
struct FVGData {
    datetime startTime;
    datetime endTime;
    double high1;
    double low1;
    double high3;
    double low3;
    bool isBullish;
    bool isTraded; // Ajouter ce champ
};

// Tableau global pour stocker les FVG actifs
FVGData activeFVGs[];
datetime lastCheckedCandleTime = 0;

// Fonction pour supprimer les FVG expirés
void RemoveExpiredFVGs() {
    datetime currentTime = TimeCurrent();
    int newSize = 0;
    for(int i = 0; i < ArraySize(activeFVGs); i++) {
        if(currentTime <= activeFVGs[i].endTime) {
            if(newSize != i) {
                activeFVGs[newSize] = activeFVGs[i];
            }
            newSize++;
        }
    }
    ArrayResize(activeFVGs, newSize);
}

CrossSignal CheckFVGSignal(string symbol)
{
    // Vérifier si c'est une nouvelle bougie
    datetime currentCandleTime = iTime(symbol, PERIOD_CURRENT, 0);
    bool isNewCandle = (currentCandleTime != lastCheckedCandleTime);

    // Mettre à jour le temps de la dernière bougie vérifiée
    if(isNewCandle) {
        lastCheckedCandleTime = currentCandleTime;
    }

    // Supprimer les FVG expirés
    RemoveExpiredFVGs();

    // Récupérer les données des bougies
    ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
    double high1 = iHigh(symbol, timeframe, 3);
    double low1  = iLow(symbol, timeframe, 3);
    double open2  = iOpen(symbol, timeframe, 2);
    double close2 = iClose(symbol, timeframe, 2);
    double high3 = iHigh(symbol, timeframe, 1);
    double low3  = iLow(symbol, timeframe, 1);
    double currentClose = iClose(symbol, timeframe, 1);
    double currentOpen = iOpen(symbol, timeframe, 1);

    bool isBearishCandle = currentClose < currentOpen;
    bool isBullishCandle = currentClose > currentOpen;

    // Vérifier les FVG existants à chaque nouvelle bougie si en mode Rebound
    if(isNewCandle && FVG_TradeAction == Rebound) {
        // Vérification des FVG existants (intégration de CheckExistingFVGs)
        for(int i = 0; i < ArraySize(activeFVGs); i++) {
            // Ajouter cette condition pour ne pas retravailler un FVG déjà tradé
            if (!activeFVGs[i].isTraded) {
                if(activeFVGs[i].isBullish) {
                    if(currentClose >= activeFVGs[i].high1 && currentClose <= activeFVGs[i].low3 && isBearishCandle) {
                        Print("Achat immédiat - BISI (FVG existant) : prix entre high1 et low3 avec bougie baissière");
                        Print("FVG start time: ", TimeToString(activeFVGs[i].startTime));
                        activeFVGs[i].isTraded = true; // Marquer le FVG comme tradé
                        return Achat;
                    }
                }
                else {
                    if(currentClose <= activeFVGs[i].low1 && currentClose >= activeFVGs[i].high3 && isBullishCandle) {
                        Print("Vente immédiate - SIBI (FVG existant) : prix entre low1 et high3 avec bougie haussière");
                        Print("FVG start time: ", TimeToString(activeFVGs[i].startTime));
                        activeFVGs[i].isTraded = true; // Marquer le FVG comme tradé
                        return Vente;
                    }
                }
            }
        }
    }

    // Récupération de la taille d'un tick pour le symbole actuel
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);

    // Calcul de l'amplitude du FVG en nombre de points
    double fvgAmplitudeBullish = MathAbs(low3 - high1) / tickSize;
    double fvgAmplitudeBearish = MathAbs(high3 - low1) / tickSize;

    // Déterminer la couleur de la bougie intermédiaire (index 2)
    bool isGreenCandle = (close2 > open2);
    bool isRedCandle   = !isGreenCandle;

    // Détection du FVG
    bool bullishFVG = false;
    bool bearishFVG = false;

    if(low3 > high1 && fvgAmplitudeBullish >= FVG_MinAmplitudePoints && isGreenCandle) {
        bullishFVG = true;
    }
    else if(high3 < low1 && fvgAmplitudeBearish >= FVG_MinAmplitudePoints && isRedCandle) {
        bearishFVG = true;
    }

    // Si un FVG est détecté
    if(bullishFVG || bearishFVG) {
        fvgStartTime = iTime(symbol, timeframe, 1);

        // Ajouter le nouveau FVG à la liste des FVG actifs
        int currentSize = ArraySize(activeFVGs);
        ArrayResize(activeFVGs, currentSize + 1);
        activeFVGs[currentSize].startTime = fvgStartTime;
        activeFVGs[currentSize].endTime = fvgStartTime + (FVG_CandleLength * PeriodSeconds(timeframe));
        activeFVGs[currentSize].high1 = high1;
        activeFVGs[currentSize].low1 = low1;
        activeFVGs[currentSize].high3 = high3;
        activeFVGs[currentSize].low3 = low3;
        activeFVGs[currentSize].isBullish = bullishFVG;
        activeFVGs[currentSize].isTraded = false; // Initialiser à false

        // On rentre ensuite dans la stratégie de trading
        if(FVG_TradeAction == Rebound) {
            datetime currentTime = TimeCurrent();

            if(bullishFVG) {
                // Vérifier si le FVG est encore valide
                if(currentTime > activeFVGs[currentSize].endTime) {
                    Print("FVG bullish expiré - Créé à: ", TimeToString(fvgStartTime), " Expiré à: ", TimeToString(activeFVGs[currentSize].endTime));
                    return Aucun;
                }

                Print("BISI - Vérification FVG bullish");
                Print("Limites rectangle - high1: ", high1, " low3: ", low3);
                Print("Validité FVG - Début: ", TimeToString(fvgStartTime), " Fin: ", TimeToString(activeFVGs[currentSize].endTime));
                Print("Prix de clôture actuel: ", currentClose);
                Print("Prix d'ouverture actuel: ", currentOpen);

                if(currentClose >= high1 && currentClose <= low3 && isBearishCandle) {
                    Print("Achat immédiat - BISI : prix entre high1 et low3 avec bougie baissière");
                    activeFVGs[currentSize].isTraded = true; // Marquer comme tradé
                    return Achat;
                }
            }
            else if(bearishFVG) {
                // Vérifier si le FVG est encore valide
                if(currentTime > activeFVGs[currentSize].endTime) {
                    Print("FVG bearish expiré - Créé à: ", TimeToString(fvgStartTime), " Expiré à: ", TimeToString(activeFVGs[currentSize].endTime));
                    return Aucun;
                }

                Print("SIBI - Vérification FVG bearish");
                Print("Limites rectangle - low1: ", low1, " high3: ", high3);
                Print("Validité FVG - Début: ", TimeToString(fvgStartTime), " Fin: ", TimeToString(activeFVGs[currentSize].endTime));
                Print("Prix de clôture actuel: ", currentClose);
                Print("Prix d'ouverture actuel: ", currentOpen);

                if(currentClose <= low1 && currentClose >= high3 && isBullishCandle) {
                    Print("Vente immédiate - SIBI : prix entre low1 et high3 avec bougie haussière");
                    activeFVGs[currentSize].isTraded = true; // Marquer comme tradé
                    return Vente;
                }
            }
        }
        else if(FVG_TradeAction == Breakout) {
            // Breakout haussier : le prix dépasse le niveau supérieur du gap (high1)
            if(bullishFVG && currentClose >= high1) {
                activeFVGs[currentSize].isTraded = true;
                Print("FVG Breakout bullish détecté - bullishFVG = ", bullishFVG,
                      ", currentClose = ", currentClose, " , high1 = ", high1, " , low1 = ", low1);
                return Achat;
            }
            // Breakout baissier : le prix est inférieur au niveau inférieur du gap (low1)
            else if(bearishFVG && currentClose <= low1) {
                activeFVGs[currentSize].isTraded = true;
                Print("FVG Breakout bearish détecté - bearishFVG = ", bearishFVG,
                      ", currentClose = ", currentClose, " , high1 = ", high1, " , low1 = ", low1);
                return Vente;
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
//| Fonction pour vérifier si une position est ouverte                |
//+------------------------------------------------------------------+
bool IsPositionOpen(string symbol)
{
    int totalPositions = PositionsTotal();

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

       // Vérifier le symbole et le Magic Number (si activé)
        if (positionSymbol == symbol && (!UseMagicNumber || positionMagic == MagicNumber))
        {
            return true; // Une position est ouverte pour ce symbole
        }
    }

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

      // Lire les informations de la position
      string symbol = PositionGetString(POSITION_SYMBOL);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      double lotSize = PositionGetDouble(POSITION_VOLUME);
      long positionMagicNumber = PositionGetInteger(POSITION_MAGIC);

      switch (StopLossType)
      {
         case SL_Classique:
            if (UseMagicNumber == true && positionMagicNumber == MagicNumber)
            {
                // Logique pour le Stop Loss classique avec le même Magic Number
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

                // Calculer les niveaux de SL et TP en pips
                double slPips = NormalizeDouble(StopLossCurrency / (lotSize * pointValue), digits);
                double tpPips = NormalizeDouble(TakeProfitCurrency / (lotSize * pointValue), digits);

                // Calculer les niveaux de SL et TP en prix
                double slPrice = 0.0;
                double tpPrice = 0.0;

                if (type == POSITION_TYPE_BUY)
                {
                    slPrice = NormalizeDouble(openPrice - slPips * point, digits);
                    tpPrice = NormalizeDouble(openPrice + tpPips * point, digits);
                }
                else if (type == POSITION_TYPE_SELL)
                {
                    slPrice = NormalizeDouble(openPrice + slPips * point, digits);
                    tpPrice = NormalizeDouble(openPrice - tpPips * point, digits);
                }
                  double currentSl = PositionGetDouble(POSITION_SL);
                double currentTp = PositionGetDouble(POSITION_TP);
                 // Modifier la position si nécessaire
                if (slPrice != currentSl || tpPrice != currentTp)
                {
                     bool modified = trade.PositionModify(ticket, slPrice, tpPrice);
                     if(modified){
                        Print("Position modifiée: SL=", slPrice, ", TP=", tpPrice, " (ticket=", ticket,")");
                     } else{
                          Print("Erreur modification de la position : ", trade.ResultRetcodeDescription());
                    }
                }
                else
                {
                        //Pas de changement
                        //Print("Position inchangée: SL=", currentSl, ", TP=", currentTp, " (ticket=", ticket,")");
                }
            }
            else if (!UseMagicNumber)
            {
               // Logique pour le Stop Loss classique sans restriction de Magic Number
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

                // Calculer les niveaux de SL et TP en pips
                double slPips = NormalizeDouble(StopLossCurrency / (lotSize * pointValue), digits);
                double tpPips = NormalizeDouble(TakeProfitCurrency / (lotSize * pointValue), digits);

                // Calculer les niveaux de SL et TP en prix
                double slPrice = 0.0;
                double tpPrice = 0.0;

                if (type == POSITION_TYPE_BUY)
                {
                    slPrice = NormalizeDouble(openPrice - slPips * point, digits);
                    tpPrice = NormalizeDouble(openPrice + tpPips * point, digits);
                }
                else if (type == POSITION_TYPE_SELL)
                {
                    slPrice = NormalizeDouble(openPrice + slPips * point, digits);
                    tpPrice = NormalizeDouble(openPrice - tpPips * point, digits);
                }
                double currentSl = PositionGetDouble(POSITION_SL);
                double currentTp = PositionGetDouble(POSITION_TP);
                // Modifier la position si nécessaire
                if (slPrice != currentSl || tpPrice != currentTp)
                {
                     bool modified = trade.PositionModify(ticket, slPrice, tpPrice);
                     if(modified){
                        Print("Position modifiée: SL=", slPrice, ", TP=", tpPrice, " (ticket=", ticket,")");
                     } else{
                          Print("Erreur modification de la position : ", trade.ResultRetcodeDescription());
                    }
                }
                else
                {
                        //Pas de changement
                        //Print("Position inchangée: SL=", currentSl, ", TP=", currentTp, " (ticket=", ticket,")");
                }
            }
            break;


         case SL_Suiveur:
            if (UseMagicNumber && positionMagicNumber == MagicNumber)
            {
               double seuilDeclenchementPercentage = 0.0, respirationPercentage = 0.0, slSuiveurPercentage = 0.0;
               double seuilDeclenchementPoints = 0.0, respirationPoints = 0.0, slSuiveurPoints = 0.0;
               UpdateTrailingStop(symbol, ticket, type, openPrice, currentPrice, sl,
                                  seuilDeclenchementPercentage, respirationPercentage, slSuiveurPercentage,
                                  seuilDeclenchementPoints, respirationPoints, slSuiveurPoints);

            }
            else if (!UseMagicNumber)
            {
               // Logique pour le Stop Loss suiveur sans restriction de Magic Number
               // Insérer ici la logique générale pour ce cas
            }
            break;

         case GridTrading:
            if (UseMagicNumber && positionMagicNumber == MagicNumber)
            {
               // Logique pour le Grid Trading avec le même Magic Number
               // Insérer ici la logique spécifique pour ce cas
            }
            else if (!UseMagicNumber)
            {
               // Logique pour le Grid Trading sans restriction de Magic Number
               // Insérer ici la logique générale pour ce cas
            }
            break;
          case low_medium_high:
            if (UseMagicNumber && positionMagicNumber == MagicNumber)
            {
               // Logique pour le Grid Trading avec le même Magic Number
               // Insérer ici la logique spécifique pour ce cas
            }
            else if (!UseMagicNumber)
            {
               // Logique pour le Grid Trading sans restriction de Magic Number
               // Insérer ici la logique générale pour ce cas
            }
            break;

         default:
            Print("Type de Stop Loss non reconnu: ", StopLossType);
            break;
      }

      // Vérifier si le Take Profit ou le Stop Loss a été atteint
      CheckTakeProfitStopLoss(symbol, ticket, type, currentPrice, sl, tp);
   }
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
//| Fonction pour afficher l'Ichimoku sur le graphique             |
//+------------------------------------------------------------------+
//--- Constantes pour Ichimoku (tendance)
const int Ichimoku_Tenkan = 9;   // Période Tenkan-sen pour la tendance (fixe)
const int Ichimoku_Kijun  = 26;  // Période Kijun-sen pour la tendance (fixe)
const int Ichimoku_Senkou = 52;  // Période Senkou Span B pour la tendance (fixe)
color  previousTrendColor = clrNONE; // Initialiser à "aucune couleur" au démarrage

void DisplayIchimokuOnChart()
{
    if (!DisplayOnChart)
        return; // Ne rien faire si l'affichage est désactivé

    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = TrendTimeframe;

    // Obtenir le nombre total de barres dans l'historique
    int totalBars = Bars(symbol, timeframe);

    // Déterminer la valeur effective de bougies à analyser
    int BougieIchimokuAnalyserEffective = Bougieichimokuaanalyser;

    // Forcer un minimum de 1000
    if (BougieIchimokuAnalyserEffective < 1000)
    {
        BougieIchimokuAnalyserEffective = 1000;
    }
    // Ne pas dépasser le nombre réel de barres disponibles
    else if (BougieIchimokuAnalyserEffective > totalBars)
    {
        BougieIchimokuAnalyserEffective = totalBars;
    }

    // Recalculer si la valeur a changé depuis la dernière fois
    if (BougieIchimokuAnalyserEffective != lastBougieIchimokuAnalyserEffective)
    {
        // Supprimer les objets existants (Tenkan, Kijun, Nuage)
        SupprimerObjetsIchimoku();

        // Mettre à jour la valeur mémorisée
        lastBougieIchimokuAnalyserEffective = BougieIchimokuAnalyserEffective;
    }

    // --- Tableaux pour les données Ichimoku ---
    double ichimokuTenkan[];
    double ichimokuKijun[];
    double ichimokuSenkouSpanA[];
    double ichimokuSenkouSpanB[];

    ArraySetAsSeries(ichimokuTenkan, true);
    ArraySetAsSeries(ichimokuKijun, true);
    ArraySetAsSeries(ichimokuSenkouSpanA, true);
    ArraySetAsSeries(ichimokuSenkouSpanB, true);

    // --- Création du handle Ichimoku ---
    int ichimokuHandle = iIchimoku(symbol, timeframe, Ichimoku_Tenkan, Ichimoku_Kijun, Ichimoku_Senkou);
    if (ichimokuHandle == INVALID_HANDLE)
    {
        Print("Erreur lors de la création du handle Ichimoku : ", GetLastError());
        return;
    }

    // --- Copie des données ---
    // On copie uniquement le nombre de barres requis
    if (CopyBuffer(ichimokuHandle, 0, 0, BougieIchimokuAnalyserEffective, ichimokuTenkan) <= 0 ||
        CopyBuffer(ichimokuHandle, 1, 0, BougieIchimokuAnalyserEffective, ichimokuKijun) <= 0 ||
        CopyBuffer(ichimokuHandle, 2, 0, BougieIchimokuAnalyserEffective, ichimokuSenkouSpanA) <= 0 ||
        CopyBuffer(ichimokuHandle, 3, 0, BougieIchimokuAnalyserEffective, ichimokuSenkouSpanB) <= 0)
    {
        Print("Erreur lors de la copie des données Ichimoku.");
        return;
    }

    // --- Boucle pour dessiner les lignes et le nuage ---
    // On itère jusqu'à BougieIchimokuAnalyserEffective - 1
    for (int i = 0; i < BougieIchimokuAnalyserEffective - 1; i++)
    {
        // Tenkan-sen (segments de ligne)
        string tenkanName = "Tenkan_" + IntegerToString(i);
        if (ichimokuTenkan[i] != EMPTY_VALUE && ichimokuTenkan[i + 1] != EMPTY_VALUE)
        {
            if (ObjectFind(0, tenkanName) < 0)
            {
                ObjectCreate(0, tenkanName, OBJ_TREND, 0, iTime(symbol, timeframe, i), ichimokuTenkan[i], iTime(symbol, timeframe, i + 1), ichimokuTenkan[i + 1]);
            }
            else
            {
                ObjectMove(0, tenkanName, 0, iTime(symbol, timeframe, i), ichimokuTenkan[i]);
                ObjectMove(0, tenkanName, 1, iTime(symbol, timeframe, i + 1), ichimokuTenkan[i + 1]);
            }

            ObjectSetInteger(0, tenkanName, OBJPROP_COLOR, previousTrendColor);
            ObjectSetInteger(0, tenkanName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, tenkanName, OBJPROP_WIDTH, 1);
        }
        else
        {
            ObjectDelete(0, tenkanName); // Supprimer si pas de données
        }

        // Kijun-sen (segments de ligne)
        string kijunName = "Kijun_" + IntegerToString(i);
        if (ichimokuKijun[i] != EMPTY_VALUE && ichimokuKijun[i + 1] != EMPTY_VALUE)
        {
            if (ObjectFind(0, kijunName) < 0)
            {
                ObjectCreate(0, kijunName, OBJ_TREND, 0, iTime(symbol, timeframe, i), ichimokuKijun[i], iTime(symbol, timeframe, i + 1), ichimokuKijun[i + 1]);
            }
            else
            {
                ObjectMove(0, kijunName, 0, iTime(symbol, timeframe, i), ichimokuKijun[i]);
                ObjectMove(0, kijunName, 1, iTime(symbol, timeframe, i + 1), ichimokuKijun[i + 1]);
            }

            ObjectSetInteger(0, kijunName, OBJPROP_COLOR, previousTrendColor);
            ObjectSetInteger(0, kijunName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, kijunName, OBJPROP_WIDTH, 1);
        }
        else
        {
            ObjectDelete(0, kijunName); // Supprimer si pas de données
        }

        // Senkou Span A et B (Nuage) - On commence Ichimoku_Kijun en avance
        if (i >= Ichimoku_Kijun && i - Ichimoku_Kijun < BougieIchimokuAnalyserEffective)
        {
            string nuageName = "Nuage_" + IntegerToString(i);
            color nuageColor;

            // Vérifier les croisements (Senkou A vs B)
            if (ichimokuSenkouSpanA[i - Ichimoku_Kijun] > ichimokuSenkouSpanB[i - Ichimoku_Kijun])
                nuageColor = TendanceH; // Senkou A au-dessus
            else
                nuageColor = TendanceB; // Senkou A en dessous

            if (ObjectFind(0, nuageName) < 0)
            {
                ObjectCreate(0, nuageName, OBJ_RECTANGLE, 0, iTime(symbol, timeframe, i - Ichimoku_Kijun), ichimokuSenkouSpanA[i - Ichimoku_Kijun], iTime(symbol, timeframe, i - Ichimoku_Kijun + 1), ichimokuSenkouSpanB[i - Ichimoku_Kijun]);
                ObjectSetInteger(0, nuageName, OBJPROP_COLOR, nuageColor);
                ObjectSetInteger(0, nuageName, OBJPROP_BACK, true);
            }

            // Déplacer les points du rectangle
            ObjectMove(0, nuageName, 0, iTime(symbol, timeframe, i - Ichimoku_Kijun), MathMin(ichimokuSenkouSpanA[i - Ichimoku_Kijun], ichimokuSenkouSpanB[i - Ichimoku_Kijun]));
            ObjectMove(0, nuageName, 1, iTime(symbol, timeframe, i - Ichimoku_Kijun + 1), MathMax(ichimokuSenkouSpanA[i - Ichimoku_Kijun], ichimokuSenkouSpanB[i - Ichimoku_Kijun]));
        }
    }

    // --- Nettoyage des objets "Nuage" au-delà de la limite ---
    for (int j = ObjectsTotal(0) - 1; j >= 0; j--)
    {
        string objName = ObjectName(0, j);
        if (StringFind(objName, "Nuage_") == 0)
        {
            // Extraire l'index de l'objet "Nuage"
            int objIndex = (int)StringToInteger(StringSubstr(objName, 6));

            // Supprimer si l'index est en dehors de la plage actuelle
            if (objIndex >= BougieIchimokuAnalyserEffective)
            {
                ObjectDelete(0, objName);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Fonction pour supprimer les objets de l'Ichimoku                |
//+------------------------------------------------------------------+
void SupprimerObjetsIchimoku()
{
    for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objName = ObjectName(0, i);
        // Vérifier si le nom de l'objet commence par "Tenkan_", "Kijun_" ou "Nuage_"
        if (StringFind(objName, "Tenkan_") == 0 || StringFind(objName, "Kijun_") == 0 || StringFind(objName, "Nuage_") == 0)
        {
            ObjectDelete(0, objName);
        }
    }
}

//+------------------------------------------------------------------+
//| Fonction pour afficher la Moyenne Mobile de tendance             |
//+------------------------------------------------------------------+
void DisplayMAOnChart()
{
    // Ne rien faire si l'affichage est désactivé
    if (!DisplayOnChart) 
        return;

    string symbol = Symbol();
    ENUM_TIMEFRAMES timeframe = TrendTimeframe;

    // Obtenir le nombre total de barres dans l'historique
    int totalBars = Bars(symbol, timeframe);

    // Déterminer la valeur effective de bougies à analyser
    int BougieTendanalyserEffective = BougieTendanalyser;

    // Forcer un minimum de 1000
    if (BougieTendanalyserEffective < 1000)
    {
        BougieTendanalyserEffective = 1000;
    }
    // Ne pas dépasser le nombre réel de barres disponibles
    else if (BougieTendanalyserEffective > totalBars)
    {
        BougieTendanalyserEffective = totalBars;
    }

    // Recalculer si la valeur a changé depuis la dernière fois
    if (BougieTendanalyserEffective != lastBougieTendanalyserEffective)
    {
        // Supprimer les objets existants de la MM de tendance
        SupprimerObjetsMMTendance();

        // Mettre à jour la valeur mémorisée
        lastBougieTendanalyserEffective = BougieTendanalyserEffective;
    }

    // --- Obtenir les données de la MM de tendance ---
    double maTrend[];
    ArraySetAsSeries(maTrend, true);

    // Création du handle de la MM
    int maTrendHandle = iMA(symbol, timeframe, TrendMA_Period, 0, MODE_SMA, PRICE_CLOSE);
    if (maTrendHandle == INVALID_HANDLE)
    {
        Print("Erreur lors de la création du handle de la MM de tendance : ", GetLastError());
        return;
    }

    // Copier UNIQUEMENT BougieTendanalyserEffective barres
    if (CopyBuffer(maTrendHandle, 0, 0, BougieTendanalyserEffective, maTrend) <= 0)
    {
        Print("Erreur lors de la copie des données de la MM de tendance.");
        return;
    }

    // --- Boucle pour dessiner ou mettre à jour la MM de tendance ---
    for (int i = 0; i < BougieTendanalyserEffective - 1; i++)
    {
        string objName = "MA_Trend_" + IntegerToString(i);

        // Vérifier si on a bien deux points consécutifs valides
        if (maTrend[i] != EMPTY_VALUE && maTrend[i + 1] != EMPTY_VALUE)
        {
            // Créer l'objet s'il n'existe pas
            if (ObjectFind(0, objName) < 0)
            {
                if (!ObjectCreate(0, objName, OBJ_TREND, 0, 
                                  iTime(symbol, timeframe, i),     maTrend[i], 
                                  iTime(symbol, timeframe, i + 1), maTrend[i + 1]))
                {
                    Print("Échec de la création de l'objet : ", objName, " Erreur : ", GetLastError());
                    continue; // Passer à l'objet suivant
                }
            }
            else
            {
                // S'il existe, le déplacer
                if (!ObjectMove(0, objName, 0, iTime(symbol, timeframe, i), maTrend[i]) ||
                    !ObjectMove(0, objName, 1, iTime(symbol, timeframe, i + 1), maTrend[i + 1]))
                {
                    Print("Échec du déplacement de l'objet : ", objName, " Erreur : ", GetLastError());
                    continue; // Passer à l'objet suivant
                }
            }

            // --- Déterminer la couleur de la MM en fonction de la tendance ---
            color maColor = TendanceH; // Valeur par défaut
            if (i > 0) // Comparer avec le point précédent
            {
                if (maTrend[i] < maTrend[i - 1])
                    maColor = TendanceH; // Haussière
                else if (maTrend[i] > maTrend[i - 1])
                    maColor = TendanceB; // Baissière
                // Si égal, conserver la couleur par défaut ou une autre couleur si souhaité
            }

            // Appliquer la couleur et la visibilité
            ObjectSetInteger(0, objName, OBJPROP_COLOR, maColor);
            ObjectSetInteger(0, objName, OBJPROP_HIDDEN, !DisplayOnChart);
            ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID); // Optionnel : Définir le style de ligne
            ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);         // Optionnel : Définir l'épaisseur de la ligne
        }
        else
        {
            // Si pas de valeur, on supprime pour éviter de laisser des segments cassés
            if (!ObjectDelete(0, objName))
            {
                Print("Échec de la suppression de l'objet : ", objName, " Erreur : ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Fonction pour supprimer les objets de la MM de tendance          |
//+------------------------------------------------------------------+
void SupprimerObjetsMMTendance()
{
    for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objName = ObjectName(0, i);
        // Vérifier si le nom de l'objet commence par "MA_Trend_"
        if (StringFind(objName, "MA_Trend_") == 0)
        {
            if (ObjectDelete(0, objName))
            {
                // Optionnel : Afficher un message de suppression réussie
                // Print("Objet supprimé : ", objName);
            }
            else
            {
                Print("Échec de la suppression de l'objet : ", objName, " Erreur : ", GetLastError());
            }
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

   // Vérifier les limites de lot
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   // Arrondir au pas de lot
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lotSize = NormalizeDouble(MathRound(lotSize / lotStep) * lotStep, 2);

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
   if (EnablePushNotifications)
   {
      if (!SendNotification(message))
          Print("Erreur lors de l'envoi de la notification push: ", GetLastError());
   }

   // Alerte dans une fenêtre MT5
   if (EnableAlerts)
   {
       Alert(message);
   }

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
        case 3: xPos = 10;                    yPos = (int)chartHeight - 440; break; // Bas gauche
        case 4: xPos = (int)chartWidth - 320; yPos = (int)chartHeight - 440; break; // Bas droit
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
    lines[lineIndex++] = StringFormat("Solde : %.2f || Valeur du point : %.2f",
                                 AccountInfoDouble(ACCOUNT_EQUITY),
                                 SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE));
                                 
  ArrayResize(lines, lineIndex + 1);
    datetime current_time = TimeCurrent();
    datetime timeClose = iTime(Symbol(), PERIOD_CURRENT, 0);
    long seconds_remaining = current_time - timeClose;
    lines[lineIndex++] = StringFormat("G/P : %.2f || Temps écouler : %02d:%02d",
                                     AccountInfoDouble(ACCOUNT_PROFIT),
                                     seconds_remaining / 60, // Minutes
                                     seconds_remaining % 60  // Secondes
                                    );
                                    
    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = StringFormat("Marge utilisée : %.2f || Marge restante : %.2f" , AccountInfoDouble(ACCOUNT_MARGIN), AccountInfoDouble(ACCOUNT_FREEMARGIN));

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
        lines[lineIndex++] = StringFormat("Nb max de POS : %d", GridMaxOrders);
    }
    else
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat("Grid trading : (%s)", (StopLossType == GridTrading) ? "True" : "False");
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Nb max de POS : 0";
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
        lines[lineIndex++] = "SL suiveur non utilisé";
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
                ArrayResize(lines, lineIndex + 1);
                lines[lineIndex++] = "-------------------------------------------";
       
    // -------------------------------------------------------
    // SECTION 5 : SL pourcentage
    // -------------------------------------------------------
        if (StopLossType == low_medium_high)
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "SL pourcentage : (True)";

// D'abord, définissez les pourcentages en fonction du type de risque
double riskPercentage = 0.0;
double slPercentage = 0.0;
double equity = AccountInfoDouble(ACCOUNT_EQUITY);

switch(Type_pourcentage)
{
case Low_risque:
riskPercentage = 0.01; // 1%
slPercentage = 0.10; // 20%
break;
case Medium_risque:
riskPercentage = 0.02; // 2%
slPercentage = 0.20; // 20%
break;
case High_risque:
riskPercentage = 0.03; // 3%
slPercentage = 0.30; // 30%
break;
}

// Calculer les valeurs en devise
double tpDevise = equity * riskPercentage;
double slDevise = equity * slPercentage;

// Calculer le lot
double slLevel, tpLevel;
ENUM_ORDER_TYPE orderType = ORDER_TYPE_BUY; // Le type d'ordre n'affecte pas le calcul du lot ici
double lotSize = CalculateLotAndRisk(_Symbol, orderType, Type_pourcentage, TPviser, slLevel, tpLevel);

// Ajouter les lignes au tableau
ArrayResize(lines, lineIndex + 1);
lines[lineIndex++] = StringFormat("Lots: %.2f, TP : %.2f €, SL : %.2f €", lotSize, tpDevise, slDevise);
    
    }
    else
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "SL pourcentage (False)";
        
ArrayResize(lines, lineIndex + 1);      
lines[lineIndex++] = "Lots: 0.00, TP : 0€, SL : 0€";

    }
                ArrayResize(lines, lineIndex + 1);
                lines[lineIndex++] = "-------------------------------------------";
    
    // -------------------------------------------------------
    // SECTION 6 : News
    // -------------------------------------------------------
    if (!UseNewsFilter)
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "News : (False)";
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Prochaine news : ";     

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Noms : ";
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Devise : ";  
   
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Précédent : ";  
    }
    else
    {   
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "News : (True)";
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Prochaine news : " + TimeToString(g_NextNews.time, TIME_DATE|TIME_MINUTES);     

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Noms : " + g_NextNews.name;
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Devise : " + g_NextNews.currency + " || Importance : " + g_NextNews.importance;  
   
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Précédent : " + g_NextNews.previous + " || Prévu : " + g_NextNews.forecast;  

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
//| Fonction pour calculer les lots suivant type de risque           |
//+------------------------------------------------------------------+
double CalculateLotAndRisk(string symbol, ENUM_ORDER_TYPE orderType, Typepourcentage riskType, int targetTP, double &sl, double &tp)
{
   if (IsPositionOpen(symbol) == true)
   {
      return false;
   }
// Récupérer l'équité du compte
double equity = AccountInfoDouble(ACCOUNT_EQUITY);

// Définir les pourcentages en fonction du type de risque
double riskPercentage = 0.0;
double slPercentage = 0.0;

switch(riskType)
{
case Low_risque:
riskPercentage = 0.01; // 1%
slPercentage = 0.10; // 10%
break;
case Medium_risque:
riskPercentage = 0.02; // 2%
slPercentage = 0.20; // 20%
break;
case High_risque:
riskPercentage = 0.03; // 3%
slPercentage = 0.30; // 30%
break;
}

// Calculer le montant risqué en devise
double riskAmount = equity * riskPercentage;

// Récupérer les informations du symbole
double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

// Calculer le lot nécessaire pour atteindre le profit cible avec le nombre de points visé
double lotSize = riskAmount / (targetTP * pointValue);
lotSize = NormalizeDouble(lotSize, 2); // Passage a 2 decimals

// Normaliser la taille du lot selon les limites du broker
double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

lotSize = MathMin(maxLot, MathMax(minLot, NormalizeDouble(lotSize, 2)));

// Calculer les points pour le SL
double slPoints = (equity * slPercentage) / (lotSize * pointValue);

// Récupérer le prix d'ouverture
double openPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);

// Calculer les niveaux de SL et TP
if(orderType == ORDER_TYPE_BUY)
{
sl = NormalizeDouble(openPrice - slPoints * point, digits);
tp = NormalizeDouble(openPrice + targetTP * point, digits);
}
else if(orderType == ORDER_TYPE_SELL)
{
sl = NormalizeDouble(openPrice + slPoints * point, digits);
tp = NormalizeDouble(openPrice - targetTP * point, digits);
}

return lotSize;
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

   // Calcul des SL et TP en fonction du type de SL choisi
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

   else if (StopLossType == low_medium_high)
   {
   volume = CalculateLotAndRisk(symbol, orderType, Type_pourcentage, TPviser, sl, tp);
   }


   // Préparer la structure MqlTradeRequest
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = volume;
   request.type = orderType;
   request.price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10; // Slippage autorisé
   request.magic = MagicNumber; // Ajout du Magic Number
   request.comment = comment;

   // Envoyer l'ordre
   if (OrderSend(request, result))
   {
      Print("Position ouverte pour ", symbol, " - Type: ", EnumToString(orderType), " - Volume: ", volume);

      // Envoyer des notifications
      SendNotifications(symbol, orderType, volume, request.price, sl, tp);

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
   if (IsPositionOpen(symbol) == true)
   {
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
   if (IsPositionOpen(symbol) == true)
   {
      return false;
   }
   else
   {
   double sl = 0.0, tp = 0.0;
   double slPercentage = 0.0, tpPercentage = 0.0, slPoints = 0.0, tpPoints = 0.0;

   CalculateClassicSLTP(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);

   if (OpenPosition(symbol, (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, volume, sl, tp))
   {
      return true;
   }
   }
   return false;
}

//+-----------------------------------------------------------------------------------+
// Fonction pour ouvrir une position en fonction du risque low medium ou high         |
//+-----------------------------------------------------------------------------------+
bool OpenPositionWithPercentageSL(string symbol, CrossSignal signal, double volume, double slLevel, double tpLevel)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = volume;
   request.type = (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   request.price = (request.type == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   request.sl = slLevel;
   request.tp = tpLevel;
   request.deviation = MaxSlippagePoints;
   request.magic = MagicNumber;
   request.comment = "";
   request.type_filling = ORDER_FILLING_FOK;

   if(!OrderSend(request, result))
   {
      Print("Erreur d'ouverture de position : ", GetLastError());
      return false;
   }
   
   if(result.retcode != TRADE_RETCODE_DONE)
   {
      Print("Erreur d'ouverture de position. Code de retour : ", result.retcode);
      return false;
   }
   
   return true;
}

//+-----------------------------------------------------------------------------------+
// Fonction pour détecter et supprimer une sous-fenêtre sous le graphique principal   |
//+-----------------------------------------------------------------------------------+
void DeleteSubWindowIfExists() {
   // Récupère le nombre total de sous-fenêtres
   int subWindows = (int)ChartGetInteger(0, CHART_WINDOWS_TOTAL);
   
   // Si une sous-fenêtre existe, on vérifie les indicateurs
   if (subWindows > 0) {
      for (int i = subWindows; i >= 1; i--) { // Commence à 1 pour ignorer la fenêtre principale
         // Récupère le nombre d'indicateurs dans la sous-fenêtre
         int indicatorCount = ChartIndicatorsTotal(0, i);
         
         // Si des indicateurs sont présents, on les supprime
         if (indicatorCount > 0) {
            for (int j = 0; j < indicatorCount; j++) {
               string indicatorName = ChartIndicatorName(0, i, j); // Récupère le nom de l'indicateur
               ChartIndicatorDelete(0, i, indicatorName); // Supprime l'indicateur
            }
         } else {
         }
      }
      ChartRedraw(); // Redessine le graphique
   } else {
   }
}


//+------------------------------------------------------------------+
//| Fonction pour supprimer les objets des autres stratégies         |
//+------------------------------------------------------------------+
void SupprimerObjetsAutresStrategies(StrategyType currentStrategy)
{
    for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string objName = ObjectName(0, i);

        // Vérifier si l'objet appartient à une autre stratégie
        bool deleteObject = false;

        // Si la stratégie actuelle est MA_Crossover
        if (currentStrategy == MA_Crossover)
        {
            // Supprimer les objets des stratégies RSI et FVG
            if ((StringFind(objName, "RSI_") == 0) || (StringFind(objName, "FVG_") == 0) || (StringFind(objName, "Label_FVG_Bullish_") == 0) || (StringFind(objName, "Label_FVG_Bearish_") == 0))
            {
                deleteObject = true;
            }
            // NE PAS supprimer les objets "MA1_", "MA2_" ou "MA_Trend_"
        }
        else if (currentStrategy == RSI_OSOB)
        {
            // Supprimer les objets des stratégies MA_Crossover (sauf "MA_Trend_") et FVG
            if ((StringFind(objName, "MA1_") == 0) || (StringFind(objName, "MA2_") == 0) || (StringFind(objName, "FVG_") == 0) || (StringFind(objName, "Label_FVG_Bullish_") == 0) || (StringFind(objName, "Label_FVG_Bearish_") == 0))
            {
                deleteObject = true;
            }
            // NE PAS supprimer les objets "MA_Trend_"
        }
        else if (currentStrategy == FVG_Strategy)
        {
            // Supprimer les objets des stratégies MA_Crossover (sauf "MA_Trend_") et RSI
            if ((StringFind(objName, "MA1_") == 0) || (StringFind(objName, "MA2_") == 0) || 
            (StringFind(objName, "RSI_") == 0) ||(StringFind(objName, "RSI_") == 0))
            {
                deleteObject = true;
            }
            // NE PAS supprimer les objets "MA_Trend_"
        }

        // Supprimer l'objet s'il appartient à une autre stratégie
        if (deleteObject)
        {
            if (!ObjectDelete(0, objName))
            {
                Print("Erreur lors de la suppression de l'objet : ", objName, " Erreur : ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Fin du code                                                      |
//+------------------------------------------------------------------+  
