//+------------------------------------------------------------------+
//|                                           ManualTradeManager.mq5 |
//|                        Copyright 2025, Your Name                 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Your Name"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "EA that manages manually opened trades with customizable SL/TP, breakeven, and trailing stop"

#include <Trade\Trade.mqh>

//--- Input parameters
input group "==== Basic Settings ===="
input bool     EnableEA = true;                    // Enable EA
input int      StopLossPips = 50;                  // Stop Loss in pips
input int      TakeProfitPips = 100;               // Take Profit in pips

input group "==== Breakeven Settings ===="
input bool     EnableBreakeven = true;             // Enable Breakeven
input double   BreakevenTriggerR = 1.0;           // Breakeven trigger (R multiple)
input int      BreakevenOffsetPips = 5;           // Breakeven offset in pips

input group "==== Trailing Stop Settings ===="
input bool     EnableTrailingStop = false;        // Enable Trailing Stop
input int      TrailingStartPips = 20;            // Trailing start distance in pips
input int      TrailingStepPips = 10;             // Trailing step in pips

input group "==== Risk Management ===="
input bool     EnableRiskManagement = true;       // Enable Risk Management
input double   MaxRiskPercent = 2.0;              // Maximum risk per trade (%)
input double   MaxLotSize = 1.0;                  // Maximum lot size

input group "==== Grid System ===="
input bool     EnableGridSystem = true;          // Enable Grid System
input int      GridSpacingPips = 50;             // Grid spacing in pips
input int      MaxGridLevels = 3;                // Maximum grid levels (including manual entry)

input group "==== Grid Lot Sizing ===="
input int      GridLotSizeMethod = 1;            // 1=Fixed Ratio, 2=Fixed Amount, 3=Custom Weights
input double   FixedRatio = 0.8;                 // Ratio for each grid level (method 1)
input double   FixedAmount = 0.1;                // Fixed lot size for all grid levels (method 2)
input double   CustomWeight2 = 30.0;             // Grid level 2 weight percentage (method 3)
input double   CustomWeight3 = 20.0;             // Grid level 3 weight percentage (method 3)

input group "==== Grid Timing ===="
input int      GridTimingMethod = 1;             // 1=Immediate, 2=Progressive, 3=Price-based
input int      ProgressiveDelay = 5;             // Delay between orders in seconds (method 2)
input int      PriceBasedTriggerPips = 20;       // Trigger distance in pips (method 3)

input group "==== Grid Management ===="
input int      GridManagementMethod = 1;         // 1=Individual, 2=Combined, 3=Tiered
input int      CombinedSLOffset = 10;            // SL offset from average entry (method 2)
input int      TieredSLAdjustPips = 15;          // SL adjustment per level (method 3)

input group "==== Advanced ===="
input int      MagicNumber = 0;                   // Magic number for manual trades (keep 0)
input bool     ManageOnlyNewTrades = true;        // Only manage trades opened after EA start

//--- Global variables
CTrade trade;
datetime ea_start_time;

//--- Structure to track managed positions
struct ManagedPosition
{
    ulong    ticket;
    datetime open_time;
    bool     breakeven_applied;
    bool     is_managed;
    double   original_sl;
    double   original_tp;
    double   risk_amount;
    int      grid_id;                // Grid group identifier
    int      grid_level;             // Grid level (1=manual, 2,3=auto)
    bool     is_grid_master;         // True for the manually opened trade
};

//--- Structure to track grid systems
struct GridSystem
{
    int      grid_id;
    string   symbol;
    ENUM_POSITION_TYPE direction;
    double   master_entry_price;
    double   master_lot_size;
    double   master_sl;
    double   master_tp;
    ulong    master_ticket;
    datetime creation_time;
    double   level2_trigger_price;
    double   level3_trigger_price;
    bool     level2_triggered;
    bool     level3_triggered;
    ulong    level2_position;
    ulong    level3_position;
    datetime last_price_check;
};

