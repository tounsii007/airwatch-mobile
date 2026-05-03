import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:airwatch_mobile/core/constants/api_constants.dart';
import 'package:airwatch_mobile/core/network/app_http_client.dart';

/// City-name localisation — the mobile mirror of the web app's
/// `src/lib/data/city-translations.ts`.
///
/// <h3>Two directions</h3>
/// <ul>
///   <li><b>Forward</b> ([localizeCity]) — "Nice" + "de" → "Nizza".</li>
///   <li><b>Reverse</b> ([resolveCityAlias], [cityNameMatches]) —
///       "Nizza" → "Nice", so airport search works across locales.</li>
/// </ul>
///
/// <h3>Three data layers (highest → lowest precedence)</h3>
/// <ol>
///   <li><b>Curated overrides</b> (~180 hand-reviewed world-class airport
///       cities in [_curated]). This is where upstream data-quality
///       bugs (slang, historical names, umlaut typos) are pinned to the
///       correct modern spelling.</li>
///   <li><b>Runtime-loaded `/data/city-i18n.json`</b> (~4,800 cities,
///       ~220 KB, fetched from `airwatch-api` at app boot). Good
///       fallback for mid-sized airports.</li>
///   <li><b>Original English name</b> — safe no-op fallback.</li>
/// </ol>
///
/// <p>Both the curated overrides AND the generated JSON come from the same
/// source the web app consumes, so a traveller who sees "Nizza" in the web
/// frontend will see the same label in the mobile app.

// ── Types ────────────────────────────────────────────────────────────────────
class _LocalizedNames {
  _LocalizedNames({required this.en, this.de, this.fr});
  final String en;
  final String? de;
  final String? fr;

  String? forLocale(String locale) {
    switch (locale) {
      case 'de':
        return de;
      case 'fr':
        return fr;
      default:
        return en;
    }
  }
}

