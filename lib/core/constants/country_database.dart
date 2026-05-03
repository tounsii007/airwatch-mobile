import 'package:airwatch_mobile/core/l10n/country_translations.dart';

class CountryInfo {
  final String code;
  final String name;

  const CountryInfo({required this.code, required this.name});

  String get flagEmoji {
    final upper = code.toUpperCase();
    if (upper.length != 2) return '';
    final first = upper.codeUnitAt(0);
    final second = upper.codeUnitAt(1);
    if (first < 65 || first > 90 || second < 65 || second > 90) {
      return '';
    }

    return String.fromCharCode(first + 127397) +
        String.fromCharCode(second + 127397);
  }

  String get flagAssetPath => 'assets/flags/4x3/${code.toLowerCase()}.svg';
}

class CountryDatabase {
  static final List<CountryInfo> all = List.unmodifiable(_countries);

  static final Map<String, CountryInfo> _byCode = {
    for (final country in _countries) country.code: country,
  };

  static final Map<String, String> _byNormalizedName = {
    for (final country in _countries) _normalize(country.name): country.code,
    ..._aliases,
  };

  static final Map<String, List<String>> _aliasesByCode =
      {for (final country in _countries) country.code: <String>[]}..addEntries(
        _aliases.entries
            .map((entry) => MapEntry(entry.value, entry.key))
            .where((entry) => _byCode.containsKey(entry.key))
            .fold<Map<String, List<String>>>(<String, List<String>>{}, (
              acc,
              entry,
            ) {
              acc.putIfAbsent(entry.key, () => <String>[]).add(entry.value);
              return acc;
            })
            .entries,
      );

  static final List<_CountrySearchEntry> _searchEntries = _countries
      .map(
        (country) => _CountrySearchEntry(
          country: country,
          normalizedName: _normalize(country.name),
          aliases: List.unmodifiable(_collectAliases(country)),
        ),
      )
      .toList(growable: false);

  /// Combines English aliases (`_aliases` table above) with the localized
  /// names from `country_translations.dart` so a query like "Tunesien" or
  /// "Tunisie" scores a match against the Tunisia entry.
  ///
  /// <p>The `countryTranslations` map is keyed by canonical English names,
  /// some of which aren't 1:1 with this database's `country.name`
  /// (e.g. the database has `United States`; the translation table has
  /// both `USA` and `United States`). Match by normalised name so every
  /// English-name variant — bare, alias, alternate spelling — funnels
  /// its de + fr forms into the alias list.
  static List<String> _collectAliases(CountryInfo country) {
    final out = <String>[...?_aliasesByCode[country.code]];
    final canonicalNorm = _normalize(country.name);
    // English-name variants for this country — drawn from both the
    // database's name and any `_aliases` key that points at the same
    // ISO code.
    final englishVariants = <String>{country.name};
    for (final entry in _aliases.entries) {
      if (entry.value == country.code) {
        englishVariants.add(entry.key);
      }
    }
    // Walk the translations map and pull de/fr names for any key that
    // either matches a known English variant directly OR normalises to
    // the same canonical form.
    for (final tEntry in countryTranslations.entries) {
      final keyNorm = _normalize(tEntry.key);
      final matches =
          englishVariants.any((v) => _normalize(v) == keyNorm) ||
          keyNorm == canonicalNorm;
      if (!matches) continue;
      for (final localized in tEntry.value.values) {
        out.add(_normalize(localized));
      }
    }
    // De-dup so the score() loop below doesn't re-test the same string.
    return out.toSet().toList(growable: false);
  }

  static CountryInfo? byCode(String? code) {
    if (code == null) return null;
    return _byCode[code.trim().toUpperCase()];
  }

  static CountryInfo? find(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final byIso = byCode(trimmed);
    if (byIso != null) return byIso;

    final aliasCode = _byNormalizedName[_normalize(trimmed)];
    if (aliasCode != null) return _byCode[aliasCode];

    // Locale-aware fallback — the user typed a German / French country
    // name (e.g. "Tunesien", "Tunisie", "Allemagne", "Royaume-Uni"). The
    // English-only `_aliases` table can't match those; route through the
    // reverse-lookup map built from `countryTranslations` and resolve
    // back to the canonical English name, then re-run the alias path.
    final canonical = resolveCountryAlias(trimmed);
    if (canonical != null) {
      final viaTranslation = _byNormalizedName[_normalize(canonical)];
      if (viaTranslation != null) return _byCode[viaTranslation];
    }
    return null;
  }

