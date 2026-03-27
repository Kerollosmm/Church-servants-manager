# CSMS — Senior Flutter Architect Review
> Reviewed: 2026-03-27 | Focus: Logic, BLoC, Architecture (No UI)

---

## 📁 auth_repository.dart (Domain)
━━━━━━━━━━━━━━━━━━━━
✅ Clean abstract contract — no Firebase imports leaked into domain layer  
✅ Method signatures use primitive types / domain models only  
❌ **Line 1** — imports `auth_user.dart` from the **data** layer directly into the domain repo interface. `AuthUser` is a freezed+firebase model (it imports `firebase_auth`), which means the domain layer has an indirect Firebase dependency.  
⚠️ Suggestion: Introduce a pure domain `UserEntity` or move `AuthUser` to domain and strip Firebase imports from it.  
🔧 Fix:
```dart
// domain/entities/user_entity.dart  (pure Dart, no firebase import)
class UserEntity {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isEmailVerified;
  final bool isArchived;
  // ...
}
```
━━━━━━━━━━━━━━━━━━━━
📊 Score: 7/10 — Logic Quality

---

## 📁 auth_failures.dart + auth_exceptions.dart (Domain)
━━━━━━━━━━━━━━━━━━━━
✅ Custom `AuthFailure` hierarchy — good domain-level error abstraction  
✅ Specific failure types for each scenario (UserNotFound, WrongPassword, WeakPassword, etc.)  
❌ **Dual-layer redundancy**: Both `AuthFailure` (failures) and `AuthException` (exceptions) exist for the same errors. This creates confusion about which layer throws which, and the mapper in `AuthErrorMapper` must know both — violating SRP.  
❌ `AuthFailure` implements `Exception` — failures should NOT be exceptions; they are value objects representing error states, not thrown objects.  
⚠️ Suggestion: Remove the `AuthException` classes entirely. Let the data layer catch `FirebaseAuthException` and directly produce `AuthFailure`. Only keep one error model.  
🔧 Fix:
```dart
// Remove: auth_exceptions.dart entirely
// In AuthErrorMapper: catch FirebaseAuthException → return AuthFailure directly
// AuthFailure should NOT implement Exception
abstract class AuthFailure {
  final String message;
  const AuthFailure(this.message);
}
```
━━━━━━━━━━━━━━━━━━━━
📊 Score: 6/10 — Logic Quality

---

## 📁 sign_in_usecase.dart + sign_out_usecase.dart (Domain)
━━━━━━━━━━━━━━━━━━━━
✅ Single-responsibility — each use case does exactly one thing  
✅ Thin wrappers around repository — correct pattern  
✅ `const` constructors — good for DI  
❌ `SignInUseCase` returns `AuthUser` (data model), not a domain entity — couples domain to data layer  
❌ No error transformation — exceptions bubble raw from repository; use case should catch and wrap  
⚠️ Suggestion: Use cases should own error mapping so BLoC never sees raw exceptions.  
🔧 Fix:
```dart
Future<AuthUser> call({required String email, required String password}) async {
  try {
    return await _repository.signIn(email: email, password: password);
  } on AuthFailure {
    rethrow; // already mapped
  } catch (e) {
    throw GenericAuthFailure(e.toString());
  }
}
```
━━━━━━━━━━━━━━━━━━━━
📊 Score: 7/10 — Logic Quality

---

## 📁 observe_auth_state_usecase.dart (Domain)
━━━━━━━━━━━━━━━━━━━━
✅ Excellent session resolution pattern — `AuthSessionResolution` sealed-like class covers all states  
✅ Graceful degraded mode using `lastKnownAppUser` — good offline resilience  
✅ Properly isolates bootstrap/session logic from BLoC  
❌ **Line 3** — imports `AuthService` directly (a data-layer concrete class), violating Clean Architecture. The use case should only depend on the repository interface.  
❌ `degradedPermissionsMessage` is a hardcoded English string mixed with Arabic strings in same file — inconsistency  
⚠️ The `checkStatus()` method has a 2-second timeout that silently falls through to `null` — this may cause false "unauthenticated" flashes on slow connections.  
🔧 Fix:
```dart
// Depend on abstract interface, not concrete AuthService
class ObserveAuthStateUseCase {
  const ObserveAuthStateUseCase(this._authService); // IAuthService, not AuthService
  final IAuthService _authService;
  ...
}
```
━━━━━━━━━━━━━━━━━━━━
📊 Score: 7/10 — Logic Quality

