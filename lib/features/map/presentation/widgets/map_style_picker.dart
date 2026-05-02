import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_styles.dart';

/// Compact basemap-style switcher.
///
/// <p>One tap on the layers icon opens a vertical popover that lists every
/// available style; one more tap selects it. Replaces the older
/// cycle-on-tap pattern (six taps to come back to the start), matching the
/// behaviour the web frontend ships under the same name.
///
/// <p>Performance shape:
/// <ul>
///   <li>Closes on tap-outside via a [TapRegion] — no global gesture
///       detector, no listener leaks if the parent tree disappears.</li>
///   <li>Picker entries don't render thumbnails; rendering six basemap
///       previews would re-fetch tiles for styles the user may never
///       pick. The 3-letter style code (DRK, SAT, NGT, …) doubles as the
///       legend so the user knows what each option maps to.</li>
///   <li>Stateful so the open/closed flag survives parent rebuilds (the
///       map screen re-renders on every aircraft position tick).</li>
/// </ul>
class MapStylePicker extends StatefulWidget {
  const MapStylePicker({
    super.key,
    required this.current,
    required this.onChanged,
  });

  /// Currently-active basemap style.
  final MapStyleId current;

  /// Fires with the user's new selection. The parent owns the state.
  final ValueChanged<MapStyleId> onChanged;

  @override
  State<MapStylePicker> createState() => _MapStylePickerState();
}

class _MapStylePickerState extends State<MapStylePicker> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _select(MapStyleId next) {
    widget.onChanged(next);
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final currentDef = styleDef(widget.current);

    final trigger = GestureDetector(
      onTap: _toggle,
      child: GlassPanel(
        padding: const EdgeInsets.all(10),
        borderRadius: 12,
        borderColor: _open ? primary.withValues(alpha: 0.45) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_rounded, size: 20, color: primary),
            const SizedBox(height: 1),
            // 3-letter code under the icon — the same hint the web
            // version puts under its <Layers> svg.
            Text(
              currentDef.label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: primary.withValues(alpha: 0.75),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );

    final popover = GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      borderRadius: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in kStyleOrder)
            _StyleEntry(
              def: styleDef(id),
              active: id == widget.current,
              primary: primary,
              isDark: isDark,
              onTap: () => _select(id),
            ),
        ],
      ),
    );

    // Popover is laid out as a normal sibling of the trigger inside a
    // `Row` — that keeps both inside the parent's hit-test bounds.
    //
    // <p>The previous implementation placed the popover via
    // `Positioned(right: 52, …)` inside a `Stack(clipBehavior: Clip.none)`.
    // Flutter renders the popover in that case (clipBehavior = none),
    // but the Stack's own bounds are sized to the trigger only — so
    // the popover's hit region falls *outside* the Stack and any tap
    // there fails to dispatch. The bug surfaced in widget tests and
    // would have been a silent dead-tap in production. Switching to
    // a Row-based layout sidesteps the hit-test box entirely:
    // everything is laid out in normal flow, the parent column in
    // MapControls grows leftward to fit, and `tester.tap` reaches the
    // popover entries.
    return TapRegion(
      onTapOutside: (_) {
        if (_open) setState(() => _open = false);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_open) ...[
            popover,
            const SizedBox(width: 6),
          ],
          trigger,
        ],
      ),
    );
  }
}

class _StyleEntry extends StatelessWidget {
  const _StyleEntry({
    required this.def,
    required this.active,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final MapStyleDef def;
  final bool active;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final swatchBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.12);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color swatch — uses the style's "high altitude" hue as a
            // recognizable preview (matches web behaviour).
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: def.colors.high,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: swatchBorder, width: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              def.label,
              style: TextStyle(
                fontFamily: UiConstants.headingFont,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active
                    ? primary
                    : (isDark
                        ? AppColors.textSecondary
                        : UiConstants.lightTextSecondary),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
