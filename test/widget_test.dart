// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f5_health/main.dart'; // MyApp 클래스 import

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // ✅ 수정된 부분: initialRoute를 명시함
    await tester.pumpWidget(const MyApp(initialRoute: '/login'));

    // 기본적으로 '0'이 보이는지 확인
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // '+' 아이콘 누르기
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // 1로 증가했는지 확인
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}


/*
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:f5_health/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
*/