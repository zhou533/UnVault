import 'package:flutter/material.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';

enum HistoryFilterType { all, sent, received }

class HistoryFilter {
  const HistoryFilter({
    this.type = HistoryFilterType.all,
    this.status,
    this.searchQuery,
  });

  final HistoryFilterType type;
  final TransactionStatus? status;
  final String? searchQuery;

  HistoryFilter copyWith({
    HistoryFilterType? type,
    TransactionStatus? Function()? status,
    String? Function()? searchQuery,
  }) {
    return HistoryFilter(
      type: type ?? this.type,
      status: status != null ? status() : this.status,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
    );
  }
}

class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  final HistoryFilter filter;
  final void Function(HistoryFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by address or tx hash',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) {
              onFilterChanged(filter.copyWith(
                searchQuery: () => value.isEmpty ? null : value,
              ));
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _typeChip('All', HistoryFilterType.all),
              const SizedBox(width: 8),
              _typeChip('Sent', HistoryFilterType.sent),
              const SizedBox(width: 8),
              _typeChip('Received', HistoryFilterType.received),
              const SizedBox(width: 16),
              _statusChip('Pending', TransactionStatus.pending),
              const SizedBox(width: 8),
              _statusChip('Confirmed', TransactionStatus.confirmed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeChip(String label, HistoryFilterType type) {
    return ChoiceChip(
      label: Text(label),
      selected: filter.type == type,
      onSelected: (_) {
        onFilterChanged(filter.copyWith(type: type));
      },
    );
  }

  Widget _statusChip(String label, TransactionStatus status) {
    return FilterChip(
      label: Text(label),
      selected: filter.status == status,
      onSelected: (selected) {
        onFilterChanged(filter.copyWith(
          status: () => selected ? status : null,
        ));
      },
    );
  }
}
