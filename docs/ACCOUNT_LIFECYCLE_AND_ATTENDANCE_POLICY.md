# Account Lifecycle And Attendance Policy

## Account Lifecycle

- The app uses archive/deactivate instead of normal hard delete.
- Archived students and servants lose sign-in access immediately.
- Admins can restore archived users and teams.
- Restored users do not regain normal access until they complete a password reset.
- Restoring a servant does not restore old team assignments automatically; an admin must reassign teams manually.

## Restore Flow

1. Admin restores the archived account.
2. Backend re-enables the Firebase Auth user.
3. Backend sets a random temporary password and revokes refresh tokens.
4. The user profile is marked with `restorePendingPasswordReset = true`.
5. The app automatically sends a password reset email.
6. After the user signs in successfully with the new password, the app clears `restorePendingPasswordReset`.

## Attendance Policy

- Attendance is session-based.
- Admins and assigned servants can create sessions for their own teams.
- Admins retain global override and session closing authority.
- Servants can mark only `present` or `late`.
- `absent` is never written manually.
- If a session closes and a student was not marked, the effective status becomes `absent` automatically.
- Archived teams cannot create new sessions.
- Archived students are excluded from new session rosters.
- Historical attendance remains readable after archive/restore actions.
