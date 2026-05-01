/// Fixes UTF-8 double-encoding (mojibake) in text data.
/// Typically occurs when UTF-8 text is decoded as Latin-1.
class TextNormalizer {
  static final _mojibakeMap = <String, String>{
    'Ã¨': 'è',
    'Ã©': 'é',
    'Ãª': 'ê',
    'Ã«': 'ë',
    'Ã ': 'à',
    'Ã¡': 'á',
    'Ã¢': 'â',
    'Ã¤': 'ä',
    'Ã£': 'ã',
    'Ã§': 'ç',
    'Ã´': 'ô',
    'Ã¶': 'ö',
    'Ã³': 'ó',
    'Ã²': 'ò',
    'Ã¹': 'ù',
    'Ã»': 'û',
    'Ã¼': 'ü',
    'Ã®': 'î',
    'Ã¯': 'ï',
    'Ã±': 'ñ',
    'Ã­': 'í',
    'Å"': 'œ',
    'Å¡': 'š',
    'ÄŸ': 'ğ',
    'Ä±': 'ı',
    'Åž': 'Ş',
    'ÅŸ': 'ş',
    'Ã‡': 'Ç',
    'Ãœ': 'Ü',
    'Ã–': 'Ö',
    'Ã„': 'Ä',
    'Ã‰': 'É',
    'Ã€': 'À',
    'Â°': '°',
    'Â': '',
  };

  static final _mojibakePattern = RegExp(
    _mojibakeMap.keys.map(RegExp.escape).join('|'),
  );

  /// Fix mojibake in a single regex pass (more efficient than chained replaceAll).
  static String fixMojibake(String input) {
    return input.replaceAllMapped(
      _mojibakePattern,
      (match) => _mojibakeMap[match.group(0)!] ?? match.group(0)!,
    );
  }
}
