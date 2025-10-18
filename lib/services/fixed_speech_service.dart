import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:audio_session/audio_session.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'fixed_tts_service.dart';
import 'error_handler_service.dart';

class FixedSpeechService {
  static final FixedSpeechService _instance = FixedSpeechService._internal();
  factory FixedSpeechService() => _instance;
  FixedSpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FixedTtsService _ttsService = FixedTtsService();
  final Logger _logger = Logger();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  // Потоки для уведомлений
  final StreamController<String> _recognitionController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  // Геттеры для потоков
  Stream<String> get recognitionStream => _recognitionController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get statusStream => _statusController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _logger.i('Инициализация сервиса речи');
      _statusController.add('Инициализация сервиса речи');
      
      // Инициализация TTS
      await _ttsService.initialize();
      
      // Запрос разрешений
      final permissions = await _requestPermissions();
      if (!permissions) {
        _logger.e('Нет разрешений для микрофона');
        _errorController.add('Нет разрешений для микрофона');
        return false;
      }

      // Настройка аудио сессии
      await _setupAudioSession();

      // Инициализация speech_to_text
      final available = await _speechToText.initialize(
        onError: (error) {
          _handleError(error.errorMsg);
        },
        onStatus: (status) {
          _handleStatusChange(status);
        },
        debugLogging: false,
      );

      if (available) {
        _isInitialized = true;
        _logger.i('Сервис речи успешно инициализирован');
        _statusController.add('Сервис речи готов к работе');
        return true;
      } else {
        _errorHandler.handleSpeechError('Speech Recognition недоступен', context: 'Инициализация');
        _logger.e('Speech Recognition недоступен');
        _errorController.add('Speech Recognition недоступен');
        return false;
      }
    } catch (e, stackTrace) {
      _errorHandler.handleSpeechError('Ошибка инициализации: $e', context: 'Инициализация', exception: e, stackTrace: stackTrace);
      _logger.e('Ошибка инициализации: $e');
      _errorController.add('Ошибка инициализации: $e');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      _logger.i('Запрос разрешений микрофона');
      
      final microphoneStatus = await Permission.microphone.status;
      _logger.d('Текущий статус микрофона: $microphoneStatus');
      
      if (microphoneStatus.isDenied) {
        _logger.i('Запрашиваем разрешение микрофона');
        
        final result = await Permission.microphone.request();
        _logger.d('Результат запроса: $result');
        
        return result.isGranted;
      }
      
      return microphoneStatus.isGranted;
    } catch (e, stackTrace) {
      _errorHandler.handlePermissionError('Ошибка запроса разрешений: $e', context: 'Микрофон', exception: e, stackTrace: stackTrace);
      _logger.e('Ошибка запроса разрешений: $e');
      return false;
    }
  }

  Future<void> _setupAudioSession() async {
    try {
      _logger.i('Настройка аудио сессии');
      
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      
      _logger.i('Аудио сессия настроена');
    } catch (e, stackTrace) {
      _errorHandler.handleError('Ошибка настройки аудио сессии: $e', context: 'Аудио сессия', exception: e, stackTrace: stackTrace);
      _logger.w('Ошибка настройки аудио сессии: $e');
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      _logger.e('Сервис не инициализирован');
      _errorController.add('Сервис не инициализирован');
      return;
    }
    
    // Если уже слушаем, сначала останавливаем
    if (_isListening) {
      _logger.w('Уже слушаю, останавливаем перед перезапуском');
      await stopListening();
      // Дополнительная задержка для полного освобождения ресурсов
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _logger.i('Начало прослушивания');
    _statusController.add('Начало прослушивания');
    
    try {
      await WakelockPlus.enable();
      
      await _speechToText.listen(
        onResult: _handleRecognitionResult,
        listenFor: const Duration(seconds: 15), // Максимум 15 секунд
        pauseFor: const Duration(seconds: 5),   // Остановка после 5 сек тишины
        localeId: 'ru_RU',
        cancelOnError: false, // Не отменять при ошибках
        partialResults: true,
        listenMode: ListenMode.dictation,
      );
      
      _logger.i('Команда listen() отправлена');
    } catch (e, stackTrace) {
      _errorHandler.handleSpeechError('Ошибка при запуске прослушивания: $e', context: 'Запуск прослушивания', exception: e, stackTrace: stackTrace);
      _logger.e('Ошибка при запуске прослушивания: $e');
      _errorController.add('Ошибка при запуске прослушивания: $e');
    }
  }

  void _handleRecognitionResult(result) {
    final text = result.recognizedWords.toLowerCase().trim();
    final isFinal = result.finalResult;
    final confidence = result.confidence;
    
    _logger.d('Распознано: "$text" (финальный: $isFinal, уверенность: $confidence)');

    if (text.isEmpty) {
      return;
    }

    // Для partial результатов просто логируем, не обрабатываем
    if (!isFinal) {
      _logger.d('Partial результат: $text - продолжаем слушать');
      return;
    }

    // Для финальных результатов проверяем уверенность
    if (confidence != null && confidence < 0.2) {
      _logger.d('Слишком низкая уверенность ($confidence), игнорируем');
      return;
    }

    // Проверяем, содержит ли результат название акции
    final stocks = ['сбер', 'яндекс', 'норникель', 'голиаф', 'валюта'];
    bool containsStock = stocks.any((stock) => text.contains(stock));
    
    if (!containsStock) {
      _logger.d('Результат не содержит название акции, игнорируем: $text');
      return;
    }

    // Отправляем финальный результат только если он содержит акцию
    _logger.i('Финальный результат с акцией: $text');
    _statusController.add('Результат: $text');
    _recognitionController.add(text);
  }

  void _handleStatusChange(String status) {
    final wasListening = _isListening;
    _isListening = status == 'listening';
    _listeningController.add(_isListening);
    
    _logger.i('Статус изменен: $status, слушаем: $_isListening (было: $wasListening)');
    _statusController.add('Статус: $status');
    
    if (status == 'listening' && !wasListening) {
      _logger.i('Прослушивание запущено');
      _statusController.add('Прослушивание запущено');
    }
    
    if (status == 'done') {
      _logger.i('Прослушивание завершено');
      _statusController.add('Прослушивание завершено');
      WakelockPlus.disable();
    }
  }

  void _handleError(String errorMsg) {
    // Не показываем ошибку timeout как критическую
    if (errorMsg.contains('timeout')) {
      _logger.i('Сессия завершена по таймауту (норма)');
      _statusController.add('Сессия завершена');
      WakelockPlus.disable();
      return;
    }
    
    _logger.e('Ошибка распознавания: $errorMsg');
    _errorController.add(errorMsg);
    WakelockPlus.disable();
  }

  Future<void> stopListening() async {
    _logger.i('Остановка прослушивания');
    _statusController.add('Остановка прослушивания');
    
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      _listeningController.add(false);
      // Небольшая задержка для завершения остановки
      await Future.delayed(const Duration(milliseconds: 100));
    }
    WakelockPlus.disable();
  }

  Future<void> speak(String text) async {
    await _ttsService.speak(text);
  }

  void dispose() {
    // Синхронная остановка для dispose
    _speechToText.stop();
    _isListening = false;
    _listeningController.add(false);
    WakelockPlus.disable();
    
    _recognitionController.close();
    _listeningController.close();
    _errorController.close();
    _statusController.close();
    _ttsService.dispose();
  }

  // Геттеры для состояния
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
}