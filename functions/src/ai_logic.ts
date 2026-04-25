import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { adminDb } from './admin';
import { VertexAI } from '@google-cloud/vertexai';

// Authentication Helper
async function requireServant(
  auth: { token?: Record<string, unknown>; uid?: string } | null | undefined,
): Promise<string> {
  const uid = auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }

  // Fast path: use custom claim
  if ((auth?.token?.role === 'servant' || auth?.token?.role === 'admin') && auth?.token?.isArchived !== true) {
    return uid;
  }

  // Slow path: verify from Firestore
  const userDoc = await adminDb.collection('Users').doc(uid).get();
  const userData = userDoc.data();
  if (userData?.isArchived === true) {
    throw new HttpsError('permission-denied', 'This account has been archived.');
  }
  if (userData?.role !== 'servant' && userData?.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only servants and admins can access AI insights.');
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
 * US-01: Servant Get Trend Insight
 */
export const getAttendanceInsight = onCall<{ groupId: string; question: string }>(async (request) => {
  const callerUid = await requireServant(request.auth);
  const { groupId, question } = request.data;

  if (!groupId) {
    throw new HttpsError('invalid-argument', 'Missing groupId.');
  }

  // 1. Fetch group data
  const classDoc = await adminDb.collection('Classes').doc(groupId).get();
  if (!classDoc.exists) {
    throw new HttpsError('not-found', 'Group not found.');
  }
  const classData = classDoc.data()!;

  // 2. Fetch aggregated metrics (from denormalized fields)
  const groupSummary = classData.groupAttendanceSummary || {};
  
  // 3. Construct Prompt (PII Safe)
  const prompt = `
    You are an AI assistant for a church attendance system.
    Current Group: ${classData.name || groupId}
    Aggregated Metrics: ${JSON.stringify(groupSummary)}
    
    User Question: "${question}"
    
    Instructions:
    - Provide a concise (2-3 sentences) analysis of the attendance trends.
    - Identify any significant drops or positive streaks.
    - DO NOT use individual student names if they were not provided in the metrics.
    - Suggest 2 actionable steps for the servant.
    - Return a JSON object with keys "insight" (string) and "actions" (array of strings).
  `;

  try {
    const model = getAI().getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent(prompt);
    const responseText = result.response.candidates?.[0].content.parts[0].text || '{}';
    
    // Clean JSON if model wrapped it in markdown
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const finalData = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText);

    return {
      insight: finalData.insight || 'No insight generated.',
      actions: finalData.actions || [],
    };
  } catch (error) {
    console.error('AI Insight Error:', error);
    throw new HttpsError('internal', 'Failed to generate AI insight.');
  }
});

/**
 * US-02: Servant Smart Query
 */
export const smartQuery = onCall<{ query: string }>(async (request) => {
  await requireServant(request.auth);
  const { query } = request.data;

  // 1. Construct Prompt for Query Parsing
  const prompt = `
    You are a Firestore query translator for a church management system.
    Translate the natural language query: "${query}" into a set of structured filters for the "Students" collection.
    
    Fields available: name, mobile, group, classId, grade, isArchived, attendanceSummary.
    
    Instructions:
    - If the query asks for "absent students", filter by "attendanceSummary.isAtRisk" == true (hypothetical field).
    - If the query mentions a grade, filter by "grade" == [number].
    - Return a JSON object with:
      "message": A human-readable summary of what you found.
      "filters": An array of [field, operator, value].
      "limit": Number of records.
  `;

  try {
    const model = getAI().getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent(prompt);
    const responseText = result.response.candidates?.[0].content.parts[0].text || '{}';
    
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const finalData = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText);

    // Note: In a production app, we would use finalData.filters to actually query Firestore.
    // For this MVP, we return the parsed intent to show the user it understood.
    return {
      message: finalData.message || 'I understood your query and I am searching...',
      filters: finalData.filters || [],
      limit: finalData.limit || 20
    };
  } catch (error) {
    console.error('Smart Query Error:', error);
    throw new HttpsError('internal', 'Failed to process smart query.');
  }
});
