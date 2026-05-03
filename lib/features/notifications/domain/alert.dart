import 'package:flutter/material.dart';

import 'package:airwatch_mobile/core/theme/app_colors.dart';

/// Alert kinds the central hub knows how to render. Each kind has its
/// own icon + accent colour but shares the same shape so the bell
/// dropdown can list them in a single feed.
///
/// <p>Mirrors the web frontend's `alertStore` types — squawk emergency,
/// geofence intrusion, system message — with two extras for mobile:
/// `system` (offline / quota) and `info` (general feedback).
enum AlertKind { squawk, geofence, system, info }

/// One entry in the central alert hub. Immutable; the store builds new
/// instances on each tick rather than mutating in place.
@immutable
class AppAlert {
  /// Stable key — used to deduplicate when re-deriving the live alert
  /// list on each flight tick (so the same squawk doesn't fire ten
  /// times in a row).
  final String id;
  final AlertKind kind;
  final String title;
  final String? subtitle;
  final DateTime firedAt;

  /// Optional `id` that the consumer can use to focus the relevant
  /// entity (an aircraft icao24 for squawk, a fence id for geofence).
  final String? targetId;

  const AppAlert({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    required this.firedAt,
    this.targetId,
  });

  /// Visual icon + colour for the bell badge / list tile. Centralised
  /// here so the hub UI never has to switch on the kind.
  IconData get icon => switch (kind) {
    AlertKind.squawk => Icons.warning_amber_rounded,
    AlertKind.geofence => Icons.fence_rounded,
    AlertKind.system => Icons.cloud_off_rounded,
    AlertKind.info => Icons.info_outline_rounded,
  };

  Color get accent => switch (kind) {
    AlertKind.squawk => AppColors.error,
    AlertKind.geofence => AppColors.warning,
    AlertKind.system => AppColors.textMuted,
    AlertKind.info => AppColors.info,
  };
}
