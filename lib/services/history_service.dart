import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_query.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _historyKey = 'stock_query_history';
  static const int _maxHistoryItems = 20;

  Future<List<StockQuery>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];
      
      return historyJson
          .map((json) => StockQuery.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Ошибка загрузки истории: $e');
      return [];
    }
  }

  Future<void> addQuery(StockQuery query) async {
    try {
      final history = await getHistory();
      
      // Добавляем новый запрос в начало списка
      history.insert(0, query);
      
      // Ограничиваем количество элементов
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      // Сохраняем в SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history
          .map((query) => jsonEncode(query.toJson()))
          .toList();
      
      await prefs.setStringList(_historyKey, historyJson);
      print('Запрос добавлен в историю: ${query.stock} ${query.row} ${query.col}');
    } catch (e) {
      print('Ошибка сохранения в историю: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      print('История очищена');
    } catch (e) {
      print('Ошибка очистки истории: $e');
    }
  }

  Future<void> removeQuery(StockQuery query) async {
    try {
      final history = await getHistory();
      history.removeWhere((item) => 
          item.stock == query.stock && 
          item.row == query.row && 
          item.col == query.col &&
          item.timestamp == query.timestamp);
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history
          .map((query) => jsonEncode(query.toJson()))
          .toList();
      
      await prefs.setStringList(_historyKey, historyJson);
      print('Запрос удален из истории');
    } catch (e) {
      print('Ошибка удаления из истории: $e');
    }
  }
}
