const test = require('node:test');
const assert = require('node:assert/strict');

const {
  parseCreateRequest,
  parseStudentCreateRequest,
  buildStudentProfile,
  deleteAuthUserIfExists,
  deleteDocIfExists,
} = require('../lib/lifecycle_helpers');

// ─── parseCreateRequest ──────────────────────────────────────────

test('parseCreateRequest normalizes provisioning payloads', () => {
  const result = parseCreateRequest({
    email: ' Admin@Example.COM ',
    password: ' secret1 ',
    name: ' Admin User ',
    role: 'admin',
  });

  assert.equal(result.email, 'admin@example.com');
  assert.equal(result.password, 'secret1');
  assert.equal(result.name, 'Admin User');
  assert.equal(result.role, 'admin');
});

test('parseCreateRequest rejects missing fields', () => {
  assert.throws(
    () => parseCreateRequest({ email: 'a@b.com', password: 'secret', name: 'Test' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Missing'),
  );
});

test('parseCreateRequest rejects invalid email format', () => {
  assert.throws(
    () => parseCreateRequest({ email: 'not-an-email', password: 'secret', name: 'Test', role: 'admin' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Invalid email'),
  );
});

test('parseCreateRequest rejects short password', () => {
  assert.throws(
    () => parseCreateRequest({ email: 'a@b.com', password: 'ab', name: 'Test', role: 'admin' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('6 characters'),
  );
});

test('parseCreateRequest rejects invalid role', () => {
  assert.throws(
    () => parseCreateRequest({ email: 'a@b.com', password: 'secret', name: 'Test', role: 'owner' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Invalid role'),
  );
});

// ─── parseStudentCreateRequest ───────────────────────────────────

test('parseStudentCreateRequest accepts valid input with all fields', () => {
  const result = parseStudentCreateRequest({
    email: ' Student@Example.COM ',
    password: ' secret1 ',
    name: ' Student Name ',
    group: 'year1',
    classId: 'team-1',
    phone: '1234567890',
  });

  assert.equal(result.email, 'student@example.com');
  assert.equal(result.password, 'secret1');
  assert.equal(result.name, 'Student Name');
  assert.equal(result.group, 'year1');
  assert.equal(result.classId, 'team-1');
  assert.equal(result.phone, '1234567890');
});

test('parseStudentCreateRequest accepts valid input with only required fields', () => {
  const result = parseStudentCreateRequest({
    email: 'a@b.com',
    password: 'secret',
    name: 'Test',
  });

  assert.equal(result.email, 'a@b.com');
  assert.equal(result.group, null);
  assert.equal(result.classId, null);
  assert.equal(result.phone, null);
});

test('parseStudentCreateRequest rejects missing email', () => {
  assert.throws(
    () => parseStudentCreateRequest({ password: 'secret', name: 'Test' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Missing'),
  );
});

test('parseStudentCreateRequest rejects missing password', () => {
  assert.throws(
    () => parseStudentCreateRequest({ email: 'a@b.com', name: 'Test' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Missing'),
  );
});

test('parseStudentCreateRequest rejects missing name', () => {
  assert.throws(
    () => parseStudentCreateRequest({ email: 'a@b.com', password: 'secret' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Missing'),
  );
});

test('parseStudentCreateRequest rejects bad email format', () => {
  assert.throws(
    () => parseStudentCreateRequest({ email: 'not-an-email', password: 'secret', name: 'Test' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Invalid email'),
  );
});

test('parseStudentCreateRequest rejects short password', () => {
  assert.throws(
    () => parseStudentCreateRequest({ email: 'a@b.com', password: 'ab', name: 'Test' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('6 characters'),
  );
});

test('parseStudentCreateRequest rejects invalid group', () => {
  assert.throws(
    () => parseStudentCreateRequest({ email: 'a@b.com', password: 'secret', name: 'Test', group: 'year4' }),
    (err) => err.code === 'invalid-argument' && err.message.includes('Invalid group'),
  );
});

// ─── buildStudentProfile ─────────────────────────────────────────

test('buildStudentProfile includes all fields when populated', () => {
  const doc = buildStudentProfile({
    uid: 'uid-1',
    name: 'Test Student',
    email: 'test@example.com',
    group: 'year2',
    classId: 'team-3',
    phone: '0987654321',
  });

  assert.equal(doc.uid, 'uid-1');
  assert.equal(doc.name, 'Test Student');
  assert.equal(doc.email, 'test@example.com');
  assert.equal(doc.group, 'year2');
  assert.equal(doc.classId, 'team-3');
  assert.equal(doc.phone, '0987654321');
  assert.equal(doc.isArchived, false);
  assert.equal(doc.role, 'student');
  assert.ok(doc.createdAt instanceof Date);
  assert.ok(doc.updatedAt instanceof Date);
});

test('buildStudentProfile sets nullable fields to null', () => {
  const doc = buildStudentProfile({
    uid: 'uid-2',
    name: 'No Extras',
    email: 'no@extras.com',
    group: null,
    classId: null,
    phone: null,
  });

  assert.strictEqual(doc.group, null);
  assert.strictEqual(doc.classId, null);
  assert.strictEqual(doc.phone, null);
});

// ─── deleteAuthUserIfExists ──────────────────────────────────────

test('deleteAuthUserIfExists returns success on delete', async () => {
  const mockAuth = {
    deleteUser: async () => {},
  };

  const result = await deleteAuthUserIfExists(mockAuth, 'uid-1');
  assert.equal(result.success, true);
  assert.equal(result.error, null);
});

test('deleteAuthUserIfExists returns success on not-found', async () => {
  const mockAuth = {
    deleteUser: async () => {
      throw new Error('There is no user record corresponding to the provided identifier.');
    },
  };

  const result = await deleteAuthUserIfExists(mockAuth, 'uid-missing');
  assert.equal(result.success, true);
  assert.equal(result.error, null);
});

test('deleteAuthUserIfExists returns failure on other errors', async () => {
  const mockAuth = {
    deleteUser: async () => {
      throw new Error('Unexpected database error');
    },
  };

  const result = await deleteAuthUserIfExists(mockAuth, 'uid-1');
  assert.equal(result.success, false);
  assert.equal(result.error, 'Unexpected database error');
});

// ─── deleteDocIfExists ───────────────────────────────────────────

test('deleteDocIfExists returns success on delete', async () => {
  const mockDb = {
    collection: (name) => ({
      doc: (id) => ({
        delete: async () => ({}),
      }),
    }),
  };

  const result = await deleteDocIfExists(mockDb, 'Users', 'uid-1');
  assert.equal(result.success, true);
  assert.equal(result.error, null);
});

test('deleteDocIfExists returns success on not-found', async () => {
  const mockDb = {
    collection: (name) => ({
      doc: (id) => ({
        delete: async () => {
          throw new Error('no document to update');
        },
      }),
    }),
  };

  const result = await deleteDocIfExists(mockDb, 'Users', 'uid-missing');
  assert.equal(result.success, true);
  assert.equal(result.error, null);
});

test('deleteDocIfExists returns failure on other errors', async () => {
  const mockDb = {
    collection: (name) => ({
      doc: (id) => ({
        delete: async () => {
          throw new Error('Permission denied');
        },
      }),
    }),
  };

  const result = await deleteDocIfExists(mockDb, 'Users', 'uid-1');
  assert.equal(result.success, false);
  assert.equal(result.error, 'Permission denied');
});
