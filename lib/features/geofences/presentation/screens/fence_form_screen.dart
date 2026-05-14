import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
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
///   <li>Optional altitude band + airline filter (min AND max).</li>
/// </ul>
///
/// <p>All labels + error messages come from {@link AppStrings} so the
/// form fully respects the active locale — same as web commit 4a6ea68.
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

  void _save(AppStrings s) {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = s.fenceErrNameRequired);
      return;
    }
    final result = _type == GeoFenceType.circle
        ? _buildCircle(name, s)
        : _buildRect(name, s);
    if (result is _Err) {
      setState(() => _error = result.message);
      return;
    }
    final fence = (result as _Ok).fence;
    ref.read(geofencesProvider.notifier).add(fence);
    if (mounted) Navigator.of(context).pop();
  }

  _BuildResult _buildCircle(String name, AppStrings s) {
    final lat = double.tryParse(_centerLat.text);
    final lon = double.tryParse(_centerLon.text);
    final r = double.tryParse(_radius.text);
    if (lat == null || lat < -90 || lat > 90) {
      return _Err(s.fenceErrLatRange);
    }
    if (lon == null || lon < -180 || lon > 180) {
      return _Err(s.fenceErrLonRange);
    }
    if (r == null || r <= 0) {
      return _Err(s.fenceErrRadius);
    }
    return _Ok(
      GeoFence(
        id: 'fence-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: GeoFenceType.circle,
        centerLat: lat,
        centerLon: lon,
        radiusKm: r,
        minAltitudeFt: double.tryParse(_minAlt.text),
        maxAltitudeFt: double.tryParse(_maxAlt.text),
        airlineFilter: _airline.text.trim().isEmpty
            ? null
            : _airline.text.trim(),
      ),
    );
  }

  _BuildResult _buildRect(String name, AppStrings s) {
    final n = double.tryParse(_north.text);
    final south = double.tryParse(_south.text);
    final e = double.tryParse(_east.text);
    final w = double.tryParse(_west.text);
    if (n == null || south == null || e == null || w == null) {
      return _Err(s.fenceErrBoundsRequired);
    }
    if (n <= south) return _Err(s.fenceErrNorthSouth);
    if (e <= w) return _Err(s.fenceErrEastWest);
    return _Ok(
      GeoFence(
        id: 'fence-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: GeoFenceType.rectangle,
        northLat: n,
        southLat: south,
        eastLon: e,
        westLon: w,
        minAltitudeFt: double.tryParse(_minAlt.text),
        maxAltitudeFt: double.tryParse(_maxAlt.text),
        airlineFilter: _airline.text.trim().isEmpty
            ? null
            : _airline.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final typeLabel = _type == GeoFenceType.circle
        ? s.fenceTypeCircle
        : s.fenceTypeRectangle;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.fenceFormTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _save(s),
            child: Text(
              s.fenceSaveButton,
              style: const TextStyle(
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
            // Heading mirrors the web form's "NEW {0} GEOFENCE".
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                s.fenceNewHeading.replaceAll('{0}', typeLabel),
                style: const TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Type chooser.
            GlassPanel(
              padding: const EdgeInsets.all(8),
              borderRadius: 10,
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: s.fenceTypeCircle,
                      icon: Icons.circle_outlined,
                      active: _type == GeoFenceType.circle,
                      onTap: () => setState(() => _type = GeoFenceType.circle),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _TypeButton(
                      label: s.fenceTypeRectangle,
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

            _Field(
              label: s.fenceNameLabel,
              hint: s.fenceNamePlaceholder,
              controller: _name,
            ),

            if (_type == GeoFenceType.circle) ...[
              _Field(
                label: s.fenceCenterLatLabel,
                controller: _centerLat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              _Field(
                label: s.fenceCenterLonLabel,
                controller: _centerLon,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              _Field(
                label: s.fenceRadiusLabel,
                controller: _radius,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ] else ...[
              _Field(
                label: s.fenceNorthLabel,
                controller: _north,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              _Field(
                label: s.fenceSouthLabel,
                controller: _south,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              _Field(
                label: s.fenceEastLabel,
                controller: _east,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
              _Field(
                label: s.fenceWestLabel,
                controller: _west,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              s.fenceOptionalFilters,
              style: const TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            _Field(
              label: s.fenceMinAltLabel,
              controller: _minAlt,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _Field(
              label: s.fenceMaxAltLabel,
              controller: _maxAlt,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            _Field(label: s.fenceAirlineLabel, controller: _airline),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
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
    this.hint,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
            Icon(
              icon,
              size: 14,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
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
