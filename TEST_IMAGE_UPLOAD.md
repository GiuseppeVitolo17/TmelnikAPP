# Test Image Upload - FireCMS

## Verifica funzionamento upload immagini

Per testare se il caricamento immagini funziona correttamente:

### 1. Test tramite FireCMS Web Interface

1. Vai su [FireCMS](https://app.firecms.co/p/tmelnikapp)
2. Accedi al CMS
3. Vai alla collection **"Users"**
4. Seleziona un utente
5. Prova a caricare un'immagine nel campo profilo (se presente)
6. Verifica che l'upload funzioni

### 2. Test tramite App Mobile

1. Apri l'app sul dispositivo
2. Vai al **Profile** (icona persona in alto a destra)
3. Tocca l'icona **camera** sull'avatar
4. Seleziona un'immagine dalla **galleria**
5. Verifica che:
   - L'immagine venga caricata
   - Venga mostrato un indicatore di progresso
   - L'immagine appaia nell'avatar dopo il caricamento

### 3. Verifica Firebase Storage Rules

Se l'upload fallisce, verifica le regole di Storage:

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona progetto `tmelnikapp`
3. Vai su **Storage** → **Rules**
4. Verifica che le regole siano configurate come in `FIREBASE_STORAGE_RULES.md`

### 4. Codici di Errore Possibili

Se vedi errori nell'app, controlla i codici:

**RSS Feed Errors:**
- `RSS_ERR_TIMEOUT`: Timeout durante il fetch del feed
- `RSS_ERR_NETWORK`: Errore di rete
- `RSS_ERR_HTTP`: Errore HTTP (status code non 200)
- `RSS_ERR_PARSE`: Errore durante il parsing XML
- `RSS_ERR_FETCH_TIMEOUT`: Timeout durante fetch Instagram
- `RSS_ERR_FETCH_HTTP`: Errore HTTP durante fetch
- `RSS_ERR_FETCH_NETWORK`: Errore di rete durante fetch
- `RSS_ERR_CACHE_FALLBACK`: Fallback alla cache fallito
- `RSS_ERR_NO_CACHE`: Nessuna cache disponibile

**News Screen Errors:**
- `NEWS_000`: Errore fatale
- `NEWS_001`: Errore durante fetch news
- `NEWS_003`: Errore durante post-processing

**Profile Image Errors:**
- `PROFILE_IMG_ERR_PICK`: Errore selezione immagine
- `PROFILE_IMG_ERR_RESIZE`: Errore resize/compressione
- `PROFILE_IMG_ERR_UPLOAD`: Errore upload Firebase Storage
- `PROFILE_IMG_ERR_PERMISSION`: Permessi negati
- `PROFILE_IMG_ERR_TIMEOUT`: Timeout upload

### 5. Debug Logs

Controlla i log dell'app per vedere i dettagli:
- `📤 [PROFILE_IMAGE]`: Log upload immagini
- `📰 [RSS]`: Log feed RSS
- `📊 [NEWS_SCREEN]`: Log schermata news
- `❌`: Errori
- `✅`: Successi
- `⚠️`: Warning
