import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:airwatch_mobile/core/constants/airport_full_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/airport/presentation/screens/airport_detail_screen.dart';

/// Tiered airport coverage. Each tier governs the minimum zoom at which
/// the airport's IATA-coded label appears on the map.
///
/// <p>Tier choice rules (mirrored from the web frontend's
/// `useAirportLabels.ts`):
/// <ul>
///   <li>tier 1 (zoom ≥ 4) — global hubs PLUS at least one capital-level
///       airport per major country. Visible from continent view.</li>
///   <li>tier 2 (zoom ≥ 6) — second-tier nationals; together with tier 1
///       this gives "≥ 3 per country" for North Africa + Middle East and
///       "≥ 1 per country" everywhere in Asia / Sub-Saharan Africa.</li>
///   <li>full database (zoom ≥ 8) — every airport in
///       [airportFullDatabase] that's inside the viewport.</li>
/// </ul>
///
/// <p>Coordinates are NOT hard-coded here. The IATA code resolves through
/// [lookupAirportByIata] (the 21k-row generated dataset) at first
/// render — same source the web frontend uses, so adding a code in either
/// project doesn't drift the platforms apart.
const Set<String> _tier1Hubs = {
  // ─── Europe ─────────────────────────────────────────────────────────────
  'LHR', 'CDG', 'FRA', 'AMS', 'IST', 'MAD', 'BCN', 'FCO', 'MUC', 'ZRH',
  'VIE', 'CPH', 'OSL', 'ARN', 'HEL', 'WAW', 'PRG', 'BRU', 'DUB', 'ATH',
  'LIS', 'MXP', 'BER',

  // ─── Middle East — capital-level per country ────────────────────────────
  'DXB', 'AUH',                      // UAE
  'DOH',                              // Qatar
  'JED', 'RUH',                      // Saudi Arabia
  'TLV',                              // Israel
  'IKA', 'THR',                      // Iran
  'BGW',                              // Iraq
  'KWI',                              // Kuwait
  'BAH',                              // Bahrain
  'MCT',                              // Oman
  'SAH',                              // Yemen
  'AMM',                              // Jordan
  'BEY',                              // Lebanon
  'DAM',                              // Syria
  'LCA',                              // Cyprus

  // ─── North Africa — capital + major hub ─────────────────────────────────
  'CAI', 'HRG',                      // Egypt
  'CMN', 'RAK',                      // Morocco
  'ALG',                              // Algeria
  'TUN',                              // Tunisia
  'TIP',                              // Libya

  // ─── Sub-Saharan Africa — country capitals ──────────────────────────────
  'JNB', 'CPT',                      // South Africa
  'NBO',                              // Kenya
  'ADD',                              // Ethiopia
  'LOS', 'ABV',                      // Nigeria
  'ACC',                              // Ghana
  'DKR',                              // Senegal
  'ABJ',                              // Ivory Coast
  'DAR',                              // Tanzania
  'EBB',                              // Uganda
  'KGL',                              // Rwanda
  'LAD',                              // Angola
  'KRT',                              // Sudan
  'FIH',                              // DR Congo
  'MRU',                              // Mauritius
  'TNR',                              // Madagascar

  // ─── Asia — country-level capitals ──────────────────────────────────────
  'HND', 'NRT',                      // Japan
  'PEK', 'PVG',                      // China
  'HKG',                              // Hong Kong
  'TPE',                              // Taiwan
  'ICN',                              // South Korea
  'SIN',                              // Singapore
  'KUL',                              // Malaysia
  'BKK',                              // Thailand
  'CGK',                              // Indonesia
  'MNL',                              // Philippines
  'HAN', 'SGN',                      // Vietnam
  'PNH',                              // Cambodia
  'VTE',                              // Laos
  'RGN',                              // Myanmar
  'DEL', 'BOM',                      // India
  'DAC',                              // Bangladesh
  'KTM',                              // Nepal
  'CMB',                              // Sri Lanka
  'MLE',                              // Maldives
  'KHI', 'ISB', 'LHE',               // Pakistan
  'KBL',                              // Afghanistan
  'TAS',                              // Uzbekistan
  'ALA', 'NQZ',                      // Kazakhstan
  'GYD',                              // Azerbaijan
  'EVN',                              // Armenia
  'TBS',                              // Georgia
  'UBN',                              // Mongolia

  // ─── North America — country / state capital coverage ──────────────────
  'JFK', 'LAX', 'ORD', 'ATL', 'DFW', 'DEN', 'SFO', 'MIA',
  'ANC',                              // Alaska
  // Canada
  'YYZ', 'YUL', 'YVR', 'YYC',
  'YOW', 'YEG', 'YHZ', 'YWG',
  'YQB', 'YZF', 'YFB',
  // Greenland
  'GOH', 'SFJ', 'JAV', 'THU',
  // Mexico
  'MEX', 'GDL', 'MTY', 'CUN',
  'TIJ',

  // ─── Caribbean & Central America — capitals ────────────────────────────
  'HAV',                              // Cuba
  'SJU',                              // Puerto Rico
  'SDQ',                              // Dominican Republic
  'KIN',                              // Jamaica
  'NAS',                              // Bahamas
  'GUA',                              // Guatemala
  'SAL',                              // El Salvador
  'TGU',                              // Honduras
  'MGA',                              // Nicaragua
  'SJO',                              // Costa Rica
  'PTY',                              // Panama

  // ─── South America — capital + major hub per country ───────────────────
  'GRU', 'GIG', 'BSB',
  'EZE', 'AEP',
  'SCL',
  'LIM',
  'BOG',
  'CCS',
  'UIO', 'GYE',
  'VVI', 'LPB',
  'ASU',
  'MVD',
  'PBM',
  'GEO',
  'CAY',

  // ─── Russia — Moscow + far-east + regional spread ──────────────────────
  'SVO', 'DME', 'VKO',
  'LED',
  'KZN',
  'AER',
  'SVX',
  'OVB',
  'IKT',
  'VVO', 'KHV',
  'PKC',
  'UFA',

  // ─── Oceania ───────────────────────────────────────────────────────────
  'SYD', 'MEL', 'AKL',
};

