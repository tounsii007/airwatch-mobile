/// Open-Meteo weather code → emoji.
///
/// <p>Single source of truth for the platform's "what does code N look
/// like" mapping. Mirrors airwatch-web's `getWeatherEmoji` so a user
/// moving between the two clients sees the same glyph for the same
/// code at the same time-of-day.
///
/// <p>Used by:
/// <ul>
///   <li>the map's airport-label layer (small emoji next to the IATA),</li>
///   <li>the airport-detail screen's weather card (large temperature
///       readout),</li>
///   <li>any future surface that wants a weather-aware glyph.</li>
/// </ul>
///
/// <p>[isDay] only affects the clear-sky branch (☀️ ↔ 🌙). All other
/// codes have an identical look at night and day per WMO convention.
/// Returns a thermometer for an unknown / null code so the caller
/// never has to special-case "no data".
String getWeatherEmoji(int? code, bool isDay) {
  if (code == null) return '🌡️';
  if (code == 0) return isDay ? '☀️' : '🌙';
  if (code <= 3) return isDay ? '⛅' : '☁️';
  if (code <= 49) return '🌫️'; // fog / mist
  if (code <= 59) return '🌦️'; // drizzle
  if (code <= 69) return '🌧️'; // rain
  if (code <= 79) return '🌨️'; // snow
  if (code <= 82) return '🌧️'; // rain showers
  if (code <= 86) return '🌨️'; // snow showers
  if (code >= 95) return '⛈️'; // thunderstorm
  return '☁️';
}
