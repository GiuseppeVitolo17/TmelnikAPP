Notification setup (FCM topic + Cloud Function)

Contents
- functions/index.js: Firestore onCreate function on `project_offers/{id}` that sends a data-only FCM message to the `projects` topic with `{ type: 'project_created', projectId }`.
- firebase.json, .firebaserc: example config targeting project `tmelnikapp`.
- functions/package.json: minimal deps (`firebase-admin`, `firebase-functions`) and Node 18 engine.

Deploy (best practices)
1) Requirements
   - Node 18 (nvm recommended)
   - Firebase CLI (`npm i -g firebase-tools`)

2) Select the project
   - Edit `.firebaserc` if needed (default: `tmelnikapp`).

3) Install deps and deploy
   ```bash
   cd notification_setup/functions
   npm install
   cd ..
   firebase use tmelnikapp
   firebase deploy --only functions
   ```

Client behavior
- The app subscribes to `projects`. When it receives `project_created` with `projectId`, it fetches the project from Firestore, generates the “catchy” text locally, and shows a local notification only in background.

Note
- No intrusive in-app popups; logs only in foreground.

