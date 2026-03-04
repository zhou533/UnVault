import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/constants/chain_config.dart';

part 'network_notifier.g.dart';

@Riverpod(keepAlive: true)
class ActiveNetwork extends _$ActiveNetwork {
  @override
  ChainConfig build() => BuiltInChains.ethereumMainnet;

  void switchNetwork(ChainConfig chain) => state = chain;
}
