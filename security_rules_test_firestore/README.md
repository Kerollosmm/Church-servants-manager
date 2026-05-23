# Firestore Security Rules Unit Tests

This project contains a comprehensive unit test suite for the CSMS Firestore Security Rules.

## Prerequisites

- **Node.js 18+** installed
- **Firebase CLI** installed (`npm install -g firebase-tools`)
- **Java JRE** installed (required for the Firebase Emulator)

## Installation

1. Navigate to this directory:
   ```bash
   cd security_rules_test_firestore
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Running Tests

### 1. Start the Emulator
In a **separate terminal window**, navigate to this directory and start the Firestore emulator:
```bash
npx firebase emulators:start --only firestore
```

### 2. Run the Test Suite
In your **original terminal**, run the tests:
```bash
npm test
```

## Test Coverage

The test suite covers:
- **Authentication**: Verifies that only signed-in users can access the database.
- **RBAC (Role-Based Access Control)**: Validates permissions for Admins, Servants, and Students.
- **Data Integrity**: Ensures immutable fields (roles, UIDs) cannot be tampered with.
- **Attendance Flow**: Tests roster-based validation for marking attendance.
- **Result Isolation**: Ensures students can only see their own results, while authorized servants can see their group's results.

## Deploying Rules

Once the tests pass, you can deploy the rules to production:
```bash
firebase deploy --only firestore:rules
```

## Troubleshooting

- **Emulator not starting**: Ensure no other process is using port 8080.
- **Tests failing with 403**: This is often expected for "Unauthorized" test cases. Check if the test expectation matches the rule logic.
- **Java errors**: Ensure `java -version` returns a valid JRE version.
