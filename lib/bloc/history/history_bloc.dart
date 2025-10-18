import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../models/stock_query.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final Logger _logger = Logger();
  static const String _historyKey = 'stock_query_history';
  static const int _maxHistoryItems = 20;

  HistoryBloc() : super(HistoryInitial()) {
    on<HistoryLoad>(_onLoad);
    on<HistoryAddQuery>(_onAddQuery);
    on<HistoryRemoveQuery>(_onRemoveQuery);
    on<HistoryClear>(_onClear);
  }

  Future<void> _onLoad(HistoryLoad event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      if (historyJson.isEmpty) {
        emit(HistoryEmpty());
        return;
      }
      
      final history = historyJson
          .map((json) => StockQuery.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      emit(HistoryLoaded(queries: history));
      _logger.i('История загружена: ${history.length} записей');
    } catch (e) {
      _logger.e('Ошибка загрузки истории: $e');
      emit(HistoryError(message: 'Ошибка загрузки истории: $e'));
    }
  }

  Future<void> _onAddQuery(HistoryAddQuery event, Emitter<HistoryState> emit) async {
    try {
      if (state is HistoryLoaded) {
        final currentState = state as HistoryLoaded;
        final updatedHistory = [event.query, ...currentState.queries];
        
        // Ограничиваем количество элементов
        final limitedHistory = updatedHistory.length > _maxHistoryItems
            ? updatedHistory.take(_maxHistoryItems).toList()
            : updatedHistory;
        
        // Сохраняем в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final historyJson = limitedHistory
            .map((query) => jsonEncode(query.toJson()))
            .toList();
        
        await prefs.setStringList(_historyKey, historyJson);
        
        emit(HistoryLoaded(queries: limitedHistory));
        emit(HistoryQueryAdded(query: event.query));
        _logger.i('Запрос добавлен в историю: ${event.query.stock}');
      } else {
        // Если истории нет, создаем новую
        final prefs = await SharedPreferences.getInstance();
        final historyJson = [jsonEncode(event.query.toJson())];
        await prefs.setStringList(_historyKey, historyJson);
        
        emit(HistoryLoaded(queries: [event.query]));
        emit(HistoryQueryAdded(query: event.query));
      }
    } catch (e) {
      _logger.e('Ошибка добавления в историю: $e');
      emit(HistoryError(message: 'Ошибка добавления в историю: $e'));
    }
  }

  Future<void> _onRemoveQuery(HistoryRemoveQuery event, Emitter<HistoryState> emit) async {
    try {
      if (state is HistoryLoaded) {
        final currentState = state as HistoryLoaded;
        final updatedHistory = currentState.queries.where((query) => 
            query.stock != event.query.stock || 
            query.row != event.query.row ||
            query.col != event.query.col ||
            query.timestamp != event.query.timestamp
        ).toList();
        
        final prefs = await SharedPreferences.getInstance();
        final historyJson = updatedHistory
            .map((query) => jsonEncode(query.toJson()))
            .toList();
        
        await prefs.setStringList(_historyKey, historyJson);
        
        if (updatedHistory.isEmpty) {
          emit(HistoryEmpty());
        } else {
          emit(HistoryLoaded(queries: updatedHistory));
        }
        
        _logger.i('Запрос удален из истории');
      }
    } catch (e) {
      _logger.e('Ошибка удаления из истории: $e');
      emit(HistoryError(message: 'Ошибка удаления из истории: $e'));
    }
  }

  Future<void> _onClear(HistoryClear event, Emitter<HistoryState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      emit(HistoryEmpty());
      emit(HistoryCleared());
      _logger.i('История очищена');
    } catch (e) {
      _logger.e('Ошибка очистки истории: $e');
      emit(HistoryError(message: 'Ошибка очистки истории: $e'));
    }
  }
}
