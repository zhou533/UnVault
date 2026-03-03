// ignore_for_file: public_member_api_docs -- internal chain config constants

enum GasType { eip1559, legacy }

class ChainConfig {
  const ChainConfig({
    required this.chainId,
    required this.name,
    required this.symbol,
    required this.rpcUrls,
    required this.explorerUrl,
    this.decimals = 18,
    this.gasType = GasType.eip1559,
    this.isTestnet = false,
  });

  final int chainId;
  final String name;
  final String symbol;
  final int decimals;
  final List<String> rpcUrls;
  final String explorerUrl;
  final GasType gasType;
  final bool isTestnet;
}

abstract final class BuiltInChains {
  static const ethereumMainnet = ChainConfig(
    chainId: 1,
    name: 'Ethereum',
    symbol: 'ETH',
    rpcUrls: ['https://eth.llamarpc.com', 'https://rpc.ankr.com/eth'],
    explorerUrl: 'https://etherscan.io',
  );

  static const sepolia = ChainConfig(
    chainId: 11155111,
    name: 'Sepolia',
    symbol: 'ETH',
    rpcUrls: ['https://rpc.sepolia.org', 'https://rpc.ankr.com/eth_sepolia'],
    explorerUrl: 'https://sepolia.etherscan.io',
    isTestnet: true,
  );

  static const polygon = ChainConfig(
    chainId: 137,
    name: 'Polygon',
    symbol: 'POL',
    rpcUrls: ['https://polygon-rpc.com', 'https://rpc.ankr.com/polygon'],
    explorerUrl: 'https://polygonscan.com',
  );

  static const arbitrum = ChainConfig(
    chainId: 42161,
    name: 'Arbitrum One',
    symbol: 'ETH',
    rpcUrls: ['https://arb1.arbitrum.io/rpc', 'https://rpc.ankr.com/arbitrum'],
    explorerUrl: 'https://arbiscan.io',
  );

  static const optimism = ChainConfig(
    chainId: 10,
    name: 'Optimism',
    symbol: 'ETH',
    rpcUrls: [
      'https://mainnet.optimism.io',
      'https://rpc.ankr.com/optimism',
    ],
    explorerUrl: 'https://optimistic.etherscan.io',
  );

  static const base = ChainConfig(
    chainId: 8453,
    name: 'Base',
    symbol: 'ETH',
    rpcUrls: ['https://mainnet.base.org', 'https://base.llamarpc.com'],
    explorerUrl: 'https://basescan.org',
  );

  static const bsc = ChainConfig(
    chainId: 56,
    name: 'BNB Smart Chain',
    symbol: 'BNB',
    rpcUrls: [
      'https://bsc-dataseed.binance.org',
      'https://rpc.ankr.com/bsc',
    ],
    explorerUrl: 'https://bscscan.com',
    gasType: GasType.legacy,
  );

  static const avalanche = ChainConfig(
    chainId: 43114,
    name: 'Avalanche C-Chain',
    symbol: 'AVAX',
    rpcUrls: [
      'https://api.avax.network/ext/bc/C/rpc',
      'https://rpc.ankr.com/avalanche',
    ],
    explorerUrl: 'https://snowtrace.io',
    gasType: GasType.legacy,
  );

  static const all = [
    ethereumMainnet,
    sepolia,
    polygon,
    arbitrum,
    optimism,
    base,
    bsc,
    avalanche,
  ];
}
