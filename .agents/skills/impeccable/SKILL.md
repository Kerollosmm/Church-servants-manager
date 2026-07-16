---
name: impeccable
description: "Use when user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve frontend interface. Covers websites, landing pages, dashboards, product UI, app shells, components, forms, settings, onboarding, and empty states. Handles UX review, visual hierarchy, information architecture, cognitive load, accessibility, performance, responsive behavior, theming, anti-patterns, typography, fonts, spacing, layout, alignment, color, motion, micro-interactions, UX copy, error states, edge cases, i18n, and reusable design systems or tokens. Also use for bland designs that need to become bolder or more delightful, loud designs that should become quieter, live browser iteration on UI elements, or ambitious visual effects that should feel technically extraordinary. Not for backend-only or non-UI tasks."
argument-hint: "[{{command_hint}}] [target]"
user-invocable: true
allowed-tools:
 - Bash(npx impeccable *)
license: Apache 2.0. Based on Anthropic's frontend-design skill. See NOTICE.md for attribution.
---

Designs and iterates production-grade frontend interfaces. Real working code, committed design choices, exceptional craft.

## Setup (non-optional)

Before any design work or file edits, pass these gates. Skipping them produces generic output that ignores project.

| Gate | Required check | If fail |
|---|---|---|
| Context | PRODUCT.md / DESIGN.md loader result is known from `node {{scripts_path}}/load-context.mjs`. | Run loader before continuing. |
| Product | PRODUCT.md exists and is not empty or placeholder (`[TODO]` markers, <200 chars). | Run `{{command_prefix}}impeccable teach`, refresh context, then resume. Never synthesize PRODUCT.md from user's original prompt alone. |
| Command | matching command reference is loaded when sub-command is used. | Load reference before continuing. |
| Craft | `{{command_prefix}}impeccable craft` has user-confirmed shape brief for this task. `teach` / PRODUCT.md never counts as shape. | Run `{{command_prefix}}impeccable shape` and wait for explicit brief confirmation. |
| Image | Required visual probes / mocks are generated or skipped with reason. | Resolve image-generation gate in `shape.md` or `craft.md` before code. |
| Mutation | All active gates above pass. | Do not edit project files yet. |

Codex-style agents must state this before editing files:

```text
IMPECCABLE_PREFLIGHT: context=pass product=pass command_reference=pass shape=pass|not_required image_gate=pass|skipped:<reason> mutation=open
```

For `{{command_prefix}}impeccable craft`, `shape=pass` is only valid after separate user response approving shape design brief, or when user provided already-confirmed brief in request. Do not mark `shape=pass` after writing PRODUCT.md, summarizing assumptions, or drafting unconfirmed brief yourself.

Other harnesses should follow same checklist when they can expose this state.

### 1. Context gathering

Two files, case-insensitive. loader looks at project root by default and falls back to `.agents/context/` and `docs/` if root is clean. Override with `IMPECCABLE_CONTEXT_DIR=path/to/dir` (absolute or relative to cwd).

- **PRODUCT.md**: required. Users, brand, tone, anti-references, strategic principles.
- **DESIGN.md**: optional, strongly recommended. Colors, typography, elevation, components.

Load both in one call:

```bash
node {{scripts_path}}/load-context.mjs
```

Consume full JSON output. Never pipe through `head`, `tail`, `grep`, or `jq`. output's `contextDir` field tells you where files were resolved from.

If output is already in this session's conversation history, don't re-run. Exceptions requiring fresh load: you ran `{{command_prefix}}impeccable teach` or `{{command_prefix}}impeccable document` (they rewrite files), or user manually edited one.

`{{command_prefix}}impeccable live` already warms context via `live.mjs`. If you've run `live.mjs`, don't also run `load-context.mjs` this session.

If PRODUCT.md is missing, empty, or placeholder (`[TODO]` markers, <200 chars): run `{{command_prefix}}impeccable teach`, then resume user's original task with fresh context. If original task was `{{command_prefix}}impeccable craft`, resume into `{{command_prefix}}impeccable shape` before any implementation work.

If DESIGN.md is missing: nudge once per session (*"Run `{{command_prefix}}impeccable document` for more on-brand output"*), then proceed.

### 2. Register

