#!/usr/bin/env node

/**
 * One-time migration for normalizing students.classId to real team document IDs.
 *
 * Usage:
 *   node scripts/migrate_student_class_ids.js --dry-run
 *   node scripts/migrate_student_class_ids.js --apply
 *   node scripts/migrate_student_class_ids.js --apply --report=reports/student_class_id_migration.json
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const { FieldValue } = require('firebase-admin/firestore');

const GROUP_LABELS = new Set(['year1', 'year2', 'year3']);
const args = process.argv.slice(2);
const isApply = args.includes('--apply');
const isDryRun = !isApply;
const reportArg = args.find((arg) => arg.startsWith('--report='));
const reportPath = reportArg
  ? reportArg.split('=')[1]
  : path.join(process.cwd(), 'student_class_id_migration_report.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

function normalizeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

async function pickCollectionName(candidates) {
  const rootCollections = await db.listCollections();
  const available = new Set(rootCollections.map((collection) => collection.id));
  for (const candidate of candidates) {
    if (available.has(candidate)) {
      return candidate;
    }
  }
  return candidates[0];
}

async function loadClassIndex(classesCollection) {
  const classesSnap = await classesCollection.get();
  const classesById = new Map();
  const classesByGroupAndName = new Map();

  for (const doc of classesSnap.docs) {
    const data = doc.data();
    const id = doc.id;
    const name = normalizeString(data.name);
    const groupId = normalizeString(data.groupId);
    const classMeta = { id, name, groupId };
    classesById.set(id, classMeta);

    if (groupId && name) {
      classesByGroupAndName.set(`${groupId}|${name}`, classMeta);
    }
  }

  return { classesById, classesByGroupAndName };
}

async function applyUpdates(updates) {
  if (updates.length === 0) return 0;

  let applied = 0;
  for (let i = 0; i < updates.length; i += 350) {
    const batch = db.batch();
    const slice = updates.slice(i, i + 350);
    for (const item of slice) {
      batch.set(item.ref, item.patch, { merge: true });
      applied += 1;
    }
    await batch.commit();
  }
  return applied;
}

async function recomputeClassStudentIds({
  classesCollection,
  studentsCollection,
  classIds,
  dryRun,
}) {
  if (classIds.size === 0) return 0;

  const ids = Array.from(classIds);
  let updatedClassCount = 0;

  for (let i = 0; i < ids.length; i += 100) {
    const batch = db.batch();
    const slice = ids.slice(i, i + 100);

    for (const classId of slice) {
      const membersSnap = await studentsCollection
          .where('classId', '==', classId)
          .get();
      const studentIds = membersSnap.docs.map((doc) => doc.id);

      if (!dryRun) {
        batch.set(
          classesCollection.doc(classId),
          {
            student_ids: studentIds,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }
      updatedClassCount += 1;
    }

    if (!dryRun) {
      await batch.commit();
    }
  }

  return updatedClassCount;
}

async function main() {
  const studentsCollectionName = await pickCollectionName(['students', 'Students']);
  const classesCollectionName = await pickCollectionName(['classes', 'Classes']);

  const studentsCollection = db.collection(studentsCollectionName);
  const classesCollection = db.collection(classesCollectionName);

  const { classesById, classesByGroupAndName } = await loadClassIndex(classesCollection);
  const studentsSnap = await studentsCollection.get();

  const updates = [];
  const unresolved = [];
  const affectedClassIds = new Set();

  let scanned = 0;
  let needsFix = 0;

  for (const doc of studentsSnap.docs) {
    scanned += 1;
    const data = doc.data();

    const classId = normalizeString(data.classId);
    const hasClassId = classId.length > 0;
    const needsNormalization = !hasClassId || GROUP_LABELS.has(classId);
    if (!needsNormalization) continue;

    needsFix += 1;

    const group = normalizeString(data.group);
    const teamName = normalizeString(data.team_name) || normalizeString(data.teamName);
    let resolved = null;

    if (group && teamName) {
      resolved = classesByGroupAndName.get(`${group}|${teamName}`) || null;
    }

    if (!resolved && GROUP_LABELS.has(classId) && teamName) {
      resolved = classesByGroupAndName.get(`${classId}|${teamName}`) || null;
    }

    if (!resolved && classId && classesById.has(classId)) {
      resolved = classesById.get(classId);
    }

    if (!resolved) {
      unresolved.push({
        docId: doc.id,
        uid: data.uid || null,
        classId: classId || null,
        group: group || null,
        teamName: teamName || null,
      });
      continue;
    }

    updates.push({
      ref: doc.ref,
      patch: {
        classId: resolved.id,
        team_name: resolved.name,
        group: resolved.groupId,
        updatedAt: FieldValue.serverTimestamp(),
      },
    });
    affectedClassIds.add(resolved.id);
  }

  let appliedUpdates = 0;
  if (!isDryRun) {
    appliedUpdates = await applyUpdates(updates);
  }

  const recomputedClassDocs = await recomputeClassStudentIds({
    classesCollection,
    studentsCollection,
    classIds: affectedClassIds,
    dryRun: isDryRun,
  });

  const report = {
    mode: isDryRun ? 'dry-run' : 'apply',
    generatedAt: new Date().toISOString(),
    collections: {
      students: studentsCollectionName,
      classes: classesCollectionName,
    },
    stats: {
      scannedStudents: scanned,
      studentsNeedingNormalization: needsFix,
      resolvableStudents: updates.length,
      appliedStudentUpdates: appliedUpdates,
      unresolvedStudents: unresolved.length,
      recomputedClassDocs,
    },
    unresolved,
  };

  const absoluteReportPath = path.isAbsolute(reportPath)
    ? reportPath
    : path.resolve(process.cwd(), reportPath);
  fs.mkdirSync(path.dirname(absoluteReportPath), { recursive: true });
  fs.writeFileSync(absoluteReportPath, JSON.stringify(report, null, 2), 'utf8');

  console.log(
    `Mode: ${report.mode} | scanned=${scanned} | needsFix=${needsFix} | resolvable=${updates.length} | unresolved=${unresolved.length}`,
  );
  if (!isDryRun) {
    console.log(`Applied updates: ${appliedUpdates}`);
  }
  console.log(`Recomputed class docs: ${recomputedClassDocs}`);
  console.log(`Report: ${absoluteReportPath}`);
}

main().catch((error) => {
  console.error('Migration failed:', error);
  process.exitCode = 1;
});
