# 🔧 Fix Google Client ID Error 400

## ❌ **Problema:**
Ricevi l'errore "400. This is an error" quando provi a fare login con Google.

## 🔍 **Causa:**
Il Google Client ID nel file `web/index.html` non corrisponde a quello configurato in Firebase Console.

## ✅ **SOLUZIONE:**

### **PASSO 1: Ottieni il Client ID Corretto**

1. **Vai su Firebase Console:**
   - Apri: https://console.firebase.google.com/
   - Seleziona il progetto: `tmelnikapp`

2. **Apri Project Settings:**
   - Clicca sull'icona ⚙️ (Settings) in alto a sinistra
   - Seleziona "Project settings"

3. **Trova il Web Client ID:**
   - Scorri fino a "Your apps"
   - Cerca la sezione "Web app" (icona `</>`)
   - **COPIA** il "Web client ID" completo
   - Dovrebbe iniziare con: `950924265668-`
   - E finire con: `.apps.googleusercontent.com`

### **PASSO 2: Aggiorna il File HTML**

1. **Apri il file:** `web/index.html`

2. **Trova questa riga:**
   ```html
   <meta name="google-signin-client_id" content="950924265668-PASTE_YOUR_REAL_CLIENT_ID_HERE.apps.googleusercontent.com">
   ```

3. **Sostituisci** `PASTE_YOUR_REAL_CLIENT_ID_HERE` con il Client ID che hai copiato

   **Esempio:**
   ```html
   <meta name="google-signin-client_id" content="950924265668-abc123def456ghi789jkl.apps.googleusercontent.com">
   ```

### **PASSO 3: Riavvia l'App**

1. **Ferma l'app** (Ctrl+C nel terminale)

2. **Riavvia:**
   ```bash
   ./run_firebase_google.sh
   ```

3. **Prova di nuovo** il login con Google

## 🚨 **IMPORTANTE:**

- **NON** cambiare il numero `950924265668` - è il Project Number
- **SOSTITUISCI** solo la parte `PASTE_YOUR_REAL_CLIENT_ID_HERE`
- Il Client ID completo deve essere **esattamente** quello di Firebase Console

## 🔍 **Come Verificare:**

Se il Client ID è corretto, vedrai:
- ✅ Popup di Google Sign-In si apre
- ✅ Puoi selezionare il tuo account Google
- ✅ Login avviene con successo

Se è sbagliato, vedrai:
- ❌ Errore 400
- ❌ Popup di errore di Google

## 📞 **Se Continui ad Avere Problemi:**

1. Verifica che Google Sign-In sia abilitato in Firebase Console:
   - Authentication → Sign-in method → Google → Abilitato

2. Controlla che il dominio sia autorizzato:
   - Authentication → Settings → Authorized domains
   - Assicurati che `localhost` sia nella lista

3. Verifica che il progetto abbia un nome e email di supporto:
   - Project Settings → General → Project details
