# 🔐 Come fare il Login Firebase

## Metodo 1: Comando diretto (Raccomandato)

Apri il terminale e esegui:

```bash
cd /Users/giuseppe/TmelnikAPP
firebase login
```

Questo comando aprirà **automaticamente** il browser (Chrome o quello di default) per l'autenticazione.

1. **Se il browser si apre automaticamente:**
   - Completa l'autenticazione Google
   - Autorizza Firebase CLI
   - Torna qui e dimmi "fatto"

2. **Se il browser NON si apre:**
   - Vai manualmente su: https://console.firebase.google.com
   - Accedi con il tuo account Google
   - Seleziona il progetto: **tmelnikapp**
   - Poi torna qui

## Metodo 2: Login tramite URL

Se il comando `firebase login` non funziona:

1. Apri Chrome manualmente
2. Vai su: https://console.firebase.google.com
3. Accedi con il tuo account Google
4. Seleziona il progetto: **tmelnikapp**
5. Poi esegui nel terminale:
   ```bash
   firebase login
   ```
   e completa l'autenticazione

## Verifica Login

Dopo il login, verifica con:

```bash
firebase projects:list
```

Dovresti vedere il progetto **tmelnikapp** nella lista.

## Dopo il Login

Una volta completato il login, esegui:

```bash
./QUICK_DEPLOY.sh
```

Questo script configurerà e deployerà le email functions automaticamente.

