// Procedurally synthesises the AirWatch launcher icon at every size required
// by Android (mipmap-mdpi → mipmap-xxxhdpi) and iOS
// (Assets.xcassets/AppIcon.appiconset). Run with:
//
//     dart run tool/generate_launcher_icons.dart
//
// The generator draws a single 1024×1024 master in memory, then resamples it
// down to each platform-specific size. There is no committed PNG and no
// external dependency on a design tool — the asset pipeline is fully
// reproducible from source code, which means a fresh clone can rebuild every
// icon in one command and the brand colours stay in lockstep with
// [app_colors.dart].
//
// Design — "radar dome at twilight":
//
//   * Background: radial gradient from steel navy at the centre to deep navy
//     at the edges, mirroring [AppColors.surface] → [AppColors.background].
//   * Three concentric steel-blue rings ([AppColors.primary]) at decreasing
//     thickness, evoking a radar PPI (plan-position indicator).
//   * A warm-bronze sweep arc ([AppColors.accent]) at 45° → 135° anchored to
//     the centre, suggesting the live "scan" motion of the radar UI.
//   * A stylised aircraft glyph (silver-white triangle with a tail-fin line)
//     pinned dead-centre at a 25° offset, hinting at heading without being a
//     literal compass needle.
//
// Adaptive icons (Android 8.0+) get an extra foreground/background pair so
// the launcher can mask the icon to a circle, squircle, teardrop, or any
// other vendor mask without clipping the brand artwork.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

// ─────────────────────────────────────────────────────────────────────────────
// Colour palette — must mirror [AppColors] so the launcher matches the app
// chrome the moment it opens.
// ─────────────────────────────────────────────────────────────────────────────

const _bgDeep         = 0xFF0A1628;   // AppColors.background
const _bgSurface      = 0xFF0F1D32;   // AppColors.surface
const _primary        = 0xFF7A9ABF;   // AppColors.primary
const _primaryLight   = 0xFFB0C4D8;   // AppColors.primaryLight
const _primaryDark    = 0xFF4A6B8A;   // AppColors.primaryDark
const _accent         = 0xFFD4A574;   // AppColors.accent
const _accentLight    = 0xFFE8C49A;   // AppColors.accentLight
const _silver         = 0xFFD0D8E4;   // AppColors.textPrimary

// ─────────────────────────────────────────────────────────────────────────────
// Master canvas size. Every other size is resampled from this — picking 1024
// matches Apple's required marketing icon size, which avoids a second
// upscale on the iOS side.
// ─────────────────────────────────────────────────────────────────────────────

const _masterSize = 1024;

// ─────────────────────────────────────────────────────────────────────────────
// Output schedule. Two flavours per platform: the squared "legacy" launcher
// icon and (Android only) the adaptive foreground+background layers.
// ─────────────────────────────────────────────────────────────────────────────

class _AndroidTarget {
  const _AndroidTarget(this.density, this.size);
  final String density;
  final int size;
}

const _androidLegacy = <_AndroidTarget>[
  _AndroidTarget('mdpi',     48),
  _AndroidTarget('hdpi',     72),
  _AndroidTarget('xhdpi',    96),
  _AndroidTarget('xxhdpi',  144),
  _AndroidTarget('xxxhdpi', 192),
];

// Adaptive icons render the foreground inside a 66 % safe zone of a 108 dp
// canvas; vendor masks may crop everything outside it. We keep the radar
// rings well inside that zone (see [_drawForeground]).
const _androidAdaptive = <_AndroidTarget>[
  _AndroidTarget('mdpi',    108),
  _AndroidTarget('hdpi',    162),
  _AndroidTarget('xhdpi',   216),
  _AndroidTarget('xxhdpi',  324),
  _AndroidTarget('xxxhdpi', 432),
];

// iOS ships every required @1x/@2x/@3x variant inside one .appiconset bundle
// shared between iPhone and iPad. The 1024 marketing icon is included so the
// App Store Connect upload doesn't need a second pass.
class _IosTarget {
  const _IosTarget(this.filename, this.size);
  final String filename;
  final int size;
}

