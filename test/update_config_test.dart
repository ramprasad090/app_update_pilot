import 'package:flutter_test/flutter_test.dart';
import 'package:app_update_pilot/app_update_pilot.dart';

void main() {
  group('UpdateConfig', () {
    test('fromJson parses all fields', () {
      final config = UpdateConfig.fromJson({
        'latest_version': '2.1.0',
        'min_version': '1.5.0',
        'min_version_android': '1.5.0',
        'min_version_ios': '1.4.0',
        'urgency': 'recommended',
        'changelog': '## What\'s new\n- Bug fixes',
        'rollout_percentage': 0.5,
        'maintenance_mode': false,
      });

      expect(config.latestVersion, '2.1.0');
      expect(config.minVersion, '1.5.0');
      expect(config.minVersionByPlatform?['android'], '1.5.0');
      expect(config.minVersionByPlatform?['ios'], '1.4.0');
      expect(config.urgency, UpdateUrgency.recommended);
      expect(config.changelog, contains('Bug fixes'));
      expect(config.rolloutPercentage, 0.5);
      expect(config.maintenanceMode, false);
    });

    test('fromJson handles minimal fields', () {
      final config = UpdateConfig.fromJson({
        'latest_version': '1.0.0',
      });

      expect(config.latestVersion, '1.0.0');
      expect(config.urgency, UpdateUrgency.optional);
      expect(config.rolloutPercentage, 1.0);
      expect(config.maintenanceMode, false);
    });

    test('fromStore creates store config', () {
      final config = UpdateConfig.fromStore();
      expect(config.checkStore, true);
    });

    test('fromUrl creates remote config', () {
      final config = UpdateConfig.fromUrl('https://api.example.com/version');
      expect(config.remoteConfigUrl, 'https://api.example.com/version');
    });

    test('firebase creates firebase config', () {
      final config = UpdateConfig.firebase();
      expect(config.isFirebase, true);
    });

    test('urgency parsing', () {
      expect(
        UpdateConfig.fromJson({'urgency': 'critical'}).urgency,
        UpdateUrgency.critical,
      );
      expect(
        UpdateConfig.fromJson({'urgency': 'recommended'}).urgency,
        UpdateUrgency.recommended,
      );
      expect(
        UpdateConfig.fromJson({'urgency': 'optional'}).urgency,
        UpdateUrgency.optional,
      );
      expect(
        UpdateConfig.fromJson({}).urgency,
        UpdateUrgency.optional,
      );
    });
  });
}