  static String flagEmojiOf(String? value) => find(value)?.flagEmoji ?? '';

  static String? flagAssetPathOf(String? value) => find(value)?.flagAssetPath;

  static String displayName(String? value) =>
      find(value)?.name ?? value?.trim() ?? '';

  static String? codeOf(String? value) => find(value)?.code;

  static List<CountryInfo> search(String? query, {int limit = 20}) {
    if (limit <= 0) return const [];

    final normalizedQuery = _normalize(query ?? '');
    if (normalizedQuery.isEmpty) {
      if (limit >= _countries.length) return List<CountryInfo>.from(_countries);
      return _countries.take(limit).toList(growable: false);
    }

    final scored =
        _searchEntries
            .map(
              (entry) =>
                  (country: entry.country, score: entry.score(normalizedQuery)),
            )
            .where((result) => result.score != null)
            .map((result) => (country: result.country, score: result.score!))
            .toList(growable: false)
          ..sort((a, b) {
            final byScore = a.score.compareTo(b.score);
            if (byScore != 0) return byScore;
            return a.country.name.compareTo(b.country.name);
          });

    return scored
        .take(limit)
        .map((result) => result.country)
        .toList(growable: false);
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Map<String, String> _aliases = {
    'usa': 'US',
    'u s a': 'US',
    'united states': 'US',
    'united states of america': 'US',
    'uk': 'GB',
    'u k': 'GB',
    'united kingdom': 'GB',
    'great britain': 'GB',
    'england': 'GB',
    'uae': 'AE',
    'u a e': 'AE',
    'united arab emirates': 'AE',
    'south korea': 'KR',
    'north korea': 'KP',
    'russia': 'RU',
    'czech republic': 'CZ',
    'ivory coast': 'CI',
    'laos': 'LA',
    'moldova': 'MD',
    'syria': 'SY',
    'tanzania': 'TZ',
    'venezuela': 'VE',
    'bolivia': 'BO',
    'brunei': 'BN',
    'iran': 'IR',
    'palestine': 'PS',
    'vatican city': 'VA',
    'kosovo': 'XK',
    'hong kong': 'HK',
    'macau': 'MO',
    'macao': 'MO',
    'aland islands': 'AX',
    'american samoa': 'AS',
    'anguilla': 'AI',
    'antarctica': 'AQ',
    'bonaire sint eustatius and saba': 'BQ',
    'british indian ocean territory': 'IO',
    'canary islands': 'IC',
    'caribbean netherlands': 'BQ',
    'clipperton island': 'CP',
    'cocos keeling islands': 'CC',
    'cook islands': 'CK',
    'diego garcia': 'DG',
    'europe': 'EU',
    'european union': 'EU',
    'faroe islands': 'FO',
    'french guiana': 'GF',
    'french southern territories': 'TF',
    'guam': 'GU',
    'northern mariana islands': 'MP',
    'pacific community': 'PC',
    'saint barthelemy': 'BL',
    'saint martin': 'MF',
    'saint pierre and miquelon': 'PM',
    'sint maarten': 'SX',
    'taiwan': 'TW',
    'tokelau': 'TK',
    'turks and caicos islands': 'TC',
    'united nations': 'UN',
    'unknown': 'XX',
    'reunion': 'RE',
    'la reunion': 'RE',
    'curacao': 'CW',
    'eswatini': 'SZ',
    'swaziland': 'SZ',
    'cape verde': 'CV',
  };

  static const List<CountryInfo> _countries = [
    CountryInfo(code: 'AF', name: 'Afghanistan'),
    CountryInfo(code: 'AX', name: 'Aland Islands'),
    CountryInfo(code: 'AL', name: 'Albania'),
    CountryInfo(code: 'DZ', name: 'Algeria'),
    CountryInfo(code: 'AS', name: 'American Samoa'),
    CountryInfo(code: 'AD', name: 'Andorra'),
    CountryInfo(code: 'AO', name: 'Angola'),
    CountryInfo(code: 'AI', name: 'Anguilla'),
    CountryInfo(code: 'AQ', name: 'Antarctica'),
    CountryInfo(code: 'AG', name: 'Antigua and Barbuda'),
    CountryInfo(code: 'AR', name: 'Argentina'),
    CountryInfo(code: 'AM', name: 'Armenia'),
    CountryInfo(code: 'AW', name: 'Aruba'),
    CountryInfo(code: 'AU', name: 'Australia'),
    CountryInfo(code: 'AT', name: 'Austria'),
    CountryInfo(code: 'AZ', name: 'Azerbaijan'),
    CountryInfo(code: 'BS', name: 'Bahamas'),
    CountryInfo(code: 'BH', name: 'Bahrain'),
    CountryInfo(code: 'BD', name: 'Bangladesh'),
    CountryInfo(code: 'BB', name: 'Barbados'),
    CountryInfo(code: 'BY', name: 'Belarus'),
    CountryInfo(code: 'BE', name: 'Belgium'),
    CountryInfo(code: 'BZ', name: 'Belize'),
    CountryInfo(code: 'BJ', name: 'Benin'),
    CountryInfo(code: 'BM', name: 'Bermuda'),
    CountryInfo(code: 'BT', name: 'Bhutan'),
    CountryInfo(code: 'BO', name: 'Bolivia'),
    CountryInfo(code: 'BQ', name: 'Bonaire, Sint Eustatius and Saba'),
    CountryInfo(code: 'BA', name: 'Bosnia and Herzegovina'),
    CountryInfo(code: 'BW', name: 'Botswana'),
    CountryInfo(code: 'BV', name: 'Bouvet Island'),
    CountryInfo(code: 'BR', name: 'Brazil'),
    CountryInfo(code: 'IO', name: 'British Indian Ocean Territory'),
    CountryInfo(code: 'VG', name: 'British Virgin Islands'),
    CountryInfo(code: 'BN', name: 'Brunei'),
    CountryInfo(code: 'BG', name: 'Bulgaria'),
    CountryInfo(code: 'BF', name: 'Burkina Faso'),
    CountryInfo(code: 'BI', name: 'Burundi'),
    CountryInfo(code: 'CV', name: 'Cabo Verde'),
    CountryInfo(code: 'KH', name: 'Cambodia'),
    CountryInfo(code: 'CM', name: 'Cameroon'),
    CountryInfo(code: 'CA', name: 'Canada'),
    CountryInfo(code: 'IC', name: 'Canary Islands'),
    CountryInfo(code: 'KY', name: 'Cayman Islands'),
    CountryInfo(code: 'CF', name: 'Central African Republic'),
    CountryInfo(code: 'TD', name: 'Chad'),
    CountryInfo(code: 'CL', name: 'Chile'),
    CountryInfo(code: 'CN', name: 'China'),
    CountryInfo(code: 'CX', name: 'Christmas Island'),
    CountryInfo(code: 'CP', name: 'Clipperton Island'),
    CountryInfo(code: 'CC', name: 'Cocos (Keeling) Islands'),
    CountryInfo(code: 'CO', name: 'Colombia'),
    CountryInfo(code: 'KM', name: 'Comoros'),
    CountryInfo(code: 'CG', name: 'Congo'),
    CountryInfo(code: 'CD', name: 'Congo (Democratic Republic of the)'),
    CountryInfo(code: 'CK', name: 'Cook Islands'),
    CountryInfo(code: 'CR', name: 'Costa Rica'),
    CountryInfo(code: 'CI', name: 'Cote d\'Ivoire'),
    CountryInfo(code: 'HR', name: 'Croatia'),
    CountryInfo(code: 'CU', name: 'Cuba'),
    CountryInfo(code: 'CW', name: 'Curacao'),
    CountryInfo(code: 'CY', name: 'Cyprus'),
    CountryInfo(code: 'CZ', name: 'Czechia'),
    CountryInfo(code: 'DK', name: 'Denmark'),
    CountryInfo(code: 'DG', name: 'Diego Garcia'),
    CountryInfo(code: 'DJ', name: 'Djibouti'),
    CountryInfo(code: 'DM', name: 'Dominica'),
    CountryInfo(code: 'DO', name: 'Dominican Republic'),
    CountryInfo(code: 'EC', name: 'Ecuador'),
    CountryInfo(code: 'EG', name: 'Egypt'),
    CountryInfo(code: 'SV', name: 'El Salvador'),
    CountryInfo(code: 'GQ', name: 'Equatorial Guinea'),
    CountryInfo(code: 'ER', name: 'Eritrea'),
    CountryInfo(code: 'EE', name: 'Estonia'),
    CountryInfo(code: 'SZ', name: 'Eswatini'),
    CountryInfo(code: 'ET', name: 'Ethiopia'),
    CountryInfo(code: 'EU', name: 'European Union'),
    CountryInfo(code: 'FK', name: 'Falkland Islands'),
    CountryInfo(code: 'FO', name: 'Faroe Islands'),
    CountryInfo(code: 'FJ', name: 'Fiji'),
    CountryInfo(code: 'FI', name: 'Finland'),
    CountryInfo(code: 'FR', name: 'France'),
    CountryInfo(code: 'GF', name: 'French Guiana'),
    CountryInfo(code: 'PF', name: 'French Polynesia'),
    CountryInfo(code: 'TF', name: 'French Southern Territories'),
    CountryInfo(code: 'GA', name: 'Gabon'),
    CountryInfo(code: 'GM', name: 'Gambia'),
    CountryInfo(code: 'GE', name: 'Georgia'),
    CountryInfo(code: 'DE', name: 'Germany'),
    CountryInfo(code: 'GH', name: 'Ghana'),
    CountryInfo(code: 'GI', name: 'Gibraltar'),
    CountryInfo(code: 'GR', name: 'Greece'),
    CountryInfo(code: 'GL', name: 'Greenland'),
    CountryInfo(code: 'GD', name: 'Grenada'),
    CountryInfo(code: 'GP', name: 'Guadeloupe'),
    CountryInfo(code: 'GU', name: 'Guam'),
    CountryInfo(code: 'GT', name: 'Guatemala'),
    CountryInfo(code: 'GG', name: 'Guernsey'),
    CountryInfo(code: 'GN', name: 'Guinea'),
    CountryInfo(code: 'GW', name: 'Guinea-Bissau'),
    CountryInfo(code: 'GY', name: 'Guyana'),
    CountryInfo(code: 'HT', name: 'Haiti'),
    CountryInfo(code: 'HM', name: 'Heard Island and McDonald Islands'),
    CountryInfo(code: 'HN', name: 'Honduras'),
    CountryInfo(code: 'HK', name: 'Hong Kong'),
    CountryInfo(code: 'HU', name: 'Hungary'),
    CountryInfo(code: 'IS', name: 'Iceland'),
    CountryInfo(code: 'IN', name: 'India'),
    CountryInfo(code: 'ID', name: 'Indonesia'),
    CountryInfo(code: 'IR', name: 'Iran'),
    CountryInfo(code: 'IQ', name: 'Iraq'),
    CountryInfo(code: 'IE', name: 'Ireland'),
    CountryInfo(code: 'IM', name: 'Isle of Man'),
    CountryInfo(code: 'IL', name: 'Israel'),
    CountryInfo(code: 'IT', name: 'Italy'),
    CountryInfo(code: 'JM', name: 'Jamaica'),
    CountryInfo(code: 'JP', name: 'Japan'),
    CountryInfo(code: 'JE', name: 'Jersey'),
    CountryInfo(code: 'JO', name: 'Jordan'),
    CountryInfo(code: 'KZ', name: 'Kazakhstan'),
    CountryInfo(code: 'KE', name: 'Kenya'),
    CountryInfo(code: 'KI', name: 'Kiribati'),
    CountryInfo(code: 'KP', name: 'Korea (Democratic People\'s Republic of)'),
    CountryInfo(code: 'KR', name: 'Korea (Republic of)'),
    CountryInfo(code: 'XK', name: 'Kosovo'),
    CountryInfo(code: 'KW', name: 'Kuwait'),
    CountryInfo(code: 'KG', name: 'Kyrgyzstan'),
    CountryInfo(code: 'LA', name: 'Lao People\'s Democratic Republic'),
    CountryInfo(code: 'LV', name: 'Latvia'),
    CountryInfo(code: 'LB', name: 'Lebanon'),
    CountryInfo(code: 'LS', name: 'Lesotho'),
    CountryInfo(code: 'LR', name: 'Liberia'),
    CountryInfo(code: 'LY', name: 'Libya'),
    CountryInfo(code: 'LI', name: 'Liechtenstein'),
    CountryInfo(code: 'LT', name: 'Lithuania'),
    CountryInfo(code: 'LU', name: 'Luxembourg'),
    CountryInfo(code: 'MO', name: 'Macao'),
    CountryInfo(code: 'MG', name: 'Madagascar'),
    CountryInfo(code: 'MW', name: 'Malawi'),
    CountryInfo(code: 'MY', name: 'Malaysia'),
    CountryInfo(code: 'MV', name: 'Maldives'),
    CountryInfo(code: 'ML', name: 'Mali'),
    CountryInfo(code: 'MT', name: 'Malta'),
    CountryInfo(code: 'MH', name: 'Marshall Islands'),
    CountryInfo(code: 'MQ', name: 'Martinique'),
    CountryInfo(code: 'MR', name: 'Mauritania'),
    CountryInfo(code: 'MU', name: 'Mauritius'),
    CountryInfo(code: 'YT', name: 'Mayotte'),
    CountryInfo(code: 'MX', name: 'Mexico'),
    CountryInfo(code: 'FM', name: 'Micronesia'),
    CountryInfo(code: 'MD', name: 'Moldova (Republic of)'),
    CountryInfo(code: 'MC', name: 'Monaco'),
    CountryInfo(code: 'MN', name: 'Mongolia'),
    CountryInfo(code: 'ME', name: 'Montenegro'),
    CountryInfo(code: 'MS', name: 'Montserrat'),
    CountryInfo(code: 'MA', name: 'Morocco'),
    CountryInfo(code: 'MZ', name: 'Mozambique'),
    CountryInfo(code: 'MM', name: 'Myanmar'),
    CountryInfo(code: 'NA', name: 'Namibia'),
    CountryInfo(code: 'NR', name: 'Nauru'),
    CountryInfo(code: 'NP', name: 'Nepal'),
    CountryInfo(code: 'NL', name: 'Netherlands'),
    CountryInfo(code: 'NC', name: 'New Caledonia'),
    CountryInfo(code: 'NZ', name: 'New Zealand'),
    CountryInfo(code: 'NI', name: 'Nicaragua'),
    CountryInfo(code: 'NE', name: 'Niger'),
    CountryInfo(code: 'NG', name: 'Nigeria'),
    CountryInfo(code: 'NU', name: 'Niue'),
    CountryInfo(code: 'NF', name: 'Norfolk Island'),
    CountryInfo(code: 'MK', name: 'North Macedonia'),
    CountryInfo(code: 'MP', name: 'Northern Mariana Islands'),
    CountryInfo(code: 'NO', name: 'Norway'),
    CountryInfo(code: 'OM', name: 'Oman'),
    CountryInfo(code: 'PC', name: 'Pacific Community'),
    CountryInfo(code: 'PK', name: 'Pakistan'),
    CountryInfo(code: 'PW', name: 'Palau'),
    CountryInfo(code: 'PS', name: 'Palestine, State of'),
    CountryInfo(code: 'PA', name: 'Panama'),
    CountryInfo(code: 'PG', name: 'Papua New Guinea'),
    CountryInfo(code: 'PY', name: 'Paraguay'),
    CountryInfo(code: 'PE', name: 'Peru'),
    CountryInfo(code: 'PH', name: 'Philippines'),
    CountryInfo(code: 'PN', name: 'Pitcairn'),
    CountryInfo(code: 'PL', name: 'Poland'),
    CountryInfo(code: 'PT', name: 'Portugal'),
    CountryInfo(code: 'PR', name: 'Puerto Rico'),
    CountryInfo(code: 'QA', name: 'Qatar'),
    CountryInfo(code: 'RE', name: 'Reunion'),
    CountryInfo(code: 'RO', name: 'Romania'),
    CountryInfo(code: 'RU', name: 'Russian Federation'),
    CountryInfo(code: 'RW', name: 'Rwanda'),
    CountryInfo(code: 'BL', name: 'Saint Barthelemy'),
    CountryInfo(
      code: 'SH',
      name: 'Saint Helena, Ascension and Tristan da Cunha',
    ),
    CountryInfo(code: 'KN', name: 'Saint Kitts and Nevis'),
    CountryInfo(code: 'LC', name: 'Saint Lucia'),
    CountryInfo(code: 'MF', name: 'Saint Martin'),
    CountryInfo(code: 'PM', name: 'Saint Pierre and Miquelon'),
    CountryInfo(code: 'VC', name: 'Saint Vincent and the Grenadines'),
    CountryInfo(code: 'WS', name: 'Samoa'),
    CountryInfo(code: 'SM', name: 'San Marino'),
    CountryInfo(code: 'ST', name: 'Sao Tome and Principe'),
    CountryInfo(code: 'SA', name: 'Saudi Arabia'),
    CountryInfo(code: 'SN', name: 'Senegal'),
    CountryInfo(code: 'RS', name: 'Serbia'),
    CountryInfo(code: 'SC', name: 'Seychelles'),
    CountryInfo(code: 'SL', name: 'Sierra Leone'),
    CountryInfo(code: 'SG', name: 'Singapore'),
    CountryInfo(code: 'SX', name: 'Sint Maarten'),
    CountryInfo(code: 'SK', name: 'Slovakia'),
    CountryInfo(code: 'SI', name: 'Slovenia'),
    CountryInfo(code: 'SB', name: 'Solomon Islands'),
    CountryInfo(code: 'SO', name: 'Somalia'),
    CountryInfo(code: 'ZA', name: 'South Africa'),
    CountryInfo(
      code: 'GS',
      name: 'South Georgia and the South Sandwich Islands',
    ),
    CountryInfo(code: 'SS', name: 'South Sudan'),
    CountryInfo(code: 'ES', name: 'Spain'),
    CountryInfo(code: 'LK', name: 'Sri Lanka'),
    CountryInfo(code: 'SD', name: 'Sudan'),
    CountryInfo(code: 'SR', name: 'Suriname'),
    CountryInfo(code: 'SJ', name: 'Svalbard and Jan Mayen'),
    CountryInfo(code: 'SE', name: 'Sweden'),
    CountryInfo(code: 'CH', name: 'Switzerland'),
    CountryInfo(code: 'SY', name: 'Syrian Arab Republic'),
    CountryInfo(code: 'TW', name: 'Taiwan'),
    CountryInfo(code: 'TJ', name: 'Tajikistan'),
    CountryInfo(code: 'TZ', name: 'Tanzania, United Republic of'),
    CountryInfo(code: 'TH', name: 'Thailand'),
    CountryInfo(code: 'TL', name: 'Timor-Leste'),
    CountryInfo(code: 'TG', name: 'Togo'),
    CountryInfo(code: 'TK', name: 'Tokelau'),
    CountryInfo(code: 'TO', name: 'Tonga'),
    CountryInfo(code: 'TT', name: 'Trinidad and Tobago'),
    CountryInfo(code: 'TN', name: 'Tunisia'),
    CountryInfo(code: 'TR', name: 'Turkey'),
    CountryInfo(code: 'TM', name: 'Turkmenistan'),
    CountryInfo(code: 'TC', name: 'Turks and Caicos Islands'),
    CountryInfo(code: 'TV', name: 'Tuvalu'),
    CountryInfo(code: 'UG', name: 'Uganda'),
    CountryInfo(code: 'UA', name: 'Ukraine'),
    CountryInfo(code: 'AE', name: 'United Arab Emirates'),
    CountryInfo(code: 'GB', name: 'United Kingdom'),
    CountryInfo(code: 'UN', name: 'United Nations'),
    CountryInfo(code: 'US', name: 'United States'),
    CountryInfo(code: 'UM', name: 'United States Minor Outlying Islands'),
    CountryInfo(code: 'VI', name: 'United States Virgin Islands'),
    CountryInfo(code: 'XX', name: 'Unknown'),
    CountryInfo(code: 'UY', name: 'Uruguay'),
    CountryInfo(code: 'UZ', name: 'Uzbekistan'),
    CountryInfo(code: 'VU', name: 'Vanuatu'),
    CountryInfo(code: 'VA', name: 'Vatican City'),
    CountryInfo(code: 'VE', name: 'Venezuela'),
    CountryInfo(code: 'VN', name: 'Vietnam'),
    CountryInfo(code: 'WF', name: 'Wallis and Futuna'),
    CountryInfo(code: 'EH', name: 'Western Sahara'),
    CountryInfo(code: 'YE', name: 'Yemen'),
    CountryInfo(code: 'ZM', name: 'Zambia'),
    CountryInfo(code: 'ZW', name: 'Zimbabwe'),
  ];
}

class _CountrySearchEntry {
  final CountryInfo country;
  final String normalizedName;
  final List<String> aliases;

  const _CountrySearchEntry({
    required this.country,
    required this.normalizedName,
    required this.aliases,
  });

  int? score(String query) {
    final normalizedCode = country.code.toLowerCase();
    if (normalizedCode == query) return 0;
    if (normalizedName == query) return 1;
    if (aliases.contains(query)) return 2;
    if (normalizedCode.startsWith(query)) return 3;
    if (normalizedName.startsWith(query)) return 4;
    if (_startsWithWord(normalizedName, query)) return 5;

    for (final alias in aliases) {
      if (alias.startsWith(query)) return 6;
      if (_startsWithWord(alias, query)) return 7;
    }

    if (normalizedName.contains(query)) return 8;
    if (aliases.any((alias) => alias.contains(query))) return 9;
    return null;
  }

  bool _startsWithWord(String haystack, String needle) {
    if (haystack.startsWith(needle)) return true;
    return haystack.contains(' $needle');
  }
}
