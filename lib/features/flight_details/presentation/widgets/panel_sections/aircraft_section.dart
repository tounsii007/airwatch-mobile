import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/flight_details/presentation/screens/photo_gallery_screen.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';

import 'panel_widgets.dart';

/// Aircraft type + details section.
class PanelAircraftSection extends StatelessWidget {
  final FlightRouteInfo? route;
  final AircraftMetadata? metadata;
  final bool isLoading;
  final bool isDark;
  final Color primary;

  const PanelAircraftSection({
    super.key,
    required this.route,
    required this.metadata,
    required this.isLoading,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer Airlabs data, fallback to hexdb metadata
    final model = route?.aircraftModel ?? metadata?.displayType;
    final manufacturer = route?.aircraftManufacturer ?? metadata?.manufacturer;
    final operator = metadata?.operatorName;
    final age = route?.aircraftAge;
    final built = route?.aircraftBuilt;
    final engine = route?.engineType;
    final engineCount = route?.engineCount;
    final msn = route?.msn;
    final typecode = metadata?.typecode;
    final ageLabel = age == null
        ? null
        : built != null
        ? '$age y ($built)'
        : '$age y';

    if (model == null && metadata == null && !isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aircraft model + typecode badge
          Row(
            children: [
              Icon(Icons.airplanemode_active_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  model ??
                      (isLoading
                          ? context.tr('loading')
                          : UiConstants.unknownValue),
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: UiConstants.bodyFontSize,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimary
                        : UiConstants.lightTextPrimary,
                  ),
                ),
              ),
              if (typecode != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    typecode,
                    style: TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: UiConstants.tinyFontSize,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
            ],
          ),
          if (operator != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
              child: Text(
                '${context.s.operatedBy} $operator',
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondary
                      : UiConstants.lightTextSecondary,
                ),
              ),
            ),
          // Detail chips: Manufacturer, Engine, Age, Built
          if (manufacturer != null || engine != null || age != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (manufacturer != null)
                    DetailChip(
                      icon: Icons.factory_rounded,
                      label: manufacturer,
                      color: primary,
                      isDark: isDark,
                    ),
                  if (engine != null)
                    DetailChip(
                      icon: Icons.local_fire_department_rounded,
                      // Compose "engines × type" when both are known
                      // (e.g. "4× turbofan"), matching web's MetadataSection
                      // composition. Falls back to just the type when the
                      // count is missing.
                      label: engineCount != null
                          ? '$engineCount× ${engine[0].toUpperCase()}${engine.substring(1)}'
                          : '${engine[0].toUpperCase()}${engine.substring(1)}',
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  if (ageLabel != null)
                    DetailChip(
                      icon: Icons.calendar_today_rounded,
                      label: ageLabel,
                      color: AppColors.altitudeMedium,
                      isDark: isDark,
                    ),
                  // MSN (manufacturer serial number) — useful for
                  // spotters tracking a specific airframe across
                  // registrations. Renders as a plain tag rather than
                  // taking a coloured slot since it's a string ID,
                  // not a categorical attribute.
                  if (msn != null && msn.isNotEmpty)
                    DetailChip(
                      icon: Icons.tag_rounded,
                      label: 'MSN $msn',
                      color: AppColors.textSecondary,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Aircraft photo with airline livery. Tappable to open the full
/// multi-photo gallery (mirrors the web frontend's `PhotoGallery`
/// modal, which opens when a user taps the photo on
/// DesktopDetailsPanel).
class PanelAircraftPhoto extends StatelessWidget {
  final String aircraftPhotoUrl;
  final AircraftMetadata? metadata;
  final bool isDark;
  final Color primary;

  /// ICAO24 hex of the aircraft — needed to fetch the photo gallery.
  /// Optional so a single-photo render path still works without it.
  final String? icao24;

  const PanelAircraftPhoto({
    super.key,
    required this.aircraftPhotoUrl,
    required this.metadata,
    required this.isDark,
    required this.primary,
    this.icao24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GestureDetector(
        onTap: icao24 == null
            ? null
            : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => PhotoGalleryScreen(icao24: icao24!),
                  ),
                );
              },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Photo
              CachedNetworkImage(
                imageUrl: aircraftPhotoUrl,
                width: double.infinity,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (_, url) => Container(
                  height: 110,
                  color: isDark ? AppColors.surface : const Color(0xFFF0F4F8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                errorWidget: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
              // Gradient overlay at bottom for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // Photo credit + aircraft info + "tap to expand" hint
              Positioned(
                bottom: 4,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'planespotters.net',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const Spacer(),
                    if (icao24 != null) ...[
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (metadata?.registration != null)
                      Text(
                        metadata?.registration ?? '',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
