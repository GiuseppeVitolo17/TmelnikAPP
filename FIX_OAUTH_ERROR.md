# Risoluzione Errore OAuth Firebase

## Errore: "Error 401: invalid_client - The OAuth client was not found"

Questo errore si verifica quando Firebase CLI non riesce a trovare il client OAuth corretto.

## Soluzione 1: Reimpostare il progetto Firebase

```bash
# 1. Logout completo
firebase logout

# 2. Rimuovi la configurazione del progetto (temporaneamente)
mv .firebaserc .firebaserc.backup

# 3. Login di nuovo
firebase login

# 4. Seleziona/crea il progetto
firebase init

# Oppure se il progetto esiste già:
firebase use --add
# Seleziona: tmelnikapp

# 5. Ripristina la configurazione
mv .firebaserc.backup .firebaserc
```

## Soluzione 2: Usa un progetto Firebase diverso

Se il progetto `tmelnikapp` non è configurato correttamente:

1. Vai su: https://console.firebase.google.com
2. Verifica che il progetto `tmelnikapp` esista
3. Se non esiste, crealo
4. Poi esegui:
   ```bash
   firebase use --add
   ```
   E seleziona il progetto corretto

## Soluzione 3: Reinstallare Firebase CLI

```bash
# Disinstalla
npm uninstall -g firebase-tools

# Reinstalla
npm install -g firebase-tools

# Login
firebase login
```

## Soluzione 4: Verifica permessi progetto

1. Vai su: https://console.firebase.google.com/project/tmelnikapp/settings/general
2. Verifica che tu sia Owner/Admin del progetto
3. Se non lo sei, chiedi a chi ha creato il progetto di aggiungerti

## Soluzione 5: Usa login alternativo

```bash
# Prova con un account diverso
firebase login --no-localhost
# Questo ti darà un URL da aprire manualmente
```

## Dopo aver risolto

Una volta completato il login, verifica:

```bash
firebase projects:list
firebase use tmelnikapp
```

Poi puoi procedere con il deploy:

```bash
./QUICK_DEPLOY.sh
```

