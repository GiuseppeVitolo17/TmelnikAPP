# Analisi Approfondita: Problema Caricamento News RSS

## 🔍 Problemi Identificati

### 1. **Parsing XML Inefficiente**
- **Problema**: Il parsing usa regex multiple per ogni item (6-7 regex per item)
- **Impatto**: Ogni regex deve scansionare l'intero XML/item, molto costoso
- **Dettagli**:
  - `itemRegex` trova tutti gli item
  - Per ogni item: `titleMatch`, `linkMatch`, `pubDateMatch`, `descriptionMatch`
  - Poi: `mediaMatch`, `enclosureMatch`, `imgInDescriptionMatch`
  - Ogni regex viene eseguita anche se non necessaria

### 2. **Timeout Troppo Lungo**
- **Problema**: Timeout di 10 secondi per feed
- **Impatto**: L'app aspetta fino a 10 secondi prima di fallire
- **Dettagli**: Se un feed è lento, blocca l'intero processo

### 3. **Parsing di Troppi Item**
- **Problema**: Il parsing continua anche dopo aver trovato abbastanza item recenti
- **Impatto**: Processa item vecchi inutilmente
- **Dettagli**: Il feed può contenere centinaia di item, ma ne servono solo 30 recenti

### 4. **Troppi setState Durante Fetch**
- **Problema**: `onItemFound` callback chiama `setState` per ogni item
- **Impatto**: UI si aggiorna continuamente, causando lag
- **Dettagli**: Se arrivano 30 item, ci sono 30 setState consecutivi

### 5. **Pulizia Testo Costosa**
- **Problema**: `_cleanXmlText` viene chiamata 4 volte per item
- **Impatto**: Operazioni ripetute su ogni campo
- **Dettagli**: title, url, pubDate, description vengono tutti puliti

### 6. **Filtraggio Multiplo**
- **Problema**: Il filtro per data viene fatto 3 volte:
  1. Durante il parsing (in `_parseRssXml`)
  2. Dopo il parsing (in `_fetchErasmusFeed` e `_fetchInstagramFeed`)
  3. Dopo l'aggregazione (in `fetchAggregatedNews`)
- **Impatto**: Operazioni ridondanti

### 7. **Comparazione Cache Dopo Fetch**
- **Problema**: La comparazione con la cache avviene dopo aver già aggiunto tutti gli item
- **Impatto**: UI mostra item che poi vengono rimossi/aggiornati

## 🚀 Soluzioni Proposte

### 1. **Ottimizzare Parsing XML**
- Limitare il numero di item da parsare (es. primi 100)
- Fermare il parsing quando abbiamo abbastanza item recenti (30)
- Usare regex più efficienti o parsing XML nativo

### 2. **Ridurre Timeout**
- Ridurre da 10 a 5 secondi
- Fallback più rapido se un feed è lento

### 3. **Batch UI Updates**
- Raccogliere item in batch (es. ogni 5 item)
- Aggiornare UI solo ogni batch invece di ogni item

### 4. **Ottimizzare Pulizia Testo**
- Cache dei risultati di pulizia se possibile
- Pulire solo quando necessario

### 5. **Filtraggio Precoce**
- Filtrare durante il parsing, non dopo
- Evitare filtri multipli

### 6. **Lazy Loading Immagini**
- Non caricare immagini durante il parsing
- Caricare solo quando visibili

## 📊 Metriche Attuali vs Attese

**Attuale:**
- Tempo parsing: ~3-5 secondi per feed
- Item processati: ~100-200 per feed
- setState chiamati: ~30-60 durante fetch
- Timeout: 10 secondi

**Dopo Ottimizzazioni:**
- Tempo parsing: ~1-2 secondi per feed
- Item processati: ~30-50 per feed (solo recenti)
- setState chiamati: ~6-10 (batch di 5)
- Timeout: 5 secondi

## 🎯 Priorità Implementazione

1. **Alta**: Limitare parsing a item recenti e fermare quando raggiunto limite
2. **Alta**: Batch UI updates invece di setState per item
3. **Media**: Ridurre timeout a 5 secondi
4. **Media**: Limitare numero item da parsare (primi 100)
5. **Bassa**: Ottimizzare regex/pulizia testo
