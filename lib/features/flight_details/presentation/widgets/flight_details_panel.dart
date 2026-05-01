import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/settings_provider.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_code_formatter.dart';
import 'package:airwatch_mobile/core/utils/flight_status_utils.dart';
import 'package:airwatch_mobile/core/utils/responsive.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/favorites/data/favorites_repository.dart';
import 'package:airwatch_mobile/features/flight_details/data/services/flight_details_service.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';

import 'panel_sections/action_buttons_section.dart';
import 'panel_sections/aircraft_section.dart';
import 'panel_sections/co2_footer_section.dart';
import 'panel_sections/data_grid_section.dart';
import 'panel_sections/gate_section.dart';
import 'panel_sections/prediction_card_section.dart';
import 'panel_sections/route_section.dart';
import 'panel_sections/status_section.dart';

class FlightDetailsPanel extends ConsumerStatefulWidget {
  const FlightDetailsPanel({super.key});

  @override
  ConsumerState<FlightDetailsPanel> createState() => _FlightDetailsPanelState();
}

class _FlightDetailsPanelState extends ConsumerState<FlightDetailsPanel> {
  AirlineInfo? _airline;
  FlightRouteInfo? _route;
  AircraftMetadata? _metadata;
  String? _aircraftPhotoUrl;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _refreshError = false;
  String? _lastIcao;
  Timer? _refreshRetryTimer;

  final _service = FlightDetailsService();

  @override
  void dispose() {
    _refreshRetryTimer?.cancel();
    super.dispose();
  }

  /// Manual refresh — fetches fresh position + flight data from Airlabs
  Future<void> _refreshFlight(AircraftState aircraft, WidgetRef ref) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final result = await _service.refresh(
        aircraft,
        hasRouteLoaded: _route != null,
      );
      if (result.aircraft != null) {
        ref.read(selectedAircraftProvider.notifier).set(result.aircraft);
      }

      if (result.shouldReloadDetails) {
        _lastIcao = null;
        _fetchDetails(aircraft);
      }
    } catch (e) {
      debugPrint('[Refresh] Error: $e');
      if (mounted) {
        setState(() { _isRefreshing = false; _refreshError = true; });
        _refreshRetryTimer?.cancel();
        _refreshRetryTimer = Timer(UiConstants.retryDelay, () {
          if (mounted && _refreshError) _refreshFlight(aircraft, ref);
        });
        return;
      }
    }

    if (mounted) setState(() { _isRefreshing = false; _refreshError = false; });
  }

  void _fetchDetails(AircraftState aircraft) {
    if (_lastIcao == aircraft.icao24) return;
    _lastIcao = aircraft.icao24;
    _airline = _service.resolveAirline(aircraft.callsign);
    _route = null;
    _metadata = null;
    _aircraftPhotoUrl = null;
    _isLoading = true;
    _loadDetails(aircraft);
  }

  Future<void> _loadDetails(AircraftState aircraft) async {
    try {
      final data = await _service.load(aircraft);
      if (!mounted || _lastIcao != aircraft.icao24) return;
      setState(() {
        _airline = data.airline;
        _route = data.route;
        _metadata = data.metadata;
        _aircraftPhotoUrl = data.aircraftPhotoUrl;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted && _lastIcao == aircraft.icao24) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aircraft = ref.watch(selectedAircraftProvider);
    if (aircraft == null) {
      _lastIcao = null;
      return const SizedBox.shrink();
    }

    _fetchDetails(aircraft);

    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelWidth = Responsive.detailsPanelWidth(context);
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    final content = _PanelContent(
      aircraft: aircraft,
      airline: _airline,
      route: _route,
      metadata: _metadata,
      aircraftPhotoUrl: _aircraftPhotoUrl,
      isLoading: _isLoading,
      isDark: isDark,
      primary: primary,
      onClose: () {
        ref.read(selectedAircraftProvider.notifier).set(null);
        _lastIcao = null;
      },
      onTrack: () => ref.read(isTrackingFlightProvider.notifier).set(true),
      onFavorite: () {
        final cs = aircraft.callsign?.trim() ?? aircraft.icao24;
        ref.read(favoritesProvider.notifier).toggle(FavoriteItem(
          id: cs,
          type: FavoriteType.flight,
          label: cs,
          subtitle: _airline?.name ?? aircraft.originCountry,
        ));
      },
      onRefresh: () => _refreshFlight(aircraft, ref),
      isRefreshing: _isRefreshing,
      refreshError: _refreshError,
    );

    if (isMobile) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * AppConfig.panelMaxHeightRatio,
          ),
          child: content,
        ),
      );
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + AppConfig.panelTopOffset,
      left: 12,
      bottom: 80,
      width: panelWidth,
      child: content,
    );
  }
}

