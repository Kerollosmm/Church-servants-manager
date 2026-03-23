# Phase 3 — Dashboards

## Goal
Refactor the Admin Dashboard and Servant Dashboard screens to match the Stitch designs,
using Phase 1 shared components (AppHeader, AppStatCard, AppSectionCard, AppScreenShell).

---

## Stitch References
| Screen | Stitch ID | Screenshot |
|---|---|---|
| Admin Dashboard (Matched Header) | `8b55a3308238485ead6902d032d0c7d2` | [View](https://lh3.googleusercontent.com/aida/ADBb0ugd7trEoiHM_A7kVzJzxZ9UOfL_HUqIPSsHb9XWms3geDpA0h2VacWQR-L0sQPW5e4nd11EQ61EAqiMuHoQaDXFxYN958PkmPtJSb_qvk9hbuNtfk4kdv2leGXUDVWBr5sxSYAPwcWMWXg0kAc7tXAaK77AQslZkISr126BY_T2FiijnEBx_afh2scGCZCWJmYIIgDtSslViUcedseFzi0OaZHKKrahNkKcXyC5WBtibSnvL1SahBZJkTyT) |
| Servant Dashboard with Logo | `d50e3bba02924f9d99309b1d20598e9a` | [View](https://lh3.googleusercontent.com/aida/ADBb0uisRfCWPQt8BE-pbAVRpbXmm_oxnEBYFRvk0B2x9CsYg5zgJk_MVZx3pZBWlZYxuHl8x8Nb8sT31WIy2HPmXYgv-o7EClpzs_qFo-wtSe_-tjbdzqFjU3iUJFBkdJ3VBPZIg4kL0-XRRjyiofEqHI-yQ722chO3JONr2cLPZu32Defgpir5wNJoOS20TwsJ2TeELXvjdD1IdWuiNkdloWej-veoROM3zlziup3Ol3YMOZYHcXSXlo21CTQ) |

---

## Screen Designs

### Admin Dashboard
Layout (top to bottom):
1. **`AppHeader`** — logo + "لوحة التحكم" (Admin Panel) title, ochre accent bottom edge
2. **Welcome strip** — "مرحباً، {admin_name}" using `primaryContainer` tint bg
3. **Stats row** — 3 `AppStatCard` widgets: Total Students, Total Servants, Sessions This Month
4. **Recent Activity section** — `AppSectionCard` with header "آخر الجلسات" showing list of last 3 sessions
5. **Quick Actions section** — 2×2 grid of navigation cards (Students, Servants, Attendance, Settings)
6. **Bottom navigation bar** or FAB (from routing — not modified here)

### Servant Dashboard  
Layout (top to bottom):
1. **`AppHeader`** — logo + servant name + "خادم" subtitle
2. **My Students count card** — `AppStatCard` showing assigned students and this week's attendance %
3. **Upcoming sessions** — `AppSectionCard` "الجلسات القادمة" with next 2 sessions
4. **My students mini-list** — `AppSectionCard` "طلابي" with first 5 students using `AppPersonListTile`
5. **CTA** — `AppPrimaryButton` "تسجيل حضور" (Take Attendance) — navigates to attendance session

---

## Implementation Plan

### 3.1 Admin Dashboard
**File:** `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` (or equivalent)

Decompose into private widgets:
```dart
class AdminDashboardScreen extends StatelessWidget {
  // BlocBuilder on AdminBloc or multiple blocs
  Widget build(context) => AppScreenShell(
    appBar: AppHeader(title: 'لوحة التحكم', showLogo: true),
    body: ...,
  );
}

class _WelcomeStrip extends StatelessWidget {...}
class _StatsRow extends StatelessWidget {...}        // Row of 3 AppStatCards
class _RecentSessions extends StatelessWidget {...}  // AppSectionCard + list
class _QuickActions extends StatelessWidget {...}    // 2x2 action grid
```

Quick action cards: use `InkWell` + `AppSectionCard` with icon + label.

### 3.2 Servant Dashboard
**File:** `lib/features/servant/presentation/screens/servant_dashboard_screen.dart`

```dart
class ServantDashboardScreen extends StatelessWidget {
  Widget build(context) => AppScreenShell(
    appBar: AppHeader(title: servantName, subtitle: 'خادم', showLogo: true),
    body: ...,
  );
}

class _MyStudentsSummary extends StatelessWidget {...}
class _UpcomingSessions extends StatelessWidget {...}
class _MyStudentsMiniList extends StatelessWidget {...}
class _AttendanceCTA extends StatelessWidget {...}
```

### 3.3 Responsive Scroll
- All dashboard body: wrapped in `CustomScrollView` with `SliverList` so content scrolls naturally on small phones
- Stats row: `Row` with 3 `Expanded` children each containing `AppStatCard`

---

## Affected Files
| Action | File |
|---|---|
| MODIFY | `lib/features/admin/presentation/screens/admin_dashboard_screen.dart` (or find equivalent) |
| MODIFY | `lib/features/servant/presentation/screens/servant_dashboard_screen.dart` |
| EXPLORE FIRST | `lib/features/admin/` — check if admin screen exists |
| EXPLORE FIRST | `lib/features/team/` — admin may live here |
