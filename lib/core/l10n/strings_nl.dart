import 'strings_base.dart';

/// Dutch localisation — Stage-1 translation set.
///
/// <p>See `strings_pl.dart` header for the coverage rationale — same
/// approach: ~80 high-visibility keys translated to native Dutch, rest
/// falls back to English via the abstract base. The i18n parity test
/// has Dutch on the "soft" list, so missing keys flag a warning
/// rather than a fail.
///
/// <p>Aviation Dutch is fairly Anglicised in practice; common cockpit /
/// schedule terms (track, replay, squawk, ICAO) often stay in English
/// even in Dutch-language interfaces. Translations here lean towards
/// formal Dutch rather than colloquial.
class StringsNl extends AppStrings {
  // ── Primary nav ────────────────────────────────────────────────────
  @override
  String get map => 'KAART';
  @override
  String get search => 'ZOEKEN';
  @override
  String get airport => 'LUCHTHAVENS';
  @override
  String get favs => 'OPGESLAGEN';
  @override
  String get settings => 'INSTELLINGEN';

  // ── Secondary nav ──────────────────────────────────────────────────
  @override
  String get airports => 'LUCHTHAVENS';
  @override
  String get airlines => 'LUCHTVAART';
  @override
  String get cargo => 'VRACHT';
  @override
  String get spotting => 'SPOTTING';
  @override
  String get dashboard => 'DASHBOARD';
  @override
  String get globe => 'GLOBE';
  @override
  String get stats => 'STATISTIEKEN';
  @override
  String get more => 'MEER';
  @override
  String get compare => 'VERGELIJK';
  @override
  String get moreFeatures => 'Meer functies';
  @override
  String get overview => 'Overzicht';
  @override
  String get dashboardSubtitle => 'Persoonlijk overzicht';
  @override
  String get statsSubtitle => 'Volg-geschiedenis';
  @override
  String get airlinesSubtitle => 'Live carrier-lijst';
  @override
  String get spottingShortSubtitle => 'Vluchten in de buurt';
  @override
  String get cargoSubtitle => 'Alleen vrachtvluchten';
  @override
  String get geofences => 'Geofences';
  @override
  String get geofencesSubtitle => 'Zones voor inkomende vluchten';
  @override
  String get compareFlights => 'Vluchten vergelijken';
  @override
  String get compareSubtitle => 'Statistieken naast elkaar';

  // ── Map / aircraft ─────────────────────────────────────────────────
  @override
  String get flights => 'Vluchten';
  @override
  String get aircraft => 'Vliegtuigen';
  @override
  String get altitude => 'HOOGTE';
  @override
  String get speed => 'SNELHEID';
  @override
  String get heading => 'KOERS';
  @override
  String get departure => 'VERTREK';
  @override
  String get arrival => 'AANKOMST';
  @override
  String get operatedBy => 'Uitgevoerd door';
  @override
  String get track => 'VOLG';
  @override
  String get replay => 'REPLAY';
  @override
  String get history => 'HISTORIE';
  @override
  String get favorite => 'OPSLAAN';
  @override
  String get share => 'DELEN';

  // ── Status badges ──────────────────────────────────────────────────
  @override
  String get enRoute => 'ONDERWEG';
  @override
  String get landed => 'GELAND';
  @override
  String get scheduled => 'GEPLAND';
  @override
  String get delayed => 'VERTRAAGD';
  @override
  String get onTime => 'OP TIJD';
  @override
  String get onGround => 'OP DE GROND';
  @override
  String get airborne => 'IN DE LUCHT';

  // ── Common / settings ──────────────────────────────────────────────
  @override
  String get searchHint => 'Vlucht, luchtvaart, registratie...';
  @override
  String get noResults => 'Geen resultaten';
  @override
  String get noFavorites => 'NOG NIETS OPGESLAGEN';
  @override
  String get appearance => 'WEERGAVE';
  @override
  String get mapStyle => 'KAARTSTIJL';
  @override
  String get units => 'EENHEDEN';
  @override
  String get mapOptions => 'KAARTOPTIES';
  @override
  String get dataSource => 'GEGEVENSBRON';
  @override
  String get language => 'TAAL';
  @override
  String get airportRadar => 'LUCHTHAVENS';
  @override
  String get departures => 'VERTREKKEN';
  @override
  String get arrivals => 'AANKOMSTEN';
  @override
  String get tagline => 'VOLG DE HEMEL IN REAL-TIME';
  @override
  String get shareText => 'Bekijk deze vlucht in AirWatch.';
  @override
  String get arMode => 'AR-MODUS';
  @override
  String get pointSkyUp => 'Richt je camera op de hemel';
  @override
  String get flightHistory => 'VLUCHTHISTORIE';
  @override
  String get searchingDays => 'Bezig met zoeken in de laatste 7 dagen...';

