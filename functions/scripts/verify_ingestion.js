const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, '..', 'physiq-5811f-firebase-adminsdk-fbsvc-59d1437e0c.json');
const serviceAccount = require(serviceAccountPath);

if (admin.apps.length === 0) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

async function verify() {
  console.log("Verifying 'foods' collection...");
  const foodsSnap = await db.collection('foods').limit(5).get();
  console.log(`Found ${foodsSnap.size} food documents.`);
  foodsSnap.forEach(doc => {
    console.log(`- ${doc.id}: ${JSON.stringify(doc.data())}`);
  });

  console.log("\nVerifying 'food_aliases' collection...");
  const aliasesSnap = await db.collection('food_aliases').limit(5).get();
  console.log(`Found ${aliasesSnap.size} alias documents.`);
  aliasesSnap.forEach(doc => {
    console.log(`- ${doc.id}: ${JSON.stringify(doc.data())}`);
  });
}

verify().catch(console.error);
