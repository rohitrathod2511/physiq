const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // User needs to provide this
const exercises = require('./exercises.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function seedExercises() {
  const collectionRef = db.collection('exercise_metadata');

  console.log(`Starting seed for ${exercises.length} exercises...`);

  const batch = db.batch();

  for (const exercise of exercises) {
    // Use the ID as the document ID for easy lookup
    const docRef = collectionRef.doc(exercise.id);
    batch.set(docRef, exercise);
  }

  try {
    await batch.commit();
    console.log('Successfully seeded exercises!');
  } catch (error) {
    console.error('Error seeding exercises:', error);
  }
}

seedExercises();
