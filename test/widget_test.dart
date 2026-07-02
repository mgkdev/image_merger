import 'package:flutter_test/flutter_test.dart';
import 'package:image_merger/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ImageMergerApp());

    // Verify that the app title exists.
    expect(find.text('Image Grid Merger'), findsOneWidget);
  });
}
