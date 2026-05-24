/// App-wide metadata constants that change on a different cadence than
/// the app binary itself.
///
/// <p>The app *version* (e.g. "2.0.0") comes from package_info_plus at
/// runtime — it's defined in pubspec.yaml and stamped into the build
/// artifact, so a hand-edited copy in Dart source would inevitably
/// drift. The *privacy-policy revision date* below, on the other hand,
/// is tied to the wording of PRIVACY.md — bump it only when the policy
/// text changes, NOT on every code release.
library;

/// Date of the most recent revision to the privacy-policy wording.
/// Bump alongside any edit to PRIVACY.md or the in-app dialog copy.
///
/// <p>Format: ISO-8601 yyyy-MM-dd (UTC). Displayed as-is in the
/// privacy dialog without locale-specific formatting — keeps the
/// "regulator can see what date you're claiming" rule simple.
const String privacyPolicyDate = '2026-05-03';
