# Email Notifications Setup Guide

## Overview

This guide explains how to set up email notifications for project applications using Firebase Cloud Functions.

## Prerequisites

1. Firebase CLI installed: `npm install -g firebase-tools`
2. Firebase project with Cloud Functions enabled
3. Email service credentials (Gmail, SendGrid, Mailgun, etc.)

## Setup Steps

### 1. Install Firebase CLI and Login

```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize Functions (if not already done)

```bash
cd functions
npm install
```

### 3. Configure Email Credentials

#### Option A: Using Firebase Functions Config (Recommended)

```bash
firebase functions:config:set email.user="your-email@gmail.com"
firebase functions:config:set email.pass="your-app-password"
firebase functions:config:set email.from="noreply@tmelnikapp.com"
```

**For Gmail:**
- Enable 2-factor authentication
- Generate an "App Password" in Google Account settings
- Use the app password instead of your regular password

#### Option B: Using Environment Variables

Set environment variables in Firebase Console:
- Go to Firebase Console → Functions → Configuration
- Add: `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_FROM`

### 4. Deploy Functions

```bash
firebase deploy --only functions
```

### 5. Test Email Notifications

1. Create a test application in the app
2. Check Firebase Functions logs: `firebase functions:log`
3. Verify emails are sent to organizer and applicant

## Functions Created

### `onApplicationCreated`
- **Trigger:** When a new project application is created
- **Actions:**
  - Sends notification email to NGO organizers
  - Sends confirmation email to applicant

### `onApplicationStatusUpdated`
- **Trigger:** When application status changes
- **Actions:**
  - Sends status update email to applicant

## Email Service Alternatives

### SendGrid (Recommended for Production)

```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

await sgMail.send({
  to: email,
  from: 'noreply@tmelnikapp.com',
  subject: 'Subject',
  html: 'Body',
});
```

### Mailgun

```javascript
const formData = require('form-data');
const Mailgun = require('mailgun.js');
const mailgun = new Mailgun(formData);
const mg = mailgun.client({
  username: 'api',
  key: process.env.MAILGUN_API_KEY,
});

await mg.messages.create('your-domain.com', {
  from: 'noreply@tmelnikapp.com',
  to: email,
  subject: 'Subject',
  html: 'Body',
});
```

## Troubleshooting

### Emails not sending
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify email credentials are correct
3. Check spam folder
4. Verify Cloud Functions are deployed: `firebase functions:list`

### Gmail authentication errors
- Make sure 2FA is enabled
- Use App Password, not regular password
- Check that "Less secure app access" is not needed (use App Password instead)

### Function timeout
- Increase timeout in function definition:
  ```javascript
  .runWith({ timeoutSeconds: 540, memory: '256MB' })
  ```

## Security Notes

- Never commit email credentials to version control
- Use Firebase Functions config or environment variables
- Rotate credentials regularly
- Monitor email sending quotas

## Cost Considerations

- Firebase Cloud Functions: Free tier includes 2M invocations/month
- Email service: Check pricing for your provider
- Gmail: Free but has sending limits (500 emails/day)
- SendGrid: Free tier includes 100 emails/day

## Next Steps

1. Customize email templates in `functions/index.js`
2. Add more email templates (project updates, reminders, etc.)
3. Add email preferences per user
4. Implement email templates with HTML/CSS

