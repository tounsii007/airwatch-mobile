/// Localized country names.
/// Maps English country name → {locale: localizedName}.
const Map<String, Map<String, String>> countryTranslations = {
  // Europe
  'Germany': {'de': 'Deutschland', 'fr': 'Allemagne'},
  'France': {'de': 'Frankreich', 'fr': 'France'},
  'Italy': {'de': 'Italien', 'fr': 'Italie'},
  'Spain': {'de': 'Spanien', 'fr': 'Espagne'},
  'Portugal': {'de': 'Portugal', 'fr': 'Portugal'},
  'UK': {'de': 'Vereinigtes Königreich', 'fr': 'Royaume-Uni'},
  'United Kingdom': {'de': 'Vereinigtes Königreich', 'fr': 'Royaume-Uni'},
  'Netherlands': {'de': 'Niederlande', 'fr': 'Pays-Bas'},
  'Belgium': {'de': 'Belgien', 'fr': 'Belgique'},
  'Switzerland': {'de': 'Schweiz', 'fr': 'Suisse'},
  'Austria': {'de': 'Österreich', 'fr': 'Autriche'},
  'Poland': {'de': 'Polen', 'fr': 'Pologne'},
  'Czechia': {'de': 'Tschechien', 'fr': 'Tchéquie'},
  'Czech Republic': {'de': 'Tschechien', 'fr': 'Tchéquie'},
  'Hungary': {'de': 'Ungarn', 'fr': 'Hongrie'},
  'Romania': {'de': 'Rumänien', 'fr': 'Roumanie'},
  'Greece': {'de': 'Griechenland', 'fr': 'Grèce'},
  'Turkey': {'de': 'Türkei', 'fr': 'Turquie'},
  'Denmark': {'de': 'Dänemark', 'fr': 'Danemark'},
  'Sweden': {'de': 'Schweden', 'fr': 'Suède'},
  'Norway': {'de': 'Norwegen', 'fr': 'Norvège'},
  'Finland': {'de': 'Finnland', 'fr': 'Finlande'},
  'Iceland': {'de': 'Island', 'fr': 'Islande'},
  'Ireland': {'de': 'Irland', 'fr': 'Irlande'},
  'Croatia': {'de': 'Kroatien', 'fr': 'Croatie'},
  'Serbia': {'de': 'Serbien', 'fr': 'Serbie'},
  'Bulgaria': {'de': 'Bulgarien', 'fr': 'Bulgarie'},
  'Slovakia': {'de': 'Slowakei', 'fr': 'Slovaquie'},
  'Slovenia': {'de': 'Slowenien', 'fr': 'Slovénie'},
  'Latvia': {'de': 'Lettland', 'fr': 'Lettonie'},
  'Lithuania': {'de': 'Litauen', 'fr': 'Lituanie'},
  'Estonia': {'de': 'Estland', 'fr': 'Estonie'},
  'Malta': {'de': 'Malta', 'fr': 'Malte'},
  'Luxembourg': {'de': 'Luxemburg', 'fr': 'Luxembourg'},
  'Cyprus': {'de': 'Zypern', 'fr': 'Chypre'},
  'Albania': {'de': 'Albanien', 'fr': 'Albanie'},
  'Montenegro': {'de': 'Montenegro', 'fr': 'Monténégro'},
  'North Macedonia': {'de': 'Nordmazedonien', 'fr': 'Macédoine du Nord'},
  'Bosnia and Herzegovina': {
    'de': 'Bosnien und Herzegowina',
    'fr': 'Bosnie-Herzégovine',
  },

  // Middle East / North Africa
  'UAE': {'de': 'Vereinigte Arabische Emirate', 'fr': 'Émirats arabes unis'},
  'United Arab Emirates': {
    'de': 'Vereinigte Arabische Emirate',
    'fr': 'Émirats arabes unis',
  },
  'Saudi Arabia': {'de': 'Saudi-Arabien', 'fr': 'Arabie saoudite'},
  'Qatar': {'de': 'Katar', 'fr': 'Qatar'},
  'Oman': {'de': 'Oman', 'fr': 'Oman'},
  'Kuwait': {'de': 'Kuwait', 'fr': 'Koweït'},
  'Bahrain': {'de': 'Bahrain', 'fr': 'Bahreïn'},
  'Jordan': {'de': 'Jordanien', 'fr': 'Jordanie'},
  'Lebanon': {'de': 'Libanon', 'fr': 'Liban'},
  'Iraq': {'de': 'Irak', 'fr': 'Irak'},
  'Iran': {'de': 'Iran', 'fr': 'Iran'},
  'Israel': {'de': 'Israel', 'fr': 'Israël'},
  'Egypt': {'de': 'Ägypten', 'fr': 'Égypte'},
  'Morocco': {'de': 'Marokko', 'fr': 'Maroc'},
  'Tunisia': {'de': 'Tunesien', 'fr': 'Tunisie'},
  'Algeria': {'de': 'Algerien', 'fr': 'Algérie'},
  'Libya': {'de': 'Libyen', 'fr': 'Libye'},

  // Sub-Saharan Africa
  'South Africa': {'de': 'Südafrika', 'fr': 'Afrique du Sud'},
  'Nigeria': {'de': 'Nigeria', 'fr': 'Nigéria'},
  'Kenya': {'de': 'Kenia', 'fr': 'Kenya'},
  'Ethiopia': {'de': 'Äthiopien', 'fr': 'Éthiopie'},
  'Tanzania': {'de': 'Tansania', 'fr': 'Tanzanie'},
  'Ghana': {'de': 'Ghana', 'fr': 'Ghana'},
  'Senegal': {'de': 'Senegal', 'fr': 'Sénégal'},
  'Ivory Coast': {'de': 'Elfenbeinküste', 'fr': "Côte d'Ivoire"},
  'Cameroon': {'de': 'Kamerun', 'fr': 'Cameroun'},
  'Rwanda': {'de': 'Ruanda', 'fr': 'Rwanda'},
  'Mauritius': {'de': 'Mauritius', 'fr': 'Maurice'},
  'Madagascar': {'de': 'Madagaskar', 'fr': 'Madagascar'},
  'Mozambique': {'de': 'Mosambik', 'fr': 'Mozambique'},

  // Americas
  'USA': {'de': 'USA', 'fr': 'États-Unis'},
  'United States': {'de': 'Vereinigte Staaten', 'fr': 'États-Unis'},
  'Canada': {'de': 'Kanada', 'fr': 'Canada'},
  'Mexico': {'de': 'Mexiko', 'fr': 'Mexique'},
  'Brazil': {'de': 'Brasilien', 'fr': 'Brésil'},
  'Argentina': {'de': 'Argentinien', 'fr': 'Argentine'},
  'Chile': {'de': 'Chile', 'fr': 'Chili'},
  'Colombia': {'de': 'Kolumbien', 'fr': 'Colombie'},
  'Peru': {'de': 'Peru', 'fr': 'Pérou'},
  'Cuba': {'de': 'Kuba', 'fr': 'Cuba'},
  'Panama': {'de': 'Panama', 'fr': 'Panama'},
  'Costa Rica': {'de': 'Costa Rica', 'fr': 'Costa Rica'},
  'Ecuador': {'de': 'Ecuador', 'fr': 'Équateur'},

  // Asia-Pacific
  'China': {'de': 'China', 'fr': 'Chine'},
  'Japan': {'de': 'Japan', 'fr': 'Japon'},
  'South Korea': {'de': 'Südkorea', 'fr': 'Corée du Sud'},
  'India': {'de': 'Indien', 'fr': 'Inde'},
  'Thailand': {'de': 'Thailand', 'fr': 'Thaïlande'},
  'Vietnam': {'de': 'Vietnam', 'fr': 'Viêt Nam'},
  'Indonesia': {'de': 'Indonesien', 'fr': 'Indonésie'},
  'Malaysia': {'de': 'Malaysia', 'fr': 'Malaisie'},
  'Philippines': {'de': 'Philippinen', 'fr': 'Philippines'},
  'Singapore': {'de': 'Singapur', 'fr': 'Singapour'},
  'Taiwan': {'de': 'Taiwan', 'fr': 'Taïwan'},
  'Hong Kong': {'de': 'Hongkong', 'fr': 'Hong Kong'},
  'Australia': {'de': 'Australien', 'fr': 'Australie'},
  'New Zealand': {'de': 'Neuseeland', 'fr': 'Nouvelle-Zélande'},
  'Pakistan': {'de': 'Pakistan', 'fr': 'Pakistan'},
  'Bangladesh': {'de': 'Bangladesch', 'fr': 'Bangladesh'},
  'Sri Lanka': {'de': 'Sri Lanka', 'fr': 'Sri Lanka'},
  'Nepal': {'de': 'Nepal', 'fr': 'Népal'},
  'Myanmar': {'de': 'Myanmar', 'fr': 'Myanmar'},
  'Cambodia': {'de': 'Kambodscha', 'fr': 'Cambodge'},

  // Other
  'Russia': {'de': 'Russland', 'fr': 'Russie'},
  'Ukraine': {'de': 'Ukraine', 'fr': 'Ukraine'},
  'Georgia': {'de': 'Georgien', 'fr': 'Géorgie'},
  'Azerbaijan': {'de': 'Aserbaidschan', 'fr': 'Azerbaïdjan'},
  'Armenia': {'de': 'Armenien', 'fr': 'Arménie'},
  'Kazakhstan': {'de': 'Kasachstan', 'fr': 'Kazakhstan'},
  'Uzbekistan': {'de': 'Usbekistan', 'fr': 'Ouzbékistan'},
  'Moldova': {'de': 'Moldau', 'fr': 'Moldavie'},
};

