# Vocabo App

Flutter monorepo managed with Melos 7.x + Dart Pub Workspaces.

## Structure
- `apps/vocabo_mobile` - iOS + Android app
- `apps/vocabo_desktop` - macOS app
- `packages/vocabo_core` - Pure Dart: models, enums, constants, exceptions
- `packages/vocabo_api` - API client, repositories, DTOs (depends on vocabo_core)
- `packages/vocabo_ui` - Shared Flutter widgets, theme (depends on vocabo_core)

## Commands
- `melos bootstrap` - Install all dependencies
- `melos analyze` - Run static analysis across all packages
- `melos test` - Run tests across all packages
- `melos format` - Format all Dart files
- `melos clean` - Clean all packages
- `melos gen` - Run build_runner code generation

## Conventions
- Melos config lives in the root `pubspec.yaml` under the `melos:` key (Melos 7.x)
- Every sub-package must have `resolution: workspace` in its pubspec.yaml
- `vocabo_core` must remain pure Dart (no Flutter SDK dependency)
- Apps reference shared packages via relative path dependencies
- All generated code (*.g.dart, *.freezed.dart) is gitignored
