import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Web 版をブラウザ向けの中央カラムレイアウトに包む。
class WebShell extends StatelessWidget {
  const WebShell({super.key, required this.child});

  final Widget child;

  static const _maxContentWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final brightness = Theme.of(context).brightness;
    final outerColor = brightness == Brightness.light
        ? const Color(0xFFE9EEF5)
        : const Color(0xFF0E1116);
    final frameColor = brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF1A1D21);

    return ColoredBox(
      color: outerColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: frameColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _WebTopBar(brightness: brightness),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final barColor = brightness == Brightness.light
        ? AppColors.primary.withValues(alpha: 0.06)
        : const Color(0xFF232830);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: barColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.language, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'まもる計算',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Web版',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