ManagedPosition managed_positions[];
GridSystem grid_systems[];
int next_grid_id = 1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set trade parameters
    trade.SetExpertMagicNumber(MagicNumber);
    trade.SetAsyncMode(false);
    trade.SetTypeFillingBySymbol(Symbol());
    
    // Record EA start time
    ea_start_time = TimeCurrent();
    
    // Initialize managed positions array
    ArrayResize(managed_positions, 0);
    
    Print("Manual Trade Manager EA initialized successfully");
    Print("Grid System: ", EnableGridSystem ? "Enabled" : "Disabled");
    if(EnableGridSystem)
    {
        Print("Grid Settings: Spacing=", GridSpacingPips, " pips, Max Levels=", MaxGridLevels);
        Print("Lot Method=", GridLotSizeMethod, ", Timing Method=", GridTimingMethod, ", Management Method=", GridManagementMethod);
    }
    Print("Monitoring all currency pairs for manual trades...");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Manual Trade Manager EA stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!EnableEA) return;
    
    // Main management functions
    DetectAndManageNewTrades();
    UpdateManagedPositions();
    
    // Grid system functions
    if(EnableGridSystem)
    {
        UpdateGridSystems();
    }
}

//+------------------------------------------------------------------+
//| Detect new manual trades and add them to management             |
//+------------------------------------------------------------------+
void DetectAndManageNewTrades()
{
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0) continue;
        
        if(!PositionSelectByTicket(ticket)) continue;
        
        // Check if this is a manual trade
        if(!IsManualTrade(ticket)) continue;
        
        // Check if already managed
        if(IsAlreadyManaged(ticket)) continue;
        
        // Check if we should only manage new trades
        if(ManageOnlyNewTrades && PositionGetInteger(POSITION_TIME) < ea_start_time)
            continue;
        
        // Add to management
        AddToManagement(ticket);
        
        // Check if we should create a grid system for this trade
        if(EnableGridSystem && MaxGridLevels > 1)
        {
            CreateGridSystem(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Check if position is a manual trade                             |
//+------------------------------------------------------------------+
bool IsManualTrade(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return false;
    
    long magic = PositionGetInteger(POSITION_MAGIC);
    long reason = PositionGetInteger(POSITION_REASON);
    
    // Manual trades have magic = 0 and reason != 3 (not opened by EA)
    return (magic == MagicNumber && reason != POSITION_REASON_EXPERT);
}

//+------------------------------------------------------------------+
//| Check if position is already managed                            |
//+------------------------------------------------------------------+
bool IsAlreadyManaged(ulong ticket)
{
    for(int i = 0; i < ArraySize(managed_positions); i++)
    {
        if(managed_positions[i].ticket == ticket)
            return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Add position to management                                       |
//+------------------------------------------------------------------+
void AddToManagement(ulong ticket)
{
    if(!PositionSelectByTicket(ticket)) return;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double volume = PositionGetDouble(POSITION_VOLUME);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    // Calculate pip value for this symbol
    double pip_value = GetPipValue(symbol);
    double point_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Calculate new SL and TP
    double new_sl = 0, new_tp = 0;
    
    if(pos_type == POSITION_TYPE_BUY)
    {
        new_sl = open_price - (StopLossPips * pip_value);
        new_tp = open_price + (TakeProfitPips * pip_value);
    }
    else if(pos_type == POSITION_TYPE_SELL)
    {
        new_sl = open_price + (StopLossPips * pip_value);
        new_tp = open_price - (TakeProfitPips * pip_value);
    }
    
    // Apply risk management if enabled
    if(EnableRiskManagement)
    {
        double risk_amount = CalculateRiskAmount(symbol, volume, open_price, new_sl);
        double max_risk = AccountInfoDouble(ACCOUNT_BALANCE) * MaxRiskPercent / 100.0;
        
        if(risk_amount > max_risk)
        {
            Print("Warning: Trade ", ticket, " exceeds maximum risk. Risk: $", 
                  DoubleToString(risk_amount, 2), " Max: $", DoubleToString(max_risk, 2));
            // Optionally adjust position size or skip management
        }
    }
    
    // Set SL/TP only if they're not already set or if our values are better
    bool modify_needed = false;
    
    if(current_sl == 0 || ShouldUpdateSL(current_sl, new_sl, pos_type))
    {
        modify_needed = true;
    }
    
    if(current_tp == 0 || ShouldUpdateTP(current_tp, new_tp, pos_type))
    {
        modify_needed = true;
    }
    
    if(modify_needed)
    {
        if(trade.PositionModify(symbol, new_sl, new_tp))
        {
            Print("Successfully added trade ", ticket, " to management. Symbol: ", symbol, 
                  " SL: ", DoubleToString(new_sl, _Digits), " TP: ", DoubleToString(new_tp, _Digits));
        }
        else
        {
            Print("Failed to modify trade ", ticket, ". Error: ", GetLastError());
            return;
        }
    }
    
    // Add to managed positions array
    int new_index = ArraySize(managed_positions);
    ArrayResize(managed_positions, new_index + 1);
    
    managed_positions[new_index].ticket = ticket;
    managed_positions[new_index].open_time = (datetime)PositionGetInteger(POSITION_TIME);
    managed_positions[new_index].breakeven_applied = false;
    managed_positions[new_index].is_managed = true;
    managed_positions[new_index].original_sl = current_sl;
    managed_positions[new_index].original_tp = current_tp;
    managed_positions[new_index].risk_amount = CalculateRiskAmount(symbol, volume, open_price, new_sl);
    managed_positions[new_index].grid_id = 0;
    managed_positions[new_index].grid_level = 1;
    managed_positions[new_index].is_grid_master = false;
}

//+------------------------------------------------------------------+
//| Update all managed positions                                     |
//+------------------------------------------------------------------+
void UpdateManagedPositions()
{
    for(int i = ArraySize(managed_positions) - 1; i >= 0; i--)
    {
        ulong ticket = managed_positions[i].ticket;
        
        // Check if position still exists
        if(!PositionSelectByTicket(ticket))
        {
            // Position closed, remove from management
            RemoveFromManagement(i);
            continue;
        }
        
        // Apply breakeven if enabled and conditions met
        if(EnableBreakeven && !managed_positions[i].breakeven_applied)
        {
            ApplyBreakeven(i);
        }
        
        // Apply trailing stop if enabled
        if(EnableTrailingStop)
        {
            ApplyTrailingStop(i);
        }
    }
}

//+------------------------------------------------------------------+
//| Apply breakeven to position                                     |
//+------------------------------------------------------------------+
void ApplyBreakeven(int index)
{
    ulong ticket = managed_positions[index].ticket;
    if(!PositionSelectByTicket(ticket)) return;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    double pip_value = GetPipValue(symbol);
    double profit_pips;
    
    // Calculate current profit in pips
    if(pos_type == POSITION_TYPE_BUY)
    {
        profit_pips = (current_price - open_price) / pip_value;
    }
    else
    {
        profit_pips = (open_price - current_price) / pip_value;
    }
    
    // Check if breakeven trigger is reached
    double required_profit = StopLossPips * BreakevenTriggerR;
    
    if(profit_pips >= required_profit)
    {
        // Calculate breakeven SL
        double new_sl;
        if(pos_type == POSITION_TYPE_BUY)
        {
            new_sl = open_price + (BreakevenOffsetPips * pip_value);
        }
        else
        {
            new_sl = open_price - (BreakevenOffsetPips * pip_value);
        }
        
        // Apply breakeven
        if(trade.PositionModify(symbol, new_sl, current_tp))
        {
            managed_positions[index].breakeven_applied = true;
            Print("Breakeven applied to trade ", ticket, ". New SL: ", DoubleToString(new_sl, _Digits));
        }
    }
}

//+------------------------------------------------------------------+
//| Apply trailing stop to position                                 |
//+------------------------------------------------------------------+
void ApplyTrailingStop(int index)
{
    ulong ticket = managed_positions[index].ticket;
    if(!PositionSelectByTicket(ticket)) return;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    double pip_value = GetPipValue(symbol);
    double new_sl = current_sl;
    
    if(pos_type == POSITION_TYPE_BUY)
    {
        double potential_sl = current_price - (TrailingStartPips * pip_value);
        if(potential_sl > current_sl + (TrailingStepPips * pip_value))
        {
            new_sl = potential_sl;
        }
    }
    else
    {
        double potential_sl = current_price + (TrailingStartPips * pip_value);
        if(potential_sl < current_sl - (TrailingStepPips * pip_value))
        {
            new_sl = potential_sl;
        }
    }
    
    // Apply trailing stop if changed
    if(new_sl != current_sl)
    {
        if(trade.PositionModify(symbol, new_sl, current_tp))
        {
            Print("Trailing stop applied to trade ", ticket, ". New SL: ", DoubleToString(new_sl, _Digits));
        }
    }
}

//+------------------------------------------------------------------+
//| Remove position from management                                  |
//+------------------------------------------------------------------+
void RemoveFromManagement(int index)
{
    if(index < 0 || index >= ArraySize(managed_positions)) return;
    
    // Shift array elements
    for(int i = index; i < ArraySize(managed_positions) - 1; i++)
    {
        managed_positions[i] = managed_positions[i + 1];
    }
    
    // Resize array
    ArrayResize(managed_positions, ArraySize(managed_positions) - 1);
}

//+------------------------------------------------------------------+
//| Calculate pip value for symbol                                   |
//+------------------------------------------------------------------+
double GetPipValue(string symbol)
{
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    // For most pairs, pip is 10 * point (except JPY pairs where pip = point)
    if(digits == 3 || digits == 5)
        return point * 10;
    else
        return point;
}

//+------------------------------------------------------------------+
//| Calculate risk amount for position                              |
//+------------------------------------------------------------------+
double CalculateRiskAmount(string symbol, double volume, double open_price, double sl_price)
{
    if(sl_price == 0) return 0;
    
    double pip_risk = MathAbs(open_price - sl_price) / GetPipValue(symbol);
    double pip_value_in_account_currency = CalculatePipValue(symbol, volume);
    
    return pip_risk * pip_value_in_account_currency;
}

//+------------------------------------------------------------------+
//| Calculate pip value in account currency                         |
//+------------------------------------------------------------------+
double CalculatePipValue(string symbol, double volume)
{
    double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    return (tick_value / tick_size) * GetPipValue(symbol) * volume;
}

//+------------------------------------------------------------------+
//| Check if SL should be updated                                   |
//+------------------------------------------------------------------+
bool ShouldUpdateSL(double current_sl, double new_sl, ENUM_POSITION_TYPE pos_type)
{
    if(current_sl == 0) return true;
    
    if(pos_type == POSITION_TYPE_BUY)
        return new_sl > current_sl;
    else
        return new_sl < current_sl;
}

//+------------------------------------------------------------------+
//| Check if TP should be updated                                   |
//+------------------------------------------------------------------+
bool ShouldUpdateTP(double current_tp, double new_tp, ENUM_POSITION_TYPE pos_type)
{
    if(current_tp == 0) return true;
    
    // Only update if new TP is more conservative (closer to current price)
    if(pos_type == POSITION_TYPE_BUY)
        return new_tp < current_tp;
    else
        return new_tp > current_tp;
}

//+------------------------------------------------------------------+
//| Create grid system for new manual trade                         |
//+------------------------------------------------------------------+
void CreateGridSystem(ulong master_ticket)
{
    if(!PositionSelectByTicket(master_ticket)) return;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double lot_size = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    // Create new grid system
    int new_index = ArraySize(grid_systems);
    ArrayResize(grid_systems, new_index + 1);
    
    grid_systems[new_index].grid_id = next_grid_id++;
    grid_systems[new_index].symbol = symbol;
    grid_systems[new_index].direction = pos_type;
    grid_systems[new_index].master_entry_price = entry_price;
    grid_systems[new_index].master_lot_size = lot_size;
    grid_systems[new_index].master_ticket = master_ticket;
    grid_systems[new_index].creation_time = TimeCurrent();
    // Get master position SL/TP for unified management
    if(PositionSelectByTicket(master_ticket))
    {
        grid_systems[new_index].master_sl = PositionGetDouble(POSITION_SL);
        grid_systems[new_index].master_tp = PositionGetDouble(POSITION_TP);
    }
    
    // Calculate trigger prices
    double pip_value = GetPipValue(symbol);
    if(pos_type == POSITION_TYPE_SELL)
    {
        grid_systems[new_index].level2_trigger_price = entry_price + (GridSpacingPips * pip_value);
        grid_systems[new_index].level3_trigger_price = entry_price + (GridSpacingPips * 2 * pip_value);
    }
    else
    {
        grid_systems[new_index].level2_trigger_price = entry_price - (GridSpacingPips * pip_value);
        grid_systems[new_index].level3_trigger_price = entry_price - (GridSpacingPips * 2 * pip_value);
    }
    
    grid_systems[new_index].level2_triggered = false;
    grid_systems[new_index].level3_triggered = false;
    grid_systems[new_index].level2_position = 0;
    grid_systems[new_index].level3_position = 0;
    grid_systems[new_index].last_price_check = TimeCurrent();
    
    // Update master position with grid info
    UpdateMasterPositionGridInfo(master_ticket, grid_systems[new_index].grid_id);
    
    Print("Grid system created for trade ", master_ticket, ". Grid ID: ", grid_systems[new_index].grid_id);
}

//+------------------------------------------------------------------+
//| Update master position with grid information                    |
//+------------------------------------------------------------------+
void UpdateMasterPositionGridInfo(ulong ticket, int grid_id)
{
    for(int i = 0; i < ArraySize(managed_positions); i++)
    {
        if(managed_positions[i].ticket == ticket)
        {
            managed_positions[i].grid_id = grid_id;
            managed_positions[i].grid_level = 1;
            managed_positions[i].is_grid_master = true;
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Update all grid systems                                         |
//+------------------------------------------------------------------+
void UpdateGridSystems()
{
    for(int i = ArraySize(grid_systems) - 1; i >= 0; i--)
    {
        // Check if master position still exists
        if(!PositionSelectByTicket(grid_systems[i].master_ticket))
        {
            // Master closed, clean up grid system
            CleanupGridSystem(i);
            continue;
        }
        
        // Check for price triggers
        CheckPriceTriggers(i);
        
        // Apply grid management
        ApplyGridManagement(i);
    }
}

//+------------------------------------------------------------------+
//| Check for price triggers and execute market orders             |
//+------------------------------------------------------------------+
void CheckPriceTriggers(int grid_index)
{
    if(grid_index < 0 || grid_index >= ArraySize(grid_systems)) return;
    
    GridSystem& grid = grid_systems[grid_index];
    
    // Get current market price
    double current_price = 0;
    if(grid.direction == POSITION_TYPE_BUY)
    {
        current_price = SymbolInfoDouble(grid.symbol, SYMBOL_ASK);
    }
    else
    {
        current_price = SymbolInfoDouble(grid.symbol, SYMBOL_BID);
    }
    
    if(current_price == 0) return;
    
    // Check Level 2 trigger
    if(!grid.level2_triggered && MaxGridLevels >= 2)
    {
        bool trigger_level2 = false;
        
        if(grid.direction == POSITION_TYPE_SELL && current_price >= grid.level2_trigger_price)
        {
            trigger_level2 = true;
        }
        else if(grid.direction == POSITION_TYPE_BUY && current_price <= grid.level2_trigger_price)
        {
            trigger_level2 = true;
        }
        
        if(trigger_level2)
        {
            ExecuteGridEntry(grid_index, 2, current_price);
        }
    }
    
    // Check Level 3 trigger
    if(!grid.level3_triggered && MaxGridLevels >= 3)
    {
        bool trigger_level3 = false;
        
        if(grid.direction == POSITION_TYPE_SELL && current_price >= grid.level3_trigger_price)
        {
            trigger_level3 = true;
        }
        else if(grid.direction == POSITION_TYPE_BUY && current_price <= grid.level3_trigger_price)
        {
            trigger_level3 = true;
        }
        
        if(trigger_level3)
        {
            ExecuteGridEntry(grid_index, 3, current_price);
        }
    }
}

//+------------------------------------------------------------------+
//| Execute grid entry with market order                           |
//+------------------------------------------------------------------+
void ExecuteGridEntry(int grid_index, int level, double current_price)
{
    if(grid_index < 0 || grid_index >= ArraySize(grid_systems)) return;
    
    GridSystem& grid = grid_systems[grid_index];
    
    // Calculate lot size for this level
    double grid_lot_size = CalculateGridLotSize(grid.master_lot_size, level);
    
    // Execute market order
    ENUM_ORDER_TYPE order_type = (grid.direction == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    
    string comment = "GRID_" + IntegerToString(grid.grid_id) + "_L" + IntegerToString(level);
    
    if(trade.PositionOpen(grid.symbol, order_type, grid_lot_size, current_price, grid.master_sl, grid.master_tp, comment))
    {
        ulong position_ticket = trade.ResultDeal();
        
        if(level == 2)
        {
            grid.level2_triggered = true;
            grid.level2_position = position_ticket;
        }
        else if(level == 3)
        {
            grid.level3_triggered = true;
            grid.level3_position = position_ticket;
        }
        
        // Add to managed positions with unified SL
        AddGridPositionToManagement(position_ticket, grid.grid_id, level, grid.master_sl, grid.master_tp);
        
        Print("Grid level ", level, " triggered for grid ", grid.grid_id, ". Entry: ", DoubleToString(current_price, _Digits), 
              " Lot: ", DoubleToString(grid_lot_size, 2), " SL: ", DoubleToString(grid.master_sl, _Digits));
    }
    else
    {
        Print("Failed to execute grid level ", level, " for grid ", grid.grid_id, ". Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Calculate lot size for grid level                              |
//+------------------------------------------------------------------+
double CalculateGridLotSize(double master_lot_size, int level)
{
    double result = master_lot_size;
    
    switch(GridLotSizeMethod)
    {
        case 1: // Fixed Ratio
            for(int i = 1; i < level; i++)
            {
                result *= FixedRatio;
            }
            break;
            
        case 2: // Fixed Amount
            result = FixedAmount;
            break;
            
        case 3: // Custom Weights
            if(level == 2)
                result = master_lot_size * (CustomWeight2 / 100.0);
            else if(level == 3)
                result = master_lot_size * (CustomWeight3 / 100.0);
            break;
    }
    
    // Ensure minimum lot size
    double min_lot = SymbolInfoDouble(SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE), SYMBOL_VOLUME_MIN);
    if(result < min_lot) result = min_lot;
    
    // Ensure maximum lot size
    if(result > MaxLotSize) result = MaxLotSize;
    
    return NormalizeDouble(result, 2);
}


//+------------------------------------------------------------------+
//| Add grid position to management with unified SL                |
//+------------------------------------------------------------------+
void AddGridPositionToManagement(ulong ticket, int grid_id, int level, double unified_sl, double unified_tp)
{
    if(!PositionSelectByTicket(ticket)) return;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    double volume = PositionGetDouble(POSITION_VOLUME);
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    
    // Note: SL/TP are already set during PositionOpen, but we verify here
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    
    // Ensure unified SL/TP if not already set correctly
    if(MathAbs(current_sl - unified_sl) > Point * 5 || MathAbs(current_tp - unified_tp) > Point * 5)
    {
        trade.PositionModify(symbol, unified_sl, unified_tp);
    }
    
    // Add to managed positions
    int new_index = ArraySize(managed_positions);
    ArrayResize(managed_positions, new_index + 1);
    
    managed_positions[new_index].ticket = ticket;
    managed_positions[new_index].open_time = (datetime)PositionGetInteger(POSITION_TIME);
    managed_positions[new_index].breakeven_applied = false;
    managed_positions[new_index].is_managed = true;
    managed_positions[new_index].original_sl = unified_sl;
    managed_positions[new_index].original_tp = unified_tp;
    managed_positions[new_index].risk_amount = CalculateRiskAmount(symbol, volume, open_price, unified_sl);
    managed_positions[new_index].grid_id = grid_id;
    managed_positions[new_index].grid_level = level;
    managed_positions[new_index].is_grid_master = false;
}

//+------------------------------------------------------------------+
//| Calculate SL/TP for grid position                              |
//+------------------------------------------------------------------+
void CalculateGridSLTP(int grid_id, int level, string symbol, double entry_price, ENUM_POSITION_TYPE pos_type, double& sl, double& tp)
{
    double pip_value = GetPipValue(symbol);
    
    switch(GridManagementMethod)
    {
        case 1: // Individual
            if(pos_type == POSITION_TYPE_BUY)
            {
                sl = entry_price - (StopLossPips * pip_value);
                tp = entry_price + (TakeProfitPips * pip_value);
            }
            else
            {
                sl = entry_price + (StopLossPips * pip_value);
                tp = entry_price - (TakeProfitPips * pip_value);
            }
            break;
            
        case 2: // Combined
            // Calculate average entry price of all grid positions
            double avg_entry = CalculateGridAverageEntry(grid_id);
            if(pos_type == POSITION_TYPE_BUY)
            {
                sl = avg_entry - ((StopLossPips + CombinedSLOffset) * pip_value);
                tp = avg_entry + (TakeProfitPips * pip_value);
            }
            else
            {
                sl = avg_entry + ((StopLossPips + CombinedSLOffset) * pip_value);
                tp = avg_entry - (TakeProfitPips * pip_value);
            }
            break;
            
        case 3: // Tiered
            int adjustment = (level - 1) * TieredSLAdjustPips;
            if(pos_type == POSITION_TYPE_BUY)
            {
                sl = entry_price - ((StopLossPips + adjustment) * pip_value);
                tp = entry_price + (TakeProfitPips * pip_value);
            }
            else
            {
                sl = entry_price + ((StopLossPips + adjustment) * pip_value);
                tp = entry_price - (TakeProfitPips * pip_value);
            }
            break;
    }
}

//+------------------------------------------------------------------+
//| Calculate average entry price for grid                         |
//+------------------------------------------------------------------+
double CalculateGridAverageEntry(int grid_id)
{
    double total_weighted_price = 0;
    double total_volume = 0;
    
    for(int i = 0; i < ArraySize(managed_positions); i++)
    {
        if(managed_positions[i].grid_id == grid_id)
        {
            ulong ticket = managed_positions[i].ticket;
            if(PositionSelectByTicket(ticket))
            {
                double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
                double volume = PositionGetDouble(POSITION_VOLUME);
                
                total_weighted_price += entry_price * volume;
                total_volume += volume;
            }
        }
    }
    
    return (total_volume > 0) ? total_weighted_price / total_volume : 0;
}

//+------------------------------------------------------------------+
//| Apply grid management to all positions in grid                 |
//+------------------------------------------------------------------+
void ApplyGridManagement(int grid_index)
{
    if(grid_index < 0 || grid_index >= ArraySize(grid_systems)) return;
    if(GridManagementMethod != 2) return; // Only for combined management
    
    GridSystem& grid = grid_systems[grid_index];
    double avg_entry = CalculateGridAverageEntry(grid.grid_id);
    if(avg_entry == 0) return;
    
    // Update all positions in this grid with new combined SL/TP
    for(int i = 0; i < ArraySize(managed_positions); i++)
    {
        if(managed_positions[i].grid_id == grid.grid_id)
        {
            ulong ticket = managed_positions[i].ticket;
            if(PositionSelectByTicket(ticket))
            {
                string symbol = PositionGetString(POSITION_SYMBOL);
                ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double pip_value = GetPipValue(symbol);
                
                double new_sl, new_tp;
                if(pos_type == POSITION_TYPE_BUY)
                {
                    new_sl = avg_entry - ((StopLossPips + CombinedSLOffset) * pip_value);
                    new_tp = avg_entry + (TakeProfitPips * pip_value);
                }
                else
                {
                    new_sl = avg_entry + ((StopLossPips + CombinedSLOffset) * pip_value);
                    new_tp = avg_entry - (TakeProfitPips * pip_value);
                }
                
                trade.PositionModify(symbol, new_sl, new_tp);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Clean up grid system                                           |
//+------------------------------------------------------------------+
void CleanupGridSystem(int grid_index)
{
    if(grid_index < 0 || grid_index >= ArraySize(grid_systems)) return;
    
    GridSystem& grid = grid_systems[grid_index];
    
    Print("Grid system ", grid.grid_id, " cleaned up - master position closed");
    
    // Remove from array
    for(int i = grid_index; i < ArraySize(grid_systems) - 1; i++)
    {
        grid_systems[i] = grid_systems[i + 1];
    }
    ArrayResize(grid_systems, ArraySize(grid_systems) - 1);
}

//+------------------------------------------------------------------+