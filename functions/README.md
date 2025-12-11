# Tmelnik Email Functions

Firebase Cloud Functions for sending email notifications on project application events.

## Functions

### `onApplicationCreated`
**Trigger:** When a new project application is created in Firestore

**Actions:**
- Sends notification email to NGO organizers
- Sends confirmation email to applicant

**Fields Required in Application Document:**
- `userId` - User who applied
- `userEmail` - Applicant email
- `projectId` - Project offer ID
- `projectTitle` - Project title
- `ngoId` - NGO ID (optional)
- `appliedAt` - Timestamp
- `status` - Application status (default: "pending")

### `onApplicationStatusUpdated`
**Trigger:** When application status field is updated

**Actions:**
- Sends status update email to applicant

**Status Values:**
- `pending` - Initial status (orange badge)
- `accepted` - Application accepted (green badge)
- `rejected` - Application rejected (red badge)

## Configuration

Email configuration is done via Firebase Functions config:

```bash
firebase functions:config:set email.user="your-email@gmail.com"
firebase functions:config:set email.pass="your-password"
firebase functions:config:set email.from="noreply@tmelnikapp.com"
firebase functions:config:set email.service="gmail"
```

See `EMAIL_NOTIFICATIONS_SETUP.md` in project root for detailed setup instructions.

## Local Development

```bash
# Install dependencies
npm install

# Run emulator (requires Firebase CLI)
firebase emulators:start --only functions

# Run shell for testing
npm run shell
```

## Deployment

```bash
# Deploy all functions
npm run deploy

# Or using Firebase CLI
firebase deploy --only functions
```

## Testing

1. Create a test application in Firestore console or app
2. Check logs: `firebase functions:log`
3. Verify emails are sent

## Troubleshooting

- **Emails not sending:** Check Firebase Functions logs for errors
- **Authentication errors:** Verify email credentials are correct
- **Function timeout:** Increase timeout in function definition (currently 540s)
- **Rate limits:** Gmail has 500 emails/day limit; use SendGrid for production

## Cost Considerations

- Free tier: 2M function invocations/month
- Email service: Check provider pricing
- Recommended: SendGrid free tier (100 emails/day) for production

