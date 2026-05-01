import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:airwatch_mobile/features/map/domain/turbulence/parse_sigmet.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/turbulence_provider.dart';

/// Translucent polygon layer for active SIGMET zones.
///
/// <p>Mirrors the web frontend's `useTurbulenceOverlay` hook — same
/// severity colour palette ({@link severityColor}), same opacity
/// stepping (light tint, stronger outline). Hidden when the toggle in
/// [showTurbulenceProvider] is off; auto-disposes its stream when the
/// map screen unmounts.
class TurbulenceOverlayLayer extends ConsumerWidget {
  const TurbulenceOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(showTurbulenceProvider);
    if (!enabled) return const SizedBox.shrink();
    final asyncZones = ref.watch(turbulenceZonesProvider);
    final zones = asyncZones.value ?? const <TurbulenceZone>[];
    if (zones.isEmpty) return const SizedBox.shrink();

    return PolygonLayer(
      polygons: [
        for (final z in zones)
          Polygon(
            points: [
              for (final p in z.polygon) LatLng(p[0], p[1]),
            ],
            color: severityColor(z.severity).withValues(alpha: 0.18),
            borderColor: severityColor(z.severity).withValues(alpha: 0.85),
            borderStrokeWidth: 1.4,
          ),
      ],
    );
  }
}
