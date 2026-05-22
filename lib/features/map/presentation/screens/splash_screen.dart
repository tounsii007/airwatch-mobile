import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/l10n/ui_text.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoScale;
  late AnimationController _logoGlow;
  late AnimationController _textSlide;
  late AnimationController _bgShift;
  late AnimationController _fadeOut;
  late AnimationController _gridAnim;
  Timer? _textSlideTimer;
  Timer? _fadeOutTimer;

  @override
  void initState() {
    super.initState();
    _logoScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward(from: 0);
    _logoGlow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _textSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _bgShift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _gridAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _fadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Sequence: logo appears → text slides in → hold → fade out
    _textSlideTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _textSlide.forward();
      }
    });
    _fadeOutTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _fadeOut.forward().then((_) {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textSlideTimer?.cancel();
    _fadeOutTimer?.cancel();
    _logoScale.dispose();
    _logoGlow.dispose();
    _textSlide.dispose();
    _bgShift.dispose();
    _gridAnim.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoScale,
          _logoGlow,
          _textSlide,
          _bgShift,
          _fadeOut,
          _gridAnim,
        ]),
        builder: (context, _) {
          final opacity = (1.0 - _fadeOut.value).clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ═══ Layer 1: Neutral charcoal gradient background ═══
                // Was a steel-blue gradient; now a near-black charcoal mix
                // so the splash matches the iter 73 surface palette (matches
                // airwatch-web's neutral-surface look).
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.5, -1),
                      end: Alignment(0.5, 1),
                      colors: [
                        Color(0xFF151515),
                        Color(0xFF1F1F1F),
                        Color(0xFF252525),
                        Color(0xFF0F0F0F),
                      ],
                    ),
                  ),
                ),

                // ═══ Layer 2: Tech grid pattern ═══
                CustomPaint(
                  size: size,
                  painter: _TechGridPainter(
                    progress: _gridAnim.value,
                    bgProgress: _bgShift.value,
                  ),
                ),

                // ═══ Layer 3: Diagonal light streak ═══
                Positioned(
                  top: -size.height * 0.3,
                  left: -size.width * 0.5 + (_bgShift.value * size.width * 0.3),
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Container(
                      width: size.width * 2,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.02),
                            Colors.white.withValues(alpha: 0.04),
                            Colors.white.withValues(alpha: 0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ═══ Layer 4: Center logo + text ═══
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Metallic "A" logo
                      Transform.scale(
                        scale: Curves.elasticOut.transform(
                          _logoScale.value.clamp(0.0, 1.0),
                        ),
                        child: _AirwatchLogo(
                          glowIntensity: _logoGlow.value,
                          size: 120,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // "AIRWATCH" text
                      SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.5),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _textSlide,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: FadeTransition(
                          opacity: _textSlide,
                          child: Column(
                            children: [
                              // App name with metallic shader
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFCCD6E0),
                                        Color(0xFF8A9BB0),
                                        Color(0xFFE0E8F0),
                                        Color(0xFF7A8DA0),
                                      ],
                                      stops: [0.0, 0.4, 0.6, 1.0],
                                    ).createShader(bounds),
                                child: const Text(
                                  'AIRWATCH',
                                  style: TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 8,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                context.tr('airwatch_tagline'),
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(
                                    0xFF8A9BB0,
                                  ).withValues(alpha: 0.6),
                                  letterSpacing: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ═══ Layer 5: Bottom loading bar ═══
                Positioned(
                  bottom: size.height * 0.12,
                  left: size.width * 0.25,
                  right: size.width * 0.25,
                  child: FadeTransition(
                    opacity: _textSlide,
                    child: _LoadingBar(progress: _textSlide.value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The metallic "A" arrow logo from the mockup
class _AirwatchLogo extends StatelessWidget {
  final double glowIntensity;
  final double size;
  const _AirwatchLogo({required this.glowIntensity, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(glowIntensity: glowIntensity)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double glowIntensity;
  _LogoPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final s = size.width / 100;

    // Glow behind logo
    canvas.drawCircle(
      Offset(cx, cx),
      40 * s,
      Paint()
        ..color = const Color(
          0xFF4A6B8A,
        ).withValues(alpha: 0.08 + glowIntensity * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // The "A" arrow shape — metallic look
    final path = Path()
      ..moveTo(cx, 10 * s) // Top point
      ..lineTo(cx + 35 * s, 75 * s) // Bottom right
      ..lineTo(cx + 25 * s, 75 * s) // Inner right
      ..lineTo(cx + 18 * s, 55 * s) // Right notch top
      ..lineTo(cx - 18 * s, 55 * s) // Left notch top
      ..lineTo(cx - 25 * s, 75 * s) // Inner left
      ..lineTo(cx - 35 * s, 75 * s) // Bottom left
      ..close();

    // Metallic gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(
          const Color(0xFFD0D8E0),
          const Color(0xFFE8F0F8),
          glowIntensity,
        )!,
        const Color(0xFFA0AEC0),
        const Color(0xFFCCD6E0),
        const Color(0xFF8090A4),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        )
        ..style = PaintingStyle.fill,
    );

    // Subtle edge highlight (left edge)
    canvas.drawPath(
      Path()
        ..moveTo(cx, 10 * s)
        ..lineTo(cx - 35 * s, 75 * s)
        ..lineTo(cx - 25 * s, 75 * s)
        ..lineTo(cx - 3 * s, 15 * s)
        ..close(),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08 + glowIntensity * 0.04)
        ..style = PaintingStyle.fill,
    );

    // Inner crossbar of the "A"
    final barPath = Path()
      ..moveTo(cx - 15 * s, 50 * s)
      ..lineTo(cx + 15 * s, 50 * s)
      ..lineTo(cx + 12 * s, 45 * s)
      ..lineTo(cx - 12 * s, 45 * s)
      ..close();
    canvas.drawPath(
      barPath,
      Paint()..color = const Color(0xFF8A9BB0).withValues(alpha: 0.5),
    );

    // Subtle metallic reflection line
    canvas.drawLine(
      Offset(cx - 5 * s, 18 * s),
      Offset(cx + 15 * s, 50 * s),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06 + glowIntensity * 0.04)
        ..strokeWidth = 1.5 * s
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.glowIntensity != glowIntensity;
}

/// Tech grid background
class _TechGridPainter extends CustomPainter {
  final double progress;
  final double bgProgress;
  _TechGridPainter({required this.progress, required this.bgProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2A3F5A).withValues(alpha: 0.15)
      ..strokeWidth = 0.3;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Subtle circuit-like patterns at random grid intersections
    final rng = math.Random(42);
    final dotPaint = Paint()
      ..color = const Color(0xFF4A6B8A).withValues(alpha: 0.12);
    for (int i = 0; i < 20; i++) {
      final x = (rng.nextInt((size.width / 40).floor()) * 40).toDouble();
      final y = (rng.nextInt((size.height / 40).floor()) * 40).toDouble();
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
      // Small connecting lines
      if (rng.nextBool()) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 40, y),
          Paint()
            ..color = const Color(0xFF4A6B8A).withValues(alpha: 0.08)
            ..strokeWidth = 0.5,
        );
      }
    }

    // Animated scan line
    final scanY = size.height * progress;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      Paint()
        ..color = const Color(0xFF6B8AB0).withValues(alpha: 0.06)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _TechGridPainter old) =>
      old.progress != progress;
}

/// Loading bar
class _LoadingBar extends StatelessWidget {
  final double progress;
  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: const Color(0xFF2A3F5A).withValues(alpha: 0.3),
          ),
          // Progress-bar fill grows from the leading edge — flips
          // automatically in RTL so the bar still "fills toward
          // the future" (which is the right side for an Arabic reader).
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A6B8A), Color(0xFF8AA0B8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B8AB0).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('initializing'),
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 10,
            color: const Color(0xFF6B8AB0).withValues(alpha: 0.4),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
