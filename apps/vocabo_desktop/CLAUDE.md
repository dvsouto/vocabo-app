# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (from this directory)
flutter run -d macos

# Run with custom API URL
flutter run -d macos --dart-define=API_URL=https://api.example.com

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Monorepo commands (from root vocabo-app/)
melos bootstrap    # Install all deps
melos analyze      # Lint all packages
melos test         # Test all packages
melos gen          # Run build_runner code generation
```

## Architecture

### State Management — Riverpod

All state uses `flutter_riverpod`. Key provider patterns:

- **AsyncNotifierProvider** for operations with loading/error states (login, logout, vocabulary list)
- **FutureProvider** for one-shot async data (auth status, user profile, dictionary init)
- **Provider** for derived/computed state (API client, search service)
- **StateProvider** for simple UI state (search query, modal visibility)
- **ChangeNotifierProvider** for `AudioPlayerService`
- **Provider.family** for parameterized lookups (`isTermInVocabularyProvider(term)`)

Providers live in `lib/src/providers/`. Services with business logic live in `lib/src/services/`.

### Dual Flutter Engine (macOS Tray Panel)

The app runs **two separate Flutter engines**:

1. **Main engine** — `main()` in `lib/main.dart`, renders the full app window
2. **Tray panel engine** — `trayPanelMain()` (annotated `@pragma('vm:entry-point')`), renders a floating panel from the system tray

Communication between engines and native macOS code uses platform channels:
- `vocabo/tray_panel` — main app ↔ macOS native
- `vocabo/tray_panel_actions` — tray panel ↔ macOS native

The native tray panel controller lives in `macos/Runner/TrayPanelController.swift`.

### Navigation

Simple `Navigator.push`/`pop` based routing (no router package). Auth state in `app.dart` determines root screen:
- Authenticated → `DashboardScreen`
- Unauthenticated → `LoginEmailScreen`

### Monorepo Package Dependencies

- **vocabo_core** — Pure Dart: models (`UserVocabulary`, `Vocabulary`, `User`), enums (`WordType`), `FuzzySearchEngine`, exceptions
- **vocabo_api** — `VocaboApiClient`, repositories (`AuthRepository`, `UserVocabularyRepository`, etc.), `TokenStorage` interface
- **vocabo_ui** — Theme system (`VocaboTheme`, `VocaboColors`, `VocaboTypography`, `VocaboSpacing`), shared widgets (`VocaboTextField`, `VocaboPrimaryButton`, `GlassCard`, etc.)

### Key Architectural Decisions

- `SecureTokenStorage` (in `lib/src/auth/`) implements `TokenStorage` from vocabo_api using `flutter_secure_storage` with macOS Keychain
- Environment config via `--dart-define` with defaults in `.env` (`API_URL`)
- Audio files are cached to disk via `AudioCacheService` before playback
- `DictionaryManager` handles offline dictionary download with gzip compression and version checking
- Window close is intercepted — app hides instead of quitting (tray-resident behavior)