Every design task is **brand** (marketing, landing, campaign, long-form content, portfolio: design IS product) or **product** (app UI, admin, dashboard, tool: design SERVES product).

Identify before designing. Priority: (1) cue in task itself ("landing page" vs "dashboard"); (2) surface in focus ( page, file, or route being worked on); (3) `register` field in PRODUCT.md. First match wins.

If PRODUCT.md lacks `register` field (legacy), infer it once from its "Users" and "Product Purpose" sections, then cache inferred value for session. Suggest user run `{{command_prefix}}impeccable teach` to add field explicitly.

Load matching reference: [reference/brand.md](reference/brand.md) or [reference/product.md](reference/product.md). shared design laws below apply to both.

## Shared design laws

Apply to every design, both registers. Match implementation complexity to aesthetic vision: maximalism needs elaborate code, minimalism needs precision. Interpret creatively. Vary across projects; never converge on same choices. {{model}} is capable of extraordinary work. Don't hold back.

### Color

- Use OKLCH. Reduce chroma as lightness approaches 0 or 100; high chroma at extremes looks garish.
- Never use `#000` or `#fff`. Tint every neutral toward brand hue (chroma 0.005–0.01 is enough).
- Pick **color strategy** before picking colors. Four steps on commitment axis:
 - **Restrained**: tinted neutrals + one accent ≤10%. Product default; brand minimalism.
 - **Committed**: one saturated color carries 30–60% of surface. Brand default for identity-driven pages.
 - **Full palette**: 3–4 named roles, each used deliberately. Brand campaigns; product data viz.
 - **Drenched**: surface IS color. Brand heroes, campaign pages.
- "one accent ≤10%" rule is Restrained only. Committed / Full palette / Drenched exceed it on purpose. Don't collapse every design to Restrained by reflex.

### Theme

Dark vs. light is never default. Not dark "because tools look cool dark." Not light "to be safe."

Before choosing, write one sentence of physical scene: who uses this, where, under what ambient light, in what mood. If sentence doesn't force answer, it's not concrete enough. Add detail until it does.

"Observability dashboard" does not force answer. "SRE glancing at incident severity on 27-inch monitor at 2am in dim room" does. Run sentence, not category.

### Typography

- Cap body line length at 65–75ch.
- Hierarchy through scale + weight contrast (≥1.25 ratio between steps). Avoid flat scales.

### Layout

- Vary spacing for rhythm. Same padding everywhere is monotony.
- Cards are lazy answer. Use them only when they're truly best affordance. Nested cards are always wrong.
- Don't wrap everything in container. Most things don't need one.

### Motion

- Don't animate CSS layout properties.
- Ease out with exponential curves (ease-out-quart / quint / expo). No bounce, no elastic.

### Absolute bans

Match-and-refuse. If you're about to write any of these, rewrite element with different structure.

- **Side-stripe borders.** `border-left` or `border-right` greater than 1px as colored accent on cards, list items, callouts, or alerts. Never intentional. Rewrite with full borders, background tints, leading numbers/icons, or nothing.
- **Gradient text.** `background-clip: text` combined with gradient background. Decorative, never meaningful. Use single solid color. Emphasis via weight or size.
- **Glassmorphism as default.** Blurs and glass cards used decoratively. Rare and purposeful, or nothing.
- ** hero-metric template.** Big number, small label, supporting stats, gradient accent. SaaS cliché.
- **Identical card grids.** Same-sized cards with icon + heading + text, repeated endlessly.
- **Modal as first thought.** Modals are usually laziness. Exhaust inline / progressive alternatives first.

### Copy

- Every word earns its place. No restated headings, no intros that repeat title.
- **No em dashes.** Use commas, colons, semicolons, periods, or parentheses. Also not `--`.

### The AI slop test

If someone could look at this interface and say "AI made that" without doubt, it's failed. Cross-register failures are absolute bans above. Register-specific failures live in each reference.

**Category-reflex check.** Run at two altitudes; second one catches what first one misses.

- **First-order:** if someone could guess theme + palette from category alone ("observability → dark blue", "healthcare → white + teal", "finance → navy + gold", "crypto → neon on black"), it's first training-data reflex. Rework scene sentence and color strategy until answer isn't obvious from domain.
- **Second-order:** if someone could guess aesthetic family from category-plus-anti-references ("AI workflow tool that's not SaaS-cream → editorial-typographic", "fintech that's not navy-and-gold → terminal-native dark mode"), it's trap one tier deeper. first reflex was avoided; second wasn't. Rework until both answers are not obvious. brand register's [reflex-reject aesthetic lanes](reference/brand.md) list catches currently-saturated families.

