import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/conversion_constants.dart';
import 'package:airwatch_mobile/features/search/data/services/search_service.dart';
import '../../data/datasources/airlabs_flights_datasource.dart';
import '../../data/models/aircraft_state.dart';
import '../widgets/map_styles.dart';

final airlabsFlightsDatasourceProvider = Provider<AirlabsFlightsDatasource>((ref) {
  final ds = AirlabsFlightsDatasource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

// --- Simple state providers using Notifier ---

enum AltitudeFilter { all, low, medium, high, ground }
enum CategoryFilter { all, jets, helicopters, cargo, light, ground }

// Altitude filter
class AltitudeFilterNotifier extends Notifier<AltitudeFilter> {
  @override
  AltitudeFilter build() => AltitudeFilter.all;
  void set(AltitudeFilter value) => state = value;
}

final altitudeFilterProvider =
    NotifierProvider<AltitudeFilterNotifier, AltitudeFilter>(
        AltitudeFilterNotifier.new);

// Category filter
class CategoryFilterNotifier extends Notifier<CategoryFilter> {
  @override
  CategoryFilter build() => CategoryFilter.all;
  void set(CategoryFilter value) => state = value;
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, CategoryFilter>(
        CategoryFilterNotifier.new);

// Selected aircraft
class SelectedAircraftNotifier extends Notifier<AircraftState?> {
  @override
  AircraftState? build() => null;
  void set(AircraftState? value) => state = value;
}

final selectedAircraftProvider =
    NotifierProvider<SelectedAircraftNotifier, AircraftState?>(
        SelectedAircraftNotifier.new);

// Map center
class MapCenterNotifier extends Notifier<LatLng> {
  @override
  LatLng build() => const LatLng(AppConfig.defaultLat, AppConfig.defaultLon);
  void set(LatLng value) => state = value;
}

final mapCenterProvider =
    NotifierProvider<MapCenterNotifier, LatLng>(MapCenterNotifier.new);

// Map zoom
class MapZoomNotifier extends Notifier<double> {
  @override
  double build() => AppConfig.defaultZoom;
  void set(double value) => state = value;
}

final mapZoomProvider =
    NotifierProvider<MapZoomNotifier, double>(MapZoomNotifier.new);

// Map bounds
class MapBounds {
  final double south, north, west, east;
  MapBounds(
      {required this.south,
      required this.north,
      required this.west,
      required this.east});
}

class MapBoundsNotifier extends Notifier<MapBounds?> {
  @override
  MapBounds? build() => null;
  void set(MapBounds? value) => state = value;
}

final mapBoundsProvider =
    NotifierProvider<MapBoundsNotifier, MapBounds?>(MapBoundsNotifier.new);

// --- Real-time aircraft stream (Airlabs — 5 min interval) ---
final aircraftStreamProvider =
    StreamProvider<Map<String, AircraftState>>((ref) {
  final ds = ref.watch(airlabsFlightsDatasourceProvider);
  ds.startPolling();
  ref.onDispose(() => ds.stopPolling());

  // Convert List stream to Map<icao24, AircraftState>
  // Also update session cache for offline search
  return ds.stateStream.map((list) {
    final map = <String, AircraftState>{};
    for (final ac in list) {
      if (ac.icao24.isNotEmpty) {
        map[ac.icao24] = ac;
      }
    }
    SearchService.updateSeenAircraft(map);
    return map;
  });
});

// Filtered aircraft based on altitude + category
final filteredAircraftProvider =
    Provider<Map<String, AircraftState>>((ref) {
  final aircraftAsync = ref.watch(aircraftStreamProvider);
  final altFilter = ref.watch(altitudeFilterProvider);
  final catFilter = ref.watch(categoryFilterProvider);
  // Voice-driven cargo-only filter — orthogonal to the existing
  // category dropdown. When on, it restricts the result to flights
  // whose airline ICAO is on the cargo carrier list.
  final cargoOnly = ref.watch(showCargoOnlyProvider);

  return aircraftAsync.when(
    data: (aircraft) {
      if (altFilter == AltitudeFilter.all &&
          catFilter == CategoryFilter.all &&
          !cargoOnly) {
        return aircraft;
      }

      return Map.fromEntries(aircraft.entries.where((entry) {
        final a = entry.value;
        // Cargo-only filter — orthogonal to the category dropdown.
        if (cargoOnly) {
          final cs = (a.callsign ?? '').toUpperCase().trim();
          if (cs.length < 3) return false;
          if (!_cargoCallsignPrefixes.contains(cs.substring(0, 3))) {
            return false;
          }
        }

        // Altitude filter
        if (altFilter != AltitudeFilter.all) {
          if (altFilter == AltitudeFilter.ground) {
            if (!a.onGround) return false;
          } else {
            final alt = a.altitude;
            if (alt == null) return false;
            final feet = alt * ConversionConstants.metersToFeet;
            final pass = switch (altFilter) {
              AltitudeFilter.low => feet < AppConfig.altitudeLowMax,
              AltitudeFilter.medium => feet >= AppConfig.altitudeLowMax && feet < AppConfig.altitudeMedMax,
              AltitudeFilter.high => feet >= AppConfig.altitudeMedMax,
              _ => true,
            };
            if (!pass) return false;
          }
        }

        // Category filter
        if (catFilter != CategoryFilter.all) {
          final pass = switch (catFilter) {
            CategoryFilter.helicopters => a.category == 8,
            CategoryFilter.cargo => a.category == 6,
            CategoryFilter.light => a.category == 2 || a.category == 9,
            CategoryFilter.jets => a.category >= 4 && a.category <= 7 && a.category != 6,
            CategoryFilter.ground => a.onGround,
            _ => true,
          };
          if (!pass) return false;
        }

        return true;
      }));
    },
    loading: () => {},
    error: (_, _) => {},
  );
});

// Aircraft count
final aircraftCountProvider = Provider<int>((ref) {
  return ref.watch(filteredAircraftProvider).length;
});

// Search query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Search results — search directly from aircraft stream
final searchResultsProvider = Provider<List<AircraftState>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final q = query.toLowerCase();

  final aircraftAsync = ref.watch(aircraftStreamProvider);
  return aircraftAsync.when(
    data: (aircraft) => aircraft.values.where((a) {
      return (a.callsign?.toLowerCase().contains(q) ?? false) ||
          a.icao24.toLowerCase().contains(q) ||
          (a.originCountry?.toLowerCase().contains(q) ?? false);
    }).take(50).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// Toggle states
class BoolNotifier extends Notifier<bool> {
  final bool _initial;
  BoolNotifier(this._initial);
  @override
  bool build() => _initial;
  void set(bool value) => state = value;
  void toggle() => state = !state;
}

final isTrackingFlightProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));
final showTrailsProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));
final showHeatmapProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(false));
final showRadarProvider =
    NotifierProvider<BoolNotifier, bool>(() => BoolNotifier(true));

