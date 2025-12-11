# Email Notifications Setup Guide

## Overview

This guide explains how to set up email notifications for project applications using Firebase Cloud Functions.

**✅ Functions are already created and ready to deploy!**

## Quick Start (Automated Setup)

Run the setup script:

```bash
chmod +x setup_email_functions.sh
./setup_email_functions.sh
```

The script will:
- Check/install Firebase CLI
- Install function dependencies
- Guide you through email configuration
- Optionally deploy the functions

## Manual Setup Steps

### 1. Install Firebase CLI and Login

```bash
npm install -g firebase-tools
firebase login
```

### 2. Install Function Dependencies

```bash
cd functions
npm install
cd ..
```

### 3. Configure Email Credentials

#### Option A: Gmail (Easiest for Testing)

**Step 1:** Enable 2-factor authentication on your Google Account
- Go to: https://myaccount.google.com/security
- Enable "2-Step Verification"

**Step 2:** Generate App Password
- Go to: https://myaccount.google.com/apppasswords
- Select "Mail" and "Other (Custom name)"
- Enter "Tmelnik Functions" as name
- Copy the generated 16-character password

**Step 3:** Configure Firebase Functions

```bash
firebase functions:config:set email.user="your-email@gmail.com"
firebase functions:config:set email.pass="xxxx xxxx xxxx xxxx"  # Your app password
firebase functions:config:set email.from="noreply@tmelnikapp.com"
firebase functions:config:set email.service="gmail"
```

#### Option B: Custom SMTP Server

```bash
firebase functions:config:set email.host="smtp.example.com"
firebase functions:config:set email.port="587"
firebase functions:config:set email.user="your-email@example.com"
firebase functions:config:set email.pass="your-password"
firebase functions:config:set email.from="noreply@tmelnikapp.com"
firebase functions:config:set email.secure="false"
```

#### Option C: SendGrid (Recommended for Production)

1. Sign up at https://sendgrid.com
2. Create API Key with "Mail Send" permissions
3. Configure:

```bash
firebase functions:config:set email.service="sendgrid"
firebase functions:config:set email.user="apikey"
firebase functions:config:set email.pass="your-sendgrid-api-key"
firebase functions:config:set email.from="noreply@tmelnikapp.com"
```

**Note:** For SendGrid, you'll need to modify the transporter configuration to use SendGrid's API.

### 4. Deploy Functions

```bash
firebase deploy --only functions
```

**Deploy only specific functions:**
```bash
firebase deploy --only functions:onApplicationCreated
firebase deploy --only functions:onApplicationStatusUpdated
```

### 5. Verify Deployment

Check deployed functions:
```bash
firebase functions:list
```

### 6. Test Email Notifications

1. Create a test application in the app
2. Check Firebase Functions logs:
   ```bash
   firebase functions:log
   ```
3. View logs in real-time:
   ```bash
   firebase functions:log --only onApplicationCreated
   ```
4. Verify emails are sent to organizer and applicant
5. Test status update by changing application status in the app

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

