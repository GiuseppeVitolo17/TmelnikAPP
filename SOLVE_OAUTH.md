# 🔧 Risoluzione Errore OAuth Firebase

## Problema: "Error 401: invalid_client - The OAuth client was not found"

Questo errore significa che Firebase CLI non riesce a trovare il progetto o il client OAuth non è configurato.

## ✅ Soluzione Step-by-Step

### Passo 1: Verifica che il progetto esista

1. **Vai su Firebase Console:**
   - Apri: https://console.firebase.google.com
   - Accedi con il tuo account Google: `giuseppevitolopokemon@gmail.com`

2. **Controlla se il progetto `tmelnikapp` esiste:**
   - Se NON esiste, crealo cliccando "Add project"
   - Nome progetto: `tmelnikapp`
   - Segui la procedura di creazione

### Passo 2: Se il progetto esiste, verifica i permessi

1. Vai su: https://console.firebase.google.com/project/tmelnikapp/settings/iam
2. Verifica di essere **Owner** o **Editor** del progetto
3. Se non lo sei, chiedi a chi ha creato il progetto di aggiungerti

### Passo 3: Reimposta la configurazione locale

Nel terminale, esegui:

```bash
cd /Users/giuseppe/TmelnikAPP

# Rimuovi temporaneamente la configurazione
mv .firebaserc .firebaserc.backup

# Prova login di nuovo
firebase login

# Se il login funziona, inizializza il progetto
firebase init

# Scegli:
# - Firestore: Yes
# - Functions: Yes (se vuoi deployare le email functions)
# - Storage: No (o Yes se serve)
# - Hosting: No (già configurato)
# - Seleziona il progetto: tmelnikapp
```

### Passo 4: Se il progetto NON esiste, crealo

1. Vai su: https://console.firebase.google.com
2. Clicca "Add project" o "Create a project"
3. Nome: `tmelnikapp`
4. Segui la procedura guidata
5. **IMPORTANTE:** Abilita Firestore e Storage durante la creazione

### Passo 5: Dopo aver creato/configurato il progetto

```bash
# Login
firebase login

# Seleziona il progetto
firebase use --add
# Scegli: tmelnikapp

# Verifica
firebase projects:list
```

## Alternativa: Usa un progetto esistente

Se hai già un progetto Firebase esistente con un nome diverso:

```bash
firebase use --add
# Seleziona il progetto esistente dalla lista
```

Poi aggiorna `.firebaserc` se necessario.

## Verifica finale

Dopo aver risolto, verifica:

```bash
firebase projects:list
firebase use tmelnikapp
firebase projects:list
```

Dovresti vedere `tmelnikapp` nella lista.

## Poi procedi con il deploy

```bash
./QUICK_DEPLOY.sh
```

