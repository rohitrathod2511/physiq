const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

// Key path relative to this script
const serviceAccountPath = path.join(__dirname, '../physiq-5811f-firebase-adminsdk-fbsvc-59d1437e0c.json');
console.log('Loading service account from:', serviceAccountPath);

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase initialized successfully.');
} catch (e) {
  console.error('Failed to initialize Firebase:', e);
  process.exit(1);
}

const db = getFirestore();

async function testWrite() {
  console.log('Attempting to write to Firestore...');
  try {
    const docRef = db.collection('foods').doc('DEBUG_TEST_DOC');
    await docRef.set({
      name: 'Debug Test Food',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      debug: true
    });
    console.log('Successfully wrote to foods/DEBUG_TEST_DOC');

    // Verify read
    const doc = await docRef.get();
    if (doc.exists) {
      console.log('Successfully read back the document:', doc.data());
    } else {
      console.error('Document was written but cannot be read back immediately.');
    }

  } catch (e) {
    console.error('Write operation failed:', e);
  }
}

testWrite().catch(console.error);
