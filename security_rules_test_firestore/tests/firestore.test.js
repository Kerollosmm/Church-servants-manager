const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { setDoc, getDoc, updateDoc, deleteDoc, collection, doc, collectionGroup, query, getDocs } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'church-6eb05'; // Use the project ID

jest.setTimeout(30000);

describe('Firestore Security Rules', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8'),
        host: 'localhost',
        port: 8080,
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // --- Helper: Seed Data ---
  async function seedUser(uid, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'Users', uid), {
        uid,
        name: 'Test User',
        email: `${uid}@example.com`,
        role: 'servant',
        isArchived: false,
        ...data,
      });
    });
  }

  async function seedStudent(studentId, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'Students', studentId), {
        uid: studentId,
        name: 'Test Student',
        group: 'year1',
        classId: 'team-1',
        isArchived: false,
        ...data,
      });
    });
  }

  async function seedClass(classId, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'Classes', classId), {
        name: 'Team A',
        groupId: 'year1',
        isArchived: false,
        ...data,
      });
    });
  }

  async function seedSession(sessionId, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'attendance', sessionId), {
        teamId: 'team-1',
        startsAt: new Date(),
        endsAt: new Date(Date.now() + 30 * 60000),
        isClosed: false,
        studentIdsSnapshot: ['student-1'],
        ...data,
      });
    });
  }

  // --- Tests: Users Collection ---
  describe('Users collection', () => {
    test('unauthenticated user cannot read profiles', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(db, 'Users', 'any-user')));
    });

    test('user can read their own profile', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertSucceeds(getDoc(doc(db, 'Users', uid)));
    });

    test('servant can read another servant profile', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant' });
      await seedUser('other', { role: 'servant' });
      const db = testEnv.authenticatedContext(uid, { role: 'servant' }).firestore();
      await assertSucceeds(getDoc(doc(db, 'Users', 'other')));
    });

    test('admin can read any profile', async () => {
      const adminId = 'admin-1';
      await seedUser(adminId, { role: 'admin' });
      await seedUser('other', { role: 'servant' });
      const db = testEnv.authenticatedContext(adminId, { role: 'admin' }).firestore();
      await assertSucceeds(getDoc(doc(db, 'Users', 'other')));
    });

    test('user can update their own name', async () => {
      const uid = 'user-123';
      await seedUser(uid, { name: 'Old Name' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertSucceeds(updateDoc(doc(db, 'Users', uid), { name: 'New Name' }));
    });

    test('user cannot change their own role', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertFails(updateDoc(doc(db, 'Users', uid), { role: 'admin' }));
    });
  });

  // --- Tests: Students Collection ---
  describe('Students collection', () => {
    test('servant can read student in their assigned team', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedStudent('student-1', { classId: teamId });
      
      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertSucceeds(getDoc(doc(db, 'Students', 'student-1')));
    });

    test('servant cannot read student in another group', async () => {
      const servantId = 'servant-1';
      await seedUser(servantId, { groupId: 'year1', role: 'servant' });
      await seedStudent('student-1', { group: 'year2' });
      
      const db = testEnv.authenticatedContext(servantId, { role: 'servant', groupId: 'year1' }).firestore();
      await assertFails(getDoc(doc(db, 'Students', 'student-1')));
    });

    test('student can read their own profile', async () => {
      const studentId = 'student-123';
      await seedUser(studentId, { role: 'student' });
      await seedStudent(studentId, { uid: studentId });
      
      const db = testEnv.authenticatedContext(studentId).firestore();
      await assertSucceeds(getDoc(doc(db, 'Students', studentId)));
    });
  });

  // --- Tests: Data Validation ---
  describe('student data validation', () => {
    test('servant cannot update student with empty name', async () => {
      const servantId = 'servant-validate-1';
      const teamId = 'team-validate';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedStudent('student-validate-1', { classId: teamId });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertFails(updateDoc(doc(db, 'Students', 'student-validate-1'), { name: '' }));
    });

    test('servant cannot update student with non-string name', async () => {
      const servantId = 'servant-validate-2';
      const teamId = 'team-validate-2';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedStudent('student-validate-2', { classId: teamId });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertFails(updateDoc(doc(db, 'Students', 'student-validate-2'), { name: 123 }));
    });

    test('admin can update student with valid name', async () => {
      const adminId = 'admin-validate';
      await seedUser(adminId, { role: 'admin' });
      await seedStudent('student-validate-3', {});

      const db = testEnv.authenticatedContext(adminId, { role: 'admin' }).firestore();
      await assertSucceeds(updateDoc(doc(db, 'Students', 'student-validate-3'), { name: 'Valid Name' }));
    });
  });

  // --- Tests: Attendance Marks ---
  describe('attendance marks', () => {
    test('authorized servant can create a mark', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: ['student-1'] });
      
      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertSucceeds(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
        teamId: teamId,
        studentId: 'student-1',
        status: 'present',
        markedByUserId: servantId,
      }));
    });

    test('student cannot mark themselves present', async () => {
      const studentId = 'student-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(studentId, { role: 'student' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: [studentId] });
      
      const db = testEnv.authenticatedContext(studentId, { role: 'student' }).firestore();
      await assertFails(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
        teamId: teamId,
        studentId: studentId,
        status: 'present',
        markedByUserId: studentId,
      }));
    });

    test('system can create automated marks', async () => {
      const adminId = 'admin-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(adminId, { role: 'admin' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: ['student-1'] });
      
      const db = testEnv.authenticatedContext(adminId, { role: 'admin' }).firestore();
      // Even though it's admin context, the logic for 'system' suffix is tested
      await assertSucceeds(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_system'), {
        teamId: teamId,
        studentId: 'student-1',
        status: 'absent',
        markedByUserId: 'system',
      }));
    });
  });

  // --- Tests added for Feature 024 ---
  describe('Feature 024: Code Review Remediation Tests', () => {
    test('servant cannot read pastoral records via collection group', async () => {
      const servantId = 'servant-1';
      await seedUser(servantId, { role: 'servant' });
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'Students/student-1/PastoralRecords/record-1'), {
          recordId: 'record-1',
          studentId: 'student-1',
          type: 'phoneCall',
          summary: 'Hello',
          visitedByUid: servantId,
          visitedByName: 'Test Servant',
          createdAt: new Date(),
        });
      });
      const db = testEnv.authenticatedContext(servantId, { role: 'servant' }).firestore();
      await assertFails(getDocs(query(collectionGroup(db, 'PastoralRecords'))));
    });

    test('admin can read pastoral records via collection group', async () => {
      const adminId = 'admin-1';
      await seedUser(adminId, { role: 'admin' });
      const db = testEnv.authenticatedContext(adminId, { role: 'admin' }).firestore();
      await assertSucceeds(getDocs(query(collectionGroup(db, 'PastoralRecords'))));
    });

    test('new user without profile doc can self-register with student role', async () => {
      const newUid = 'new-user-999';
      const db = testEnv.authenticatedContext(newUid).firestore();
      await assertSucceeds(setDoc(doc(db, 'Users', newUid), {
        uid: newUid,
        name: 'New Student',
        email: 'new@example.com',
        role: 'student',
        isArchived: false,
      }));
    });

    test('servant can create student in their assigned sector and team', async () => {
      const servantId = 'servant-1';
      await seedUser(servantId, { role: 'servant', assignedSectorIds: ['sector-1'], assignedTeamIds: ['team-1'] });
      const db = testEnv.authenticatedContext(servantId, { role: 'servant' }).firestore();
      await assertSucceeds(setDoc(doc(db, 'Students', 'student-scoped'), {
        uid: 'student-scoped',
        name: 'Scoped Student',
        sectorId: 'sector-1',
        classId: 'team-1',
        isArchived: false,
      }));
    });

    test('servant cannot create student with classId outside their scope', async () => {
      const servantId = 'servant-1';
      await seedUser(servantId, { role: 'servant', assignedSectorIds: ['sector-1'], assignedTeamIds: ['team-1'] });
      const db = testEnv.authenticatedContext(servantId, { role: 'servant' }).firestore();
      await assertFails(setDoc(doc(db, 'Students', 'student-unscoped'), {
        uid: 'student-unscoped',
        name: 'Unscoped Student',
        sectorId: 'sector-1',
        classId: 'team-2',
        isArchived: false,
      }));
    });
  });
});
