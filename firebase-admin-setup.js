// Firebase Admin SDK Setup
// This is for server-side operations (Node.js backend)

const admin = require("firebase-admin");

// Option 1: Using service account key file
const serviceAccount = require("./path/to/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://tmelnikapp-default-rtdb.firebaseio.com" // Optional
});

// Option 2: Using environment variables (RECOMMENDED)
// Set these environment variables:
// export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
// export FIREBASE_PROJECT_ID="tmelnikapp"
// export FIREBASE_PRIVATE_KEY="your-private-key"
// export FIREBASE_CLIENT_EMAIL="your-client-email"

// admin.initializeApp({
//   credential: admin.credential.applicationDefault(),
//   projectId: process.env.FIREBASE_PROJECT_ID
// });

// Example usage
const db = admin.firestore();

// Create a user
async function createUser(email, password, displayName) {
  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: displayName
    });
    console.log('Successfully created new user:', userRecord.uid);
    return userRecord;
  } catch (error) {
    console.log('Error creating new user:', error);
    throw error;
  }
}

// Add data to Firestore
async function addData(collection, data) {
  try {
    const docRef = await db.collection(collection).add(data);
    console.log('Document written with ID: ', docRef.id);
    return docRef;
  } catch (error) {
    console.log('Error adding document: ', error);
    throw error;
  }
}

module.exports = {
  admin,
  createUser,
  addData
};
