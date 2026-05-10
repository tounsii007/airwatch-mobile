import 'package:airwatch_mobile/core/utils/reduced_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prefersReducedMotion picks up MediaQuery.disableAnimations',
      (tester) async {
    bool? captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            captured = prefersReducedMotion(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured, isTrue);
  });

  testWidgets('prefersReducedMotion is false by default', (tester) async {
    bool? captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            captured = prefersReducedMotion(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured, isFalse);
  });
}
