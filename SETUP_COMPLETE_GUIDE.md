# Tmelnik App - Complete Setup Guide

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Email Notifications Setup](#email-notifications-setup)
3. [Firebase Configuration](#firebase-configuration)
4. [Deployment](#deployment)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### 1. Node.js Installation

**macOS (using Homebrew):**
```bash
brew install node
```

**Verify:**
```bash
node --version  # Should be v18.x or higher
npm --version   # Should be 9.x or higher
```

**Alternative:** Download from https://nodejs.org/

### 2. Firebase CLI Installation

```bash
npm install -g firebase-tools
```

**Verify:**
```bash
firebase --version
```

### 3. Firebase Login

```bash
firebase login
```

This opens a browser for authentication. Complete the login process.

---

## Email Notifications Setup

### Step 1: Install Function Dependencies

```bash
cd functions
npm install
cd ..
```

### Step 2: Configure Email Service

#### Option A: Gmail (Recommended for Testing)

1. **Enable 2-Factor Authentication:**
   - Visit: https://myaccount.google.com/security
   - Enable "2-Step Verification"

2. **Generate App Password:**
   - Visit: https://myaccount.google.com/apppasswords
   - Select "Mail" → "Other (Custom name)"
   - Enter: "Tmelnik Functions"
   - Copy the 16-character password (format: `xxxx xxxx xxxx xxxx`)

3. **Configure Firebase Functions:**
   ```bash
   firebase functions:config:set \
     email.user="your-email@gmail.com" \
     email.pass="xxxx xxxx xxxx xxxx" \
     email.from="noreply@tmelnikapp.com" \
     email.service="gmail"
   ```

#### Option B: Custom SMTP Server

```bash
firebase functions:config:set \
  email.host="smtp.example.com" \
  email.port="587" \
  email.user="your-email@example.com" \
  email.pass="your-password" \
  email.from="noreply@tmelnikapp.com" \
  email.secure="false"
```

#### Option C: SendGrid (Recommended for Production)

1. Sign up at https://sendgrid.com
2. Create API Key with "Mail Send" permissions
3. Configure:
   ```bash
   firebase functions:config:set \
     email.service="sendgrid" \
     email.user="apikey" \
     email.pass="your-sendgrid-api-key" \
     email.from="noreply@tmelnikapp.com"
   ```

**Verify Configuration:**
```bash
firebase functions:config:get
```

### Step 3: Select Firebase Project

```bash
firebase use --add
```

Select: `tmelnikapp` (or your project name)

### Step 4: Deploy Functions

```bash
firebase deploy --only functions
```

**Expected Output:**
```
✔  functions[onApplicationCreated(firestore)] Successful create operation.
✔  functions[onApplicationStatusUpdated(firestore)] Successful create operation.
```

### Step 5: Verify Deployment

```bash
# List deployed functions
firebase functions:list

# View function logs
firebase functions:log
```

---

## Firebase Configuration

### Firestore Rules

Rules are already configured in `firestore.rules`. Deploy with:

```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes

Indexes are configured in `firestore.indexes.json`. Deploy with:

```bash
firebase deploy --only firestore:indexes
```

### Storage Rules

Storage rules are in `storage.rules`. Deploy with:

```bash
firebase deploy --only storage
```

---

## Deployment

### Deploy Everything

```bash
firebase deploy
```

### Deploy Specific Components

```bash
# Functions only
firebase deploy --only functions

# Firestore rules
firebase deploy --only firestore:rules

# Firestore indexes
firebase deploy --only firestore:indexes

# Storage rules
firebase deploy --only storage

# Hosting (if configured)
firebase deploy --only hosting
```

---

## Testing

### Test Email Notifications

1. **Create a test application** in the app:
   - Login as a user
   - Browse to a project
   - Click "Apply"

2. **Check Function Logs:**
   ```bash
   # Real-time logs
   firebase functions:log --only onApplicationCreated
   
   # All logs
   firebase functions:log
   ```

3. **Verify Emails:**
   - Check organizer email inbox
   - Check applicant email inbox
   - Check spam folder if not received

4. **Test Status Update:**
   - Change application status in app (as organizer)
   - Check function logs: `firebase functions:log --only onApplicationStatusUpdated`
   - Verify applicant receives status update email

---

## Troubleshooting

### Functions Not Deploying

**Issue:** `Error: HTTP Error: 403`
- **Solution:** Enable billing in Firebase Console
- Cloud Functions require billing to be enabled (Blaze plan)

**Issue:** `Error: Functions did not deploy properly`
- **Solution:** Check function logs: `firebase functions:log`
- Verify Node.js version: `node --version` (should be 18.x)

### Emails Not Sending

**Issue:** No emails received
- **Check logs:** `firebase functions:log`
- **Verify credentials:** `firebase functions:config:get`
- **Check spam folder**
- **Verify email addresses** are correct

**Issue:** Authentication failed
- **For Gmail:** Use App Password, not regular password
- **Verify 2FA** is enabled on Google Account
- **Check credentials** are correct

### Configuration Issues

**View current config:**
```bash
firebase functions:config:get
```

**Update config:**
```bash
firebase functions:config:set email.user="new-email@gmail.com"
```

**Remove config:**
```bash
firebase functions:config:unset email
```

---

## Quick Reference

### Essential Commands

```bash
# Login to Firebase
firebase login

# Select project
firebase use --add

# Install function dependencies
cd functions && npm install && cd ..

# Configure email
firebase functions:config:set email.user="..." email.pass="..."

# Deploy functions
firebase deploy --only functions

# View logs
firebase functions:log

# List functions
firebase functions:list
```

### Function URLs (if HTTP functions exist)

```bash
# Get function URL
firebase functions:config:get
```

---

## Security Notes

⚠️ **Important:**
- Never commit email credentials to Git
- Use Firebase Functions config or environment variables
- Rotate credentials regularly
- Monitor function logs for unauthorized access
- Use App Passwords for Gmail (not regular passwords)

---

## Cost Considerations

### Free Tier Limits
- **Cloud Functions:** 2M invocations/month
- **Firestore:** 50K reads/day, 20K writes/day
- **Storage:** 5GB storage, 1GB downloads/day

### Email Service Costs
- **Gmail:** Free (500 emails/day limit)
- **SendGrid:** Free tier (100 emails/day)
- **Production:** Consider SendGrid paid plans for higher limits

---

## Support

For issues:
1. Check function logs: `firebase functions:log`
2. Review Firebase Console → Functions → Logs
3. Check email service provider status
4. Verify configuration: `firebase functions:config:get`

---

## Next Steps

After successful deployment:

1. ✅ Test email notifications with real applications
2. ✅ Monitor function performance in Firebase Console
3. ✅ Set up email preferences per user (future enhancement)
4. ✅ Consider upgrading to SendGrid for production
5. ✅ Monitor costs in Firebase Console

---

**Last Updated:** December 2024

