/// RFC 5545 .ics generator — Dart port of airwatch-web's
/// `icsExport.ts` (commit cd26298).
///
/// <h3>Why hand-rolled</h3>
/// The set of fields we emit is tiny (UID, DTSTAMP, DTSTART, DTEND,
/// SUMMARY, LOCATION, DESCRIPTION, URL). Every Dart pub.dev option is
/// either dormant or pulls a date library. RFC 5545's line-folding +
/// escaping rules fit in ~50 lines.
///
/// <h3>Use case in AirWatch Mobile</h3>
/// The Saved screen exposes "Export .ics" — bundles every saved
/// flight + airport + airline into a calendar file the user can
/// share via the system share-sheet (system Files / Mail /
/// Google Calendar / Apple Calendar handle import).
library;

class IcsEvent {
  /// Stable per-item id; we suffix it with `@airwatch.app` for RFC 5545.
  final String id;

  /// Event start (UTC instant).
  final DateTime start;

  /// Event end. When null we use [start] + 1 hour.
  final DateTime? end;

  /// One-line title (becomes SUMMARY).
  final String title;

  /// Optional venue / airport / coordinates (becomes LOCATION).
  final String? location;

  /// Multi-line free text (becomes DESCRIPTION).
  final String? description;

  /// Optional URL the calendar app can render as a link.
  final String? url;

  const IcsEvent({
    required this.id,
    required this.start,
    required this.title,
    this.end,
    this.location,
    this.description,
    this.url,
  });
}

/// RFC 5545 §3.3.5 BASIC date-time form, in UTC: 19980119T070000Z.
String _formatUtc(DateTime at) {
  final d = at.toUtc();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${d.year}${pad(d.month)}${pad(d.day)}T'
      '${pad(d.hour)}${pad(d.minute)}${pad(d.second)}Z';
}

/// RFC 5545 §3.3.11: backslashes escape `\`, `,`, `;`, and newlines
/// become `\n`. Carriage returns are dropped.
String escapeText(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\r', '')
      .replaceAll('\n', r'\n');
}

/// RFC 5545 §3.1: lines longer than 75 octets MUST be split with a
/// CRLF + space continuation. Assumes ASCII input (the caller's UTF-8
/// content stays fine until lines exceed ~75 chars AND contain
/// multi-byte runes).
String foldLine(String line) {
  if (line.length <= 75) return line;
  final parts = <String>[];
  parts.add(line.substring(0, 75));
  var pos = 75;
  while (pos < line.length) {
    final end = pos + 74;
    parts.add(' ${line.substring(pos, end > line.length ? line.length : end)}');
    pos += 74;
  }
  return parts.join('\r\n');
}

/// Render a list of events as a complete VCALENDAR document. Returns
/// the raw .ics bytes-as-string ready to share.
///
/// <p>Output validates cleanly against the iCalendar Validator and
/// imports correctly into Google Calendar / Apple Calendar / Outlook.
String buildIcs(List<IcsEvent> events, {String calName = 'AirWatch'}) {
  final dtstamp = _formatUtc(DateTime.now().toUtc());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//AirWatch//Mobile//EN',
    'CALSCALE:GREGORIAN',
    'X-WR-CALNAME:${escapeText(calName)}',
  ];

  for (final ev in events) {
    final startStr = _formatUtc(ev.start);
    final endStr = _formatUtc(ev.end ?? ev.start.add(const Duration(hours: 1)));
    lines.add('BEGIN:VEVENT');
    lines.add(foldLine('UID:${escapeText(ev.id)}@airwatch.app'));
    lines.add('DTSTAMP:$dtstamp');
    lines.add('DTSTART:$startStr');
    lines.add('DTEND:$endStr');
    lines.add(foldLine('SUMMARY:${escapeText(ev.title)}'));
    if (ev.location != null) {
      lines.add(foldLine('LOCATION:${escapeText(ev.location!)}'));
    }
    if (ev.description != null) {
      lines.add(foldLine('DESCRIPTION:${escapeText(ev.description!)}'));
    }
    if (ev.url != null) {
      lines.add(foldLine('URL:${escapeText(ev.url!)}'));
    }
    lines.add('END:VEVENT');
  }

  lines.add('END:VCALENDAR');
  // RFC 5545 mandates CRLF line endings + a trailing CRLF.
  return '${lines.join('\r\n')}\r\n';
}
