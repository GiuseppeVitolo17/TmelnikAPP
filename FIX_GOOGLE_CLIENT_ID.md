# 🔧 Fix Google Client ID Error 400

## ❌ **Problem:**
You get "400. This is an error" when trying to sign in with Google.

## 🔍 **Cause:**
The Google Client ID in `web/index.html` does not match the one configured in Firebase Console.

## ✅ **Solution:**

### **STEP 1: Get the correct Client ID**

1. **Open Firebase Console:**
   - Go to: https://console.firebase.google.com/
   - Select project: `tmelnikapp`

2. **Open Project Settings:**
   - Click the ⚙️ (Settings) icon
   - Select "Project settings"

3. **Find the Web Client ID:**
   - Scroll to "Your apps"
   - Locate the "Web app" (icon `</>`)
   - **COPY** the full "Web client ID"
   - It should start with `950924265668-`
   - And end with `.apps.googleusercontent.com`

### **STEP 2: Update the HTML file**

1. **Open:** `web/index.html`

2. **Find this line:**
   ```html
   <meta name="google-signin-client_id" content="950924265668-PASTE_YOUR_REAL_CLIENT_ID_HERE.apps.googleusercontent.com">
   ```

3. **Replace** `PASTE_YOUR_REAL_CLIENT_ID_HERE` with the Client ID you copied

   **Example:**
   ```html
   <meta name="google-signin-client_id" content="950924265668-abc123def456ghi789jkl.apps.googleusercontent.com">
   ```

### **STEP 3: Restart the app**

1. **Stop the app** (Ctrl+C in the terminal)

2. **Restart:**
   ```bash
   ./run_firebase_google.sh
   ```

3. **Try signing in with Google again**

## 🚨 **IMPORTANT:**

- **DO NOT** change the `950924265668` number — it's the Project Number
- **REPLACE** only the `PASTE_YOUR_REAL_CLIENT_ID_HERE` part
- The full Client ID must be **exactly** the one from Firebase Console

## 🔍 **How to verify:**

If the Client ID is correct, you will see:
- ✅ Google Sign-In popup opens
- ✅ You can select your Google account
- ✅ Sign-in succeeds

If it’s wrong, you will see:
- ❌ Error 400
- ❌ Google error popup

## 📞 **If problems persist:**

1. Verify Google Sign-In is enabled in Firebase Console:
   - Authentication → Sign-in method → Google → Enabled

2. Check authorized domains:
   - Authentication → Settings → Authorized domains
   - Ensure `localhost` is in the list

3. Ensure the project has a name and support email:
   - Project Settings → General → Project details
