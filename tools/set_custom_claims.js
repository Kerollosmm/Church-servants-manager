const admin = require('firebase-admin');
const fs = require('fs');

/**
 * CLI tool to set custom claims (roles) for users in Firebase Auth.
 * 
 * Usage: 
 * 1. Ensure you have service-account.json in the project root.
 * 2. Run: node tools/set_custom_claims.js <UID> <ROLE>
 * 
 * Available Roles: admin, servant, student
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

const args = process.argv.slice(2);
if (args.length < 2) {
  console.log('Usage: node tools/set_custom_claims.js <UID> <ROLE>');
  console.log('Roles: admin | servant | student');
  process.exit(1);
}

const uid = args[0];
const role = args[1].toLowerCase();

const validRoles = ['admin', 'servant', 'student'];
if (!validRoles.includes(role)) {
  console.error(`Invalid role: ${role}. Valid roles are: ${validRoles.join(', ')}`);
  process.exit(1);
}

async function setCustomClaims(uid, role) {
  try {
    const user = await admin.auth().getUser(uid);
    const currentClaims = user.customClaims || {};
    
    // Set custom user claims on this newly created user.
    await admin.auth().setCustomUserClaims(uid, { ...currentClaims, role: role });
    console.log(`Successfully assigned role '${role}' to user ${uid}`);
    
    // Verify the claims
    const updatedUser = await admin.auth().getUser(uid);
    console.log('Current claims:', updatedUser.customClaims);
    
    process.exit(0);
  } catch (error) {
    console.error('Error setting custom claims:', error);
    process.exit(1);
  }
}

setCustomClaims(uid, role);
