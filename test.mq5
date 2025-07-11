//+------------------------------------------------------------------+
//|                                                        MonEA.mq5 |
//|                              Copyright 2024 Votre Nom            |
//|                              https://www.votre-site.com          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Votre Nom"
#property link      "https://www.votre-site.com"
#property version   "1.00"
#property strict
#property tester_indicator "Examples\\ZigZag"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Arrays\ArrayInt.mqh>
#include <ChartObjects\ChartObject.mqh>
#include <Arrays\ArrayString.mqh>
#include <ChartObjects/ChartObjectsTxtControls.mqh>

// desactivation des log en mode backtest
#define DEBUG_MODE false  // Mettez "true" pour activer les logs si nécessaire
bool isBacktestNonVisuel = false; // Variable pour détecter le mode Backtest non visuel pour if else debut oninit


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
input string  activIA                 = "=== Activation IA ===";
input bool    IA                      = false;           // Utiliser IA
input bool    paireIA                 = false;           // Afficher les paires analyser par l'IA
input int     PositionpaireIA         = 3;               // 1=Haut gauche, 2=Haut Droite, 3=Bas Gauche, 4=Bas Droite
input color   TextColorIA               = clrBlack;      // Couleur de tous les textes
input color   TableFondColorIA          = clrYellow;     // Couleur de fond du tableau
input string  magic_settings          = "=== Gestion du Magic Number ===";
input bool    UseMagicNumber          = false;           // False = Manuel + Tous magic
input int     MagicNumber             = 123456;          // Magic Number
input string  ecart1                  = "";
input string  display_settings        = "=== Paramètres d'affichage ===";
input bool    DisplayTable            = true; // Afficher le tableau d'informations
input int     TextPosition            = 4;               // 1=Haut gauche, 2=Haut Droite, 3=Bas Gauche, 4=Bas Droite
input color   TextColor               = clrBlack;        // Couleur de tous les textes
input color   TableFondColor          = clrYellow;       // Couleur de fond du tableau
input string  ecart2                  = "";
input string  swaptrade               = "=== Swap d'interêt ===";
input bool    SwapPositif             = false;           // True = Swap+ (Prend que dans le sens des interêts positifs)
input string  ecart3                  = "";
input string  symbol_settings         = "=== Symboles à trader ===";
input bool    TradeAllForexPairs      = true;            // Trader toutes les paires Forex
input bool    TradeAllIndices         = true;            // Trader tous les indices
input string  ecart4                  = "";
input string  news_settings           = "=== Gestion des actualités ===";
input bool    UseNewsFilter           = false;           // Utiliser le filtre des actualités
input int     NewsFilterMinutesBefore = 60;              // Minutes avant les actualités pour éviter le trading
input int     NewsFilterMinutesAfter  = 60;              // Minutes après les actualités pour éviter le trading
enum Choiximportance {High, High_Medium, All};
input Choiximportance NewsImportance  = High;            // Choix importance news
input string  ecart5                  = "";
input string  notification            = "=== Notification ===";
input bool    EnablePushNotifications = false;           // Activer les notifications push
input bool    EnableAlerts            = false;           // Activer les alertes (fenêtre pop-up MT5)
input string  ecart6                  = "";
input string  risque                  = "=== Paramètres des lots ===";
enum LotType {LotFixe, low_medium_high};
input LotType LotSizeType             = LotFixe;         // Type de gestion du volume
input double  FixedLotSize            = 0.01;            // Taille de lot fixe
enum RisqueType {Very_Low_P, Low_P, Medium_P, High_P, Very_High_P};
input RisqueType RisquePoucentage    = Very_Low_P;        // Very low(1%) Low(2%) Medium(5%) High(10%) Very high(20%) 
input string  ecart7                  = "";
input string  spreadslippage          = "=== Spread et slippage ===";
input bool    UseMaxSpreadFilter      = false;           // Utiliser le filtre de spread maximum
input long    MaxSpreadPoints         = 20;              // Spread maximum autorisé en points
input long    MaxSlippagePoints       = 3;               // Slippage maximum autorisé en points
input string  ecart8                  = "";
input string trend_settings           = "=== Méthode de détermination de la tendance ===";
input bool DisplayOnChart             = false;           // Afficher les indicateurs de tendance sur le graphique
input bool UseTrendDetection          = false;           // activer ou désactiver la détection de tendance
enum TrendMethod {Ichimoku, MA};
input TrendMethod TrendMethodChoice   = Ichimoku;        // Choix de la méthode de tendance
input ENUM_TIMEFRAMES TrendTimeframe  = PERIOD_D1;       // Unité de temps pour la tendance
input int     Bougieichimokuaanalyser = 1000;            // Nombre de bougies à utiliser 1000 minimum
input int TrendMA_Period              = 200;             // Période de la MM pour la tendance
input int   BougieTendanalyser        = 1000;            // Nombre de bougies à utiliser 1000 minimum
input color TendanceH                 = clrBlue;
input color TendanceB                 = clrYellow;
input string  ecart9                  = "";
input string  strategy_settings       = "=== Stratégie de trading ===";
enum StrategyType {MA_Crossover, RSI_OSOB, FVG_Strategy, PP_RSI_MA_Strategy, Support_Resistance};
input StrategyType Strategy           = RSI_OSOB;    // Choix de la stratégie
input string  ecart10                 = "";
//--- Paramètres pour la stratégie de croisement de MM
input string  ma_settings             = "--- Paramètres des Moyennes Mobiles ---";
input int     MA_Period1              = 20;              // MM Rapide
input int     MA_Period2              = 50;              // MM Lente
input ENUM_MA_METHOD MA_Method        = MODE_SMA;        // Méthode de calcul des MM
input ENUM_APPLIED_PRICE MA_Price     = PRICE_CLOSE;     // Prix appliqué pour les MM
input color   couleurdoubleMM         = clrYellow;       // Couleur des deux MM
input int     BougieMMaanalyser       = 1000;            // Nombre de bougies à utiliser 1000 minimum
input string  ecart11                 = "";
//--- Paramètres pour la stratégie RSI
input string  rsi_settings            = "--- Paramètres RSI ---";
input int     RSI_Period              = 14;              // Période du RSI
input string  ecart12                 = "";
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
input string  ecart13                 = "";
input string  Pprsima_setting         = "--- Paramètres PP RSI MA ---"; 
enum PP_Action {PPRebond, PPRSIMAoverhold};
input PP_Action  PP_TradeAction       = PPRSIMAoverhold; // Choix stratégie
input string  ecart14                 = "";
input string  SR_settings             = "--- Paramètres des Support/Résistance ---";
input bool    DisplaySROnChart        = true;            // Affichage des Supports / Résistances
input int     NbcontactSR             = 3;               // Contact pour détécter un S/R
input color   couleurSR               = clrYellow;       // Couleur des S/R
input int     BougieSRaanalyser       = 1000;            // Nombre de bougies à utiliser 1000 minimum
enum Method_SR {Fractal, ZigZag};
input Method_SR  Method_detection_SR  = Fractal;         // Choix méthode de détéction des S/R
input string  ecart15                 = "";
input string  stoploss_settings       = "=== Paramètres de Stop Loss ===";
enum StopType {SL_Classique, GridTrading};
input StopType StopLossType           = GridTrading;     // Type de Stop Loss
input string  ecart16                 = "";
input string  sl_classique_settings   = "--- Paramètres SL Classique ---";
input double  StopLossCurrency        = 1.0;             // Stop Loss en devise (0 pour aucun SL)
input double  TakeProfitCurrency      = 1.0;             // Take Profit en devise (0 pour aucun TP)
input string  ecart17                 = "";
//--- Paramètres pour le Grid Trading
input string  grid_settings           = "--- Paramètres du Grid Trading ---";
input double  GridDistancePoints5D    = 0.0001;          // Distance nouvelle position du grid 5 décimales
input double  GridDistancePoints4D    = 0.001;           // Distance nouvelle position du grid 4 décimales
input double  GridDistancePoints3D    = 0.01;            // Distance nouvelle position du grid 3 décimales
input double  GridDistancePoints2D    = 0.1;             // Distance nouvelle position du grid 2 décimales
input double  InpSeuilDeclenchement5D = 0.0001;          // Seuil de déclenchement 5 décimales
input double  InpSeuilDeclenchement4D = 0.001;           // Seuil de déclenchement 4 décimales
input double  InpSeuilDeclenchement3D = 0.01;            // Seuil de déclenchement 3 décimales
input double  InpSeuilDeclenchement2D = 0.1;             // Seuil de déclenchement 2 décimales
input double  InpRespiration5D        = 0.0001;          // Respiration pour le seuil 5 décimales
input double  InpRespiration4D        = 0.001;           // Respiration pour le seuil 4 décimales
input double  InpRespiration3D        = 0.01;            // Respiration pour le seuil 3 décimales
input double  InpRespiration2D        = 0.1;             // Respiration pour le seuil 2 décimales
input double  InpSLsuiveur5D          = 0.001;          // Distance du SL suiveur 5 décimales
input double  InpSLsuiveur4D          = 0.01;           // Distance du SL suiveur 4 décimales
input double  InpSLsuiveur3D          = 0.1;            // Distance du SL suiveur 3 décimales
input double  InpSLsuiveur2D          = 1.0;             // Distance du SL suiveur 2 décimales
input double  InpRespirationSL5D      = 0.0001;          // Respiration SLsuiveur 5 décimales mode "Seuil" UNIQUEMENT
input double  InpRespirationSL4D      = 0.001;           // Respiration SLsuiveur 4 décimales mode "Seuil" UNIQUEMENT
input double  InpRespirationSL3D      = 0.01;            // Respiration SLsuiveur 3 décimales mode "Seuil" UNIQUEMENT
input double  InpRespirationSL2D      = 0.1;             // Respiration SLsuiveur 2 décimales mode "Seuil" UNIQUEMENT
enum Choixsuiveur {Seuil, Cours_Actuel};
input Choixsuiveur Typesuivie = Cours_Actuel; // Choix Type de suivie
enum risquegrid {Lots_Grid, POS_Grid};
input risquegrid Risque_Grid         = Lots_Grid;        // Choix du type de limitation
input double     GridMaxlots             = 1.00;         // Nombre maximum de lots utiliser dans le grid
input int     GridMaxOrders           = 5;               // Nombre maximum de positions dans le grid
input string  ecart18                 = "";
//--- Paramètres pour le type de risque
input string  typerisque              = "--- Paramètres Low, medium, high ---";
enum Typepourcentage {Verylow_risque, Low_risque, Medium_risque, High_risque, Veryhigh_risque};
input Typepourcentage Type_pourcentage= Low_risque;      // Very low (1%) Low(2%), Medium(5%), High(10%), Very high (20%)
input int     TPpourcentage           = 10;              // Tp en point
input int     SLpourcentage           = 10;              // SL en point
input string  ecart19                 = "";


//--- Variables pour le SL suiveur
bool seuil_declenche_actif = false;
double sl_level = 0.0;
double position_price_open = 0.0;
double trailingSL = 0.0;
double adjusted_InpSeuilDeclenchement = 0.0;
double adjusted_InpRespiration = 0.0;
double adjusted_InpSLsuiveur = 0.0;
double InpRequis;  // Variable pour stocker le prix requis
double InpBroker; // Variable pour stocker la limite du broker

//--- Variables globales pour la martingale
int MartingaleAttempts[]; // Tableau pour suivre les tentatives de martingale par symbole

//--- Variables globales
datetime      LastTradeTime     = 0;
//datetime      lastVerificationTime = 0;;             // Heure de la dernière vérification pour SL/TP
//input int     VerificationInterval  = 1;             // Intervalle de vérification en secondes (5 minutes = 300 secondes)
string        ActiveSymbols[];                         // Tableau des symboles actifs
bool          isNewMinute       = false;
datetime      lastMinuteChecked = 0;
ulong         current_ticket    = 0;                   // Pour suivre le ticket de la position courante
datetime      lastBarTime       = 0;                   // Heure de la dernière bougie traitée

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

