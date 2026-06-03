# TypeScript Development Skill

Use this skill when developing or refactoring TypeScript code, particularly for Firebase Cloud Functions.

## Core Objectives
- **Type Safety:** Ensure strict typing across the codebase. Avoid `any` at all costs.
- **Firebase Best Practices:** Follow recommended patterns for Cloud Functions, including proper error handling, idempotency, and resource management.
- **Code Intelligence:** Simulate LSP capabilities (Go to Definition, Find References) using `grep` and `read_file` tools.

## Key Guidelines
1. **Strict Typing:** Always define interfaces or types for request payloads, response data, and Firestore documents.
2. **Cloud Functions Patterns:**
   - Use `functions.https.onCall` for client-triggered functions.
   - Use `functions.firestore.document().onWrite()` for database triggers.
   - Always use `runTransaction` for administrative tasks to prevent race conditions.
3. **Error Handling:** Use `functions.https.HttpsError` for HTTPS functions to provide meaningful error codes to the client.
4. **Environment Config:** Use `functions.config()` or secret manager for sensitive credentials.

## Simulating LSP
- **Go to Definition:** Search for `class Name`, `interface Name`, or `function name` using `grep`.
- **Find References:** Search for the symbol name using `grep`, filtering for relevant file extensions.
- **Type Info:** Read the file where the symbol is defined to understand its type structure.

## Verification
- Run `npm run build` in the `functions/` directory to check for compilation errors.
- Run `npm run lint` to ensure code style compliance.
- Run tests in `functions/test/` using `npm test`.
