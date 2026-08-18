# Laravel Cursor Rules

These project rules are derived from the shared `/docs` source of truth and the technology-specific `/laravel/docs` documentation.

## Precedence
1. Explicit product/business requirements in `/docs`.
2. Technology-specific documentation in `/laravel/docs`.
3. Applicable `.mdc` rules in `/laravel/.cursor/rules`.
4. User instructions for the current task, provided they do not violate safety or the documented product constraints.

## Rule behavior
- `alwaysApply: true` is used only for the project context rule.
- Other rules use targeted globs or agent-requested descriptions to reduce unnecessary context.
- Read the relevant documentation before implementation.
- Do not invent pending business decisions.

## Scope
These rules guide development only for the `laravel` codebase. Shared product rules remain in `/docs`.