// Variables globales pour stocker les niveaux PP, R, et S
double g_PPLevel = 0.0;
double g_R1Level = 0.0;
double g_R2Level = 0.0;
double g_R3Level = 0.0;
double g_S1Level = 0.0;
double g_S2Level = 0.0;
double g_S3Level = 0.0;

// Variable globale pour stocker les S/R
double levelsUp[];
double levelsDown[];

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
// Variable globale pour stocker la dernière valeur utilisée et détecter les changements
int lastBougieSRaanalyserEffective = 0;

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
//| Fonction de suppression des indicateurs de tendance             |
//+------------------------------------------------------------------+
void RemoveAllIndicators()
{
   int deletedCount = 0;

   // Supprimer les objets de l'ancienne méthode de tendance
   if (TrendMethodChoice == Ichimoku)
   {
      // Nouvelle méthode est Ichimoku : supprimer les objets MA
      deletedCount += ObjectsDeleteAll(0, "MA_Trend_");
      if (deletedCount > 0)
      {
         //Print("Supprimé ", deletedCount, " objets MA avant de passer à Ichimoku.");
      }
      else
      {
         //Print("Aucun objet MA trouvé à supprimer avant de passer à Ichimoku.");
      }
   }
   else if (TrendMethodChoice == MA)
   {
      // Nouvelle méthode est MA : supprimer les objets Ichimoku
      deletedCount += ObjectsDeleteAll(0, "Tenkan_");
      deletedCount += ObjectsDeleteAll(0, "Kijun_");
      deletedCount += ObjectsDeleteAll(0, "Nuage_");
      if (deletedCount > 0)
      {
         //Print("Supprimé ", deletedCount, " objets Ichimoku avant de passer à MA.");
      }
      else
      {
         //Print("Aucun objet Ichimoku trouvé à supprimer avant de passer à MA.");
      }
   }
   else
   {
      // Si aucune méthode de tendance valide n'est sélectionnée, ne rien faire
      //Print("Aucune méthode de tendance valide sélectionnée. Aucun objet supprimé.");
   }

   isIndicatorLoaded = false;
}

//+------------------------------------------------------------------+
//| Fonction d'initialisation de l'expert                            |
//+------------------------------------------------------------------+
int OnInit()
{

    if (isBacktestNonVisuel)
    {
       // Pour backtest sans visuel
if (MQLInfoInteger(MQL_TESTER)) // Vérifie si on est en mode backtest
{
ChartSetInteger(0, CHART_SHOW, false); // Essaye de cacher le graphique

// Supprime tous les objets graphiques pour éviter les ralentissements
ObjectsDeleteAll(0);

// Désactive les commentaires affichés sur l'écran
Comment("");

// Désactive le rafraîchissement du graphique
ChartSetInteger(0, CHART_AUTOSCROLL, false);
ChartSetInteger(0, CHART_SHIFT, false);

// Supprime tous les indicateurs
int total = ChartIndicatorsTotal(0, 0); // Premier 0 = chart_id, second 0 = subwindow (principale)
for(int i=total-1; i>=0; i--)
{
    string indicator_name = ChartIndicatorName(0, 0, i);
    ChartIndicatorDelete(0, 0, indicator_name); // Nécessite le nom de l'indicateur
}

Print("Mode backtest détecté : Affichage graphique désactivé.");

}


return(INIT_SUCCEEDED); // Sortir immédiatement pour éviter d'exécuter le reste de Oninit()
       
    }
    
    
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

 // Fonction de grid avec verification si EA activer ou non
   if (StopLossType == GridTrading)
   {
      // Vérification complète des conditions pour le trading automatique
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        //Print("ManageGridSLSuiveur: Trading automatique désactivé, fonction ignorée");
        return;
    }
    
    // Vérifier également si le compte permet le trading
    if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
    {
        //Print("ManageGridSLSuiveur: Trading non autorisé sur ce compte, fonction ignorée");
        return;
    }
    
    // Vérifier si le trading est autorisé pour l'expert
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        //Print("ManageGridSLSuiveur: Trading non autorisé pour cet expert, fonction ignorée");
        return;
    }
    
    // Vérifier également si l'expert est autorisé à trader
    if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        //Print("ManageGridSLSuiveur: Trading algorithmique désactivé, fonction ignorée");
        return;
    }
      DeletePendingLimitOrders();
      PlacePendingOrder();
      ManageGridSLSuiveur();
   }

   // appelle istherenews pour MAJ en temps reel et pas chaque minutes
   string symbol = Symbol();
   IsThereNews(symbol);

   // Mettre à jour la liste des symboles actifs à chaque tick
    BuildActiveSymbolList();
    
   // Variable statique pour suivre la stratégie précédente
   static int AncienneStrategie = -1;
   
   // Récupérer le timeframe actuel du graphique
   ENUM_TIMEFRAMES currentTF = (ENUM_TIMEFRAMES)Period();
   // Vérifier si une nouvelle bougie s'est formée pour MAJ FVG
   datetime currentBarTime = iTime(Symbol(), currentTF, 0);
   
    // Suppression indicateur selon strategie de signal
   switch(Strategy) {
      case MA_Crossover:
         SupprimerObjetsFVG();
         SupprimerObjetsPP();
         SupprimerObjetsSR();
         if ((int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) > 0)
         { // Si une sous-fenêtre existe
            DeleteSubWindowIfExists(); // Supprime la sous-fenêtre
         }

         DisplayMAsignal(); // Affiche la MA
         break;

      case RSI_OSOB:
         if (AncienneStrategie != RSI_OSOB)
         {
         DeleteSubWindowIfExists();
         AncienneStrategie = RSI_OSOB;
         }
         if(RSI_Period != previous_RSI_Period) // si changement periode RSI
         {
         DeleteSubWindowIfExists();
         DisplayRSIInSubWindow();
        // Mettre a jour la période précédente
        previous_RSI_Period = RSI_Period;
        }
        else
        {
        // Afficher simplement le RSI dans la sous-fenêtre existante
        SupprimerObjetsMM();
        SupprimerObjetsFVG();
        SupprimerObjetsPP();
        SupprimerObjetsSR();
        DisplayRSIInSubWindow();
        }

         break;

      case FVG_Strategy:
      {
           if (AncienneStrategie != FVG_Strategy)
         {
         DeleteSubWindowIfExists();
         SupprimerObjetsSR();
         SupprimerObjetsMM();
         SupprimerObjetsPP();
         AncienneStrategie = PP_RSI_MA_Strategy;
         }

         DisplayFVGsignal(); // Affiche le FVG
         
         lastBarTime = currentBarTime;
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
      case PP_RSI_MA_Strategy:
         if (AncienneStrategie != PP_RSI_MA_Strategy)
         {
         DeleteSubWindowIfExists();
         AncienneStrategie = PP_RSI_MA_Strategy;
         }
         SupprimerObjetsFVG();
         SupprimerObjetsMM();
         SupprimerObjetsSR();
         DisplayPPRSIMA(_Symbol, 14, 9, 0, MODE_SMA);
         break;
         
      case Support_Resistance:
         {
         SupprimerObjetsMM();
         SupprimerObjetsPP();
         SupprimerObjetsFVG();
         DisplaySRLevels();
         // Supprime la sous-fenêtre si elle existe
         if ((int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) > 0)
         {
             DeleteSubWindowIfExists();
         }
         
         lastBarTime = currentBarTime;
         if (currentBarTime != lastBarTime)
         {
         SupprimerObjetsSR();       // Supprimer anciens SR
         DisplaySRLevels();         // Créer les nouveaux SR
         lastBarTime = currentBarTime; // Mettre à jour la dernière bougie traitée
         }
         }
        break;
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
      CheckForNewSignals(symbol, i);
        
   }

    // Mettre à jour les positions existantes
    UpdateExistingPositions(); // <--- Déplacé ici APRÈS la boucle multi-paires

}

