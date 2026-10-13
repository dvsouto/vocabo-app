import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';

const _icons = <String, IconData>{
  'school': Icons.school_outlined,
  'record_voice_over': Icons.record_voice_over_outlined,
  'chat_bubble_outline': Icons.chat_bubble_outline,
  'theater_comedy': Icons.theater_comedy_outlined,
  'mood': Icons.mood,
  'restaurant': Icons.restaurant,
  'emoji_objects': Icons.emoji_objects_outlined,
  'link': Icons.link,
  'text_fields': Icons.text_fields,
  'trending_up': Icons.trending_up,
  'swap_horiz': Icons.swap_horiz,
  'local_fire_department': Icons.local_fire_department_outlined,
  'devices': Icons.devices_outlined,
  'flight_takeoff': Icons.flight_takeoff,
  'work_outline': Icons.work_outline,
  'handshake': Icons.handshake_outlined,
  'home': Icons.home_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'park': Icons.park_outlined,
  'face': Icons.face_outlined,
  'people': Icons.people_outline,
  'medical_services': Icons.medical_services_outlined,
  'fitness_center': Icons.fitness_center,
  'movie': Icons.movie_outlined,
  'join_inner': Icons.join_inner,
  'badge': Icons.badge_outlined,
  'newspaper': Icons.newspaper,
  'auto_awesome': Icons.auto_awesome_outlined,
  'compare_arrows': Icons.compare_arrows,
  'graphic_eq': Icons.graphic_eq,
  'history_edu': Icons.history_edu_outlined,
  'stacked_line_chart': Icons.stacked_line_chart,
};

IconData collectionIcon(String name) =>
    _icons[name] ?? Icons.collections_bookmark_outlined;

({Color foreground, Color background}) difficultyColors(
  CollectionDifficulty difficulty,
) => switch (difficulty) {
  CollectionDifficulty.easy => (
    foreground: const Color(0xFF1E8E3E),
    background: const Color(0xFFE6F4EA),
  ),
  CollectionDifficulty.medium => (
    foreground: const Color(0xFFB45309),
    background: const Color(0xFFFFF1E0),
  ),
  CollectionDifficulty.hard => (
    foreground: const Color(0xFFC5221F),
    background: const Color(0xFFFCE8E6),
  ),
};

String difficultyLabel(AppLocalizations l10n, CollectionDifficulty value) =>
    switch (value) {
      CollectionDifficulty.easy => l10n.collectionDifficultyEasy,
      CollectionDifficulty.medium => l10n.collectionDifficultyMedium,
      CollectionDifficulty.hard => l10n.collectionDifficultyHard,
    };

/// Green, orange or red label with the collection difficulty.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge(this.difficulty, {super.key});

  final CollectionDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final colors = difficultyColors(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        difficultyLabel(context.l10n, difficulty).toUpperCase(),
        style: VocaboTypography.labelSm.copyWith(
          color: colors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// The collection icon in a tinted circle.
class CollectionIcon extends StatelessWidget {
  const CollectionIcon(this.collection, {super.key, this.size = 44});

  final WordCollection collection;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = difficultyColors(collection.difficulty);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.background,
        shape: BoxShape.circle,
      ),
      child: Icon(
        collectionIcon(collection.icon),
        color: colors.foreground,
        size: size * 0.5,
      ),
    );
  }
}
