import 'strings_base.dart';

/// Turkish localisation — Stage-1 translation set.
///
/// <p>See `strings_pl.dart` header for the coverage rationale. Same
/// pattern: ~80 highest-visibility keys translated; rest fall back to
/// English via [AppStrings]. The i18n parity test has Turkish on the
/// "soft" list.
///
/// <p>Aviation Turkish uses both English loans (callsign, squawk, ATC)
/// and native vocabulary (uçak = aircraft, kalkış = departure, varış =
/// arrival). Translations here favour the native vocabulary except for
/// internationally-standardised technical terms (ICAO, IATA, FL).
class StringsTr extends AppStrings {
  // ── Primary nav ────────────────────────────────────────────────────
  @override
  String get map => 'HARİTA';
  @override
  String get search => 'ARA';
  @override
  String get airport => 'HAVAALANLARI';
  @override
  String get favs => 'KAYDEDİLEN';
  @override
  String get settings => 'AYARLAR';

  // ── Secondary nav ──────────────────────────────────────────────────
  @override
  String get airports => 'HAVAALANLARI';
  @override
  String get airlines => 'HAVAYOLLARI';
  @override
  String get cargo => 'KARGO';
  @override
  String get spotting => 'SPOTTING';
  @override
  String get dashboard => 'PANEL';
  @override
  String get globe => 'KÜRE';
  @override
  String get stats => 'İSTATİSTİKLER';
  @override
  String get more => 'DAHA FAZLA';
  @override
  String get compare => 'KARŞILAŞTIR';
  @override
  String get moreFeatures => 'Daha fazla özellik';
  @override
  String get overview => 'Genel Bakış';
  @override
  String get dashboardSubtitle => 'Kişisel genel bakış';
  @override
  String get statsSubtitle => 'Takip geçmişi';
  @override
  String get airlinesSubtitle => 'Canlı havayolu listesi';
  @override
  String get spottingShortSubtitle => 'Yakındaki uçuşlar';
  @override
  String get cargoSubtitle => 'Yalnızca kargo uçuşları';
  @override
  String get geofences => 'Geofence';
  @override
  String get geofencesSubtitle => 'Gelen uçuşlar için bölgeler';
  @override
  String get compareFlights => 'Uçuşları karşılaştır';
  @override
  String get compareSubtitle => 'Yan yana istatistikler';

  // ── Map / aircraft ─────────────────────────────────────────────────
  @override
  String get flights => 'Uçuşlar';
  @override
  String get aircraft => 'Uçaklar';
  @override
  String get altitude => 'İRTİFA';
  @override
  String get speed => 'HIZ';
  @override
  String get heading => 'YÖN';
  @override
  String get departure => 'KALKIŞ';
  @override
  String get arrival => 'VARIŞ';
  @override
  String get operatedBy => 'İşleten';
  @override
  String get track => 'TAKİP ET';
  @override
  String get replay => 'TEKRAR İZLE';
  @override
  String get history => 'GEÇMİŞ';
  @override
  String get favorite => 'KAYDET';
  @override
  String get share => 'PAYLAŞ';

  // ── Status badges ──────────────────────────────────────────────────
  @override
  String get enRoute => 'YOLDA';
  @override
  String get landed => 'İNDİ';
  @override
  String get scheduled => 'PLANLANDI';
  @override
  String get delayed => 'GECİKMELİ';
  @override
  String get onTime => 'ZAMANINDA';
  @override
  String get onGround => 'YERDE';
  @override
  String get airborne => 'HAVADA';

  // ── Common / settings ──────────────────────────────────────────────
  @override
  String get searchHint => 'Uçuş, havayolu, kayıt...';
  @override
  String get noResults => 'Sonuç yok';
  @override
  String get noFavorites => 'HENÜZ KAYITLI YOK';
  @override
  String get appearance => 'GÖRÜNÜM';
  @override
  String get mapStyle => 'HARİTA STİLİ';
  @override
  String get units => 'BİRİMLER';
  @override
  String get mapOptions => 'HARİTA SEÇENEKLERİ';
  @override
  String get dataSource => 'VERİ KAYNAĞI';
  @override
  String get language => 'DİL';
  @override
  String get airportRadar => 'HAVAALANLARI';
  @override
  String get departures => 'KALKIŞLAR';
  @override
  String get arrivals => 'VARIŞLAR';
  @override
  String get tagline => 'GÖKYÜZÜNÜ GERÇEK ZAMANLI İZLEYİN';
  @override
  String get shareText => 'Bu uçuşu AirWatch\'ta görüntüleyin.';
  @override
  String get arMode => 'AR MODU';
  @override
  String get pointSkyUp => 'Kameranı gökyüzüne doğrult';
  @override
  String get flightHistory => 'UÇUŞ GEÇMİŞİ';
  @override
  String get searchingDays => 'Son 7 gün taranıyor...';

