# Login Screen Refactoring Plan (Ochre Sanctuary)

## Objective
Refactor the Authentication Login Screen to match the new "Ochre Sanctuary" design system. The implementation will focus on pixel-perfect accuracy, high performance (strict 60fps), and clean, maintainable architecture with zero dead code.

## Key Files & Context
- **Target File:** `lib/features/auth/presentation/screens/login_screen.dart`
- **Design Reference:** `DESIGN.md` and `UI/login_screen_with_logo/code.html`
- **Theme Constraints:** Primary color `#a58255`, background `#f7f7f6`, rounded-xl (12px), RTL layout.

## Subagent Review & Strategy

### 1. Frontend Design (Visuals & Layout)
- **Background:** Instead of expensive `BackdropFilter` blurs, we will use `RadialGradient` containers to simulate the blurred blobs. This achieves the exact visual aesthetic without the massive raster thread cost.
- **Card-on-Canvas:** The main layout will be a centered white `Container` over the light background, utilizing `shadow-xl`.
- **Form Elements:** Inputs will be restyled with `#f7f7f6` fill, `primary/20` borders, and leading icons (right-aligned for RTL). The primary button will feature the solid Ochre color with an ambient `shadow-primary/30`.

### 2. Performance Optimization
- **Minimal Rebuilds:** The `obscurePassword` state will be managed via a localized `ValueNotifier<bool>` and `ValueListenableBuilder` inside the password field, ensuring the toggle does not rebuild the entire `Scaffold` or `Form`.
- **Const Constructors:** The widget tree will be aggressively structured to use `const` modifiers for padding, static text, and decorations to short-circuit rebuild passes.
- **Raster Efficiency:** Avoiding `Opacity`, `ClipRRect` (where possible), and `saveLayer()` to ensure the UI thread and Raster thread stay well under the 16ms budget.

### 3. Code Architecture & Cleanliness
- **Component Extraction:** We will extract reusable widgets to keep `login_screen.dart` declarative and clean:
  - `OchreAuthCard`: The main floating container.
  - `OchreTextField`: The stylized text input.
  - `OchreButton`: The primary solid button with ambient shadow.
- **Dead Code Removal:** Any unused legacy widgets (e.g., `GradientBorderContainer` if completely replaced by the new design) will be removed or deprecated properly.
- **BLoC Integration:** The existing `AuthBloc` event (`AuthEventSignIn`) and listener logic (`AuthError`, `AuthNeedsVerification`) will remain intact, ensuring business logic is preserved.

## Implementation Steps
1. **Theme Setup:** Ensure `AppColors` and `AppSpacing` align with the Ochre Sanctuary requirements.
2. **Widget Extraction:** Build the new `OchreTextField`, `OchreButton`, and background wrapper components.
3. **Screen Assembly:** Rebuild `LoginScreen` combining the new components and integrating the existing `_emailController`, `_passwordController`, and `AuthBloc` triggers.
4. **Cleanup:** Remove old Auth UI widgets that are no longer needed to satisfy the "no dead code" requirement.

## Verification & Testing
- **Visual Check:** Verify the layout exactly matches the HTML/Image reference, especially in RTL mode.
- **Performance Profiling:** Run in `--profile` mode and check the DevTools timeline to confirm no raster jank occurs from the background decorations.
- **Functional Test:** Ensure form validation, login submission, and error snackbars continue to work seamlessly.