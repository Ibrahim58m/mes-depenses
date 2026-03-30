import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final byCatAsync = ref.watch(expensesByCategoryProvider(period));
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: catsAsync.when(
        data: (cats) => byCatAsync.when(
          data: (byCat) {
            if (byCat.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucune dépense catégorisée',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      'Appuyez sur une transaction pour la catégoriser',
                      style:
                          TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final total = byCat.values.fold(0.0, (a, b) => a + b);
            final sorted = byCat.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length + 1,
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _TotalRow(total: total),
                  );
                }
                final e = sorted[i - 1];
                final cat = cats.firstWhere(
                  (c) => c.id == e.key,
                  orElse: () => Category.defaults.last,
                );
                final pct = total > 0 ? e.value / total * 100 : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                Color(cat.color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(cat.icon,
                              style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(cat.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    '${NumberFormat('#,##0').format(e.value)} DJF',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(cat.color),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  color: Color(cat.color),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${pct.toStringAsFixed(1)}% du total',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final double total;
  const _TotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total catégorisé',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(
            '${NumberFormat('#,##0').format(total)} DJF',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.indigo.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