const Set<String> _tier2Regionals = {
  // ─── Europe — secondary hubs ────────────────────────────────────────────
  'LGW', 'ORY', 'DUS', 'HAM', 'STR', 'CGN', 'NUE', 'HAJ', 'LEJ',
  'NCE', 'LYS', 'MRS', 'TLS', 'BOD',
  'BGY', 'NAP', 'VCE', 'BLQ',
  'GVA', 'BSL', 'PMI', 'AGP', 'IBZ', 'TFS', 'LPA',
  'EDI', 'MAN', 'BHX',
  'OPO', 'FAO', 'SKG', 'SOF', 'OTP', 'BUD', 'KRK', 'BEG', 'ZAG',
  'SAW', 'AYT', 'ADB', 'ESB',
  'RIX', 'VNO', 'TLL',

  // ─── Middle East — second + third hubs per country ─────────────────────
  'SHJ', 'RKT',
  'DMM', 'MED',
  'ETM', 'HFA',
  'MHD', 'SYZ', 'ISF',
  'BSR', 'EBL',
  'SLL',
  'ADE',
  'AQJ',
  'ALP', 'LTK',
  'PFO',

  // ─── North Africa — second + third hubs per country ────────────────────
  'SSH', 'LXR', 'ASW',
  'AGA', 'FEZ', 'RBA', 'TNG',
  'ORN', 'CZL',
  'NBE', 'MIR', 'DJE',
  'BEN', 'MJI',

  // ─── Sub-Saharan Africa — at least one per country ─────────────────────
  'JRO', 'ZNZ',
  'MBA',
  'DSS',
  'DLA', 'NSI',
  'VFA', 'HRE',
  'GBE',
  'WDH',
  'MPM',
  'LUN',
  'BZV',
  'LBV',
  'SSG',
  'JUB',
  'ASM',
  'JIB',
  'MGQ',
  'BKO',
  'OUA',
  'NIM',
  'NDJ',
  'ROB',
  'FNA',
  'CKY',
  'NKC',
  'COO',
  'LFW',
  'RAI',
  'SEZ',

  // ─── Asia — secondary regionals ─────────────────────────────────────────
  'KIX', 'NGO', 'FUK',
  'SHA', 'SZX', 'CTU', 'CKG',
  'GMP',
  'CEB', 'DVO',
  'SUB', 'UPG',
  'DAD',
  'REP',
  'MDL',
  'CGP',
  'PBH',
  'BLR', 'MAA', 'HYD', 'CCU',
  'BWN',
  'ASB',
  'DYU',
  'FRU',

  // ─── USA — additional regional hubs ─────────────────────────────────────
  'EWR', 'IAH', 'SEA', 'BOS', 'CLT', 'MSP', 'DTW', 'MCO', 'LAS', 'PHX',
  'PHL', 'BWI', 'DCA', 'IAD', 'TPA', 'FLL', 'SLC', 'SAN', 'PDX', 'MCI',
  'BNA', 'AUS', 'STL', 'PIT', 'IND', 'CMH', 'CLE', 'MEM',
  'FAI', 'JNU',

  // ─── Canada — secondary cities ──────────────────────────────────────────
  'YQR', 'YXE', 'YYJ', 'YXX', 'YHM',
  'YQM', 'YYT', 'YQT', 'YXY',

  // ─── Greenland & Arctic — small fields kept at tier-2 ──────────────────
  'JEG', 'UAK',

  // ─── Mexico — touristic + regional ─────────────────────────────────────
  'PVR', 'SJD', 'MID', 'OAX', 'BJX', 'CJS', 'CUL',

  // ─── Caribbean & Central America — second hubs ─────────────────────────
  'POP',
  'MBJ',
  'AUA',
  'CUR',
  'BGI',
  'POS',
  'BZE',
  'GCM',

  // ─── South America — secondaries per country ───────────────────────────
  'CNF', 'SSA', 'REC', 'FOR', 'POA', 'CWB', 'MAO', 'VCP', 'BEL',
  'COR', 'MDZ', 'BRC', 'USH',
  'ARI', 'IPC', 'PMC', 'CCP',
  'CUZ', 'AQP', 'IQT',
  'MDE', 'CTG', 'CLO', 'BAQ',
  'MAR', 'VLN',
  'CUE',
  'CIJ',
  'AXM', 'PEI',

  // ─── Russia — wider regional coverage ──────────────────────────────────
  'KUF',
  'ROV', 'KRR',
  'MRV',
  'KJA',
  'BAX',
  'OMS',
  'TJM',
  'SGC',
  'YKS',
  'GDX',
  'UUS',
  'MMK',
  'ARH',
  'KGD',
  'VOG',
  'CEK',
  'PEE',
  'NJC',

  // ─── Oceania ───────────────────────────────────────────────────────────
  'BNE', 'PER', 'ADL', 'OOL', 'CNS',
  'ZQN', 'CHC', 'WLG',
  'NOU',
  'PPT',
  'NAN', 'SUV',
  'APW',
  'TBU',
  'POM',
};

