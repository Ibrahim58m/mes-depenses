import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/category.dart';
import 'transactions_screen.dart';
import 'beneficiaries_screen.dart';
import 'categories_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    _HomeTab(),
    TransactionsScreen(),
    BeneficiariesScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Bénéficiaires'),
          NavigationDestination(
              icon: Icon(Icons.category), label: 'Catégories'),
        ],
      ),
    );
  }
}

// ─── Onglet Accueil ─────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final totalAsync = ref.watch(totalExpensesProvider(period));
    final byCatAsync = ref.watch(expensesByCategoryProvider(period));
    final dailyAsync = ref.watch(dailyExpensesProvider(30));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Mes Dépenses',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Importer SMS',
            onPressed: () => _importSms(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de période
            _PeriodSelector(
              current: period,
              onChanged: (p) =>
                  ref.read(selectedPeriodProvider.notifier).state = p,
            ),
            const SizedBox(height: 16),

            // Carte total
            totalAsync.when(
              data: (total) => _TotalCard(total: total, period: period),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 16),

            // Graphique journalier
            const Text('Dépenses journalières',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            dailyAsync.when(
              data: (daily) => _DailyBarChart(data: daily),
              loading: () =>
                  const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Erreur: $e'),
            ),
            const SizedBox(height: 16),

            // Graphique par catégorie
            const Text('Par catégorie',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (cats) => byCatAsync.when(
                data: (byCat) =>
                    byCat.isEmpty
                        ? const _EmptyChart()
                        : _CategoryPieChart(data: byCat, categories: cats),
                loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Erreur: $e'),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importSms(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Import des SMS en cours...'),
          ],
        ),
      ),
    );

    try {
      final count = await ref.read(smsImportProvider.future);
      if (context.mounted) {
        Navigator.pop(context);
        ref.invalidate(transactionsProvider);
        ref.invalidate(totalExpensesProvider);
        ref.invalidate(expensesByCategoryProvider);
        ref.invalidate(expensesByBeneficiaryProvider);
        ref.invalidate(dailyExpensesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count nouvelle(s) transaction(s) importée(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Widgets ────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final Period current;
  final ValueChanged<Period> onChanged;

  const _PeriodSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      Period.week: '7j',
      Period.month: 'Ce mois',
      Period.threeMonths: '3 mois',
      Period.year: 'Cette année',
      Period.all: 'Tout',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Period.values.map((p) {
          final isSelected = p == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[p]!),
              selected: isSelected,
              onSelected: (_) => onChanged(p),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final Period period;

  const _TotalCard({required this.total, required this.period});

  @override
  Widget build(BuildContext context) {
    const labels = {
      Period.week: '7 derniers jours',
      Period.month: 'Ce mois',
      Period.threeMonths: '3 derniers mois',
      Period.year: 'Cette année',
      Period.all: 'Toutes les dépenses',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels[period]!,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,##0').format(total)} DJF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total des dépenses',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  final Map<DateTime, double> data;

  const _DailyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _EmptyChart();

    final sorted = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final last14 = sorted.length > 14
        ? sorted.sublist(sorted.length - 14)
        : sorted;
    final maxVal = last14.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.2,
          barGroups: last14.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: const Color(0xFF3498DB),
                  width: 14,
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
                  if (idx < 0 || idx >= last14.length) {
                    return const SizedBox();
                  }
                  return Text(
                    DateFormat('dd/MM').format(last14[idx].key),
                    style: const TextStyle(fontSize: 9),
                  );
                },
                reservedSize: 28,
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

class _CategoryPieChart extends StatelessWidget {
  final Map<int, double> data;
  final List<Category> categories;

  const _CategoryPieChart({required this.data, required this.categories});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final sections = data.entries.map((e) {
      final cat = categories.firstWhere(
        (c) => c.id == e.key,
        orElse: () => Category.defaults.last,
      );
      final pct = total > 0 ? (e.value / total * 100) : 0;
      return PieChartSectionData(
        color: Color(cat.color),
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: data.entries.map((e) {
            final cat = categories.firstWhere(
              (c) => c.id == e.key,
              orElse: () => Category.defaults.last,
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(cat.color),
                      shape: BoxShape.circle,
                    )),
                const SizedBox(width: 4),
                Text(
                  '${cat.icon} ${cat.name}: ${NumberFormat('#,##0').format(e.value)} DJF',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Aucune donnée',
              style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
