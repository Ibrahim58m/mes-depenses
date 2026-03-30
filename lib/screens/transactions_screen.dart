import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../database/db_helper.dart';
import '../widgets/transaction_card.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final txAsync = ref.watch(transactionsProvider(period));
    final catAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<Period>(
            icon: const Icon(Icons.filter_list),
            onSelected: (p) =>
                ref.read(selectedPeriodProvider.notifier).state = p,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Period.week, child: Text('7 derniers jours')),
              PopupMenuItem(value: Period.month, child: Text('Ce mois')),
              PopupMenuItem(value: Period.threeMonths, child: Text('3 mois')),
              PopupMenuItem(value: Period.year, child: Text('Cette année')),
              PopupMenuItem(value: Period.all, child: Text('Tout')),
            ],
          ),
        ],
      ),
      body: catAsync.when(
        data: (cats) => txAsync.when(
          data: (txs) => txs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune transaction',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Appuyez sur Sync pour importer vos SMS',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: txs.length,
                  itemBuilder: (ctx, i) => TransactionCard(
                    transaction: txs[i],
                    categories: cats,
                    onCategoryTap: () =>
                        _showCategoryPicker(ctx, ref, txs[i], cats),
                  ),
                ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, WidgetRef ref,
      Transaction tx, List<Category> cats) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _CategoryPickerSheet(
        transaction: tx,
        categories: cats,
        onSelected: (cat) async {
          await DbHelper().updateTransactionCategory(tx.id!, cat.id!);
          ref.invalidate(transactionsProvider);
          ref.invalidate(expensesByCategoryProvider);
        },
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final ValueChanged<Category> onSelected;

  const _CategoryPickerSheet({
    required this.transaction,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catégoriser: ${transaction.displayName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final isSelected = transaction.categoryId == cat.id;
              return GestureDetector(
                onTap: () {
                  onSelected(cat);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(cat.color)
                        : Color(cat.color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(cat.color),
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Color(cat.color),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
