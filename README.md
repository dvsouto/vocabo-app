# Vocabo App

Flutter monorepo with desktop (macOS) and mobile (iOS + Android) applications.

## Structure

```
apps/
  vocabo_mobile/     # iOS + Android
  vocabo_desktop/    # macOS
packages/
  vocabo_core/       # Models, enums, constants (pure Dart)
  vocabo_api/        # API client, repositories, DTOs
  vocabo_ui/         # Shared widgets, theme, design system
```

## Getting Started

```bash
# Install Melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run analyze
melos analyze

# Run mobile app
cd apps/vocabo_mobile && flutter run

# Run desktop app
cd apps/vocabo_desktop && flutter run
```
