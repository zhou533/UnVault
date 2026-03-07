import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/core/widgets/screen_security_wrapper.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class VerifyMnemonicScreen extends ConsumerStatefulWidget {
  const VerifyMnemonicScreen({
    required this.walletId,
    required this.words,
    super.key,
  });

  final int walletId;
  final List<String> words;

  @override
  ConsumerState<VerifyMnemonicScreen> createState() =>
      _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends ConsumerState<VerifyMnemonicScreen> {
  late final List<int> _challengeIndices;
  late final List<List<String>> _options;
  final List<String?> _selected = [null, null, null];
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random.secure();
    final indices = List.generate(widget.words.length, (i) => i)..shuffle(rng);
    _challengeIndices = indices.take(3).toList()..sort();

    // For each challenge, build 3 shuffled options (1 correct + 2 wrong)
    _options = _challengeIndices.map((correctIdx) {
      final correctWord = widget.words[correctIdx];
      final wrongWords = widget.words
          .where((w) => w != correctWord)
          .toList()
        ..shuffle(rng);
      final opts = [correctWord, ...wrongWords.take(2)]..shuffle(rng);
      return opts;
    }).toList();
  }

  Future<void> _verify() async {
    for (var i = 0; i < _challengeIndices.length; i++) {
      if (_selected[i] == null) {
        setState(() => _error = 'Please select a word for each position.');
        return;
      }
      if (_selected[i] != widget.words[_challengeIndices[i]]) {
        setState(
          () => _error = 'Incorrect. Check word #${_challengeIndices[i] + 1}.',
        );
        return;
      }
    }

    await ref.read(walletRepositoryProvider).markBackedUp(widget.walletId);
    ref.invalidate(walletListProvider);
    if (mounted) context.goNamed(RouteNames.walletList);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return ScreenSecurityWrapper(child: Scaffold(
      appBar: AppBar(title: const Text('Verify Phrase')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Text(
              'Select the correct word for each position '
              'to verify your backup.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (ctx, qi) => _QuestionBlock(
                  label: 'Word #${_challengeIndices[qi] + 1}',
                  options: _options[qi],
                  selected: _selected[qi],
                  accentColor: accentColor,
                  onSelect: (word) => setState(() {
                    _selected[qi] = word;
                    _error = null;
                  }),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _verify,
                child: const Text('Verify & Continue'),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.label,
    required this.options,
    required this.selected,
    required this.accentColor,
    required this.onSelect,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final Color accentColor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: options.map((word) {
            final isSelected = word == selected;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: word != options.last ? 10 : 0,
                ),
                child: GestureDetector(
                  onTap: () => onSelect(word),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                            ),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
