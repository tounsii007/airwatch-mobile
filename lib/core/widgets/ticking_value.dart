import 'dart:async';

import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Briefly flashes the text color when the wrapped [value] changes.
///
/// <p>Mirrors airwatch-web's `TickingValue.tsx` (commit 6eeb5b8) — a
/// primitive that gives the user a visual cue when a live stat updates
/// (altitude / heading / speed / V/S / lat / lon on the flight-details
/// panel). Without it, a WS push that replaces every stat looks the
/// same as the panel sitting idle for 60 s, and you don't notice the
/// flight is actually moving.
///
/// <p>Compares the new value to the prior render via [State]; on
/// change, flips a flag for [flashFor] then settles back over a
/// [settleDuration] colour transition. The animation is implicit
/// (Flutter's [AnimatedDefaultTextStyle]) so the parent re-rendering
/// with the same value doesn't reset the timer mid-fade.
class TickingValue extends StatefulWidget {
  /// The current value — anything with a meaningful `==`. Strings are
  /// the typical case (already-formatted "FL360" / "+1200 ft/m").
  /// `num` works too; the widget just uses `==` for the change check.
  final Object value;

  /// The text style applied to the rendered value (in both flash and
  /// settled states). The flash colour is layered on top via
  /// [AnimatedDefaultTextStyle.style.color] so the rest of the style
  /// (font / size / weight / spacing) doesn't drift between the two
  /// states.
  final TextStyle style;

  /// How long the flash colour stays applied before fading back to
  /// the normal text color. Default matches the web's 350 ms.
  final Duration flashFor;

  /// How long the colour transition back to normal takes. Default
  /// matches the web's 700 ms.
  final Duration settleDuration;

  /// The flash colour applied when [value] changes. Defaults to the
  /// app's accent colour — same default the web uses for
  /// "text-[var(--accent)]" on TickingValue.
  final Color? flashColor;

  const TickingValue({
    super.key,
    required this.value,
    required this.style,
    this.flashFor = const Duration(milliseconds: 350),
    this.settleDuration = const Duration(milliseconds: 700),
    this.flashColor,
  });

  @override
  State<TickingValue> createState() => _TickingValueState();
}

class _TickingValueState extends State<TickingValue> {
  Object? _previous;
  bool _flashing = false;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _previous = widget.value;
  }

  @override
  void didUpdateWidget(covariant TickingValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compare new vs prior; if changed, flip the flash flag and
    // schedule the settle. Guard against the timer firing on a
    // disposed widget — the parent could unmount mid-flash on a
    // panel close.
    if (widget.value != _previous) {
      _previous = widget.value;
      _settleTimer?.cancel();
      setState(() => _flashing = true);
      _settleTimer = Timer(widget.flashFor, () {
        if (!mounted) return;
        setState(() => _flashing = false);
      });
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.style.color ?? AppColors.textPrimary;
    final accent = widget.flashColor ?? AppColors.accent;
    return AnimatedDefaultTextStyle(
      duration: _flashing
          ? const Duration(milliseconds: 80)
          : widget.settleDuration,
      style: widget.style.copyWith(color: _flashing ? accent : baseColor),
      child: Text(widget.value.toString()),
    );
  }
}
