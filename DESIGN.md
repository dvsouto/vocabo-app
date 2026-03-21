# Design System Specification: The Linguistic Atelier



## 1. Overview & Creative North Star

**Creative North Star: "The Digital Polymath"**

The objective of this design system is to move beyond the utilitarian "flashcard app" aesthetic and into the realm of a sophisticated workspace. We are crafting a "Digital Polymath" experience—one that feels like a premium macOS utility: quiet, authoritative, and frictionless.



We break the "template" look by rejecting rigid, boxed-in layouts. Instead, we embrace **Intentional Asymmetry** and **Optical Weight**. This system relies on expansive breathing room (white space) and high-contrast typography scales to guide the eye, creating a sense of editorial prestige rather than a standard software interface.



---



## 2. Colors & Surface Philosophy

Our palette is rooted in professional "Atelier Blues" and "Cognitive Grays," designed to reduce visual fatigue during deep study sessions.



### The Surface Hierarchy

We do not use lines to separate ideas; we use **Tonal Nesting**.

- **Base Layer:** `surface` (#faf9fe) — The canvas.

- **Secondary Workspaces:** `surface-container-low` (#f4f3f8) — For grouping related vocabulary sets.

- **Interactive Elevated Elements:** `surface-container-lowest` (#ffffff) — For cards that need to "pop" against the workspace.



### The "No-Line" Rule

**Explicit Instruction:** 1px solid borders are strictly prohibited for sectioning content. Boundaries must be defined solely through background color shifts. For example, a vocabulary list item sits on `surface-container` against a `surface` background. No strokes. No dividers.



### The "Glass & Gradient" Rule

For the Tray Icon interface and floating menus, use **Glassmorphism**:

- **Fill:** `surface` at 70% opacity.

- **Effect:** 20px - 40px Backdrop Blur.

- **Accent:** Use a subtle linear gradient from `primary` (#0058bc) to `primary-container` (#0070eb) for main "Add" actions to give them a "jewel" like depth that flat colors lack.



---



## 3. Typography

We utilize a single-font-family strategy (Inter) to mimic the macOS SF Pro aesthetic, relying on extreme scale and weight shifts to create hierarchy.



- **Display (The Statement):** `display-md` (2.75rem, Bold). Use for "New Word" entries. It should feel monumental.

- **Headlines (The Anchor):** `headline-sm` (1.5rem, Semi-Bold). Use for category headers.

- **Body (The Workhorse):** `body-md` (0.875rem, Regular). Optimized for definitions and examples.

- **Labels (The Metadata):** `label-sm` (0.6875rem, Medium, All Caps, Letter Spacing +5%). Use for part-of-speech tags (e.g., NOUN, VERB).



**Editorial Note:** Always maintain a minimum 1.5x line-height for body text to ensure the "Sophisticated" brand personality is preserved through legibility.



---



## 4. Elevation & Depth

Depth in this system is a gradient of focus, not a drop shadow from 2005.



- **The Layering Principle:** Stack `surface-container-lowest` cards on `surface-container-low` backgrounds to create a soft, natural lift.

- **Ambient Shadows:** For floating elements (Modals/Popovers), use a "Whisper Shadow":

- **Color:** `on-surface` (#1a1b1f) at 4% opacity.

- **Blur:** 32px.

- **Spread:** 0px.

- **Y-Offset:** 8px.

- **The "Ghost Border" Fallback:** If a boundary is legally required for accessibility, use `outline-variant` (#c1c6d7) at **15% opacity**. It should be felt, not seen.



---



## 5. Components



### Buttons (The Interaction Points)

- **Primary ("Add"):** `primary` (#0058bc) background with `on-primary` (#ffffff) text. Roundedness: `md` (0.75rem). Use a 2px inner-glow (lighter blue) on the top edge to simulate a physical macOS button.

- **Secondary ("Listen"):** `secondary-container` (#6664e4) background with `on-secondary-container` (#fffbff) text.

- **Tertiary:** Transparent background with `primary` text. No border.



### Input Fields (The Focus State)

- **State - Idle:** `surface-container-highest` background, no border.

- **State - Focus:** `surface-container-lowest` background. Add a 2px "Focus Ring" using `primary` at 30% opacity.

- **Corner Radius:** `DEFAULT` (0.5rem).



### Vocabulary Cards & Lists

- **Rule:** Forbid divider lines.

- **Separation:** Use `spacing-4` (1rem) of vertical white space or a subtle shift to `surface-container-low`.

- **Anatomy:** High-contrast `title-lg` for the word, `body-sm` for the translation, and a `tertiary-fixed` (#72fe88) chip for "Mastered" status.



### The Tray Interface (Unique Component)

A compact, floating glass window (`surface` @ 80% opacity + blur) used for quick-entry. Use `rounded-xl` (1.5rem) to differentiate it from the main application window.



---



## 6. Do’s and Don’ts



### Do:

- **Do** use `spacing-8` (2rem) and `spacing-10` (2.5rem) generously. If it feels like "too much" space, it’s probably just right.

- **Do** use `tertiary` (#006b27) for "Correct/Success" states to maintain the professional, non-alarming tone.

- **Do** ensure all interactive elements have a minimum target of 44x44px, even if the visual asset is smaller.



### Don’t:

- **Don’t** use pure black (#000000) for text. Use `on-surface` (#1a1b1f) for a softer, more premium contrast.

- **Don’t** use "Default" shadows. If the shadow is dark enough to be easily seen, it is too heavy.

- **Don’t** use more than two levels of nesting. If you need a card inside a card inside a section, reconsider the layout density.
