import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/admin/presentation/providers/admin_providers.dart';
import 'package:airwatch_mobile/features/admin/presentation/screens/admin_metrics_screen.dart';

/// Admin login screen. Submits to `/admin/login` on the airwatch-api
/// backend and, on success, pushes [AdminMetricsScreen].
///
/// <p>Recommended account: a VIEWER configured via
/// `VIEWER_PASSWORD_HASH` on the backend. ADMIN credentials would also
/// work but the mobile UI never offers state-changing actions, so VIEWER is
/// the principle-of-least-privilege option for this surface.
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _user = TextEditingController(text: 'viewer');
  final _pw   = TextEditingController();
  final _totp = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pw.dispose();
    _totp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
    final s = S.of(ref.read(languageProvider));
    final ok = await ref.read(adminSignedInProvider.notifier).login(
      _user.text.trim(),
      _pw.text,
      totp: _totp.text.trim().isEmpty ? null : _totp.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AdminMetricsScreen()),
      );
    } else {
      setState(() { _busy = false; _error = s.adminBadCreds; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(ref.watch(languageProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.adminLogin),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GlassPanel(
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_moon_outlined, size: 48, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(s.adminLogin,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('airwatch-api',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1)),
                const SizedBox(height: 24),
                TextField(
                  controller: _user,
                  decoration: InputDecoration(
                    labelText: s.adminUsername,
                    border: const OutlineInputBorder(),
                  ),
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw,
                  decoration: InputDecoration(
                    labelText: s.adminPassword,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _totp,
                  decoration: InputDecoration(
                    labelText:  s.adminTotpLabel,
                    helperText: s.adminTotpHint,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_busy,
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(s.adminSignIn),
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
