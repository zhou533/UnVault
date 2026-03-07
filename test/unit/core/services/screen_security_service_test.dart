import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/services/screen_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScreenSecurityService service;
  late List<MethodCall> methodCalls;

  setUp(() {
    methodCalls = [];
    service = const ScreenSecurityService();

    // Mock the method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.unvault/screen_security'),
      (call) async {
        methodCalls.add(call);
        if (call.method == 'enableProtection') return null;
        if (call.method == 'disableProtection') return null;
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.unvault/screen_security'),
      null,
    );
  });

  group('ScreenSecurityService', () {
    test('enableProtection sends method call', () async {
      await service.enableProtection();
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'enableProtection');
    });

    test('disableProtection sends method call', () async {
      await service.disableProtection();
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'disableProtection');
    });

    test('enableProtection is idempotent (no errors on double call)',
        () async {
      await service.enableProtection();
      await service.enableProtection();
      expect(methodCalls, hasLength(2));
    });
  });
}
