# Phase 1 — Auth & Roles: Data Model

## AuthUser (existing — reference only, do not change)
```
AuthUser {
  uid: String
  email: String
  name: String
  role: UserRole          // admin | servant | student
  isEmailVerified: bool
  teamId: String?
  isArchived: bool
}
```

## AuthState Transitions
```
AuthInitial
  └─ AuthEventCheckStatus ──► AuthLoading
       ├─ user == null          ──► AuthUnauthenticated
       ├─ !emailVerified        ──► AuthNeedsVerification
       ├─ isArchived            ──► AuthArchived(message, email)
       ├─ degraded claims       ──► AuthDegraded(user, message)
       └─ ok                   ──► AuthAuthenticated(user)

AuthAuthenticated / AuthDegraded
  └─ AuthEventSignOut ──► AuthUnauthenticated

AuthUnauthenticated
  └─ LoginScreen → AuthEventSignIn
  └─ RegisterScreen → AuthEventSignUp

AuthNeedsVerification
  └─ VerifyEmailScreen → AuthEventSendVerification / AuthEventRefreshUser

AuthError(message)
  └─ render inline error banner
```

## Collection Casing Contract
| Firestore path | Correct casing |
|----------------|---------------|
| `Users/{uid}` | capital **U** |
| `Users/{uid}/role` | field on user doc |

## AdminGate Input/Output Contract
```
Input:  AuthBloc state (from context)
Output: child widget  ── if AuthAuthenticated && role == admin
        redirect push  ── if any other state
```

## Firestore Security Rule Sketch (users collection)
```javascript
match /Users/{userId} {
  allow read: if request.auth.uid == userId
               || isAdmin();
  allow write: if isAdmin();
}
```
