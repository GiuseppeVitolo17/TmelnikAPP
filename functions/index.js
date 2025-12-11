const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configure email transporter
// Supports multiple email providers: Gmail, SendGrid, SMTP
function getEmailTransporter() {
  const emailConfig = functions.config().email || {};
  const emailUser = emailConfig.user || process.env.EMAIL_USER;
  const emailPass = emailConfig.pass || process.env.EMAIL_PASS;
  const emailService = emailConfig.service || process.env.EMAIL_SERVICE || 'gmail';
  const emailHost = emailConfig.host || process.env.EMAIL_HOST;
  const emailPort = emailConfig.port || process.env.EMAIL_PORT || 587;
  const emailSecure = emailConfig.secure || process.env.EMAIL_SECURE === 'true';

  // Use SMTP config if host is provided, otherwise use service
  if (emailHost) {
    return nodemailer.createTransport({
      host: emailHost,
      port: parseInt(emailPort),
      secure: emailSecure,
      auth: {
        user: emailUser,
        pass: emailPass,
      },
    });
  }

  // Use service-based config (Gmail, SendGrid, etc.)
  return nodemailer.createTransport({
    service: emailService,
    auth: {
      user: emailUser,
      pass: emailPass,
    },
  });
}

const transporter = getEmailTransporter();

/**
 * Cloud Function triggered when a new project application is created
 * Sends email notifications to:
 * 1. The organizer of the NGO associated with the project
 * 2. The applicant (confirmation email)
 */
