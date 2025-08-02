# Manual Trade Manager EA v2.0 - Documentatie

## Overzicht

De Manual Trade Manager EA is een geavanceerde MT5 Expert Advisor die automatisch handmatig geopende trades beheert met intelligente grid-functionaliteit. De EA detecteert trades die je vanaf je telefoon opent en kan automatisch extra grid entries plaatsen met volledige trade management.

## Hoofdfuncties

### 🎯 Automatische Trade Detectie
- Detecteert handmatig geopende trades van alle currency pairs
- Werkt met trades geopend vanaf MT5 mobile app
- Meerdere trades kunnen tegelijkertijd beheerd worden zonder conflict

### 🔥 **NIEUW: Intelligent Range Averaging System**
- **Price Trigger Entries**: EA plaatst automatisch market orders wanneer prijs tegen je in beweegt
- **Unified Stop Loss**: Alle grid entries krijgen exact dezelfde SL als originele trade
- **3 Lot Size Methoden**: Fixed Ratio, Fixed Amount, of Custom Weights
- **Range Protection**: Voorkomt front-running door entries te spreiden over range

### 📊 Trade Management Features
- **Stop Loss & Take Profit**: Vaste pip-waarden (instelbaar)
- **Breakeven Functie**: Verplaatst SL naar breakeven na X R profit
- **Trailing Stop**: Optionele trailing stop functionaliteit
- **Risk Management**: Controleert trade grootte en risico percentage
- **Grid Management**: Intelligent beheer van alle grid entries

## Installatie & Setup

### 1. Installatie
1. Plaats `ManualTradeManager.mq5` in de `MQL5/Experts/` folder van je MT5
2. Open het bestand in MetaEditor
3. Compileer met F7 of via menu: Compile
4. Sluit MetaEditor

### 2. Activatie
1. Open MT5 terminal (VPS aanbevolen voor 24/7 werking)
2. Sleep de EA vanaf Navigator naar een willekeurige chart
3. Configureer de instellingen (zie hieronder)
4. Zet "Allow live trading" aan
5. Klik OK

### 3. VPS Setup (Aanbevolen)
- Upload de EA naar je VPS
- Zorg dat MT5 op VPS constant draait
- Synchroniseer je account tussen mobile en VPS
- EA draait 24/7 en beheert alle nieuwe trades

## Parameter Instellingen

### Basic Settings
```
EnableEA = true                    // EA aan/uit schakelaar
StopLossPips = 50                  // Stop Loss in pips
TakeProfitPips = 100               // Take Profit in pips
```

### Breakeven Settings
```
EnableBreakeven = true             // Breakeven functie aan/uit
BreakevenTriggerR = 1.0           // Trigger na X R profit (1.0 = 1:1)
BreakevenOffsetPips = 5           // Offset boven/onder breakeven (veiligheidsmarge)
```

### Trailing Stop Settings
```
EnableTrailingStop = false        // Trailing stop aan/uit
TrailingStartPips = 20           // Start trailing na X pips profit
TrailingStepPips = 10            // Verplaats SL per X pips beweging
```

### Range Averaging Settings
```
EnableGridSystem = true          // Range averaging systeem aan/uit
GridSpacingPips = 50            // Afstand tussen trigger levels in pips
MaxGridLevels = 3               // Maximum aantal entries (inclusief handmatige entry)
```

### Lot Size Configuration
```
GridLotSizeMethod = 1           // 1=Fixed Ratio, 2=Fixed Amount, 3=Custom Weights
FixedRatio = 0.8               // Ratio per level (method 1): 1.0 → 0.8 → 0.64
FixedAmount = 0.1              // Vaste lot size voor alle levels (method 2)
CustomWeight2 = 30.0           // Level 2 percentage van handmatige entry (method 3)
CustomWeight3 = 20.0           // Level 3 percentage van handmatige entry (method 3)
```

### Risk Management
```
EnableRiskManagement = true       // Risk management aan/uit
MaxRiskPercent = 2.0             // Maximum risico per trade (% van account)
MaxLotSize = 1.0                 // Maximum lot grootte
```

### Advanced Settings
```
MagicNumber = 0                   // Magic number voor handmatige trades (houd op 0)
ManageOnlyNewTrades = true        // Beheer alleen trades na EA start
```

