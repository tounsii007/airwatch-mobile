import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:airwatch_mobile/features/airline/presentation/screens/airline_detail_screen.dart';
import 'package:airwatch_mobile/features/map/data/datasources/flight_info_datasource.dart';
import 'package:airwatch_mobile/core/constants/country_database.dart';
import 'package:airwatch_mobile/core/constants/config.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/utils/flight_status_utils.dart';
import 'package:airwatch_mobile/core/utils/aircraft_icons.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/search/data/models/search_models.dart';
import 'package:airwatch_mobile/features/search/data/services/search_service.dart';
import 'package:airwatch_mobile/features/search/presentation/widgets/highlighted_text.dart';
import 'package:airwatch_mobile/features/search/presentation/widgets/search_section_header.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final void Function(AircraftState aircraft) onFlightSelected;

  const SearchScreen({super.key, required this.onFlightSelected});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _service = SearchService();

  String _query = '';
  Timer? _debounce;
  List<SearchResultItem> _suggestions = [];
  bool _isSearching = false;
  SearchFilter _activeFilter = SearchFilter.all;
  int _searchGeneration = 0;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(AppConfig.searchDebounce, () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    final generation = ++_searchGeneration;
    final q = query.trim().toUpperCase();
    if (q.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final aircraft = ref.read(aircraftStreamProvider).when(
          data: (data) => data,
          loading: () => <String, AircraftState>{},
          error: (error, stackTrace) => <String, AircraftState>{},
        );

    final results = await _service.search(q, liveAircraft: aircraft);

    if (mounted && generation == _searchGeneration) {
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    final filtered = _service.filterResults(_suggestions, _activeFilter);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : UiConstants.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: UiConstants.searchHeaderPadding,
              child: Center(
                child: NeonText(
                  text: context.s.search,
                  fontSize: UiConstants.searchHeaderFontSize,
                  color: primary,
                  glowRadius: isDark ? 10 : 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: UiConstants.screenPadding,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : UiConstants.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorder : UiConstants.lightBorder,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontFamily: UiConstants.headingFont,
                    fontSize: UiConstants.bodyFontSize,
                    color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('search_flights_hint'),
                    hintStyle: TextStyle(
                      fontFamily: UiConstants.bodyFont,
                      fontSize: UiConstants.bodyFontSize,
                      color: isDark ? AppColors.textMuted : UiConstants.lightHintText,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: primary),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              _onQueryChanged('');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: UiConstants.screenPadding,
                children: [
                  _FilterChip(
                    label: context.tr('all'),
                    count: _suggestions.isNotEmpty ? _suggestions.length : null,
                    isActive: _activeFilter == SearchFilter.all,
                    color: primary,
                    isDark: isDark,
                    onTap: () => setState(() => _activeFilter = SearchFilter.all),
                  ),
                  _FilterChip(
                    label: context.tr('live'),
                    count: _suggestions.isNotEmpty ? _countForType(SearchResultType.liveAircraft) : null,
                    isActive: _activeFilter == SearchFilter.live,
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () => setState(() => _activeFilter = SearchFilter.live),
                  ),
                  _FilterChip(
                    label: context.tr('airlines'),
                    count: _suggestions.isNotEmpty ? _countForType(SearchResultType.airline) : null,
                    isActive: _activeFilter == SearchFilter.airlines,
                    color: AppColors.accent,
                    isDark: isDark,
                    onTap: () => setState(() => _activeFilter = SearchFilter.airlines),
                  ),
                  _FilterChip(
                    label: context.tr('flights_upper'),
                    count: _suggestions.isNotEmpty
                        ? _countForType(SearchResultType.apiResult) + _countForType(SearchResultType.airlineFlight)
                        : null,
                    isActive: _activeFilter == SearchFilter.flights,
                    color: primary,
                    isDark: isDark,
                    onTap: () => setState(() => _activeFilter = SearchFilter.flights),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_isSearching)
              Padding(
                padding: UiConstants.screenPadding,
                child: LinearProgressIndicator(
                  color: primary,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  minHeight: 2,
                ),
              ),
            Expanded(
              child: _query.isEmpty
                  ? _emptyState(isDark)
                  : filtered.isEmpty && !_isSearching
                      ? _noResults(isDark)
                      : _activeFilter == SearchFilter.all
                          ? _buildGroupedResults(filtered, isDark, primary)
                          : ListView.builder(
                              padding: UiConstants.searchResultsPadding,
                              itemCount: filtered.length,
                              itemBuilder: (_, index) => _ResultTile(
                                result: filtered[index],
                                isDark: isDark,
                                primary: primary,
                                query: _query,
                                onTap: () => _onResultTap(filtered[index]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // Group by type for ALL filter
  Map<SearchResultType, List<SearchResultItem>> _groupResults(List<SearchResultItem> results) {
    final groups = <SearchResultType, List<SearchResultItem>>{};
    for (final r in results) {
      (groups[r.type] ??= []).add(r);
    }
    return groups;
  }

  int _countForType(SearchResultType type) {
    return _suggestions.where((r) => r.type == type).length;
  }

  static const _groupOrder = [
    SearchResultType.liveAircraft,
    SearchResultType.airline,
    SearchResultType.apiResult,
    SearchResultType.airlineFlight,
    SearchResultType.country,
  ];

  static const _groupColors = {
    SearchResultType.liveAircraft: AppColors.success,
    SearchResultType.airline: AppColors.accent,
    SearchResultType.apiResult: null, // uses primary
    SearchResultType.airlineFlight: null, // uses primary
    SearchResultType.country: AppColors.altitudeLow,
  };

  String _groupLabel(BuildContext context, SearchResultType type) {
    return switch (type) {
      SearchResultType.liveAircraft => context.tr('live'),
      SearchResultType.airline => context.tr('airlines'),
      SearchResultType.apiResult => context.tr('flights_upper'),
      SearchResultType.airlineFlight => context.tr('flights_upper'),
      SearchResultType.country => context.tr('countries'),
    };
  }

  void _onResultTap(SearchResultItem result) {
    switch (result.type) {
      case SearchResultType.liveAircraft:
        // Try live first, fall back to cached aircraft (landed flights)
        final selected = _service.resolveSelectedAircraft(
          result,
          liveAircraft: _liveAircraftSnapshot(),
        ) ?? result.aircraft;
        if (selected != null) {
          widget.onFlightSelected(selected);
        }
      case SearchResultType.country:
        _controller.text = result.title;
        _controller.selection = TextSelection.collapsed(offset: result.title.length);
        _onQueryChanged(result.title);
      case SearchResultType.airline:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AirlineDetailScreen(
            icao: result.airlineIcao ?? '',
            iata: result.airlineIata,
            name: result.title,
            // subtitle is non-nullable on SearchResultItem.
            country: result.subtitle.split(' - ').lastOrNull,
          ),
        ));
      case SearchResultType.apiResult:
      case SearchResultType.airlineFlight:
        final selected = _service.resolveSelectedAircraft(
          result,
          liveAircraft: _liveAircraftSnapshot(),
        );
        if (selected != null) {
          widget.onFlightSelected(selected);
        }
    }
  }

  Map<String, AircraftState> _liveAircraftSnapshot() {
    return ref.read(aircraftStreamProvider).when(
          data: (data) => data,
          loading: () => <String, AircraftState>{},
          error: (error, stackTrace) => <String, AircraftState>{},
        );
  }

  Widget _buildGroupedResults(List<SearchResultItem> results, bool isDark, Color primary) {
    final groups = _groupResults(results);
    final widgets = <Widget>[];

    for (final type in _groupOrder) {
      final items = groups[type];
      if (items == null || items.isEmpty) continue;

      final color = _groupColors[type] ?? primary;
      widgets.add(
        SearchSectionHeader(
          title: _groupLabel(context, type),
          count: items.length,
          color: color,
          isDark: isDark,
        ),
      );

      for (final item in items) {
        widgets.add(
          _ResultTile(
            result: item,
            isDark: isDark,
            primary: primary,
            query: _query,
            onTap: () => _onResultTap(item),
          ),
        );
      }
    }

    return ListView(
      padding: UiConstants.searchResultsPadding,
      children: widgets,
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flight_rounded,
            size: 48,
            color: isDark ? AppColors.textMuted : UiConstants.lightDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('search_flights_prompt'),
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: UiConstants.bodyFontSize,
              color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('search_examples'),
            style: TextStyle(
              fontFamily: UiConstants.bodyFont,
              fontSize: UiConstants.captionFontSize,
              color: isDark ? AppColors.textMuted : UiConstants.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noResults(bool isDark) {
    return Center(
      child: Text(
        context.tr('no_results'),
        style: TextStyle(
          fontFamily: UiConstants.bodyFont,
          fontSize: UiConstants.bodyFontSize,
          color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isActive;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.count,
    required this.isActive,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.5)
                : (isDark ? AppColors.glassBorder : UiConstants.lightBorder),
          ),
        ),
        child: Center(
          child: Text(
            count != null ? '$label ($count)' : label,
            style: TextStyle(
              fontFamily: UiConstants.headingFont,
              fontSize: UiConstants.tinyFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: isActive ? color : (isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResultItem result;
  final bool isDark;
  final Color primary;
  final String query;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.isDark,
    required this.primary,
    this.query = '',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = FlightStatusUtils.statusColor(result.status, primary: primary);
    final statusLabel = FlightStatusUtils.statusLabel(context, result.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: GlassPanel(
          padding: const EdgeInsets.all(12),
          borderRadius: 12,
          child: Row(
            children: [
              _leadingVisual(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      text: result.title,
                      query: query,
                      baseStyle: TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: UiConstants.captionFontSize,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : UiConstants.lightTextPrimary,
                      ),
                      highlightColor: primary,
                    ),
                    if (result.subtitle.isNotEmpty)
                      HighlightedText(
                        text: result.subtitle,
                        query: query,
                        baseStyle: TextStyle(
                          fontFamily: UiConstants.bodyFont,
                          fontSize: UiConstants.captionFontSize,
                          color: isDark ? AppColors.textSecondary : UiConstants.lightTextSecondary,
                        ),
                        highlightColor: primary,
                      ),
                  ],
                ),
              ),
              if (statusLabel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: UiConstants.headingFont,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              if (_showsChevron(result.type))
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? AppColors.textMuted : UiConstants.lightDisabled,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leadingVisual() {
    final (icon, iconColor) = switch (result.type) {
      SearchResultType.liveAircraft => (
          Icons.flight_rounded,
          result.altitude != null
              ? AircraftIconPainter.getAltitudeColor(result.altitude)
              : AppColors.success,
        ),
      SearchResultType.airline => (Icons.airlines_rounded, AppColors.accent),
      SearchResultType.apiResult => (Icons.flight_takeoff_rounded, primary),
      SearchResultType.airlineFlight => (Icons.flight_rounded, primary),
      SearchResultType.country => (Icons.flag_rounded, AppColors.altitudeLow),
    };

    final isAirline = result.type == SearchResultType.airline;
    final size = isAirline ? 44.0 : 36.0;

    if (isAirline) {
      return SizedBox(
        width: size,
        height: size,
        child: _airlineLogo(iconColor),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: switch (result.type) {
        SearchResultType.country => _countryFlag(iconColor),
        _ => Icon(icon, size: 18, color: iconColor),
      },
    );
  }

  Widget _countryFlag(Color fallbackColor) {
    final assetPath = CountryDatabase.flagAssetPathOf(result.countryCode);
    if (assetPath == null) {
      return Icon(Icons.flag_rounded, size: 18, color: fallbackColor);
    }

    return Padding(
      padding: const EdgeInsets.all(7),
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _airlineLogo(Color fallbackColor) {
    final iata = result.airlineIata;
    final logoUrl = FlightInfoDatasource.getAirlineLogoUrl(iata);
    if (logoUrl == null) {
      return Icon(Icons.airlines_rounded, size: 22, color: fallbackColor);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) =>
              Icon(Icons.airlines_rounded, size: 22, color: fallbackColor),
          placeholder: (_, _) =>
              Icon(Icons.airlines_rounded, size: 22, color: fallbackColor),
        ),
      ),
    );
  }

  bool _showsChevron(SearchResultType type) {
    return switch (type) {
      SearchResultType.airline || SearchResultType.country => true,
      SearchResultType.liveAircraft ||
      SearchResultType.apiResult ||
      SearchResultType.airlineFlight => false,
    };
  }
}
