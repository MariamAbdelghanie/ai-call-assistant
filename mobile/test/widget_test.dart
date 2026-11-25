// Uygulamanin acilista cokmedigini dogrulayan temel duman testi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_call_assistant/main.dart';
import 'package:ai_call_assistant/services/api_client.dart';
import 'package:ai_call_assistant/services/auth_service.dart';
import 'package:ai_call_assistant/state/app_state.dart';

void main() {
  testWidgets('Uygulama acilista cokmuyor', (WidgetTester tester) async {
    final state = AppState(ApiClient());
    // Firebase baslatilmadan da ekran cizilebilmeli: AuthService
    // yapilandirma yoksa hazir duruma gecip giris ekranini gosterir.
    final auth = AuthService();
    await tester.pumpWidget(CallAssistantApp(state: state, auth: auth));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
