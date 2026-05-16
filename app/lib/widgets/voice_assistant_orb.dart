import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gemini Live–style voice orb: idle breathing + speaking pulse/ripples.
class VoiceAssistantOrb extends StatefulWidget {
  final bool isSpeaking;
  final double size;

  const VoiceAssistantOrb({
    super.key,
    required this.isSpeaking,
    this.size = 220,
  });

  @override
  State<VoiceAssistantOrb> createState() => _VoiceAssistantOrbState();
}

class _VoiceAssistantOrbState extends State<VoiceAssistantOrb>
    with TickerProviderStateMixin {
  static const Color _pink = Color(0xFFFF4FD8);
  static const Color _purple = Color(0xFF7B61FF);

  late final AnimationController _breathController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathController, _pulseController]),
        builder: (context, _) {
          final breath = 0.92 + _breathController.value * 0.08;
          final pulse = _pulseController.value;
          return CustomPaint(
            painter: _OrbPainter(
              isSpeaking: widget.isSpeaking,
              breathScale: breath,
              pulsePhase: pulse,
            ),
            child: Center(child: _MicIcon(isSpeaking: widget.isSpeaking)),
          );
        },
      ),
    );
  }
}

class _MicIcon extends StatelessWidget {
  final bool isSpeaking;
  const _MicIcon({required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _MicPainter(
        color: isSpeaking ? Colors.white : Colors.white.withOpacity(0.85),
      ),
    );
  }
}

class _MicPainter extends CustomPainter {
  final Color color;
  _MicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.42),
        width: w * 0.28,
        height: h * 0.42,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, paint);

    final stand = Path()
      ..moveTo(w * 0.5, h * 0.68)
      ..lineTo(w * 0.5, h * 0.82)
      ..moveTo(w * 0.35, h * 0.82)
      ..lineTo(w * 0.65, h * 0.82);
    canvas.drawPath(
      stand,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MicPainter oldDelegate) => oldDelegate.color != color;
}

class _OrbPainter extends CustomPainter {
  final bool isSpeaking;
  final double breathScale;
  final double pulsePhase;

  static const Color _pink = Color(0xFFFF4FD8);
  static const Color _purple = Color(0xFF7B61FF);

  _OrbPainter({
    required this.isSpeaking,
    required this.breathScale,
    required this.pulsePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.22 * breathScale;

    if (isSpeaking) {
      for (var i = 0; i < 3; i++) {
        final t = (pulsePhase + i * 0.33) % 1.0;
        final rippleRadius = baseRadius + t * size.width * 0.38;
        final opacity = (1.0 - t) * 0.45;
        canvas.drawCircle(
          center,
          rippleRadius,
          Paint()
            ..color = _pink.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _pink.withOpacity(isSpeaking ? 0.75 : 0.45),
          _purple.withOpacity(isSpeaking ? 0.55 : 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 2.2))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSpeaking ? 28 : 18);

    canvas.drawCircle(center, baseRadius * 2.0, glow);

    final orb = Paint()
      ..shader = const RadialGradient(
        colors: [_pink, _purple, Color(0xFF3D2A80)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawCircle(center, baseRadius, orb);

    final highlight = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.35), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: center + Offset(-baseRadius * 0.25, -baseRadius * 0.25),
          radius: baseRadius * 0.6,
        ),
      );
    canvas.drawCircle(center, baseRadius * 0.85, highlight);

    if (isSpeaking) {
      final arcPaint = Paint()
        ..color = _pink.withOpacity(0.25 + 0.2 * math.sin(pulsePhase * math.pi * 2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: baseRadius * 1.35),
        pulsePhase * math.pi * 2,
        math.pi * 0.8,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.isSpeaking != isSpeaking ||
      old.breathScale != breathScale ||
      old.pulsePhase != pulsePhase;
}
