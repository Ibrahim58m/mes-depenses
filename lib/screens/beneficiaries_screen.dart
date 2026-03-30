import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class BeneficiariesScreen extends ConsumerWidget {
  const BeneficiariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final benefAsync = ref.watch(expensesByBeneficiaryProvider(period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bénéficiaires',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: benefAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun transfert enregistré',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final sorted = data.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final total = sorted.fold(0.0, (sum, e) => sum + e.value);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Graphique top bénéficiaires
                if (sorted.length >= 2) ...[
                  const Text('Répartition des transferts',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _BeneficiaryBarChart(data: sorted.take(8).toList(), total: total),
                  const SizedBox(height: 20),
                ],

                // Liste complète
                const Text('Détail par bénéficiaire',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...sorted.map((e) {
                  final pct = total > 0 ? e.value / total * 100 : 0.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.purple.shade50,
                            child: Text(
                              e.key.isNotEmpty
                                  ? e.key[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(e.key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  color: Colors.purple.shade400,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${NumberFormat('#,##0').format(e.value)} DJF',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _BeneficiaryBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final double total;

  const _BeneficiaryBarChart({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: Colors.purple.shade400,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  final name = data[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 7)}…' : name,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
