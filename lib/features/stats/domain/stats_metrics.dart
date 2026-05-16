import 'package:airwatch_mobile/features/stats/data/personal_stats_provider.dart';

/// Pure aggregators for the personal-stats screen. Mirrors airwatch-web's
/// `statsMetrics.ts` (commit 1e24147) — same shapes, same sort, same
/// breakpoints. Kept in `domain/` so it has no Flutter dependency and
/// can be unit-tested at function level.

class CountEntry {
  final String key;
  final int count;
  const CountEntry(this.key, this.count);
}

/// Top airline ICAOs by view count. Drops empty / null airline codes.
List<CountEntry> topAirlines(List<ViewedFlight> flights, {int limit = 5}) {
  final counts = <String, int>{};
  for (final f in flights) {
    final a = f.airlineIcao;
    if (a == null || a.isEmpty) continue;
    counts[a] = (counts[a] ?? 0) + f.views;
  }
  final entries = counts.entries.map((e) => CountEntry(e.key, e.value)).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return entries.take(limit).toList(growable: false);
}

/// Top routes — "ORIG → DEST" pair by view count. Drops rows with
/// either side missing so a partial Airlabs response doesn't pollute
/// the chart with "??? → FRA" rows.
List<CountEntry> topRoutes(List<ViewedFlight> flights, {int limit = 5}) {
  final counts = <String, int>{};
  for (final f in flights) {
    final o = f.originIata;
    final d = f.destIata;
    if (o == null || d == null || o.isEmpty || d.isEmpty) continue;
    final key = '$o → $d';
    counts[key] = (counts[key] ?? 0) + f.views;
  }
  final entries = counts.entries.map((e) => CountEntry(e.key, e.value)).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return entries.take(limit).toList(growable: false);
}

/// Top airports — counts an airport once per row whether it shows up as
/// origin or destination. Self-loops (origin == dest) are de-duped so a
/// single flight doesn't double its home airport.
List<CountEntry> topAirports(List<ViewedFlight> flights, {int limit = 5}) {
  final counts = <String, int>{};
  for (final f in flights) {
    final seen = <String>{};
    final o = f.originIata;
    final d = f.destIata;
    if (o != null && o.isNotEmpty) seen.add(o);
    if (d != null && d.isNotEmpty) seen.add(d);
    for (final ap in seen) {
      counts[ap] = (counts[ap] ?? 0) + f.views;
    }
  }
  final entries = counts.entries.map((e) => CountEntry(e.key, e.value)).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return entries.take(limit).toList(growable: false);
}

/// Distinct airline count — drops null / empty.
int countUniqueAirlines(List<ViewedFlight> flights) {
  final seen = <String>{};
  for (final f in flights) {
    final a = f.airlineIcao;
    if (a != null && a.isNotEmpty) seen.add(a);
  }
  return seen.length;
}

/// Distinct airport count — origin + destination, drops null / empty.
int countUniqueAirports(List<ViewedFlight> flights) {
  final seen = <String>{};
  for (final f in flights) {
    final o = f.originIata;
    final d = f.destIata;
    if (o != null && o.isNotEmpty) seen.add(o);
    if (d != null && d.isNotEmpty) seen.add(d);
  }
  return seen.length;
}

/// 24 hourly buckets — `viewsByHour[i]` = how many [ViewedFlight.lastSeenAt]
/// values fall in `[i:00, i+1:00)` LOCAL TIME. The chart wants
/// time-of-day in the user's locale, not UTC, so a flight viewed at
/// 14:32 CEST lands in bucket 14 regardless of where the user lives.
List<int> viewsByHour(List<ViewedFlight> flights) {
  final buckets = List<int>.filled(24, 0);
  for (final f in flights) {
    final local = f.lastSeenAt.toLocal();
    buckets[local.hour] += 1;
  }
  return buckets;
}

class ActivitySummary {
  /// First [ViewedFlight.firstSeenAt] across the dataset. Null when no
  /// flights have been recorded yet.
  final DateTime? trackingSince;

  /// Span in days between [trackingSince] and now. 0 for a single-day
  /// dataset (a row recorded today only).
  final int daysActive;

  /// 0-23 hour-of-day with the highest count. Null when no data.
  final int? peakHour;
  final int peakHourCount;

  const ActivitySummary({
    this.trackingSince,
    this.daysActive = 0,
    this.peakHour,
    this.peakHourCount = 0,
  });
}

ActivitySummary activitySummary(List<ViewedFlight> flights) {
  if (flights.isEmpty) return const ActivitySummary();

  DateTime since = flights.first.firstSeenAt;
  for (final f in flights) {
    if (f.firstSeenAt.isBefore(since)) since = f.firstSeenAt;
  }
  final daysActive = DateTime.now().toUtc().difference(since).inDays;

  final buckets = viewsByHour(flights);
  int peakHour = 0;
  int peakCount = 0;
  for (var i = 0; i < buckets.length; i++) {
    if (buckets[i] > peakCount) {
      peakCount = buckets[i];
      peakHour = i;
    }
  }

  return ActivitySummary(
    trackingSince: since,
    daysActive: daysActive < 0 ? 0 : daysActive,
    peakHour: peakCount == 0 ? null : peakHour,
    peakHourCount: peakCount,
  );
}
