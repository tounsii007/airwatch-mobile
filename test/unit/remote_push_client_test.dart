import 'package:airwatch_mobile/features/notifications/data/remote_push_client.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('NoOpPush (default)', () {
    test('initialize / isAvailable / register / unregister all no-op',
        () async {
      final client = NoOpPush();
      await client.initialize();
      expect(await client.isAvailable(), isFalse);
      expect(await client.registerToken('test-client'), isFalse);
      expect(await client.unregisterToken('test-client'), isFalse);
      expect(client.currentToken, isNull);
    });
  });

  group('PushClientId', () {
    test('generates a stable id and reuses it across calls', () async {
      final id1 = await PushClientId.getOrCreate();
      final id2 = await PushClientId.getOrCreate();
      expect(id1, id2);
      expect(id1.startsWith('aw-'), isTrue);
      expect(id1.length, greaterThan(8));
    });

    test('persists across "app restarts" (re-reading prefs)', () async {
      final first = await PushClientId.getOrCreate();
      // SharedPreferences is mock-backed; the same key survives.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('airwatch.push.clientId'), first);
    });
  });

  group('MobilePushSubscriptionRequest.toJson', () {
    test('emits the exact wire shape the api expects', () {
      const req = MobilePushSubscriptionRequest(
        clientId: 'aw-abc',
        token: 'fcm-token-xyz',
        platform: 'fcm',
        language: 'de',
      );
      final json = req.toJson();
      expect(json['clientId'], 'aw-abc');
      expect(json['token'], 'fcm-token-xyz');
      expect(json['platform'], 'fcm');
      expect(json['language'], 'de');
    });

    test('omits language when null', () {
      const req = MobilePushSubscriptionRequest(
        clientId: 'aw-abc',
        token: 'apns-token',
        platform: 'apns',
      );
      final json = req.toJson();
      expect(json.containsKey('language'), isFalse);
    });
  });
}
