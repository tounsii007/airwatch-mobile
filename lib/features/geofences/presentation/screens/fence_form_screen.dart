import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';

/// Form for creating a new geofence (circle or rectangle).
///
/// <p>Mirrors the web frontend's `FenceForm.tsx` validation contract
/// (in `fencePayload.ts`):
/// <ul>
///   <li>Name required.</li>
///   <li>Lat in [-90, 90], lon in [-180, 180].</li>
///   <li>Radius > 0 km for circles.</li>
///   <li>For rectangles: north > south, east > west.</li>
///   <li>Optional altitude band + airline filter.</li>
/// </ul>
class FenceFormScreen extends ConsumerStatefulWidget {
  const FenceFormScreen({super.key});

  @override
  ConsumerState<FenceFormScreen> createState() => _FenceFormScreenState();
}

class _FenceFormScreenState extends ConsumerState<FenceFormScreen> {
  GeoFenceType _type = GeoFenceType.circle;
  final _name = TextEditingController();
  final _centerLat = TextEditingController();
  final _centerLon = TextEditingController();
  final _radius = TextEditingController(text: '50');
  final _north = TextEditingController();
  final _south = TextEditingController();
  final _east = TextEditingController();
  final _west = TextEditingController();
  final _minAlt = TextEditingController();
  final _maxAlt = TextEditingController();
  final _airline = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _centerLat.dispose();
    _centerLon.dispose();
    _radius.dispose();
    _north.dispose();
    _south.dispose();
    _east.dispose();
    _west.dispose();
    _minAlt.dispose();
    _maxAlt.dispose();
    _airline.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name required');
      return;
    }
    final result = _type == GeoFenceType.circle ? _buildCircle(name) : _buildRect(name);
    if (result is _Err) {
      setState(() => _error = result.message);
      return;
    }
    final fence = (result as _Ok).fence;
    ref.read(geofencesProvider.notifier).add(fence);
    if (mounted) Navigator.of(context).pop();
  }

  _BuildResult _buildCircle(String name) {
    final lat = double.tryParse(_centerLat.text);
    final lon = double.tryParse(_centerLon.text);
    final r = double.tryParse(_radius.text);
    if (lat == null || lat < -90 || lat > 90) {
      return _Err('Latitude must be in [-90, 90]');
    }
    if (lon == null || lon < -180 || lon > 180) {
      return _Err('Longitude must be in [-180, 180]');
    }
    if (r == null || r <= 0) {
      return _Err('Radius must be > 0 km');
    }
    return _Ok(GeoFence(
      id: 'fence-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: GeoFenceType.circle,
      centerLat: lat,
      centerLon: lon,
      radiusKm: r,
      minAltitudeFt: double.tryParse(_minAlt.text),
      maxAltitudeFt: double.tryParse(_maxAlt.text),
      airlineFilter: _airline.text.trim().isEmpty ? null : _airline.text.trim(),
    ));
  }

  _BuildResult _buildRect(String name) {
    final n = double.tryParse(_north.text);
    final s = double.tryParse(_south.text);
    final e = double.tryParse(_east.text);
    final w = double.tryParse(_west.text);
    if (n == null || s == null || e == null || w == null) {
      return _Err('All four bounds required');
    }
    if (n <= s) return _Err('North must be greater than south');
    if (e <= w) return _Err('East must be greater than west');
    return _Ok(GeoFence(
      id: 'fence-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: GeoFenceType.rectangle,
      northLat: n,
      southLat: s,
      eastLon: e,
      westLon: w,
      minAltitudeFt: double.tryParse(_minAlt.text),
      maxAltitudeFt: double.tryParse(_maxAlt.text),
      airlineFilter: _airline.text.trim().isEmpty ? null : _airline.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New geofence'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'SAVE',
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Type chooser.
            GlassPanel(
              padding: const EdgeInsets.all(8),
              borderRadius: 10,
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'CIRCLE',
                      icon: Icons.circle_outlined,
                      active: _type == GeoFenceType.circle,
                      onTap: () => setState(() => _type = GeoFenceType.circle),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _TypeButton(
                      label: 'RECTANGLE',
                      icon: Icons.crop_square_rounded,
                      active: _type == GeoFenceType.rectangle,
                      onTap: () =>
                          setState(() => _type = GeoFenceType.rectangle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _Field(label: 'Name', controller: _name),

            if (_type == GeoFenceType.circle) ...[
              _Field(label: 'Center latitude (-90..90)', controller: _centerLat,
                  keyboardType: TextInputType.number),
              _Field(label: 'Center longitude (-180..180)', controller: _centerLon,
                  keyboardType: TextInputType.number),
              _Field(label: 'Radius (km)', controller: _radius,
                  keyboardType: TextInputType.number),
            ] else ...[
              _Field(label: 'North latitude', controller: _north, keyboardType: TextInputType.number),
              _Field(label: 'South latitude', controller: _south, keyboardType: TextInputType.number),
              _Field(label: 'East longitude', controller: _east, keyboardType: TextInputType.number),
              _Field(label: 'West longitude', controller: _west, keyboardType: TextInputType.number),
            ],

            const SizedBox(height: 8),
            Text(
              'Optional filters',
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            _Field(label: 'Min altitude (ft)', controller: _minAlt,
                keyboardType: TextInputType.number),
            _Field(label: 'Max altitude (ft)', controller: _maxAlt,
                keyboardType: TextInputType.number),
            _Field(label: 'Airline ICAO (e.g. DLH)', controller: _airline),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

sealed class _BuildResult {
  const _BuildResult();
}

class _Ok extends _BuildResult {
  final GeoFence fence;
  const _Ok(this.fence);
}

class _Err extends _BuildResult {
  final String message;
  const _Err(this.message);
}
