---
name: High-Contrast Light Operational System
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#434655'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#545f73'
  on-secondary: '#ffffff'
  secondary-container: '#d5e0f8'
  on-secondary-container: '#586377'
  tertiary: '#46566c'
  on-tertiary: '#ffffff'
  tertiary-container: '#5e6e85'
  on-tertiary-container: '#e9f0ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  success: '#0d7a2e'
  on-success: '#ffffff'
  success-container: '#d7f5d7'
  on-success-container: '#002106'
  warning: '#8c5000'
  on-warning: '#ffffff'
  warning-container: '#ffe3b8'
  on-warning-container: '#2e1800'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#d3e4fe'
  tertiary-fixed-dim: '#b7c8e1'
  on-tertiary-fixed: '#0b1c30'
  on-tertiary-fixed-variant: '#38485d'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
  navy-text: '#1e293b'
  border: '#e2e8f0'
  divider: '#f1f5f9'
  slate-400: '#64748b'
  slate-300: '#cbd5e1'
typography:
  display:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
    textTransform: uppercase
  code:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
fonts:
  imports:
    - url: https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@600;700&display=swap
      desc: Headlines (Display, Headline LG, Headline MD)
    - url: https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap
      desc: Body text
    - url: https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap
      desc: Labels, code, technical text
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
  max-width: 100vw
breakpoints:
  mobile: 640px
  tablet: 768px
  desktop: 1024px
  wide: 1280px
components:
  button:
    padding: 8px 16px
    font: body-md (Inter, 14px, semibold 500)
    radius: DEFAULT (0.25rem / 4px)
    primary-bg: primary-container (#2563eb)
    primary-text: '#ffffff'
    secondary-border: navy-text (#1e293b)
    secondary-text: navy-text (#1e293b)
    ghost-text: navy-text (#1e293b)
  input:
    border: 1px solid border (#e2e8f0)
    background: '#ffffff'
    label-font: label-caps (JetBrains Mono, 12px, 600, uppercase)
    label-color: slate-400 (#64748b)
    focus-border: 2px solid primary-container (#2563eb)
    radius: DEFAULT (0.25rem / 4px)
  card:
    background: '#ffffff'
    border: 1px solid border (#e2e8f0)
    padding: 24px
    radius: lg (0.5rem / 8px)
    shadow: none
  chip:
    height: 24px
    padding: 0 8px
    font: label-caps (JetBrains Mono, 12px)
    gap: 4px
    dot-size: 8px
    radius: full (9999px)
  list:
    divider: 1px solid divider (#f1f5f9)
    hover-bg: '#f8fafc'
  modal:
    shadow: 0px 4px 12px rgba(30, 41, 59, 0.05)
    radius: lg (0.5rem / 8px)
---

## Brand & Style

This design system is engineered for high-stakes operational environments, such as infrastructure management, fintech dashboards, and enterprise-grade SaaS. It prioritizes **clarity, speed of recognition, and functional authority**.

The design style is **Corporate / Modern** with a lean toward **Minimalism**. It utilizes a "density-focused" aesthetic that ensures critical information is never lost. The visual mood is precise and reliable, using sharp typography and a structured grid to convey a sense of technical excellence.

## Colors

The palette is anchored by an ultra-clean background (`#f7f9fb`), which reduces eye strain while maintaining a crisp, modern feel.

- **Primary Container (`#2563eb`):** Electric blue used for primary calls-to-action, active states, and critical highlights.
- **Primary (`#004ac6`):** Darker blue variant for hover/pressed states and high-emphasis elements.
- **On-Surface (`#191c1e`):** Near-black for primary typography, providing high-contrast legibility.
- **Slate Scale (`#64748b` → `#cbd5e1`):** Secondary text and disabled states.
- **Success (`#0d7a2e`), Warning (`#8c5000`), Error (`#ba1a1a`):** Saturated semantic colors for status signals.

## Typography

Tri-font strategy to differentiate intent:

1. **Hanken Grotesk (Headlines):** Sharp contemporary grotesque for titles and displays.
2. **Inter (Body):** Exceptional UI legibility for dense data and long-form text.
3. **JetBrains Mono (Labels/Technical):** Monospaced font for metadata, labels, and system status.

## Layout & Spacing

**Fixed-Fluid Hybrid**: Desktop views capped at 1280px; internal containers use a fluid 12-column grid.

- 8px linear scale for spacing; 4px for tight component internals
- 24px gutters between data-heavy widgets
- Mobile: 16px margins, 4-column grid, xl spacing reduced 25%

## Elevation & Depth

Tonal layers and crisp outlines instead of heavy shadows:

- Background: `#f7f9fb`; Cards: `#ffffff` with 1px `#e2e8f0` border
- Active inputs: 2px primary border
- Modals only: subtle 12px blur shadow at 5% navy

## Shapes

Soft (`0.25rem` / 4px) — modern but professional.

- Buttons, inputs, chips: 4px radius
- Cards, modals: 8px radius
- Status pills: fully rounded

## Components

### Buttons
- **Primary:** `bg-[#2563eb] text-white font-medium`
- **Secondary:** `border border-[#1e293b] text-[#1e293b]`
- **Ghost:** `text-[#1e293b]` no bg/border until hover

### Input Fields
- **Default:** `bg-white border border-[#e2e8f0]`
- **Label:** JetBrains Mono, uppercase, `#64748b`
- **Focus:** 2px `#2563eb` border

### Cards
- `bg-white border border-[#e2e8f0]` padding 24px, radius 8px, no shadow

### Status Chips
- Uppercase JetBrains Mono label with 8px colored dot prefix
- Fully rounded pill shape

### Lists
- 1px `#f1f5f9` dividers
- `#f8fafc` hover background on interactive rows