class _PanelContent extends ConsumerWidget {
  final AircraftState aircraft;
  final AirlineInfo? airline;
  final FlightRouteInfo? route;
  final AircraftMetadata? metadata;
  final String? aircraftPhotoUrl;
  final bool isLoading;
  final bool isDark;
  final Color primary;
  final VoidCallback onClose;
  final VoidCallback onTrack;
  final VoidCallback onFavorite;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final bool refreshError;

  const _PanelContent({
    required this.aircraft,
    this.airline,
    this.route,
    this.metadata,
    this.aircraftPhotoUrl,
    required this.isLoading,
    required this.isDark,
    required this.primary,
    required this.onClose,
    required this.onTrack,
    required this.onFavorite,
    required this.onRefresh,
    this.isRefreshing = false,
    this.refreshError = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final altColor = FlightStatusUtils.altitudeColor(aircraft.altitude);
    final cs = aircraft.callsign?.trim() ?? '';
    final logoUrl = airline != null
        ? FlightInfoDatasource.getAirlineLogoUrl(airline?.iata ?? '')
        : null;

    return GlassPanel(
      blur: AppConfig.panelGlassBlurDark,
      opacity: isDark ? AppConfig.panelGlassOpacityDark : AppConfig.panelGlassOpacityLight,
      borderRadius: AppConfig.panelBorderRadius,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- HEADER ----
            _header(cs, logoUrl),

            // ---- ROUTE: DEP ----plane---- ARR ----
            PanelRouteSection(
              route: route,
              isLoading: isLoading,
              isDark: isDark,
              primary: primary,
            ),

            // ---- STATUS + DELAYS (from Airlabs) ----
            if (route != null && route!.fromAirlabs)
              PanelStatusSection(
                route: route!,
                isDark: isDark,
                primary: primary,
              ),

            // ---- GATE / TERMINAL INFO ----
            if (route != null && route!.fromAirlabs)
              PanelGateSection(
                route: route!,
                isDark: isDark,
                primary: primary,
              ),

            // ---- AIRCRAFT TYPE + DETAILS ----
            PanelAircraftSection(
              route: route,
              metadata: metadata,
              isLoading: isLoading,
              isDark: isDark,
              primary: primary,
            ),

            // ---- FLIGHT DATA GRID ----
            PanelDataGrid(
              aircraft: aircraft,
              settings: settings,
              altColor: altColor,
              isDark: isDark,
            ),

            // ---- TAGS ROW ----
            _tagsRow(),

            // ---- AI / HEURISTIC PREDICTION CARD ----
            //
            // Mirrors the web frontend's `PredictionCard.tsx` — donut
            // gauge of arrival-delay probability + factor pills. Hidden
            // when the predictor decides it has too little signal.
            PanelPredictionCard(
              aircraft: aircraft,
              route: route,
              isDark: isDark,
            ),

            // ---- AIRCRAFT PHOTO (above buttons) ----
            if (aircraftPhotoUrl != null)
              PanelAircraftPhoto(
                aircraftPhotoUrl: aircraftPhotoUrl!,
                metadata: metadata,
                isDark: isDark,
                primary: primary,
                // Tapping the photo opens the multi-photo gallery,
                // matching the web frontend's `PhotoGallery` modal.
                icao24: aircraft.icao24,
              ),

            // ---- CO₂ + SHARE FOOTER ----
            //
            // Mirrors the web frontend's `Co2Footer.tsx` — kg-CO₂ estimate
            // for the dep→arr great circle on the left, native share
            // sheet on the right (clipboard fallback when the platform
            // has no share daemon).
            PanelCo2Footer(
              aircraft: aircraft,
              route: route,
              airline: airline,
              metadata: metadata,
              isDark: isDark,
            ),

            // ---- ACTIONS ----
            PanelActionButtons(
              aircraft: aircraft,
              isDark: isDark,
              onTrack: onTrack,
              onFavorite: onFavorite,
            ),
          ],
        ),
      ),
    );
  }

  // -- Header --
  Widget _header(String cs, String? logoUrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
        )),
      ),
      child: Row(
        children: [
          if (logoUrl != null)
            Container(
              width: 60, height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(3),
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.contain,
                errorWidget: (_, error, stackTrace) => Icon(
                    Icons.airlines_rounded, color: primary, size: 22),
                placeholder: (_, url) => const SizedBox.shrink(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.flight_rounded, color: primary, size: 22),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (airline != null)
                  Text(airline?.name ?? '', style: TextStyle(
                    fontFamily: UiConstants.bodyFont, fontSize: UiConstants.bodyFontSize, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                  )),
                // Large flight number
                NeonText(
                  text: _displayFlightNumber(cs),
                  fontSize: 26, color: primary,
                  glowRadius: isDark ? 10 : 0,
                ),
              ],
            ),
          ),
          if (aircraft.originCountry != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Text(aircraft.originCountry ?? '', style: TextStyle(
                fontFamily: UiConstants.bodyFont, fontSize: UiConstants.microFontSize,
                fontWeight: FontWeight.w700, color: primary,
              )),
            ),
          const SizedBox(width: 4),
          // Refresh button: normal -> loading -> error (auto-retry)
          GestureDetector(
            onTap: isRefreshing ? null : onRefresh,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: refreshError
                    ? AppColors.error.withValues(alpha: 0.15)
                    : primary.withValues(alpha: isDark ? 0.1 : 0.06),
                borderRadius: BorderRadius.circular(6),
                border: refreshError
                    ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                    : null,
              ),
              child: isRefreshing
                  ? SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primary))
                  : refreshError
                      ? Icon(Icons.wifi_off_rounded, size: 16,
                          color: AppColors.error)
                      : Icon(Icons.refresh_rounded, size: 16, color: primary),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close_rounded, size: 18,
                color: isDark ? AppColors.textSecondary : UiConstants.lightTextMuted),
          ),
        ],
      ),
    );
  }

  // -- Tags row: ICAO24, Registration --
  Widget _tagsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _Tag(label: 'ICAO24', value: aircraft.icao24.toUpperCase(),
              color: primary, isDark: isDark),
          if (metadata?.registration != null)
            _Tag(label: 'REG', value: metadata?.registration ?? '',
                color: primary, isDark: isDark),
          if (metadata?.typecode != null)
            _Tag(label: 'TYPE', value: metadata?.typecode ?? '',
                color: AppColors.accent, isDark: isDark),
        ],
      ),
    );
  }

  String _displayFlightNumber(String cs) {
    return FlightCodeFormatter.displayFlightCode(
      callsign: cs,
      fallback: aircraft.icao24,
      spaced: true,
    );
  }
}

// ================= SMALL PRIVATE WIDGETS =================

class _Tag extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool isDark;
  const _Tag({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 9,
            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontFamily: 'Orbitron', fontSize: 9,
            fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