// ── Layer 1: Curated overrides (~180 cities) ────────────────────────────────
// Every entry hand-verified against real-world usage. The upstream dataset
// sometimes returns historical names (Konstantinopel, Bombay, Preßburg),
// slang (Pantruche, Jo'anna, "The Big Apple") or typos (Zuerich, Ōsaka) —
// these overrides pin the correct modern spelling regardless of source.
final Map<String, _LocalizedNames> _curated = {
  // ── Europe — DACH ─────────────────────────────────────────────────────────
  'Munich': _LocalizedNames(en: 'Munich', de: 'München', fr: 'Munich'),
  'Cologne': _LocalizedNames(en: 'Cologne', de: 'Köln', fr: 'Cologne'),
  'Nuremberg': _LocalizedNames(
    en: 'Nuremberg',
    de: 'Nürnberg',
    fr: 'Nuremberg',
  ),
  'Dusseldorf': _LocalizedNames(
    en: 'Dusseldorf',
    de: 'Düsseldorf',
    fr: 'Düsseldorf',
  ),
  'Hanover': _LocalizedNames(en: 'Hanover', de: 'Hannover', fr: 'Hanovre'),
  'Vienna': _LocalizedNames(en: 'Vienna', de: 'Wien', fr: 'Vienne'),
  'Zurich': _LocalizedNames(en: 'Zurich', de: 'Zürich', fr: 'Zurich'),
  'Geneva': _LocalizedNames(en: 'Geneva', de: 'Genf', fr: 'Genève'),
  'Basel': _LocalizedNames(en: 'Basel', de: 'Basel', fr: 'Bâle'),
  'Bern': _LocalizedNames(en: 'Bern', de: 'Bern', fr: 'Berne'),

  // ── Europe — Romance & Benelux ───────────────────────────────────────────
  'Nice': _LocalizedNames(en: 'Nice', de: 'Nizza', fr: 'Nice'),
  'Lyon': _LocalizedNames(en: 'Lyon', de: 'Lyon', fr: 'Lyon'),
  'Marseille': _LocalizedNames(
    en: 'Marseille',
    de: 'Marseille',
    fr: 'Marseille',
  ),
  'Strasbourg': _LocalizedNames(
    en: 'Strasbourg',
    de: 'Straßburg',
    fr: 'Strasbourg',
  ),
  'Brussels': _LocalizedNames(en: 'Brussels', de: 'Brüssel', fr: 'Bruxelles'),
  'Antwerp': _LocalizedNames(en: 'Antwerp', de: 'Antwerpen', fr: 'Anvers'),
  'Rome': _LocalizedNames(en: 'Rome', de: 'Rom', fr: 'Rome'),
  'Milan': _LocalizedNames(en: 'Milan', de: 'Mailand', fr: 'Milan'),
  'Venice': _LocalizedNames(en: 'Venice', de: 'Venedig', fr: 'Venise'),
  'Florence': _LocalizedNames(en: 'Florence', de: 'Florenz', fr: 'Florence'),
  'Naples': _LocalizedNames(en: 'Naples', de: 'Neapel', fr: 'Naples'),
  'Turin': _LocalizedNames(en: 'Turin', de: 'Turin', fr: 'Turin'),
  'Bologna': _LocalizedNames(en: 'Bologna', de: 'Bologna', fr: 'Bologne'),
  'Genoa': _LocalizedNames(en: 'Genoa', de: 'Genua', fr: 'Gênes'),
  // Spain
  'Madrid': _LocalizedNames(en: 'Madrid', de: 'Madrid', fr: 'Madrid'),
  'Seville': _LocalizedNames(en: 'Seville', de: 'Sevilla', fr: 'Séville'),
  'Valencia': _LocalizedNames(en: 'Valencia', de: 'Valencia', fr: 'Valence'),
  'Malaga': _LocalizedNames(en: 'Málaga', de: 'Málaga', fr: 'Malaga'),
  'Bilbao': _LocalizedNames(en: 'Bilbao', de: 'Bilbao', fr: 'Bilbao'),
  'Zaragoza': _LocalizedNames(en: 'Zaragoza', de: 'Saragossa', fr: 'Saragosse'),
  'Majorca': _LocalizedNames(en: 'Majorca', de: 'Mallorca', fr: 'Majorque'),
  'Porto': _LocalizedNames(en: 'Porto', de: 'Porto', fr: 'Porto'),

  // ── Europe — Nordic / Baltic / Slavic ────────────────────────────────────
  'Copenhagen': _LocalizedNames(
    en: 'Copenhagen',
    de: 'Kopenhagen',
    fr: 'Copenhague',
  ),
  'Stockholm': _LocalizedNames(
    en: 'Stockholm',
    de: 'Stockholm',
    fr: 'Stockholm',
  ),
  'Gothenburg': _LocalizedNames(
    en: 'Gothenburg',
    de: 'Göteborg',
    fr: 'Göteborg',
  ),
  'Helsinki': _LocalizedNames(en: 'Helsinki', de: 'Helsinki', fr: 'Helsinki'),
  'Oslo': _LocalizedNames(en: 'Oslo', de: 'Oslo', fr: 'Oslo'),
  'Bergen': _LocalizedNames(en: 'Bergen', de: 'Bergen', fr: 'Bergen'),
  'Prague': _LocalizedNames(en: 'Prague', de: 'Prag', fr: 'Prague'),
  'Warsaw': _LocalizedNames(en: 'Warsaw', de: 'Warschau', fr: 'Varsovie'),
  'Krakow': _LocalizedNames(en: 'Krakow', de: 'Krakau', fr: 'Cracovie'),
  'Wroclaw': _LocalizedNames(en: 'Wroclaw', de: 'Breslau', fr: 'Wrocław'),
  'Gdansk': _LocalizedNames(en: 'Gdansk', de: 'Danzig', fr: 'Gdańsk'),
  'Budapest': _LocalizedNames(en: 'Budapest', de: 'Budapest', fr: 'Budapest'),
  'Bucharest': _LocalizedNames(en: 'Bucharest', de: 'Bukarest', fr: 'Bucarest'),
  // Force modern name — upstream still returns "Preßburg" (pre-1918).
  'Bratislava': _LocalizedNames(
    en: 'Bratislava',
    de: 'Bratislava',
    fr: 'Bratislava',
  ),
  'Ljubljana': _LocalizedNames(
    en: 'Ljubljana',
    de: 'Ljubljana',
    fr: 'Ljubljana',
  ),
  // Force modern name — upstream still returns "Agram" (k.u.k. era).
  'Zagreb': _LocalizedNames(en: 'Zagreb', de: 'Zagreb', fr: 'Zagreb'),
  'Belgrade': _LocalizedNames(en: 'Belgrade', de: 'Belgrad', fr: 'Belgrade'),
  'Sarajevo': _LocalizedNames(en: 'Sarajevo', de: 'Sarajevo', fr: 'Sarajevo'),
  'Sofia': _LocalizedNames(en: 'Sofia', de: 'Sofia', fr: 'Sofia'),
  'Skopje': _LocalizedNames(en: 'Skopje', de: 'Skopje', fr: 'Skopje'),
  'Tirana': _LocalizedNames(en: 'Tirana', de: 'Tirana', fr: 'Tirana'),
  'Thessaloniki': _LocalizedNames(
    en: 'Thessaloniki',
    de: 'Thessaloniki',
    fr: 'Thessalonique',
  ),
  // Force modern name — upstream still returns "Revel" (pre-independence).
  'Tallinn': _LocalizedNames(en: 'Tallinn', de: 'Tallinn', fr: 'Tallinn'),
  'Riga': _LocalizedNames(en: 'Riga', de: 'Riga', fr: 'Riga'),
  'Vilnius': _LocalizedNames(en: 'Vilnius', de: 'Vilnius', fr: 'Vilnius'),
  'Minsk': _LocalizedNames(en: 'Minsk', de: 'Minsk', fr: 'Minsk'),
  'Chisinau': _LocalizedNames(en: 'Chișinău', de: 'Kischinau', fr: 'Chișinău'),
  'Moscow': _LocalizedNames(en: 'Moscow', de: 'Moskau', fr: 'Moscou'),
  'Saint Petersburg': _LocalizedNames(
    en: 'Saint Petersburg',
    de: 'Sankt Petersburg',
    fr: 'Saint-Pétersbourg',
  ),
  'Kyiv': _LocalizedNames(en: 'Kyiv', de: 'Kiew', fr: 'Kiev'),
  // Caucasus
  'Tbilisi': _LocalizedNames(en: 'Tbilisi', de: 'Tiflis', fr: 'Tbilissi'),
  'Yerevan': _LocalizedNames(en: 'Yerevan', de: 'Jerewan', fr: 'Erevan'),
  'Baku': _LocalizedNames(en: 'Baku', de: 'Baku', fr: 'Bakou'),

  // ── Europe — Mediterranean ───────────────────────────────────────────────
  'Athens': _LocalizedNames(en: 'Athens', de: 'Athen', fr: 'Athènes'),
  'Istanbul': _LocalizedNames(en: 'Istanbul', de: 'Istanbul', fr: 'Istanbul'),
  'Lisbon': _LocalizedNames(en: 'Lisbon', de: 'Lissabon', fr: 'Lisbonne'),

  // ── UK & Ireland ─────────────────────────────────────────────────────────
  'London': _LocalizedNames(en: 'London', de: 'London', fr: 'Londres'),
  'Edinburgh': _LocalizedNames(
    en: 'Edinburgh',
    de: 'Edinburgh',
    fr: 'Édimbourg',
  ),
  'Dublin': _LocalizedNames(en: 'Dublin', de: 'Dublin', fr: 'Dublin'),

  // ── Middle East / North Africa ───────────────────────────────────────────
  'Cairo': _LocalizedNames(en: 'Cairo', de: 'Kairo', fr: 'Le Caire'),
  'Algiers': _LocalizedNames(en: 'Algiers', de: 'Algier', fr: 'Alger'),
  'Tunis': _LocalizedNames(en: 'Tunis', de: 'Tunis', fr: 'Tunis'),
  'Casablanca': _LocalizedNames(
    en: 'Casablanca',
    de: 'Casablanca',
    fr: 'Casablanca',
  ),
  'Marrakech': _LocalizedNames(
    en: 'Marrakech',
    de: 'Marrakesch',
    fr: 'Marrakech',
  ),
  'Jeddah': _LocalizedNames(en: 'Jeddah', de: 'Dschidda', fr: 'Djeddah'),
  'Riyadh': _LocalizedNames(en: 'Riyadh', de: 'Riad', fr: 'Riyad'),
  'Abu Dhabi': _LocalizedNames(
    en: 'Abu Dhabi',
    de: 'Abu Dhabi',
    fr: 'Abou Dabi',
  ),
  'Dubai': _LocalizedNames(en: 'Dubai', de: 'Dubai', fr: 'Dubaï'),
  'Doha': _LocalizedNames(en: 'Doha', de: 'Doha', fr: 'Doha'),
  'Tel Aviv': _LocalizedNames(en: 'Tel Aviv', de: 'Tel Aviv', fr: 'Tel-Aviv'),
  'Jerusalem': _LocalizedNames(
    en: 'Jerusalem',
    de: 'Jerusalem',
    fr: 'Jérusalem',
  ),
  'Damascus': _LocalizedNames(en: 'Damascus', de: 'Damaskus', fr: 'Damas'),
  'Baghdad': _LocalizedNames(en: 'Baghdad', de: 'Bagdad', fr: 'Bagdad'),
  'Tehran': _LocalizedNames(en: 'Tehran', de: 'Teheran', fr: 'Téhéran'),
  'Isfahan': _LocalizedNames(en: 'Isfahan', de: 'Isfahan', fr: 'Ispahan'),
  // Upstream has "Alexandria" for Mashhad — data corruption override.
  'Mashhad': _LocalizedNames(en: 'Mashhad', de: 'Maschhad', fr: 'Mashhad'),
  'Beirut': _LocalizedNames(en: 'Beirut', de: 'Beirut', fr: 'Beyrouth'),
  'Amman': _LocalizedNames(en: 'Amman', de: 'Amman', fr: 'Amman'),
  'Muscat': _LocalizedNames(en: 'Muscat', de: 'Maskat', fr: 'Mascate'),
  'Kuwait City': _LocalizedNames(
    en: 'Kuwait City',
    de: 'Kuwait-Stadt',
    fr: 'Koweït',
  ),
  'Manama': _LocalizedNames(en: 'Manama', de: 'Manama', fr: 'Manama'),
  'Medina': _LocalizedNames(en: 'Medina', de: 'Medina', fr: 'Médine'),
  'Mecca': _LocalizedNames(en: 'Mecca', de: 'Mekka', fr: 'La Mecque'),
  'Tripoli': _LocalizedNames(en: 'Tripoli', de: 'Tripolis', fr: 'Tripoli'),

  // ── Sub-Saharan Africa ───────────────────────────────────────────────────
  'Nairobi': _LocalizedNames(en: 'Nairobi', de: 'Nairobi', fr: 'Nairobi'),
  'Johannesburg': _LocalizedNames(
    en: 'Johannesburg',
    de: 'Johannesburg',
    fr: 'Johannesbourg',
  ),
  'Cape Town': _LocalizedNames(en: 'Cape Town', de: 'Kapstadt', fr: 'Le Cap'),
  'Durban': _LocalizedNames(en: 'Durban', de: 'Durban', fr: 'Durban'),
  'Lagos': _LocalizedNames(en: 'Lagos', de: 'Lagos', fr: 'Lagos'),
  'Abuja': _LocalizedNames(en: 'Abuja', de: 'Abuja', fr: 'Abuja'),
  'Accra': _LocalizedNames(en: 'Accra', de: 'Accra', fr: 'Accra'),
  'Addis Ababa': _LocalizedNames(
    en: 'Addis Ababa',
    de: 'Addis Abeba',
    fr: 'Addis-Abeba',
  ),
  'Khartoum': _LocalizedNames(en: 'Khartoum', de: 'Khartum', fr: 'Khartoum'),
  'Dar es Salaam': _LocalizedNames(
    en: 'Dar es Salaam',
    de: 'Daressalam',
    fr: 'Dar es Salaam',
  ),
  'Kigali': _LocalizedNames(en: 'Kigali', de: 'Kigali', fr: 'Kigali'),
  'Kampala': _LocalizedNames(en: 'Kampala', de: 'Kampala', fr: 'Kampala'),
  'Luanda': _LocalizedNames(en: 'Luanda', de: 'Luanda', fr: 'Luanda'),
  'Harare': _LocalizedNames(en: 'Harare', de: 'Harare', fr: 'Harare'),
  'Dakar': _LocalizedNames(en: 'Dakar', de: 'Dakar', fr: 'Dakar'),
  'Abidjan': _LocalizedNames(en: 'Abidjan', de: 'Abidjan', fr: 'Abidjan'),

  // ── East & Southeast Asia ────────────────────────────────────────────────
  'Beijing': _LocalizedNames(en: 'Beijing', de: 'Peking', fr: 'Pékin'),
  'Shanghai': _LocalizedNames(en: 'Shanghai', de: 'Schanghai', fr: 'Shanghai'),
  'Guangzhou': _LocalizedNames(en: 'Guangzhou', de: 'Guangzhou', fr: 'Canton'),
  'Shenzhen': _LocalizedNames(en: 'Shenzhen', de: 'Shenzhen', fr: 'Shenzhen'),
  'Chengdu': _LocalizedNames(en: 'Chengdu', de: 'Chengdu', fr: 'Chengdu'),
  'Chongqing': _LocalizedNames(
    en: 'Chongqing',
    de: 'Chongqing',
    fr: 'Chongqing',
  ),
  'Xi\'an': _LocalizedNames(en: "Xi'an", de: "Xi'an", fr: "Xi'an"),
  'Wuhan': _LocalizedNames(en: 'Wuhan', de: 'Wuhan', fr: 'Wuhan'),
  'Nanjing': _LocalizedNames(en: 'Nanjing', de: 'Nanking', fr: 'Nankin'),
  'Macau': _LocalizedNames(en: 'Macau', de: 'Macao', fr: 'Macao'),
  'Hong Kong': _LocalizedNames(
    en: 'Hong Kong',
    de: 'Hongkong',
    fr: 'Hong Kong',
  ),
  'Taipei': _LocalizedNames(en: 'Taipei', de: 'Taipeh', fr: 'Taipei'),
  'Tokyo': _LocalizedNames(en: 'Tokyo', de: 'Tokio', fr: 'Tokyo'),
  'Osaka': _LocalizedNames(en: 'Osaka', de: 'Osaka', fr: 'Osaka'),
  'Kyoto': _LocalizedNames(en: 'Kyoto', de: 'Kyōto', fr: 'Kyoto'),
  'Nagoya': _LocalizedNames(en: 'Nagoya', de: 'Nagoya', fr: 'Nagoya'),
  'Sapporo': _LocalizedNames(en: 'Sapporo', de: 'Sapporo', fr: 'Sapporo'),
  'Fukuoka': _LocalizedNames(en: 'Fukuoka', de: 'Fukuoka', fr: 'Fukuoka'),
  'Seoul': _LocalizedNames(en: 'Seoul', de: 'Seoul', fr: 'Séoul'),
  'Busan': _LocalizedNames(en: 'Busan', de: 'Busan', fr: 'Busan'),
  'Singapore': _LocalizedNames(
    en: 'Singapore',
    de: 'Singapur',
    fr: 'Singapour',
  ),
  'Bangkok': _LocalizedNames(en: 'Bangkok', de: 'Bangkok', fr: 'Bangkok'),
  'Hanoi': _LocalizedNames(en: 'Hanoi', de: 'Hanoi', fr: 'Hanoï'),
  'Ho Chi Minh City': _LocalizedNames(
    en: 'Ho Chi Minh City',
    de: 'Ho-Chi-Minh-Stadt',
    fr: 'Hô Chi Minh-Ville',
  ),
  'Manila': _LocalizedNames(en: 'Manila', de: 'Manila', fr: 'Manille'),
  'Jakarta': _LocalizedNames(en: 'Jakarta', de: 'Jakarta', fr: 'Jakarta'),
  'Kuala Lumpur': _LocalizedNames(
    en: 'Kuala Lumpur',
    de: 'Kuala Lumpur',
    fr: 'Kuala Lumpur',
  ),
  'Yangon': _LocalizedNames(en: 'Yangon', de: 'Rangun', fr: 'Rangoun'),
  'Phnom Penh': _LocalizedNames(
    en: 'Phnom Penh',
    de: 'Phnom Penh',
    fr: 'Phnom Penh',
  ),
  'Vientiane': _LocalizedNames(
    en: 'Vientiane',
    de: 'Vientiane',
    fr: 'Vientiane',
  ),

  // ── South Asia ───────────────────────────────────────────────────────────
  'Mumbai': _LocalizedNames(en: 'Mumbai', de: 'Mumbai', fr: 'Bombay'),
  'Delhi': _LocalizedNames(en: 'Delhi', de: 'Delhi', fr: 'Delhi'),
  'Kolkata': _LocalizedNames(en: 'Kolkata', de: 'Kalkutta', fr: 'Calcutta'),
  'Chennai': _LocalizedNames(en: 'Chennai', de: 'Chennai', fr: 'Chennai'),
  'Bangalore': _LocalizedNames(
    en: 'Bangalore',
    de: 'Bangalore',
    fr: 'Bangalore',
  ),
  'Hyderabad': _LocalizedNames(
    en: 'Hyderabad',
    de: 'Hyderabad',
    fr: 'Hyderabad',
  ),
  'Karachi': _LocalizedNames(en: 'Karachi', de: 'Karatschi', fr: 'Karachi'),
  'Lahore': _LocalizedNames(en: 'Lahore', de: 'Lahore', fr: 'Lahore'),
  'Islamabad': _LocalizedNames(
    en: 'Islamabad',
    de: 'Islamabad',
    fr: 'Islamabad',
  ),
  'Colombo': _LocalizedNames(en: 'Colombo', de: 'Colombo', fr: 'Colombo'),
  'Dhaka': _LocalizedNames(en: 'Dhaka', de: 'Dhaka', fr: 'Dacca'),
  'Kathmandu': _LocalizedNames(
    en: 'Kathmandu',
    de: 'Kathmandu',
    fr: 'Katmandou',
  ),

  // ── Central Asia ─────────────────────────────────────────────────────────
  // Upstream has "Werny" (tsarist era) — override.
  'Almaty': _LocalizedNames(en: 'Almaty', de: 'Almaty', fr: 'Almaty'),
  'Astana': _LocalizedNames(en: 'Astana', de: 'Astana', fr: 'Astana'),
  'Tashkent': _LocalizedNames(en: 'Tashkent', de: 'Taschkent', fr: 'Tachkent'),
  'Ulaanbaatar': _LocalizedNames(
    en: 'Ulaanbaatar',
    de: 'Ulan-Bator',
    fr: 'Oulan-Bator',
  ),

  // ── North America ────────────────────────────────────────────────────────
  'New York': _LocalizedNames(en: 'New York', de: 'New York', fr: 'New York'),
  'Los Angeles': _LocalizedNames(
    en: 'Los Angeles',
    de: 'Los Angeles',
    fr: 'Los Angeles',
  ),
  'Chicago': _LocalizedNames(en: 'Chicago', de: 'Chicago', fr: 'Chicago'),
  'Philadelphia': _LocalizedNames(
    en: 'Philadelphia',
    de: 'Philadelphia',
    fr: 'Philadelphie',
  ),
  'San Francisco': _LocalizedNames(
    en: 'San Francisco',
    de: 'San Francisco',
    fr: 'San Francisco',
  ),
  'Seattle': _LocalizedNames(en: 'Seattle', de: 'Seattle', fr: 'Seattle'),
  'Boston': _LocalizedNames(en: 'Boston', de: 'Boston', fr: 'Boston'),
  'Miami': _LocalizedNames(en: 'Miami', de: 'Miami', fr: 'Miami'),
  'Atlanta': _LocalizedNames(en: 'Atlanta', de: 'Atlanta', fr: 'Atlanta'),
  'Houston': _LocalizedNames(en: 'Houston', de: 'Houston', fr: 'Houston'),
  'Dallas': _LocalizedNames(en: 'Dallas', de: 'Dallas', fr: 'Dallas'),
  'Denver': _LocalizedNames(en: 'Denver', de: 'Denver', fr: 'Denver'),
  'Las Vegas': _LocalizedNames(
    en: 'Las Vegas',
    de: 'Las Vegas',
    fr: 'Las Vegas',
  ),
  'Phoenix': _LocalizedNames(en: 'Phoenix', de: 'Phoenix', fr: 'Phoenix'),
  'Washington': _LocalizedNames(
    en: 'Washington',
    de: 'Washington',
    fr: 'Washington',
  ),
  'Orlando': _LocalizedNames(en: 'Orlando', de: 'Orlando', fr: 'Orlando'),
  'Detroit': _LocalizedNames(en: 'Detroit', de: 'Detroit', fr: 'Détroit'),
  'Pittsburgh': _LocalizedNames(
    en: 'Pittsburgh',
    de: 'Pittsburgh',
    fr: 'Pittsburgh',
  ),
  'Minneapolis': _LocalizedNames(
    en: 'Minneapolis',
    de: 'Minneapolis',
    fr: 'Minneapolis',
  ),
  'Charlotte': _LocalizedNames(
    en: 'Charlotte',
    de: 'Charlotte',
    fr: 'Charlotte',
  ),
  'Nashville': _LocalizedNames(
    en: 'Nashville',
    de: 'Nashville',
    fr: 'Nashville',
  ),
  'New Orleans': _LocalizedNames(
    en: 'New Orleans',
    de: 'New Orleans',
    fr: 'La Nouvelle-Orléans',
  ),
  'Salt Lake City': _LocalizedNames(
    en: 'Salt Lake City',
    de: 'Salt Lake City',
    fr: 'Salt Lake City',
  ),
  'Kansas City': _LocalizedNames(
    en: 'Kansas City',
    de: 'Kansas City',
    fr: 'Kansas City',
  ),
  'St. Louis': _LocalizedNames(
    en: 'St. Louis',
    de: 'St. Louis',
    fr: 'Saint-Louis',
  ),
  'Cincinnati': _LocalizedNames(
    en: 'Cincinnati',
    de: 'Cincinnati',
    fr: 'Cincinnati',
  ),
  'San Diego': _LocalizedNames(
    en: 'San Diego',
    de: 'San Diego',
    fr: 'San Diego',
  ),
  'Tampa': _LocalizedNames(en: 'Tampa', de: 'Tampa', fr: 'Tampa'),
  'Portland': _LocalizedNames(en: 'Portland', de: 'Portland', fr: 'Portland'),
  // Canada
  'Toronto': _LocalizedNames(en: 'Toronto', de: 'Toronto', fr: 'Toronto'),
  'Montreal': _LocalizedNames(en: 'Montreal', de: 'Montréal', fr: 'Montréal'),
  'Quebec': _LocalizedNames(en: 'Quebec', de: 'Québec', fr: 'Québec'),
  'Vancouver': _LocalizedNames(
    en: 'Vancouver',
    de: 'Vancouver',
    fr: 'Vancouver',
  ),
  'Ottawa': _LocalizedNames(en: 'Ottawa', de: 'Ottawa', fr: 'Ottawa'),
  'Calgary': _LocalizedNames(en: 'Calgary', de: 'Calgary', fr: 'Calgary'),
  'Edmonton': _LocalizedNames(en: 'Edmonton', de: 'Edmonton', fr: 'Edmonton'),
  'Winnipeg': _LocalizedNames(en: 'Winnipeg', de: 'Winnipeg', fr: 'Winnipeg'),
  'Halifax': _LocalizedNames(en: 'Halifax', de: 'Halifax', fr: 'Halifax'),

  // ── Latin America ────────────────────────────────────────────────────────
  'Mexico City': _LocalizedNames(
    en: 'Mexico City',
    de: 'Mexiko-Stadt',
    fr: 'Mexico',
  ),
  'Cancun': _LocalizedNames(en: 'Cancún', de: 'Cancún', fr: 'Cancún'),
  'Guadalajara': _LocalizedNames(
    en: 'Guadalajara',
    de: 'Guadalajara',
    fr: 'Guadalajara',
  ),
  'Sao Paulo': _LocalizedNames(
    en: 'São Paulo',
    de: 'São Paulo',
    fr: 'São Paulo',
  ),
  'Rio de Janeiro': _LocalizedNames(
    en: 'Rio de Janeiro',
    de: 'Rio de Janeiro',
    fr: 'Rio de Janeiro',
  ),
  'Brasilia': _LocalizedNames(en: 'Brasília', de: 'Brasília', fr: 'Brasilia'),
  'Buenos Aires': _LocalizedNames(
    en: 'Buenos Aires',
    de: 'Buenos Aires',
    fr: 'Buenos Aires',
  ),
  'Lima': _LocalizedNames(en: 'Lima', de: 'Lima', fr: 'Lima'),
  'Santiago': _LocalizedNames(
    en: 'Santiago',
    de: 'Santiago de Chile',
    fr: 'Santiago du Chili',
  ),
  'Bogota': _LocalizedNames(en: 'Bogota', de: 'Bogotá', fr: 'Bogota'),
  'Caracas': _LocalizedNames(en: 'Caracas', de: 'Caracas', fr: 'Caracas'),
  'Quito': _LocalizedNames(en: 'Quito', de: 'Quito', fr: 'Quito'),
  'La Paz': _LocalizedNames(en: 'La Paz', de: 'La Paz', fr: 'La Paz'),
  'Montevideo': _LocalizedNames(
    en: 'Montevideo',
    de: 'Montevideo',
    fr: 'Montevideo',
  ),
  'Asuncion': _LocalizedNames(en: 'Asunción', de: 'Asunción', fr: 'Asuncion'),
  'Panama City': _LocalizedNames(
    en: 'Panama City',
    de: 'Panama-Stadt',
    fr: 'Panama',
  ),
  'Guatemala City': _LocalizedNames(
    en: 'Guatemala City',
    de: 'Guatemala-Stadt',
    fr: 'Guatemala',
  ),
  'San Jose': _LocalizedNames(en: 'San José', de: 'San José', fr: 'San José'),
  'Havana': _LocalizedNames(en: 'Havana', de: 'Havanna', fr: 'La Havane'),
  'Santo Domingo': _LocalizedNames(
    en: 'Santo Domingo',
    de: 'Santo Domingo',
    fr: 'Saint-Domingue',
  ),

  // ── Oceania ──────────────────────────────────────────────────────────────
  'Sydney': _LocalizedNames(en: 'Sydney', de: 'Sydney', fr: 'Sydney'),
  'Melbourne': _LocalizedNames(
    en: 'Melbourne',
    de: 'Melbourne',
    fr: 'Melbourne',
  ),
  'Brisbane': _LocalizedNames(en: 'Brisbane', de: 'Brisbane', fr: 'Brisbane'),
  'Perth': _LocalizedNames(en: 'Perth', de: 'Perth', fr: 'Perth'),
  'Auckland': _LocalizedNames(en: 'Auckland', de: 'Auckland', fr: 'Auckland'),
};

