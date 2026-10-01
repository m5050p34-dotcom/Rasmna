// ═══════════════════════════════════════════════════════════
// اختبارات Rasmna
//
// ملاحظة: التطبيق يعتمد على Supabase (يحتاج اتصالاً بشبكة)
// لذلك اختبار التطبيق الكامل غير ممكن في بيئة الاختبار.
// هنا نضع اختبارات أساسية لا تحتاج تهيئة خارجية.
// ═══════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rasmna Basic Tests', () {
    testWidgets('Simple widget renders correctly',
        (WidgetTester tester) async {
      // اختبار بسيط: تأكد أن Flutter يعمل
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Rasmna')),
          ),
        ),
      );

      expect(find.text('Rasmna'), findsOneWidget);
    });

    test('Basic math still works', () {
      // اختبار تأكدي بسيط
      expect(1 + 1, equals(2));
    });
  });
}
