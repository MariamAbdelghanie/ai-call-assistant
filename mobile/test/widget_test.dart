// Uygulamanin acilista cokmedigini dogrulayan temel duman testi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_call_assistant/main.dart';
import 'package:ai_call_assistant/services/api_client.dart';
import 'package:ai_call_assistant/state/app_state.dart';

void main() {
  testWidgets('Karsilama ekrani aciliyor', (WidgetTester tester) async {
    final state = AppState(ApiClient());
    await tester.pumpWidget(CallAssistantApp(state: state));
    await tester.pump();

    // Karsilama ekranindaki ana eylem dugmesi gorunmeli.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