//+------------------------------------------------------------------------------------------------+
//| Fonction pour vérifier si les conditions de marché sont bonnes Weekend spread trade autoriser  |
//+------------------------------------------------------------------------------------------------+
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
//| Fonction pour vérifier si les conditions de marché sont bonnes   |
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
        int valueCount = CalendarValueHistory(values, now - 86400, now + 432000, countries[i].code); // Recherche news sur 5 jours

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
      "Esp35", "Ger40", "Fra40", "UK100" 
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
// Vérifie si un symbole est disponible et synchronisé               |
//+------------------------------------------------------------------+
bool IsSymbolAvailable(string symbol)
{
   if(!SymbolSelect(symbol, true))
      return false;

   // Vérifie que le symbole est bien synchronisé avec le serveur (important pour indicateurs)
   if(!SymbolIsSynchronized(symbol))
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Fonction pour initialiser les handles des indicateurs            |
//+------------------------------------------------------------------+
void InitializeIndicatorHandles()
{
   if (!TradeAllForexPairs && !TradeAllIndices)
   {
      string symbol = Symbol();
      
            // Vérification : est-ce que le symbole est disponible ?
      if (!IsSymbolAvailable(symbol))
      {
         Print("Symbole non disponible : ", symbol);
         return;
      }

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

double volume = ChoixTypeLots();
if (volume <= 0)
{
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
      }
      else
      {
      }
   }
   // Ouvrir la position avec Grid Trading en BUY
   else if (StopLossType == GridTrading)
   {
      if (OpenPositionWithGridTrading(symbol, signal, volume))
      {
      }
      else
      {
      }
   }

}
else if (signal == Vente && trend != TrendHaussiere)
{
   // Ouvrir la position avec Stop Loss Classique
   if (StopLossType == SL_Classique)
   {
      if (OpenPositionWithClassicSL(symbol, signal, volume))
      {
      }
      else
      {
      }
   }
   // Ouvrir la position avec Grid Trading en SELL
   else if (StopLossType == GridTrading)
   {
      if (OpenPositionWithGridTrading(symbol, signal, volume))
      {
      }
      else
      {
      }
   }
   // Ajoutez d'autres types de Stop Loss ici si nécessaire
}
else
{
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

      case PP_RSI_MA_Strategy:
         return CheckPPRSIMASignal(symbol);
      
      case Support_Resistance:
         return CheckSRSignal(symbol);

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
   //datetime currentBarTime = iTime(symbol, _Period, 0);
   datetime currentBarTime = TimeCurrent() - (TimeCurrent() % _Period * 60);
   
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
//| Fonction pour vérifier le signal S/R                             |
//+------------------------------------------------------------------+
// fractal M1 M5
// zigzag H1 H4 D
CrossSignal CheckSRSignal(string symbol)
{
    // Réinitialiser les niveaux
    ArrayResize(levelsUp, 0);
    ArrayResize(levelsDown, 0);

    // --- Paramètres de détection ---
    int totalBars = Bars(symbol, PERIOD_CURRENT);
    int bougieMax = BougieSRaanalyser;

    if (bougieMax > totalBars)
        bougieMax = totalBars;
    if (bougieMax < 1000)
        bougieMax = 1000;

    // --- Détection des niveaux SR selon la méthode choisie ---
    switch (Method_detection_SR)
    {
        case Fractal:
            DetectFractalLevels(symbol, bougieMax, NbcontactSR); // Détection Fractals
            break;

        case ZigZag:
            DetectZigZagLevels(symbol, 12, 5, 3, bougieMax, NbcontactSR); // Détection ZigZag
            break;
    }

    // --- Vérification sur la DERNIÈRE bougie clôturée ---
    const int index = 1; // bougie précédente
    double high  = iHigh(symbol, PERIOD_CURRENT, index);
    double low   = iLow(symbol, PERIOD_CURRENT, index);
    double close = iClose(symbol, PERIOD_CURRENT, index);

    const double tolerance = _Point * 5;

    // --- Vérification des supports ---
    for (int i = 0; i < ArraySize(levelsDown); i++)
    {
        double support = levelsDown[i];

        bool touch = (low >= support - tolerance && low <= support + tolerance);
        bool clotureAuDessus = (close > support + _Point * 2);

        if (touch && clotureAuDessus)
        {
            Print("📈 Signal détecté : Achat (support touché à ", DoubleToString(support, _Digits), ")");
            return Achat;
        }
    }

    // --- Vérification des résistances ---
    for (int i = 0; i < ArraySize(levelsUp); i++)
    {
        double resistance = levelsUp[i];

        bool touch = (high >= resistance - tolerance && high <= resistance + tolerance);
        bool clotureEnDessous = (close < resistance - _Point * 2);

        if (touch && clotureEnDessous)
        {
            Print("📉 Signal détecté : Vente (résistance touchée à ", DoubleToString(resistance, _Digits), ")");
            return Vente;
        }
    }

    return Aucun;
}

//+------------------------------------------------------------------+
//| Fonction pour afficher les S/R                                   |
//+------------------------------------------------------------------+
void DisplaySRLevels()
{
    int totalBars = Bars(_Symbol, _Period);

    // Vérifier si les paramètres ont changé
    if (CheckParameterChange())
    {
        Print("🔄 Modification des paramètres détectée, suppression des anciens niveaux SR...");
        SupprimerObjetsSR();
        lastBougieSRaanalyserEffective = 0;
    }

    // Calculer le nombre effectif de bougies à analyser
    int bougieSRaanalyserEffective = BougieSRaanalyser;

    if (bougieSRaanalyserEffective < 1000)
        bougieSRaanalyserEffective = 1000;
    else if (bougieSRaanalyserEffective > totalBars)
        bougieSRaanalyserEffective = totalBars;

    // Recalculer les niveaux si le nombre de bougies a changé
    if (bougieSRaanalyserEffective != lastBougieSRaanalyserEffective)
    {
        SupprimerObjetsSR();
        lastBougieSRaanalyserEffective = bougieSRaanalyserEffective;
    }

    // Si l'affichage est désactivé, on sort
    if (!DisplaySROnChart)
        return;

    // --- Détection des niveaux selon la méthode choisie ---
    switch (Method_detection_SR)
    {
        case Fractal:
            DetectFractalLevels(_Symbol, bougieSRaanalyserEffective, NbcontactSR);
            break;

        case ZigZag:
            DetectZigZagLevels(_Symbol, 12, 5, 3, bougieSRaanalyserEffective, NbcontactSR);
            break;
    }

    // --- Affichage des résistances ---
    for (int i = 0; i < ArraySize(levelsUp); i++)
    {
        string name = "Ligne_R" + IntegerToString(i);
        if (!ObjectCreate(0, name, OBJ_HLINE, 0, 0, levelsUp[i]))
            continue;

        ObjectSetInteger(0, name, OBJPROP_COLOR, couleurSR);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    }

    // --- Affichage des supports ---
    for (int i = 0; i < ArraySize(levelsDown); i++)
    {
        string name = "Ligne_S" + IntegerToString(i);
        if (!ObjectCreate(0, name, OBJ_HLINE, 0, 0, levelsDown[i]))
            continue;

        ObjectSetInteger(0, name, OBJPROP_COLOR, couleurSR);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    }
}

//+------------------------------------------------------------------+
//| Fonction pour détecter les SR avec les Zigzag                    |
//+------------------------------------------------------------------+
void DetectZigZagLevels(string symbol, int depth, int deviation, int backstep, int barsToCheck, int nbContacts)
{
    ArrayResize(levelsUp, 0);
    ArrayResize(levelsDown, 0);

    int handle = iCustom(symbol, PERIOD_CURRENT, "Examples\\ZigZag", depth, deviation, backstep);
    if (handle == INVALID_HANDLE)
    {
        Print("Erreur : handle ZigZag invalide");
        return;
    }

    double zigzagBuffer[];
    ArraySetAsSeries(zigzagBuffer, true);

    if (CopyBuffer(handle, 0, 0, barsToCheck, zigzagBuffer) <= 0)
    {
        Print("Erreur : impossible de copier les données ZigZag");
        return;
    }

    const double tolerance = _Point * 10;
    double niveauxTemp[1000];
    int nbTouches[1000];
    int count = 0;

    // Étape 1 : Regrouper les niveaux ZigZag similaires
    for (int i = 0; i < barsToCheck; i++)
    {
        double zz = zigzagBuffer[i];
        if (zz == 0.0 || zz == EMPTY_VALUE)
            continue;

        bool found = false;
        for (int j = 0; j < count; j++)
        {
            if (MathAbs(niveauxTemp[j] - zz) < tolerance)
            {
                nbTouches[j]++;
                found = true;
                break;
            }
        }

        if (!found)
        {
            niveauxTemp[count] = zz;
            nbTouches[count] = 1;
            count++;
        }
    }

    double price = SymbolInfoDouble(symbol, SYMBOL_BID);

    // Étape 2 : Classer les niveaux selon leur position par rapport au prix
    for (int i = 0; i < count; i++)
    {
        if (nbTouches[i] >= nbContacts)
        {
            if (niveauxTemp[i] > price)
            {
                // Résistance
                ArrayResize(levelsUp, ArraySize(levelsUp) + 1);
                levelsUp[ArraySize(levelsUp) - 1] = niveauxTemp[i];
            }
            else if (niveauxTemp[i] < price)
            {
                // Support
                ArrayResize(levelsDown, ArraySize(levelsDown) + 1);
                levelsDown[ArraySize(levelsDown) - 1] = niveauxTemp[i];
            }
        }
    }

    IndicatorRelease(handle);
}

//+------------------------------------------------------------------+
//| Fonction pour détecter les SR avec les fractals                  |
//+------------------------------------------------------------------+
void DetectFractalLevels(string symbol, int barsToCheck, int nbContacts)
{
    ArrayResize(levelsUp, 0);
    ArrayResize(levelsDown, 0);

    int handle = iFractals(symbol, PERIOD_CURRENT);
    if (handle == INVALID_HANDLE)
    {
        Print("Erreur : handle Fractals invalide");
        return;
    }

    double fractalUp[], fractalDown[];
    ArraySetAsSeries(fractalUp, true);
    ArraySetAsSeries(fractalDown, true);

    if (CopyBuffer(handle, 0, 0, barsToCheck, fractalUp) <= 0 ||
        CopyBuffer(handle, 1, 0, barsToCheck, fractalDown) <= 0)
    {
        Print("Erreur : impossible de copier les données Fractals");
        return;
    }

    const double tolerance = _Point * 10;
    double niveauxTemp[1000];
    int nbTouches[1000];
    int count = 0;

    for (int i = 0; i < barsToCheck; i++)
    {
        double niveau = 0;

        if (fractalUp[i] != 0.0 && fractalUp[i] != EMPTY_VALUE)
            niveau = fractalUp[i];
        else if (fractalDown[i] != 0.0 && fractalDown[i] != EMPTY_VALUE)
            niveau = fractalDown[i];

        if (niveau == 0)
            continue;

        bool found = false;
        for (int j = 0; j < count; j++)
        {
            if (MathAbs(niveauxTemp[j] - niveau) < tolerance)
            {
                nbTouches[j]++;
                found = true;
                break;
            }
        }

        if (!found)
        {
            niveauxTemp[count] = niveau;
            nbTouches[count] = 1;
            count++;
        }
    }

    double price = SymbolInfoDouble(symbol, SYMBOL_BID);

    for (int i = 0; i < count; i++)
    {
        if (nbTouches[i] >= nbContacts)
        {
            if (niveauxTemp[i] > price)
            {
                // Résistance
                ArrayResize(levelsUp, ArraySize(levelsUp) + 1);
                levelsUp[ArraySize(levelsUp) - 1] = niveauxTemp[i];
            }
            else if (niveauxTemp[i] < price)
            {
                // Support
                ArrayResize(levelsDown, ArraySize(levelsDown) + 1);
                levelsDown[ArraySize(levelsDown) - 1] = niveauxTemp[i];
            }
        }
    }

    IndicatorRelease(handle);
}

//+------------------------------------------------------------------+
//| Fonction pour afficher les PP, supports, résistances, RSI et MA  |
//+------------------------------------------------------------------+
void DisplayPPRSIMA(string symbol, int rsiPeriod = 14, int maPeriod = 9, int maShift = 0, ENUM_MA_METHOD maMethod = MODE_SMA)
{
   // Variables pour stocker les données
   double RSIBuffer[];
   double MABuffer[];
   ArraySetAsSeries(RSIBuffer, true);
   ArraySetAsSeries(MABuffer, true);

   // Vérifier si une nouvelle bougie DAILY s'est formée (pour recalculer les niveaux PP, R, S)
   static datetime lastCheckedDailyTime = 0;
   datetime currentDailyBarTime = iTime(symbol, PERIOD_D1, 0);
   if (currentDailyBarTime != lastCheckedDailyTime)
   {
      // Mettre à jour le temps de la dernière vérification
      lastCheckedDailyTime = currentDailyBarTime;

      // Calculer les niveaux PP, supports, et résistances en utilisant les données de la bougie Daily précédente
      double highDaily = iHigh(symbol, PERIOD_D1, 1);
      double lowDaily = iLow(symbol, PERIOD_D1, 1);
      double closeDaily = iClose(symbol, PERIOD_D1, 1);

      // Calcul du PP (méthode classique)
      g_PPLevel = (highDaily + lowDaily + closeDaily) / 3.0;

      // Calcul des résistances (R1, R2, R3)
      g_R1Level = (2 * g_PPLevel) - lowDaily;
      g_R2Level = g_PPLevel + (highDaily - lowDaily);
      g_R3Level = highDaily + 2 * (g_PPLevel - lowDaily);

      // Calcul des supports (S1, S2, S3)
      g_S1Level = (2 * g_PPLevel) - highDaily;
      g_S2Level = g_PPLevel - (highDaily - lowDaily);
      g_S3Level = lowDaily - 2 * (highDaily - g_PPLevel);

      // Débogage : Afficher les niveaux calculés
      //Print("Niveaux Daily - PP: ", DoubleToString(g_PPLevel, 5),", R1: ", DoubleToString(g_R1Level, 5), ", R2: ", DoubleToString(g_R2Level, 5), ", R3: ", DoubleToString(g_R3Level, 5), ", S1: ", DoubleToString(g_S1Level, 5), ", S2: ", DoubleToString(g_S2Level, 5), ", S3: ", DoubleToString(g_S3Level, 5));
   }
   
   // Affichage des Points Pivots (PP), supports et résistances sur le graphique principal
      // Utiliser les niveaux stockés dans les variables globales
      CreatePivotLine("PP_Line", g_PPLevel, clrBlue, STYLE_SOLID, "Point Pivot");
      CreatePivotLine("R1_Line", g_R1Level, clrRed, STYLE_DASH, "Résistance 1");
      CreatePivotLine("R2_Line", g_R2Level, clrRed, STYLE_DASH, "Résistance 2");
      CreatePivotLine("R3_Line", g_R3Level, clrRed, STYLE_DASH, "Résistance 3");
      CreatePivotLine("S1_Line", g_S1Level, clrYellow, STYLE_DASH, "Support 1");
      CreatePivotLine("S2_Line", g_S2Level, clrYellow, STYLE_DASH, "Support 2");
      CreatePivotLine("S3_Line", g_S3Level, clrYellow, STYLE_DASH, "Support 3");
      
   // Mettre à jour la position temporelle des lignes uniquement à chaque nouvelle bougie du timeframe actuel
   static datetime lastCheckedTime = 0;
   datetime currentBarTime = iTime(symbol, _Period, 0);
   if (currentBarTime != lastCheckedTime)
   {
      // Mettre à jour le temps de la dernière vérification
      lastCheckedTime = currentBarTime;

      // Supprimer les anciennes lignes PP, supports et résistances pour éviter les doublons
      SupprimerObjetsPP();      
   }

   // Vérifier si le handle RSI n'a pas encore été créé
   if (RSIHandle == INVALID_HANDLE)
   {
      RSIHandle = iRSI(symbol, _Period, rsiPeriod, PRICE_CLOSE); // Utilisation de la variable globale
      if (RSIHandle == INVALID_HANDLE)
      {
         Print("Erreur: Impossible de créer le handle RSI pour ", symbol, ". Code d'erreur : ", GetLastError());
         return;
      }
      else
      {
         //Print("Handle RSI créé avec succès pour ", symbol, ". Handle : ", RSIHandle);
      }
   }

   // Obtenir le handle pour la MA
   int MAHandle = iMA(symbol, _Period, maPeriod, maShift, maMethod, RSIHandle);
   if (MAHandle == INVALID_HANDLE)
   {
      Print("Erreur: Impossible de créer le handle MA pour ", symbol, ". Code d'erreur : ", GetLastError());
      return;
   }
   else
   {
      //Print("Handle MA créé avec succès pour ", symbol, ". Handle : ", MAHandle);
   }

   // Copier les données du RSI et de la MA pour la bougie actuelle
   if (CopyBuffer(RSIHandle, 0, 0, 1, RSIBuffer) <= 0)
   {
      Print("Erreur lors de la copie des données RSI pour ", symbol, ". Code d'erreur : ", GetLastError());
      return;
   }

   if (CopyBuffer(MAHandle, 0, 0, 1, MABuffer) <= 0)
   {
      Print("Erreur lors de la copie des données MA pour ", symbol, ". Code d'erreur : ", GetLastError());
      return;
   }

   // Valeurs du RSI et de la MA
   double rsi = RSIBuffer[0];
   double ma = MABuffer[0];
   //Print("RSI actuel : ", DoubleToString(rsi, 2), ", MA actuelle : ", DoubleToString(ma, 2));

   // --- Affichage du RSI et de la MA dans une sous-fenêtre ---
   // Vérifier si une sous-fenêtre existe, sinon en créer une
   if ((int)ChartGetInteger(0, CHART_WINDOWS_TOTAL) <= 1)
   {
      // Ajouter l'indicateur RSI pour créer une sous-fenêtre
      // Vérifier si l'indicateur RSI est déjà ajouté à la sous-fenêtre
      string rsiIndicatorName = "RSI_" + symbol + "_" + IntegerToString(_Period);
      if (ChartIndicatorGet(0, 1, rsiIndicatorName) == INVALID_HANDLE)
      {
         if (!ChartIndicatorAdd(0, 1, RSIHandle))
         {
            Print("Erreur lors de l'ajout de l'indicateur RSI à la sous-fenêtre. Code d'erreur : ", GetLastError());
            return;
         }
         else
         {
            //Print("Indicateur RSI ajouté à la sous-fenêtre 1 avec succès.");
         }
               if (!ChartIndicatorAdd(0, 1, MAHandle))
      {
         Print("Erreur lors de l'ajout de l'indicateur MA à la sous-fenêtre. Code d'erreur : ", GetLastError());
         return;
      }
      else
      {
         //Print("Indicateur MA ajouté à la sous-fenêtre 1 avec succès pour ", symbol);
      }
      }
   }

   

   // --- Dessiner les lignes de surachat et survente pour le RSI ---
   // Ligne de surachat (70)
   string overboughtLine = "RSI_Overbought_Line_" + symbol;
   if (ObjectFind(0, overboughtLine) < 0) // Vérifier si l'objet n'existe pas
   {
      if (!ObjectCreate(0, overboughtLine, OBJ_HLINE, 1, 0, 70))
      {
         Print("Erreur lors de la création de la ligne de surachat pour ", symbol, ". Code d'erreur : ", GetLastError());
      }
      else
      {
         ObjectSetInteger(0, overboughtLine, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, overboughtLine, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, overboughtLine, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, overboughtLine, OBJPROP_BACK, false); // Forcer la ligne à l'arrière-plan
         ObjectSetInteger(0, overboughtLine, OBJPROP_HIDDEN, false); // S'assurer que la ligne est visible
         //Print("Ligne de surachat (70) créée avec succès pour ", symbol);
      }
   }

   // Ligne de survente (30)
   string oversoldLine = "RSI_Oversold_Line_" + symbol;
   if (ObjectFind(0, oversoldLine) < 0) // Vérifier si l'objet n'existe pas
   {
      if (!ObjectCreate(0, oversoldLine, OBJ_HLINE, 1, 0, 30))
      {
         Print("Erreur lors de la création de la ligne de survente pour ", symbol, ". Code d'erreur : ", GetLastError());
      }
      else
      {
         ObjectSetInteger(0, oversoldLine, OBJPROP_COLOR, clrRed);
         ObjectSetInteger(0, oversoldLine, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, oversoldLine, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, oversoldLine, OBJPROP_BACK, false); // Forcer la ligne à l'arrière-plan
         ObjectSetInteger(0, oversoldLine, OBJPROP_HIDDEN, false); // S'assurer que la ligne est visible
         //Print("Ligne de survente (30) créée avec succès pour ", symbol);
      }
   }

   // --- Libérer le handle MA (mais pas RSIHandle, car il est global) ---
   IndicatorRelease(MAHandle);

   // Rafraîchir le graphique pour s'assurer que les modifications sont visibles
   ChartRedraw(0);
   //Print("Affichage des PP, supports, résistances, RSI et MA terminé pour ", symbol);
}
//+------------------------------------------------------------------+
//| Fonction pour créer une ligne de tendance horizontale sur le graphique |
//+------------------------------------------------------------------+
void CreatePivotLine(string name, double price, color lineColor, ENUM_LINE_STYLE style, string description)
{
   // Vérifier si l'objet existe déjà
   if (ObjectFind(0, name) >= 0)
   {
      // Si l'objet existe, le supprimer pour éviter les problèmes
      ObjectDelete(0, name);
      //Print("Ligne ", description, " supprimée pour recréation");
   }
   
   // Déterminer les dates de début et de fin pour la ligne
   datetime time1 = iTime(_Symbol, _Period, 1000); // 1000 bougies en arrière
   datetime time2 = iTime(_Symbol, _Period, 0) + PeriodSeconds(_Period) * 10; // Bougie actuelle + 10 bougies dans le futur
   
   // Si la fonction iTime échoue ou si nous n'avons pas assez de bougies, ajuster time1
   if (time1 == 0)
   {
      // Si moins de 1000 bougies sont disponibles, utiliser la première bougie du graphique
      time1 = iTime(_Symbol, _Period, iBars(_Symbol, _Period) - 1);
      Print("Attention : Moins de 1000 bougies disponibles. Début ajusté à la première bougie.");
   }
   
   // Créer un nouvel objet de type TREND (ligne horizontale entre time1 et time2)
   if (!ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price))
   {
      Print("Erreur lors de la création de la ligne ", name, ". Code d'erreur : ", GetLastError());
      return;
   }
   else
   {
      //Print("Ligne ", description, " créée avec succès : ", name, " à la valeur ", DoubleToString(price, 5));
   }
   
   // Configurer les propriétés de l'objet
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2); // Augmenté à 2 pour meilleure visibilité
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); // S'assurer que la ligne est visible
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true); // Permettre la sélection de la ligne
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false); // Ne pas sélectionner par défaut
   ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); // Visible sur tous les timeframes
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100); // Priorité d'affichage élevée
   ObjectSetString(0, name, OBJPROP_TOOLTIP, description + " (" + DoubleToString(price, 5) + ")");
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false); // Ne pas étendre la ligne à droite au-delà de time2
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false); // Ne pas étendre la ligne à gauche au-delà de time1

   // Rafraîchir le graphique pour s'assurer que les modifications sont visibles
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier le signal PP                             |
//+------------------------------------------------------------------+

