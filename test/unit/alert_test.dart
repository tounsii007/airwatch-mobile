import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/features/notifications/domain/alert.dart';

void main() {
  group('AppAlert kind → icon + accent', () {
    AppAlert make(AlertKind k) =>
        AppAlert(id: 'x', kind: k, title: 't', firedAt: DateTime.now());

    test('squawk uses warning icon + error red', () {
      final a = make(AlertKind.squawk);
      expect(a.icon, Icons.warning_amber_rounded);
      expect(a.accent, AppColors.error);
    });

    test('geofence uses fence icon + warning amber', () {
      final a = make(AlertKind.geofence);
      expect(a.icon, Icons.fence_rounded);
      expect(a.accent, AppColors.warning);
    });

    test('system uses cloud-off + muted', () {
      final a = make(AlertKind.system);
      expect(a.icon, Icons.cloud_off_rounded);
      expect(a.accent, AppColors.textMuted);
    });

    test('info uses info-outline + info colour', () {
      final a = make(AlertKind.info);
      expect(a.icon, Icons.info_outline_rounded);
      expect(a.accent, AppColors.info);
    });
  });

  test('AppAlert is immutable — fields stay after construction', () {
    final t = DateTime.utc(2025);
    final a = AppAlert(
      id: 'sq-AABBCC',
      kind: AlertKind.squawk,
      title: 'Emergency squawk',
      subtitle: 'DLH400 · 7700',
      firedAt: t,
      targetId: 'AABBCC',
    );
    expect(a.id, 'sq-AABBCC');
    expect(a.title, 'Emergency squawk');
    expect(a.subtitle, 'DLH400 · 7700');
    expect(a.firedAt, t);
    expect(a.targetId, 'AABBCC');
  });
}