exports.onApplicationCreated = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '256MB',
  })
  .firestore.document('project_applications/{applicationId}')
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
        const emailFrom = functions.config().email?.from || process.env.EMAIL_FROM || 'noreply@tmelnikapp.com';
        
        for (const email of organizerEmails) {
          try {
            await transporter.sendMail({
              from: emailFrom,
              to: email,
              subject: `New Application: ${application.projectTitle}`,
              html: `
                <!DOCTYPE html>
                <html>
                <head>
                  <meta charset="utf-8">
                  <style>
                    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                    .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
                    .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
                    .info-box { background-color: white; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #2196F3; }
                    .button { display: inline-block; padding: 12px 24px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    <div class="header">
                      <h1>📧 New Project Application</h1>
                    </div>
                    <div class="content">
                      <p>A new application has been submitted for your project.</p>
                      <div class="info-box">
                        <h3>${application.projectTitle}</h3>
                        <p><strong>Applicant:</strong> ${application.userEmail}</p>
                        <p><strong>Applied on:</strong> ${new Date(application.appliedAt.toMillis()).toLocaleString('en-US', { dateStyle: 'full', timeStyle: 'short' })}</p>
                        <p><strong>Status:</strong> <span style="color: orange; font-weight: bold;">${application.status.toUpperCase()}</span></p>
                        ${ngoData ? `<p><strong>Organization:</strong> ${ngoData.name || 'N/A'}</p>` : ''}
                      </div>
                      <p>Please log in to the app to review and manage this application.</p>
                      <p style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666;">
                        This is an automated notification from Tmelnik App.
                      </p>
                    </div>
                  </div>
                </body>
                </html>
              `,
            });
            console.log(`✅ Email sent to organizer: ${email}`);
          } catch (emailError) {
            console.error(`❌ Failed to send email to ${email}:`, emailError);
            // Continue with other emails even if one fails
          }
        }
        console.log(`📧 Email notifications sent to ${organizerEmails.length} organizer(s)`);
      }

      // Send confirmation email to applicant
      if (application.userEmail) {
        try {
          const emailFrom = functions.config().email?.from || process.env.EMAIL_FROM || 'noreply@tmelnikapp.com';
          
          await transporter.sendMail({
            from: emailFrom,
            to: application.userEmail,
            subject: `Application Confirmation: ${application.projectTitle}`,
            html: `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <style>
                  body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                  .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
                  .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
                  .info-box { background-color: white; padding: 15px; margin: 15px 0; border-radius: 5px; border-left: 4px solid #4CAF50; }
                  .status-badge { display: inline-block; padding: 5px 10px; background-color: orange; color: white; border-radius: 3px; font-weight: bold; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>✅ Application Received</h1>
                  </div>
                  <div class="content">
                    <p>Dear Applicant,</p>
                    <p>Thank you for your application! We have received your submission and it is now under review.</p>
                    <div class="info-box">
                      <h3>${application.projectTitle}</h3>
                      <p><strong>Application Date:</strong> ${new Date(application.appliedAt.toMillis()).toLocaleString('en-US', { dateStyle: 'full', timeStyle: 'short' })}</p>
                      <p><strong>Status:</strong> <span class="status-badge">${application.status.toUpperCase()}</span></p>
                    </div>
                    <p>You will receive an email notification when your application status is updated.</p>
                    <p>You can also track all your applications in the app under your profile section.</p>
                    <p style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666;">
                      This is an automated confirmation from Tmelnik App.<br>
                      If you have any questions, please contact the organization directly.
                    </p>
                  </div>
                </div>
              </body>
              </html>
            `,
          });
          console.log(`✅ Confirmation email sent to applicant: ${application.userEmail}`);
        } catch (emailError) {
          console.error(`❌ Failed to send confirmation email to ${application.userEmail}:`, emailError);
        }
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
exports.onApplicationStatusUpdated = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '256MB',
  })
  .firestore.document('project_applications/{applicationId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send email if status changed
    if (before.status === after.status) {
      return null;
    }

    try {
      if (after.userEmail) {
        const emailFrom = functions.config().email?.from || process.env.EMAIL_FROM || 'noreply@tmelnikapp.com';
        
        // Determine status color and emoji
        let statusColor = '#FF9800'; // orange for pending
        let statusEmoji = '⏳';
        if (after.status === 'accepted') {
          statusColor = '#4CAF50';
          statusEmoji = '✅';
        } else if (after.status === 'rejected') {
          statusColor = '#F44336';
          statusEmoji = '❌';
        }

        try {
          await transporter.sendMail({
            from: emailFrom,
            to: after.userEmail,
            subject: `Application Update: ${after.projectTitle}`,
            html: `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <style>
                  body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                  .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                  .header { background-color: ${statusColor}; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
                  .content { background-color: #f9f9f9; padding: 20px; border-radius: 0 0 8px 8px; }
                  .status-box { background-color: white; padding: 20px; margin: 15px 0; border-radius: 5px; border-left: 4px solid ${statusColor}; }
                  .status-badge { display: inline-block; padding: 8px 16px; background-color: ${statusColor}; color: white; border-radius: 5px; font-weight: bold; font-size: 16px; }
                  .old-status { color: #666; text-decoration: line-through; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>${statusEmoji} Application Status Updated</h1>
                  </div>
                  <div class="content">
                    <p>Dear Applicant,</p>
                    <p>Your application status has been updated by the organization.</p>
                    <div class="status-box">
                      <h3>${after.projectTitle}</h3>
                      <p><span class="old-status">Previous: ${before.status.toUpperCase()}</span></p>
                      <p><strong>New Status:</strong> <span class="status-badge">${statusEmoji} ${after.status.toUpperCase()}</span></p>
                    </div>
                    ${after.status === 'accepted' ? '<p style="background-color: #E8F5E9; padding: 15px; border-radius: 5px;"><strong>🎉 Congratulations!</strong> Your application has been accepted. The organization will contact you soon with further details.</p>' : ''}
                    ${after.status === 'rejected' ? '<p style="background-color: #FFEBEE; padding: 15px; border-radius: 5px;">We\'re sorry to inform you that your application was not selected this time. Don\'t give up - there are many other opportunities available!</p>' : ''}
                    <p>Please log in to the app to view more details and manage your applications.</p>
                    <p style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666;">
                      This is an automated notification from Tmelnik App.
                    </p>
                  </div>
                </div>
              </body>
              </html>
            `,
          });
          console.log(`✅ Status update email sent to: ${after.userEmail}`);
        } catch (emailError) {
          console.error(`❌ Failed to send status update email to ${after.userEmail}:`, emailError);
        }
      }

      return null;
    } catch (error) {
      console.error('❌ Error in onApplicationStatusUpdated function:', error);
      return null;
    }
  });

