import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Selected basemap style.
///
/// <p>Mirrors the web frontend's `mapStyles.ts` so the two platforms stay
/// visually in sync. Adding a new entry here? Update [kMapStyles] AND
/// [kStyleOrder] (the picker iterates the latter for stable ordering).
enum MapStyleId { dark, night, satellite, streets, terrain, toner }

/// Per-style palette for altitude-coded flight markers.
///
/// <p>Each style ships its own hue ramp tuned for the basemap underneath —
/// e.g. [satellite] needs higher-saturation neons to pop against the
/// natural greens/blues of orthophoto tiles, while [toner] uses muted
/// pastels because the Carto-Light basemap is already low-contrast.
@immutable
class MapStyleColors {
  const MapStyleColors({
    required this.ground,
    required this.low,
    required this.med,
    required this.high,
    required this.selected,
  });

  /// Markers for aircraft on the ground (alt < 100 ft).
  final Color ground;

  /// Markers for low-altitude flights (< 10 k ft).
  final Color low;

  /// Markers for medium-altitude flights (10–30 k ft).
  final Color med;

  /// Markers for high-altitude flights (> 30 k ft).
  final Color high;

  /// Highlight ring + label for the user-selected aircraft.
  final Color selected;
}

/// Metadata for a single basemap style.
///
/// <p>The [url] points at a tile-server template (e.g. CARTO, Google sat,
/// Stadia toner). [attribution] is the legal copyright string the picker
/// displays in tiny text. [dark] flags whether the basemap itself is dark
/// — the airport-label hook uses that to flip its label colors so they
/// stay readable on either background.
@immutable
class MapStyleDef {
  const MapStyleDef({
    required this.label,
    required this.url,
    required this.attribution,
    required this.dark,
    required this.colors,
    this.maxNativeZoom,
  });

  /// 3-letter style code shown in the picker (DRK, SAT, NGT, …).
  ///
  /// <p>Doubles as the legend so a user knows what each option maps to
  /// without needing a screenshot fetch (the web version reasoned the same
  /// way: rendering 6 basemap previews would refetch tiles for styles the
  /// user may never pick).
  final String label;

  /// Tile-URL template, with `{z}/{x}/{y}` placeholders.
  final String url;

  /// One-line copyright string to display under the picker.
  final String attribution;

  /// Whether the basemap is dark — flips airport-label color contrast.
  final bool dark;

  /// Optional max-native zoom (some providers stop at zoom 18 / 19).
  final int? maxNativeZoom;

  /// Per-style marker palette (see [MapStyleColors]).
  final MapStyleColors colors;
}

// ── Color presets — kept as private consts so the catalog stays terse ──

const _darkPalette = MapStyleColors(
  ground: Color(0xFF6B7280),
  low: Color(0xFF4ADE80),
  med: Color(0xFFFBBF24),
  high: Color(0xFFE879A8),
  selected: Color(0xFFE0F0FF),
);

const _nightPalette = MapStyleColors(
  ground: Color(0xFF555555),
  low: Color(0xFF00FF88),
  med: Color(0xFFFF9500),
  high: Color(0xFFFF3B7A),
  selected: Color(0xFFFFFFFF),
);

const _satellitePalette = MapStyleColors(
  ground: Color(0xFFAAAAAA),
  low: Color(0xFF00FF66),
  med: Color(0xFFFFD700),
  high: Color(0xFFFF4488),
  selected: Color(0xFFFFFFFF),
);

const _streetsPalette = MapStyleColors(
  ground: Color(0xFF333333),
  low: Color(0xFF0066FF),
  med: Color(0xFFCC0000),
  high: Color(0xFF9900CC),
  selected: Color(0xFFFF6600),
);

const _terrainPalette = MapStyleColors(
  ground: Color(0xFF000000),
  low: Color(0xFF0000FF),
  med: Color(0xFFFF0000),
  high: Color(0xFF8B00FF),
  selected: Color(0xFFFF6600),
);

const _tonerPalette = MapStyleColors(
  ground: Color(0xFF9CA3AF),
  low: Color(0xFF22C55E),
  med: Color(0xFFEAB308),
  high: Color(0xFFEC4899),
  selected: Color(0xFF2563EB),
);

/// The full basemap catalog.
///
/// <p>URLs use `@2x` retina tiles where the provider offers them — mobile
/// devices have high-DPI screens and the bandwidth cost is acceptable.
/// The provider domain is hit directly (no nginx proxy as on the web —
/// a Flutter binary doesn't have the browser's same-origin restriction
/// that prompted that rebuild).
const Map<MapStyleId, MapStyleDef> kMapStyles = {
  MapStyleId.dark: MapStyleDef(
    label: 'DRK',
    url: 'https://basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}@2x.png',
    attribution: '© CARTO © OSM',
    dark: false,
    colors: _darkPalette,
  ),
  MapStyleId.night: MapStyleDef(
    label: 'NGT',
    url: 'https://basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}@2x.png',
    attribution: '© CARTO',
    dark: false,
    colors: _nightPalette,
  ),
  MapStyleId.satellite: MapStyleDef(
    label: 'SAT',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '© Esri',
    dark: false,
    colors: _satellitePalette,
    maxNativeZoom: 18,
  ),
  MapStyleId.streets: MapStyleDef(
    label: 'STR',
    url: 'https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}@2x.png',
    attribution: '© CARTO © OSM',
    dark: false,
    colors: _streetsPalette,
  ),
  MapStyleId.terrain: MapStyleDef(
    label: 'TER',
    url: 'https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}@2x.png',
    attribution: '© CARTO © OSM',
    dark: false,
    colors: _terrainPalette,
  ),
  MapStyleId.toner: MapStyleDef(
    label: 'LGT',
    url: 'https://basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}@2x.png',
    attribution: '© CARTO',
    dark: false,
    colors: _tonerPalette,
  ),
};

/// Stable picker order. Iterate this — not `kMapStyles.keys` — when
/// rendering, because Dart's `Map` iteration order is insertion order
/// and adding entries later would shift the picker.
const List<MapStyleId> kStyleOrder = [
  MapStyleId.dark,
  MapStyleId.night,
  MapStyleId.satellite,
  MapStyleId.streets,
  MapStyleId.terrain,
  MapStyleId.toner,
];

/// Convenience: resolve a style id to its definition. Throws [StateError]
/// for an unknown id (every member of [MapStyleId] is in [kMapStyles] so
/// this can only fire if someone adds an enum value without a catalog
/// entry — fail-loud is better than a silent fallback).
MapStyleDef styleDef(MapStyleId id) =>
    kMapStyles[id] ??
    (throw StateError('No MapStyleDef for $id — update kMapStyles.'));
