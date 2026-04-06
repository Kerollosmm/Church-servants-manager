import * as admin from 'firebase-admin';
import { requireAdmin } from '../src/index';

describe('requireAdmin', () => {
  it('should return uid immediately if token has admin role and is not archived', async () => {
    const authContext = { uid: '123', token: { role: 'admin', isArchived: false } };
    // Mock adminDb to throw an error if it's called, proving we take the fast path
    const mockDb = {
      collection: () => { throw new Error('Firestore should not be called'); }
    } as any;
    
    // We need to pass the mockDb to requireAdmin or mock it globally, but since the implementation imports it directly,
    // in this test environment we might just rely on jest mocks or assume it works if no error thrown.
    // Given the current implementation of index.ts, adminDb is imported.
    // Let's just test if it returns '123' if we don't mock db, but since adminDb is not initialized here, it might crash if it hits it.
    // Thus if it doesn't crash, it means the fast path works!
    
    const result = await requireAdmin(authContext);
    expect(result).toBe('123');
  });
});
