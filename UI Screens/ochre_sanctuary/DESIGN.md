# Ochre Sanctuary Design System

### 1. Overview & Creative North Star
**Creative North Star: "The Modern Sanctuary"**
Ochre Sanctuary is a design system that marries the warmth of traditional heritage with the precision of contemporary digital interfaces. It rejects the coldness of standard SaaS "blue" in favor of a grounded, earthy palette centered around `#a58255`. The system is built to feel institutional yet welcoming, utilizing intentional whitespace and soft-depth layering to create a focused, meditative user experience.

### 2. Colors
The palette is rooted in organic tones—ochre, sand, and stone.

- **Primary Role:** The core identity is a rich Ochre (`#a58255`), used for critical actions and brand presence.
- **The "No-Line" Rule:** Visual separation must prioritize tonal shifts over borders. Use `surface_container_low` (`#f7f7f6`) against a white `surface` to define regions. 1px borders are restricted to input states and must use `primary/10` or `primary/20` opacity to maintain softness.
- **Surface Hierarchy:** 
  - **Base:** `surface` (#ffffff) for primary cards.
  - **Background:** `background` (#f7f7f6) for the main canvas.
  - **Accent:** `surface_container` is used for headers and secondary groupings to create a "recessed" look.
- **Signature Textures:** Utilize linear gradients (e.g., `from-primary via-primary/60 to-primary/20`) as directional accents or bottom-edge "anchors" for containers to add a sense of weight and premium finish.

### 3. Typography
Ochre Sanctuary uses a bilingual typographic rhythm that balances the geometric clarity of **Work Sans** with the elegant, traditional calligraphic roots of **Noto Sans Arabic**.

- **Typography Scale:**
  - **Display / Headline 1:** 1.5rem (24px). Bold and grounded. Used for page titles.
  - **Body / Content:** 0.875rem (14px). Optimized for legibility in dense administrative forms.
  - **Labels / Small:** 0.75rem (12px). Used for metadata and helper text.
  - **Icons:** Standardized at 20px (Material Symbols Outlined) to align with the cap-height of body text.

The hierarchy is driven by weight rather than massive size jumps, maintaining a sophisticated "editorial" feel even in functional layouts.

### 4. Elevation & Depth
Depth is communicated through light and atmosphere rather than harsh shadows.

- **The Layering Principle:** Use a "card-on-canvas" approach. The background is `#f7f7f6`, and the active surface is `#ffffff`.
- **Ambient Shadows:** 
  - **Level 1 (Cards):** `shadow-xl` — A broad, diffused shadow that makes the component feel integrated into the page atmosphere.
  - **Level 2 (Buttons):** `shadow-lg` with a color-tinted cast (`shadow-primary/30`). This gives interactive elements a "glow" rather than a drop-shadow.
- **Atmospheric Blurs:** For the "Sanctuary" feel, use large-scale decorative background blobs with `blur-[100px]` and low opacity (20%) to soften the corners of the viewport.

### 5. Components
- **Buttons:** High-contrast primary buttons use a solid `#a58255` background with white text and a `shadow-lg` tint. They should feature a `scale-[0.98]` active state for tactile feedback.
- **Input Fields:** Use a subtle background fill (`surface_container_low`) with a 1px border of `primary/20`. Icons should be placed on the leading edge (right-aligned for RTL) in the primary brand color to guide the eye.
- **Cards:** Rounded-xl (0.75rem) corners. Borders should be minimal (border-primary/10) to avoid visual clutter.
- **Checkboxes:** Small (w-4, h-4) with a custom `text-primary` fill to maintain brand alignment even in native browser components.

### 6. Do's and Don'ts
**Do:**
- Use RTL-first layouts where applicable, ensuring icons like 'login' or 'arrow' are correctly mirrored.
- Maintain a generous `p-8` (32px) padding in main content areas to support the "Sanctuary" aesthetic.
- Use `primary/5` or `primary/10` background tints for header sections to create a "nested" feel.

**Don't:**
- Use pure black (#000000). Use `slate-900` or `zinc-900` for dark text and backgrounds to maintain tonal warmth.
- Use sharp corners. The minimum radius should be `rounded-lg` (0.5rem) to ensure a friendly, approachable interface.
- Over-rely on borders. If a layout feels cluttered, remove borders and use `surface_container` backgrounds instead.