CrossSignal CheckPPRSIMASignal(string symbol,
int rsiPeriod = 14,
int maPeriod = 9,
int maShift = 0,
ENUM_MA_METHOD maMethod = MODE_SMA,
int index = 0)
{
static datetime lastCheckedTime = 0;
datetime currentBarTime = iTime(symbol, _Period, 0);

// Vérifier si nous sommes sur une nouvelle bougie
if (currentBarTime == lastCheckedTime)
{
return Aucun; // On ne fait rien tant qu'on n'est pas sur une nouvelle bougie
}

// Mettre à jour le temps de la dernière vérification
lastCheckedTime = currentBarTime;

// Variables statiques pour suivre l'état du RSI
static bool rsiWasOverbought = false;
static bool rsiWasOversold = false;
static bool signalSentAfterOverbought = false;
static bool signalSentAfterOversold = false;

// Calculer les niveaux PP, supports, et résistances (comme dans DisplayPPRSIMA)
double highDaily = iHigh(symbol, PERIOD_D1, 1);
double lowDaily = iLow(symbol, PERIOD_D1, 1);
double closeDaily = iClose(symbol, PERIOD_D1, 1);

double pp = (highDaily + lowDaily + closeDaily) / 3.0;
double r1 = (2 * pp) - lowDaily;
double r2 = pp + (highDaily - lowDaily);
double r3 = highDaily + 2 * (pp - lowDaily);
double s1 = (2 * pp) - highDaily;
double s2 = pp - (highDaily - lowDaily);
double s3 = lowDaily - 2 * (highDaily - pp);

// Récupérer les données de la bougie précédente (index 1)
double high = iHigh(symbol, _Period, 1);
double low = iLow(symbol, _Period, 1);
double close = iClose(symbol, _Period, 1);

// Selon la stratégie choisie (PP_TradeAction)
if (PP_TradeAction == PPRebond)
{
// Stratégie PP Rebond (inchangé - je le laisse pour la complétude)
// Résistances (R1, R2, R3) : Touche/Traverse et clôture en dessous -> Vente
if ((high >= r1 && close < r1) || (high >= r2 && close < r2) || (high >= r3 && close < r3))
{
return Vente;
}

  // Supports (S1, S2, S3) : Touche/Traverse et clôture au-dessus -> Achat
  if ((low <= s1 && close > s1) || (low <= s2 && close > s2) || (low <= s3 && close > s3))
  {
     return Achat;
  }

}
else if (PP_TradeAction == PPRSIMAoverhold)
{
// Stratégie PPRSIMA Overhold
// Obtenir les données RSI et MA
double rsi[];
double ma[];
ArraySetAsSeries(rsi, true);
ArraySetAsSeries(ma, true);

  // Obtenir le handle RSI
  int rsiHandle = iRSI(symbol, _Period, rsiPeriod, PRICE_CLOSE);
  if (rsiHandle == INVALID_HANDLE)
  {
     Print("Erreur: Impossible de créer le handle RSI pour ", symbol);
     return Aucun;
  }

  // Obtenir le handle MA appliqué au RSI
  int maHandle = iMA(symbol, _Period, maPeriod, maShift, maMethod, PRICE_CLOSE); // Appliquer la MA au prix, PAS au RSI
    if (maHandle == INVALID_HANDLE)
    {
        Print("Erreur: Impossible de créer le handle MA pour ", symbol);
        IndicatorRelease(rsiHandle); // Libérer le handle RSI
        return Aucun;
    }

  // Copier les données RSI et MA des deux dernières bougies (index 1 et 2)
  if (CopyBuffer(rsiHandle, 0, 1, 2, rsi) <= 0 || CopyBuffer(maHandle, 0, 1, 2, ma) <= 0)
  {
     Print("Erreur lors de la copie des données RSI ou MA pour ", symbol);
     IndicatorRelease(rsiHandle);  // Libérer les handles
     IndicatorRelease(maHandle);
     return Aucun;
  }
  
  // Obtenir la MA du prix
  double maPrice[];
  ArraySetAsSeries(maPrice, true);
  int maPriceHandle = iMA(symbol, _Period, maPeriod, maShift, maMethod, PRICE_CLOSE);
  if(CopyBuffer(maPriceHandle, 0, 1, 2, maPrice) <= 0)
  {
      Print("Erreur lors de la copie des données de la MA du prix");
      IndicatorRelease(rsiHandle);
      IndicatorRelease(maHandle);
      IndicatorRelease(maPriceHandle);
      return Aucun;
  }
  IndicatorRelease(maPriceHandle);

  // Vérifier les conditions de surachat/survente et croisement RSI/MA
  double rsiCurrent = rsi[0]; // RSI de la bougie précédente (index 1)
  double rsiPrevious = rsi[1]; // RSI de l'avant-dernière bougie (index 2)
  double maCurrent = maPrice[0]; // MA du prix de la bougie précédente
  double maPrevious = maPrice[1]; // MA du prix de l'avant-dernière bougie

    // Mise à jour de l'état de surachat/survente
    if (rsiCurrent > 70) {
        rsiWasOverbought = true;
        signalSentAfterOverbought = false; // Réinitialiser le signal après retour en zone
    } else if (rsiCurrent < 30) {
        rsiWasOversold = true;
        signalSentAfterOversold = false; // Réinitialiser le signal après retour en zone
    }


  // Signal de Vente : RSI a été en surachat, croise MA à la baisse, et prix > PP
    if (rsiWasOverbought && !signalSentAfterOverbought && rsiCurrent < maCurrent && rsiPrevious > maPrevious && close > pp)
    {
        signalSentAfterOverbought = true; // Marquer qu'un signal a été envoyé
        rsiWasOverbought = false; // optionnel
        return Vente;
    }

    // Signal d'Achat : RSI a été en survente, croise MA à la hausse, et prix < PP
    if (rsiWasOversold && !signalSentAfterOversold && rsiCurrent > maCurrent && rsiPrevious < maPrevious && close < pp)
    {
        signalSentAfterOversold = true; // Marquer qu'un signal a été envoyé
        rsiWasOversold = false; // optionnel
        return Achat;
    }

  // Libérer les handles
  IndicatorRelease(rsiHandle);
  IndicatorRelease(maHandle);

}

return Aucun;
}

//+------------------------------------------------------------------+
//| Fonction pour vérifier si les objets PP existent                 |
//+------------------------------------------------------------------+
void CheckPPObjects()
{
   string ppObjects[] = {"PP_Object", "R1_Object", "R2_Object", "R3_Object", "S1_Object", "S2_Object", "S3_Object"};
   
   for(int i=0; i<ArraySize(ppObjects); i++)
   {
      if(ObjectFind(0, ppObjects[i]) >= 0)
      {
         // L'objet existe
         double price = ObjectGetDouble(0, ppObjects[i], OBJPROP_PRICE, 0);
         Print("Vérification: ", ppObjects[i], " existe avec prix = ", DoubleToString(price, 5));
      }
      else
      {
         // L'objet n'existe pas
         Print("Vérification: ", ppObjects[i], " N'EXISTE PAS!");
      }
   }
}

//+------------------------------------------------------------------+
//| Fonction pour calculer et afficher les MM de signal |
//+------------------------------------------------------------------+
void DisplayMAsignal()
{
int BougieMMaanalyserEffective = BougieMMaanalyser; // Copie de la valeur d'entrée

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
// Libération des handles
IndicatorRelease(ma1Handle);
IndicatorRelease(ma2Handle);
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
// Fonction pour calculer le volume total des positions ouvertes     |
// (avec ou sans filtre par Magic Number)                           |
//+------------------------------------------------------------------+
double CountTotalVolume()
{
    double totalVolume = 0.0;

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) continue; // Ignorer les tickets invalides

        // Si UseMagicNumber est true, on vérifie le Magic Number
        if (UseMagicNumber)
        {
            long positionMagic = PositionGetInteger(POSITION_MAGIC);
            if (positionMagic == MagicNumber)
            {
                totalVolume += PositionGetDouble(POSITION_VOLUME); // Ajouter le volume de la position
            }
        }
        else
        {
            // Si UseMagicNumber est false, on compte le volume de toutes les positions
            totalVolume += PositionGetDouble(POSITION_VOLUME);
        }
    }

    return (totalVolume);
}

//+-------------------------------------------------------------------------+
// Fonction pour compter toutes les positions (avec ou sans filtre magic)   |
//+-------------------------------------------------------------------------+
int CountToutesPositions()
{
   int total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) > 0)
      {
         // Si UseMagicNumber est true, on vérifie le magic number
         if(UseMagicNumber)
         {
            long positionMagic = PositionGetInteger(POSITION_MAGIC);
            if(positionMagic == MagicNumber)
            {
               total++;
            }
         }
         else
         {
            // Si UseMagicNumber est false, on compte toutes les positions
            total++;
         }
      }
   }
   if(UseMagicNumber)
   {
   }
   else
   {
   }
   return total;
}

