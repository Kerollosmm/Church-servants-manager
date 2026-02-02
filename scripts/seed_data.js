/**
 * Data Seeding Script for Church Management System
 *
 * Prerequisites:
 * 1. Node.js installed.
 * 2. npm install firebase-admin
 * 3. Download 'serviceAccountKey.json' from Firebase Console -> Project Settings -> Service Accounts
 *    and place it in the same directory as this script.
 *
 * Usage:
 * node seed_data.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

const users = [
  {
    email: 'admin@test.com',
    password: 'password123',
    name: 'Admin User',
    role: 'admin'
  },
  {
    email: 'servant@test.com',
    password: 'password123',
    name: 'Servant User',
    role: 'servant'
  },
  {
    email: 'student@test.com',
    password: 'password123',
    name: 'Student User',
    role: 'student'
  }
];

const mockGroups = [
  {
    name: 'St. Mary Service',
    grade: '10',
    servantId: '' // Will be filled dynamically
  },
  {
    name: 'St. Mark Service',
    grade: '11',
    servantId: ''
  }
];

const mockLessons = [
  {
    title: 'Introduction to Faith',
    content: 'Lesson content goes here...',
    date: new Date().toISOString()
  },
  {
    title: 'History of the Church',
    content: 'Lesson content goes here...',
    date: new Date().toISOString()
  }
];

async function seedData() {
  console.log('Starting data seeding...');

  try {
    // 1. Create Users
    for (const userData of users) {
      let uid;
      try {
        const userRecord = await auth.createUser({
          email: userData.email,
          password: userData.password,
          displayName: userData.name,
        });
        uid = userRecord.uid;
        console.log(`Created Auth user: ${userData.email} (${uid})`);
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          const user = await auth.getUserByEmail(userData.email);
          uid = user.uid;
          console.log(`User already exists: ${userData.email} (${uid})`);
        } else {
          throw error;
        }
      }

      // Create/Update Firestore Document
      await db.collection('users').doc(uid).set({
        email: userData.email,
        name: userData.name,
        role: userData.role,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      console.log(`Updated Firestore document for: ${userData.email}`);

      // Store UID for relationships
      if (userData.role === 'servant') {
        mockGroups[0].servantId = uid;
      }
    }

    // 2. Create Groups
    console.log('Seeding Groups...');
    const groupsRef = db.collection('groups');
    for (const group of mockGroups) {
      await groupsRef.add(group);
    }

    // 3. Create Lessons
    console.log('Seeding Lessons...');
    const lessonsRef = db.collection('lessons');
    for (const lesson of mockLessons) {
      await lessonsRef.add(lesson);
    }

    console.log('Data seeding completed successfully!');
    process.exit(0);

  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData();
