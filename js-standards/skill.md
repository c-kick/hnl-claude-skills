# JavaScript Standards and Patterns

Apply when writing or modifying JavaScript in `assets/js/`. Covers DOMule library usage, module patterns, and event handling.

## DOMule Library

External library at `assets/js/domule/`. Repository: https://github.com/c-kick/DOMule

### Core Modules

| Module | Purpose |
|--------|---------|
| `core.events.mjs` | Event system with `docReady`, `docLoaded`, `addListener` |
| `core.loader.mjs` | Dynamic module loading via `data-requires` |
| `core.log.mjs` | Logging with `logger.info()`, `logger.error()`, `DEBUG` flag |

### Utilities

| Utility | Purpose |
|---------|---------|
| `util.ensure-visibility.mjs` | `ViewportScroller` - scroll elements into view with header detection |
| `util.observe.mjs` | `isVisible`, `isUnobstructed`, `getBlockerHeight` |
| `util.debounce.mjs` | Debounce/throttle utilities |

### Click Handlers (`modules/hnl.clickhandlers.mjs`)

```js
import {singleClick, doubleClick} from './domule/modules/hnl.clickhandlers.mjs';

// Bind to elements - uses PointerEvent for unified mouse/touch/pen handling
singleClick(document.querySelectorAll('.my-button'), (e, element) => {
    // e.target is the clicked element
    // element is the bound element (from currentTarget)
});
```

## Event Handling: Delegation vs Direct Binding

### Direct Binding (`singleClick`)

```js
singleClick(document.querySelectorAll('a[href*="#"]'), handler);
```

**Pros:** Clean syntax, unified pointer handling (mouse/touch/pen)
**Cons:** Only binds to elements present at DOM ready. Dynamically added elements won't be handled.

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
| Static elements (nav, footer links) | `singleClick` - cleaner |
| Dynamic content (AJAX-loaded, SPA) | Event delegation |
| Global handlers (anchor scrolling) | Event delegation |
| Component-scoped clicks | `singleClick` |

## ViewportScroller Pattern

For scroll-to-anchor functionality, cache ViewportScroller instances in a WeakMap to ensure consistent positioning and prevent rounding drift on repeated scrolls.

```js
import {ViewportScroller} from './domule/util.ensure-visibility.mjs';

// WeakMap allows garbage collection when elements are removed
const scrollerMap = new WeakMap();

const scrollToElement = (el) => {
    if (!el) return;

    let scroller = scrollerMap.get(el);
    if (!scroller) {
        scroller = new ViewportScroller(el, {
            behavior: 'smooth',
            extraOffset: 20  // breathing room below header
        });
        scrollerMap.set(el, scroller);
    }
    scroller.ensureVisible();
};
```

**Why WeakMap?**
- Same scroller instance = consistent scroll position (no rounding drift)
- WeakMap keys are weakly held - if element is removed from DOM, it gets garbage collected along with its scroller

## Lazy Loading Modules

Use `data-requires` attribute for lazy-loaded modules:

```html
<div data-requires="./nok-datepicker.mjs">
    <!-- Content that needs datepicker -->
</div>
```

The `core.loader.mjs` uses IntersectionObserver to load modules when elements become visible.

### Module Structure

Modules should export an `init()` function that the loader calls:

```js
// nok-my-feature.mjs
export const NAME = 'my-feature';

export function init(elements) {
    // elements = NodeList of elements that required this module
    elements.forEach(el => {
        // Initialize feature on element
    });
}
```

## Event System

```js
import events from './domule/core.events.mjs';

// DOM ready (DOMContentLoaded)
events.docReady(() => {
    // DOM is parsed, safe to query elements
});

// DOM loaded (window load)
events.docLoaded(() => {
    // All resources loaded (images, etc.)
});

// Custom events with cleanup
events.addListener('scroll', (e) => {
    // Throttled scroll handler
});

events.addListener('breakPointChange', (e) => {
    // Responsive breakpoint changed
});
```

## Minification

Source files use `.mjs` extension. Minified versions are `.min.mjs`:

```
nok-feature.mjs      # Source (development)
nok-feature.min.mjs  # Minified (production)
```

The loader automatically selects minified versions in production.

## Debugging

```js
import {logger, DEBUG} from './domule/core.log.mjs';

logger.info(NAME, 'Starting up...');
logger.error(NAME, 'Something went wrong', error);

if (DEBUG) {
    logger.log(NAME, 'Debug-only message');
}
```

`DEBUG` is true when `?debug` is in the URL or in development mode.