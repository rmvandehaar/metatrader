# Manual Trade Manager EA v2.0 - Documentatie

## Overzicht

De Manual Trade Manager EA is een geavanceerde MT5 Expert Advisor die automatisch handmatig geopende trades beheert met intelligente grid-functionaliteit. De EA detecteert trades die je vanaf je telefoon opent en kan automatisch extra grid entries plaatsen met volledige trade management.

## Hoofdfuncties

### 🎯 Automatische Trade Detectie
- Detecteert handmatig geopende trades van alle currency pairs
- Werkt met trades geopend vanaf MT5 mobile app
- Meerdere trades kunnen tegelijkertijd beheerd worden zonder conflict

### 🔥 **NIEUW: Intelligent Grid System**
- **Automatische Grid Entries**: EA plaatst automatisch 2 extra limit orders na handmatige entry
- **3 Lot Size Methoden**: Fixed Ratio, Fixed Amount, of Custom Weights
- **3 Timing Opties**: Immediate, Progressive (tijd-gebaseerd), of Price-based
- **3 Management Strategieën**: Individual, Combined (average entry), of Tiered

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

### Grid System Settings
```
EnableGridSystem = true          // Grid systeem aan/uit
GridSpacingPips = 50            // Afstand tussen grid levels in pips
MaxGridLevels = 3               // Maximum aantal grid levels (inclusief handmatige entry)
```

### Grid Lot Sizing
```
GridLotSizeMethod = 1           // 1=Fixed Ratio, 2=Fixed Amount, 3=Custom Weights
FixedRatio = 0.8               // Ratio per level (method 1): 1.0 → 0.8 → 0.64
FixedAmount = 0.1              // Vaste lot size voor alle levels (method 2)
CustomWeight2 = 30.0           // Grid level 2 percentage (method 3)
CustomWeight3 = 20.0           // Grid level 3 percentage (method 3)
```

### Grid Timing
```
GridTimingMethod = 1           // 1=Immediate, 2=Progressive, 3=Price-based
ProgressiveDelay = 5           // Vertraging tussen orders in seconden (method 2)
PriceBasedTriggerPips = 20     // Trigger afstand in pips (method 3)
```

### Grid Management
```
GridManagementMethod = 1       // 1=Individual, 2=Combined, 3=Tiered
CombinedSLOffset = 10         // SL offset van average entry (method 2)
TieredSLAdjustPips = 15       // SL aanpassing per level (method 3)
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
3. **Automatisch Grid Setup**: EA detecteert trade en plaatst automatisch grid orders
4. **Trade Management**: Alle entries krijgen automatisch SL/TP management
5. **Monitor via Mobile**: Volg trade progress via telefoon
6. **Automatische Exit**: Trades worden gesloten bij SL, TP of handmatige sluiting

## 🔥 Grid System Functionaliteit

### Hoe het Grid System Werkt

**Voorbeeld Short Trade:**
```
Handmatige Entry: 112.650 (0.5 lot) - Level 1
↓ +50 pips
Auto Grid Entry:  112.700 (0.4 lot) - Level 2 (limit order)
↓ +50 pips  
Auto Grid Entry:  112.750 (0.32 lot) - Level 3 (limit order)
```

**Voorbeeld Long Trade:**
```
Handmatige Entry: 112.650 (0.5 lot) - Level 1
↑ -50 pips
Auto Grid Entry:  112.600 (0.4 lot) - Level 2 (limit order)
↑ -50 pips
Auto Grid Entry:  112.550 (0.32 lot) - Level 3 (limit order)
```

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

### Grid Timing Methoden

#### **Method 1: Immediate (Standaard)**
- Grid orders worden direct na handmatige entry geplaatst
- **Voordeel**: Snelle setup, geen gemiste kansen

#### **Method 2: Progressive**
- Level 2: Na 5 seconden (instelbaar)
- Level 3: Na 10 seconden
- **Voordeel**: Gespreid plaatsen van orders

#### **Method 3: Price-based**
- Grid orders pas na X pips beweging (standaard 20 pips)
- **Voordeel**: Alleen plaatsen als markt al beweegt

### Grid Management Strategieën

#### **Method 1: Individual (Standaard)**
- Elke entry heeft eigen SL/TP
- SL Level 1: Entry - 50 pips
- SL Level 2: Entry - 50 pips
- SL Level 3: Entry - 50 pips
- **Voordeel**: Simpel, elke trade onafhankelijk

#### **Method 2: Combined**
- SL/TP gebaseerd op gemiddelde entry price
- Average entry wordt herberekend bij elke nieuwe fill
- **Voordeel**: Betere overall risk/reward

#### **Method 3: Tiered**
- SL wordt aangepast per level
- Level 1: Entry - 50 pips
- Level 2: Entry - 65 pips (50 + 15)
- Level 3: Entry - 80 pips (50 + 30)
- **Voordeel**: Meer ruimte voor verdere entries

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
- **NIEUW: Intelligent Grid System** met automatische extra entries
- **NIEUW: 3 Lot Size Methoden** (Fixed Ratio, Fixed Amount, Custom Weights)
- **NIEUW: 3 Timing Strategieën** (Immediate, Progressive, Price-based)
- **NIEUW: 3 Management Opties** (Individual, Combined, Tiered)
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