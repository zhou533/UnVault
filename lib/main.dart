import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unvault/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(ffi): Uncomment after running flutter_rust_bridge_codegen generate
  // await RustLib.init();

  runApp(const ProviderScope(child: UnVaultApp()));
}
