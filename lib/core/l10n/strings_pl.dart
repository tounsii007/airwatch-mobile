import 'strings_base.dart';

/// Polish localisation — Stage-1 translation set.
///
/// <p>Covers ~80 high-visibility keys (nav, buttons, status badges,
/// form labels, common screen titles) with native Polish translations.
/// The remaining technical / admin / help-text keys fall back to the
/// English defaults provided by [AppStrings] — that's an explicit v1
/// trade-off the i18n parity test understands (Polish is on the
/// "soft" list there).
///
/// <p>Translations are tuned for civil aviation context — "lot" for
/// flight, "lotnisko" for airport, etc. Technical terms (FL, ICAO,
/// IATA) stay as-is since they're international.
class StringsPl extends AppStrings {
  // ── Primary nav ────────────────────────────────────────────────────
  @override
  String get map => 'MAPA';
  @override
  String get search => 'SZUKAJ';
  @override
  String get airport => 'LOTNISKA';
  @override
  String get favs => 'ZAPISANE';
  @override
  String get settings => 'USTAWIENIA';

  // ── Secondary nav (More sheet) ─────────────────────────────────────
  @override
  String get airports => 'LOTNISKA';
  @override
  String get airlines => 'LINIE LOTNICZE';
  @override
  String get cargo => 'CARGO';
  @override
  String get spotting => 'SPOTTING';
  @override
  String get dashboard => 'PANEL';
  @override
  String get globe => 'GLOBUS';
  @override
  String get stats => 'STATYSTYKI';
  @override
  String get more => 'WIĘCEJ';
  @override
  String get compare => 'PORÓWNAJ';
  @override
  String get moreFeatures => 'Więcej funkcji';
  @override
  String get overview => 'Przegląd';
  @override
  String get dashboardSubtitle => 'Twój pulpit';
  @override
  String get statsSubtitle => 'Historia śledzenia';
  @override
  String get airlinesSubtitle => 'Lista przewoźników na żywo';
  @override
  String get spottingShortSubtitle => 'Loty w pobliżu';
  @override
  String get cargoSubtitle => 'Tylko loty cargo';
  @override
  String get geofences => 'Geofence';
  @override
  String get geofencesSubtitle => 'Strefy dla nadlatujących maszyn';
  @override
  String get compareFlights => 'Porównaj loty';
  @override
  String get compareSubtitle => 'Porównanie statystyk obok siebie';

  // ── Map / aircraft basics ──────────────────────────────────────────
  @override
  String get flights => 'Loty';
  @override
  String get aircraft => 'Samoloty';
  @override
  String get altitude => 'WYSOKOŚĆ';
  @override
  String get speed => 'PRĘDKOŚĆ';
  @override
  String get heading => 'KURS';
  @override
  String get departure => 'ODLOT';
  @override
  String get arrival => 'PRZYLOT';
  @override
  String get operatedBy => 'Obsługiwane przez';
  @override
  String get track => 'ŚLEDŹ';
  @override
  String get replay => 'POWTÓRKA';
  @override
  String get history => 'HISTORIA';
  @override
  String get favorite => 'ZAPISZ';
  @override
  String get share => 'UDOSTĘPNIJ';

  // ── Status badges ──────────────────────────────────────────────────
  @override
  String get enRoute => 'W TRASIE';
  @override
  String get landed => 'WYLĄDOWAŁ';
  @override
  String get scheduled => 'ZAPLANOWANY';
  @override
  String get delayed => 'OPÓŹNIONY';
  @override
  String get onTime => 'NA CZAS';
  @override
  String get onGround => 'NA ZIEMI';
  @override
  String get airborne => 'W POWIETRZU';

  // ── Common actions / shared screens ────────────────────────────────
  @override
  String get searchHint => 'Lot, linia, rejestracja...';
  @override
  String get noResults => 'Brak wyników';
  @override
  String get noFavorites => 'JESZCZE NIC NIE ZAPISANO';
  @override
  String get appearance => 'WYGLĄD';
  @override
  String get mapStyle => 'STYL MAPY';
  @override
  String get units => 'JEDNOSTKI';
  @override
  String get mapOptions => 'OPCJE MAPY';
  @override
  String get dataSource => 'ŹRÓDŁO DANYCH';
  @override
  String get language => 'JĘZYK';
  @override
  String get airportRadar => 'LOTNISKA';
  @override
  String get departures => 'ODLOTY';
  @override
  String get arrivals => 'PRZYLOTY';
  @override
  String get tagline => 'ŚLEDŹ NIEBO W CZASIE RZECZYWISTYM';
  @override
  String get shareText => 'Zobacz ten lot w AirWatch.';
  @override
  String get arMode => 'TRYB AR';
  @override
  String get pointSkyUp => 'Skieruj kamerę w niebo';
  @override
  String get flightHistory => 'HISTORIA LOTÓW';
  @override
  String get searchingDays => 'Przeszukiwanie ostatnich 7 dni...';

