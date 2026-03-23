# Phase 2 — Auth & Splash Screens

## Goal
Refactor the Splash Screen and Login Screen to exactly match Stitch designs while using
Phase 1 atomic widgets and Ochre Sanctuary tokens.

---

## Stitch References
| Screen | Stitch ID | Screenshot URL |
|---|---|---|
| Splash Screen (Restored) | `6fa54652fca14a8cb2e4d1da296b8328` | [View](https://lh3.googleusercontent.com/aida/ADBb0ujrXiMZRMdRZ7Nunfjq91uq8Av-viCT0SqiMtHUwVdOWPuSWLu7-gAx8EeYz1IeF7F8IqHpxiXVkm_mPk9g6qftmP15Pfsdl-ZHqgHPT5trcox-kYm33zLwa1SfjcS12nyQPYxwICmS56MF3_iVSXRAxIeOSIrbxsUVoI-g2pPOjgJ4P105yej8zIVRZ0dTEPnOB6B9Mg-7vxm9fp1kY8G217PDhI_HVzOfkMxRfxY4MCRA84Z_gB-zYMCn) |
| Login Screen with Logo | `1fe08fff9379424e80ddbd2b008b475b` | [View](https://lh3.googleusercontent.com/aida/ADBb0uh3iB-574S38Q6RzAuSIV9vsBZsXo6XBHF63rKbvkS3_cBEWByrAgAzKT46D3PN4Vi88EgmHN7OUdg8Yr6xJWH2HeZcAz-Jf9JW3gbYCTdcESaQoZf6RrVNhuPJcL5miMFIS2QaDchxcixwTOZHU7Kw7C7C2PJq3qMpqxXYPr0ntFWxQQKLuE4iAJ3j6EhjUl9Y6IQJ7F5UfaPFNkSTixbtrGntw-ByaZKlGz39qv4G-7-4CroU_hze-AFE) |

---

## Screen Designs (from Stitch)

### Splash Screen
- Full-screen `AppColors.background` canvas
- Centered logo (`logo_elkarooz.png`) — large, ~120px height
- App name below logo in `displayLarge` typography
- Decorative background blobs (primary/20, blur 100px) top-left and bottom-right
- Animated: logo fades in + scales from 0.8→1.0 on load (400ms ease-out)
- Auto-navigates after 2s via GoRouter redirect based on auth state

### Login Screen
- `AppScreenShell` wrapper (background + blob decorations)
- `AppHeader` at top: logo + church name
- Main card (`AppSectionCard`) centered:
  - Welcome title: `displayLarge`
  - Email input: `AppInputField` with email icon
  - Password input: `AppInputField` with lock icon, obscure toggle
  - Forgot password link: `AppTextButton`
  - Login button: `AppPrimaryButton`, full-width
- Error message area (red, below button) — driven by BLoC state
- RTL layout enforced via `Directionality`

---

## Implementation Plan

### 2.1 Splash Screen
**File:** `lib/features/auth/presentation/screens/splash_screen.dart`

```dart
class SplashScreen extends StatefulWidget {
  // Animates logo in, then navigates based on AuthBloc state
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  // initState: set up 400ms ease-out animations
  // listener on AuthBloc → navigate after animation completes (~2s)
}
```

- Navigation: already handled by `GoRouter` redirect; splash screen just shows branded intro
- No logic beyond animation + 2-second delay

### 2.2 Login Screen Full Refactor
**File:** `lib/features/auth/presentation/screens/login_screen.dart`

- Replace existing impl with decomposed private widgets:
  - `_LoginHeader` — logo + title
  - `_LoginForm` — form fields + buttons
  - `_LoginError` — error text from BLoC state
- Use `AppPrimaryButton(isLoading: state.isSubmitting)`
- Use `AppInputField` for email and password
- BLoC integration: existing `AuthBloc` — no domain changes
- `Form` key for validation, `AutovalidateMode.onUserInteraction`

### 2.3 Animation Skill Application
Following `flutter-animating-apps` skill:
- Use `AnimationController` + `CurvedAnimation` for splash
- Use hero animation for logo transition (splash → login)
  - Tag the logo in both screens with same `heroTag`

---

## Affected Files
| Action | File |
|---|---|
| NEW | `lib/features/auth/presentation/screens/splash_screen.dart` |
| MODIFY | `lib/features/auth/presentation/screens/login_screen.dart` |
| VERIFY | `lib/core/routing/` — ensure splash route exists and redirect logic is correct |
| POSSIBLY MODIFY | `lib/core/routing/app_router.dart` — add `/splash` initial route |

---

## Out of Scope (Phase 2)
- Register screen, Forgot Password screen, Verify Email screen — deferred to after MVP
  (those screens are not in the Stitch set; refactor to Ochre Sanctuary styles but no new design)