/// Pre-resolved entry: IATA + lat/lon + tier threshold. Building this
/// requires a database lookup per code, so it's cached after the first
/// call (the database itself is `const` so the cache never invalidates).
class _AptEntry {
  final String iata;
  final double lat;
  final double lon;
  final double minZoom;
  const _AptEntry(this.iata, this.lat, this.lon, this.minZoom);
}

List<_AptEntry>? _curatedCache;

/// Returns tier-1 + tier-2 entries pre-sorted by their minZoom (ascending),
/// so tier-1 hubs are processed BEFORE tier-2 in the per-zoom cap. With a
/// flat list and a hard cap, dense regions like Europe could starve out
/// tier-1 capitals in less-saturated regions like the Middle East — the
/// sort fixes that.
List<_AptEntry> _curated() {
  final cached = _curatedCache;
  if (cached != null) return cached;

  final entries = <_AptEntry>[];
  for (final iata in _tier1Hubs) {
    final apt = lookupAirportByIata(iata);
    if (apt == null) continue;
    entries.add(_AptEntry(iata, apt.lat, apt.lon, 4));
  }
  for (final iata in _tier2Regionals) {
    final apt = lookupAirportByIata(iata);
    if (apt == null) continue;
    entries.add(_AptEntry(iata, apt.lat, apt.lon, 6));
  }
  // Stable sort by tier (ascending). Within a tier, insertion order wins.
  entries.sort((a, b) => a.minZoom.compareTo(b.minZoom));

  _curatedCache = entries;
  return entries;
}

/// World-airport markers. Tier 1 hubs at zoom 4+, tier 2 regionals at 6+,
/// the full 21k-airport database at 8+. Every render path goes through
/// the same per-zoom cap so dense regions don't choke the layout.
class AirportMarkersLayer extends StatelessWidget {
  final double zoom;
  const AirportMarkersLayer({super.key, required this.zoom});

