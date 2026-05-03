import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/flight_details/presentation/screens/photo_gallery_screen.dart';

void main() {
  group('PhotoGalleryScreen widget', () {
    testWidgets('renders without throwing for a known ICAO24', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PhotoGalleryScreen(icao24: 'AABBCC')),
      );
      // Initial frame — loading spinner placeholder.
      expect(find.byType(PhotoGalleryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Skip past loading delay; in a widget test the network call
      // throws (no platform), but the catch falls back to empty list
      // → empty state should render.
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('empty state shows "No photos available" + close button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: PhotoGalleryScreen(icao24: '')),
      );
      // Empty icao24 → service returns empty list immediately.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('No photos available'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
    });
  });
}
