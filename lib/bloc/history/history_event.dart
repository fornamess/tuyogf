import 'package:equatable/equatable.dart';
import '../../models/stock_query.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryLoad extends HistoryEvent {}

class HistoryAddQuery extends HistoryEvent {
  final StockQuery query;

  const HistoryAddQuery({required this.query});

  @override
  List<Object?> get props => [query];
}

class HistoryRemoveQuery extends HistoryEvent {
  final StockQuery query;

  const HistoryRemoveQuery({required this.query});

  @override
  List<Object?> get props => [query];
}

class HistoryClear extends HistoryEvent {}
