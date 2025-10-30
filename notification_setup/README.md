Notification setup (FCM topic + Cloud Function)

Contenuto
- functions/index.js: function Firestore onCreate su `project_offers/{id}` che invia un messaggio FCM data-only al topic `projects` con `{ type: 'project_created', projectId }`.
- firebase.json, .firebaserc: config esempio per progetto `tmelnikapp`.
- functions/package.json: dipendenze minime (`firebase-admin`, `firebase-functions`) e engine Node 18.

Deploy (best practice)
1) Requisiti
   - Node 18 (consigliato nvm)
   - Firebase CLI (`npm i -g firebase-tools`)

2) Seleziona il progetto
   - Modifica `.firebaserc` se necessario (default: `tmelnikapp`).

3) Installa dipendenze e deploy
   ```bash
   cd notification_setup/functions
   npm install
   cd ..
   firebase use tmelnikapp
   firebase deploy --only functions
   ```

Funzionamento client
- L'app è iscritta a `projects`. Quando riceve `project_created` con `projectId`, recupera il progetto da Firestore, genera la frase “catchy” localmente e mostra una notifica locale solo in background.

Nota
- Nessun popup in-app a schermo; log in foreground.