  // ── Stats screen ───────────────────────────────────────────────────
  @override
  String get statsFlightsTracked => 'GEVOLGDE VLUCHTEN';
  @override
  String get statsAvgViewsPerFlight => 'GEM. VIEWS / VLUCHT';
  @override
  String get statsUniqueAirlines => 'LUCHTVAART';
  @override
  String get statsUniqueAirports => 'LUCHTHAVENS';
  @override
  String get statsTrackingSince => 'VOLGEN SINDS';
  @override
  String get statsDaysActive => 'ACTIEVE DAGEN';
  @override
  String get statsPeakHour => 'PIEK';
  @override
  String get statsActivityChart => 'ACTIVITEIT · 24U';
  @override
  String get statsTopRoutes => 'TOP-ROUTES';
  @override
  String get statsTopAirports => 'TOP-LUCHTHAVENS';
  @override
  String get statsRecentFlights => 'RECENTE VLUCHTEN';
  @override
  String get statsExport => 'Exporteer';
  @override
  String get statsExportJson => 'Exporteer als JSON';
  @override
  String get statsExportCsv => 'Exporteer als CSV';
  @override
  String get statsExportJsonCopied => 'JSON gekopieerd naar klembord';
  @override
  String get statsExportCsvCopied => 'CSV gekopieerd naar klembord';
  @override
  String get statsClear => 'Wis historie';
  @override
  String get statsClearConfirm =>
      'Hiermee wordt je lokale volg-historie permanent verwijderd. Doorgaan?';
  @override
  String get statsEmptyTitle => 'Nog geen gevolgde vluchten';
  @override
  String get statsEmptyHint =>
      'Tik op een vlucht op de kaart om je persoonlijke volg-historie te starten.';

  // ── Replay ────────────────────────────────────────────────────────
  @override
  String get replayTitle => 'Replay';
  @override
  String get replayHeading => '7-daagse vlucht-replay';
  @override
  String get replayBody =>
      'Voer een callsign of vluchtnummer in om de laatste 7 dagen te zien — inclusief vertragingen, geplande vs. werkelijke tijden en route.';
  @override
  String get replayHint => 'Vluchtnummer (bijv. TU744)';
  @override
  String get replaySearchAction => 'Zoeken';
  @override
  String get replayExamples => 'Voorbeelden: TU744, DLH441, RYR1234';

  // ── Nearby airports ───────────────────────────────────────────────
  @override
  String get nearbyAirportsTitle => 'Luchthavens in de buurt';
  @override
  String get nearbyAirportsCta =>
      'Gebruik je locatie om nabijgelegen luchthavens te vinden.';
  @override
  String get useMyLocation => 'GEBRUIK MIJN LOCATIE';
  @override
  String get locating => 'Bezig met lokaliseren…';
  @override
  String get geoDenied => 'Locatietoestemming geweigerd.';
  @override
  String get geoUnavailable => 'Locatieservice niet beschikbaar.';
  @override
  String get noNearbyAirports => 'Geen luchthavens binnen bereik.';

  // ── Wiki / common ─────────────────────────────────────────────────
  @override
  String get wikiAbout => 'Over';
  @override
  String get wikiReadMore => 'Lees op Wikipedia';
  @override
  String get squawkEmergencyTitle => 'Noodsquawk';
  @override
  String get squawkHijack => 'Kaping (7500)';
  @override
  String get squawkRadioFailure => 'Radiostoring (7600)';
  @override
  String get squawkGeneral => 'Algemeen noodgeval (7700)';
  @override
  String get co2EstimateLabel => 'CO₂-schatting';
  @override
  String get co2PerPaxLabel => 'per passagier';
  @override
  String get errorPrefix => 'Fout';
  @override
  String get retryButton => 'Opnieuw';
  @override
  String get streetsStyle => 'Straten';
  @override
  String get terrainStyle => 'Terrein';
  @override
  String get popularAirports => 'Populaire luchthavens';

  // ── AR HUD compact stat labels ─────────────────────────────────────────
  @override
  String get arHudHdg => 'KOERS';
  @override
  String get arHudPitch => 'PITCH';
  @override
  String get arHudInView => 'IN BEELD';

