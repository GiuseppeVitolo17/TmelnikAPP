const functions = require('firebase-functions');
const admin = require('firebase-admin');

try { admin.initializeApp(); } catch (_) {}

const eu = functions.region('europe-west3');

exports.onProjectOfferCreate = eu.firestore
  .document('project_offers/{projectId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const title = data.title || 'New Project Available!';
    const location = data.location ? ` · ${data.location}` : '';

    const message = {
      notification: {
        title: 'New Project Available! 🎉',
        body: `${title}${location}`.substring(0, 120),
      },
      data: {
        type: 'project_created',
        projectId: context.params.projectId,
      },
      topic: 'projects',
      android: {
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            contentAvailable: true,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('FCM sent to topic projects:', response);
    } catch (e) {
      console.error('Error sending FCM', e);
    }
  });

// Temporary test endpoint to send a push to topic 'projects'
exports.sendTestPush = eu.https.onRequest(async (req, res) => {
  try {
    const token = (req.query.token || req.body?.token || '').toString().trim();
    const title = (req.query.title || req.body?.title || 'Test: New Project Available! 🎉').toString();
    const body = (req.query.body || req.body?.body || 'This is a test push from Functions').toString();
    
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: { type: 'project_created_test' },
      android: {
        priority: 'high',
      },
    };

    let resp;
    if (token) {
      message.token = token;
      resp = await admin.messaging().send(message);
      console.log('Sent to token:', token.substring(0, 12) + '…', resp);
    } else {
      message.topic = 'projects';
      resp = await admin.messaging().send(message);
      console.log('Sent to topic projects:', resp);
    }
    res.status(200).send('Test push sent');
  } catch (e) {
    console.error('sendTestPush error:', e);
    res.status(500).send(`Error sending test push: ${e?.message || e}`);
  }
});

// Test endpoint: creates a minimal project_offers document to trigger onCreate
exports.createTestProject = eu.https.onRequest(async (req, res) => {
  try {
    const doc = await admin.firestore().collection('project_offers').add({
      title: 'Test Push Project',
      location: 'Test City',
      description: 'Auto-generated for push test',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.status(200).send(`Created test project ${doc.id}`);
  } catch (e) {
    console.error('createTestProject error:', e);
    res.status(500).send(`Error creating test project: ${e?.message || e}`);
  }
});


