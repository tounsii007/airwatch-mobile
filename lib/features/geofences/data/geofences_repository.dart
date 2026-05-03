import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';

/// SharedPreferences-backed Riverpod store for the user's geofences.
///
/// <p>The web frontend persists fences via the backend's REST API;
/// mobile keeps them on-device under a simple JSON key. The schema
/// matches the REST payload so a future "sync to backend" step can
/// just iterate the local list and POST each entry.
class GeofencesNotifier extends Notifier<List<GeoFence>> {
  static const _key = 'geofences_v1';

  @override
  List<GeoFence> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => GeoFence.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {
      // Silent recovery — corrupt JSON resets the store rather than
      // crashing the app on startup.
      state = const [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void add(GeoFence f) {
    state = [...state, f];
    _save();
  }

  void remove(String id) {
    state = state.where((f) => f.id != id).toList();
    _save();
  }

  void toggleActive(String id) {
    state = state
        .map((f) => f.id == id ? f.copyWith(active: !f.active) : f)
        .toList();
    _save();
  }

  /// Replace the entire list — used by future "import from backend"
  /// flows. Persists immediately.
  void replace(List<GeoFence> next) {
    state = List.of(next);
    _save();
  }
}

final geofencesProvider = NotifierProvider<GeofencesNotifier, List<GeoFence>>(
  GeofencesNotifier.new,
);
