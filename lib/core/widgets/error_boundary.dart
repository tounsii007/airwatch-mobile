import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Per-segment error boundary, mirroring airwatch-web's commit 59b28bf.
///
/// <h3>What it catches</h3>
/// Any synchronous exception thrown inside the [child] widget tree
/// during build / layout / paint. Async errors (futures, streams)
/// are NOT caught here — those still need their own handlers in the
/// data layer (see Riverpod's `AsyncValue.when` patterns).
///
/// <h3>Why per-segment, not app-wide</h3>
/// A crash inside the AR HUD shouldn't kill the whole app. Wrap each
/// top-level screen — and any feature surface that mixes user input
/// with external data (3D globe, replay scrubber, voice command) —
/// in its own boundary. The fallback shows a small "section
/// unavailable" panel + retry button instead of replacing the whole
/// app with the framework's red error screen.
///
/// <h3>Reset semantics</h3>
/// Pressing "retry" rebuilds the wrapped subtree from scratch. Use the
/// optional [resetKey] to force a reset from the parent — e.g. when
/// the user changes the language or theme and the error was rooted in
/// the old config.
class ErrorBoundary extends StatefulWidget {
  /// The subtree this boundary protects.
  final Widget child;

  /// When this changes, the boundary resets and re-renders [child].
  /// Useful for parent-driven recovery (config change, navigation).
  final Object? resetKey;

  /// Optional override for the fallback UI. When null we render the
  /// default "section unavailable" panel.
  final Widget Function(FlutterErrorDetails details, VoidCallback retry)?
      fallbackBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.resetKey,
    this.fallbackBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void didUpdateWidget(covariant ErrorBoundary old) {
    super.didUpdateWidget(old);
    // Parent-driven reset.
    if (old.resetKey != widget.resetKey && _error != null) {
      setState(() => _error = null);
    }
  }

  void _retry() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final captured = _error;
    if (captured != null) {
      final builder = widget.fallbackBuilder ?? _defaultFallback;
      return builder(captured, _retry);
    }
    // Wrap child in an ErrorWidget.builder catcher. Flutter routes
    // build / layout / paint exceptions through ErrorWidget.builder;
    // a custom builder swap here scopes the catch to the subtree.
    return _ErrorBoundaryHost(
      onError: (details) {
        if (!mounted) return;
        // Defer the setState to the next frame — calling it during a
        // build pass throws "setState during build" assertions.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _error == null) {
            setState(() => _error = details);
          }
        });
      },
      child: widget.child,
    );
  }

  Widget _defaultFallback(FlutterErrorDetails details, VoidCallback retry) {
    return _DefaultErrorView(
      details: details,
      onRetry: retry,
    );
  }
}

/// Catches build-time exceptions in the subtree by overriding
/// [ErrorWidget.builder] for its descendants. Restores the previous
/// builder when unmounted so non-boundary parts of the app keep
/// using the framework default.
class _ErrorBoundaryHost extends StatefulWidget {
  final Widget child;
  final void Function(FlutterErrorDetails) onError;

  const _ErrorBoundaryHost({required this.child, required this.onError});

  @override
  State<_ErrorBoundaryHost> createState() => _ErrorBoundaryHostState();
}

class _ErrorBoundaryHostState extends State<_ErrorBoundaryHost> {
  late final ErrorWidgetBuilder _previous;

  @override
  void initState() {
    super.initState();
    _previous = ErrorWidget.builder;
    ErrorWidget.builder = (details) {
      widget.onError(details);
      // Render a transparent placeholder while the host re-renders
      // with the captured error in state. Keeping it visually empty
      // avoids the "flash of red" before the fallback appears.
      return const SizedBox.shrink();
    };
  }

  @override
  void dispose() {
    ErrorWidget.builder = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DefaultErrorView extends StatelessWidget {
  final FlutterErrorDetails details;
  final VoidCallback onRetry;

  const _DefaultErrorView({required this.details, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.45),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.sectionUnavailable,
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  // Show only the exception summary — full stacktraces
                  // belong in logs, not in front of the user.
                  details.exceptionAsString().split('\n').first,
                  style: TextStyle(
                    fontFamily: UiConstants.bodyFont,
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : UiConstants.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      s.retryButton.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: UiConstants.headingFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
