import 'package:flutter/widgets.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';

/// Right-to-left layout helpers — Dart port of airwatch-web's
/// `rtl.ts` (commit d0a7598).
///
/// <h3>Why a tiny helper</h3>
/// Two callers need to ask "is this language RTL?": the [Directionality]
/// wrapper around the MaterialApp body that flips Flutter's layout
/// system, and any component that flips an icon (chevrons, arrows).
/// Centralising the membership test means adding 'fa' or 'ur' is a
/// one-line edit.
///
/// <h3>What we deliberately do NOT do</h3>
/// We don't manually reverse the order of children in every Row — Flutter
/// already does that automatically when a [Directionality] ancestor
/// reports `TextDirection.rtl`. Components that hard-code
/// [Alignment.centerLeft] / [EdgeInsets.only(left:)] (rather than
/// `start` / `end` variants) won't flip; tracked as a follow-up.
const Set<AppLanguage> rtlLanguages = {AppLanguage.ar};

bool isRtl(AppLanguage lang) => rtlLanguages.contains(lang);

TextDirection textDirectionFor(AppLanguage lang) =>
    isRtl(lang) ? TextDirection.rtl : TextDirection.ltr;
