# Deploy Email Functions - Step by Step Guide

## Prerequisites Installation

### 1. Install Node.js (if not already installed)

**On macOS:**
```bash
# Using Homebrew (recommended)
brew install node

# Or download from https://nodejs.org/
```

**Verify installation:**
```bash
node --version  # Should show v18.x or higher
npm --version   # Should show 9.x or higher
```

### 2. Install Firebase CLI

```bash
npm install -g firebase-tools
```

**Verify installation:**
```bash
firebase --version
```

### 3. Login to Firebase

```bash
firebase login
```

This will open a browser for authentication.

### 4. Select Firebase Project

```bash
firebase use --add
```

Select your project: `tmelnikapp` (or your project name)

## Setup Email Functions

### Step 1: Install Dependencies

```bash
cd functions
npm install
cd ..
```

### Step 2: Configure Email Credentials

**For Gmail (Recommended for Testing):**

1. Enable 2-factor authentication on your Google Account:
   - Go to: https://myaccount.google.com/security
   - Enable "2-Step Verification"

2. Generate App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Other (Custom name)"
   - Enter "Tmelnik Functions" as name
   - Copy the generated 16-character password

3. Configure Firebase Functions:

```bash
firebase functions:config:set email.user="your-email@gmail.com"
firebase functions:config:set email.pass="xxxx xxxx xxxx xxxx"
firebase functions:config:set email.from="noreply@tmelnikapp.com"
firebase functions:config:set email.service="gmail"
```

**Verify configuration:**
```bash
firebase functions:config:get
```

### Step 3: Deploy Functions

```bash
firebase deploy --only functions
```

This will deploy both functions:
- `onApplicationCreated`
- `onApplicationStatusUpdated`

**Deploy output should show:**
```
✔  functions[onApplicationCreated(firestore)] Successful create operation.
✔  functions[onApplicationStatusUpdated(firestore)] Successful create operation.
```

### Step 4: Verify Deployment

```bash
# List deployed functions
firebase functions:list

# View logs
firebase functions:log
```

## Testing

1. **Create a test application** in the app
2. **Check logs:**
   ```bash
   firebase functions:log --only onApplicationCreated
   ```
3. **Verify emails** are sent to:
   - Organizer email (if NGO is associated)
   - Applicant email (confirmation)

## Troubleshooting

### Functions not deploying
- Check Firebase project: `firebase projects:list`
- Verify billing is enabled (required for Cloud Functions)
- Check logs: `firebase functions:log`

### Emails not sending
- Verify email credentials: `firebase functions:config:get`
- Check function logs for errors
- Test email credentials manually
- Check spam folder

### Authentication errors
- For Gmail: Use App Password, not regular password
- Verify 2FA is enabled
- Check email/user are correct

## Quick Commands Reference

```bash
# Install dependencies
cd functions && npm install && cd ..

# Configure email
firebase functions:config:set email.user="..." email.pass="..." email.from="..."

# Deploy
firebase deploy --only functions

# View logs
firebase functions:log

# Delete config (if needed)
firebase functions:config:unset email
```

## Next Steps After Deployment

1. Test with a real application in the app
2. Monitor function logs for the first few emails
3. Check email deliverability
4. Consider upgrading to SendGrid for production (better deliverability, higher limits)