  @override
  Widget build(BuildContext context) {
    if (zoom < 4) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final camera = MapCamera.maybeOf(context);
    if (camera == null) return const SizedBox.shrink();

    // Pad the bounds by 10 % of the visible span so airports JUST outside
    // the viewport still get rendered. Without this, a city like Tunis
    // (TUN) at the very-top of a Tunisia-centric pan can have its dot
    // rendered while the label gets clipped — or vice versa, the dot is
    // offscreen but the label that would extend INTO the screen never
    // gets a chance to render because the dot's lat/lon failed the
    // strict inside-bounds test. Mirrors the web `useAirportLabels`
    // padding behaviour added in the same-origin-proxy commit.
    final raw = camera.visibleBounds;
    final latPad = (raw.north - raw.south) * 0.10;
    final lonPad = (raw.east - raw.west) * 0.10;
    final south = raw.south - latPad;
    final north = raw.north + latPad;
    final west = raw.west - lonPad;
    final east = raw.east + lonPad;

    // Cap labels per zoom tier so dense regions don't choke the layout.
    // Numbers tuned empirically on a 6.7" screen at zoom 4–10:
    //   * zoom < 7   → 100  (tier-1 only — gives head-room on continent
    //                       view without flooding Europe)
    //   * zoom < 9   → 180  (tier-1 + most of tier-2)
    //   * zoom ≥ 9   → 280  (full near-zoom city detail)
    final maxLabels = zoom < 7 ? 100 : (zoom < 9 ? 180 : 280);

    // Build the working set:
    //   * zoom < 8: pre-sorted tier-1 + tier-2 only (curated)
    //   * zoom ≥ 8: every airport from the full 21k-row database
    //     intersecting the padded viewport. Use ICAO as the unique key
    //     so tier-1/2 entries don't double-render with full-DB entries.
    final List<_AptEntry> source;
    if (zoom < 8) {
      source = _curated();
    } else {
      final seen = <String>{};
      final fullList = <_AptEntry>[];
      // Tier-1 first, then tier-2, then everything else — ensures the cap
      // never starves the high-priority sets at high zoom too.
      for (final entry in _curated()) {
        seen.add(entry.iata);
        fullList.add(entry);
      }
      for (final apt in airportFullDatabase.values) {
        if (apt.iata.isEmpty || seen.contains(apt.iata)) continue;
        if (apt.lat < south || apt.lat > north) continue;
        if (apt.lon < west || apt.lon > east) continue;
        fullList.add(_AptEntry(apt.iata, apt.lat, apt.lon, 8));
      }
      source = fullList;
    }

    final showLabel = zoom >= 6;
    final dotSize = zoom < 5 ? 5.0 : 7.0;

    void openAirport(BuildContext ctx, String iata) {
      Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => AirportDetailScreen(iataCode: iata),
      ));
    }

    final markers = <Marker>[];
    for (final entry in source) {
      if (markers.length >= maxLabels) break;
      if (zoom < entry.minZoom) continue;
      // Bounds + padding test (the curated path skipped this step;
      // doing it here keeps the high-zoom branch's check uniform).
      if (entry.lat < south || entry.lat > north) continue;
      if (entry.lon < west || entry.lon > east) continue;

      markers.add(
        Marker(
          point: LatLng(entry.lat, entry.lon),
          width: showLabel ? 80 : dotSize * 2 + 4,
          height: showLabel ? 22 : dotSize * 2 + 4,
          child: GestureDetector(
            onTap: () => openAirport(context, entry.iata),
            child: showLabel
                ? _Lbl(iata: entry.iata, isDark: isDark)
                : _Dot(size: dotSize, isDark: isDark),
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final bool isDark;
  const _Dot({required this.size, required this.isDark});
  @override
  Widget build(BuildContext context) {
    const c = UiConstants.lightPrimary;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: 0.8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: c.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 4)],
        ),
      ),
    );
  }
}

class _Lbl extends StatelessWidget {
  final String iata;
  final bool isDark;
  const _Lbl({required this.iata, required this.isDark});
  @override
  Widget build(BuildContext context) {
    const c = UiConstants.lightPrimary;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.withValues(alpha: 0.4), width: 0.5),
          boxShadow: isDark
              ? [BoxShadow(color: c.withValues(alpha: 0.2), blurRadius: 4)]
              : [],
        ),
        child: Text(
          iata,
          style: const TextStyle(
            fontFamily: UiConstants.headingFont,
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: c,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
