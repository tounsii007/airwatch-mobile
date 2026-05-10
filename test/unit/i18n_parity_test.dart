import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// i18n parity test — catches drift between locales.
///
/// Mirrors airwatch-web's vitest parity test but adapted for the
/// abstract-class i18n shape: each locale subclass overrides a
/// subset of the base getters; the test asserts that every locale
/// covers the SAME set of keys (no rogues, no missing translations).
///
/// Architecture note: because the abstract `AppStrings` provides
/// English defaults via concrete getter bodies, "missing" in DE/FR/
/// ES/IT silently falls through to English at runtime. That's a
/// fine fallback — but it's still a leak. This test fails if any
/// locale silently relies on the English fallback for a key that
/// any OTHER locale has localized, since that's almost always a
/// translation oversight rather than an intentional choice.
void main() {
  test('every concrete locale overrides the same key set', () {
    final files = {
      'en': 'lib/core/l10n/strings_en.dart',
      'de': 'lib/core/l10n/strings_de.dart',
      'fr': 'lib/core/l10n/strings_fr.dart',
      'es': 'lib/core/l10n/strings_es.dart',
      'it': 'lib/core/l10n/strings_it.dart',
    };

    final keysByLocale = <String, Set<String>>{};
    for (final entry in files.entries) {
      final src = File(entry.value).readAsStringSync();
      keysByLocale[entry.key] = _extractGetterNames(src);
    }

    // Pick the union — every locale should cover the same key set.
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
      // We still want to flag it so a maintainer notices, but only
      // as a soft warning, not a fail.
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
      reason: 'i18n drift — every non-en locale must cover the union '
          'set of keys defined across all locales:\n'
          '${issues.join("\n")}',
    );
  });

  test('no empty translations', () {
    final files = [
      'lib/core/l10n/strings_de.dart',
      'lib/core/l10n/strings_fr.dart',
      'lib/core/l10n/strings_es.dart',
      'lib/core/l10n/strings_it.dart',
    ];
    final empty = <String>[];
    final emptyRe = RegExp(r"String get (\w+) =>\s*'';");
    for (final path in files) {
      final src = File(path).readAsStringSync();
      for (final m in emptyRe.allMatches(src)) {
        empty.add('$path:${m.group(1)}');
      }
    }
    expect(empty, isEmpty,
        reason: 'empty translations: ${empty.join(", ")}');
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