---

## 📁 auth_service.dart (Data)
━━━━━━━━━━━━━━━━━━━━
✅ Properly implements `AuthRepository` interface  
✅ All async calls wrapped in try/catch with error mapping  
✅ `lastKnownAppUser` cache for degraded mode — smart offline fallback  
✅ `signOut()` clears `_lastKnownAppUser` — correct state cleanup  
❌ **Line 6** — `AuthService` implements `AuthRepository` AND exposes extra methods not in the interface (`sendEmailVerification`, `sendPasswordResetEmail`, `reloadUser`, `refreshCurrentAppUser`). This violates ISP — the interface should be extended, not the concrete class.  
❌ `currentUser` and `authStateChanges` are exposed publicly but are not part of `AuthRepository` interface — callers depending on concrete type bypass abstraction.  
⚠️ `_lastKnownAppUser` is mutable state inside a service — not thread-safe in theory (though Dart is single-threaded, it is a code smell).  
━━━━━━━━━━━━━━━━━━━━
📊 Score: 7/10 — Logic Quality

---

## 📁 firebase_auth_provider.dart (Data)
━━━━━━━━━━━━━━━━━━━━
✅ Implements `AuthProvider` interface — correct abstraction  
✅ `logIn()` handles archived accounts by signing out silently — good defensive programming  
✅ `getUserData()` has `forceRefresh` parameter for cache busting  
❌ Contains business logic: archived account check (`_signOutSilently`) belongs in domain/use-case, not the Firebase provider  
⚠️ `getUserData()` has no retry on network failure — a single timeout could block the user  
⚠️ `createUser()` is very long (80+ lines) — should be broken into private helpers  
━━━━━━━━━━━━━━━━━━━━
📊 Score: 7/10 — Logic Quality

---

## 📁 auth_error_mapper.dart (Data)
━━━━━━━━━━━━━━━━━━━━
✅ Centralized error mapping — single place to map Firebase → domain failures  
✅ Handles both `FirebaseAuthException` and custom exception types  
✅ Fallback `GenericAuthFailure` for unknown errors  
❌ Must handle BOTH `AuthException` types AND `FirebaseAuthException` — symptom of the dual-layer issue noted above  
❌ Arabic strings mixed with English — `'تم إيقاف هذا الحساب. تواصل مع الإدارة.'` should be in a localization file  
⚠️ `if (e is AuthFailure) return e;` at line 54 — if a failure somehow leaks as exception, it passes through silently. Consider logging.  
━━━━━━━━━━━━━━━━━━━━
📊 Score: 8/10 — Logic Quality

---

## 📁 auth_bloc.dart + auth_event.dart + auth_state.dart (Presentation)
━━━━━━━━━━━━━━━━━━━━
✅ Sealed `AuthEvent` and `AuthState` — exhaustive pattern matching possible  
✅ All states covered: Initial, Loading, Authenticated, Unauthenticated, NeedsVerification, Archived, Degraded, Error, VerificationSent, PasswordResetSent  
✅ `StreamSubscription` properly cancelled in `close()`  
✅ Internal events `_AuthEventSessionChanged` / `_AuthEventSessionError` — correct encapsulation  
✅ Uses all three use cases correctly — does NOT call repository directly  
❌ **Line 17** — `AuthBloc` still holds a direct reference to `AuthService` (concrete class) for `signUp`, `sendEmailVerification`, `sendPasswordResetEmail`. These operations bypass use cases.  
❌ **auth_bloc_handlers.dart line 63** — `_handleSignUp` calls `bloc._authService.signUp(...)` directly instead of a `SignUpUseCase` — logic leak!  
❌ **auth_bloc_handlers.dart line 91** — `_handleSendVerification` calls `bloc._authService.sendEmailVerification()` directly — missing use case.  
🔧 Fix:
```dart
// Create SignUpUseCase and SendVerificationUseCase
// Inject them into AuthBloc instead of AuthService directly
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;
  final SignUpUseCase _signUpUseCase;           // NEW
  final SendVerificationUseCase _sendVerificationUseCase; // NEW
  final ObserveAuthStateUseCase _observeAuthStateUseCase;
  // Remove: final AuthService _authService;
}
```
━━━━━━━━━━━━━━━━━━━━
📊 Score: 6/10 — Logic Quality
