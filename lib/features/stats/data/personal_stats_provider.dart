import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';

/// One row of the user's personal "viewed flights" history.
///
/// <p>Mirrors airwatch-web's `ViewedFlight` shape (lib/stores/statsStore.ts)
/// so a future cross-platform export reads identically on both sides.
class ViewedFlight {
  /// Stable identifier — ICAO24 hex address. Used both as map key for
  /// dedup and as the deep-link target for the flight detail screen.
  final String icao24;

  /// The callsign captured at view time (e.g. "DLH441"). Optional — some
  /// aircraft transmit a position without a callsign for several minutes
  /// after take-off.
  final String? callsign;

  /// Origin / destination IATA pair as known at view time. Mostly null
  /// for the first ticks of a flight; populated once Airlabs returns a
  /// schedule match.
  final String? originIata;
  final String? destIata;

  /// Resolved airline ICAO (first three chars of [callsign] when it
  /// matches the canonical pattern). Pre-computed at capture time so
  /// the metrics aggregators don't re-parse on every render.
  final String? airlineIcao;

  /// How many times this aircraft has been opened in the details panel.
  /// `recordView` increments this on each subsequent capture.
  final int views;

  /// First-seen / last-seen timestamps. Both are ISO-8601 in UTC for
  /// trivial cross-platform persistence + sort stability.
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  const ViewedFlight({
    required this.icao24,
    required this.callsign,
    required this.originIata,
    required this.destIata,
    required this.airlineIcao,
    required this.views,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  Map<String, dynamic> toJson() => {
    'icao24': icao24,
    'callsign': callsign,
    'originIata': originIata,
    'destIata': destIata,
    'airlineIcao': airlineIcao,
    'views': views,
    'firstSeenAt': firstSeenAt.toUtc().toIso8601String(),
    'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
  };

  static ViewedFlight? fromJson(Map<String, dynamic> j) {
    final icao = j['icao24'];
    if (icao is! String || icao.isEmpty) return null;
    return ViewedFlight(
      icao24: icao,
      callsign: j['callsign'] as String?,
      originIata: j['originIata'] as String?,
      destIata: j['destIata'] as String?,
      airlineIcao: j['airlineIcao'] as String?,
      views: (j['views'] as num?)?.toInt() ?? 1,
      firstSeenAt:
          DateTime.tryParse(j['firstSeenAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      lastSeenAt:
          DateTime.tryParse(j['lastSeenAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

/// Immutable bundle the UI watches. Splitting flight list from total
/// view count keeps the count cheap to compute (no re-scan) and avoids
/// a degenerate "every view bumps the list reference" rebuild storm.
class PersonalStatsState {
  final List<ViewedFlight> viewedFlights;
  final int totalViews;
  const PersonalStatsState({
    this.viewedFlights = const [],
    this.totalViews = 0,
  });
}

/// SharedPreferences key. Versioned so a future schema change can
/// migrate without losing history.
const _kPersistKey = 'stats.viewed_flights.v1';
const _kPersistTotalKey = 'stats.total_views.v1';
const _kMaxRows = 500; // matches the favorites cap on mobile

class PersonalStatsNotifier extends Notifier<PersonalStatsState> {
  @override
  PersonalStatsState build() {
    _load();
    return const PersonalStatsState();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kPersistKey);
    final total = p.getInt(_kPersistTotalKey) ?? 0;
    if (raw == null || raw.isEmpty) {
      state = PersonalStatsState(totalViews: total);
      return;
    }
    try {
      final list = jsonDecode(raw);
      if (list is! List) return;
      final flights = <ViewedFlight>[];
      for (final entry in list) {
        if (entry is Map) {
          final vf = ViewedFlight.fromJson(Map<String, dynamic>.from(entry));
          if (vf != null) flights.add(vf);
        }
      }
      state = PersonalStatsState(viewedFlights: flights, totalViews: total);
    } catch (_) {
      // Corrupt blob — start fresh so the user never sees a permanently
      // broken stats page. The on-disk copy gets overwritten on the
      // next recordView call.
    }
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    final payload = state.viewedFlights
        .map((vf) => vf.toJson())
        .toList(growable: false);
    await p.setString(_kPersistKey, jsonEncode(payload));
    await p.setInt(_kPersistTotalKey, state.totalViews);
  }

  /// Capture an aircraft selection. Bumps the views count on existing
  /// rows, otherwise inserts a fresh entry. Enforces a hard cap so the
  /// JSON blob never grows without bound — oldest non-current rows go
  /// first.
  void recordView(AircraftState aircraft) {
    final now = DateTime.now().toUtc();
    final icao24 = aircraft.icao24;
    if (icao24.isEmpty) return;

    final callsign = aircraft.callsign?.trim();
    final airline =
        (callsign != null &&
            callsign.length >= 3 &&
            RegExp(r'^[A-Z]{3}').hasMatch(callsign.toUpperCase()))
        ? callsign.substring(0, 3).toUpperCase()
        : null;

    final existing = state.viewedFlights;
    final idx = existing.indexWhere((v) => v.icao24 == icao24);
    final updated = List<ViewedFlight>.of(existing);

    if (idx >= 0) {
      final prev = updated.removeAt(idx);
      // Keep the originally captured first-seen so the "tracking since"
      // metric stays stable across views.
      updated.insert(
        0,
        ViewedFlight(
          icao24: icao24,
          callsign: callsign?.isNotEmpty == true ? callsign : prev.callsign,
          originIata: prev.originIata,
          destIata: prev.destIata,
          airlineIcao: prev.airlineIcao ?? airline,
          views: prev.views + 1,
          firstSeenAt: prev.firstSeenAt,
          lastSeenAt: now,
        ),
      );
    } else {
      updated.insert(
        0,
        ViewedFlight(
          icao24: icao24,
          callsign: callsign,
          originIata: null,
          destIata: null,
          airlineIcao: airline,
          views: 1,
          firstSeenAt: now,
          lastSeenAt: now,
        ),
      );
      // Trim from the tail — drop the OLDEST rows when over the cap.
      // Same rule as the favorites store: keep recency, sacrifice age.
      if (updated.length > _kMaxRows) {
        updated.removeRange(_kMaxRows, updated.length);
      }
    }

    state = PersonalStatsState(
      viewedFlights: updated,
      totalViews: state.totalViews + 1,
    );
    _persist();
  }

  /// Augment an existing row with route info (origin / dest IATA) once
  /// the airport-resolution comes back. Called from the flight-details
  /// loader after Airlabs returns a schedule match. No-op if the row
  /// has been pruned by the cap or the user has already cleared stats.
  void enrichRoute({
    required String icao24,
    String? originIata,
    String? destIata,
  }) {
    final existing = state.viewedFlights;
    final idx = existing.indexWhere((v) => v.icao24 == icao24);
    if (idx < 0) return;
    final prev = existing[idx];
    // Skip the persist hop when nothing actually changes — common case
    // on a re-render of the same flight.
    if (prev.originIata == originIata && prev.destIata == destIata) return;
    final updated = List<ViewedFlight>.of(existing);
    updated[idx] = ViewedFlight(
      icao24: prev.icao24,
      callsign: prev.callsign,
      originIata: originIata ?? prev.originIata,
      destIata: destIata ?? prev.destIata,
      airlineIcao: prev.airlineIcao,
      views: prev.views,
      firstSeenAt: prev.firstSeenAt,
      lastSeenAt: prev.lastSeenAt,
    );
    state = PersonalStatsState(
      viewedFlights: updated,
      totalViews: state.totalViews,
    );
    _persist();
  }

  /// Nuke the entire history. Used by the "Clear history" button on
  /// the stats screen.
  void clear() {
    state = const PersonalStatsState();
    _persist();
  }
}

final personalStatsProvider =
    NotifierProvider<PersonalStatsNotifier, PersonalStatsState>(
      PersonalStatsNotifier.new,
    );