// ── Normalisation + merged lookup tables ────────────────────────────────────
/// Lowercase + combining-mark-strip → so "Köln", "KÖLN" and "Koln" all
/// resolve to the same key. Mirrors the web app's behaviour exactly.
String _normalize(String name) {
  // Dart's String has no NFD helper, but diacritic removal via a lookup
  // table covers the characters actually present in city names.
  const withDiacritics =
      'áàâäãåçéèêëíìîïñóòôöõøßúùûüýÿÁÀÂÄÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕØÚÙÛÜÝ';
  const stripped = 'aaaaaaceeeeiiiinoooooosuuuuyyAAAAAACEEEEIIIINOOOOOUUUUY';
  final buf = StringBuffer();
  for (final rune in name.runes) {
    final ch = String.fromCharCode(rune);
    final idx = withDiacritics.indexOf(ch);
    buf.write(idx >= 0 ? stripped[idx] : ch);
  }
  return buf.toString().toLowerCase().trim();
}

final Map<String, _LocalizedNames> _forward = {};
final Map<String, String> _reverse = {};

void _registerEntry(_LocalizedNames entry) {
  final key = _normalize(entry.en);
  _forward[key] = entry;
  _reverse[key] = entry.en;
  if (entry.de != null) _reverse[_normalize(entry.de!)] = entry.en;
  if (entry.fr != null) _reverse[_normalize(entry.fr!)] = entry.en;
}

