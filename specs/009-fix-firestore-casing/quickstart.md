# Quickstart: Fix Firestore Collection Casing

## Goal

Apply the Firestore collection casing correction with minimal scope and verify that all Firestore path consumers now use lowercase canonical names.

## Implementation Steps

1. Update the string values in `lib/core/constants/firestore_collections.dart` to lowercase canonical names.
2. Search the repository for hardcoded quoted Firestore path strings `Users`, `Students`, and `Classes`.
3. Normalize only in-scope Firestore path literals in:
   - Flutter app code under `lib/`
   - Firebase Cloud Functions under `functions/`
   - Tests under `test/`
   - Firestore index configuration in `firestore.indexes.json`
4. Do not rename Dart classes, constant members, or unrelated identifiers.
5. Annotate changed production code lines with `// FIX [009]: align Firestore path casing` where constitutionally required.

## Verification Steps

1. Run repo-wide search to confirm no in-scope uppercase Firestore path literals remain.
2. Run `flutter analyze`.
3. Run the targeted regression suites most directly impacted by Firestore path usage.
4. Confirm the diff is limited to string-value normalization and direct path literals.

## Expected Result

- The app, backend, tests, and Firestore index configuration all use `users`, `students`, and `classes` as the canonical Firestore collection names.
- Existing callers continue compiling because identifiers are unchanged.
- Targeted automated checks remain green.
