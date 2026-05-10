import 'strings_base.dart';

/// Arabic locale — parity with airwatch-web's ar.json (commit d0a7598).
///
/// <p>Aviation jargon (METAR, TAF, NOTAM, ICAO, IATA, squawk, AirWatch)
/// stays in its de-facto international form — same convention used
/// by every other locale.
///
/// <p>The text-direction flip happens at the [Directionality] level
/// in [app.dart] via [isRtl] from `core/utils/rtl.dart`; this file
/// only carries the strings.
class StringsAr extends AppStrings {
  @override
  String get map => 'الخريطة';
  @override
  String get search => 'بحث';
  @override
  String get airport => 'المطارات';
  @override
  String get favs => 'المحفوظة';
  @override
  String get settings => 'الإعدادات';

  @override
  String get flights => 'رحلات';
  @override
  String get aircraft => 'طائرات';

  @override
  String get altitude => 'الارتفاع';
  @override
  String get speed => 'السرعة';
  @override
  String get heading => 'الاتجاه';
  @override
  String get departure => 'المغادرة';
  @override
  String get arrival => 'الوصول';
  @override
  String get operatedBy => 'تشغيل بواسطة';
  @override
  String get track => 'تتبع';
  @override
  String get replay => 'إعادة';
  @override
  String get history => 'السجل';
  @override
  String get favorite => 'حفظ';
  @override
  String get share => 'مشاركة';

  @override
  String get enRoute => 'في الطريق';
  @override
  String get landed => 'هبطت';
  @override
  String get scheduled => 'مجدولة';
  @override
  String get delayed => 'متأخرة';
  @override
  String get onTime => 'في الموعد';
  @override
  String get onGround => 'على الأرض';
  @override
  String get airborne => 'في الجو';

  @override
  String get searchHint => 'رحلة، شركة، تسجيل...';
  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get appearance => 'المظهر';
  @override
  String get mapStyle => 'نمط الخريطة';
  @override
  String get units => 'الوحدات';
  @override
  String get mapOptions => 'خيارات الخريطة';
  @override
  String get dataSource => 'مصدر البيانات';
  @override
  String get language => 'اللغة';

  @override
  String get flightHistory => 'سجل الرحلة';
  @override
  String get searchingDays => 'البحث في آخر 7 أيام...';

  @override
  String get airportRadar => 'المطارات';
  @override
  String get departures => 'المغادرات';
  @override
  String get arrivals => 'الوصول';

  @override
  String get tagline => 'تتبع السماء في الوقت الفعلي';

  @override
  String get shareText => 'شاهد هذه الرحلة في AirWatch.';

  @override
  String get noFavorites => 'لا شيء محفوظ بعد';

  @override
  String get arMode => 'وضع الواقع المعزز';
  @override
  String get pointSkyUp => 'وجه الكاميرا نحو السماء';

  @override
  String get airports => 'المطارات';
  @override
  String get airlines => 'شركات الطيران';
  @override
  String get cargo => 'الشحن';
  @override
  String get spotting => 'الرصد';
  @override
  String get dashboard => 'لوحة التحكم';
  @override
  String get globe => 'الكرة الأرضية';
  @override
  String get stats => 'الإحصائيات';

  @override
  String get streetsStyle => 'الشوارع';
  @override
  String get terrainStyle => 'التضاريس';

  @override
  String get adminLogin => 'تسجيل دخول المسؤول';
  @override
  String get adminDashboard => 'المسؤول';
  @override
  String get adminUsername => 'اسم المستخدم';
  @override
  String get adminPassword => 'كلمة المرور';
  @override
  String get adminSignIn => 'تسجيل الدخول';
  @override
  String get adminSignOut => 'تسجيل الخروج';
  @override
  String get adminHealth => 'الحالة';
  @override
  String get adminMetrics => 'مقاييس مباشرة';
  @override
  String get adminRpsLabel => 'طلبات / ثانية';
  @override
  String get adminActive => 'الجلسات النشطة';
  @override
  String get adminHeap => 'استخدام الذاكرة';
  @override
  String get adminBadCreds => 'اسم المستخدم أو كلمة المرور غير صحيحة';
  @override
  String get adminTotpLabel => 'TOTP (اختياري)';
  @override
  String get adminTotpHint =>
      'مطلوب فقط إذا تم تفعيل المصادقة الثنائية لهذا الحساب';
  @override
  String get adminErrorRate => 'الأخطاء %';
  @override
  String get adminTotalReqs => 'إجمالي طلبات الواجهة الخلفية';
  @override
  String get adminFlightsKpi => 'الرحلات';
  @override
  String get adminOffline => 'غير متصل بـ airwatch-api';
  @override
  String get adminOfflineHint =>
      'قد تكون الجلسة منتهية الصلاحية أو الواجهة الخلفية غير متاحة. '
      'اضغط على تسجيل الخروج وأعد الدخول.';

