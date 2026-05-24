import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasikoshub/main.dart';

void main() {
  testWidgets('KosHub app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));
    await tester.pump();

    expect(find.text('KosHub'), findsWidgets);
  });
}
