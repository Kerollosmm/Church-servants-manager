const admin = require('firebase-admin');
const fs = require('fs');

/**
 * CLI tool to sync custom claims (roles, teams) for users in Firebase Auth
 * from their Firestore 'Users' document.
 * 
 * Usage: 
 * 1. Ensure you have service-account.json in the project root.
 * 2. Run: node tools/set_custom_claims.js <UID>
 */

const serviceAccountPath = './service-account.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.error('Error: service-account.json not found in root directory.');
  console.log('Please download your service account key from Firebase Console -> Project Settings -> Service Accounts');
  process.exit(1);
}

const serviceAccount = require('../service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setCustomClaims(uid) {
  try {
    // 1. Fetch user data from Firestore to get the source of truth
    const db = admin.firestore();
    const userDoc = await db.collection('Users').doc(uid).get();

    if (!userDoc.exists) {
      console.error(`Error: User document for UID ${uid} not found in Firestore 'Users' collection.`);
      process.exit(1);
    }

    const userData = userDoc.data();
    const role = userData.role;
    const assignedTeamIds = userData.assignedTeamIds || [];
    const isArchived = userData.isArchived || false;

    if (!role) {
      console.error(`Error: User document for UID ${uid} is missing the 'role' field.`);
      process.exit(1);
    }

    console.log(`Found user ${uid} in Firestore. Syncing claims:`);
    console.log(` - Role: ${role}`);
    console.log(` - Teams: [${assignedTeamIds.join(', ')}]`);
    console.log(` - Archived: ${isArchived}`);

    // 2. Build explicit canonical claim object (overwrite entirely to clear stale keys)
    const newClaims = {
      role: role,
      assignedTeamIds: assignedTeamIds,
      isArchived: isArchived
    };

    // 3. Set the claims
    await admin.auth().setCustomUserClaims(uid, newClaims);
    console.log(`Successfully synced canonical claims for user ${uid}`);

    // 4. Verify the claims
    const updatedUser = await admin.auth().getUser(uid);
    console.log('Verified JWT Custom Claims:', updatedUser.customClaims);

    process.exit(0);
  } catch (error) {
    console.error('Error syncing custom claims:', error);
    process.exit(1);
  }
}

// Check arguments
const args = process.argv.slice(2);
if (args.length < 1) {
  console.log('Usage: node tools/set_custom_claims.js <UID>');
  process.exit(1);
}

const uid = args[0];
setCustomClaims(uid);
