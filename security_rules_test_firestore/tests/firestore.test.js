const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { setDoc, getDoc, updateDoc, deleteDoc, collection, doc } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'church-6eb05'; // Use the project ID

describe('Firestore Security Rules', () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
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
      await setDoc(doc(db, 'servants', uid), {
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

  // --- Tests: Servants Collection ---
  describe('servants collection', () => {
    test('unauthenticated user cannot read profiles', async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(db, 'servants', 'any-user')));
    });

    test('user can read their own profile', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertSucceeds(getDoc(doc(db, 'servants', uid)));
    });

    test('servant cannot read another servant profile', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant' });
      await seedUser('other', { role: 'servant' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertFails(getDoc(doc(db, 'servants', 'other')));
    });

    test('admin can read any profile', async () => {
      const adminId = 'admin-1';
      await seedUser(adminId, { role: 'admin' });
      await seedUser('other', { role: 'servant' });
      const db = testEnv.authenticatedContext(adminId).firestore();
      await assertSucceeds(getDoc(doc(db, 'servants', 'other')));
    });

    test('user can update their own name', async () => {
      const uid = 'user-123';
      await seedUser(uid, { name: 'Old Name' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertSucceeds(updateDoc(doc(db, 'servants', uid), { name: 'New Name' }));
    });

    test('user cannot change their own role', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertFails(updateDoc(doc(db, 'servants', uid), { role: 'admin' }));
    });
  });

  // --- Tests: Students Collection ---
  describe('Students collection', () => {
    test('servant can read student in their assigned team', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedStudent('student-1', { classId: teamId });
      
      const db = testEnv.authenticatedContext(servantId).firestore();
      await assertSucceeds(getDoc(doc(db, 'Students', 'student-1')));
    });

    test('servant cannot read student in another group', async () => {
      const servantId = 'servant-1';
      await seedUser(servantId, { groupId: 'year1', role: 'servant' });
      await seedStudent('student-1', { group: 'year2' });
      
      const db = testEnv.authenticatedContext(servantId).firestore();
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

      const db = testEnv.authenticatedContext(servantId).firestore();
      await assertFails(updateDoc(doc(db, 'Students', 'student-validate-1'), { name: '' }));
    });

    test('servant cannot update student with non-string name', async () => {
      const servantId = 'servant-validate-2';
      const teamId = 'team-validate-2';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedStudent('student-validate-2', { classId: teamId });

      const db = testEnv.authenticatedContext(servantId).firestore();
      await assertFails(updateDoc(doc(db, 'Students', 'student-validate-2'), { name: 123 }));
    });

    test('admin can update student with valid name', async () => {
      const adminId = 'admin-validate';
      await seedUser(adminId, { role: 'admin' });
      await seedStudent('student-validate-3', {});

      const db = testEnv.authenticatedContext(adminId).firestore();
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
      
      const db = testEnv.authenticatedContext(servantId).firestore();
      await assertSucceeds(setDoc(doc(db, 'attendance', sessionId, 'marks', 'student-1_session-1'), {
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
      
      const db = testEnv.authenticatedContext(studentId).firestore();
      await assertFails(setDoc(doc(db, 'attendance', sessionId, 'marks', 'student-1_session-1'), {
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
      
      const db = testEnv.authenticatedContext(adminId).firestore();
      // Even though it's admin context, the logic for 'system' suffix is tested
      await assertSucceeds(setDoc(doc(db, 'attendance', sessionId, 'marks', 'student-1_system'), {
        studentId: 'student-1',
        status: 'absent',
        markedByUserId: 'system',
      }));
    });
  });
});
