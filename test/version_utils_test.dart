import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_pilot/app_update_pilot.dart';

void main() {
  group('VersionUtils', () {
    group('parse', () {
      test('parses standard version', () {
        expect(VersionUtils.parse('1.2.3'), [1, 2, 3]);
      });

      test('parses version with prefix', () {
        expect(VersionUtils.parse('v1.2.3'), [1, 2, 3]);
      });

      test('parses two-part version', () {
        expect(VersionUtils.parse('1.2'), [1, 2]);
      });
    });

    group('isOlderThan', () {
      test('returns true when current is older', () {
        expect(VersionUtils.isOlderThan('1.0.0', '1.0.1'), isTrue);
        expect(VersionUtils.isOlderThan('1.0.0', '2.0.0'), isTrue);
        expect(VersionUtils.isOlderThan('1.9.9', '2.0.0'), isTrue);
      });

      test('returns false when current is newer', () {
        expect(VersionUtils.isOlderThan('1.0.1', '1.0.0'), isFalse);
        expect(VersionUtils.isOlderThan('2.0.0', '1.9.9'), isFalse);
      });

      test('returns false when versions are equal', () {
        expect(VersionUtils.isOlderThan('1.0.0', '1.0.0'), isFalse);
      });

      test('handles different length versions', () {
        expect(VersionUtils.isOlderThan('1.0', '1.0.1'), isTrue);
        expect(VersionUtils.isOlderThan('1.0.1', '1.0'), isFalse);
      });
    });

    group('isEqual', () {
      test('returns true for equal versions', () {
        expect(VersionUtils.isEqual('1.0.0', '1.0.0'), isTrue);
      });

      test('returns true for equivalent versions', () {
        expect(VersionUtils.isEqual('1.0', '1.0.0'), isTrue);
      });

      test('returns false for different versions', () {
        expect(VersionUtils.isEqual('1.0.0', '1.0.1'), isFalse);
      });
    });
  });
}
