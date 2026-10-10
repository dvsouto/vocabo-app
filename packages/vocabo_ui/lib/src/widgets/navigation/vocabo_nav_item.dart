import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboNavItem extends StatelessWidget {
  const VocaboNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  /// Short text shown in a pill at the end of the row (e.g. a due count).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : Colors.white60;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: VocaboRadius.sm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? VocaboColors.primary : Colors.transparent,
            borderRadius: VocaboRadius.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: VocaboTypography.bodyMd.copyWith(
                    color: color,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : VocaboColors.primary.withValues(alpha: 0.35),
                    borderRadius: VocaboRadius.sm,
                  ),
                  child: Text(
                    badge!,
                    style: VocaboTypography.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
