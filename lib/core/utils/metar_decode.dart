/// Self-contained METAR/TAF decoder — Dart port of the web frontend's
/// `metarDecode.ts`. The aviation METAR vocabulary is bounded (~50
/// weather codes, two cloud formats, two wind formats, two visibility
/// formats) and well-specified. Decoding inline gives total control
/// over what fields we surface, a pure function trivial to unit-test,
/// and a tree-shakeable label table.
///
/// Coverage:
///   * Wind: dir + speed + gust + variable + 0KT calm in KT/MPS/KMH.
///   * Visibility: stat-mile (5SM, 1/2SM, "1 1/2SM"), metric (9999 → ≥10).
///   * Clouds: SKC/CLR/CAVOK + FEW/SCT/BKN/OVC at 3-digit FL with CB/TCU.
///   * Temp/dew with M-prefix negative parsing.
///   * Altimeter: A2992 inHg / Q1013 hPa.
///   * Phenomena: 30-ish recognised codes (RA, SN, FG, TS, …) with the
///     leading intensity prefix (`-`, `+`, `VC`).
///   * TAF: walks the FM/TEMPO/BECMG groups and decodes each window
///     independently using the same primitives.
///
/// Anything unknown stays in [DecodedMetar.unknown] so the operator
/// still sees the source token; we never drop information.
library;

class DecodedWind {
  /// Heading in degrees, 0–359, or null when calm/variable.
  final int? direction;
  final int speed;
  final int? gust;

  /// Speed unit, "KT" / "MPS" / "KMH" — METAR almost always KT.
  final String unit;

  /// True when the wind is reported as variable (VRB) or "00000KT".
  final bool variable;

  const DecodedWind({
    required this.direction,
    required this.speed,
    required this.gust,
    required this.unit,
    required this.variable,
  });
}

enum VisibilityUnit { sm, m, cavok }

class DecodedVisibility {
  /// Either a numeric value (meters or stat-miles) or a string like
  /// "1 1/2" / "≥10" / "CAVOK".
  final Object value;
  final VisibilityUnit unit;

  const DecodedVisibility({required this.value, required this.unit});
}

class DecodedCloudLayer {
  /// One of SKC / CLR / CAVOK / FEW / SCT / BKN / OVC.
  final String cover;

  /// Cloud-base altitude in feet AGL, or null for SKC / CLR / CAVOK.
  final int? baseFt;

  /// Optional convective type — CB (cumulonimbus) or TCU (towering cumulus).
  final String? type;

  const DecodedCloudLayer({
    required this.cover,
    required this.baseFt,
    required this.type,
  });
}

class DecodedTemperature {
  final int? tempC;
  final int? dewC;

  const DecodedTemperature({this.tempC, this.dewC});
}

class DecodedAltimeter {
  final double? inHg;
  final int? hPa;

  const DecodedAltimeter({this.inHg, this.hPa});
}

class DecodedPhenomenon {
  /// `-` (light), `+` (heavy), `VC` (in vicinity), or null (moderate).
  final String? intensity;
  final String code;

  const DecodedPhenomenon({required this.intensity, required this.code});
}

class DecodedMetar {
  final String? station;

  /// Day-of-month + zulu time (e.g. "10 14:55Z").
  final String? observed;

  /// "AUTO" / "COR" / null.
  final String? modifier;
  final DecodedWind? wind;
  final DecodedVisibility? visibility;
  final List<DecodedCloudLayer> cloudLayers;
  final DecodedTemperature temperature;
  final DecodedAltimeter altimeter;
  final List<DecodedPhenomenon> phenomena;

  /// Source tokens we couldn't confidently decode — kept verbatim.
  final List<String> unknown;
  final String raw;

  const DecodedMetar({
    this.station,
    this.observed,
    this.modifier,
    this.wind,
    this.visibility,
    this.cloudLayers = const [],
    this.temperature = const DecodedTemperature(),
    this.altimeter = const DecodedAltimeter(),
    this.phenomena = const [],
    this.unknown = const [],
    required this.raw,
  });
}

