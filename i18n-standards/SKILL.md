---
name: i18n-standards
description: Standards for internationalization and string handling. Apply when touching files with user-facing strings or preparing strings for translation.
allowed-tools: Read, Grep, Glob, Edit
---

# Internationalization (i18n) Standards

Apply these standards when working with user-facing strings in this project.

## Background

Projects often accumulate a mix of hardcoded and translatable strings over time.
This is a low-priority cleanup task — apply these standards gradually when you touch
files that contain user-facing strings.

## Quick Reference

### PHP: User-Facing Strings (WordPress)

All user-facing strings should use WordPress translation functions with the project's text domain constant:

```php
// Simple string
echo __('Save Changes', TEXT_DOMAIN);

// Echoing directly
_e('Submit Form', TEXT_DOMAIN);

// With placeholders
printf(
    __('Showing %d of %d results', TEXT_DOMAIN),
    $current,
    $total
);

// Pluralization
printf(
    _n('%d item', '%d items', $count, TEXT_DOMAIN),
    $count
);
```

### Language Conventions

| Context | Language | Example |
|---------|----------|---------|
| Code comments | English | `// Check if user is logged in` |
| Variable/function names | English | `$user_name`, `get_opening_hours()` |
| Log messages | English | `error_log('Failed to load template');` |
| User-facing text | Primary locale (translatable) | `__('Settings', TEXT_DOMAIN)` |
| Admin labels | Primary locale (translatable) | `'label' => __('Phone number', TEXT_DOMAIN)` |

### JavaScript Strings (WordPress)

Use `@wordpress/i18n` for Gutenberg/block editor strings:

```javascript
import { __, _n, sprintf } from '@wordpress/i18n';

// Simple string — use the text domain string (not the PHP constant)
const label = __('Edit', 'my-theme');

// With placeholders
const message = sprintf(
    __('Showing %d results', 'my-theme'),
    count
);
```

## When Refactoring

When you encounter hardcoded or mixed-language strings in a file you're editing:

1. **Identify** user-facing strings (displayed to users in browser)
2. **Wrap** them with `__()` or `_e()`
3. **Keep** code comments and internal messages in English
4. **Don't** translate:
   - Log messages
   - Debug output
   - Internal error messages not shown to users
   - API responses (unless they're user-facing error messages)

## Text Domain

The text domain should be defined as a constant in the project's configuration:

```php
define('TEXT_DOMAIN', 'my-theme');
```

Always use the text domain constant in PHP. In JavaScript, use the text domain string directly (JS doesn't have access to PHP constants).

## Generating POT Files

After making i18n changes, regenerate the POT file:

```bash
# Using WP-CLI (if available)
wp i18n make-pot . languages/<text-domain>.pot --domain=<text-domain>

# Or using @wordpress/i18n npm package
npx @wordpress/i18n make-pot . languages/<text-domain>.pot
```

## Checklist

When touching files with strings:
- [ ] User-facing PHP strings wrapped with `__()` or `_e()`
- [ ] User-facing JS strings use `@wordpress/i18n`
- [ ] Text domain constant used in PHP, text domain string in JS
- [ ] Code comments remain in English
- [ ] No hardcoded user-facing strings without translation wrapper
- [ ] Placeholders use `printf()`/`sprintf()` not concatenation

## Priority

This is a **low-priority** gradual cleanup task. Don't create separate commits
just for i18n changes — include them when you're already modifying a file for
other reasons.