bool _seeded = false;
void _seed() {
  if (_seeded) return;
  _seeded = true;
  for (final entry in _curated.values) {
    _registerEntry(entry);
  }
}

// ── Runtime loader ───────────────────────────────────────────────────────────
Future<void>? _loadFuture;

/// Fetches `/data/city-i18n.json` from the backend and merges entries
/// into the lookup tables. The curated layer always wins (existing keys are
/// never overwritten by generated data).
///
/// <p>Call once at app boot — subsequent invocations share the same future.
Future<void> loadCityI18n({Dio? dio}) {
  _seed();
  if (_loadFuture != null) return _loadFuture!;
  _loadFuture = _doLoad(dio ?? AppHttpClient.create());
  return _loadFuture!;
}

Future<void> _doLoad(Dio dio) async {
  try {
    final response = await dio.get<dynamic>(ApiConstants.cityI18n);
    if (response.statusCode != 200 || response.data == null) return;
    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    for (final raw in data.values) {
      if (raw is! Map) continue;
      final en = raw['en'] as String?;
      if (en == null) continue;
      final key = _normalize(en);
      // Curated layer wins.
      if (_forward.containsKey(key)) continue;
      _registerEntry(
        _LocalizedNames(
          en: en,
          de: raw['de'] as String?,
          fr: raw['fr'] as String?,
        ),
      );
    }
  } catch (_) {
    // Silent fallback — the curated layer is usable on its own and we retry
    // on the next [loadCityI18n] call (the future is reset by resetting
    // _loadFuture below).
    _loadFuture = null;
  }
}

