import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/utils/rtl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression net for the RTL plumbing landed across commits 9aa84e9 +
/// 2f8d2a7. Confirms:
///
///   * `isRtl` membership matches the expected language set.
///   * `textDirectionFor` returns the right `TextDirection`.
///   * `Directionality` actually flips a child's layout — using a Row
///     with a leading + trailing icon, we measure that the leading
///     icon ends up on the right side of the row when wrapped in
///     `TextDirection.rtl`. This exercises the same widget-tree path
///     the MaterialApp.builder uses in app.dart.
void main() {
  group('isRtl', () {
    test('Arabic is RTL', () {
      expect(isRtl(AppLanguage.ar), isTrue);
    });

    test('all other locales are LTR', () {
      for (final lang in [
        AppLanguage.en,
        AppLanguage.de,
        AppLanguage.fr,
        AppLanguage.es,
        AppLanguage.it,
      ]) {
        expect(isRtl(lang), isFalse, reason: '$lang must be LTR');
      }
    });
  });

  group('textDirectionFor', () {
    test('maps each AppLanguage to the right TextDirection', () {
      expect(textDirectionFor(AppLanguage.ar), TextDirection.rtl);
      expect(textDirectionFor(AppLanguage.en), TextDirection.ltr);
      expect(textDirectionFor(AppLanguage.de), TextDirection.ltr);
      expect(textDirectionFor(AppLanguage.fr), TextDirection.ltr);
      expect(textDirectionFor(AppLanguage.es), TextDirection.ltr);
      expect(textDirectionFor(AppLanguage.it), TextDirection.ltr);
    });
  });

  group('Directionality flips a Row layout under RTL', () {
    Widget buildRowUnder(TextDirection dir) => Directionality(
      textDirection: dir,
      child: const SizedBox(
        width: 200,
        height: 40,
        child: Row(
          children: [
            Icon(Icons.arrow_back, key: ValueKey('leading')),
            Expanded(child: SizedBox()),
            Icon(Icons.close, key: ValueKey('trailing')),
          ],
        ),
      ),
    );

    testWidgets('LTR: leading icon sits on the left half', (tester) async {
      await tester.pumpWidget(buildRowUnder(TextDirection.ltr));
      final leading = tester.getCenter(find.byKey(const ValueKey('leading')));
      final trailing = tester.getCenter(find.byKey(const ValueKey('trailing')));
      expect(
        leading.dx < trailing.dx,
        isTrue,
        reason: 'leading should sit to the left of trailing in LTR',
      );
    });

    testWidgets('RTL: leading icon flips to the right half', (tester) async {
      await tester.pumpWidget(buildRowUnder(TextDirection.rtl));
      final leading = tester.getCenter(find.byKey(const ValueKey('leading')));
      final trailing = tester.getCenter(find.byKey(const ValueKey('trailing')));
      expect(
        leading.dx > trailing.dx,
        isTrue,
        reason: 'leading should sit to the right of trailing in RTL',
      );
    });
  });

  group('EdgeInsetsDirectional resolves relative to TextDirection', () {
    Widget buildPaddedRow(TextDirection dir) => Directionality(
      textDirection: dir,
      child: Center(
        child: SizedBox(
          width: 100,
          height: 40,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: Container(
              key: const ValueKey('child'),
              color: const Color(0xFF000000),
            ),
          ),
        ),
      ),
    );

    testWidgets('start padding sits on the parent\'s start edge in LTR', (
      tester,
    ) async {
      await tester.pumpWidget(buildPaddedRow(TextDirection.ltr));
      final child = tester.getRect(find.byKey(const ValueKey('child')));
      // Find the SizedBox(100x40) parent rect by looking at its
      // outer rect via find.bySemanticsLabel won't work — use the
      // element traversal directly.
      final parent = tester.getRect(find.byType(SizedBox).last);
      // Child shifted right by 20 from parent's left edge.
      expect(child.left - parent.left, 20);
    });

    testWidgets('start padding flips to the parent\'s right in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(buildPaddedRow(TextDirection.rtl));
      final child = tester.getRect(find.byKey(const ValueKey('child')));
      final parent = tester.getRect(find.byType(SizedBox).last);
      // In RTL, "start" is the right edge — child sits 20 from
      // the parent's right.
      expect(parent.right - child.right, 20);
    });
  });
}