//+------------------------------------------------------------------+
//| Fonction de comptage des positions sur le compte entier          |
//+------------------------------------------------------------------+
int CountPositions()
{
   int count = 0; // Initialiser le compteur à 0

   // Parcourir toutes les positions ouvertes en ordre décroissant
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      // Sélectionner la position par son ticket
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) // Vérifier si la sélection a échoué
      {
         continue; // Passer à la position suivante
      }

      // Incrémenter le compteur pour chaque position ouverte, quel que soit le symbole
      count++;
   }

   // Afficher le nombre total de positions pour le débogage
   return count; // Retourner le nombre total de positions sur le compte
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
                // Logique Stop Loss classique avec Magic Number
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

                // Calcul du SL et TP
                double slPips = NormalizeDouble(StopLossCurrency / (lotSize * pointValue), digits);
                double tpPips = NormalizeDouble(TakeProfitCurrency / (lotSize * pointValue), digits);

                double slPrice = (type == POSITION_TYPE_BUY) ? NormalizeDouble(openPrice - slPips * point, digits)
                                                             : NormalizeDouble(openPrice + slPips * point, digits);
                double tpPrice = (type == POSITION_TYPE_BUY) ? NormalizeDouble(openPrice + tpPips * point, digits)
                                                             : NormalizeDouble(openPrice - tpPips * point, digits);

                if (slPrice != sl || tpPrice != tp)
                {
                     bool modified = trade.PositionModify(ticket, slPrice, tpPrice);
                     if (modified)
                     {
                        Print("Position modifiée: SL=", slPrice, ", TP=", tpPrice, " (ticket=", ticket, ")");
                     }
                     else
                     {
                          Print("Erreur modification de la position : ", trade.ResultRetcodeDescription());
                     }
                }
            }
            else if (!UseMagicNumber)
            {
                // Logique Stop Loss classique pour toutes les positions
                double pointValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
                int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

                double slPips = NormalizeDouble(StopLossCurrency / (lotSize * pointValue), digits);
                double tpPips = NormalizeDouble(TakeProfitCurrency / (lotSize * pointValue), digits);

                double slPrice = (type == POSITION_TYPE_BUY) ? NormalizeDouble(openPrice - slPips * point, digits)
                                                             : NormalizeDouble(openPrice + slPips * point, digits);
                double tpPrice = (type == POSITION_TYPE_BUY) ? NormalizeDouble(openPrice + tpPips * point, digits)
                                                             : NormalizeDouble(openPrice - tpPips * point, digits);

                if (slPrice != sl || tpPrice != tp)
                {
                     bool modified = trade.PositionModify(ticket, slPrice, tpPrice);
                     if (modified)
                     {
                        Print("Position modifiée: SL=", slPrice, ", TP=", tpPrice, " (ticket=", ticket, ")");
                     }
                     else
                     {
                          Print("Erreur modification de la position : ", trade.ResultRetcodeDescription());
                     }
                }
            }
            break;

        case GridTrading:
            if (UseMagicNumber == true && positionMagicNumber == MagicNumber)
            {
               // Logique Grid Trading avec Magic Number
               double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
               int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

               // Calculer le breakeven (BE) pour toutes les positions ouvertes
               double breakevenPrice = CalculateBreakevenPrice(symbol, (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
               if (breakevenPrice == 0.0)
               {
                  Print("Erreur: Impossible de calculer le breakeven pour ", symbol, ", Ticket: ", ticket);
                  continue;
               }

            
            }
            else if (!UseMagicNumber)
            {
               // Logique Grid Trading pour toutes les positions
               double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
               int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

               // Calculer le breakeven (BE) pour toutes les positions ouvertes
               double breakevenPrice = CalculateBreakevenPrice(symbol, (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
               if (breakevenPrice == 0.0)
               {
                  continue;
               }

                             
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
    IndicatorRelease(ichimokuHandle);
}

//+------------------------------------------------------------------+
//| Fonction pour supprimer les anciens objets PP, supports et résistances |
//+------------------------------------------------------------------+
void SupprimerObjetsPP()
{
   int deletedCount = 0;
   
   // Supprimer les objets PP (préfixe "PP_Line_")
   deletedCount += ObjectsDeleteAll(0, "PP_Line");
   
   // Supprimer les objets de résistance (préfixe "R")
   int resistCount = ObjectsDeleteAll(0, "R");
   deletedCount += resistCount;
   
   // Supprimer les objets de support (préfixe "S")
   int supportCount = ObjectsDeleteAll(0, "S");
   deletedCount += supportCount;
   
   // Message final en fonction du nombre total d'objets supprimés
   if (deletedCount > 0)
   {
      //Print("Supprimé ", deletedCount, " objets au total.");
   }
   else
   {
      //Print("Aucun objet PP, S, ou R trouvé à supprimer.");
   }
}

//+------------------------------------------------------------------+
//| Fonction pour supprimer les objets de l'Ichimoku                 |
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
//| Fonction pour supprimer les objets S/R                           |
//+------------------------------------------------------------------+
void SupprimerObjetsSR()
{
    for (int i = ObjectsTotal(0) - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if (StringFind(name, "Ligne_") == 0)
            ObjectDelete(0, name);
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
      lotSize = ChoixTypeLots(); // Utiliser directement la taille fixe configurée
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

                       // Vérifier le nombre de positions ouvertes et le total des lots pour le symbole actif
                       string activeSymbol = Symbol();
                       int positionCount = 0;
                       double totalLots = 0.0;

                       // Parcourir toutes les positions ouvertes pour compter celles du symbole actif et calculer les lots
                       for (int i = PositionsTotal() - 1; i >= 0; i--)
                       {
                          ulong ticket = PositionGetTicket(i);
                          if (ticket == 0) continue;
                          string posSymbol = PositionGetString(POSITION_SYMBOL);

                          if (posSymbol == activeSymbol)
                          {
                             positionCount++;
                             totalLots += PositionGetDouble(POSITION_VOLUME);
                          }
                       }
    ArrayResize(lines, lineIndex + 1);
    if (positionCount == 0)
    {
    // Aucune position ouverte sur le symbole actif : valeur du point pour 0.01 lot
    lines[lineIndex++] = StringFormat("Solde : %.2f || Valeur du point : %.4f",
                                    AccountInfoDouble(ACCOUNT_EQUITY),
                                    SymbolInfoDouble(activeSymbol, SYMBOL_TRADE_TICK_VALUE) / 100);
    }
    else
    {
   // Une ou plusieurs positions ouvertes sur le symbole actif : valeur du point ajustée pour le total des lots
   lines[lineIndex++] = StringFormat("Solde : %.2f || Valeur du point : %.4f",
                                    AccountInfoDouble(ACCOUNT_EQUITY),
                                    (SymbolInfoDouble(activeSymbol, SYMBOL_TRADE_TICK_VALUE) / 100) * totalLots);
    }
                                 
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
    lines[lineIndex++] = StringFormat("Marge utilisée : %.2f || Marge restante : %.2f" , AccountInfoDouble(ACCOUNT_MARGIN), AccountInfoDouble(ACCOUNT_MARGIN_FREE));

    int totalPositions = CountPositions();
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
            string status = (StopLossType == GridTrading) ? "True" : "False";
            string maxInfo;
            if (Risque_Grid == Lots_Grid) {
            maxInfo = StringFormat(" Max: POS: 0 || Lots:%.2f", GridMaxlots);
            } else {
            maxInfo = StringFormat(" Max: POS:%d || Lots: 0", GridMaxOrders);
            }
            lines[lineIndex++] = StringFormat("Grid trading : (%s)%s", status, maxInfo);
            
            //SL suiveur non déclencher attente seuil de declenchement            
            if (!seuil_declenche_actif)
            {
                 // preparation variable pour calcul des niveaux de placement du SLintial et le niveaux de declenchement
                 string symbol = PositionGetString(POSITION_SYMBOL);
                 ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                 bool isBuy = (posType == POSITION_TYPE_BUY);
                 // Conversion swap négatif en points
                 int swapPoints = 0;
                 double swapAmount = PositionGetDouble(POSITION_SWAP);
                 if(swapAmount < 0)
                 {
                     swapPoints = ConvertCurrencyToPoints(symbol, MathAbs(swapAmount), lotSize);
                 }
         
                 double triggerDistance;
                 double breathingRoom;
                 double breathingRoomSL;   
                 double trailingSLDistance;
                 double currentSL = PositionGetDouble(POSITION_SL);
                 int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
                 switch(digits)
                 {
                 case 5:
                    triggerDistance    = InpSeuilDeclenchement5D;
                    breathingRoom      = InpRespiration5D;
                    breathingRoomSL    = InpRespirationSL5D;
                    trailingSLDistance = InpSLsuiveur5D;
                    break;
            
                 case 4:
                    triggerDistance    = InpSeuilDeclenchement4D;
                    breathingRoom      = InpRespiration4D;
                    breathingRoomSL    = InpRespirationSL4D;
                    trailingSLDistance = InpSLsuiveur4D;
                    break;
            
                 case 3:
                    triggerDistance    = InpSeuilDeclenchement3D;
                    breathingRoom      = InpRespiration3D;
                    breathingRoomSL    = InpRespirationSL3D;
                    trailingSLDistance = InpSLsuiveur3D;
                    break;
            
                 case 2:
                    triggerDistance    = InpSeuilDeclenchement2D;
                    breathingRoom      = InpRespiration2D;
                    breathingRoomSL    = InpRespirationSL2D;
                    trailingSLDistance = InpSLsuiveur2D;
                    break;
            
                 default:
                    // Valeurs par défaut ou message d’erreur
                    triggerDistance    = InpSeuilDeclenchement5D;
                    breathingRoom      = InpRespiration5D;
                    breathingRoomSL    = InpRespirationSL5D;
                    trailingSLDistance = InpSLsuiveur5D;
                    Print("Nombre de décimales non géré : ", digits);
                    break;
                 }
                     
                 
                 // Gestion SL Initial (Seuil de déclenchement)
                 if(currentSL == 0.0)
                 {
                 //calcul du BE
                 ENUM_ORDER_TYPE sensLocal = (isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
                 double BEtableau = CalculateBreakevenPrice(symbol, sensLocal);

                 double seuilActivation = isBuy ?
                 BEtableau + triggerDistance + breathingRoom + (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT)) :
                 BEtableau - triggerDistance - breathingRoom - (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT));
         
                 double slInitial = isBuy ?
                 BEtableau + triggerDistance + (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT)) :
                 BEtableau - triggerDistance - (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT));
                 
                 double slactivation = slInitial;
                 double niveauxdeclechement = seuilActivation;
                 
                 // Calcul comme SL classique => prix / points / % / €
                 double slSuiveur = GetCurrentSL(Symbol());
                 double openSuiv  = PositionGetDouble(POSITION_PRICE_OPEN);
                 double lotSuiv   = PositionGetDouble(POSITION_VOLUME);
                 double sPoints   = PointsDifference(Symbol(), BEtableau, slactivation);
                 double sCurr     = ConvertPointsToCurrency(Symbol(), sPoints, lotSuiv);
                 double sPct      = EquityPercentage(sCurr);
            
                 ArrayResize(lines, lineIndex + 1);
                 lines[lineIndex++] = StringFormat("Seuil : %.5f || Réspiration : %.5f" , triggerDistance, breathingRoom);
      
                 if (!slSuiveur)
                 {        
                 ArrayResize(lines, lineIndex + 1);
                 lines[lineIndex++] = StringFormat("déclencher a: %.5f || SL placé a : %.5f", seuilActivation, slInitial);
                     
                 ArrayResize(lines, lineIndex + 1);
                 lines[lineIndex++] = StringFormat("%.0f points || %.2f%% || %.2f%s", sPoints, sPct, sCurr, AccountInfoString(ACCOUNT_CURRENCY));
                 }
                 } // fin if currentsl == 00
                 else
                 {}
            
            // SL suiveur déclenché
            }
           else
            {
          
            ArrayResize(lines, lineIndex + 1);
            lines[lineIndex++] = StringFormat("SL suiveur déclenché à : %.5f", trailingSL);

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
                   lines[lineIndex++] = StringFormat("SL suiveur placé à : %.5f", slSuiveur, AccountInfoString(ACCOUNT_CURRENCY));
                    
                   ArrayResize(lines, lineIndex + 1);
                   lines[lineIndex++] = StringFormat("%.0f points || %.2f%% || %.2f%s", sPoints, sPct, sCurr, AccountInfoString(ACCOUNT_CURRENCY));
               }
               else
               {}
            }
    }
    else
    {
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = StringFormat("Grid trading : (%s)", (StopLossType == GridTrading) ? "True" : "False");
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Seuil de déclenchement : 0.0";

        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "Respiration pour seuil : 0.0";
        
        ArrayResize(lines, lineIndex + 1);
        lines[lineIndex++] = "SL placé à : 0.00000 || 0 points || 0% || 0.00";
    }

    ArrayResize(lines, lineIndex + 1);
    lines[lineIndex++] = "-------------------------------------------";

    //--------------------------------------------------------
    // SECTION 5 : News
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

   double lotSize = ChoixTypeLots(); // Utilisez la taille de lot fixe par défaut

   if (StopLossType == SL_Classique)
   {
      // Convertir le SL en devise
      double slInCurrency = ConvertPointsToCurrency(currentSymbol, StopLossCurrency, lotSize);
      string message_sl = "SL placé à: " + DoubleToString(slInCurrency, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
      DrawSingleLabel(LABEL_SL_A, message_sl, TextColor, 2, 20);
   }
}

//+------------------------------------------------------------------+
//| Fonction pour ajuster la valeur si trop petite selon les digits |
//+------------------------------------------------------------------+
double AdjustRespirationValue(double value, string parameterType)
{
    string symbol = PositionGetString(POSITION_SYMBOL);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double adjustedValue = value;

    switch(digits)
    {
        case 5:
            if(value <= 0.00009)
            {
                adjustedValue = 0.0001;
                Print("?? ", parameterType, " trop petit pour ", symbol, " (5 décimales), ajusté à 0.0001 points");
            }
            break;

        case 4:
            if(value <= 0.0009)
            {
                adjustedValue = 0.001;
                Print("?? ", parameterType, " trop petit pour ", symbol, " (4 décimales), ajusté à 0.001 points");
            }
            break;

        case 3:
            if(value <= 0.009)
            {
                adjustedValue = 0.01;
                Print("?? ", parameterType, " trop petit pour ", symbol, " (3 décimales), ajusté à 0.01 points");
            }
            break;

        case 2:
            if(value <= 0.09)
            {
                adjustedValue = 0.1;
                Print("?? ", parameterType, " trop petit pour ", symbol, " (2 décimales), ajusté à 0.1 points");
            }
            break;

        default:
            if(value <= 0.9)
            {
                adjustedValue = 1.0;
                Print("?? ", parameterType, " trop petit pour ", symbol, " (décimales inconnues), ajusté à 1.0 points");
            }
            break;
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
//| Conversion swap -> points (ex: -0.18€ → 5 points)               |
//+------------------------------------------------------------------+
int ConvertCurrencyToPoints(string symbol, double amountCurrency, double lotSize)
{
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

    if(point == 0 || lotSize == 0 || tickValue == 0) return 0;
    
    return (int)MathRound((amountCurrency * tickSize) / (point * lotSize * tickValue)); // MathRound pour plus de précision
}

//+------------------------------------------------------------------+
//| Fonction pour calculer le prix de breakeven des positions ouvertes |
//+------------------------------------------------------------------+
double CalculateBreakevenPrice(string symbol, ENUM_ORDER_TYPE orderType)
{
   double totalVolume = 0.0;
   double totalPriceVolume = 0.0;
   int totalPositions = 0;

   // Parcourir toutes les positions ouvertes
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      // Sélectionner la position par son ticket
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) // Vérifier si la sélection a échoué
      {
         continue; // Passer à la position suivante
      }

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      // Vérifier si la position correspond au symbole et au type d'ordre
      if (posSymbol == symbol && ((orderType == ORDER_TYPE_BUY && posType == POSITION_TYPE_BUY) ||
                                  (orderType == ORDER_TYPE_SELL && posType == POSITION_TYPE_SELL)))
      {
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double volume = PositionGetDouble(POSITION_VOLUME);
         totalVolume += volume;
         totalPriceVolume += openPrice * volume;
         totalPositions++;
      }
   }

   // Calculer le prix de breakeven
   if (totalVolume > 0)
   {
      double breakevenPrice = totalPriceVolume / totalVolume;
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      return NormalizeDouble(breakevenPrice, digits);
   }
   else
   {
      //Print("Aucune position ouverte pour ", symbol, " (", EnumToString(orderType), ")");
      return 0.0; // Retourner 0.0 si aucune position n'est ouverte
   }
}

//+------------------------------------------------------------------+
//| Fonction pour detecter le sens de la position                    |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE DetectOpenPositionType(string symbol)
{
    int totalBuy = 0;
    int totalSell = 0;

    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;

        string sym = PositionGetString(POSITION_SYMBOL);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

        if(sym == symbol)
        {
            if(posType == POSITION_TYPE_BUY) totalBuy++;
            if(posType == POSITION_TYPE_SELL) totalSell++;
        }
    }

    if (totalBuy > 0 && totalSell == 0)
        return ORDER_TYPE_BUY;
    else if (totalSell > 0 && totalBuy == 0)
        return ORDER_TYPE_SELL;
    else
        return (ENUM_ORDER_TYPE)-1; // Mixte ou aucune position
}