## Gebruiksinstructies

### Dagelijkse Workflow
1. **Start EA op VPS**: Zorg dat EA actief is op je VPS
2. **Open Trade op Telefoon**: Gebruik MT5 mobile app voor trade entry
3. **Automatisch Range Setup**: EA detecteert trade en berekent trigger prices
4. **Price Monitoring**: EA monitort continu of trigger levels worden geraakt
5. **Market Entry Execution**: Bij trigger → onmiddellijke market order met unified SL
5. **Monitor via Mobile**: Volg trade progress via telefoon
6. **Automatische Exit**: Trades worden gesloten bij SL, TP of handmatige sluiting

## 🔥 Range Averaging System Functionaliteit

### Hoe het Range Averaging Werkt

**Voorbeeld Short Trade:**
```
1. Handmatige Entry: 112.650 (0.5 lot, SL @ 112.700)
2. Prijs stijgt naar 112.700 → TRIGGER → Market Short @ 112.700 (0.4 lot, SL @ 112.700)
3. Prijs stijgt naar 112.750 → TRIGGER → Market Short @ 112.750 (0.32 lot, SL @ 112.700)
```

**Voorbeeld Long Trade:**
```
1. Handmatige Entry: 112.650 (0.5 lot, SL @ 112.600)
2. Prijs daalt naar 112.600 → TRIGGER → Market Long @ 112.600 (0.4 lot, SL @ 112.600)
3. Prijs daalt naar 112.550 → TRIGGER → Market Long @ 112.550 (0.32 lot, SL @ 112.600)
```

### ✅ **Voordelen van Price Triggers:**
- **Geen Front-running**: Orders worden pas geplaatst bij daadwerkelijke prijs beweging
- **Unified Risk**: Alle entries hebben exact dezelfde stop loss
- **Real Range Coverage**: Entries worden alleen genomen als prijs echt die levels raakt
- **Market Execution**: Onmiddellijke fills, geen slippage bij limit orders

### Grid Lot Size Methoden

#### **Method 1: Fixed Ratio (Aanbevolen)**
- Level 1: 0.5 lot (handmatige entry)
- Level 2: 0.5 × 0.8 = 0.4 lot
- Level 3: 0.4 × 0.8 = 0.32 lot
- **Voordeel**: Proportionele verdeling, minder risico op hogere levels

#### **Method 2: Fixed Amount**
- Level 1: Originele lot size (handmatig)
- Level 2: 0.1 lot (vast)
- Level 3: 0.1 lot (vast)
- **Voordeel**: Predictable lot sizes

#### **Method 3: Custom Weights**
- Level 1: 50% van totaal planned (handmatig)
- Level 2: 30% van handmatige entry
- Level 3: 20% van handmatige entry
- **Voordeel**: Volledige controle over verdeling

### Range Trigger System

#### **Price Monitoring:**
- EA monitort continu de marktprijs
- Trigger levels worden berekend op basis van GridSpacingPips
- Wanneer prijs trigger level raakt → onmiddellijke market order

#### **Unified Stop Loss Management:**
- **Alle entries krijgen exact dezelfde SL** als de originele handmatige trade
- **Geen aparte SL berekening** per level
- **Consistent risico** over alle entries in de range

#### **Smart Execution:**
- **Real-time triggers**: Alleen wanneer prijs daadwerkelijk beweegt
- **Market orders**: Onmiddellijke fills, geen wachten
- **No front-running**: Orders worden niet vooraf geplaatst

### Breakeven Functionaliteit
- **Trigger**: Wanneer trade X R profit heeft (standaard 1R)
- **Actie**: SL wordt verplaatst naar entry price + offset
- **Voordeel**: Trade wordt risicovrij, kan niet meer verlies maken
- **Voorbeeld**: Trade met 50 pip SL, bij 50 pip profit → SL naar breakeven + 5 pips

### Trailing Stop Werking
- **Activatie**: Alleen bij voldoende profit (TrailingStartPips)
- **Beweging**: SL volgt prijs met TrailingStepPips afstand
- **Richting**: SL beweegt alleen in gunstige richting
- **Voordeel**: Maximaliseert profit bij sterke trends

## Technical Details