/// Phenomena dictionary. Keys are 2-letter codes, values are
/// human-readable English labels (translated downstream by the UI).
const Map<String, String> _phenomena = {
  // Descriptors
  'MI': 'shallow', 'BC': 'patches', 'PR': 'partial', 'DR': 'low drifting',
  'BL': 'blowing', 'SH': 'shower(s)', 'TS': 'thunderstorm', 'FZ': 'freezing',
  // Precipitation
  'DZ': 'drizzle', 'RA': 'rain', 'SN': 'snow', 'SG': 'snow grains',
  'IC': 'ice crystals', 'PL': 'ice pellets', 'GR': 'hail', 'GS': 'small hail',
  'UP': 'unknown precip',
  // Obscuration
  'BR': 'mist', 'FG': 'fog', 'FU': 'smoke', 'VA': 'volcanic ash',
  'DU': 'widespread dust', 'SA': 'sand', 'HZ': 'haze',
  // Other
  'PO': 'dust whirls', 'SQ': 'squalls', 'FC': 'funnel cloud',
  'SS': 'sandstorm', 'DS': 'duststorm',
};

final _stationRe = RegExp(r'^[A-Z]{4}$');
final _observedRe = RegExp(r'^(\d{2})(\d{2})(\d{2})Z$');
final _modifierRe = RegExp(r'^(AUTO|COR)$');
final _windRe = RegExp(r'^(VRB|\d{3})(\d{2,3})(?:G(\d{2,3}))?(KT|MPS|KMH)$');
final _visSmRe = RegExp(r'^(?:(\d+)\s+)?(\d{1,2}|\d\/\d|\d+\/\d+)SM$');
final _visMRe = RegExp(r'^(\d{4})$');
final _cloudRe = RegExp(r'^(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)?$');
final _tempRe = RegExp(r'^(M?\d{2})\/(M?\d{2})$');
final _altHgRe = RegExp(r'^A(\d{4})$');
final _altHpaRe = RegExp(r'^Q(\d{4})$');
final _phenomRe = RegExp(r'^([-+]|VC)?([A-Z]{2,4})$');

