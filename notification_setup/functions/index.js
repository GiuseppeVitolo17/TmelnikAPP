const functions = require('firebase-functions');
const admin = require('firebase-admin');

try { admin.initializeApp(); } catch (_) {}

exports.onProjectOfferCreate = functions.firestore
  .document('project_offers/{projectId}')
  .onCreate(async (snap, context) => {
    const payload = {
      data: {
        type: 'project_created',
        projectId: context.params.projectId,
      },
    };

    try {
      await admin.messaging().sendToTopic('projects', payload, { priority: 'high' });
      console.log('FCM sent to topic projects');
    } catch (e) {
      console.error('Error sending FCM', e);
    }
  });


