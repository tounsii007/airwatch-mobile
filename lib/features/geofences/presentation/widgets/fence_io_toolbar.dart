import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/geofences/data/fence_io.dart';
import 'package:airwatch_mobile/features/geofences/data/geofences_repository.dart';
import 'package:airwatch_mobile/features/geofences/domain/geofence.dart';

/// Export / Import toolbar at the top of the fences list. Mirrors the
/// web's `FenceIOToolbar.tsx` (commit 982c6d2) — same statuses, same
/// JSON envelope, so a file exported on mobile imports cleanly on web
/// and vice versa.
///
/// <p>Export uses `share_plus` so the user picks the destination
/// themselves (Notes / Files / Drive / mail). Import is paste-from-
/// clipboard — keeps the dependency surface flat (no file_picker
/// runtime permission dance) and works identically on Android + iOS.
class FenceIOToolbar extends ConsumerStatefulWidget {
  const FenceIOToolbar({super.key, required this.fences});
  final List<GeoFence> fences;

  @override
  ConsumerState<FenceIOToolbar> createState() => _FenceIOToolbarState();
}

class _FenceIOToolbarState extends ConsumerState<FenceIOToolbar> {
  _Status? _status;
  bool _busy = false;

  Future<void> _export(AppStrings s) async {
    if (widget.fences.isEmpty) {
      setState(() => _status = _Status.info(s.fenceExportEmpty));
      return;
    }
    final json = buildExportJson(widget.fences);
    try {
      await SharePlus.instance.share(
        ShareParams(text: json, subject: 'airwatch-fences.json'),
      );
      final count = widget.fences.length;
      final msg = count == 1
          ? s.fenceExportedOne
          : s.fenceExportedMany.replaceAll('{0}', '$count');
      if (mounted) setState(() => _status = _Status.ok(msg));
    } catch (e) {
      if (mounted) {
        setState(
          () => _status = _Status.err(
            s.fenceReadFailed.replaceAll('{0}', e.toString()),
          ),
        );
      }
    }
  }

  Future<void> _import(AppStrings s) async {
    setState(() {
      _busy = true;
      _status = _Status.info(s.fenceReadingFile);
    });
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final raw = data?.text?.trim();
      if (raw == null || raw.isEmpty) {
        if (mounted) {
          setState(
            () => _status = _Status.err(
              s.fenceReadFailed.replaceAll('{0}', 'clipboard empty'),
            ),
          );
        }
        return;
      }
      final result = parseImportJson(raw);
      if (result is FenceImportErr) {
        final text = result.path.isEmpty
            ? s.fenceImportInvalidJson.replaceAll('{0}', result.message)
            : s.fenceImportSchemaMismatch
                  .replaceAll('{0}', result.path)
                  .replaceAll('{1}', result.message);
        if (mounted) setState(() => _status = _Status.err(text));
        return;
      }
      final ok = (result as FenceImportOk).fences;
      // POST through the existing repository so validation, dedup,
      // and persistence run exactly like a manually-created fence.
      final notifier = ref.read(geofencesProvider.notifier);
      for (final fence in ok) {
        notifier.add(fence);
      }
      final msg = ok.length == 1
          ? s.fenceImportedOne
          : s.fenceImportedMany.replaceAll('{0}', '${ok.length}');
      if (mounted) setState(() => _status = _Status.ok(msg));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _IOButton(
            icon: Icons.file_download_outlined,
            label: s.fenceExport,
            tooltip: s.fenceExportTooltip,
            onTap: _busy ? null : () => _export(s),
          ),
          _IOButton(
            icon: Icons.file_upload_outlined,
            label: _busy ? s.fenceImporting : s.fenceImport,
            tooltip: s.fenceImportTooltip,
            onTap: _busy ? null : () => _import(s),
          ),
          if (_status != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                _status!.text,
                style: TextStyle(
                  fontFamily: UiConstants.bodyFont,
                  fontSize: 10,
                  color: switch (_status!.tone) {
                    _Tone.ok => AppColors.success,
                    _Tone.err => AppColors.error,
                    _Tone.info => AppColors.textMuted,
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _Tone { ok, err, info }

class _Status {
  final _Tone tone;
  final String text;
  const _Status._(this.tone, this.text);
  factory _Status.ok(String t) => _Status._(_Tone.ok, t);
  factory _Status.err(String t) => _Status._(_Tone.err, t);
  factory _Status.info(String t) => _Status._(_Tone.info, t);
}

class _IOButton extends StatelessWidget {
  const _IOButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = disabled ? AppColors.textMuted : AppColors.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.glassBorder),
            borderRadius: BorderRadius.circular(6),
            color: disabled
                ? Colors.transparent
                : AppColors.surface.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: UiConstants.headingFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
