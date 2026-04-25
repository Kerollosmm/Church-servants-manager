import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { adminDb } from './admin';
import { VertexAI } from '@google-cloud/vertexai';

// Authentication Helper (Student)
async function requireStudent(
  auth: { token?: Record<string, unknown>; uid?: string } | null | undefined,
): Promise<string> {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  return uid;
}

// AI Client Initialization (Lazy)
let vertexAI: VertexAI | null = null;
function getAI() {
  if (!vertexAI) {
    vertexAI = new VertexAI({ project: process.env.GCLOUD_PROJECT, location: 'us-central1' });
  }
  return vertexAI;
}

/**
 * US-03: Student Get Encouragement
 */
export const getStudentEncouragement = onCall<{ studentId?: string }>(async (request) => {
  const callerUid = await requireStudent(request.auth);
  
  // A student can only get their own encouragement, or an admin/servant can specify studentId
  const targetUid = request.data.studentId || callerUid;
  
  // Security check: If caller is student, they MUST be requesting their own data
  if (request.auth?.token?.role === 'student' && targetUid !== callerUid) {
    throw new HttpsError('permission-denied', 'Students can only view their own encouragement.');
  }

  // 1. Fetch student data
  const studentSnap = await adminDb.collection('Students').where('uid', '==', targetUid).limit(1).get();
  if (studentSnap.empty) {
    throw new HttpsError('not-found', 'Student record not found.');
  }
  const studentData = studentSnap.docs[0].data();
  const firstName = studentData.name?.split(' ')[0] || 'Student';

  // 2. Fetch summary metrics
  const summary = studentData.attendanceSummary || {};

  // 3. Construct Prompt
  const prompt = `
    You are a supportive church youth leader. 
    Student Name: ${firstName}
    Attendance Summary: ${JSON.stringify(summary)}    
    Instructions:
    - Write a short, friendly, and motivational message (1-2 sentences) based on their attendance.
    - If they have a high streak, congratulate them.
    - If they missed sessions, give gentle encouragement to return.
    - Return a JSON object with key "encouragement" (string).
  `;

  try {
    const model = getAI().getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent(prompt);
    const responseText = result.response.candidates?.[0].content.parts[0].text || '{}';
    
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const finalData = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText);

    return {
      encouragement: finalData.encouragement || 'Keep growing in faith and fellowship!',
    };
  } catch (error) {
    console.error('Student AI Error:', error);
    // Return a default message instead of failing, to preserve user experience
    return {
      encouragement: 'We are so glad to have you in our community! See you next time.',
    };
  }
});
