import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/sms_service.dart';

// ─── Période sélectionnée ───────────────────────────────────────
enum Period { week, month, threeMonths, year, all }

final selectedPeriodProvider = StateProvider<Period>((ref) => Period.month);

DateTime? _fromDate(Period p) {
  final now = DateTime.now();
  switch (p) {
    case Period.week:
      return now.subtract(const Duration(days: 7));
    case Period.month:
      return DateTime(now.year, now.month, 1);
    case Period.threeMonths:
      return DateTime(now.year, now.month - 2, 1);
    case Period.year:
      return DateTime(now.year, 1, 1);
    case Period.all:
      return null;
  }
}

// ─── Transactions ───────────────────────────────────────────────
final transactionsProvider =
    FutureProvider.family<List<Transaction>, Period>((ref, period) async {
  final db = DbHelper();
  return db.getAllTransactions(from: _fromDate(period));
});

// ─── Catégories ────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return DbHelper().getCategories();
});

// ─── Total dépenses ────────────────────────────────────────────
final totalExpensesProvider =
    FutureProvider.family<double, Period>((ref, period) async {
  return DbHelper().getTotalExpenses(from: _fromDate(period));
});

// ─── Dépenses par catégorie ────────────────────────────────────
final expensesByCategoryProvider =
    FutureProvider.family<Map<int, double>, Period>((ref, period) async {
  return DbHelper().getExpensesByCategory(from: _fromDate(period));
});

// ─── Dépenses par bénéficiaire ─────────────────────────────────
final expensesByBeneficiaryProvider =
    FutureProvider.family<Map<String, double>, Period>((ref, period) async {
  return DbHelper().getExpensesByBeneficiary(from: _fromDate(period));
});

// ─── Graphique journalier ──────────────────────────────────────
final dailyExpensesProvider =
    FutureProvider.family<Map<DateTime, double>, int>((ref, days) async {
  return DbHelper().getDailyExpenses(days: days);
});

// ─── Import SMS ────────────────────────────────────────────────
final smsImportProvider =
    FutureProvider.autoDispose<int>((ref) async {
  return SmsService().importHistoricalSms();
});