/// Returns the localized country name for the given locale.
/// Falls back to the original English name if no translation exists.
String localizeCountry(String country, String locale) {
  if (locale == 'en') return country;
  final translations = countryTranslations[country];
  if (translations == null) return country;
  return translations[locale] ?? country;
}

// ── Reverse lookup ──────────────────────────────────────────────────────────
//
// Powers locale-aware country search: typing "Tunesien" (de) or "Tunisie"
// (fr) resolves to the canonical English "Tunisia" so downstream code that
// keys off country names (search, airport filtering, flag lookup) keeps
// working without every layer needing to know about translations.
//
// Lazily seeded the first time a reverse-lookup helper fires — building
// the map at app boot would be wasted work for users that never search.

Map<String, String>? _reverseCountryIndex;

/// Strip diacritics + lowercase + collapse whitespace so "tunesien", "Tunesien"
/// and "  TUNESIEN  " all resolve identically. Mirrors the normalisation used
/// in `city_translations.dart` for consistent behaviour across the two
/// reverse-lookup tables.
String _normalizeCountryQuery(String s) {
  // Combining-mark strip via NFD + filter. ASCII fast-path keeps the hot
  // call site (every keystroke during search) allocation-free for the
  // common case of plain English input.
  if (s.codeUnits.every((c) => c < 0x80)) {
    return s.trim().toLowerCase();
  }
  const diacritics = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'æ': 'ae',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'œ': 'oe',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ß': 'ss',
  };
  final lower = s.trim().toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(diacritics[ch] ?? ch);
  }
  return buf.toString();
}

