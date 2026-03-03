import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] wrapped in a [ProviderScope] and [MaterialApp].
  ///
  /// Pass a [container] to provide a pre-configured [ProviderContainer]
  /// with scoped overrides for unit testing.
  Future<void> pumpApp(
    Widget widget, {
    ProviderContainer? container,
  }) async {
    await pumpWidget(
      UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp(home: widget),
      ),
    );
  }
}
