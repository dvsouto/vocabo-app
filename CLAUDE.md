# Vocabo App

Flutter monorepo managed with Melos 7.x + Dart Pub Workspaces.

## Structure
- `apps/vocabo_mobile` - iOS + Android app
- `apps/vocabo_desktop` - macOS app
- `packages/vocabo_core` - Pure Dart: models, enums, constants, exceptions
- `packages/vocabo_api` - API client, repositories, DTOs (depends on vocabo_core)
- `packages/vocabo_ui` - Shared Flutter widgets, theme (depends on vocabo_core)
- `packages/vocabo_translation_mlkit` - ML Kit implementation of `TranslationService`; only the mobile app depends on it (it has no arm64 simulator slice, so the iOS simulator build drops it)
- `packages/vocabo_l10n` - The 16 ARB files, `context.l10n` and localized label helpers (generated output is gitignored; run `melos gen:l10n`)
- `packages/vocabo_app` - Everything the apps share: providers, services, auth, plans, screens and widgets. Apps keep only their shell and override `platformAdapterProvider` / `platformSettingsCardProvider` with what the OS offers

## Commands
- `melos bootstrap` - Install all dependencies
- `melos analyze` - Run static analysis across all packages
- `melos test` - Run tests across all packages
- `melos format` - Format all Dart files
- `melos clean` - Clean all packages
- `melos gen` - Run build_runner code generation
- `melos gen:l10n` - Generate the translations in `vocabo_l10n`
- Mobile previews: `apps/vocabo_mobile/integration_test/screens_preview_test.dart` saves phone screenshots (see the scratch notes in the test header); Android needs `flutter config --jdk-dir` pointing at a JDK 17/21 when Android Studio bundles a newer one

## Conventions
- Melos config lives in the root `pubspec.yaml` under the `melos:` key (Melos 7.x)
- Every sub-package must have `resolution: workspace` in its pubspec.yaml
- `vocabo_core` must remain pure Dart (no Flutter SDK dependency)
- Apps reference shared packages via relative path dependencies
- Business rules and screens live in `vocabo_app`, never in an app; an app only adds platform integrations (window, tray, spotlight, pickers, notifications)
- All generated code (*.g.dart, *.freezed.dart) is gitignored
