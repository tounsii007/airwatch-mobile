import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// i18n parity test — catches drift between locales.
///
/// Mirrors airwatch-web's vitest parity test but adapted for the
/// abstract-class i18n shape: each locale subclass overrides a
/// subset of the base getters; the test asserts that every "core"
/// locale covers the SAME set of keys (no rogues, no missing
/// translations).
///
/// <h3>Core vs soft locales</h3>
/// "Core" locales (en/de/fr/es/it) are fully translated — they MUST
/// cover the union of every key any other core locale overrides.
/// Missing-in-core is treated as a translation bug and fails the
/// test. English is auto-skipped because the abstract base provides
/// English defaults; "missing" there means "the default is fine".
///
/// "Soft" locales (pl/nl/tr) are Stage-1 — they ship with ~80
/// high-visibility translations and fall back to English for the
/// rest. The test still scans them so a maintainer can see the
/// coverage trend over time, but coverage gaps surface as a non-
/// fatal print rather than a failure. Once a soft locale catches
/// up to full coverage, move it up to the `coreLocales` list and
/// the test will start enforcing parity.
///
/// <h3>Why a SoftLocale tier at all</h3>
/// Without it, adding a new locale becomes a 250-string all-or-
/// nothing commit — which is painful both for the first author and
/// for future translation reviewers. The soft tier lets nav + most
/// common interactions go bilingual immediately while leaving room
/// for a later sweep on admin / help text.
void main() {
  const coreLocales = ['en', 'de', 'fr', 'es', 'it'];
  const softLocales = ['pl', 'nl', 'tr'];

  test('every core locale overrides the same key set', () {
    final files = <String, String>{
      for (final code in coreLocales) code: 'lib/core/l10n/strings_$code.dart',
    };

    final keysByLocale = <String, Set<String>>{};
    for (final entry in files.entries) {
      final src = File(entry.value).readAsStringSync();
      keysByLocale[entry.key] = _extractGetterNames(src);
    }

    // Pick the union — every core locale should cover this set.
    final all = <String>{};
    for (final keys in keysByLocale.values) {
      all.addAll(keys);
    }

    final issues = <String>[];
    for (final entry in keysByLocale.entries) {
      final missing = all.difference(entry.value);
      if (missing.isEmpty) continue;
      // Skip the English file — base class provides English defaults
      // for unspecified keys, so missing-in-en is structurally fine.
      if (entry.key == 'en') continue;
      issues.add(
        '${entry.key} missing ${missing.length} keys: '
        '${(missing.toList()..sort()).take(8).join(", ")}'
        '${missing.length > 8 ? "..." : ""}',
      );
    }

    expect(
      issues,
      isEmpty,
      reason:
          'i18n drift — every non-en core locale must cover the union '
          'set of keys defined across all core locales:\n'
          '${issues.join("\n")}',
    );
  });

  test('soft locales pl/nl/tr report coverage non-fatally', () {
    // Re-read the core union — we measure soft locales against it.
    final coreUnion = <String>{};
    for (final code in coreLocales) {
      final src = File('lib/core/l10n/strings_$code.dart').readAsStringSync();
      coreUnion.addAll(_extractGetterNames(src));
    }

    final lines = <String>[];
    for (final code in softLocales) {
      final src = File('lib/core/l10n/strings_$code.dart').readAsStringSync();
      final keys = _extractGetterNames(src);
      final missing = coreUnion.difference(keys);
      final coverage = coreUnion.isEmpty
          ? 100.0
          : 100 * (1 - missing.length / coreUnion.length);
      lines.add(
        '[$code] Stage-1: covers ${keys.length}/${coreUnion.length} '
        'keys (${coverage.toStringAsFixed(0)} %).',
      );
    }
    for (final l in lines) {
      // ignore: avoid_print
      print(l);
    }

    // Soft locales must AT LEAST exist + parse. The coverage is just
    // a reported metric; gaps don't fail the build.
    for (final code in softLocales) {
      final file = File('lib/core/l10n/strings_$code.dart');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'soft locale $code is missing its file',
      );
    }
  });

  test('no empty translations', () {
    final files = [
      for (final c in [...coreLocales, ...softLocales])
        if (c != 'en') 'lib/core/l10n/strings_$c.dart',
    ];
    final empty = <String>[];
    final emptyRe = RegExp(r"String get (\w+) =>\s*'';");
    for (final path in files) {
      final src = File(path).readAsStringSync();
      for (final m in emptyRe.allMatches(src)) {
        empty.add('$path:${m.group(1)}');
      }
    }
    expect(empty, isEmpty, reason: 'empty translations: ${empty.join(", ")}');
  });
}

/// Pull `String get foo => '...'` getter names out of a Dart source
/// file. Robust enough for the existing format of the strings_*.dart
/// files but not a general-purpose Dart parser.
Set<String> _extractGetterNames(String src) {
  // Match `String get foo =>` — everything between `get ` and ` =>`.
  // Across line breaks because some entries are multi-line.
  final re = RegExp(r'String\s+get\s+(\w+)\s*=>', multiLine: true);
  return re.allMatches(src).map((m) => m.group(1)!).toSet();
}
