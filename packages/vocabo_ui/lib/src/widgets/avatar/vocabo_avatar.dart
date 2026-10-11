import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

/// Profile photo, or the initial of the name while there is none.
class VocaboAvatar extends StatelessWidget {
  const VocaboAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.image,
    this.radius = 32,
  });

  final String name;
  final String? imageUrl;

  /// Takes precedence over [imageUrl], e.g. a photo picked but not uploaded.
  final ImageProvider? image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final provider =
        image ?? (imageUrl == null ? null : NetworkImage(imageUrl!));
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: VocaboColors.primary.withValues(alpha: 0.1),
      foregroundImage: provider,
      onForegroundImageError: provider == null ? null : (_, _) {},
      child: Text(
        initial,
        style: VocaboTypography.headlineSm.copyWith(
          color: VocaboColors.primary,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