// Map focus trigger — set when a flight is selected from outside the map
// (search screen, airport schedule, favorites) to pan + zoom to the aircraft.
class MapFocusTrigger {
  final LatLng position;
  final double zoom;
  const MapFocusTrigger(this.position, {this.zoom = 10.0});
}

class MapFocusNotifier extends Notifier<MapFocusTrigger?> {
  @override
  MapFocusTrigger? build() => null;

  void focusOn(LatLng position, {double zoom = 10.0}) =>
      state = MapFocusTrigger(position, zoom: zoom);

  void clear() => state = null;
}

final mapFocusProvider =
    NotifierProvider<MapFocusNotifier, MapFocusTrigger?>(MapFocusNotifier.new);

// ── Cargo-airline ICAO callsign prefixes (for showCargoOnlyProvider) ─────
//
// Mirrors the web frontend's `cargoFilter.ts` list. A flight is treated
// as cargo when its callsign's leading 3 chars match this set. Kept in
// sync with `cargo_filter.dart` in the cargo feature so both screens
// agree on what counts as cargo.
const Set<String> _cargoCallsignPrefixes = {
  'FDX', 'UPS', 'GTI', 'GEC', 'CLX', 'BOX', 'ABX', 'TAY', 'NPT', 'WGN',
  'ATG', 'SQC', 'ADB', 'CKS', 'AEC', 'GMI', 'FPO', 'TGX', 'KFS', 'MSC',
  'DHK', 'DHL', 'CKK', 'CAO', 'NCA', 'ABW',
};

// ── Voice-driven map zoom ─────────────────────────────────────────────────
//
// The map's actual zoom level lives on flutter_map's `MapController` which
// isn't a Riverpod object. To let the voice command pipeline drive zoom,
// we expose an integer "tick" that the MapScreen watches: each increment
// means "zoom in once", each decrement means "zoom out once". Voice
// dispatch flips the tick and the screen reads it via `ref.listen`.
class MapZoomCommandNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void zoomIn() => state = state + 1;
  void zoomOut() => state = state - 1;
}

final mapZoomCommandProvider =
    NotifierProvider<MapZoomCommandNotifier, int>(MapZoomCommandNotifier.new);

// ── Cargo-only map filter ─────────────────────────────────────────────────
//
// Toggled by either the voice command ("cargo" / "fracht" / "fret") OR
// the Cargo-only chip on the altitude-filter strip. Persisted in
// SharedPreferences so the filter state survives an app restart —
// matches the web frontend's behaviour where the cargo filter lives in
// the settings store.
class CargoOnlyNotifier extends Notifier<bool> {
  static const _key = 'show_cargo_only_v1';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> _save(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  void set(bool value) {
    state = value;
    _save(value);
  }

  void toggle() => set(!state);
}

final showCargoOnlyProvider =
    NotifierProvider<CargoOnlyNotifier, bool>(CargoOnlyNotifier.new);

// ── Basemap style ──────────────────────────────────────────────────────────
//
// Mirrors the web frontend's MapStylePicker state. Defaults to [dark] which
// matches the app's neon aesthetic — the user can switch via the picker on
// the map controls strip.
class MapStyleNotifier extends Notifier<MapStyleId> {
  @override
  MapStyleId build() => MapStyleId.dark;
  void set(MapStyleId value) => state = value;
}

final mapStyleProvider =
    NotifierProvider<MapStyleNotifier, MapStyleId>(MapStyleNotifier.new);