/// Parse a single METAR line into structured fields. Pure function;
/// safe to call from any isolate.
DecodedMetar decodeMetar(String raw) {
  final tokens = raw.trim().split(RegExp(r'\s+')).toList();

  String? station;
  String? observed;
  String? modifier;
  DecodedWind? wind;
  DecodedVisibility? visibility;
  final cloudLayers = <DecodedCloudLayer>[];
  int? tempC;
  int? dewC;
  double? altInHg;
  int? altHpaValue;
  final phenomena = <DecodedPhenomenon>[];
  final unknown = <String>[];

  if (tokens.isNotEmpty &&
      (tokens.first == 'METAR' || tokens.first == 'SPECI')) {
    tokens.removeAt(0);
  }

  for (var i = 0; i < tokens.length; i++) {
    final tok = tokens[i];
    if (tok.isEmpty) continue;

    if (tok == 'RMK') {
      // Push the rest as a single unknown blob so the raw is preserved.
      final tail = tokens.sublist(i + 1).join(' ');
      if (tail.isNotEmpty) unknown.add('RMK $tail');
      break;
    }

    if (station == null && _stationRe.hasMatch(tok)) {
      station = tok;
      continue;
    }

    final obs = _observedRe.firstMatch(tok);
    if (observed == null && obs != null) {
      observed = '${obs.group(1)} ${obs.group(2)}:${obs.group(3)}Z';
      continue;
    }

    if (modifier == null && _modifierRe.hasMatch(tok)) {
      modifier = tok;
      continue;
    }

    if (tok == 'CAVOK') {
      visibility = const DecodedVisibility(
        value: 'CAVOK',
        unit: VisibilityUnit.cavok,
      );
      cloudLayers.add(
        const DecodedCloudLayer(cover: 'CAVOK', baseFt: null, type: null),
      );
      continue;
    }

    if (tok == 'CLR' || tok == 'SKC') {
      cloudLayers.add(DecodedCloudLayer(cover: tok, baseFt: null, type: null));
      continue;
    }

    final w = _windRe.firstMatch(tok);
    if (w != null && wind == null) {
      final dirRaw = w.group(1)!;
      final speed = int.parse(w.group(2)!);
      final gust = w.group(3) != null ? int.tryParse(w.group(3)!) : null;
      final unit = w.group(4)!;
      final variable = dirRaw == 'VRB' || (dirRaw == '000' && speed == 0);
      wind = DecodedWind(
        direction: variable ? null : int.tryParse(dirRaw),
        speed: speed,
        gust: gust,
        unit: unit,
        variable: variable,
      );
      continue;
    }

    final visSm = _visSmRe.firstMatch(tok);
    if (visSm != null && visibility == null) {
      Object value;
      final whole = visSm.group(1);
      final frac = visSm.group(2)!;
      if (whole != null && frac.contains('/')) {
        value = '$whole $frac';
      } else if (frac.contains('/')) {
        final parts = frac.split('/').map(int.parse).toList();
        value = parts[0] / parts[1];
      } else {
        value = int.parse(frac);
      }
      visibility = DecodedVisibility(value: value, unit: VisibilityUnit.sm);
      continue;
    }

    final visM = _visMRe.firstMatch(tok);
    if (visM != null && visibility == null) {
      final v = int.parse(visM.group(1)!);
      // 9999 means "10 km or more" by ICAO convention.
      visibility = DecodedVisibility(
        value: v >= 9999 ? '≥10' : v,
        unit: VisibilityUnit.m,
      );
      continue;
    }

    final cloud = _cloudRe.firstMatch(tok);
    if (cloud != null) {
      cloudLayers.add(
        DecodedCloudLayer(
          cover: cloud.group(1)!,
          baseFt: int.parse(cloud.group(2)!) * 100,
          type: cloud.group(3),
        ),
      );
      continue;
    }

    final temp = _tempRe.firstMatch(tok);
    if (temp != null && tempC == null) {
      tempC = _parseTempPart(temp.group(1)!);
      dewC = _parseTempPart(temp.group(2)!);
      continue;
    }

    final altHg = _altHgRe.firstMatch(tok);
    if (altHg != null) {
      altInHg = int.parse(altHg.group(1)!) / 100;
      continue;
    }
    final altHpa = _altHpaRe.firstMatch(tok);
    if (altHpa != null) {
      altHpaValue = int.parse(altHpa.group(1)!);
      continue;
    }

    // Phenomena tokens can stack multiple 2-letter codes after a single
    // intensity prefix: "TSRA" → ["TS","RA"], "+SHRA" → heavy shower of
    // rain. Walk 2-letter chunks; bail to the unknown bucket if any
    // chunk doesn't resolve so we don't half-decode and lose info.
    final phen = _phenomRe.firstMatch(tok);
    if (phen != null) {
      final intensity = phen.group(1);
      final body = phen.group(2)!;
      if (body.length.isEven) {
        final codes = <String>[];
        var ok = true;
        for (var p = 0; p < body.length; p += 2) {
          final code = body.substring(p, p + 2);
          if (!_phenomena.containsKey(code)) {
            ok = false;
            break;
          }
          codes.add(code);
        }
        if (ok && codes.isNotEmpty) {
          for (final code in codes) {
            phenomena.add(DecodedPhenomenon(intensity: intensity, code: code));
          }
          continue;
        }
      }
    }

    unknown.add(tok);
  }

  return DecodedMetar(
    station: station,
    observed: observed,
    modifier: modifier,
    wind: wind,
    visibility: visibility,
    cloudLayers: cloudLayers,
    temperature: DecodedTemperature(tempC: tempC, dewC: dewC),
    altimeter: DecodedAltimeter(inHg: altInHg, hPa: altHpaValue),
    phenomena: phenomena,
    unknown: unknown,
    raw: raw,
  );
}

/// Human-readable label for a phenomenon code. Returns the code itself
/// when the dictionary doesn't have an entry — keeps the operator
/// looking at *something* rather than nothing.
String phenomenonLabel(String code) => _phenomena[code] ?? code;