  // ── Stats screen ───────────────────────────────────────────────────
  @override
  String get statsFlightsTracked => 'ŚLEDZONE LOTY';
  @override
  String get statsAvgViewsPerFlight => 'ŚR. WYŚWIETLEŃ / LOT';
  @override
  String get statsUniqueAirlines => 'LINIE';
  @override
  String get statsUniqueAirports => 'LOTNISKA';
  @override
  String get statsTrackingSince => 'ŚLEDZONE OD';
  @override
  String get statsDaysActive => 'AKTYWNE DNI';
  @override
  String get statsPeakHour => 'GODZ. SZCZYTU';
  @override
  String get statsActivityChart => 'AKTYWNOŚĆ · 24H';
  @override
  String get statsTopRoutes => 'NAJLEPSZE TRASY';
  @override
  String get statsTopAirports => 'NAJLEPSZE LOTNISKA';
  @override
  String get statsRecentFlights => 'OSTATNIE LOTY';
  @override
  String get statsExport => 'Eksportuj';
  @override
  String get statsExportJson => 'Eksportuj jako JSON';
  @override
  String get statsExportCsv => 'Eksportuj jako CSV';
  @override
  String get statsExportJsonCopied => 'JSON skopiowano do schowka';
  @override
  String get statsExportCsvCopied => 'CSV skopiowano do schowka';
  @override
  String get statsClear => 'Wyczyść historię';
  @override
  String get statsClearConfirm =>
      'To trwale usunie Twoją lokalną historię śledzenia. Kontynuować?';
  @override
  String get statsEmptyTitle => 'Brak śledzonych lotów';
  @override
  String get statsEmptyHint =>
      'Dotknij lotu na mapie, aby rozpocząć osobistą historię śledzenia.';

  // ── Replay landing ────────────────────────────────────────────────
  @override
  String get replayTitle => 'Powtórka';
  @override
  String get replayHeading => '7-dniowa powtórka lotu';
  @override
  String get replayBody =>
      'Podaj numer lotu lub znak wywoławczy, aby zobaczyć ostatnie 7 dni — opóźnienia, czasy planowane vs. rzeczywiste, oraz trasę.';
  @override
  String get replayHint => 'Numer lotu (np. TU744)';
  @override
  String get replaySearchAction => 'Szukaj';
  @override
  String get replayExamples => 'Przykłady: TU744, DLH441, RYR1234';

  // ── Nearby airports ───────────────────────────────────────────────
  @override
  String get nearbyAirportsTitle => 'Lotniska w pobliżu';
  @override
  String get nearbyAirportsCta =>
      'Użyj swojej lokalizacji, aby znaleźć pobliskie lotniska.';
  @override
  String get useMyLocation => 'UŻYJ MOJEJ LOKALIZACJI';
  @override
  String get locating => 'Lokalizowanie…';
  @override
  String get geoDenied => 'Brak zgody na lokalizację.';
  @override
  String get geoUnavailable => 'Usługa lokalizacji niedostępna.';
  @override
  String get noNearbyAirports => 'Brak lotnisk w zasięgu.';

  // ── Wiki ──────────────────────────────────────────────────────────
  @override
  String get wikiAbout => 'O lotnisku';
  @override
  String get wikiReadMore => 'Czytaj na Wikipedii';

  // ── Squawk emergency ──────────────────────────────────────────────
  @override
  String get squawkEmergencyTitle => 'Squawk awaryjny';
  @override
  String get squawkHijack => 'Porwanie (7500)';
  @override
  String get squawkRadioFailure => 'Awaria radia (7600)';
  @override
  String get squawkGeneral => 'Ogólny stan awaryjny (7700)';

