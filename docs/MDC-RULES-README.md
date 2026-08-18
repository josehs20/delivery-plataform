# Cursor MDC Rules

The project now contains technology-specific Cursor rules under:

- `laravel/.cursor/rules/`
- `flutter/.cursor/rules/`

The rules use Cursor MDC frontmatter with `alwaysApply`, `globs`, and `description` according to the current project-rules format.

The shared `/docs` directory remains the canonical product source of truth.

Before implementing a feature, the agent should consult the relevant shared product document, the relevant technology-specific document, and the applicable rule files.
