const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure email transporter (use your email service credentials)
const transporter = nodemailer.createTransport({
  service: 'gmail', // or use another service like SendGrid, Mailgun, etc.
  auth: {
    user: functions.config().email?.user || process.env.EMAIL_USER,
    pass: functions.config().email?.pass || process.env.EMAIL_PASS,
  },
});

/**
 * Cloud Function triggered when a new project application is created
 * Sends email notifications to:
 * 1. The organizer of the NGO associated with the project
 * 2. The applicant (confirmation email)
 */
exports.onApplicationCreated = functions.firestore
  .document('project_applications/{applicationId}')
  .onCreate(async (snap, context) => {
    const application = snap.data();
    const applicationId = context.params.applicationId;

    try {
      // Get project details
      const projectDoc = await admin
        .firestore()
        .collection('project_offers')
        .doc(application.projectId)
        .get();

      if (!projectDoc.exists) {
        console.error(`Project ${application.projectId} not found`);
        return null;
      }

      const project = projectDoc.data();

      // Get NGO details if available
      let ngoData = null;
      if (application.ngoId) {
        const ngoDoc = await admin
          .firestore()
          .collection('ngos')
          .doc(application.ngoId)
          .get();
        if (ngoDoc.exists) {
          ngoData = ngoDoc.data();
        }
      }

      // Get organizer email (from NGO or admin users)
      let organizerEmails = [];
      if (application.ngoId) {
        const organizers = await admin
          .firestore()
          .collection('users')
          .where('ngoId', '==', application.ngoId)
          .where('isOrganizer', '==', true)
          .get();

        organizers.forEach((doc) => {
          const userData = doc.data();
          if (userData.email) {
            organizerEmails.push(userData.email);
          }
        });
      }

      // Send email to organizer(s)
      if (organizerEmails.length > 0) {
        for (const email of organizerEmails) {
          await transporter.sendMail({
            from: functions.config().email?.from || process.env.EMAIL_FROM || 'noreply@tmelnikapp.com',
            to: email,
            subject: `New Application: ${application.projectTitle}`,
            html: `
              <h2>New Project Application</h2>
              <p>A new application has been submitted for your project.</p>
              <h3>Project: ${application.projectTitle}</h3>
              <p><strong>Applicant:</strong> ${application.userEmail}</p>
              <p><strong>Applied on:</strong> ${new Date(application.appliedAt.toMillis()).toLocaleString()}</p>
              <p><strong>Status:</strong> ${application.status}</p>
              <p>Please log in to the app to review and manage this application.</p>
            `,
          });
        }
        console.log(`Email sent to organizers: ${organizerEmails.join(', ')}`);
      }

      // Send confirmation email to applicant
      if (application.userEmail) {
        await transporter.sendMail({
          from: functions.config().email?.from || process.env.EMAIL_FROM || 'noreply@tmelnikapp.com',
          to: application.userEmail,
          subject: `Application Confirmation: ${application.projectTitle}`,
          html: `
            <h2>Application Received</h2>
            <p>Thank you for your application!</p>
            <h3>Project: ${application.projectTitle}</h3>
            <p>Your application has been successfully submitted and is now pending review.</p>
            <p><strong>Status:</strong> ${application.status}</p>
            <p>You will be notified when the status of your application changes.</p>
            <p>You can track your applications in the app under your profile.</p>
          `,
        });
        console.log(`Confirmation email sent to: ${application.userEmail}`);
      }

      return null;
    } catch (error) {
      console.error('Error sending email notifications:', error);
      return null;
    }
  });

/**
 * Cloud Function triggered when application status is updated
 * Sends email notification to the applicant
 */
exports.onApplicationStatusUpdated = functions.firestore
  .document('project_applications/{applicationId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send email if status changed
    if (before.status === after.status) {
      return null;
    }

    try {
      if (after.userEmail) {
        await transporter.sendMail({
          from: functions.config().email?.from || process.env.EMAIL_FROM || 'noreply@tmelnikapp.com',
          to: after.userEmail,
          subject: `Application Update: ${after.projectTitle}`,
          html: `
            <h2>Application Status Updated</h2>
            <h3>Project: ${after.projectTitle}</h3>
            <p>Your application status has been updated.</p>
            <p><strong>Previous Status:</strong> ${before.status}</p>
            <p><strong>New Status:</strong> ${after.status}</p>
            <p>Please log in to the app for more details.</p>
          `,
        });
        console.log(`Status update email sent to: ${after.userEmail}`);
      }

      return null;
    } catch (error) {
      console.error('Error sending status update email:', error);
      return null;
    }
  });

