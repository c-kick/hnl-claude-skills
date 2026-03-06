# SCSS Standards & CSS Architecture

Apply when working with CSS, SCSS, or styling in this project.

## Architecture Overview

A well-structured SCSS project separates concerns into entry points, components, tools, and tokens. Adapt the structure below to match the project's naming conventions.

**Main entry points (compiled via bundler):**
| File | Output | Purpose |
|------|--------|---------|
| `assets/css/components.scss` | `components.css` | Frontend styles |
| `assets/css/backend.scss` | `backend.css` | Admin/editor styles |

**Recommended directory structure:**
```
assets/css/
├── components/          # BEM components (_*.scss)
├── tools/               # Mixins, utilities, RFS
├── libs/                # Third-party styles
├── _variables.scss      # Design tokens, breakpoints
├── _colors.scss         # Color system
├── _helpers.scss        # Utility classes (loaded last)
└── _reboot.scss         # CSS reset / normalization
```

## Build Commands

```bash
# Main build (via bundler)
npm run build

# Compile individual standalone SCSS files (sass CLI)
npx sass path/to/{name}.scss path/to/{name}.css

# Minified version
npx sass path/to/{name}.scss path/to/{name}.min.css --style=compressed
```

## Standalone Component CSS (Lazy-loaded)

Components with custom styles can have co-located SCSS files that compile separately from the main bundle:
- These are **not** in the bundler — compile manually with `npx sass`
- The template system should load these CSS files on demand when the component is rendered

## Module System

Use `@use` with namespacing (not deprecated `@import`):
```scss
@use "shared" as components-base;
@use "../tools/mixins" as mixins;

// Access via namespace
@include components-base.transition-properties { ... }
@include mixins.media-breakpoint-down(md) { ... }
```

**Exception:** Helper/utility files may use `@import` in the main entry point to ensure they cascade last for utility overrides.

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

Use CSS custom properties for the color system. OKLCH is recommended for perceptual uniformity:
```scss
// Colors exposed as CSS custom properties
--color-primary, --color-secondary, --color-accent, etc.

// With variants
--color-primary--darker, --color-primary--lighter

// Alpha control via CSS variable
--bg-alpha-value: 0.5;
```

## Common Mixins

Provide project mixins for responsive breakpoints, typography, and component patterns:
```scss
@include mixins.media-breakpoint-down(md) { }
@include mixins.media-breakpoint-up(lg) { }
@include mixins.border-radius('large', 'bottom');
@include mixins.transition-properties { }
@include mixins.text-font;
@include mixins.heading-font;
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
