import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/stock_query.dart';
import '../widgets/animated_value_displays.dart';

class ImprovedResultScreen extends StatefulWidget {
  final StockQuery query;

  const ImprovedResultScreen({super.key, required this.query});

  @override
  State<ImprovedResultScreen> createState() => _ImprovedResultScreenState();
}

class _ImprovedResultScreenState extends State<ImprovedResultScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _playHapticFeedback();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _scaleController.forward();
    _fadeController.forward();
  }

  void _playHapticFeedback() {
    // Вибрация при показе результата
    HapticFeedback.heavyImpact();
    
    // Дополнительная вибрация через небольшую задержку для более ощутимого эффекта
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: _buildMainContent(),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFFFFD700),
              size: 28,
            ),
          ),
          const Spacer(),
          const Text(
            'Результат',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStockInfo(),
                const SizedBox(height: 40),
                _buildValueDisplay(),
                const SizedBox(height: 40),
                _buildCoordinates(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockInfo() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              widget.query.stock,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueDisplay() {
    return AnimatedValueDisplay(
      value: widget.query.value,
      effect: null, // Случайный каждый раз
    );
  }

  Widget _buildCoordinates() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCoordinateItem('Строка', widget.query.row),
                const SizedBox(width: 20),
                Container(
                  width: 1,
                  height: 30,
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
                const SizedBox(width: 20),
                _buildCoordinateItem('Столбец', widget.query.col),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoordinateItem(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.share,
            label: 'Поделиться',
            onPressed: _shareResult,
          ),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Копировать',
            onPressed: _copyResult,
          ),
          _buildActionButton(
            icon: Icons.refresh,
            label: 'Новый запрос',
            onPressed: _newQuery,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF16213E).withOpacity(0.9),
              const Color(0xFF0F0F23).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFFFD700),
              size: 24,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      )
      .animate()
      .shimmer(
        duration: 2000.ms,
        color: Colors.white.withOpacity(0.2),
      ),
    );
  }

  Future<void> _shareResult() async {
    try {
      HapticFeedback.heavyImpact();
      
      final text = 'Акция: ${widget.query.stock}\nКоординаты: строка ${widget.query.row}, столбец ${widget.query.col}\nЗначение: ${widget.query.value}\n\nНайдено через Cashflow App';
      
      await _shareResultWithScreenshot(text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при шаринге: $e'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _shareResultWithScreenshot(String text) async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = '${directory.path}/cashflow_result_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
          subject: 'Результат поиска акции ${widget.query.stock}',
        );
      } else {
        await Share.share(text);
      }
    } catch (e) {
      await Share.share(text);
    }
  }

  void _copyResult() {
    HapticFeedback.lightImpact();
    
    final text = 'Акция: ${widget.query.stock}\nКоординаты: строка ${widget.query.row}, столбец ${widget.query.col}\nЗначение: ${widget.query.value}';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Результат скопирован в буфер обмена'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _newQuery() {
    Navigator.pop(context);
  }
}
