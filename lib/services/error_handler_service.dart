import 'dart:async';
import 'package:logger/logger.dart';

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  final Logger _logger = Logger();
  
  // Потоки для уведомлений об ошибках
  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  final StreamController<String> _warningController = StreamController<String>.broadcast();
  final StreamController<String> _infoController = StreamController<String>.broadcast();

  // Геттеры для потоков
  Stream<AppError> get errorStream => _errorController.stream;
  Stream<String> get warningStream => _warningController.stream;
  Stream<String> get infoStream => _infoController.stream;

  void handleError(String message, {String? context, dynamic exception, StackTrace? stackTrace}) {
    final error = AppError(
      message: message,
      context: context,
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _logger.e('❌ Ошибка: $message', error: exception, stackTrace: stackTrace);
    _errorController.add(error);
  }

  void handleWarning(String message, {String? context}) {
    _logger.w('⚠️ Предупреждение: $message');
    _warningController.add('⚠️ $message');
  }

  void handleInfo(String message, {String? context}) {
    _logger.i('ℹ️ Информация: $message');
    _infoController.add('ℹ️ $message');
  }

  void handleSpeechError(String message, {String? context, dynamic exception, StackTrace? stackTrace}) {
    _logger.e('🎤 Ошибка речи: $message', error: exception, stackTrace: stackTrace);
    _errorController.add(AppError(
      message: 'Ошибка распознавания речи: $message',
      context: context ?? 'Speech Recognition',
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  void handleTtsError(String message, {String? context, dynamic exception, StackTrace? stackTrace}) {
    _logger.e('🔊 Ошибка TTS: $message', error: exception, stackTrace: stackTrace);
    _errorController.add(AppError(
      message: 'Ошибка озвучивания: $message',
      context: context ?? 'Text-to-Speech',
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  void handlePermissionError(String message, {String? context, dynamic exception, StackTrace? stackTrace}) {
    _logger.e('🔐 Ошибка разрешений: $message', error: exception, stackTrace: stackTrace);
    _errorController.add(AppError(
      message: 'Ошибка разрешений: $message',
      context: context ?? 'Permissions',
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  void handleNetworkError(String message, {String? context, dynamic exception, StackTrace? stackTrace}) {
    _logger.e('🌐 Ошибка сети: $message', error: exception, stackTrace: stackTrace);
    _errorController.add(AppError(
      message: 'Ошибка сети: $message',
      context: context ?? 'Network',
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  void handleDataError(String message, {String? context, dynamic exception, StackTrace? stackTrace}) {
    _logger.e('📊 Ошибка данных: $message', error: exception, stackTrace: stackTrace);
    _errorController.add(AppError(
      message: 'Ошибка данных: $message',
      context: context ?? 'Data Processing',
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }

  void dispose() {
    _errorController.close();
    _warningController.close();
    _infoController.close();
  }
}

class AppError {
  final String message;
  final String? context;
  final dynamic exception;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  AppError({
    required this.message,
    this.context,
    this.exception,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'AppError(message: $message, context: $context, timestamp: $timestamp)';
  }

  String get formattedMessage {
    final buffer = StringBuffer();
    buffer.write(message);
    
    if (context != null) {
      buffer.write(' (Контекст: $context)');
    }
    
    if (exception != null) {
      buffer.write(' (Исключение: $exception)');
    }
    
    return buffer.toString();
  }
}