  @override
  String get noAirlinesActive => 'لا توجد شركات طيران بها رحلات في الجو الآن';
  @override
  String get airlinesCarriers => 'قائمة شركات الطيران المباشرة';
  @override
  String get airlinesFlightOne => 'رحلة';
  @override
  String get airlinesFlightMany => 'رحلات';
  @override
  String get noCargoActive => 'لا توجد رحلات شحن في الجو الآن';
  @override
  String get cargoSubtitle => 'رحلات الشحن فقط';
  @override
  String get spottingNoNearby => 'لا توجد رحلات في نطاق 60 كم من موقعك';
  @override
  String get spottingTabList => 'قائمة';
  @override
  String get spottingTabMap => 'خريطة';
  @override
  String get spottingTryAgain => 'إعادة المحاولة';
  @override
  String get spottingPermDenied => 'تم رفض إذن الموقع';
  @override
  String get spottingPermErrPrefix => 'الموقع غير متاح';
  @override
  String get spottingSubtitle => 'الرحلات القريبة — نطاق 60 كم';

  @override
  String get statsTracked => 'متتبعة';
  @override
  String get statsAirborne => 'في الجو';
  @override
  String get statsOnGround => 'على الأرض';
  @override
  String get statsAirlabsCalls => 'طلبات AirLabs';
  @override
  String get statsTopAirlines => 'أفضل شركات الطيران (مباشر)';
  @override
  String get statsNoData => 'لا توجد بيانات بعد';
  @override
  String get statsFlightsLabel => 'رحلات';

  @override
  String get statsFlightsTracked => 'الرحلات المتتبعة';
  @override
  String get statsAvgViewsPerFlight => 'متوسط المشاهدات / رحلة';
  @override
  String get statsUniqueAirlines => 'شركات الطيران';
  @override
  String get statsUniqueAirports => 'المطارات';

  @override
  String get squawkEmergencyTitle => 'صفير الطوارئ';
  @override
  String get squawkHijack => 'اختطاف (7500)';
  @override
  String get squawkRadioFailure => 'عطل اللاسلكي (7600)';
  @override
  String get squawkGeneral => 'طوارئ عامة (7700)';

  @override
  String get co2EstimateLabel => 'تقدير CO₂';
  @override
  String get co2PerPaxLabel => 'لكل راكب';

  @override
  String get searchCargoHint => 'بحث برمز النداء / الشركة / الدولة';
  @override
  String get cargoFlightsHeader => 'رحلات الشحن';
  @override
  String get cargoHint => 'انقر على بطاقة للتتبع على الخريطة';
  @override
  String get searchNoResults => 'لا توجد مطابقات';
  @override
  String get cargoOperators => 'المشغلون';
  @override
  String get cargoTotal => 'الإجمالي';
  @override
  String get cargoAirborne => 'في الجو';
  @override
  String get cargoOnGround => 'على الأرض';

  @override
  String get airportsHeader => 'المطارات';
  @override
  String get popularAirports => 'المطارات الشائعة';
  @override
  String get departuresHeader => 'المغادرات الأخيرة';
  @override
  String get searchAirportsHint => 'IATA، مدينة، دولة (أي لغة)';

