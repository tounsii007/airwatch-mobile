import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Animated number that tweens from a previous value to a new one.
///
/// <p>Mirrors the web frontend's `CountUp.tsx` so live counters (flight
/// totals, request stats, web-vitals) feel smooth instead of jumping. Use
/// anywhere a counter would otherwise change abruptly.
///
/// <h3>Implementation notes</h3>
/// <ul>
///   <li>Driven by an [AnimationController] with [Curves.easeOutCubic] —
///       the Flutter equivalent of the web's `easeOutCubic` rAF loop.</li>
///   <li>Cleans up on dispose / value change so a fast-flipping value
///       never leaks animation handles.</li>
///   <li>Locale-aware via [intl] would be heavier than necessary here;
///       Dart's `toStringAsFixed` + manual thousands-separator gives the
///       same visual result with no dependency.</li>
///   <li>Honours the user's reduce-motion preference — when
///       [MediaQueryData.disableAnimations] is true the value snaps to
///       the new target instantly (matches web's `prefers-reduced-motion`
///       behaviour).</li>
/// </ul>
class CountUp extends StatefulWidget {
  /// Target value the counter is driving towards.
  final num value;

  /// Number of digits after the decimal point. Defaults to 0 (integer).
  final int decimals;

  /// Tween duration. Web default is 800 ms.
  final Duration duration;

  /// Optional text style applied to the rendered digits.
  final TextStyle? style;

  /// Optional thousands separator. Defaults to `,` to match en-US.
  final String thousandsSeparator;

  /// Optional decimal separator. Defaults to `.`.
  final String decimalSeparator;

  const CountUp({
    super.key,
    required this.value,
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.thousandsSeparator = ',',
    this.decimalSeparator = '.',
  });

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tween;
  // Source-of-truth for the previous value. We tween FROM this TO the
  // new widget.value on every change. Persists across rebuilds.
  late double _from;

  @override
  void initState() {
    super.initState();
    _from = widget.value.toDouble();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _tween = Tween<double>(
      begin: _from,
      end: _from,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.value = 1.0; // start at the resting position, no flicker.
  }

  @override
  void didUpdateWidget(covariant CountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.duration == widget.duration) {
      return;
    }

    final to = widget.value.toDouble();
    if (oldWidget.value != widget.value) {
      // Reduced-motion: snap directly to the new value. The
      // SchedulerBinding check matches Flutter's recommended way of
      // honouring system-level animation preferences.
      final disableAnims =
          SchedulerBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations ||
          MediaQuery.of(context).disableAnimations;
      if (disableAnims) {
        setState(() {
          _from = to;
          _tween = Tween<double>(begin: to, end: to).animate(_controller);
        });
        _controller.value = 1.0;
        return;
      }

      _tween = Tween<double>(begin: _from, end: to).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..duration = widget.duration
        ..forward(from: 0).whenComplete(() {
          if (mounted) _from = to;
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Format a double with thousands separator + fixed decimals.
  ///
  /// <p>Hot path called once per frame — kept allocation-free in the
  /// common case (no decimals, value < 1000).
  String _format(double v) {
    final fixed = v.toStringAsFixed(widget.decimals);
    final dotIndex = fixed.indexOf('.');
    final intPart = dotIndex == -1 ? fixed : fixed.substring(0, dotIndex);
    final fracPart = dotIndex == -1 ? '' : fixed.substring(dotIndex + 1);
    if (intPart.length <= 3 && widget.thousandsSeparator.isEmpty) {
      return widget.decimals == 0
          ? intPart
          : '$intPart${widget.decimalSeparator}$fracPart';
    }

    // Insert thousands separators going right-to-left.
    final negative = intPart.startsWith('-');
    final digits = negative ? intPart.substring(1) : intPart;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buf.write(widget.thousandsSeparator);
      }
      buf.write(digits[i]);
    }
    final sign = negative ? '-' : '';
    return widget.decimals == 0
        ? '$sign$buf'
        : '$sign$buf${widget.decimalSeparator}$fracPart';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tween,
      builder: (context, _) {
        return Text(
          _format(_tween.value),
          style: widget.style,
          textDirection: TextDirection.ltr,
        );
      },
    );
  }
}