void _seedCountryReverseIndex() {
  if (_reverseCountryIndex != null) return;
  final map = <String, String>{};
  for (final entry in countryTranslations.entries) {
    final canonical = entry.key;
    // Index the canonical English name itself so "Germany" / "germany" /
    // "GERMANY" all resolve to "Germany" (deals with case-only variants
    // without forcing every caller to call .toLowerCase first).
    map[_normalizeCountryQuery(canonical)] = canonical;
    // Plus every translation: de + fr.
    for (final loc in entry.value.values) {
      map[_normalizeCountryQuery(loc)] = canonical;
    }
  }
  _reverseCountryIndex = map;
}

/// Reverse lookup — given a free-form query in any of the three locales,
/// return the canonical English country name, or `null` if nothing matches.
///
/// <p>Examples:
/// <ul>
///   <li>`resolveCountryAlias("Tunesien")` → `"Tunisia"`</li>
///   <li>`resolveCountryAlias("Tunisie")`  → `"Tunisia"`</li>
///   <li>`resolveCountryAlias("Tunisia")`  → `"Tunisia"`</li>
///   <li>`resolveCountryAlias("Allemagne")` → `"Germany"`</li>
///   <li>`resolveCountryAlias("Royaume-Uni")` → `"United Kingdom"`</li>
///   <li>`resolveCountryAlias("xyz")` → `null`</li>
/// </ul>
///
/// <p>Mirrors the spirit of [resolveCityAlias] in `city_translations.dart`
/// so the airport / aircraft search bar can resolve country queries
/// regardless of the user's selected app language.
String? resolveCountryAlias(String query) {
  if (query.isEmpty) return null;
  _seedCountryReverseIndex();
  return _reverseCountryIndex![_normalizeCountryQuery(query)];
}

/// Substring-match helper — true if `query` appears (locale-insensitive)
/// inside the English name OR any of the German / French translations of
/// `countryEnglishName`.
///
/// <p>Used by aircraft / airport search filters so typing "Marok" in a
/// German UI matches "Morocco" (de: Marokko) without needing to switch
/// locales mid-search.
bool countryNameMatches(String countryEnglishName, String query) {
  final q = _normalizeCountryQuery(query);
  if (q.isEmpty) return false;
  if (_normalizeCountryQuery(countryEnglishName).contains(q)) return true;
  final translations = countryTranslations[countryEnglishName];
  if (translations == null) return false;
  for (final localized in translations.values) {
    if (_normalizeCountryQuery(localized).contains(q)) return true;
  }
  return false;
}