/// Pretty-print a phenomenon (intensity + label).
String phenomenonText(DecodedPhenomenon p) {
  final label = phenomenonLabel(p.code);
  if (p.intensity == null) return label;
  if (p.intensity == '-') return 'light $label';
  if (p.intensity == '+') return 'heavy $label';
  if (p.intensity == 'VC') return 'in vicinity: $label';
  return label;
}

int _parseTempPart(String t) {
  final sign = t.startsWith('M') ? -1 : 1;
  final num = int.parse(t.replaceFirst('M', ''));
  return sign * num;
}

class DecodedTafWindow {
  /// "INITIAL" for the first group, then FM / TEMPO / BECMG / PROB30…
  final String label;

  /// Window start (DDhhmm or DDhh→DDhh).
  final String? when;

  /// Decoded conditions for that window — reuses [DecodedMetar] shape.
  final DecodedMetar conditions;

  const DecodedTafWindow({
    required this.label,
    required this.when,
    required this.conditions,
  });
}

class DecodedTaf {
  final String? station;

  /// "DDhhmmZ" issuance time.
  final String? issued;
  final String? validFrom;
  final String? validTo;
  final List<DecodedTafWindow> windows;
  final String raw;

  const DecodedTaf({
    this.station,
    this.issued,
    this.validFrom,
    this.validTo,
    this.windows = const [],
    required this.raw,
  });
}

final _tafHeaderRe = RegExp(
  r'^TAF\s+(?:AMD\s+|COR\s+)?([A-Z]{4})\s+(\d{6}Z)\s+(\d{4})\/(\d{4})\b',
);
final _fmRe = RegExp(r'^FM(\d{6})$');
final _tempoRe = RegExp(r'^TEMPO$');
final _becmgRe = RegExp(r'^BECMG$');
final _probRe = RegExp(r'^PROB(\d{2})$');
final _periodRe = RegExp(r'^(\d{4})\/(\d{4})$');

/// Decode a TAF into its constituent forecast windows. Each window
/// carries the same [DecodedMetar] shape (minus station/observed which
/// are TAF-level, not window-level).
DecodedTaf decodeTaf(String raw) {
  String? station;
  String? issued;
  String? validFrom;
  String? validTo;
  final windows = <DecodedTafWindow>[];

  var body = raw;
  final head = _tafHeaderRe.firstMatch(raw);
  if (head != null) {
    station = head.group(1);
    issued = head.group(2);
    validFrom = head.group(3);
    validTo = head.group(4);
    body = raw.substring(head.end).trim();
  }

  final tokens = body.split(RegExp(r'\s+'));
  var cur = <String>[];
  var label = 'INITIAL';
  String? when = head != null ? '${head.group(3)}/${head.group(4)}' : null;

  void flush() {
    if (cur.isEmpty) return;
    windows.add(
      DecodedTafWindow(
        label: label,
        when: when,
        conditions: decodeMetar(cur.join(' ')),
      ),
    );
    cur = <String>[];
  }

  for (var i = 0; i < tokens.length; i++) {
    final tok = tokens[i];
    final fm = _fmRe.firstMatch(tok);
    if (fm != null) {
      flush();
      label = 'FM';
      when = fm.group(1);
      continue;
    }
    if (_tempoRe.hasMatch(tok) || _becmgRe.hasMatch(tok)) {
      flush();
      label = tok;
      when = null;
      final next = i + 1 < tokens.length ? tokens[i + 1] : null;
      final period = next != null ? _periodRe.firstMatch(next) : null;
      if (period != null) {
        when = '${period.group(1)}/${period.group(2)}';
        i++;
      }
      continue;
    }
    final prob = _probRe.firstMatch(tok);
    if (prob != null) {
      flush();
      label = 'PROB${prob.group(1)}';
      when = null;
      final next = i + 1 < tokens.length ? tokens[i + 1] : null;
      final period = next != null ? _periodRe.firstMatch(next) : null;
      if (period != null) {
        when = '${period.group(1)}/${period.group(2)}';
        i++;
      }
      continue;
    }
    cur.add(tok);
  }
  flush();

  return DecodedTaf(
    station: station,
    issued: issued,
    validFrom: validFrom,
    validTo: validTo,
    windows: windows,
    raw: raw,
  );
}
