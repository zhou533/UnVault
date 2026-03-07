import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/services/device_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeviceSecurityService service;
  bool nativeResult = false;

  setUp(() {
    service = DeviceSecurityService();
    nativeResult = false;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.unvault/device_security'),
      (call) async {
        if (call.method == 'isDeviceCompromised') {
          return nativeResult;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.unvault/device_security'),
      null,
    );
  });

  group('DeviceSecurityService', () {
    test('returns false when device is not compromised', () async {
      nativeResult = false;
      final result = await service.isDeviceCompromised();
      expect(result, isFalse);
    });

    test('returns true when device is compromised', () async {
      nativeResult = true;
      final result = await service.isDeviceCompromised();
      expect(result, isTrue);
    });

    test('returns false on platform exception (fail-safe)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.unvault/device_security'),
        (call) async {
          throw PlatformException(code: 'ERROR', message: 'native error');
        },
      );

      final result = await service.isDeviceCompromised();
      expect(result, isFalse);
    });
  });
}
