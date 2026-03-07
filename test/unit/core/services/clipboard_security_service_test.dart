import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/services/clipboard_security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClipboardSecurityService service;
  String? clipboardContent;

  setUp(() {
    service = ClipboardSecurityService();
    clipboardContent = null;

    // Mock the clipboard platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map;
        clipboardContent = args['text'] as String?;
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return clipboardContent != null ? {'text': clipboardContent} : null;
      }
      return null;
    });
  });

  tearDown(() {
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('ClipboardSecurityService', () {
    test('secureCopy copies content to clipboard', () async {
      await service.secureCopy('0x1234abcd');
      expect(clipboardContent, '0x1234abcd');
    });

    test('secureCopy starts a clear timer', () async {
      await service.secureCopy('0x1234abcd');
      expect(service.hasPendingClear, isTrue);
    });

    test('clearNow clears clipboard if content matches', () async {
      await service.secureCopy('0x1234abcd');
      await service.clearNow();

      expect(clipboardContent, '');
      expect(service.hasPendingClear, isFalse);
    });

    test('clearNow does not clear if clipboard was modified externally',
        () async {
      await service.secureCopy('0x1234abcd');

      // Simulate external clipboard change
      clipboardContent = 'external content';

      await service.clearNow();

      // External content should remain
      expect(clipboardContent, 'external content');
    });

    test('dispose cancels pending timer', () async {
      await service.secureCopy('0x1234abcd');
      service.dispose();
      expect(service.hasPendingClear, isFalse);
    });
  });
}