  // ── Stats screen ───────────────────────────────────────────────────
  @override
  String get statsFlightsTracked => 'TAKİP EDİLEN UÇUŞLAR';
  @override
  String get statsAvgViewsPerFlight => 'ORT. GÖSTERİM / UÇUŞ';
  @override
  String get statsUniqueAirlines => 'HAVAYOLLARI';
  @override
  String get statsUniqueAirports => 'HAVAALANLARI';
  @override
  String get statsTrackingSince => 'TAKİP BAŞLANGICI';
  @override
  String get statsDaysActive => 'AKTİF GÜNLER';
  @override
  String get statsPeakHour => 'ZİRVE SAATİ';
  @override
  String get statsActivityChart => 'AKTİVİTE · 24S';
  @override
  String get statsTopRoutes => 'EN İYİ ROTALAR';
  @override
  String get statsTopAirports => 'EN İYİ HAVAALANLARI';
  @override
  String get statsRecentFlights => 'SON UÇUŞLAR';
  @override
  String get statsExport => 'Dışa aktar';
  @override
  String get statsExportJson => 'JSON olarak dışa aktar';
  @override
  String get statsExportCsv => 'CSV olarak dışa aktar';
  @override
  String get statsExportJsonCopied => 'JSON panoya kopyalandı';
  @override
  String get statsExportCsvCopied => 'CSV panoya kopyalandı';
  @override
  String get statsClear => 'Geçmişi sil';
  @override
  String get statsClearConfirm =>
      'Bu yerel takip geçmişinizi kalıcı olarak siler. Devam edilsin mi?';
  @override
  String get statsEmptyTitle => 'Henüz takip edilen uçuş yok';
  @override
  String get statsEmptyHint =>
      'Kişisel takip geçmişinizi başlatmak için haritadaki bir uçuşa dokunun.';

  // ── Replay ────────────────────────────────────────────────────────
  @override
  String get replayTitle => 'Tekrar İzle';
  @override
  String get replayHeading => '7 günlük uçuş tekrarı';
  @override
  String get replayBody =>
      'Son 7 günü görmek için çağrı işareti veya uçuş numarası girin — gecikmeler, planlanan ve gerçek saatler, rota.';
  @override
  String get replayHint => 'Uçuş numarası (örn. TU744)';
  @override
  String get replaySearchAction => 'Ara';
  @override
  String get replayExamples => 'Örnekler: TU744, DLH441, RYR1234';

  // ── Nearby airports ───────────────────────────────────────────────
  @override
  String get nearbyAirportsTitle => 'Yakındaki havaalanları';
  @override
  String get nearbyAirportsCta =>
      'Yakındaki havaalanlarını bulmak için konumunuzu kullanın.';
  @override
  String get useMyLocation => 'KONUMUMU KULLAN';
  @override
  String get locating => 'Konumlandırılıyor…';
  @override
  String get geoDenied => 'Konum izni reddedildi.';
  @override
  String get geoUnavailable => 'Konum hizmeti kullanılamıyor.';
  @override
  String get noNearbyAirports => 'Menzilde havaalanı yok.';

  // ── Wiki / common ─────────────────────────────────────────────────
  @override
  String get wikiAbout => 'Hakkında';
  @override
  String get wikiReadMore => 'Vikipedi\'de oku';
  @override
  String get squawkEmergencyTitle => 'Acil squawk';
  @override
  String get squawkHijack => 'Uçak kaçırma (7500)';
  @override
  String get squawkRadioFailure => 'Telsiz arızası (7600)';
  @override
  String get squawkGeneral => 'Genel acil durum (7700)';
  @override
  String get co2EstimateLabel => 'CO₂ tahmini';
  @override
  String get co2PerPaxLabel => 'yolcu başına';
  @override
  String get errorPrefix => 'Hata';
  @override
  String get retryButton => 'Tekrar dene';
  @override
  String get streetsStyle => 'Sokaklar';
  @override
  String get terrainStyle => 'Arazi';
  @override
  String get popularAirports => 'Popüler havaalanları';

