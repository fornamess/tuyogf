import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';

class FixedTtsService {
  static final FixedTtsService _instance = FixedTtsService._internal();
  factory FixedTtsService() => _instance;
  FixedTtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();
  
  bool _isInitialized = false;
  bool _isLanguageAvailable = false;
  bool _isSpeaking = false;
  
  String _currentLanguage = 'ru-RU';
  String _currentEngine = '';
  
  // Потоки для уведомлений
  final StreamController<bool> _initializationController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakingController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  // Геттеры для потоков
  Stream<bool> get initializationStream => _initializationController.stream;
  Stream<bool> get speakingStream => _speakingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<String> get statusStream => _statusController.stream;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _logger.i('🚀 Инициализация TTS сервиса');
      _statusController.add('🚀 Инициализация TTS сервиса');

      // Настройка обработчиков событий
      await _setupEventHandlers();

      // Получение доступных движков
      await _getAvailableEngines();

      // Проверка доступности языка
      await _checkLanguageAvailability();

      // Настройка параметров TTS
      await _configureTtsSettings();

      _isInitialized = true;
      _initializationController.add(true);
      
      _logger.i('✅ TTS сервис успешно инициализирован');
      _statusController.add('✅ TTS сервис успешно инициализирован');
      
      return true;
    } catch (e) {
      _logger.e('💥 Ошибка инициализации TTS: $e');
      _errorController.add('Ошибка инициализации TTS: $e');
      _statusController.add('💥 Ошибка инициализации TTS: $e');
      return false;
    }
  }

  Future<void> _setupEventHandlers() async {
    // Обработчик завершения инициализации
    _flutterTts.setInitHandler(() {
      _logger.i('🎯 TTS движок инициализирован');
      _statusController.add('🎯 TTS движок инициализирован');
    });

    // Обработчик начала речи
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingController.add(true);
      _logger.i('🎤 Начало речи');
      _statusController.add('🎤 Начало речи');
    });

    // Обработчик завершения речи
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingController.add(false);
      _logger.i('✅ Речь завершена');
      _statusController.add('✅ Речь завершена');
    });

    // Обработчик ошибок
    _flutterTts.setErrorHandler((message) {
      _isSpeaking = false;
      _speakingController.add(false);
      _logger.e('❌ Ошибка TTS: $message');
      _errorController.add('Ошибка TTS: $message');
      _statusController.add('❌ Ошибка TTS: $message');
    });

    // Обработчик остановки речи
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _speakingController.add(false);
      _logger.i('⏹️ Речь остановлена');
      _statusController.add('⏹️ Речь остановлена');
    });

    // Обработчик паузы
    _flutterTts.setPauseHandler(() {
      _logger.i('⏸️ Речь приостановлена');
      _statusController.add('⏸️ Речь приостановлена');
    });

    // Обработчик продолжения
    _flutterTts.setContinueHandler(() {
      _logger.i('▶️ Речь продолжена');
      _statusController.add('▶️ Речь продолжена');
    });
  }

  Future<void> _getAvailableEngines() async {
    try {
      final engines = await _flutterTts.getEngines;
      _logger.i('🔧 Доступные TTS движки: $engines');
      _statusController.add('🔧 Доступные TTS движки: ${engines.length}');

      if (engines.isNotEmpty) {
        _currentEngine = engines.first;
        _logger.i('🎯 Выбран движок: $_currentEngine');
        _statusController.add('🎯 Выбран движок: $_currentEngine');
      }
    } catch (e) {
      _logger.w('⚠️ Не удалось получить список движков: $e');
      _statusController.add('⚠️ Не удалось получить список движков');
    }
  }

  Future<void> _checkLanguageAvailability() async {
    try {
      _logger.i('🌍 Проверка доступности языка: $_currentLanguage');
      _statusController.add('🌍 Проверка доступности языка: $_currentLanguage');

      // Получение доступных языков
      final languages = await _flutterTts.getLanguages;
      _logger.i('📋 Доступные языки: $languages');
      _statusController.add('📋 Доступные языки: ${languages.length}');

      // Проверка конкретного языка
      if (languages.contains(_currentLanguage)) {
        _isLanguageAvailable = true;
        _logger.i('✅ Язык $_currentLanguage доступен');
        _statusController.add('✅ Язык $_currentLanguage доступен');
      } else {
        // Попробуем найти альтернативный русский язык
        final russianVariants = languages.where((lang) => 
          lang.toLowerCase().startsWith('ru') || 
          lang.toLowerCase().contains('russian')
        ).toList();
        
        if (russianVariants.isNotEmpty) {
          _currentLanguage = russianVariants.first;
          _isLanguageAvailable = true;
          _logger.i('✅ Найден альтернативный русский язык: $_currentLanguage');
          _statusController.add('✅ Найден альтернативный русский язык: $_currentLanguage');
        } else {
          _isLanguageAvailable = false;
          _logger.w('⚠️ Русский язык не найден, используем системный');
          _statusController.add('⚠️ Русский язык не найден, используем системный');
        }
      }
    } catch (e) {
      _logger.e('💥 Ошибка проверки языка: $e');
      _errorController.add('Ошибка проверки языка: $e');
      _statusController.add('💥 Ошибка проверки языка');
    }
  }

  Future<void> _configureTtsSettings() async {
    try {
      _logger.i('⚙️ Настройка параметров TTS');
      _statusController.add('⚙️ Настройка параметров TTS');

      // Установка языка
      if (_isLanguageAvailable) {
        await _flutterTts.setLanguage(_currentLanguage);
        _logger.i('🌍 Язык установлен: $_currentLanguage');
        _statusController.add('🌍 Язык установлен: $_currentLanguage');
      }

      // Установка скорости речи (1.0 = нормальная скорость)
      await _flutterTts.setSpeechRate(0.8);
      _logger.i('🏃 Скорость речи: 0.8');

      // Установка высоты тона (1.0 = нормальная высота)
      await _flutterTts.setPitch(1.0);
      _logger.i('🎵 Высота тона: 1.0');

      // Установка громкости (1.0 = максимальная громкость)
      await _flutterTts.setVolume(0.8);
      _logger.i('🔊 Громкость: 0.8');

      // Настройка для Android
      if (Platform.isAndroid) {
        await _flutterTts.setEngine(_currentEngine);
        _logger.i('🤖 Android движок установлен: $_currentEngine');
        _statusController.add('🤖 Android движок установлен: $_currentEngine');
      }

      _logger.i('✅ Параметры TTS настроены');
      _statusController.add('✅ Параметры TTS настроены');
    } catch (e) {
      _logger.e('💥 Ошибка настройки TTS: $e');
      _errorController.add('Ошибка настройки TTS: $e');
      _statusController.add('💥 Ошибка настройки TTS');
    }
  }

  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      _logger.e('❌ TTS не инициализирован');
      _errorController.add('TTS не инициализирован');
      return false;
    }

    if (text.isEmpty) {
      _logger.w('⚠️ Пустой текст для озвучивания');
      return false;
    }

    try {
      _logger.i('🎤 Озвучивание: "$text"');
      _statusController.add('🎤 Озвучивание: "$text"');

      final result = await _flutterTts.speak(text);
      
      if (result == 1) {
        _logger.i('✅ Команда озвучивания отправлена успешно');
        _statusController.add('✅ Команда озвучивания отправлена успешно');
        return true;
      } else {
        _logger.e('❌ Ошибка отправки команды озвучивания: $result');
        _errorController.add('Ошибка отправки команды озвучивания: $result');
        return false;
      }
    } catch (e) {
      _logger.e('💥 Ошибка озвучивания: $e');
      _errorController.add('Ошибка озвучивания: $e');
      _statusController.add('💥 Ошибка озвучивания');
      return false;
    }
  }

  Future<bool> stop() async {
    try {
      _logger.i('⏹️ Остановка речи');
      _statusController.add('⏹️ Остановка речи');
      
      final result = await _flutterTts.stop();
      
      if (result == 1) {
        _isSpeaking = false;
        _speakingController.add(false);
        _logger.i('✅ Речь остановлена');
        _statusController.add('✅ Речь остановлена');
        return true;
      } else {
        _logger.e('❌ Ошибка остановки речи: $result');
        _errorController.add('Ошибка остановки речи: $result');
        return false;
      }
    } catch (e) {
      _logger.e('💥 Ошибка остановки речи: $e');
      _errorController.add('Ошибка остановки речи: $e');
      return false;
    }
  }

  Future<bool> pause() async {
    try {
      _logger.i('⏸️ Пауза речи');
      _statusController.add('⏸️ Пауза речи');
      
      final result = await _flutterTts.pause();
      
      if (result == 1) {
        _logger.i('✅ Речь приостановлена');
        _statusController.add('✅ Речь приостановлена');
        return true;
      } else {
        _logger.e('❌ Ошибка паузы речи: $result');
        _errorController.add('Ошибка паузы речи: $result');
        return false;
      }
    } catch (e) {
      _logger.e('💥 Ошибка паузы речи: $e');
      _errorController.add('Ошибка паузы речи: $e');
      return false;
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      _logger.i('🌍 Установка языка: $language');
      _statusController.add('🌍 Установка языка: $language');
      
      await _flutterTts.setLanguage(language);
      _currentLanguage = language;
      
      _logger.i('✅ Язык установлен: $language');
      _statusController.add('✅ Язык установлен: $language');
    } catch (e) {
      _logger.e('💥 Ошибка установки языка: $e');
      _errorController.add('Ошибка установки языка: $e');
    }
  }

  Future<void> setSpeechRate(double rate) async {
    try {
      _logger.i('🏃 Установка скорости речи: $rate');
      
      await _flutterTts.setSpeechRate(rate);
      
      _logger.i('✅ Скорость речи установлена: $rate');
    } catch (e) {
      _logger.e('💥 Ошибка установки скорости: $e');
      _errorController.add('Ошибка установки скорости: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      _logger.i('🎵 Установка высоты тона: $pitch');
      
      await _flutterTts.setPitch(pitch);
      
      _logger.i('✅ Высота тона установлена: $pitch');
    } catch (e) {
      _logger.e('💥 Ошибка установки высоты тона: $e');
      _errorController.add('Ошибка установки высоты тона: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      _logger.i('🔊 Установка громкости: $volume');
      
      await _flutterTts.setVolume(volume);
      
      _logger.i('✅ Громкость установлена: $volume');
    } catch (e) {
      _logger.e('💥 Ошибка установки громкости: $e');
      _errorController.add('Ошибка установки громкости: $e');
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      _logger.i('📋 Получены доступные языки: ${languages.length}');
      return languages;
    } catch (e) {
      _logger.e('💥 Ошибка получения языков: $e');
      _errorController.add('Ошибка получения языков: $e');
      return [];
    }
  }

  Future<List<String>> getAvailableEngines() async {
    try {
      final engines = await _flutterTts.getEngines;
      _logger.i('🔧 Получены доступные движки: ${engines.length}');
      return engines;
    } catch (e) {
      _logger.e('💥 Ошибка получения движков: $e');
      _errorController.add('Ошибка получения движков: $e');
      return [];
    }
  }

  void dispose() {
    _flutterTts.stop();
    _initializationController.close();
    _speakingController.close();
    _errorController.close();
    _statusController.close();
    _logger.i('🗑️ TTS сервис освобожден');
  }

  // Геттеры для состояния
  bool get isInitialized => _isInitialized;
  bool get isLanguageAvailable => _isLanguageAvailable;
  bool get isSpeaking => _isSpeaking;
  String get currentLanguage => _currentLanguage;
  String get currentEngine => _currentEngine;
}