// ── Public API ──────────────────────────────────────────────────────────────
/// Forward display lookup. Unknown names and en locale pass through unchanged.
///
/// <p>Also understands compound airport labels: "London Heathrow" with
/// `locale = 'fr'` returns "Londres Heathrow" because the "London"
/// prefix has a known translation.
String localizeCity(String city, String locale) {
  if (city.isEmpty) return city;
  if (locale == 'en') return city;
  _seed();
  final entry = _forward[_normalize(city)];
  if (entry != null) return entry.forLocale(locale) ?? city;
  // Compound-name handling: split on first space, translate prefix only.
  final spaceIdx = city.indexOf(' ');
  if (spaceIdx > 0) {
    final prefix = city.substring(0, spaceIdx);
    final rest = city.substring(spaceIdx + 1);
    final prefixEntry = _forward[_normalize(prefix)];
    if (prefixEntry != null) {
      final translatedPrefix = prefixEntry.forLocale(locale) ?? prefixEntry.en;
      if (translatedPrefix != prefix) return '$translatedPrefix $rest';
    }
  }
  return city;
}

/// Reverse lookup — free-form query in any of the three locales → canonical
/// English name, or `null` if nothing matches.
String? resolveCityAlias(String query) {
  if (query.isEmpty) return null;
  _seed();
  return _reverse[_normalize(query)];
}