## Commands

| Command | Category | Description | Reference |
|---|---|---|---|
| `craft [feature]` | Build | Shape, then build feature end-to-end | [reference/craft.md](reference/craft.md) |
| `shape [feature]` | Build | Plan UX/UI before writing code | [reference/shape.md](reference/shape.md) |
| `teach` | Build | Set up PRODUCT.md and DESIGN.md context | [reference/teach.md](reference/teach.md) |
| `document` | Build | Generate DESIGN.md from existing project code | [reference/document.md](reference/document.md) |
| `extract [target]` | Build | Pull reusable tokens and components into design system | [reference/extract.md](reference/extract.md) |
| `critique [target]` | Evaluate | UX design review with heuristic scoring | [reference/critique.md](reference/critique.md) |
| `audit [target]` | Evaluate | Technical quality checks (a11y, perf, responsive) | [reference/audit.md](reference/audit.md) |
| `polish [target]` | Refine | Final quality pass before shipping | [reference/polish.md](reference/polish.md) |
| `bolder [target]` | Refine | Amplify safe or bland designs | [reference/bolder.md](reference/bolder.md) |
| `quieter [target]` | Refine | Tone down aggressive or overstimulating designs | [reference/quieter.md](reference/quieter.md) |
| `distill [target]` | Refine | Strip to essence, remove complexity | [reference/distill.md](reference/distill.md) |
| `harden [target]` | Refine | Production-ready: errors, i18n, edge cases | [reference/harden.md](reference/harden.md) |
| `onboard [target]` | Refine | Design first-run flows, empty states, activation | [reference/onboard.md](reference/onboard.md) |
| `animate [target]` | Enhance | Add purposeful animations and motion | [reference/animate.md](reference/animate.md) |
| `colorize [target]` | Enhance | Add strategic color to monochromatic UIs | [reference/colorize.md](reference/colorize.md) |
| `typeset [target]` | Enhance | Improve typography hierarchy and fonts | [reference/typeset.md](reference/typeset.md) |
| `layout [target]` | Enhance | Fix spacing, rhythm, and visual hierarchy | [reference/layout.md](reference/layout.md) |
| `delight [target]` | Enhance | Add personality and memorable touches | [reference/delight.md](reference/delight.md) |
| `overdrive [target]` | Enhance | Push past conventional limits | [reference/overdrive.md](reference/overdrive.md) |
| `clarify [target]` | Fix | Improve UX copy, labels, and error messages | [reference/clarify.md](reference/clarify.md) |
| `adapt [target]` | Fix | Adapt for different devices and screen sizes | [reference/adapt.md](reference/adapt.md) |
| `optimize [target]` | Fix | Diagnose and fix UI performance | [reference/optimize.md](reference/optimize.md) |
| `live` | Iterate | Visual variant mode: pick elements in browser, generate alternatives | [reference/live.md](reference/live.md) |

Plus two management commands: `pin <command>` and `unpin <command>`, detailed below.

### Routing rules

1. **No argument**: render table above as user-facing command menu, grouped by category. Ask what they'd like to do.
2. **First word matches command**: load its reference file and follow its instructions. Everything after command name is target.
3. **First word doesn't match**: general design invocation. Apply setup steps, shared design laws, and loaded register reference, using full argument as context.

Setup (context gathering, register) is already loaded by then; sub-commands don't re-invoke `{{command_prefix}}impeccable`.

If first word is `craft`, setup still runs first, but [reference/craft.md](reference/craft.md) owns rest of flow. If setup invokes `teach` as blocker, finish teach, refresh context, then resume original command and target.

## Pin / Unpin

**Pin** creates standalone shortcut so `{{command_prefix}}<command>` invokes `{{command_prefix}}impeccable <command>` directly. **Unpin** removes it. script writes to every harness directory present in project.

```bash
node {{scripts_path}}/pin.mjs <pin|unpin> <command>
```

Valid `<command>` is any command from table above. Report script's result concisely. Confirm new shortcut on success, relay stderr verbatim on error.