  // ── CO2 / common ──────────────────────────────────────────────────
  @override
  String get co2EstimateLabel => 'Szacunkowy CO₂';
  @override
  String get co2PerPaxLabel => 'na pasażera';
  @override
  String get errorPrefix => 'Błąd';
  @override
  String get retryButton => 'Ponów';
  @override
  String get streetsStyle => 'Ulice';
  @override
  String get terrainStyle => 'Teren';
  @override
  String get popularAirports => 'Popularne lotniska';

  // ── AR HUD compact stat labels ─────────────────────────────────────────
  @override
  String get arHudHdg => 'KURS';
  @override
  String get arHudPitch => 'POCH.';
  @override
  String get arHudInView => 'W KADRZE';

  // ── Favourite kind labels ──────────────────────────────────────────────
  @override
  String get kindFlight => 'Lot';
  @override
  String get kindAirline => 'Linia lotnicza';
  @override
  String get kindAirport => 'Lotnisko';

  // ── Generic UI fallbacks ───────────────────────────────────────────────
  @override
  String get errorGeneric => 'Błąd';
  @override
  String get geofencesActiveCount => '{0} AKTYWNE';

  // ── Alert bell + sheet ─────────────────────────────────────────────────
  @override
  String get alertBellAria => 'Otwórz panel alertów';
  @override
  String get alertsNone => 'Brak aktywnych alertów';

  // ── Generic dialog actions ─────────────────────────────────────────────
  @override
  String get actionClose => 'Zamknij';

  // ── Settings: Privacy Policy dialog ────────────────────────────────────
  @override
  String get privacyTitle => 'Polityka prywatności';
  @override
  String get privacyLastUpdated => 'Ostatnia aktualizacja: {0} · v{1}';
  @override
  String get privacySummaryHeading => 'Podsumowanie';
  @override
  String get privacySummary1 =>
      'Brak kont, brak logowania, żadnych danych osobowych.';
  @override
  String get privacySummary2 =>
      'Bez reklam, bez SDK analitycznych, bez telemetrii.';
  @override
  String get privacySummary3 =>
      'Bez sprzedaży ani udostępniania danych stronom trzecim.';
  @override
  String get privacyOnDeviceHeading => 'Tylko na urządzeniu';
  @override
  String get privacyOnDeviceLocation =>
      'Lokalizacja — używana do wyśrodkowania mapy i znalezienia samolotów w pobliżu. Nigdy nie jest wysyłana.';
  @override
  String get privacyOnDeviceCamera =>
      'Kamera (tryb AR) — klatki są dekodowane, rysowane i odrzucane. Nigdy nie są wysyłane.';
  @override
  String get privacyOnDeviceMicrophone =>
      'Mikrofon (przycisk głosu) — przekazany do systemowego rozpoznawania mowy; do AirWatch trafia tylko transkrypcja, przetwarzana lokalnie.';
  @override
  String get privacyOnDeviceSensors =>
      'Czujniki (kompas, akcelerometr) — odczytywane z częstotliwością 10 Hz dla HUD AR; nigdy nie zapisywane.';
  @override
  String get privacyOnDeviceStorage =>
      'Ustawienia, ulubione, geofences — zapisane w piaskownicy aplikacji przez SharedPreferences / NSUserDefaults.';
  @override
  String get privacyNetworkHeading => 'Sieć';
  @override
  String get privacyNetworkHosts =>
      'Łączy się tylko z api.airwatch.app (TLS-pinned) i pics.avs.io dla logo linii. To cała lista hostów.';
  @override
  String get privacyNetworkLogs =>
      'Logi backendu są przechowywane 30 dni dla limitów; adresy IP nie są łączone z żadnym innym zbiorem danych.';
  @override
  String get privacyRightsHeading => 'Twoje prawa';
  @override
  String get privacyRightsList =>
      'Dostęp, sprostowanie, usunięcie, ograniczenie, przenoszenie, sprzeciw i wycofanie zgody — pisz na privacy@airwatch.app.';
  @override
  String get privacyRightsComplaint =>
      'Prawo do złożenia skargi do lokalnego organu ochrony danych.';
  @override
  String get privacyFullTextHeading => 'Pełny tekst';
  @override
  String get privacyFullTextRef =>
      'Zobacz PRIVACY.md w repozytorium, aby zapoznać się z pełną polityką, w tym źródłami zewnętrznymi i transferami międzynarodowymi.';
}