  // ── AR HUD compact stat labels ─────────────────────────────────────────
  @override
  String get arHudHdg => 'YÖN';
  @override
  String get arHudPitch => 'EĞIM';
  @override
  String get arHudInView => 'GÖRÜŞTE';

  // ── Favourite kind labels ──────────────────────────────────────────────
  @override
  String get kindFlight => 'Uçuş';
  @override
  String get kindAirline => 'Havayolu';
  @override
  String get kindAirport => 'Havalimanı';

  // ── Generic UI fallbacks ───────────────────────────────────────────────
  @override
  String get errorGeneric => 'Hata';
  @override
  String get geofencesActiveCount => '{0} AKTIF';

  // ── Alert bell + sheet ─────────────────────────────────────────────────
  @override
  String get alertBellAria => 'Bildirimleri aç';
  @override
  String get alertsNone => 'Aktif uyarı yok';

  // ── Generic dialog actions ─────────────────────────────────────────────
  @override
  String get actionClose => 'Kapat';

  // ── Settings: Privacy Policy dialog ────────────────────────────────────
  @override
  String get privacyTitle => 'Gizlilik Politikası';
  @override
  String get privacyLastUpdated => 'Son güncelleme: {0} · v{1}';
  @override
  String get privacySummaryHeading => 'Özet';
  @override
  String get privacySummary1 =>
      'Hesap yok, giriş yok, kişisel veri toplanmıyor.';
  @override
  String get privacySummary2 =>
      'Reklam yok, analiz SDK\'sı yok, telemetri yok.';
  @override
  String get privacySummary3 =>
      'Üçüncü taraflarla veri satışı veya paylaşımı yok.';
  @override
  String get privacyOnDeviceHeading => 'Sadece cihazda';
  @override
  String get privacyOnDeviceLocation =>
      'Konum — haritayı ortalamak ve yakındaki uçakları bulmak için kullanılır. Asla yüklenmez.';
  @override
  String get privacyOnDeviceCamera =>
      'Kamera (AR modu) — kareler çözümlenir, çizilir ve atılır. Asla yüklenmez.';
  @override
  String get privacyOnDeviceMicrophone =>
      'Mikrofon (ses düğmesi) — OS\'nin ses tanıma motoruna teslim edilir; AirWatch\'a yalnızca metin ulaşır ve yerel olarak işlenir.';
  @override
  String get privacyOnDeviceSensors =>
      'Sensörler (pusula, ivmeölçer) — AR HUD için 10 Hz\'de okunur; asla kaydedilmez.';
  @override
  String get privacyOnDeviceStorage =>
      'Ayarlar, favoriler, geofence\'ler — SharedPreferences / NSUserDefaults aracılığıyla uygulama korumalı alanında saklanır.';
  @override
  String get privacyNetworkHeading => 'Ağ';
  @override
  String get privacyNetworkHosts =>
      'Yalnızca api.airwatch.app (TLS-pinned) ve havayolu logoları için pics.avs.io ile konuşur. Tüm host listesi budur.';
  @override
  String get privacyNetworkLogs =>
      'Backend logları hız sınırlaması için 30 gün tutulur; IP adresleri başka hiçbir veri kümesiyle birleştirilmez.';
  @override
  String get privacyRightsHeading => 'Haklarınız';
  @override
  String get privacyRightsList =>
      'Erişim, düzeltme, silme, kısıtlama, taşınabilirlik, itiraz ve onay geri çekme — privacy@airwatch.app adresine yazın.';
  @override
  String get privacyRightsComplaint =>
      'Yerel veri koruma kurumunuza şikâyette bulunma hakkı.';
  @override
  String get privacyFullTextHeading => 'Tam metin';
  @override
  String get privacyFullTextRef =>
      'Üçüncü taraf kaynakları ve uluslararası aktarımlar dahil tam politika için depodaki PRIVACY.md dosyasına bakın.';
  // ── Aviation: METAR / TAF micro-labels ─────────────────────────────────
  @override
  String get metarTafValidPrefix => 'Geçerli {0} → {1}';
  @override
  String get metarTafNow => 'ŞİMDİ';

  // ── Geofences: FAB action labels ───────────────────────────────────────
  @override
  String get geofencesDrawFab => 'ÇİZ';
  @override
  String get geofencesFormFabAria => 'Koordinatla bölge ekle';
}
