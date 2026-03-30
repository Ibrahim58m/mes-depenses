import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;
  final VoidCallback? onCategoryTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = transaction.categoryId != null
        ? categories.firstWhere(
            (c) => c.id == transaction.categoryId,
            orElse: () => Category.defaults.last,
          )
        : null;

    final isExpense = transaction.type == TransactionType.debit ||
        transaction.type == TransactionType.transfer ||
        transaction.type == TransactionType.phoneCredit;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat != null
              ? Color(cat.color).withOpacity(0.2)
              : Colors.grey.shade200,
          child: Text(
            cat?.icon ?? _sourceIcon(transaction.source),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          transaction.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy • HH:mm').format(transaction.date),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _sourceColor(transaction.source).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.sourceName,
                    style: TextStyle(
                      fontSize: 10,
                      color: _sourceColor(transaction.source),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (cat != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onCategoryTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(cat.color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(cat.color),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else
                  GestureDetector(
                    onTap: onCategoryTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '+ Catégorie',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? '-' : '+'} ${NumberFormat('#,##0').format(transaction.amount)} DJF',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExpense ? Colors.red.shade600 : Colors.green.shade600,
              ),
            ),
            if (transaction.balance != null)
              Text(
                'Solde: ${NumberFormat('#,##0').format(transaction.balance)} DJF',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _sourceIcon(TransactionSource s) {
    switch (s) {
      case TransactionSource.cacBank:
        return '🏦';
      case TransactionSource.waafi:
        return '📲';
      case TransactionSource.dMoney:
        return '💰';
      default:
        return '💳';
    }
  }

  Color _sourceColor(TransactionSource s) {
    switch (s) {
      case TransactionSource.cacBank:
        return Colors.blue.shade700;
      case TransactionSource.waafi:
        return Colors.purple.shade600;
      case TransactionSource.dMoney:
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }
}
