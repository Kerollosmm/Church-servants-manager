# Quickstart: Protect Student Attendance Access

**Branch**: `011-fix-student-access` | **Date**: 2026-03-24

Use this guide to implement and verify the student attendance access fix.

## Prerequisites

- Flutter SDK available for repository validation
- Node 20 available for the existing `functions/` package
- Firebase CLI installed and authenticated
- Firestore emulator available locally

## Step 1: Prepare the rules test environment

```bash
npm install --prefix functions
```

Add or update the rules test command in `functions/package.json`, then ensure the rules test
suite can load the repo-root `firestore.rules` file.

## Step 2: Update the ownership rule

Apply the rule change in `firestore.rules` so `isOwnStudent(studentId)` resolves the student
profile document and compares its `linkedUser` field to the signed-in user ID.

Also verify that student mark reads call the ownership helper while servant reads still use
their existing team-based authorization path.

## Step 3: Add emulator verification scenarios

Create emulator fixtures for:
- student reads own mark -> allow
- student reads another student's mark -> deny
- student reads mark without linked user -> deny
- servant reads authorized mark -> unchanged baseline behavior

Run the rules tests:

```bash
npm test --prefix functions
```

## Step 4: Run repository safety checks

```bash
flutter analyze
```

## Step 5: Deploy the updated rules

```bash
firebase deploy --only firestore:rules
```

## Step 6: Perform smoke verification

- Confirm a linked student can read only their own attendance mark.
- Confirm a linked student is denied when reading another student's mark.
- Confirm servant attendance reads continue to behave as before.
