import 'package:flutter_test/flutter_test.dart';

import 'package:ai_document_assistant/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const AiDocumentAssistantApp());
    expect(find.text('Document Assistant'), findsOneWidget);
  });
}
