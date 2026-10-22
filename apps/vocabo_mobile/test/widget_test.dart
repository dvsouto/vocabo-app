import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_app/vocabo_app.dart';

void main() {
  testWidgets('App renders the login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VocaboApp()));
    await tester.pumpAndSettle();

    expect(find.text('Vocabo'), findsOneWidget);
  });
}
