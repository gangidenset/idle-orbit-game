import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/app/diagnostics.dart';

void main() {
  testWidgets('startup error screen shows the report and a copy button', (tester) async {
    await tester.pumpWidget(const StartupErrorApp(report: 'step: storage\nBoom'));
    expect(find.text('起動中にエラーが発生しました'), findsOneWidget);
    expect(find.textContaining('Boom'), findsOneWidget);
    expect(find.text('エラー内容をコピー'), findsOneWidget);
  });
}
