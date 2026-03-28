/// Utility for comparing semantic version strings.
class VersionUtils {
  VersionUtils._();

  /// Parse a version string like "1.2.3" into a list of ints [1, 2, 3].
  static List<int> parse(String version) {
    final cleaned = version.replaceAll(RegExp(r'[^0-9.]'), '');
    return cleaned.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }

  /// Returns true if [current] is less than [other].
  static bool isOlderThan(String current, String other) {
    final c = parse(current);
    final o = parse(other);
    final maxLen = c.length > o.length ? c.length : o.length;
    for (var i = 0; i < maxLen; i++) {
      final cv = i < c.length ? c[i] : 0;
      final ov = i < o.length ? o[i] : 0;
      if (cv < ov) return true;
      if (cv > ov) return false;
    }
    return false;
  }

  /// Returns true if [current] equals [other].
  static bool isEqual(String current, String other) {
    final c = parse(current);
    final o = parse(other);
    final maxLen = c.length > o.length ? c.length : o.length;
    for (var i = 0; i < maxLen; i++) {
      final cv = i < c.length ? c[i] : 0;
      final ov = i < o.length ? o[i] : 0;
      if (cv != ov) return false;
    }
    return true;
  }
}