/// Substring-match helper for airport search. True if `query` appears
/// (locale- and diacritic-insensitive) in any language variant of
/// `cityEnglishName`. Also handles compound prefixes, so typing
/// "nizza" finds "Nice Côte d'Azur".
bool cityNameMatches(String cityEnglishName, String query) {
  final q = _normalize(query);
  if (q.isEmpty) return false;
  _seed();
  final whole = _forward[_normalize(cityEnglishName)];
  if (whole != null) {
    if (_normalize(whole.en).contains(q)) return true;
    if (whole.de != null && _normalize(whole.de!).contains(q)) return true;
    if (whole.fr != null && _normalize(whole.fr!).contains(q)) return true;
  }
  final spaceIdx = cityEnglishName.indexOf(' ');
  if (spaceIdx > 0) {
    final prefix = cityEnglishName.substring(0, spaceIdx);
    final entry = _forward[_normalize(prefix)];
    if (entry != null) {
      if (_normalize(entry.en).contains(q)) return true;
      if (entry.de != null && _normalize(entry.de!).contains(q)) return true;
      if (entry.fr != null && _normalize(entry.fr!).contains(q)) return true;
    }
  }
  return _normalize(cityEnglishName).contains(q);
}

/// Legacy back-compat: exposes the old-shape map so pre-existing callers
/// (if any) keep compiling. Prefer [localizeCity] / [cityNameMatches]
/// for new code.
///
/// @deprecated Use [localizeCity].
@Deprecated('Use localizeCity / cityNameMatches / resolveCityAlias')
final Map<String, Map<String, String>> cityTranslations = {
  for (final entry in _curated.entries)
    entry.key: {
      if (entry.value.de != null) 'de': entry.value.de!,
      if (entry.value.fr != null) 'fr': entry.value.fr!,
    },
};
