import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ValueDisplayEffect {
  explosion,
  lightWave,
  fire,
  electric,
  confetti,
  hologram,
  portal,
  diamond,
}

class AnimatedValueDisplay extends StatefulWidget {
  final int value;
  final ValueDisplayEffect? effect;

  const AnimatedValueDisplay({
    super.key,
    required this.value,
    this.effect,
  });

  // Случайный выбор эффекта
  static ValueDisplayEffect getRandomEffect() {
    final effects = ValueDisplayEffect.values;
    return effects[Random().nextInt(effects.length)];
  }

  @override
  State<AnimatedValueDisplay> createState() => _AnimatedValueDisplayState();
}

class _AnimatedValueDisplayState extends State<AnimatedValueDisplay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late ValueDisplayEffect _selectedEffect;

  @override
  void initState() {
    super.initState();
    _selectedEffect = widget.effect ?? AnimatedValueDisplay.getRandomEffect();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _getCurve(),
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.2,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  Curve _getCurve() {
    switch (_selectedEffect) {
      case ValueDisplayEffect.explosion:
        return Curves.elasticOut;
      case ValueDisplayEffect.lightWave:
        return Curves.easeInOut;
      case ValueDisplayEffect.fire:
        return Curves.bounceOut;
      case ValueDisplayEffect.electric:
        return Curves.elasticInOut;
      case ValueDisplayEffect.confetti:
        return Curves.elasticOut;
      case ValueDisplayEffect.hologram:
        return Curves.easeInOut;
      case ValueDisplayEffect.portal:
        return Curves.easeInOut;
      case ValueDisplayEffect.diamond:
        return Curves.elasticOut;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _getBorderColor(),
          width: 3,
        ),
        boxShadow: _getShadows(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Эффект на заднем плане
          _buildEffectBackground(),
          // Основное число
          _buildValueText(),
        ],
      ),
    );
  }

  Widget _buildEffectBackground() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(300, 200),
          painter: _getEffectPainter(),
        );
      },
    );
  }

  Widget _buildValueText() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              'ЗНАЧЕНИЕ',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ).animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .slideY(begin: -0.2, end: 0),
            const SizedBox(height: 20),
            Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.3,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    '${widget.value}',
                    style: _getTextStyle(),
                  ),
                ),
              ),
            ).animate()
              .scale(
                begin: Offset(0.5, 0.5),
                end: Offset(1.0, 1.0),
                duration: 800.ms,
                curve: Curves.elasticOut,
              )
              .shimmer(
                duration: 2000.ms,
                color: Colors.white.withOpacity(0.3),
                delay: 1000.ms,
              ),
          ],
        );
      },
    );
  }

  CustomPainter _getEffectPainter() {
    switch (_selectedEffect) {
      case ValueDisplayEffect.explosion:
        return ExplosionPainter(_controller.value);
      case ValueDisplayEffect.lightWave:
        return LightWavePainter(_controller.value);
      case ValueDisplayEffect.fire:
        return FirePainter(_controller.value);
      case ValueDisplayEffect.electric:
        return ElectricPainter(_controller.value);
      case ValueDisplayEffect.confetti:
        return ConfettiPainter(_controller.value);
      case ValueDisplayEffect.hologram:
        return HologramPainter(_controller.value);
      case ValueDisplayEffect.portal:
        return PortalPainter(_controller.value);
      case ValueDisplayEffect.diamond:
        return DiamondPainter(_controller.value);
    }
  }

  List<Color> _getGradientColors() {
    switch (_selectedEffect) {
      case ValueDisplayEffect.explosion:
        return [
          const Color(0xFFFFD700).withOpacity(0.2),
          const Color(0xFFFF6B35).withOpacity(0.1),
          const Color(0xFF0F0F23).withOpacity(0.8),
        ];
      case ValueDisplayEffect.lightWave:
        return [
          const Color(0xFF4CAF50).withOpacity(0.2),
          const Color(0xFF00BCD4).withOpacity(0.1),
          const Color(0xFF0F0F23).withOpacity(0.7),
        ];
      case ValueDisplayEffect.fire:
        return [
          const Color(0xFFFF6B35).withOpacity(0.3),
          const Color(0xFFFFD700).withOpacity(0.2),
          const Color(0xFF0F0F23).withOpacity(0.8),
        ];
      case ValueDisplayEffect.electric:
        return [
          const Color(0xFF2196F3).withOpacity(0.2),
          const Color(0xFF00E5FF).withOpacity(0.3),
          const Color(0xFF0F0F23).withOpacity(0.6),
        ];
      case ValueDisplayEffect.confetti:
        return [
          const Color(0xFFFF9800).withOpacity(0.2),
          const Color(0xFFE91E63).withOpacity(0.2),
          const Color(0xFF0F0F23).withOpacity(0.7),
        ];
      case ValueDisplayEffect.hologram:
        return [
          const Color(0xFF9C27B0).withOpacity(0.2),
          const Color(0xFF00BCD4).withOpacity(0.2),
          const Color(0xFF0F0F23).withOpacity(0.6),
        ];
      case ValueDisplayEffect.portal:
        return [
          const Color(0xFF673AB7).withOpacity(0.2),
          const Color(0xFF3F51B5).withOpacity(0.3),
          const Color(0xFF0F0F23).withOpacity(0.5),
        ];
      case ValueDisplayEffect.diamond:
        return [
          const Color(0xFFFFFFFF).withOpacity(0.1),
          const Color(0xFFFFD700).withOpacity(0.2),
          const Color(0xFF0F0F23).withOpacity(0.7),
        ];
    }
  }

  Color _getBorderColor() {
    switch (_selectedEffect) {
      case ValueDisplayEffect.explosion:
        return const Color(0xFFFFD700).withOpacity(0.6);
      case ValueDisplayEffect.lightWave:
        return const Color(0xFF4CAF50).withOpacity(0.6);
      case ValueDisplayEffect.fire:
        return const Color(0xFFFF6B35).withOpacity(0.6);
      case ValueDisplayEffect.electric:
        return const Color(0xFF2196F3).withOpacity(0.6);
      case ValueDisplayEffect.confetti:
        return const Color(0xFFFF9800).withOpacity(0.6);
      case ValueDisplayEffect.hologram:
        return const Color(0xFF9C27B0).withOpacity(0.6);
      case ValueDisplayEffect.portal:
        return const Color(0xFF673AB7).withOpacity(0.6);
      case ValueDisplayEffect.diamond:
        return const Color(0xFFFFD700).withOpacity(0.6);
    }
  }

  List<BoxShadow> _getShadows() {
    final baseColor = _getBorderColor();
    switch (_selectedEffect) {
      case ValueDisplayEffect.explosion:
        return [
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ];
      case ValueDisplayEffect.lightWave:
        return [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ];
      case ValueDisplayEffect.fire:
        return [
          BoxShadow(
            color: baseColor.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ];
      case ValueDisplayEffect.electric:
        return [
          BoxShadow(
            color: baseColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 1,
          ),
        ];
      default:
        return [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ];
    }
  }

  TextStyle _getTextStyle() {
    final baseColor = _getBorderColor();
    return TextStyle(
      color: Colors.white,
      fontSize: 72,
      fontWeight: FontWeight.bold,
      letterSpacing: 2,
      shadows: [
        Shadow(
          color: baseColor.withOpacity(0.8),
          blurRadius: 10,
          offset: const Offset(0, 0),
        ),
        Shadow(
          color: baseColor.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }
}

// Базовые классы для эффектов
abstract class EffectPainter extends CustomPainter {
  final double progress;
  final Random random = Random();

  EffectPainter(this.progress);
}

class ExplosionPainter extends EffectPainter {
  static final List<Particle> _particles = [];
  
  ExplosionPainter(super.progress) {
    if (progress == 0 && _particles.isEmpty) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    _particles.clear();
    for (int i = 0; i < 60; i++) {
      _particles.add(Particle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      
      final velocity = progress * 2.5;
      final gravity = 0.02;
      final airResistance = 0.98;
      
      particle.x += particle.vx * velocity;
      particle.y += particle.vy * velocity + gravity * progress * progress;
      particle.vx *= airResistance;
      particle.vy *= airResistance;
      
      final distance = progress * size.width * 0.8;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD700),
          const Color(0xFFFF6B35),
          particle.life,
        )!.withOpacity(alpha * 0.8);
      
      final x = center.dx + particle.x * distance;
      final y = center.dy + particle.y * distance;
      
      canvas.drawCircle(
        Offset(x, y),
        (particle.size * (1 - progress)).clamp(1.0, 6.0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  double x = 0;
  double y = 0;
  double vx = (Random().nextDouble() - 0.5) * 4;
  double vy = (Random().nextDouble() - 0.5) * 4;
  double size = Random().nextDouble() * 4 + 2;
  double life = Random().nextDouble();
}

class LightWavePainter extends EffectPainter {
  LightWavePainter(super.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          const Color(0xFF4CAF50).withOpacity(0.7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final wavePosition = progress * size.width;
    canvas.drawRect(
      Rect.fromLTWH(wavePosition - 50, 0, 100, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FirePainter extends EffectPainter {
  static final List<FireParticle> _fireParticles = [];
  
  FirePainter(super.progress) {
    if (progress == 0.0) {
      _initializeFireParticles();
    }
  }

  void _initializeFireParticles() {
    _fireParticles.clear();
    for (int i = 0; i < 40; i++) {
      _fireParticles.add(FireParticle());
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _fireParticles) {
      particle.update(progress);
      
      final alpha = particle.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF990000),
          const Color(0xFFFF6B35),
          particle.temperature,
        )!.withOpacity(alpha * 0.7);
      
      if (particle.x >= 0 && particle.x <= size.width && 
          particle.y >= 0 && particle.y <= size.height) {
        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FireParticle {
  double x = Random().nextDouble() * 300 + 50;
  double y = 250;
  double vx = (Random().nextDouble() - 0.5) * 2;
  double vy = -Random().nextDouble() * 3 - 1;
  double size = Random().nextDouble() * 3 + 1;
  double life = 1.0;
  double temperature = Random().nextDouble();
  final double gravity = 0.02;
  final double wind = (Random().nextDouble() - 0.5) * 0.5;
  
  void update(double progress) {
    x += vx + wind * progress;
    y += vy;
    vy += gravity;
    
    life -= 0.01;
    size *= 0.99;
    
    if (life <= 0) {
      reset();
    }
  }
  
  void reset() {
    x = Random().nextDouble() * 300 + 50;
    y = 250;
    vx = (Random().nextDouble() - 0.5) * 2;
    vy = -Random().nextDouble() * 3 - 1;
    size = Random().nextDouble() * 3 + 1;
    life = 1.0;
    temperature = Random().nextDouble();
  }
}

class ElectricPainter extends EffectPainter {
  ElectricPainter(super.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (sin(progress * pi * 10) * 0.5 + 0.5).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(alpha * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(alpha * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final startX = size.width * (0.2 + i * 0.3);
      final startY = size.height * 0.8;
      
      final path = _generateLightningPath(startX, startY, size);
      final glowPath = _generateLightningPath(startX, startY, size);
      
      canvas.drawPath(glowPath, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  Path _generateLightningPath(double startX, double startY, Size size) {
    final path = Path();
    path.moveTo(startX, startY);
    
    double currentX = startX;
    double currentY = startY;
    
    final segments = 8 + random.nextInt(5);
    
    for (int i = 0; i < segments; i++) {
      currentX += (random.nextDouble() - 0.5) * 60;
      currentY -= random.nextDouble() * 30;
      
      if (currentX < 0) currentX = 0;
      if (currentX > size.width) currentX = size.width;
      if (currentY < 0) currentY = 0;
      
      path.lineTo(currentX, currentY);
    }
    
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiPainter extends EffectPainter {
  static final List<ConfettiParticle> _confettiParticles = [];
  
  ConfettiPainter(super.progress) {
    if (progress == 0.0) {
      _initializeConfetti();
    }
  }

  void _initializeConfetti() {
    _confettiParticles.clear();
    final colors = [
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
    ];
    
    for (int i = 0; i < 50; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: Random().nextDouble() * 400,
        y: -Random().nextDouble() * 100,
        color: colors[Random().nextInt(colors.length)],
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final confetti in _confettiParticles) {
      confetti.update(progress);
      
      final paint = Paint()
        ..color = confetti.color.withOpacity(confetti.life)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCenter(
        center: Offset(confetti.x, confetti.y),
        width: confetti.width,
        height: confetti.height,
      );
      
      canvas.save();
      canvas.translate(confetti.x, confetti.y);
      canvas.rotate(confetti.rotation);
      canvas.translate(-confetti.x, -confetti.y);
      canvas.drawRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConfettiParticle {
  double x;
  double y;
  double vx = (Random().nextDouble() - 0.5) * 4;
  double vy = Random().nextDouble() * 2 + 2;
  double rotation = 0;
  double rotationSpeed = (Random().nextDouble() - 0.5) * 0.2;
  double width = Random().nextDouble() * 6 + 4;
  double height = Random().nextDouble() * 6 + 4;
  double life = 1.0;
  Color color;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
  });

  void update(double progress) {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
    
    vy += 0.1;
    vx *= 0.99;
    
    if (y > 300) {
      life = (1 - progress).clamp(0.0, 1.0);
    }
  }
}

class HologramPainter extends EffectPainter {
  HologramPainter(super.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9C27B0).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Сканирующая линия
    final scanY = size.height * progress;
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      paint,
    );

    // Цифровые артефакты
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PortalPainter extends EffectPainter {
  PortalPainter(super.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = progress * size.width * 0.4;

    // Спираль
    final paint = Paint()
      ..color = const Color(0xFF673AB7).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    for (double angle = 0; angle < progress * 4 * pi; angle += 0.1) {
      final r = angle * 10;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      
      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);

    // Звездные частицы
    final starPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.8);
    
    for (int i = 0; i < 15; i++) {
      final angle = (i * 24) * (pi / 180);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      
      canvas.drawCircle(Offset(x, y), 2, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DiamondPainter extends EffectPainter {
  DiamondPainter(super.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Кристаллические грани
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180);
      final radius = 50 + progress * 30;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      
      canvas.drawLine(center, Offset(x, y), paint);
    }

    // Преломления света
    final lightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.6);
    
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180);
      final x = center.dx + cos(angle) * 25;
      final y = center.dy + sin(angle) * 25;
      
      canvas.drawCircle(Offset(x, y), 3, lightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