const _iosTargets = <_IosTarget>[
  _IosTarget('Icon-App-20x20@1x.png',     20),
  _IosTarget('Icon-App-20x20@2x.png',     40),
  _IosTarget('Icon-App-20x20@3x.png',     60),
  _IosTarget('Icon-App-29x29@1x.png',     29),
  _IosTarget('Icon-App-29x29@2x.png',     58),
  _IosTarget('Icon-App-29x29@3x.png',     87),
  _IosTarget('Icon-App-40x40@1x.png',     40),
  _IosTarget('Icon-App-40x40@2x.png',     80),
  _IosTarget('Icon-App-40x40@3x.png',    120),
  _IosTarget('Icon-App-60x60@2x.png',    120),
  _IosTarget('Icon-App-60x60@3x.png',    180),
  _IosTarget('Icon-App-76x76@1x.png',     76),
  _IosTarget('Icon-App-76x76@2x.png',    152),
  _IosTarget('Icon-App-83.5x83.5@2x.png',167),
  _IosTarget('Icon-App-1024x1024@1x.png',1024),
];

// ─────────────────────────────────────────────────────────────────────────────
// Drawing primitives
// ─────────────────────────────────────────────────────────────────────────────

/// Fills [image] with a radial gradient from [innerHex] (centre) to
/// [outerHex] (corners). The fall-off uses squared distance for a softer
/// roll, which reads better at small icon sizes than a linear ramp.
void _fillRadial(img.Image image, int innerHex, int outerHex) {
  final cx = image.width  / 2;
  final cy = image.height / 2;
  final maxR = math.sqrt(cx * cx + cy * cy);
  final iR = (innerHex >> 16) & 0xFF, iG = (innerHex >> 8) & 0xFF, iB = innerHex & 0xFF;
  final oR = (outerHex >> 16) & 0xFF, oG = (outerHex >> 8) & 0xFF, oB = outerHex & 0xFF;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final t = math.min(1.0, math.sqrt(dx * dx + dy * dy) / maxR);
      // Easing: t² accelerates the dark-edge fall-off without a hard ring.
      final tt = t * t;
      final r = (iR + (oR - iR) * tt).round();
      final g = (iG + (oG - iG) * tt).round();
      final b = (iB + (oB - iB) * tt).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

/// Draws a soft ring centred on [image] at radius [r] with thickness
/// [thickness]px and alpha [alpha] (0–255). "Soft" = an additional 1.5 px
/// fade band on each side, eliminating the staircase at small sizes.
void _drawRing(
  img.Image image,
  double r,
  double thickness,
  int hex, {
  int alpha = 255,
}) {
  final cx = image.width  / 2;
  final cy = image.height / 2;
  final inner = r - thickness / 2;
  final outer = r + thickness / 2;
  const fade = 1.5;
  final cR = (hex >> 16) & 0xFF, cG = (hex >> 8) & 0xFF, cB = hex & 0xFF;

  // Iterate only over the bounding annulus to keep this fast on large
  // canvases — O(r·thickness) instead of O(width·height).
  final yMin = math.max(0,                  (cy - outer - fade).floor());
  final yMax = math.min(image.height - 1,   (cy + outer + fade).ceil());
  final xMin = math.max(0,                  (cx - outer - fade).floor());
  final xMax = math.min(image.width  - 1,   (cx + outer + fade).ceil());

  for (var y = yMin; y <= yMax; y++) {
    for (var x = xMin; x <= xMax; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d  = math.sqrt(dx * dx + dy * dy);
      double a;
      if (d < inner - fade || d > outer + fade) {
        continue;
      } else if (d < inner) {
        a = (d - (inner - fade)) / fade;
      } else if (d > outer) {
        a = ((outer + fade) - d) / fade;
      } else {
        a = 1.0;
      }
      _blendPixel(image, x, y, cR, cG, cB, (a * alpha).round());
    }
  }
}

/// Draws a filled wedge (sweep arc) centred on [image] from [startDeg] to
/// [endDeg] (clockwise from 12 o'clock), with an outer radius of [rOuter]
/// and a soft inward fade — this is the radar "ping" arc.
void _drawSweep(
  img.Image image,
  double startDeg,
  double endDeg,
  double rOuter,
  int hex, {
  int alphaPeak = 200,
}) {
  final cx = image.width  / 2;
  final cy = image.height / 2;
  final cR = (hex >> 16) & 0xFF, cG = (hex >> 8) & 0xFF, cB = hex & 0xFF;

  // Convert degrees (0 = up, clockwise) → radians (0 = +x, ccw).
  double toRad(double deg) => (deg - 90) * math.pi / 180;
  final a0 = toRad(startDeg);
  final a1 = toRad(endDeg);

  final yMin = math.max(0,                  (cy - rOuter).floor());
  final yMax = math.min(image.height - 1,   (cy + rOuter).ceil());
  final xMin = math.max(0,                  (cx - rOuter).floor());
  final xMax = math.min(image.width  - 1,   (cx + rOuter).ceil());

  for (var y = yMin; y <= yMax; y++) {
    for (var x = xMin; x <= xMax; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d  = math.sqrt(dx * dx + dy * dy);
      if (d > rOuter) continue;
      final ang = math.atan2(dy, dx);
      // Normalise so a0 is 0 in the local angular frame.
      double rel = ang - a0;
      while (rel < 0) {
        rel += 2 * math.pi;
      }
      final span = a1 - a0;
      if (rel > span) continue;
      // Trailing fade: bright at the leading edge, soft at the tail.
      final t = rel / span;            // 0 leading → 1 trailing
      final a = (1 - t) * (1 - t);     // quadratic ease-out tail
      final radial = 1 - (d / rOuter); // fade inward as well
      final alpha = (alphaPeak * a * radial).round();
      if (alpha <= 0) continue;
      _blendPixel(image, x, y, cR, cG, cB, alpha);
    }
  }
}

/// Draws a simple convex polygon (≤ 6 vertices) by scanline-filling. Used
/// for the centre aircraft glyph — the silhouette is just two triangles.
void _fillPolygon(
  img.Image image,
  List<List<double>> pts,
  int hex, {
  int alpha = 255,
}) {
  if (pts.length < 3) return;
  final cR = (hex >> 16) & 0xFF, cG = (hex >> 8) & 0xFF, cB = hex & 0xFF;
  final yMin = pts.map((p) => p[1]).reduce(math.min).floor().clamp(0, image.height - 1);
  final yMax = pts.map((p) => p[1]).reduce(math.max).ceil().clamp(0, image.height - 1);
  for (var y = yMin; y <= yMax; y++) {
    final xs = <double>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      // Edge crosses scanline y?
      if ((a[1] <= y && b[1] > y) || (b[1] <= y && a[1] > y)) {
        final t = (y - a[1]) / (b[1] - a[1]);
        xs.add(a[0] + t * (b[0] - a[0]));
      }
    }
    xs.sort();
    for (var i = 0; i + 1 < xs.length; i += 2) {
      final x0 = xs[i].floor().clamp(0, image.width - 1);
      final x1 = xs[i + 1].ceil().clamp(0, image.width - 1);
      for (var x = x0; x <= x1; x++) {
        _blendPixel(image, x, y, cR, cG, cB, alpha);
      }
    }
  }
}

