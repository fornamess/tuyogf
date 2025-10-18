class StockQuery {
  final String stock;
  final int row;
  final int col;
  final int value;
  final DateTime timestamp;

  StockQuery({
    required this.stock,
    required this.row,
    required this.col,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'stock': stock,
      'row': row,
      'col': col,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory StockQuery.fromJson(Map<String, dynamic> json) {
    return StockQuery(
      stock: json['stock'],
      row: json['row'],
      col: json['col'],
      value: json['value'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
