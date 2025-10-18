import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/main.dart';

void main() {
  group('Cashflow App Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Start the app
      await tester.pumpWidget(const CashflowApp());
      await tester.pumpAndSettle();
      
      // Verify that the app starts without throwing an error
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