/// Source-over alpha blend onto [image] at ([x],[y]). Fast path: skips the
/// blend math when the existing pixel is already fully opaque and the new
/// pixel is fully opaque too (the common case for the radar background).
void _blendPixel(img.Image image, int x, int y, int r, int g, int b, int a) {
  if (a <= 0) return;
  if (a >= 255) {
    image.setPixelRgba(x, y, r, g, b, 255);
    return;
  }
  final p = image.getPixel(x, y);
  final dr = p.r.toInt();
  final dg = p.g.toInt();
  final db = p.b.toInt();
  final da = p.a.toInt();
  // Standard "source over" alpha compositing — premultiplication is folded
  // into the lerp so we only do one round per channel.
  final outA = a + (da * (255 - a)) ~/ 255;
  if (outA == 0) return;
  final outR = ((r * a + dr * da * (255 - a) ~/ 255) / outA).round();
  final outG = ((g * a + dg * da * (255 - a) ~/ 255) / outA).round();
  final outB = ((b * a + db * da * (255 - a) ~/ 255) / outA).round();
  image.setPixelRgba(x, y, outR, outG, outB, outA);
}

// ─────────────────────────────────────────────────────────────────────────────
// Master composition
// ─────────────────────────────────────────────────────────────────────────────

/// Renders the legacy (square-clipped) launcher master at the requested size.
img.Image _renderLegacy(int size) {
  final canvas = img.Image(width: size, height: size);
  _fillRadial(canvas, _bgSurface, _bgDeep);
  _drawCommonForeground(canvas);
  return canvas;
}

/// Renders the adaptive-icon foreground at the requested size. The brand
/// artwork is contained within the 66 % safe zone (centre 0.66 × side) so
/// any vendor mask shape clips only the transparent margin.
img.Image _renderAdaptiveForeground(int size) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  // Transparent — the launcher will composite this over the matching
  // background drawable at runtime.
  _drawCommonForeground(canvas, scale: 0.66);
  return canvas;
}

/// Renders the adaptive-icon background (full-bleed radial gradient).
img.Image _renderAdaptiveBackground(int size) {
  final canvas = img.Image(width: size, height: size);
  _fillRadial(canvas, _bgSurface, _bgDeep);
  return canvas;
}

