const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');

// Path check for serviceAccountKey.json
const serviceAccountPath = './serviceAccountKey.json';
if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ Error: serviceAccountKey.json not found in the root directory.');
    console.log('Please download it from Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function getCollectionsSchema() {
  console.log('🚀 Starting schema extraction...');
  try {
    const collections = await db.listCollections();
    const schema = {};

    if (collections.length === 0) {
        console.log('⚠️ No collections found in this database.');
    }

    for (const collection of collections) {
      console.log(`🔍 Processing collection: ${collection.id}...`);
      // Checking up to 5 documents to capture most optional fields
      const snapshot = await collection.limit(5).get();

      if (!snapshot.empty) {
        if (!schema[collection.id]) schema[collection.id] = {};

        snapshot.docs.forEach(doc => {
          const data = doc.data();
          for (const [key, value] of Object.entries(data)) {
            if (value === null) {
              schema[collection.id][key] = 'null';
            } else if (value && typeof value === 'object' && value.constructor && value.constructor.name === 'Timestamp') {
              schema[collection.id][key] = 'Timestamp';
            } else if (Array.isArray(value)) {
              schema[collection.id][key] = 'Array';
            } else if (typeof value === 'object') {
                schema[collection.id][key] = Object.keys(value).reduce((acc, k) => {
                    acc[k] = typeof value[k];
                    return acc;
                }, {});
            } else {
              schema[collection.id][key] = typeof value;
            }
          }
        });
      } else {
        schema[collection.id] = "Empty Collection (No documents found)";
      }
    }

    fs.writeFileSync('firebase_schema.json', JSON.stringify(schema, null, 2));
    console.log('✅ Success! Schema saved to firebase_schema.json');
  } catch (error) {
    console.error('❌ Error fetching collections:', error.message);
  }
}

getCollectionsSchema().catch(console.error);
