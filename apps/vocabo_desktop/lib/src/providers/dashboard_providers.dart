import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardSection { library, flashcards, progress, settings }

/// Active sidebar section. Kept in a provider so flows outside the sidebar
/// (session note, notifications, tray panel) can switch sections.
final dashboardSectionProvider = StateProvider<DashboardSection>(
  (ref) => DashboardSection.library,
);