//+------------------------------------------------------------------+
//| Gestion du SL suiveur avec choix "Seuil" ou "Cours Actuel"       |
//+------------------------------------------------------------------+
void ManageGridSLSuiveur()
{
  
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
         
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;

        // Filtrage par magic number si activé
        if(UseMagicNumber)
        {
            long positionMagic = PositionGetInteger(POSITION_MAGIC);
            if(positionMagic != MagicNumber) continue;
        }

        string symbol = PositionGetString(POSITION_SYMBOL);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        bool isBuy = (posType == POSITION_TYPE_BUY);
        double positionPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        double lotSize = PositionGetDouble(POSITION_VOLUME);

        // Conversion swap négatif en points
        int swapPoints = 0;
        double swapAmount = PositionGetDouble(POSITION_SWAP);
        if(swapAmount < 0)
        {
            swapPoints = ConvertCurrencyToPoints(symbol, MathAbs(swapAmount), lotSize);
        }


        double triggerDistance;
        double breathingRoom;
        double breathingRoomSL;   
        double trailingSLDistance;
        
        switch(digits)
        {
    case 5:
        triggerDistance    = AdjustRespirationValue(InpSeuilDeclenchement5D, "Seuil de déclenchement");
        breathingRoom      = AdjustRespirationValue(InpRespiration5D, "Respiration seuil");
        breathingRoomSL    = AdjustRespirationValue(InpRespirationSL5D, "Respiration SL");
        trailingSLDistance = AdjustRespirationValue(InpSLsuiveur5D, "SL suiveur");
        break;

    case 4:
        triggerDistance    = AdjustRespirationValue(InpSeuilDeclenchement4D, "Seuil de déclenchement");
        breathingRoom      = AdjustRespirationValue(InpRespiration4D, "Respiration seuil");
        breathingRoomSL    = AdjustRespirationValue(InpRespirationSL4D, "Respiration SL");
        trailingSLDistance = AdjustRespirationValue(InpSLsuiveur4D, "SL suiveur");
        break;

    case 3:
        triggerDistance    = AdjustRespirationValue(InpSeuilDeclenchement3D, "Seuil de déclenchement");
        breathingRoom      = AdjustRespirationValue(InpRespiration3D, "Respiration seuil");
        breathingRoomSL    = AdjustRespirationValue(InpRespirationSL3D, "Respiration SL");
        trailingSLDistance = AdjustRespirationValue(InpSLsuiveur3D, "SL suiveur");
        break;

    case 2:
        triggerDistance    = AdjustRespirationValue(InpSeuilDeclenchement2D, "Seuil de déclenchement");
        breathingRoom      = AdjustRespirationValue(InpRespiration2D, "Respiration seuil");
        breathingRoomSL    = AdjustRespirationValue(InpRespirationSL2D, "Respiration SL");
        trailingSLDistance = AdjustRespirationValue(InpSLsuiveur2D, "SL suiveur");
        break;

    default:
        // Valeurs par défaut ou message d’erreur
        triggerDistance    = AdjustRespirationValue(InpSeuilDeclenchement5D, "Seuil de déclenchement");
        breathingRoom      = AdjustRespirationValue(InpRespiration5D, "Respiration seuil");
        breathingRoomSL    = AdjustRespirationValue(InpRespirationSL5D, "Respiration SL");
        trailingSLDistance = AdjustRespirationValue(InpSLsuiveur5D, "SL suiveur");
        Print("Nombre de décimales non géré : ", digits);
        break;
        }
        // declaration variable seuildejadeclencher
        bool seuilDejaDeclenche = IsSeuilDeclencheActif(ticket);   
        // Gestion SL Initial (Seuil de déclenchement)
        if(!seuilDejaDeclenche)
        {
               //calcul du BE
               ENUM_ORDER_TYPE sensLocal = (isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
               double BE = CalculateBreakevenPrice(symbol, sensLocal);
               
            double seuilActivation = isBuy ?
                BE + triggerDistance + breathingRoom + (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT)) :
                BE - triggerDistance - breathingRoom - (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT));

            double slInitial = isBuy ?
                BE + triggerDistance + (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT)) :
                BE - triggerDistance - (swapPoints * SymbolInfoDouble(symbol, SYMBOL_POINT));

            slInitial = NormalizeDouble(slInitial, digits);

            if((isBuy && current_price >= seuilActivation) || (!isBuy && current_price <= seuilActivation))
            {
                if(trade.PositionModify(ticket, slInitial, currentTP))
                {
                    Print("SL initial placé à ", DoubleToString(slInitial, digits), " pour ", symbol);
                    SetSeuilDeclencheActif(ticket); // Marquer le seuil comme déclenché de manière persistante
                    currentSL = slInitial;
                }
                else
                {
                    Print("? Erreur placement SL initial : ", trade.ResultRetcodeDescription());
                }
            }
        }
        else
        {
            // === Mode 1 : SL suiveur "Seuil"
            if(Typesuivie == Seuil)
            {
                double seuilActivationSLSuiveur = isBuy ?
                    currentSL + trailingSLDistance + breathingRoomSL :
                    currentSL - trailingSLDistance - breathingRoomSL;

                double nouveauSL = isBuy ?
                    currentSL + trailingSLDistance :
                    currentSL - trailingSLDistance;

                nouveauSL = NormalizeDouble(nouveauSL, digits);

                if((isBuy && current_price >= seuilActivationSLSuiveur) || (!isBuy && current_price <= seuilActivationSLSuiveur))
                {
                    if(trade.PositionModify(ticket, nouveauSL, currentTP))
                    {
                        Print("SL suiveur (Seuil) déplacé à ", DoubleToString(nouveauSL, digits), " pour ", symbol);
                    }
                    else
                    {
                        Print("? Erreur déplacement SL suiveur (Seuil) : ", trade.ResultRetcodeDescription());
                    }
                }
            }

            // === Mode 2 : SL suiveur "Cours Actuel"
            else if(Typesuivie == Cours_Actuel)
            {
                double nouveauSL = isBuy ?
                    current_price - trailingSLDistance :
                    current_price + trailingSLDistance;

                nouveauSL = NormalizeDouble(nouveauSL, digits);

                if((isBuy && nouveauSL > currentSL) || (!isBuy && nouveauSL < currentSL))
                {
                    if(trade.PositionModify(ticket, nouveauSL, currentTP))
                    {
                        Print("SL suiveur (Cours Actuel) déplacé à ", DoubleToString(nouveauSL, digits), " pour ", symbol);
                    }
                    else
                    {
                        Print("? Erreur déplacement SL suiveur (Cours Actuel) : ", trade.ResultRetcodeDescription());
                    }
                }
            }
        }
    }
    // nettoyage position fermer dans tableaux pour eviter surcharge
    NettoyerSeuilDeclencheSiPositionFermee();
}

//+------------------------------------------------------------------+
//| Fonction pour gerer l'activation du seuil par position           |
//+------------------------------------------------------------------+
bool IsSeuilDeclencheActif(ulong ticket)
{
    return (GlobalVariableCheck("SEUIL_" + (string)ticket));
}

void SetSeuilDeclencheActif(ulong ticket)
{
    GlobalVariableSet("SEUIL_" + (string)ticket, 1);
}

//+------------------------------------------------------------------+
//| Fonction pour vider le tableaux quand pos fermer                 |
//+------------------------------------------------------------------+
void NettoyerSeuilDeclencheSiPositionFermee()
{
    for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
    {
        string varName = GlobalVariableName(i);

        // On filtre uniquement les variables qui commencent par "SEUIL_"
        if(StringFind(varName, "SEUIL_") == 0)
        {
            // On extrait le ticket depuis le nom de la variable
            string ticketStr = StringSubstr(varName, 6); // "SEUIL_" = 6 caractères
            ulong ticket = (ulong)StringToInteger(ticketStr);

            // Vérifie si la position existe encore
            if(!PositionSelectByTicket(ticket))
            {
                GlobalVariableDel(varName);
                Print("🧹 Variable globale supprimée : ", varName);
            }
        }
    }
}

//+---------------------------------------------------------------------+
//| Fonction pour placer un ordre limit en attente pour le grid trading |
//+---------------------------------------------------------------------+
void PlacePendingOrder()
{
    // Parcourir toutes les positions ouvertes pour identifier les symboles uniques et les types d'ordres
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) continue;
        string posSymbol = PositionGetString(POSITION_SYMBOL);
        ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        long posMagic = PositionGetInteger(POSITION_MAGIC);

        // Vérifier le Magic Number si activé
        if (UseMagicNumber && posMagic != MagicNumber) continue;

        double volume = ChoixTypeLots(); // Volume défini
        string comment = "Micheline Grid";

        // Déterminer le type d'ordre en fonction du type de position
        ENUM_ORDER_TYPE orderType = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

       // --- VÉRIFICATION DES ORDRES EN ATTENTE (DÉPLACÉE ICI) ---
        bool hasPendingOrder = false;
        for (int j = OrdersTotal() - 1; j >= 0; j--)
        {
            ulong orderTicket = OrderGetTicket(j);
            if (orderTicket == 0) continue;
            string orderSymbol = OrderGetString(ORDER_SYMBOL);
            ENUM_ORDER_TYPE orderTypePending = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            long orderMagic = OrderGetInteger(ORDER_MAGIC);

            if (orderSymbol == posSymbol && ((orderType == ORDER_TYPE_BUY && orderTypePending == ORDER_TYPE_BUY_LIMIT) ||
                                            (orderType == ORDER_TYPE_SELL && orderTypePending == ORDER_TYPE_SELL_LIMIT)))
            {
                if (UseMagicNumber)
                {
                    if (orderMagic == MagicNumber)
                    {
                        hasPendingOrder = true;
                        break; // Important: Sortir de la boucle interne (OrdersTotal)
                    }
                }
                else
                {
                    hasPendingOrder = true;
                    break; // Important: Sortir de la boucle interne (OrdersTotal)
                }
            }
        }

        if (hasPendingOrder)
        {
            continue; // Passer à la position suivante si un ordre en attente existe
        }
        // --- FIN DE LA VÉRIFICATION DES ORDRES EN ATTENTE ---


        // Appeler PlacePendingLimitOrder (seulement si aucun ordre en attente n'a été trouvé)
        if (!PlacePendingLimitOrder(posSymbol, orderType, volume, comment))
        {
            Print("Erreur lors de la placement de l'ordre ", EnumToString(orderType), " limit pour ", posSymbol, ": ", GetLastError());
        }
    }
}