  @override
  String get compareFlights => 'مقارنة الرحلات';
  @override
  String get compareSubtitle => 'مقارنة جنبًا إلى جنب';
  @override
  String get geofences => 'النطاقات الجغرافية';
  @override
  String get geofencesSubtitle => 'مناطق للرحلات الواردة';
  @override
  String get voiceCommand => 'الأمر الصوتي';
  @override
  String get voiceListening => 'يستمع…';
  @override
  String get voiceUnsupported => 'الصوت غير مدعوم';

  @override
  String get dashLiveFlights => 'الرحلات المباشرة';
  @override
  String get dashSavedItems => 'محفوظ';
  @override
  String get dashTopAirlines => 'أفضل شركات الطيران';
  @override
  String get dashAltBands => 'نطاقات الارتفاع';
  @override
  String get dashSubtitle => 'ملخص شخصي';

  @override
  String get globeReload => 'إعادة تحميل';
  @override
  String get globeSubtitle => 'عرض الكوكب';

  @override
  String get featuresHeader => 'الميزات';
  @override
  String get errorPrefix => 'خطأ';
  @override
  String get retryButton => 'إعادة المحاولة';

  // METAR / TAF / NOTAM
  @override
  String get metarTafTitle => 'METAR / TAF';
  @override
  String get metarTab => 'METAR';
  @override
  String get tafTab => 'TAF';
  @override
  String get metarUnavailable => 'METAR / TAF غير متاح';
  @override
  String get metarLabelWind => 'الرياح';
  @override
  String get metarLabelVisibility => 'الرؤية';
  @override
  String get metarLabelTemp => 'الحرارة';
  @override
  String get metarLabelAltimeter => 'QNH';
  @override
  String get metarLabelClouds => 'السحب';
  @override
  String get metarLabelWeather => 'الطقس';
  @override
  String get metarShowRaw => 'عرض الخام';
  @override
  String get metarHideRaw => 'إخفاء الخام';
  @override
  String get notamsTitle => 'NOTAMs';
  @override
  String get notamsUnavailable => 'NOTAMs غير متاح';
  @override
  String get notamsNone => 'لا توجد NOTAMs مبلغ عنها';
  @override
  String get notamsMore => '+{0} لم يتم عرضها';
  @override
  String get loadingShort => 'جاري التحميل';

  // FleetInfoCard
  @override
  String get fleetInfoTitle => 'معلومات الأسطول';
  @override
  String get fleetAge => 'عمرها {0} سنة (بُنيت {1})';
  @override
  String get fleetSightings => '{0} مشاهدة';
  @override
  String get fleetFirstSeen => 'أول رؤية {0}';
  @override
  String get fleetLastSeen => 'آخر رؤية {0}';

  // RouteStatsBadge
  @override
  String get routeTodayFlights => '{0} اليوم';
  @override
  String get routeWeekFlights => '{0} هذا الأسبوع';
  @override
  String get routeMonthFlights => '{0} في 30 يومًا';

  // AtcAudioPanel
  @override
  String get atcLiveTitle => 'ATC مباشر';
  @override
  String get atcUnavailable => 'لا توجد بثوث مفهرسة لهذا المطار';
  @override
  String get atcSearchFallback => 'البحث في LiveATC.net';
  @override
  String get atcAttribution => 'الصوت بإذن من LiveATC.net';
  @override
  String get atcOpenInBrowser => 'فتح في المتصفح';

  // Airport detail tab labels
  @override
  String get infoTab => 'معلومات';
  @override
  String get sortLabel => 'فرز';
  @override
  String get sortByTime => 'الوقت';
  @override
  String get sortByDelay => 'التأخير';

  @override
  String get sectionUnavailable => 'القسم غير متاح';

  // Relative-time
  @override
  String get relTimeNow => 'الآن';
  @override
  String get relTimeMinutes => 'منذ {0} د';
  @override
  String get relTimeHours => 'منذ {0} س';
  @override
  String get relTimeDays => 'منذ {0} ي';
  @override
  String get relTimeMonths => 'منذ {0} شهر';
  @override
  String get relTimeYears => 'منذ {0} سنة';

  // ICS export
  @override
  String get exportIcs => 'تصدير .ics';
  @override
  String get exportIcsCalName => 'AirWatch — المحفوظات';
  @override
  String get exportNoItems => 'لا شيء للتصدير';
}
