# Firebase Storage Rules per Profile Images

## Regole di sicurezza consigliate

Per permettere agli utenti di caricare immagini profilo, aggiungi queste regole in Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images: users can only upload/delete their own profile image
    match /profile_images/{userId}.jpg {
      // Allow read to authenticated users
      allow read: if request.auth != null;
      
      // Allow write (create/update) only if:
      // 1. User is authenticated
      // 2. User is uploading their own image (userId matches auth.uid)
      // 3. File is JPEG and under 5MB
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.contentType == 'image/jpeg'
                   && request.resource.size < 5 * 1024 * 1024; // 5MB max
      
      // Allow delete only if user is deleting their own image
      allow delete: if request.auth != null
                    && request.auth.uid == userId;
    }
    
    // Deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Come applicare le regole

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il progetto `tmelnikapp`
3. Vai su **Storage** → **Rules**
4. Incolla le regole sopra
5. Clicca **Publish**

## Test delle regole

Dopo aver applicato le regole, prova a caricare un'immagine profilo dall'app. Se vedi ancora errori, controlla:
- Che l'utente sia autenticato
- Che il file sia JPEG
- Che il file sia sotto 5MB
- Che l'userId corrisponda all'utente autenticato
