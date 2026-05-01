---
name: js-standards
description: JavaScript standards and patterns. Apply when writing or modifying JavaScript modules, event handling, lazy loading, scroll behavior, or browser-side utilities.
---

# JavaScript Standards and Patterns

Apply when writing or modifying JavaScript modules. Covers module patterns, event handling, lazy loading, and scroll utilities.

## Event Handling: Delegation vs Direct Binding

### Direct Binding

```js
document.querySelectorAll('.my-button').forEach(el => {
    el.addEventListener('pointerup', (e) => {
        // handle click/tap/pen
    });
});
```

**Pros:** Simple, scoped to known elements, unified pointer handling (mouse/touch/pen) via PointerEvent
**Cons:** Only binds to elements present at bind time. Dynamically added elements won't be handled.

### Event Delegation

```js
document.addEventListener('click', (e) => {
    const link = e.target.closest('a[href*="#"]');
    if (!link) return;
    // handle...
});
```

**Pros:** Handles dynamically added elements automatically
**Cons:** Runs on every click, must filter manually

### When to Use Which

| Scenario | Approach |
|----------|----------|
| Static elements (nav, footer links) | Direct binding - cleaner |
| Dynamic content (AJAX-loaded, SPA) | Event delegation |
| Global handlers (anchor scrolling) | Event delegation |
| Component-scoped clicks | Direct binding |

## Scroll-to-Element Pattern

For scroll-to-anchor functionality, cache scroll controller instances in a WeakMap to ensure consistent positioning and prevent rounding drift on repeated scrolls.

```js
// WeakMap allows garbage collection when elements are removed
const scrollerMap = new WeakMap();

const scrollToElement = (el) => {
    if (!el) return;

    let scroller = scrollerMap.get(el);
    if (!scroller) {
        scroller = { target: el, behavior: 'smooth', extraOffset: 20 };
        scrollerMap.set(el, scroller);
    }

    el.scrollIntoView({ behavior: scroller.behavior, block: 'start' });
};
```

**Why WeakMap?**
- Same scroller instance = consistent scroll position (no rounding drift)
- WeakMap keys are weakly held - if element is removed from DOM, it gets garbage collected along with its scroller

## Lazy Loading Modules

Use `data-requires` attributes (or similar) for lazy-loaded modules, combined with IntersectionObserver:

```html
<div data-requires="./datepicker.mjs">
    <!-- Content that needs datepicker -->
</div>
```

```js
// Observer triggers module load when element enters viewport
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const modulePath = entry.target.dataset.requires;
            import(modulePath).then(mod => mod.init([entry.target]));
            observer.unobserve(entry.target);
        }
    });
});

document.querySelectorAll('[data-requires]').forEach(el => observer.observe(el));
```

### Module Structure

Lazy-loaded modules should export an `init()` function:

```js
// my-feature.mjs
export const NAME = 'my-feature';

export function init(elements) {
    // elements = NodeList/array of elements that required this module
    elements.forEach(el => {
        // Initialize feature on element
    });
}
```

## Event System

When using a centralized event system, typical lifecycle hooks include:

```js
// DOM ready (DOMContentLoaded)
document.addEventListener('DOMContentLoaded', () => {
    // DOM is parsed, safe to query elements
});

// All resources loaded
window.addEventListener('load', () => {
    // All resources loaded (images, fonts, etc.)
});

// Custom events for app-level coordination
window.addEventListener('breakpointchange', (e) => {
    // Respond to viewport breakpoint changes
});
```

## Minification

Source files use `.mjs` extension. Minified versions are `.min.mjs`:

```
my-feature.mjs      # Source (development)
my-feature.min.mjs   # Minified (production)
```

The build system or loader should automatically select minified versions in production.

## Debugging

Use a structured logging approach:

```js
const DEBUG = new URLSearchParams(location.search).has('debug');

const logger = {
    info: (module, ...args) => console.info(`[${module}]`, ...args),
    error: (module, ...args) => console.error(`[${module}]`, ...args),
    debug: (module, ...args) => { if (DEBUG) console.log(`[${module}]`, ...args); },
};

logger.info(NAME, 'Starting up...');
logger.error(NAME, 'Something went wrong', error);
logger.debug(NAME, 'Debug-only message');
```

`DEBUG` is true when `?debug` is in the URL or in development mode.