  // ── Favourite kind labels ──────────────────────────────────────────────
  @override
  String get kindFlight => 'Vlucht';
  @override
  String get kindAirline => 'Luchtvaartmij.';
  @override
  String get kindAirport => 'Luchthaven';

  // ── Generic UI fallbacks ───────────────────────────────────────────────
  @override
  String get errorGeneric => 'Fout';
  @override
  String get geofencesActiveCount => '{0} ACTIEF';

  // ── Alert bell + sheet ─────────────────────────────────────────────────
  @override
  String get alertBellAria => 'Open meldingenpaneel';
  @override
  String get alertsNone => 'Geen actieve meldingen';

  // ── Generic dialog actions ─────────────────────────────────────────────
  @override
  String get actionClose => 'Sluiten';

  // ── Settings: Privacy Policy dialog ────────────────────────────────────
  @override
  String get privacyTitle => 'Privacybeleid';
  @override
  String get privacyLastUpdated => 'Laatst bijgewerkt: {0} · v{1}';
  @override
  String get privacySummaryHeading => 'Samenvatting';
  @override
  String get privacySummary1 =>
      'Geen accounts, geen logins, geen verzameling van persoonsgegevens.';
  @override
  String get privacySummary2 =>
      'Geen advertenties, geen analytics-SDK\'s, geen telemetrie.';
  @override
  String get privacySummary3 => 'Geen verkoop of deling van data met derden.';
  @override
  String get privacyOnDeviceHeading => 'Alleen op het apparaat';
  @override
  String get privacyOnDeviceLocation =>
      'Locatie — gebruikt om de kaart te centreren en nabije vliegtuigen te vinden. Wordt nooit geüpload.';
  @override
  String get privacyOnDeviceCamera =>
      'Camera (AR-modus) — frames worden gedecodeerd, getekend en weggegooid. Nooit geüpload.';
  @override
  String get privacyOnDeviceMicrophone =>
      'Microfoon (spraakknop) — doorgegeven aan de spraakherkenning van het OS; alleen het transcript bereikt AirWatch, lokaal verwerkt.';
  @override
  String get privacyOnDeviceSensors =>
      'Sensoren (kompas, accelerometer) — uitgelezen op 10 Hz voor de AR-HUD; nooit opgeslagen.';
  @override
  String get privacyOnDeviceStorage =>
      'Instellingen, favorieten, geofences — opgeslagen in de app-sandbox via SharedPreferences / NSUserDefaults.';
  @override
  String get privacyNetworkHeading => 'Netwerk';
  @override
  String get privacyNetworkHosts =>
      'Praat alleen met api.airwatch.app (TLS-pinned) en pics.avs.io voor logo\'s. Dat is de complete hostlijst.';
  @override
  String get privacyNetworkLogs =>
      'Backend-logs worden 30 dagen bewaard voor rate-limiting; IP-adressen worden met geen enkele andere dataset gecombineerd.';
  @override
  String get privacyRightsHeading => 'Jouw rechten';
  @override
  String get privacyRightsList =>
      'Inzage, rectificatie, wissing, beperking, overdraagbaarheid, bezwaar en intrekking van toestemming — schrijf naar privacy@airwatch.app.';
  @override
  String get privacyRightsComplaint =>
      'Recht om een klacht in te dienen bij je lokale gegevensbeschermingsautoriteit.';
  @override
  String get privacyFullTextHeading => 'Volledige tekst';
  @override
  String get privacyFullTextRef =>
      'Zie PRIVACY.md in de repository voor het volledige beleid, inclusief externe gegevensbronnen en internationale overdrachten.';
  // ── Aviation: METAR / TAF micro-labels ─────────────────────────────────
  @override
  String get metarTafValidPrefix => 'Geldig {0} → {1}';
  @override
  String get metarTafNow => 'NU';

  // ── Geofences: FAB action labels ───────────────────────────────────────
  @override
  String get geofencesDrawFab => 'TEKENEN';
  @override
  String get geofencesFormFabAria => 'Zone via coördinaten toevoegen';
  // ── Map controls (a11y aria-labels) ────────────────────────────────────
  @override
  String get mapAriaSearch => 'Open zoeken';
  @override
  String get mapAriaZoomIn => 'Inzoomen';
  @override
  String get mapAriaZoomOut => 'Uitzoomen';
  @override
  String get mapAriaMyLocation => 'Centreer op mijn locatie';
  @override
  String get mapAriaCargoToggle => 'Alleen vrachtvluchten';
  @override
  String get alertTileHint => 'Dubbel tikken om op de kaart te tonen';
}
