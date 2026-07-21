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
      await setDoc(doc(db, 'AttendanceSessions', sessionId), {
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

    test('user cannot change their own assignedTeamId', async () => {
      const uid = 'user-123';
      await seedUser(uid, { role: 'servant', assignedTeamId: 'team-1' });
      const db = testEnv.authenticatedContext(uid).firestore();
      await assertFails(updateDoc(doc(db, 'Users', uid), { assignedTeamId: 'team-2' }));
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

    test('servant cannot create mark with missing teamId', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: ['student-1'] });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertFails(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
        studentId: 'student-1',
        status: 'present',
        markedByUserId: servantId,
      }));
    });

    test('servant cannot create mark with mismatching markedByUserId', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: ['student-1'] });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertFails(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
        teamId: teamId,
        studentId: 'student-1',
        status: 'present',
        markedByUserId: 'other-user-id',
      }));
    });

    test('servant cannot create mark with own teamId under a foreign session', async () => {
      const servantId = 'servant-1';
      const ownTeamId = 'team-1';
      const foreignTeamId = 'team-2';
      const sessionId = 'session-foreign';
      // Servant manages team-1 only.
      await seedUser(servantId, { assignedTeamId: ownTeamId, role: 'servant' });
      // But the session belongs to team-2.
      await seedSession(sessionId, { teamId: foreignTeamId, studentIdsSnapshot: ['student-1'] });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: ownTeamId }).firestore();
      // Servant marks the doc with their own teamId and own uid — both would
      // pass the previous guards, but the session↔teamId invariant must reject.
      await assertFails(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-foreign'), {
        teamId: ownTeamId,
        studentId: 'student-1',
        status: 'present',
        markedByUserId: servantId,
      }));
    });

    test('servant can update legacy mark where teamId is missing', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: ['student-1'] });

      // Seed a legacy mark without teamId and markedByUserId
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
          studentId: 'student-1',
          status: 'absent',
        });
      });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertSucceeds(setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
        teamId: teamId,
        studentId: 'student-1',
        status: 'present',
        markedByUserId: servantId,
      }, { merge: true }));
    });

    test('servant cannot update mark to change markedByUserId', async () => {
      const servantId = 'servant-1';
      const teamId = 'team-1';
      const sessionId = 'session-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant' });
      await seedSession(sessionId, { teamId, studentIdsSnapshot: ['student-1'] });

      // Seed mark with servant-1
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
          teamId: teamId,
          studentId: 'student-1',
          status: 'present',
          markedByUserId: servantId,
        });
      });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertFails(updateDoc(doc(db, 'AttendanceSessions', sessionId, 'records', 'student-1_session-1'), {
        markedByUserId: 'other-user',
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

    test('new user cannot self-register with pre-seeded privileged fields', async () => {
      const newUid = 'new-user-preseeded';
      const db = testEnv.authenticatedContext(newUid).firestore();
      await assertFails(setDoc(doc(db, 'Users', newUid), {
        uid: newUid,
        name: 'Malicious Student',
        email: 'preseeded@example.com',
        role: 'student',
        isArchived: false,
        assignedSectorIds: ['sector-1'],
        assignedTeamIds: ['team-1'],
        assignedTeamId: 'team-1',
      }));
    });

    test('servant cannot update session to change teamId', async () => {
      const servantId = 'servant-1';
      const sessionId = 'session-123';
      await seedUser(servantId, { role: 'servant', assignedTeamIds: ['team-1', 'team-2'] });
      await seedSession(sessionId, { teamId: 'team-1' });
      const db = testEnv.authenticatedContext(servantId, { role: 'servant' }).firestore();
      await assertFails(updateDoc(doc(db, 'AttendanceSessions', sessionId), {
        teamId: 'team-2',
      }));
    });

    test('servant cannot update mark to change studentId or teamId', async () => {
      const servantId = 'servant-1';
      const sessionId = 'session-123';
      const markId = 'mark-123';
      await seedUser(servantId, { role: 'servant', assignedTeamIds: ['team-1'] });
      await seedSession(sessionId, { teamId: 'team-1' });
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'AttendanceSessions', sessionId, 'records', markId), {
          studentId: 'student-1',
          teamId: 'team-1',
          status: 'present',
          markedByUserId: servantId,
        });
      });
      const db = testEnv.authenticatedContext(servantId, { role: 'servant' }).firestore();
      await assertFails(updateDoc(doc(db, 'AttendanceSessions', sessionId, 'records', markId), {
        studentId: 'student-2',
      }));
      await assertFails(updateDoc(doc(db, 'AttendanceSessions', sessionId, 'records', markId), {
        teamId: 'team-2',
      }));
    });
  });

  // --- Tests: Admin Collection ---
  describe('Admin collection', () => {
    test('admin can read admin collection docs', async () => {
      const adminId = 'admin-1';
      await seedUser(adminId, { role: 'admin' });
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'admin', 'config'), {
          someKey: 'someValue',
        });
      });
      const db = testEnv.authenticatedContext(adminId, { role: 'admin' }).firestore();
      await assertSucceeds(getDoc(doc(db, 'admin', 'config')));
    });

    test('admin cannot write/update/delete admin collection docs', async () => {
      const adminId = 'admin-1';
      await seedUser(adminId, { role: 'admin' });
      const db = testEnv.authenticatedContext(adminId, { role: 'admin' }).firestore();
      await assertFails(setDoc(doc(db, 'admin', 'config'), {
        someKey: 'maliciousUpdate',
      }));
    });

    test('non-admin has zero access to admin collection docs', async () => {
      const servantId = 'servant-1';
      await seedUser(servantId, { role: 'servant' });
      const db = testEnv.authenticatedContext(servantId, { role: 'servant' }).firestore();
      await assertFails(getDoc(doc(db, 'admin', 'config')));
      await assertFails(setDoc(doc(db, 'admin', 'config'), {
        someKey: 'unauthorized',
      }));
    });
  });

  // --- Tests: Active Status & Teacher Role ---
  describe('Active Status & Teacher Role Rules', () => {
    test('archived servant (isArchived: true) is denied read and write access', async () => {
      const servantId = 'servant-archived-1';
      const teamId = 'team-archived-1';
      await seedUser(servantId, { assignedTeamId: teamId, role: 'servant', isArchived: true });
      await seedStudent('student-archived-1', { classId: teamId });

      const db = testEnv.authenticatedContext(servantId, { role: 'servant', assignedTeamId: teamId }).firestore();
      await assertFails(getDoc(doc(db, 'Students', 'student-archived-1')));
      await assertFails(updateDoc(doc(db, 'Students', 'student-archived-1'), { name: 'New Name' }));
    });

    test('teacher role can read team students and create attendance session', async () => {
      const teacherId = 'teacher-1';
      const teamId = 'team-teacher-1';
      await seedUser(teacherId, { assignedTeamId: teamId, role: 'teacher', isArchived: false });
      await seedStudent('student-teacher-1', { classId: teamId });

      const db = testEnv.authenticatedContext(teacherId, { role: 'teacher', assignedTeamId: teamId }).firestore();
      await assertSucceeds(getDoc(doc(db, 'Students', 'student-teacher-1')));
      await assertSucceeds(setDoc(doc(db, 'AttendanceSessions', 'session-teacher-1'), {
        teamId: teamId,
        startsAt: '2026-03-09T18:00:00Z',
        isClosed: false,
      }));
    });
  });
});
