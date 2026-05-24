import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:airwatch_mobile/core/constants/airport_full_database.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/l10n/app_strings.dart';
import 'package:airwatch_mobile/core/l10n/ui_text.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';
import 'package:airwatch_mobile/features/map/data/models/aircraft_state.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/flight_providers.dart';
import 'package:airwatch_mobile/features/map/presentation/providers/turbulence_provider.dart';
import 'package:airwatch_mobile/features/map/presentation/widgets/map_styles.dart';
import 'package:airwatch_mobile/features/voice/domain/command_parser.dart';

/// Mic button + listening indicator that turns voice commands into
/// app actions.
///
/// <p>Mirrors the web frontend's `VoiceButton.tsx`. Same parser
/// (`parseVoiceCommand` in `command_parser.dart`), same set of intents.
/// The audio path is platform-specific (`speech_to_text` package on
/// mobile, browser SpeechRecognition on the web) but the post-parse
/// command-dispatch logic is identical.
///
/// <p>Usage:
/// ```dart
/// VoiceButton(
///   onShowFlight: (callsign) {/* …*/},
/// )
/// ```
/// or stick the bare widget on the map controls strip and the default
/// dispatcher will run via Riverpod against the existing providers.
class VoiceButton extends ConsumerStatefulWidget {
  const VoiceButton({super.key, this.onShowFlight});

  /// Optional override — when the parser produces a `showFlight`
  /// intent, this callback receives the callsign so the parent can
  /// pan the map to the aircraft. When null, the button selects the
  /// matching aircraft via `selectedAircraftProvider`.
  final ValueChanged<String>? onShowFlight;

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;
  bool _listening = false;
  String _heard = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onError: (_) {},
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') {
            setState(() => _listening = false);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _available = ok;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _available = false;
      });
    }
  }

  Future<void> _toggle() async {
    if (!_available) return;
    if (_listening) {
      await _speech.stop();
      _process(_heard);
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
    });
    final lang = ref.read(languageProvider);
    final localeId = switch (lang) {
      AppLanguage.de => 'de_DE',
      AppLanguage.fr => 'fr_FR',
      AppLanguage.es => 'es_ES',
      AppLanguage.it => 'it_IT',
      AppLanguage.ar => 'ar_SA',
      AppLanguage.pl => 'pl_PL',
      AppLanguage.nl => 'nl_NL',
      AppLanguage.tr => 'tr_TR',
      AppLanguage.en => 'en_US',
    };
    await _speech.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      onResult: (res) {
        if (!mounted) return;
        setState(() => _heard = res.recognizedWords);
        if (res.finalResult) _process(_heard);
      },
    );
  }

  /// Parse and dispatch the recognised transcript.
  void _process(String transcript) {
    if (transcript.isEmpty) return;
    final lang = ref.read(languageProvider);
    final cmd = parseVoiceCommand(transcript, lang);
    if (cmd == null) return;
    _dispatch(cmd);
  }

  void _dispatch(VoiceCommand cmd) {
    switch (cmd) {
      case VShowFlight(:final callsign):
        if (widget.onShowFlight != null) {
          widget.onShowFlight!(callsign);
        } else {
          _selectByCallsign(callsign);
        }
      case VGoToAirport(:final query):
        _focusOnAirport(query);
      case VFilterCargo():
        // Toggle the cargo-only filter — second voice command flips
        // it back off, so the user doesn't have to pull up the
        // settings panel to clear the filter.
        ref.read(showCargoOnlyProvider.notifier).toggle();
      case VSetStyleDark():
        ref.read(mapStyleProvider.notifier).set(MapStyleId.dark);
      case VSetStyleLight():
        ref.read(mapStyleProvider.notifier).set(MapStyleId.toner);
      case VZoomIn():
        ref.read(mapZoomCommandProvider.notifier).zoomIn();
      case VZoomOut():
        ref.read(mapZoomCommandProvider.notifier).zoomOut();
      case VToggleRadar():
        ref.read(showRadarProvider.notifier).toggle();
      case VToggleTurbulence():
        ref.read(showTurbulenceProvider.notifier).toggle();
    }
  }

  void _selectByCallsign(String callsign) {
    final live = ref.read(aircraftStreamProvider).value;
    if (live == null) return;
    final hit = live.values.firstWhere(
      (ac) => (ac.callsign ?? '').toUpperCase() == callsign,
      orElse: () => AircraftState(icao24: ''),
    );
    if (hit.icao24.isEmpty) return;
    ref.read(selectedAircraftProvider.notifier).set(hit);
  }

  void _focusOnAirport(String query) {
    // Resolve query → IATA via the airport DB. Free-text matches:
    // exact IATA, then ICAO, then city substring.
    final q = query.trim().toUpperCase();
    if (q.length < 2) return;
    AirportEntry? hit;
    for (final apt in airportFullDatabase.values) {
      if (apt.iata == q || apt.icao == q) {
        hit = apt;
        break;
      }
      if (apt.iata.isNotEmpty && apt.city.toUpperCase().contains(q)) {
        hit ??= apt;
      }
    }
    if (hit == null) return;
    ref
        .read(mapFocusProvider.notifier)
        .focusOn(LatLng(hit.lat, hit.lon), zoom: 9);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final s = context.s;

    // Pick the label that matches the current state so the screen reader
    // announces the *current* affordance ("stop listening") rather than
    // a generic icon name.
    final String ariaLabel;
    if (!_initialized) {
      ariaLabel = s.voiceAriaInitializing;
    } else if (!_available) {
      ariaLabel = s.voiceAriaUnavailable;
    } else if (_listening) {
      ariaLabel = s.voiceAriaListening;
    } else {
      ariaLabel = s.voiceAriaIdle;
    }

    return Semantics(
      button: true,
      enabled: _initialized && _available,
      toggled: _listening,
      label: ariaLabel,
      child: GestureDetector(
        onTap: _initialized ? _toggle : null,
        behavior: HitTestBehavior.opaque,
        child: GlassPanel(
          padding: const EdgeInsets.all(10),
          borderRadius: 12,
          borderColor: _listening
              ? AppColors.error.withValues(alpha: 0.55)
              : (_available
                    ? null
                    : AppColors.textMuted.withValues(alpha: 0.25)),
          child: Icon(
            _listening
                ? Icons.mic_rounded
                : (_available
                      ? Icons.mic_none_rounded
                      : Icons.mic_off_rounded),
            size: 20,
            color: _listening
                ? AppColors.error
                : (_available ? primary : AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
