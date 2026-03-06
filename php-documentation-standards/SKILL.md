---
name: php-documentation-standards
description: Enforces PHP documentation standards for PHPStorm IDE support. Apply when writing or reviewing PHP classes, methods, docblocks, type hints, or magic property annotations.
allowed-tools: Read, Grep, Glob
---

# PHP Documentation Standards

Apply these standards when writing or reviewing PHP code in this project.

## Quick Reference

### Class Documentation
```php
/**
 * ClassName - Brief one-line description (< 80 chars)
 *
 * - What the class does
 * - Key responsibilities
 *
 * @example Real usage pattern
 * $instance = new ClassName($param);
 * $result = $instance->method();
 *
 * @property-read Type $property For magic properties
 * @package YourNamespace
 */
```

### Method Documentation
```php
/**
 * Brief description of what method does
 *
 * @param Type $param Description
 * @param Type|null $optional Optional parameter
 * @return Type Description of return value
 */
public function methodName(Type $param, ?Type $optional = null): Type {
```

### Type Hints
Always use type hints:
- Parameters: `string $name`, `?int $id`
- Return types: `function(): array`, `function(): ?User`
- Union types: `string|int|null`

### Magic Properties
```php
/**
 * @property-read FieldValue $title
 * @property-read FieldValue $content
 */
```

## Type Safety Guidelines

### Strict Types
Add to new PHP files:
```php
<?php
declare(strict_types=1);
```

### Type Hints
Always use native PHP type hints:
```php
// Parameters
public function process(int $id, ?string $name = null): void

// Return types - be specific
public function getCount(): int
public function findUser(int $id): ?User

// Union types (PHP 8+)
public function setValue(string|int $value): void
```

### Type Coercion
Explicitly cast untrusted input:
```php
// User input from $_GET, $_POST, REST params
$id = (int) $request->get_param('id');
$limit = absint($params['limit'] ?? 10);

// Array access with defaults
$value = (string) ($data['key'] ?? '');
```

### PHPDoc for Complex Types
When native types aren't enough:
```php
/**
 * @param array<string, mixed> $options
 * @param callable(int): bool $filter
 * @return array<int, User>
 */
```

### Static Analysis
Consider adding PHPStan at level 5+ for automated type checking:
```bash
composer require --dev phpstan/phpstan
./vendor/bin/phpstan analyse inc/ --level=5
```

## Checklist

Before committing:
- [ ] Class has docblock with description and @package
- [ ] Public methods have @param and @return
- [ ] Type hints on all parameters and return values
- [ ] Magic properties documented with @property-read
- [ ] At least one @example showing real usage
- [ ] Complex logic has inline comments explaining "why"
- [ ] User input is explicitly cast to expected types
- [ ] New files have `declare(strict_types=1)` where appropriate

## Complete Standards

For detailed standards with full examples, see:
@../../docs/php_documentation_standards.md
