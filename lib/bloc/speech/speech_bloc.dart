import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../services/fixed_speech_service.dart';
import '../../models/stock_data.dart';
import 'speech_event.dart';
import 'speech_state.dart';

class SpeechBloc extends Bloc<SpeechEvent, SpeechState> {
  final FixedSpeechService _speechService = FixedSpeechService();
  final Logger _logger = Logger();
  
  StreamSubscription<String>? _recognitionSubscription;
  StreamSubscription<bool>? _listeningSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<String>? _statusSubscription;

  SpeechBloc() : super(SpeechIdle()) {
    on<SpeechInitialize>(_onInitialize);
    on<SpeechStartOneTimeListening>(_onStartOneTimeListening);
    on<SpeechRecognized>(_onRecognized);
    on<SpeechStopListening>(_onStopListening);
  }

  Future<void> _onInitialize(SpeechInitialize event, Emitter<SpeechState> emit) async {
    emit(SpeechLoading());
    
    try {
      final initialized = await _speechService.initialize();
      
      if (initialized) {
        _setupSubscriptions();
        emit(SpeechIdle());
        _logger.i('Сервис речи инициализирован и готов к работе');
      } else {
        emit(const SpeechError(message: 'Не удалось инициализировать сервис речи'));
      }
    } catch (e) {
      _logger.e('Ошибка инициализации: $e');
      emit(SpeechError(message: 'Ошибка инициализации: $e'));
    }
  }

  void _setupSubscriptions() {
    _recognitionSubscription = _speechService.recognitionStream.listen((text) {
      add(SpeechRecognized(text: text, isFinal: true));
    });

    _listeningSubscription = _speechService.listeningStream.listen((isListening) {
      if (state is SpeechListening && !isListening) {
        // Если прослушивание завершилось, возвращаемся в состояние IDLE
        emit(SpeechIdle());
      }
    });

    _errorSubscription = _speechService.errorStream.listen((error) {
      emit(SpeechError(message: error));
      
      // Возвращаемся к IDLE после ошибки через 3 секунды
      Timer(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(SpeechIdle());
        }
      });
    });

    _statusSubscription = _speechService.statusStream.listen((statusMessage) {
      _logger.d('STATUS: $statusMessage');
    });
  }

  void _onStartOneTimeListening(SpeechStartOneTimeListening event, Emitter<SpeechState> emit) async {
    try {
      // Останавливаем текущее прослушивание если оно есть
      await _speechService.stopListening();
      
      // Запускаем новое
      emit(SpeechListening());
      await _speechService.startListening();
      _logger.i('Запуск одноразового прослушивания');
    } catch (e) {
      _logger.e('Ошибка запуска прослушивания: $e');
      emit(SpeechError(message: 'Ошибка запуска прослушивания: $e'));
    }
  }

  void _onStopListening(SpeechStopListening event, Emitter<SpeechState> emit) async {
    await _speechService.stopListening();
    emit(SpeechIdle());
    _logger.i('Остановка прослушивания');
  }

  void _onRecognized(SpeechRecognized event, Emitter<SpeechState> emit) {
    if (event.isFinal) {
      try {
        emit(SpeechProcessing());
        
        // Парсинг команды
        final command = _parseCommand(event.text);
        if (command != null) {
          emit(SpeechSuccess(command: command));
          _logger.i('Команда успешно распознана: $command');
        } else {
          emit(SpeechError(message: 'Не удалось распознать команду'));
          _logger.w('Не удалось распознать команду: ${event.text}');
          
          // Возвращаемся к IDLE через 2 секунды после ошибки
          Timer(const Duration(seconds: 2), () {
            if (!isClosed) {
              emit(SpeechIdle());
            }
          });
        }
      } catch (e) {
        _logger.e('Ошибка парсинга команды: $e');
        emit(SpeechError(message: 'Ошибка обработки команды'));
        
        // Возвращаемся к IDLE через 2 секунды после ошибки
        Timer(const Duration(seconds: 2), () {
          if (!isClosed) {
            emit(SpeechIdle());
          }
        });
      }
    }
  }

  String? _parseCommand(String text) {
    _logger.d('Парсинг команды: "$text"');
    
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    _logger.d('Исходные слова: $words');
    
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
    _logger.d('Обработанные слова: $processedWords');
    
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
        _logger.i('Найдена акция: $stock');
        break;
      }
    }
    
    // Поиск чисел в обработанных словах
    final numbers = <int>[];
    for (final word in processedWords) {
      final num = StockData.parseNumber(word);
      if (num != null) {
        numbers.add(num);
        _logger.d('Найдено число: $num');
      }
    }
    
    // Формирование результата - требуем как минимум 2 числа
    if (stock != null && numbers.length >= 2) {
      row = numbers[0];
      col = numbers[1];
      
      final result = '$stock $row $col';
      _logger.i('Результат парсинга: $result');
      return result;
    } else if (stock != null && numbers.length == 1) {
      // Если только одно число, считаем это и строкой и столбцом
      row = numbers[0];
      col = numbers[0];
      
      final result = '$stock $row $col';
      _logger.i('Результат парсинга (одно число): $result');
      return result;
    }
    
    // Если акция не найдена или недостаточно чисел - команда неполная
    if (stock == null) {
      _logger.d('Акция не найдена в: $text');
    } else {
      _logger.d('Недостаточно чисел. Найдено: ${numbers.length}, требуется: минимум 1');
    }
    
    return null;
  }

  @override
  Future<void> close() {
    _recognitionSubscription?.cancel();
    _listeningSubscription?.cancel();
    _errorSubscription?.cancel();
    _statusSubscription?.cancel();
    _speechService.dispose();
    return super.close();
  }
}
