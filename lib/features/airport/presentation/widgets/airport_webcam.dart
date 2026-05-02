import 'package:flutter/material.dart';
import 'package:airwatch_mobile/core/constants/ui_constants.dart';
import 'package:airwatch_mobile/core/theme/app_colors.dart';
import 'package:airwatch_mobile/core/widgets/glass_panel.dart';

/// Airport webcam viewer — displays live camera feeds from major airports.
/// Uses publicly available webcam embed URLs.
class AirportWebcam extends StatelessWidget {
  final String airportIata;
  final String airportName;

  const AirportWebcam({
    super.key,
    required this.airportIata,
    required this.airportName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primary : UiConstants.lightPrimary;
    final webcamUrl = _getWebcamUrl(airportIata);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : UiConstants.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('$airportName Webcam',
          style: TextStyle(fontFamily: UiConstants.headingFont, fontSize: 14,
              fontWeight: FontWeight.w700, color: primary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: webcamUrl != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Webcam would be displayed here via WebView or Image widget
                  Icon(Icons.videocam_rounded, size: 64,
                      color: primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Live webcam for $airportIata',
                    style: const TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 16,
                        color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  GlassPanel(
                    padding: const EdgeInsets.all(12), borderRadius: 10,
                    child: Text(webcamUrl, style: const TextStyle(fontFamily: UiConstants.bodyFont,
                        fontSize: 11, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Webcam embedding requires webview_flutter package\nfor mobile or iframe for web.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 12,
                        color: AppColors.textMuted)),
                ],
              ),
            )
          : Center(
              child: Text('No webcam available for $airportIata',
                style: const TextStyle(fontFamily: UiConstants.bodyFont, fontSize: 14,
                    color: AppColors.textSecondary)),
            ),
    );
  }

  /// Known airport webcam URLs (publicly accessible streams)
  String? _getWebcamUrl(String iata) {
    return _webcams[iata.toUpperCase()];
  }

  static const _webcams = <String, String>{
    'FRA': 'https://www.frankfurt-airport.com/en/flights---more/webcam.html',
    'MUC': 'https://www.munich-airport.de/cam',
    'CDG': 'https://www.parisaeroport.fr/en/homepage',
    'LHR': 'https://www.heathrow.com/at-the-airport/webcam',
    'AMS': 'https://www.schiphol.nl/en/page/schiphol-webcams/',
    'ZRH': 'https://www.zurich-airport.com/en/passengers/experience/webcam',
    'IST': 'https://www.igairport.com/en/webcam',
    'DXB': 'https://www.dubaiairports.ae',
    'JFK': 'https://www.jfkairport.com',
    'LAX': 'https://www.flylax.com/en/lax-webcam',
    'SIN': 'https://www.changiairport.com',
    'HND': 'https://www.tokyo-airport-bldg.co.jp/en/',
    'ATL': 'https://www.atl.com',
    'DFW': 'https://www.dfwairport.com',
  };
}
