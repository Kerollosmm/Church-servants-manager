#!/usr/bin/env node

/**
 * One-time Firestore collection casing migration:
 *   Users    -> users
 *   Students -> students
 *   Classes  -> classes
 *
 * Usage:
 *   node scripts/firestore_collection_migration.js --dry-run
 *   node scripts/firestore_collection_migration.js
 *   node scripts/firestore_collection_migration.js --delete-source
 *
 * Notes:
 * - Requires GOOGLE_APPLICATION_CREDENTIALS or Firebase default credentials.
 * - Copies document payloads only (no recursive subcollection migration).
 */

const admin = require('firebase-admin');
const { FieldPath } = require('firebase-admin/firestore');

const mappings = [
  { source: 'Users', target: 'users' },
  { source: 'Students', target: 'students' },
  { source: 'Classes', target: 'classes' },
];

const dryRun = process.argv.includes('--dry-run');
const deleteSource = process.argv.includes('--delete-source');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

async function migrateCollection({ source, target }) {
  let migrated = 0;
  let batches = 0;
  let lastDoc = null;

  console.log(`\n[${source} -> ${target}] starting migration...`);

  while (true) {
    let query = db
        .collection(source)
        .orderBy(FieldPath.documentId())
        .limit(300);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    if (!dryRun) {
      const batch = db.batch();
      for (const doc of snapshot.docs) {
        const targetRef = db.collection(target).doc(doc.id);
        batch.set(targetRef, doc.data(), { merge: true });
        if (deleteSource) {
          batch.delete(doc.ref);
        }
      }
      await batch.commit();
    }

    migrated += snapshot.size;
    batches += 1;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    console.log(
      `[${source} -> ${target}] processed ${migrated} docs across ${batches} batch(es)`,
    );
  }

  return { source, target, migrated, batches };
}

async function main() {
  const summary = [];

  console.log(
    `Firestore casing migration started (dryRun=${dryRun}, deleteSource=${deleteSource})`,
  );

  for (const mapping of mappings) {
    const result = await migrateCollection(mapping);
    summary.push(result);
  }

  console.log('\nMigration summary:');
  for (const item of summary) {
    console.log(
      `- ${item.source} -> ${item.target}: ${item.migrated} doc(s), ${item.batches} batch(es)`,
    );
  }

  if (dryRun) {
    console.log('\nDry run complete. Re-run without --dry-run to execute writes.');
  }
}

main().catch((error) => {
  console.error('\nMigration failed:', error);
  process.exitCode = 1;
});