/// Common radar+aircraft glyph drawn into [canvas]. The [scale] parameter
/// shrinks the artwork to fit inside an adaptive-icon safe zone — keep at
/// 1.0 for legacy (square) icons.
void _drawCommonForeground(img.Image canvas, {double scale = 1.0}) {
  final w = canvas.width;
  final cx = w / 2;
  final base = (w * scale) / 2; // half-side of the active drawing region

  // Three concentric rings — outer dim, middle medium, inner bright. The
  // ratios were eyeballed against a 192 px Pixel-launcher mock.
  _drawRing(canvas, base * 0.78, math.max(2, w * 0.012), _primaryDark,  alpha: 220);
  _drawRing(canvas, base * 0.55, math.max(2, w * 0.014), _primary,      alpha: 230);
  _drawRing(canvas, base * 0.32, math.max(2, w * 0.016), _primaryLight, alpha: 245);

  // A subtle hairline at the very rim — this is what gives the glyph a
  // "machined" feel on retina displays.
  _drawRing(canvas, base * 0.92, math.max(1, w * 0.004), _primary, alpha: 110);

  // Sweep arc — 35° wide leading at the 1 o'clock position. Bright bronze
  // peak fading both rotationally and inward.
  _drawSweep(canvas,  35, 70, base * 0.78, _accentLight, alphaPeak: 230);
  _drawSweep(canvas,  20, 35, base * 0.78, _accent,      alphaPeak: 90);

  // Aircraft glyph at centre. Defined as a small triangle (fuselage+nose)
  // plus a tail line; the silhouette is slightly tilted to suggest motion.
  // Coordinates are in canvas pixels.
  final s = base * 0.20;                      // half-length of the fuselage
  const theta = -25 * math.pi / 180;          // heading offset (NNE)
  List<double> rot(double x, double y) {
    final rx = x * math.cos(theta) - y * math.sin(theta);
    final ry = x * math.sin(theta) + y * math.cos(theta);
    return [cx + rx, cx + ry];
  }
  final nose      = rot(0,        -s * 1.10);
  final tailLeft  = rot(-s * 0.85, s * 0.40);
  final tailRight = rot( s * 0.85, s * 0.40);
  final tailBase  = rot(0,         s * 0.25);
  // Body
  _fillPolygon(canvas, [nose, tailLeft, tailBase], _silver);
  _fillPolygon(canvas, [nose, tailRight, tailBase], _accentLight);
  // Tail fin (vertical stabiliser)
  final finTip   = rot(0,  s * 0.65);
  final finLeft  = rot(-s * 0.18, s * 0.30);
  final finRight = rot( s * 0.18, s * 0.30);
  _fillPolygon(canvas, [finTip, finLeft, finRight], _silver);
}

// ─────────────────────────────────────────────────────────────────────────────
// IO — write all sized variants in one pass.
// ─────────────────────────────────────────────────────────────────────────────

void _writePng(img.Image image, String path) {
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('  → $path');
}

img.Image _resize(img.Image src, int size) =>
    img.copyResize(src, width: size, height: size, interpolation: img.Interpolation.cubic);

void main() {
  stdout.writeln('Rendering AirWatch launcher master…');
  final masterLegacy        = _renderLegacy(_masterSize);
  final masterAdaptiveFg    = _renderAdaptiveForeground(_masterSize);
  final masterAdaptiveBg    = _renderAdaptiveBackground(_masterSize);

  stdout.writeln('Android (legacy mipmap-*):');
  for (final t in _androidLegacy) {
    final dir = 'android/app/src/main/res/mipmap-${t.density}';
    _writePng(_resize(masterLegacy, t.size), '$dir/ic_launcher.png');
  }

  stdout.writeln('Android (adaptive foreground/background):');
  for (final t in _androidAdaptive) {
    final dir = 'android/app/src/main/res/mipmap-${t.density}';
    _writePng(_resize(masterAdaptiveFg, t.size), '$dir/ic_launcher_foreground.png');
    _writePng(_resize(masterAdaptiveBg, t.size), '$dir/ic_launcher_background.png');
  }

  stdout.writeln('iOS (Assets.xcassets/AppIcon.appiconset):');
  const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  for (final t in _iosTargets) {
    _writePng(_resize(masterLegacy, t.size), '$iosDir/${t.filename}');
  }

  stdout.writeln('Done. Re-run after any palette tweak in app_colors.dart.');
}
