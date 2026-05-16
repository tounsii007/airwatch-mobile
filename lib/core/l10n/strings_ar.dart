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
  String get more => 'المزيد';
  @override
  String get compare => 'مقارنة';
  @override
  String get moreFeatures => 'المزيد من الميزات';
  @override
  String get dashboardSubtitle => 'ملخص شخصي';
  @override
  String get statsSubtitle => 'سجل التتبع';
  @override
  String get airlinesSubtitle => 'شركات الطيران المباشرة';
  @override
  String get spottingShortSubtitle => 'رحلات قريبة';

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

  // Personal-stats overhaul (التوافق مع airwatch-web 1e24147).
  @override
  String get statsTrackingSince => 'التتبع منذ';
  @override
  String get statsDaysActive => 'الأيام النشطة';
  @override
  String get statsPeakHour => 'ساعة الذروة';
  @override
  String get statsActivityChart => 'النشاط · 24 ساعة';
  @override
  String get statsTopRoutes => 'أهم المسارات';
  @override
  String get statsTopAirports => 'أهم المطارات';
  @override
  String get statsRecentFlights => 'الرحلات الأخيرة';
  @override
  String get statsExport => 'تصدير';
  @override
  String get statsExportJson => 'تصدير كـ JSON';
  @override
  String get statsExportCsv => 'تصدير كـ CSV';
  @override
  String get statsExportJsonCopied => 'تم نسخ JSON إلى الحافظة';
  @override
  String get statsExportCsvCopied => 'تم نسخ CSV إلى الحافظة';
  @override
  String get statsClear => 'مسح السجل';
  @override
  String get statsClearConfirm =>
      'سيؤدي هذا إلى إزالة سجل التتبع المحلي نهائيًا. هل تريد المتابعة؟';
  @override
  String get statsEmptyTitle => 'لم يتم تتبع أي رحلات بعد';
  @override
  String get statsEmptyHint =>
      'انقر على رحلة على الخريطة لبدء تسجيل سجل التتبع الشخصي.';
  @override
  String get overview => 'نظرة عامة';
  @override
  String get replayTitle => 'إعادة التشغيل';
  @override
  String get replayHeading => 'إعادة تشغيل 7 أيام';
  @override
  String get replayBody =>
      'أدخل علامة نداء أو رقم رحلة لمشاهدة آخر 7 أيام — التأخيرات والأوقات المجدولة مقابل الفعلية وتتبع المسار.';
  @override
  String get replayHint => 'رقم الرحلة (مثل TU744)';
  @override
  String get replaySearchAction => 'بحث';
  @override
  String get replayExamples => 'أمثلة: TU744, DLH441, RYR1234';
  @override
  String get statsSearchHint => 'البحث عن علامة نداء / مسار / شركة…';
  @override
  String get statsSearchNoMatch => 'لا توجد رحلات تطابق هذا الفلتر.';
  @override
  String get statsSortByRecency => 'الترتيب حسب الأحدث';
  @override
  String get statsSortByViews => 'الترتيب حسب المشاهدات';

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

  // ── Geofence form ──────────────────────────────────────────────────────
  @override
  String get fenceFormTitle => 'سور جغرافي جديد';
  @override
  String get fenceNewHeading => 'سور جغرافي جديد {0}';
  @override
  String get fenceTypeCircle => 'دائرة';
  @override
  String get fenceTypeRectangle => 'مستطيل';
  @override
  String get fenceNameLabel => 'الاسم';
  @override
  String get fenceNamePlaceholder => 'مثال: اقتراب فرانكفورت';
  @override
  String get fenceRadiusLabel => 'نصف القطر (كم)';
  @override
  String get fenceCenterLatLabel => 'خط عرض المركز';
  @override
  String get fenceCenterLonLabel => 'خط طول المركز';
  @override
  String get fenceNorthLabel => 'خط العرض الشمالي';
  @override
  String get fenceSouthLabel => 'خط العرض الجنوبي';
  @override
  String get fenceEastLabel => 'خط الطول الشرقي';
  @override
  String get fenceWestLabel => 'خط الطول الغربي';
  @override
  String get fenceMinAltLabel => 'الارتفاع الأدنى (ft)';
  @override
  String get fenceMaxAltLabel => 'الارتفاع الأقصى (ft)';
  @override
  String get fenceAirlineLabel => 'رمز ICAO للشركة';
  @override
  String get fenceOptionalFilters => 'مرشحات اختيارية';
  @override
  String get fenceSaveButton => 'حفظ';
  @override
  String get fenceCancelButton => 'إلغاء';
  @override
  String get fenceErrNameRequired => 'الاسم مطلوب';
  @override
  String get fenceErrLatRange => 'خط العرض يجب أن يكون بين -90 و 90';
  @override
  String get fenceErrLonRange => 'خط الطول يجب أن يكون بين -180 و 180';
  @override
  String get fenceErrRadius => 'نصف القطر يجب أن يكون أكبر من 0 كم';
  @override
  String get fenceErrBoundsRequired => 'الحدود الأربعة مطلوبة';
  @override
  String get fenceErrNorthSouth => 'الشمال يجب أن يكون أكبر من الجنوب';
  @override
  String get fenceErrEastWest => 'الشرق يجب أن يكون أكبر من الغرب';

  // ── Geofence list ──────────────────────────────────────────────────────
  @override
  String get fenceActiveHeading => 'الأسوار الجغرافية النشطة';
  @override
  String get fenceTotalCount => '{0} الإجمالي';
  @override
  String get fencesListEmpty =>
      'لا توجد أسوار. اضغط رسم أو استخدم النموذج — ستظهر التنبيهات هنا عند دخول طائرة المنطقة.';
  @override
  String get fenceDelete => 'حذف';
  @override
  String get fenceShapeCircle => '{0}° شمال، {1}° شرق · ق {2} كم';
  @override
  String get fenceShapeRect =>
      'ج {0}° → ش {1}° · غ {2}° → ش {3}°';
  @override
  String get fenceAirlineTooltip =>
      'فقط رحلات {0} ({1}) تُفعّل هذا السور';
  @override
  String get fenceAirlineTooltipNoName => 'مرشح الشركة: {0}';
  @override
  String get fenceMinAltTooltip =>
      'فقط الرحلات على هذا الارتفاع أو أعلى تُفعّل السور';
  @override
  String get fenceMaxAltTooltip =>
      'فقط الرحلات على هذا الارتفاع أو أدنى تُفعّل السور';

  // ── Draw screen ────────────────────────────────────────────────────────
  @override
  String get fenceDrawTitle => 'رسم سور جغرافي';
  @override
  String get fenceDrawHintCircleFirst => 'اضغط لتحديد المركز';
  @override
  String get fenceDrawHintCircleSecond => 'اضغط لتحديد نصف القطر';
  @override
  String get fenceDrawHintRectFirst =>
      'اضغط لتحديد الزاوية الأولى';
  @override
  String get fenceDrawHintRectSecond =>
      'اضغط لتحديد الزاوية المقابلة';
  @override
  String get fenceDrawHintReady =>
      'احفظ عند الانتهاء أو اضغط إعادة';
  @override
  String get fenceDrawResetButton => 'إعادة';
  @override
  String get fenceDrawNameTitle => 'سمّ هذا السور';

  // ── Alerts panel ───────────────────────────────────────────────────────
  @override
  String get alertsCountOne => 'تنبيه';
  @override
  String get alertsCountMany => 'تنبيهات';
  @override
  String get alertsClearAll => 'مسح الكل';
  @override
  String get alertsClearAllTooltip => 'امسح كل التنبيهات (تبقى الأسوار)';
  @override
  String get alertsDismiss => 'تجاهل';
  @override
  String get alertsDismissTooltip =>
      'تجاهل هذا التنبيه (لا يؤثر على السجل)';
  @override
  String get alertsAllFilter => 'الكل';
  @override
  String get alertsFilterTooltip => 'تبديل تنبيهات «{0}»';
  @override
  String get alertsEmptyFilter =>
      'لا تنبيهات تطابق المرشح. اضغط الكل.';
  @override
  String get alertsShowOnMap => 'عرض هذه الرحلة على الخريطة';

  // ── Fence stats badge ──────────────────────────────────────────────────
  @override
  String get fenceStatsHitsOne => '{0} اختراق';
  @override
  String get fenceStatsHitsMany => '{0} اختراقات';
  @override
  String get fenceStatsAircraft => '{0} طائرات';
  @override
  String get fenceStatsTopAirlineWithName =>
      'أعلى شركة: {0} ({1}× هذا السور)';
  @override
  String get fenceStatsTopAirline => 'أعلى شركة: {0}';
  @override
  String get fenceStatsTopLabel => 'أعلى:';
  @override
  String get fenceStatsLast => 'آخر {0}';

  // ── Fence import/export ────────────────────────────────────────────────
  @override
  String get fenceExport => 'تصدير';
  @override
  String get fenceImport => 'استيراد';
  @override
  String get fenceImporting => 'جاري الاستيراد…';
  @override
  String get fenceExportTooltip => 'تحميل الأسوار كملف JSON';
  @override
  String get fenceImportTooltip => 'استعادة الأسوار من ملف JSON';
  @override
  String get fenceExportEmpty => 'لا شيء للتصدير';
  @override
  String get fenceExportedOne => 'تم تصدير سور واحد';
  @override
  String get fenceExportedMany => 'تم تصدير {0} أسوار';
  @override
  String get fenceReadingFile => 'قراءة الملف…';
  @override
  String get fenceImportedOne => 'تم استيراد سور واحد';
  @override
  String get fenceImportedMany => 'تم استيراد {0} أسوار';
  @override
  String get fenceImportedPartial =>
      'تم استيراد {0}، فشل {1} ({2})';
  @override
  String get fenceReadFailed => 'فشلت القراءة: {0}';
  @override
  String get fenceImportInvalidJson => 'JSON غير صالح: {0}';
  @override
  String get fenceImportSchemaMismatch =>
      'عدم تطابق المخطط عند {0}: {1}';

  // ── Dashboard empty / honest states ────────────────────────────────────
  @override
  String get dashNoDataYet => 'لا بيانات بعد';
  @override
  String get dashEmptyHint => 'افتح الخريطة لبدء تتبع الرحلات';
}
