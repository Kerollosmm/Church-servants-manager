import * as admin from "firebase-admin";
import { assignRole } from "../src/admin_roles";

describe("assignRole", () => {
  it("fails if not admin", async () => {
    const req: any = { data: { targetUid: '123', newRole: 'servant' }, auth: { uid: '456', token: { role: 'student' } } };
    await expect(assignRole(req)).rejects.toThrow('permission-denied');
  });
});
