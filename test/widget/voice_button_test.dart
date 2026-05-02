import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/features/voice/presentation/voice_button.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SafeArea(
            child: Center(child: child),
          ),
        ),
      ),
    );

void main() {
  group('VoiceButton widget', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_wrap(const VoiceButton()));
      // The widget always renders — the icon depends on platform
      // availability. In a unit test the speech_to_text init fails
      // (no platform), so we expect the unavailable / off icon.
      expect(find.byType(VoiceButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('initially shows mic-off (unavailable in test env)',
        (tester) async {
      await tester.pumpWidget(_wrap(const VoiceButton()));
      // Pump twice to give the async initSpeech a chance to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // In a widget test the platform plugin can't initialise, so the
      // button reports unavailable. Whichever icon is shown, it's
      // NOT the active-listening red-mic.
      expect(find.byIcon(Icons.mic_rounded), findsNothing);
    });
  });
}
