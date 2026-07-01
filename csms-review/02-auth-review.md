# Auth System Review

## Scope: FirebaseAuthRepository, Local Stores, Auth BLoC, Admin Provisioning

---

### 1. Firebase Auth Repository (`firebase_auth_repository.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| **Wrong auth stream** | Uses `.idTokenChanges()` instead of `.authStateChanges()`. Token refreshes every ~60 min trigger unnecessary Firestore profile re-fetches. | 🟠 Important |
| Offline recovery | Falls back to Hive cached profile when Firestore unavailable | ✅ |
| Sign-out | Properly clears Hive and Firebase auth on sign-out | ✅ |
| Error handling | Catches FirebaseAuthException with specific error codes | ✅ |

### 2. Auth User Local Store (`auth_user_local_store.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Encryption | AES-256 encryption with key stored in `FlutterSecureStorage` | ✅ |
| Hive storage | User data persisted in encrypted Hive box | ✅ |
| Token management | Auth tokens securely persisted | ✅ |

### 3. Auth User Profile Store (`auth_user_profile_store.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| Profile caching | 30-min TTL caching with `_cachedGet` | ✅ |
| Read strategy | Tries Firestore cache first, then server (reduces reads) | ✅ |
| Cache invalidation | Proper invalidation on profile updates | ✅ |

### 4. Auth BLoC (`auth_bloc.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| State coverage | `AuthInitial`, `Authenticated`, `Unauthenticated`, `AuthLoading`, `AuthError`, `DegradedPermission`, `AccountInactive`, `EmailVerificationPending`, `ProfileSyncFailure` | ✅ |
| Edge cases | Handles email not verified, account inactive, degraded permissions | ✅ |
| Event handling | Clean event-driven architecture with mapEventToState | ✅ |

### 5. Admin User Provisioning (`admin_user_provisioning_service.dart`)

| Aspect | Finding | Severity |
|--------|---------|----------|
| User creation | Creates Firestore user doc with `isActive`, role, email | ✅ |
| No custom claims | Uses Firestore doc flags (Spark plan compliant) | ✅ |
| **No transaction** | Checks existence via `_db.collection(users).doc(email).get()` then writes — race condition if two admins provision same email concurrently | 🟡 Minor |
| **Double `isActive` check** | Reads servant doc from Firestore on every `checkStatus()` call with no caching — increased Firestore reads on every app launch | 🟠 Important |

---

## Recommendations

1. **🟠 Important**: Switch to `.authStateChanges()` to avoid unnecessary 60-min profile re-fetches.
2. **🟠 Important**: Cache `isActive` status in Hive on first read; only re-check on explicit events (role change, admin action).
3. **🟡 Minor**: Wrap user creation in a Firestore Transaction to prevent duplicate provisioning race condition.
