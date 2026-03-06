# SCSS Standards & CSS Architecture

Apply when working with CSS, SCSS, or styling in this project.

## Architecture Overview

**Main entry points (webpack-compiled):**
| File | Output | Purpose |
|------|--------|---------|
| `assets/css/nok-components.scss` | `nok-components.css` | Frontend styles |
| `assets/css/nok-backend-css.scss` | `nok-backend-css.css` | Admin/editor |
| `assets/css/color_tests-v2.scss` | `color_tests-v2.css` | Color system |

**Directory structure:**
```
assets/css/
├── components/          # Production BEM components (_nok-*.scss)
├── tools/               # Mixins, RFS, utilities
├── libs/                # Third-party (baseline grid)
├── _nok-variables.scss  # Design tokens, breakpoints
├── _nok-colors-v2.scss  # OKLCH color system
├── _nok-helpers.scss    # Utility classes (loaded last)
└── _nok-reboot.scss     # CSS reset
```

## Build Commands

```bash
# Main build (webpack)
npm run build

# Compile individual post-part CSS (sass CLI)
npx sass template-parts/post-parts/{name}.scss template-parts/post-parts/{name}.css

# Minified version
npx sass template-parts/post-parts/{name}.scss template-parts/post-parts/{name}.min.css --style=compressed
```

## Post-Parts CSS (Lazy-loaded)

Post-parts with custom styles have co-located SCSS files that compile separately:
- `template-parts/post-parts/nok-bmi-calculator.scss` → `.css`
- These are **not** in webpack — compile manually with `npx sass`
- `TemplateRenderer.php` loads CSS via `resolve_css_file()` method

## Module System

Use `@use` with namespacing (not deprecated `@import`):
```scss
@use "shared" as components-base;
@use "../tools/nok-mixins" as mixins;

// Access via namespace
@include components-base.transition-properties { ... }
@include mixins.media-breakpoint-down(md) { ... }
```

**Exception:** `_nok-helpers.scss` uses `@import` in `nok-components.scss` to ensure it cascades last for utility overrides.

## Performance Patterns

### Expensive Properties to Avoid Animating
- `backdrop-filter` — GPU recomposite every frame
- `box-shadow` — triggers repaint

### Preferred Pattern: Opacity on Pseudo-element
```scss
// BAD: Animating backdrop-filter
transition: backdrop-filter 300ms ease;

// GOOD: Static filter, animate opacity
&::before {
  content: '';
  position: absolute;
  inset: 0;
  backdrop-filter: blur(5px);
  opacity: 0;
  transition: opacity 300ms ease;
}
&.active::before {
  opacity: 1;
}
```

## Color System

Uses OKLCH color space via `_nok-colors-v2.scss`:
```scss
// Colors exposed as CSS custom properties
--nok-lightblue, --nok-darkblue, --nok-yellow, etc.

// With variants
--nok-lightblue--darker, --nok-lightblue--lighter

// Alpha control via CSS variable
--bg-alpha-value: 0.5;
```

## Common Mixins

From `tools/_nok-mixins.scss`:
```scss
@include mixins.media-breakpoint-down(md) { }
@include mixins.media-breakpoint-up(lg) { }
@include mixins.nok-border-radius('large', 'bottom');
@include mixins.transition-properties { }
@include mixins.nok-text-font;
@include mixins.nok-heading-font;
```

## Breakpoints

```scss
$grid-breakpoints: (
  xs: 0,
  sm: 576px,
  md: 768px,
  lg: 992px,
  xl: 1200px,
  xxl: 1400px,
  xxxl: 1600px
);
```