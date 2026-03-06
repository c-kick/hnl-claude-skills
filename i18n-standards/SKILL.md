---
name: i18n-standards
description: Standards for internationalization and string handling. Apply when touching files with user-facing strings, resolving mixed Dutch/English text, or preparing strings for translation.
allowed-tools: Read, Grep, Glob, Edit
---

# Internationalization (i18n) Standards

Apply these standards when working with user-facing strings in this project.

## Background

This codebase has mixed Dutch and English strings due to incremental development.
This is a low-priority cleanup task - apply these standards gradually when you touch
files that contain user-facing strings.

## Quick Reference

### User-Facing Strings

All user-facing strings should use WordPress translation functions:

```php
// Simple string
echo __('Save Changes', THEME_TEXT_DOMAIN);

// Echoing directly
_e('Submit Form', THEME_TEXT_DOMAIN);

// With placeholders
printf(
    __('Showing %d of %d results', THEME_TEXT_DOMAIN),
    $current,
    $total
);

// Pluralization
printf(
    _n('%d item', '%d items', $count, THEME_TEXT_DOMAIN),
    $count
);
```

### Language Conventions

| Context | Language | Example |
|---------|----------|---------|
| Code comments | English | `// Check if user is logged in` |
| Variable/function names | English | `$patient_name`, `get_opening_hours()` |
| Log messages | English | `error_log('Failed to load template');` |
| User-facing text | Dutch (translatable) | `__('Instellingen', THEME_TEXT_DOMAIN)` |
| Admin labels | Dutch (translatable) | `'label' => __('Telefoonnummer', THEME_TEXT_DOMAIN)` |

### JavaScript Strings

Use `@wordpress/i18n` for Gutenberg/block editor strings:

```javascript
import { __, _n, sprintf } from '@wordpress/i18n';

// Simple string
const label = __('Edit', 'nok-2025-v1');

// With placeholders
const message = sprintf(
    __('Showing %d results', 'nok-2025-v1'),
    count
);
```

## When Refactoring

When you encounter mixed-language strings in a file you're editing:

1. **Identify** user-facing strings (displayed to users in browser)
2. **Wrap** them with `__()` or `_e()`
3. **Keep** code comments and internal messages in English
4. **Don't** translate:
   - Log messages
   - Debug output
   - Internal error messages not shown to users
   - API responses (unless they're user-facing error messages)

## Constants

The theme text domain is defined as:

```php
define('THEME_TEXT_DOMAIN', 'nok-2025-v1');
```

Always use `THEME_TEXT_DOMAIN` constant, never hardcode the text domain string.

## Generating POT Files

After making i18n changes, regenerate the POT file:

```bash
# Using WP-CLI (if available)
wp i18n make-pot . languages/nok-2025-v1.pot --domain=nok-2025-v1

# Or using @wordpress/i18n npm package
npx @wordpress/i18n make-pot . languages/nok-2025-v1.pot
```

## Checklist

When touching files with strings:
- [ ] User-facing PHP strings wrapped with `__()` or `_e()`
- [ ] User-facing JS strings use `@wordpress/i18n`
- [ ] Text domain is `THEME_TEXT_DOMAIN` (PHP) or `'nok-2025-v1'` (JS)
- [ ] Code comments remain in English
- [ ] No hardcoded Dutch strings without translation wrapper
- [ ] Placeholders use `printf()`/`sprintf()` not concatenation

## Priority

This is a **low-priority** gradual cleanup task. Don't create separate commits
just for i18n changes - include them when you're already modifying a file for
other reasons.