### Trade Detectie Methode
```mql5
// EA detecteert handmatige trades via:
- Magic Number = 0 (handmatige trades)
- Position Reason ≠ 3 (niet door EA geopend)
- Timestamp controle (alleen nieuwe trades)
```

### Position Tracking
- EA houdt lijst bij van beheerde trades
- Elke trade krijgt unieke tracking ID
- Status wordt bijgehouden (breakeven toegepast, etc.)
- Automatische cleanup bij gesloten trades

### Risk Calculation
```
Risk Amount = (Entry Price - Stop Loss) × Lot Size × Pip Value
Risk Percentage = Risk Amount / Account Balance × 100
```

## Veiligheidsfeatures

### 1. Duplicate Protection
- EA voorkomt dubbel management van dezelfde trade
- Controleert of trade al onder beheer staat
- Unieke tracking per position ticket

### 2. Error Handling
- Validatie van alle trade modificaties
- Logging van fouten en succesvolle acties
- Graceful handling van verbindingsproblemen

### 3. Account Protection
- Maximum risico controle per trade
- Lot size beperkingen
- Waarschuwingen bij grote risico's

## Troubleshooting

### Veelvoorkomende Problemen

#### EA detecteert trades niet
**Oplossing:**
- Controleer of "Allow live trading" aan staat
- Verificeer dat MagicNumber op 0 staat
- Check of ManageOnlyNewTrades correct is ingesteld

#### SL/TP worden niet toegepast
**Oplossing:**
- Controleer broker's minimum stop level
- Verificeer spread tijdens trade opening
- Check MT5 terminal logging voor foutmeldingen

#### Breakeven werkt niet
**Oplossing:**
- Controleer BreakevenTriggerR instelling
- Verificeer dat EnableBreakeven = true
- Check of trade voldoende profit heeft

#### Conflicten tussen trades
**Oplossing:**
- EA beheert elke trade individueel
- Geen actie vereist, dit is normaal gedrag
- Elke trade heeft eigen SL/TP management

### Logging & Monitoring
```
// EA logs naar MT5 Experts tab:
- Trade detectie berichten
- Succesvol toegepaste management
- Breakeven activatie
- Risk management waarschuwingen
- Error berichten met details
```

## Performance Tips

### Optimale Setup
1. **VPS Gebruik**: 24/7 uptime voor consistent management
2. **Lage Latency**: Kies VPS dicht bij broker server
3. **Stabiele Verbinding**: Vermijd frequente disconnecties
4. **Clean Installation**: Gebruik dedicated MT5 installatie voor EA

### Best Practices
1. **Test eerst op Demo**: Valideer instellingen voor live gebruik
2. **Start Klein**: Begin met kleine lot sizes
3. **Monitor Resultaten**: Houd performance bij
4. **Regelmatige Updates**: Check EA status dagelijks
5. **Backup Settings**: Bewaar optimale parameter configuraties

## Version History

### v2.0 (Huidige Versie)
- **NIEUW: Range Averaging System** met price trigger entries
- **NIEUW: Unified Stop Loss** - alle entries krijgen zelfde SL
- **NIEUW: Market Order Execution** bij price triggers
- **NIEUW: 3 Lot Size Methoden** (Fixed Ratio, Fixed Amount, Custom Weights)
- Automatische detectie handmatige trades
- Configureerbare SL/TP in pips
- Breakeven functionaliteit met R-multiple trigger
- Optionele trailing stop
- Risk management controles
- Multi-pair ondersteuning
- VPS geoptimaliseerd

### v1.0 (Vorige Versie)
- Basis trade management functionaliteit
- Eenvoudige SL/TP management
- Breakeven en trailing stop

## Support & Contact

Voor vragen, bugs of feature requests:
- Check eerst deze documentatie
- Test op demo account
- Documenteer specifieke foutmeldingen
- Include parameter instellingen bij support aanvragen

## Disclaimer

Deze EA is ontwikkeld voor educatieve en ondersteunende doeleinden. Trading forex brengt altijd risico's met zich mee. Test altijd grondig op demo accounts voordat je live gaat. De ontwikkelaar is niet verantwoordelijk voor trading verliezen.

---

**Laatste Update**: 2025-01-02  
**Versie**: 2.0  
**Compatibiliteit**: MT5 Build 4000+