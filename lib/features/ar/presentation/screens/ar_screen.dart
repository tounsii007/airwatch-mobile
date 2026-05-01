import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/core/widgets/neon_text.dart';

/// AR Mode — identifies aircraft in the sky using camera + GPS.
/// This is the UI shell. Camera integration requires platform-specific plugins:
/// - camera package for camera feed
/// - geolocator for user position
/// - sensors_plus for compass heading + device tilt
///
/// Logic: Compare user GPS + compass bearing + tilt angle against
/// live aircraft positions to find matches in the viewing direction.
class ARScreen extends StatelessWidget {
  const ARScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview placeholder
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a2a3a), Color(0xFF0a1520)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 64,
                      color: primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'AR mode requires camera permission\nand GPS access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 14,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.s.pointSkyUp,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 13,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // Crosshair overlay
          Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Horizontal line
                  Container(width: 200, height: 1,
                      color: primary.withValues(alpha: 0.15)),
                  // Vertical line
                  Container(width: 1, height: 200,
                      color: primary.withValues(alpha: 0.15)),
                  // Center dot
                  Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: primary.withValues(alpha: 0.5),
                      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8)],
                    )),
                ],
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(10), borderRadius: 12,
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeonText(text: context.s.arMode, fontSize: 14, color: primary,
                      glowRadius: isDark ? 8 : 0),
                ],
              ),
            ),
          ),

          // Bottom info
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassPanel(
                  borderRadius: 16, padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'AR Aircraft Detection',
                            style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 14,
                                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This feature uses your camera, GPS, and compass to identify aircraft in the sky. '
                        'It matches the direction you\'re looking with live flight positions to show you '
                        'which flights are overhead.\n\n'
                        'Required: Camera permission, Location permission, Device sensors.',
                        style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      // Platform note
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.construction_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'AR mode requires native mobile build (Android/iOS). Not available on web.',
                            style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 11,
                                color: AppColors.warning),
                          )),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
