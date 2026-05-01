import 'package:airwatch_mobile/core/l10n/app_strings.dart';

/// Typed result of parsing a voice transcript.
///
/// <p>Mirrors the web frontend's `VoiceCommand` union — same nine
/// command kinds so a transcript that worked on the web (e.g.
/// "show flight DLH123") fires the same intent on mobile.
sealed class VoiceCommand {
  const VoiceCommand();
}

class VShowFlight extends VoiceCommand {
  final String callsign;
  const VShowFlight(this.callsign);
}

class VGoToAirport extends VoiceCommand {
  final String query;
  const VGoToAirport(this.query);
}

class VFilterCargo extends VoiceCommand {
  const VFilterCargo();
}

class VSetStyleDark extends VoiceCommand {
  const VSetStyleDark();
}

class VSetStyleLight extends VoiceCommand {
  const VSetStyleLight();
}

class VZoomIn extends VoiceCommand {
  const VZoomIn();
}

class VZoomOut extends VoiceCommand {
  const VZoomOut();
}

class VToggleRadar extends VoiceCommand {
  const VToggleRadar();
}

class VToggleTurbulence extends VoiceCommand {
  const VToggleTurbulence();
}

typedef _Pattern = (RegExp regex, VoiceCommand Function(Match) build);

// ── EN patterns ────────────────────────────────────────────────────────────
final _patternsEn = <_Pattern>[
  (
    RegExp(r'(?:show|track|find)\s+(?:flight\s+)?([A-Z]{2,3}\d{1,5})',
        caseSensitive: false),
    (m) => VShowFlight(m.group(1)!.toUpperCase()),
  ),
  (
    RegExp(r'(?:show\s+)?cargo|freight', caseSensitive: false),
    (_) => const VFilterCargo(),
  ),
  (
    RegExp(r'dark\s+mode|switch.*dark', caseSensitive: false),
    (_) => const VSetStyleDark(),
  ),
  (
    RegExp(r'light\s+mode|switch.*light', caseSensitive: false),
    (_) => const VSetStyleLight(),
  ),
  (
    RegExp(r'zoom\s+in|closer', caseSensitive: false),
    (_) => const VZoomIn(),
  ),
  (
    RegExp(r'zoom\s+out|further', caseSensitive: false),
    (_) => const VZoomOut(),
  ),
  (
    RegExp(r'\bradar\b|\bweather\b', caseSensitive: false),
    (_) => const VToggleRadar(),
  ),
  (
    RegExp(r'turbulence', caseSensitive: false),
    (_) => const VToggleTurbulence(),
  ),
  // goToAirport must be LAST — it's the greedy catch-all.
  (
    RegExp(r'(?:go\s+to|show|open)\s+(?:airport\s+)?(\w{3,})',
        caseSensitive: false),
    (m) => VGoToAirport(m.group(1)!),
  ),
];

// ── DE patterns ────────────────────────────────────────────────────────────
final _patternsDe = <_Pattern>[
  (
    RegExp(r'(?:zeige?|suche?|finde?)\s+(?:flug\s+)?([A-Z]{2,3}\d{1,5})',
        caseSensitive: false),
    (m) => VShowFlight(m.group(1)!.toUpperCase()),
  ),
  (
    RegExp(r'fracht|cargo', caseSensitive: false),
    (_) => const VFilterCargo(),
  ),
  (
    RegExp(r'dunkel|dunkler?\s+modus', caseSensitive: false),
    (_) => const VSetStyleDark(),
  ),
  (
    RegExp(r'hell|heller?\s+modus', caseSensitive: false),
    (_) => const VSetStyleLight(),
  ),
  (
    RegExp(r'(?:rein|näher)\s*zoom|vergrößer', caseSensitive: false),
    (_) => const VZoomIn(),
  ),
  (
    RegExp(r'(?:raus|weiter)\s*zoom|verklein', caseSensitive: false),
    (_) => const VZoomOut(),
  ),
  (
    RegExp(r'\bradar\b|\bwetter\b', caseSensitive: false),
    (_) => const VToggleRadar(),
  ),
  (
    RegExp(r'turbulenz', caseSensitive: false),
    (_) => const VToggleTurbulence(),
  ),
  (
    RegExp(r'(?:gehe?\s+(?:zu|nach)|öffne?)\s+(\S{3,})', caseSensitive: false),
    (m) => VGoToAirport(m.group(1)!),
  ),
  (
    RegExp(r'(?:zeige?)\s+flughafen\s+(\S{3,})', caseSensitive: false),
    (m) => VGoToAirport(m.group(1)!),
  ),
];

// ── FR patterns ────────────────────────────────────────────────────────────
final _patternsFr = <_Pattern>[
  (
    RegExp(
        r"(?:montre|affiche|cherche|trouve)\s+(?:(?:le\s+)?vol\s+)?([A-Z]{2,3}\d{1,5})",
        caseSensitive: false),
    (m) => VShowFlight(m.group(1)!.toUpperCase()),
  ),
  (
    RegExp(
        r"(?:aller?\s+[àa]|montre|ouvre)\s+(?:(?:l')?a[ée]roport\s+)?(\w{3,})",
        caseSensitive: false),
    (m) => VGoToAirport(m.group(1)!),
  ),
  (
    RegExp(r'fret|cargo', caseSensitive: false),
    (_) => const VFilterCargo(),
  ),
  (
    RegExp(r'mode\s+sombre|sombre', caseSensitive: false),
    (_) => const VSetStyleDark(),
  ),
  (
    RegExp(r'mode\s+clair|clair', caseSensitive: false),
    (_) => const VSetStyleLight(),
  ),
  (
    RegExp(r'zoom\s+(?:avant|plus)', caseSensitive: false),
    (_) => const VZoomIn(),
  ),
  (
    RegExp(r'zoom\s+(?:arri[eè]re|moins)', caseSensitive: false),
    (_) => const VZoomOut(),
  ),
  (
    RegExp(r'radar|m[ée]t[ée]o', caseSensitive: false),
    (_) => const VToggleRadar(),
  ),
  (
    RegExp(r'turbulence', caseSensitive: false),
    (_) => const VToggleTurbulence(),
  ),
];

/// Parse a free-form transcript into a typed command. Returns `null`
/// when no pattern matches.
///
/// <p>The behaviour mirrors the web's `parseVoiceCommand`:
/// <ul>
///   <li>Try the patterns of the user's UI language first.</li>
///   <li>If nothing matched and the language was non-English, fall
///       through to the English patterns — covers the case where a
///       multilingual user mixes English flight callsigns into a
///       German / French sentence.</li>
/// </ul>
VoiceCommand? parseVoiceCommand(String transcript, AppLanguage language) {
  final t = transcript.trim();
  if (t.isEmpty) return null;

  final patterns = switch (language) {
    AppLanguage.de => _patternsDe,
    AppLanguage.fr => _patternsFr,
    AppLanguage.en => _patternsEn,
  };

  for (final (regex, build) in patterns) {
    final match = regex.firstMatch(t);
    if (match != null) return build(match);
  }

  // English fallback — see doc above.
  if (language != AppLanguage.en) {
    for (final (regex, build) in _patternsEn) {
      final match = regex.firstMatch(t);
      if (match != null) return build(match);
    }
  }
  return null;
}
