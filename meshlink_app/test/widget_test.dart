import 'package:flutter_test/flutter_test.dart';
import 'package:meshlink_app/main.dart';

void main() {
  testWidgets('MeshLink app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MeshLinkApp());
    expect(find.text('MeshLink'), findsOneWidget);
  });
}
