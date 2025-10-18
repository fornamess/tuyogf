import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../bloc/speech/speech_bloc.dart';
import '../bloc/speech/speech_event.dart';
import '../bloc/speech/speech_state.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../models/stock_data.dart';
import '../models/stock_query.dart';
import 'improved_result_screen.dart';
import 'improved_history_screen.dart';

class ImprovedMainScreen extends StatefulWidget {
  const ImprovedMainScreen({super.key});

  @override
  State<ImprovedMainScreen> createState() => _ImprovedMainScreenState();
}

class _ImprovedMainScreenState extends State<ImprovedMainScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  Future<void> _initializeApp() async {
    await WakelockPlus.enable();
    context.read<SpeechBloc>().add(SpeechInitialize());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F23),
        title: const Text(
          'Cashflow',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<SpeechBloc>().add(SpeechInitialize());
            },
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
      body: _buildMainContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Cashflow',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => HistoryBloc()..add(HistoryLoad()),
                    child: const ImprovedHistoryScreen(),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.history,
              color: Color(0xFFFFD700),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFFFD700)),
          SizedBox(height: 20),
          Text(
            'Инициализация...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'Ошибка',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              context.read<SpeechBloc>().add(SpeechInitialize());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: Text(
        'Загрузка...',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocListener<SpeechBloc, SpeechState>(
      listener: (context, state) {
        if (state is SpeechSuccess) {
          // Парсим команду правильно (как в SpeechBloc)
          final commandText = state.command;
          final words = commandText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
          
          // Добавляем логику для разделения составных чисел типа "25" -> ["2", "5"]
          final processedWords = <String>[];
          for (final word in words) {
            // Проверяем, является ли слово числом и больше 9
            final parsedNum = StockData.parseNumber(word);
            if (parsedNum != null && parsedNum > 9 && parsedNum < 100) {
              // Разделяем двузначные числа на отдельные цифры
              final numStr = parsedNum.toString();
              for (int i = 0; i < numStr.length; i++) {
                processedWords.add(numStr[i]);
              }
            } else {
              processedWords.add(word);
            }
          }
          
          String? stock;
          int? row;
          int? col;
          
          final stocksLower = StockData.getAvailableStocks().map((s) => s.toLowerCase()).toList();
          
          // Поиск акции в исходных словах (до обработки чисел)
          for (final word in words) {
            if (stocksLower.contains(word.toLowerCase())) {
              stock = StockData.getAvailableStocks().firstWhere(
                (s) => s.toLowerCase() == word.toLowerCase()
              );
              break;
            }
          }
          
          // Поиск чисел в обработанных словах
          final numbers = <int>[];
          for (final word in processedWords) {
            final num = StockData.parseNumber(word);
            if (num != null) {
              numbers.add(num);
            }
          }
          
          // Отладочная информация
          print('Распознанная команда: "$commandText"');
          print('Исходные слова: $words');
          print('Обработанные слова: $processedWords');
          print('Акция: $stock');
          print('Числа: $numbers');
          
          if (stock != null && numbers.length >= 2) {
            row = numbers[0];
            col = numbers[1];
            
            print('Результат: $stock строка $row столбец $col');
            
            try {
              // Получаем значение из таблицы
              final value = StockData.getValue(stock, row, col);
              
              // Создаем StockQuery
              final query = StockQuery(
                stock: stock,
                row: row,
                col: col,
                value: value,
                timestamp: DateTime.now(),
              );
              
              // Вибрация при успешном распознавании
              HapticFeedback.heavyImpact();
              
              // Переходим с объектом
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImprovedResultScreen(query: query),
                ),
              ).then((_) {
                // После возврата с экрана результата сбрасываем состояние
                context.read<SpeechBloc>().add(SpeechStopListening());
              });
            } catch (e) {
              // Если ошибка при получении значения
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              // Сбрасываем состояние после ошибки
              context.read<SpeechBloc>().add(SpeechStopListening());
            }
          } else {
            // Если не удалось распарсить команду
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Не удалось распознать команду: $commandText'),
                backgroundColor: Colors.red,
              ),
            );
            // Сбрасываем состояние после ошибки парсинга
            context.read<SpeechBloc>().add(SpeechStopListening());
          }
        } else if (state is SpeechError) {
          // Показываем ошибку только если это не timeout
          if (!state.message.contains('timeout')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: BlocBuilder<SpeechBloc, SpeechState>(
        builder: (context, state) {
          if (state is SpeechLoading) {
            return _buildLoadingState();
          } else if (state is SpeechIdle) {
            return _buildIdleContent();
          } else if (state is SpeechListening) {
            return _buildListeningContent();
          } else if (state is SpeechProcessing) {
            return _buildProcessingContent();
          } else if (state is SpeechError) {
            return _buildErrorContent(state);
          } else {
            return _buildIdleContent();
          }
        },
      ),
    );
  }

  Widget _buildIdleContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              context.read<SpeechBloc>().add(SpeechStartOneTimeListening());
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.3),
                    const Color(0xFFFFD700).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                size: 60,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.2),
                  const Color(0xFFFFD700).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              'Нажмите микрофон и скажите название акции и координаты',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 60),
          _buildAvailableStocks(),
        ],
      ),
    );
  }

  Widget _buildListeningContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.3),
                        const Color(0xFF4CAF50).withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 60,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4CAF50).withOpacity(0.2),
                  const Color(0xFF4CAF50).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              'Слушаю команду...',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3).withOpacity(0.3),
                  const Color(0xFF2196F3).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF2196F3),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.sync,
              size: 60,
              color: Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2196F3).withOpacity(0.2),
                  const Color(0xFF2196F3).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF2196F3).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Text(
              'Обрабатываю команду...',
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(SpeechError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),
              border: Border.all(
                color: Colors.red,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.error,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.red.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Text(
              state.message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Принудительно возвращаемся в IDLE и запускаем новое прослушивание
              context.read<SpeechBloc>().add(SpeechStopListening());
              Future.delayed(const Duration(milliseconds: 100), () {
                context.read<SpeechBloc>().add(SpeechStartOneTimeListening());
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableStocks() {
    final stocks = StockData.getAvailableStocks();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF16213E).withOpacity(0.8),
            const Color(0xFF0F0F23).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Доступные акции:',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stocks.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stocks.map((stock) => _buildStockChip(stock)).toList(),
          ),
          const SizedBox(height: 15),
          const Text(
            'Пример команды: "Сбер два пять"',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockChip(String stock) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        stock,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            icon: Icons.info_outline,
            label: 'Инструкция',
            onPressed: _showInstructions,
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
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF16213E).withOpacity(0.9),
              const Color(0xFF0F0F23).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSpeechActivation(String command) {
    try {
      final parts = command.split(' ');
      if (parts.length >= 3) {
        final stock = parts[0];
        final row = int.parse(parts[1]);
        final col = int.parse(parts[2]);
        
        final value = StockData.getValue(stock, row, col);
        
        final query = StockQuery(
          stock: stock,
          row: row,
          col: col,
          value: value,
          timestamp: DateTime.now(),
        );
        
        // Добавляем в историю
        context.read<HistoryBloc>().add(HistoryAddQuery(query: query));
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImprovedResultScreen(query: query),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Ошибка обработки команды: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Ошибка',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Как пользоваться',
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        content: const Text(
          '1. Произнесите название акции и координаты\n'
          '2. Например: "Яндекс два пять"\n\n'
          'Доступные акции:\n'
          '• Сбер\n• Яндекс\n• Норникель\n• Голиаф\n• Валюта',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Понятно',
              style: TextStyle(color: Color(0xFFFFD700)),
            ),
          ),
        ],
      ),
    );
  }

}
