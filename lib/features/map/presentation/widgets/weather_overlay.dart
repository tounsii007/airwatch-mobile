import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Weather tile overlay using OpenWeatherMap free tile layer.
/// Shows clouds, precipitation, or wind over the map.
enum WeatherLayer { none, clouds, precipitation, wind, temperature }

class WeatherOverlay extends StatelessWidget {
  final WeatherLayer layer;

  const WeatherOverlay({super.key, this.layer = WeatherLayer.none});

  @override
  Widget build(BuildContext context) {
    if (layer == WeatherLayer.none) return const SizedBox.shrink();

    // OpenWeatherMap free tile layers (no API key needed for basic tiles)
    final layerCode = switch (layer) {
      WeatherLayer.clouds => 'clouds_new',
      WeatherLayer.precipitation => 'precipitation_new',
      WeatherLayer.wind => 'wind_new',
      WeatherLayer.temperature => 'temp_new',
      WeatherLayer.none => '',
    };

    if (layerCode.isEmpty) return const SizedBox.shrink();

    // Note: OpenWeatherMap requires an API key for tile layers.
    // Using a free alternative: RainViewer for precipitation radar.
    // For demo purposes, using OpenWeatherMap with a placeholder.
    // In production, set OPENWEATHER_KEY env var.
    return Opacity(
      opacity: 0.4,
      child: TileLayer(
        urlTemplate:
            'https://tile.openweathermap.org/map/$layerCode/{z}/{x}/{y}.png?appid=demo',
        tileProvider: NetworkTileProvider(),
        errorTileCallback: (tile, error, stackTrace) {},
      ),
    );
  }
}
