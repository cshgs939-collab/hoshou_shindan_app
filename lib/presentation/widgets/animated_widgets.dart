import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ShieldLoadingAnimation extends StatefulWidget {
  const ShieldLoadingAnimation({super.key, this.size = 120});

  final double size;

  @override
  State<ShieldLoadingAnimation> createState() => _ShieldLoadingAnimationState();
}

class _ShieldLoadingAnimationState extends State<ShieldLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final fill = Curves.easeOut.transform(_controller.value);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ShieldPainter(fill: fill),
            child: Center(
              child: Icon(
                Icons.shield,
                size: widget.size * 0.45,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({required this.fill});

  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(rect.center, size.width / 2, background);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.secondary.withValues(alpha: 0.15),
        ],
        stops: [0, fill.clamp(0.05, 1.0)],
      ).createShader(rect);

    final fillRect = Rect.fromLTWH(
      0,
      size.height * (1 - fill),
      size.width,
      size.height * fill,
    );
    canvas.drawRect(fillRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) {
    return oldDelegate.fill != fill;
  }
}

class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  final int value;
  final String Function(int value) formatter;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, animatedValue, child) {
        return Text(
          formatter(animatedValue.round()),
          style: style,
        );
      },
    );
  }
}