//+---------------------------------------------------------------------+
//| Fonction pour placer un ordre limit en attente pour le grid trading |
//+---------------------------------------------------------------------+
bool PlacePendingLimitOrder(string symbol, ENUM_ORDER_TYPE orderType, double volume, string comment = "")
{
       //verification nouvelle bougie pour ouvrir
   if(!IsNewBar())
   {
      return false;
   }
    // --- 1. Vérifications initiales et configuration ---

    // Compter les positions ouvertes (avec ou sans filtre magic)
    int currentPositionstoutes = CountToutesPositions();
    // Compter le nombre de lots ouverts (avec ou sans filtre magic)
    double totalVolume = CountTotalVolume();

    switch (Risque_Grid)
    {
    case POS_Grid:
        if (currentPositionstoutes >= GridMaxOrders)
        {
            Print("PlacePendingLimitOrder : Nombre maximal d'ordres atteint (", GridMaxOrders, "). Annulation.");
            return false;
        }
        break;

    case Lots_Grid:
        if (totalVolume >= GridMaxlots)
        {
            Print("PlacePendingLimitOrder : Volume maximal de lots atteint (", GridMaxlots, "). Annulation.");
            return false;
        }
        break;
    }

    // Vérifier le type d'ordre
    if (orderType != ORDER_TYPE_BUY && orderType != ORDER_TYPE_SELL)
    {
        Print("Erreur : Type d'ordre invalide pour un ordre limite : ", EnumToString(orderType));
        return false;
    }

    // Récupérer les informations sur le symbole
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);


    // --- 2. Calcul du prix de Breakeven et du prix initial ---

    // Calculer le prix de breakeven
    double breakevenPrice = CalculateBreakevenPrice(symbol, orderType);
    if (breakevenPrice == 0.0)
    {
        Print("Erreur : Aucun prix de breakeven trouvé pour ", symbol);
        return false;
    }

    // Choix decimale griddistancepoint
    double GridDistancePoints;
    switch(digits)
    {
    case 5:
        GridDistancePoints  = GridDistancePoints5D;
        break;
    case 4:
        GridDistancePoints  = GridDistancePoints4D;
        break;
    case 3:
        GridDistancePoints  = GridDistancePoints3D;
        break;
    case 2:
        GridDistancePoints  = GridDistancePoints2D;
        break;
    default:    
        // Valeurs par défaut ou message d’erreur
        GridDistancePoints  = GridDistancePoints5D;
        Print("Nombre de décimales non géré : ", digits);
        break;
    }
    
    // Calculer le prix initial de l'ordre limite
    double price;
    if (orderType == ORDER_TYPE_BUY)
    {
        price = breakevenPrice - GridDistancePoints;
    }
    else // ORDER_TYPE_SELL
    {
        price = breakevenPrice + GridDistancePoints;
    }


    // --- 3. Vérification de la distance minimale du courtier et ajustement ---

    // Obtenir le niveau de stop minimum du courtier (en points)
    long stopsLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
    if (stopsLevel < 0)
    {
        Print("PlacePendingLimitOrder : Erreur lors de la récupération de SYMBOL_TRADE_STOPS_LEVEL.  Code d'erreur : ", GetLastError());
        return false;  // Erreur critique : impossible de continuer sans le niveau de stop
    }
    double minDistance = stopsLevel * point; // Distance minimale en unités de prix


    // --- 4. Dépassement du niveau de prix et ajustement final du prix ---

    // Vérifier si le prix actuel a dépassé le niveau calculé
    // ET ajuster pour la distance minimale du courtier
    bool priceLevelExceeded = false;
    double adjustedPrice = price; // Commencer avec le prix calculé initialement

    if (orderType == ORDER_TYPE_BUY)
    {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        if (bid <= price)
        {
            priceLevelExceeded = true;
            adjustedPrice = bid - GridDistancePoints; // Recalculer à partir du Bid
        }

        // Vérification de la distance minimale du courtier (ACHAT)
        if (MathAbs(adjustedPrice - bid) < minDistance)
        {
            adjustedPrice = bid - minDistance; // Ajuster à la distance minimale
            //Print("PlacePendingLimitOrder : Prix d'ACHAT ajusté à ", adjustedPrice, " en raison de la distance minimale du courtier (", minDistance, ")");
        }
    }
    else // ORDER_TYPE_SELL
    {
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        if (ask >= price)
        {
            priceLevelExceeded = true;
            adjustedPrice = ask + GridDistancePoints; // Recalculer à partir du Ask
        }

         // Vérification de la distance minimale du courtier (VENTE)
        if (MathAbs(adjustedPrice - ask) < minDistance)
        {
            adjustedPrice = ask + minDistance; // Ajuster à la distance minimale
              //Print("PlacePendingLimitOrder : Prix de VENTE ajusté à ", adjustedPrice, " en raison de la distance minimale du courtier (", minDistance, ")");
        }
    }

     price = NormalizeDouble(adjustedPrice, digits);

    // --- 5. Vérifications finales de validité et journalisation ---
      // Journal pour afficher les niveaux
    //Print("PlacePendingLimitOrder : ", symbol, " ", EnumToString(orderType), " à ", price, " (Breakeven : ", breakevenPrice, ", GridDistance : ", GridDistancePoints, " points, MinDistance : ",minDistance,")");


    // Vérifier que le prix est valide
    if (price <= 0.0)
    {
        Print("PlacePendingLimitOrder : Prix invalide (<= 0). Annulation.");
        return false;
    }



    // --- 6. Placement de l'ordre ---

    // Préparer la structure MqlTradeRequest
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    request.action = TRADE_ACTION_PENDING;
    request.symbol = symbol;
    request.volume = volume;
    request.type = orderType == ORDER_TYPE_BUY ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
    request.price = price;
    request.deviation = 10; // Slippage autorisé
    request.magic = MagicNumber; // Ajout du Magic Number
    request.comment = comment;
    request.type_filling = ORDER_FILLING_IOC; // Ajustez selon votre courtier

    // Envoyer l'ordre
    if (!OrderSend(request, result))
    {
        Print("PlacePendingLimitOrder : Échec de OrderSend. Code d'erreur : ", GetLastError(), ", result.retcode : ", result.retcode);
        return false;
    }

      //Print("PlacePendingLimitOrder : Ordre placé avec succès. Ticket : ", result.order); // Journaliser le placement réussi
      return true;
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

    // Vérification du swap si SwapPositif est activé
    if (SwapPositif)
    {
        double swapLong = SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
        double swapShort = SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);

        if ((orderType == ORDER_TYPE_BUY && swapLong <= 0) || 
            (orderType == ORDER_TYPE_SELL && swapShort <= 0))
        {
            //Print("Trade refusé pour ", symbol, " - Swap non favorable (", (orderType == ORDER_TYPE_BUY ? swapLong : swapShort), ")");
            return false; // On refuse d'ouvrir la position
        }
    }

    // Calcul des SL et TP en fonction du type de SL choisi
    if (StopLossType == SL_Classique)
    {
        CalculateClassicSLTP(symbol, orderType, sl, tp, slPercentage, tpPercentage, slPoints, tpPoints);
    }
    else if (StopLossType == GridTrading)
    {
        //deja defini dans placependinglimitorder
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
    request.magic = MagicNumber;
    request.comment = comment;
    // seuil declenchement en fonction des decimales
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double triggerDistance;
    switch(digits)
    {
    case 5:
        triggerDistance    = InpSeuilDeclenchement5D;
        break;

    case 4:
        triggerDistance    = InpSeuilDeclenchement4D;
        break;

    case 3:
        triggerDistance    = InpSeuilDeclenchement3D;
        break;

    case 2:
        triggerDistance    = InpSeuilDeclenchement2D;
        break;

    default:
        // Valeurs par défaut ou message d’erreur
        triggerDistance    = InpSeuilDeclenchement5D;
        //Print("Nombre de décimales non géré : ", digits);
        break;
    }
    
    // Envoyer l'ordre
    if (OrderSend(request, result))
    {
        //Print("Position ouverte pour ", symbol, " - Type: ", EnumToString(orderType), " - Volume: ", volume);
        SendNotifications(symbol, orderType, volume, request.price, sl, tp);
        return true;
    }
    else
    {
        //Print("Erreur lors de l'ouverture de la position : ", result.comment);
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
   
   //verification qu'aucune position existe deja pour ce symbol
   if(IsPositionOpen(symbol))
   {
      //Print("Position déjà ouverte sur ", symbol, ". Aucune nouvelle position ne sera ouverte.");
      return false;
   }

   // Compter les positions ouvertes (avec ou sans filtre magic)
   int currentPositionstoutes = CountToutesPositions();

   // Vérifier si le nombre maximum de positions est atteint
   if(currentPositionstoutes >= GridMaxOrders)
   {
      return false;
   }

   // Déterminer le type d'ordre en fonction du signal
   ENUM_ORDER_TYPE orderType = (signal == Achat) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   // Vérifier si le symbole est tradable
   if(!SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE))
   {
      return false;
   }

   // Récupérer la taille d'un point pour le symbole
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   // Récupérer le prix actuel
   double currentPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : SymbolInfoDouble(symbol, SYMBOL_ASK);

   // Vérifier si une position est déjà ouverte pour ce symbole
   int currentSymbolPositions = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) > 0)
      {
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         if(posSymbol == symbol)
         {
            currentSymbolPositions++;
         }
      }
   }
   if(currentSymbolPositions > 0)
   {
      return false;
   }


   volume = ChoixTypeLots(); // Forcer la taille fixe
   // Ouvrir la première position (sans SL ni TP)
   if(OpenPosition(symbol, orderType, volume, 0.0, 0.0)) // SL et TP explicitement à 0.0
   {
      return true;
   }
   else
   {
      return false;
   }
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

//+------------------------------------------------------------------+
//| Fonction pour supprimer les ordres limit en attente orphelins    |
//+------------------------------------------------------------------+
void DeletePendingLimitOrders()
{
    // Vérifier les deux types d'ordres (BUY et SELL)
    ENUM_ORDER_TYPE orderTypes[] = {ORDER_TYPE_BUY, ORDER_TYPE_SELL};
    for (int t = 0; t < ArraySize(orderTypes); t++)
    {
        ENUM_ORDER_TYPE orderType = orderTypes[t];

        // Parcourir tous les ordres en attente (sans restriction de symbole)
        for (int i = OrdersTotal() - 1; i >= 0; i--)
        {
            ulong ticket = OrderGetTicket(i);
            if (ticket == 0) continue;

            string orderSymbol = OrderGetString(ORDER_SYMBOL);
            ENUM_ORDER_TYPE orderTypePending = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            long orderMagic = OrderGetInteger(ORDER_MAGIC);

            // Vérifier si l'ordre est un ordre limit (BUY_LIMIT ou SELL_LIMIT)
            if ((orderType == ORDER_TYPE_BUY && orderTypePending == ORDER_TYPE_BUY_LIMIT) ||
                (orderType == ORDER_TYPE_SELL && orderTypePending == ORDER_TYPE_SELL_LIMIT))
            {
                // Vérifier s'il existe une position ouverte correspondante (même symbole, type, et Magic Number si applicable)
                bool hasMatchingPosition = false;

                for (int j = 0; j < PositionsTotal(); j++)
                {
                    ulong posTicket = PositionGetTicket(j);
                    if (posTicket == 0) continue;

                    string posSymbol = PositionGetString(POSITION_SYMBOL);
                    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                    long posMagic = PositionGetInteger(POSITION_MAGIC);

                    // Vérifier le symbole, le type de position, et le Magic Number si applicable
                    if (posSymbol == orderSymbol &&
                        ((orderType == ORDER_TYPE_BUY && posType == POSITION_TYPE_BUY) ||
                         (orderType == ORDER_TYPE_SELL && posType == POSITION_TYPE_SELL)) &&
                        (!UseMagicNumber || posMagic == MagicNumber)) // Simplification de la condition
                    {
                        hasMatchingPosition = true;
                        break; // Sortir de la boucle interne dès qu'une correspondance est trouvée
                    }
                }

                // Si aucune position ouverte correspondante n'est trouvée, supprimer l'ordre limit en attente
                if (!hasMatchingPosition)
                {
                    Print("Aucune position ouverte correspondante trouvée pour l'ordre limit en attente ", ticket, ", Symbole: ", orderSymbol, ", suppression de l'ordre");
                    MqlTradeRequest request;
                    MqlTradeResult result;
                    ZeroMemory(request);
                    ZeroMemory(result);

                    request.action = TRADE_ACTION_REMOVE;
                    request.order = ticket;

                    if (OrderSend(request, result))
                    {
                        Print("Ordre ", ticket, " supprimé avec succès."); // AJOUT: Confirmation de suppression
                    }
                    else
                    {
                        Print("ERREUR: Impossible de supprimer l'ordre ", ticket, ".  Erreur: ", GetLastError(), ", Résultat: ", result.retcode); // AJOUT: Gestion d'erreur
                    }
                }
            }
        }
    }
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
//| Fonction pour vérifier si une nouvelle bougie est apparue         |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime last_bar_time = 0;
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if (current_bar_time != last_bar_time)
   {
      last_bar_time = current_bar_time;
      return true;
   }
   return false;
}

//---------------------------------------------------------
// Fonction pour déterminer le lot selon le type choisi   |
//---------------------------------------------------------
double ChoixTypeLots()
{
   double LotsChoix = 0.0;

   switch(LotSizeType)
   {
      case LotFixe:
         LotsChoix = FixedLotSize;
         break;

      case low_medium_high:
        // lot Basée uniquement sur la marge restante
         switch(RisquePoucentage)
         {
            case Very_Low_P:
            {
               double equity = AccountInfoDouble(ACCOUNT_EQUITY);
               double riskPercent = 1.0;
            
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double margePour001 = 0.0;
            
               if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 0.01, ask, margePour001) || margePour001 <= 0)
               {
                  Print("Erreur : Impossible de calculer la marge pour 0.01 lot.");
                  return 0.0;
               }
            
               double margeCible = equity * (riskPercent / 100.0);
               LotsChoix = NormalizeDouble((margeCible / margePour001) * 0.01, 2);
               return LotsChoix;
               break;
            }
            
            case Low_P:
            {
               double equity = AccountInfoDouble(ACCOUNT_EQUITY);
               double riskPercent = 2.0;
            
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double margePour001 = 0.0;
            
               if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 0.01, ask, margePour001) || margePour001 <= 0)
               {
                  Print("Erreur : Impossible de calculer la marge pour 0.01 lot.");
                  return 0.0;
               }
            
               double margeCible = equity * (riskPercent / 100.0);
               LotsChoix = NormalizeDouble((margeCible / margePour001) * 0.01, 2);
               return LotsChoix;
               break;
            }
            
            case Medium_P:
            {
               double equity = AccountInfoDouble(ACCOUNT_EQUITY);
               double riskPercent = 5.0;
            
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double margePour001 = 0.0;
            
               if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 0.01, ask, margePour001) || margePour001 <= 0)
               {
                  Print("Erreur : Impossible de calculer la marge pour 0.01 lot.");
                  return 0.0;
               }
            
               double margeCible = equity * (riskPercent / 100.0);
               LotsChoix = NormalizeDouble((margeCible / margePour001) * 0.01, 2);
               return LotsChoix;
               break;
            }
            
            case High_P:
            {
               double equity = AccountInfoDouble(ACCOUNT_EQUITY);
               double riskPercent = 10.0;
            
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double margePour001 = 0.0;
            
               if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 0.01, ask, margePour001) || margePour001 <= 0)
               {
                  Print("Erreur : Impossible de calculer la marge pour 0.01 lot.");
                  return 0.0;
               }
            
               double margeCible = equity * (riskPercent / 100.0);
               LotsChoix = NormalizeDouble((margeCible / margePour001) * 0.01, 2);
               return LotsChoix;
               break;
            }
            
            case Very_High_P:
            {
               double equity = AccountInfoDouble(ACCOUNT_EQUITY);
               double riskPercent = 20.0;
            
               double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               double margePour001 = 0.0;
            
               if (!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 0.01, ask, margePour001) || margePour001 <= 0)
               {
                  Print("Erreur : Impossible de calculer la marge pour 0.01 lot.");
                  return 0.0;
               }
            
               double margeCible = equity * (riskPercent / 100.0);
               LotsChoix = NormalizeDouble((margeCible / margePour001) * 0.01, 2);
               return LotsChoix;
               break;
            }
         }
         break;
   }
   // Vérification finale du volume
   if (LotsChoix < 0.01)
   {
      return 0.01;
   }
      
   return LotsChoix;
}


//+------------------------------------------------------------------+
//| Fin du code                                                      |
//+------------------------------------------------------------------+ 