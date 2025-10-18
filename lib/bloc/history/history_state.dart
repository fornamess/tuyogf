import 'package:equatable/equatable.dart';
import '../../models/stock_query.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<StockQuery> queries;

  const HistoryLoaded({required this.queries});

  @override
  List<Object?> get props => [queries];
}

class HistoryEmpty extends HistoryState {}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class HistoryQueryAdded extends HistoryState {
  final StockQuery query;

  const HistoryQueryAdded({required this.query});

  @override
  List<Object?> get props => [query];
}

class HistoryCleared extends HistoryState {}
