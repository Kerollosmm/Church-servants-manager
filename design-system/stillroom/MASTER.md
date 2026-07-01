# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Stillroom
**Generated:** 2026-06-25 00:05:00
**Category:** Beauty/Spa/Wellness Service

---

## Global Rules

### Color Palette

| Role | Hex | CSS Variable |
|------|-----|--------------|
| Background (Oat Linen) | `#F6F4F0` | `--color-bg-linen` |
| Surface (Chalk Cream) | `#FAF9F6` | `--color-surface-cream` |
| Primary Text (Charcoal) | `#2D2926` | `--color-text-charcoal` |
| Muted Text (Stone) | `#6D6763` | `--color-text-stone` |
| Accent 1 (Terracotta) | `#C07A65` | `--color-accent-terracotta` |
| Accent 2 (Sage) | `#94A496` | `--color-accent-sage` |
| Accent 3 (Ocean Blue) | `#6B7F8A` | `--color-accent-ocean` |

**Color Notes:** Warm layered neutral tones with landscape-inspired accent pops (Terracotta, Sage, Ocean). Avoid harsh contrasts and electric colors.

### Typography

- **Heading Font:** Lora (Serif)
- **Body Font:** Raleway (Sans-Serif)
- **Mood:** calm, wellness, restorative, slow living, minimalist, Nordic cabin
- **Google Fonts:** [Lora + Raleway](https://fonts.google.com/share?selection.family=Lora:wght@400;500;600;700|Raleway:wght@300;400;500;600;700)

**CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400;0,500;0,600;0,700;1,400&family=Raleway:wght@300;400;500;600;700&display=swap');
```

### Spacing Variables

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(45, 41, 38, 0.02)` | Very subtle lift |
| `--shadow-md` | `0 8px 24px rgba(45, 41, 38, 0.04)` | Cards, buttons |
| `--shadow-lg` | `0 16px 40px rgba(45, 41, 38, 0.06)` | Elegant dropdowns or hero overlays |

---

## Component Specs

### Buttons

```css
/* Primary Button (Terracotta or Sage accent) */
.btn-primary {
  background: var(--color-accent-terracotta);
  color: var(--color-surface-cream);
  padding: 14px 28px;
  border-radius: 4px;
  font-family: 'Raleway', sans-serif;
  font-weight: 500;
  letter-spacing: 0.05em;
  transition: all 300ms cubic-bezier(0.25, 1, 0.5, 1);
  border: none;
  cursor: pointer;
}

.btn-primary:hover {
  background: #b26853;
  transform: translateY(-1px);
}

/* Secondary Button (Outline Style) */
.btn-secondary {
  background: transparent;
  color: var(--color-text-charcoal);
  border: 1px solid var(--color-text-stone);
  padding: 14px 28px;
  border-radius: 4px;
  font-family: 'Raleway', sans-serif;
  font-weight: 500;
  letter-spacing: 0.05em;
  transition: all 300ms cubic-bezier(0.25, 1, 0.5, 1);
  cursor: pointer;
}

.btn-secondary:hover {
  border-color: var(--color-text-charcoal);
  background: rgba(45, 41, 38, 0.02);
}
```

### Cards

```css
.card {
  background: var(--color-surface-cream);
  border: 1px solid rgba(45, 41, 38, 0.05);
  border-radius: 4px;
  padding: 32px;
  box-shadow: var(--shadow-md);
  transition: all 300ms cubic-bezier(0.25, 1, 0.5, 1);
  cursor: pointer;
}

.card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}
```

### Inputs

```css
.input {
  padding: 14px 18px;
  border: 1px solid rgba(45, 41, 38, 0.15);
  background: var(--color-surface-cream);
  color: var(--color-text-charcoal);
  border-radius: 4px;
  font-family: 'Raleway', sans-serif;
  font-size: 16px;
  transition: all 300ms cubic-bezier(0.25, 1, 0.5, 1);
}

.input:focus {
  border-color: var(--color-accent-sage);
  outline: none;
  box-shadow: 0 0 0 3px rgba(148, 164, 150, 0.15);
}
```

### Modals

```css
.modal-overlay {
  background: rgba(45, 41, 38, 0.3);
  backdrop-filter: blur(8px);
  transition: opacity 300ms ease;
}

.modal {
  background: var(--color-surface-cream);
  border-radius: 4px;
  padding: 40px;
  box-shadow: var(--shadow-lg);
  max-width: 500px;
  width: 90%;
}
```

---

## Style Guidelines

**Style:** Soft UI Evolution

**Keywords:** Evolved soft UI, better contrast, modern aesthetics, subtle depth, accessibility-focused, improved shadows, hybrid

**Best For:** Modern enterprise apps, SaaS platforms, health/wellness, modern business tools, professional, hybrid

**Key Effects:** Improved shadows (softer than flat, clearer than neumorphism), modern (200-300ms), focus visible, WCAG AA/AAA

### Page Pattern

**Pattern Name:** Hero-Centric + Social Proof

- **CTA Placement:** Above fold
- **Section Order:** Hero > Features > CTA

---

## Anti-Patterns (Do NOT Use)

- ❌ Bright neon colors
- ❌ Harsh animations
- ❌ Dark mode

### Additional Forbidden Patterns

- ❌ **Emojis as icons** — Use SVG icons (Heroicons, Lucide, Simple Icons)
- ❌ **Missing cursor:pointer** — All clickable elements must have cursor:pointer
- ❌ **Layout-shifting hovers** — Avoid scale transforms that shift layout
- ❌ **Low contrast text** — Maintain 4.5:1 minimum contrast ratio
- ❌ **Instant state changes** — Always use transitions (150-300ms)
- ❌ **Invisible focus states** — Focus states must be visible for a11y

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile
