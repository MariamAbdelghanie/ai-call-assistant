import 'package:ai_call_assistant/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('telefon sahibi giris ekrani gorunur', (WidgetTester tester) async {
    await tester.pumpWidget(const CallAssistantApp());

    expect(find.text('Telefon sahibi hesabı'), findsOneWidget);
    expect(find.text('Devam et'), findsOneWidget);
  });
}
