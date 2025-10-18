import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/history/history_state.dart';
import '../models/stock_query.dart';
import 'improved_result_screen.dart';

class ImprovedHistoryScreen extends StatelessWidget {
  const ImprovedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  if (state is HistoryLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                      ),
                    );
                  } else if (state is HistoryEmpty) {
                    return _buildEmptyState();
                  } else if (state is HistoryLoaded) {
                    return _buildHistoryList(context, state.queries);
                  } else if (state is HistoryError) {
                    return _buildErrorState(context, state.message);
                  }
                  return const Center(
                    child: Text(
                      'Загрузка...',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'История запросов',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is HistoryLoaded && state.queries.isNotEmpty) {
                return IconButton(
                  onPressed: () => _showClearDialog(context),
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: Colors.red,
                    size: 28,
                  ),
                );
              }
              return const SizedBox(width: 48);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: const Color(0xFFFFD700).withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'История пуста',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Сделайте первый запрос,\nчтобы увидеть историю',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
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
              BlocProvider.of<HistoryBloc>(context).add(HistoryLoad());
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

  Widget _buildHistoryList(BuildContext context, List<StockQuery> queries) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: queries.length,
      itemBuilder: (context, index) {
        final query = queries[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildHistoryItem(context, query, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryItem(BuildContext context, StockQuery query, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF16213E).withOpacity(0.9),
            const Color(0xFF0F0F23).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImprovedResultScreen(query: query),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStockIcon(query.stock),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        query.stock,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Строка ${query.row}, Столбец ${query.col}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        query.formattedTime,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${query.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'руб.',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockIcon(String stock) {
    IconData iconData;
    Color iconColor;

    switch (stock.toLowerCase()) {
      case 'сбер':
        iconData = Icons.account_balance;
        iconColor = const Color(0xFF4CAF50);
        break;
      case 'яндекс':
        iconData = Icons.search;
        iconColor = const Color(0xFFFF9800);
        break;
      case 'норникель':
        iconData = Icons.terrain;
        iconColor = const Color(0xFF9C27B0);
        break;
      case 'голиаф':
        iconData = Icons.shopping_cart;
        iconColor = const Color(0xFF2196F3);
        break;
      case 'валюта':
        iconData = Icons.attach_money;
        iconColor = const Color(0xFFFFD700);
        break;
      default:
        iconData = Icons.trending_up;
        iconColor = const Color(0xFFFFD700);
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Очистить историю',
          style: TextStyle(color: Color(0xFFFFD700)),
        ),
        content: const Text(
          'Вы уверены, что хотите очистить всю историю запросов?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<HistoryBloc>().add(HistoryClear());
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
