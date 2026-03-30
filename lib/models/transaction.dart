enum TransactionType { debit, credit, transfer, phoneCredit, bankToWallet }

enum TransactionSource { cacBank, waafi, dMoney, unknown }

class Transaction {
  final int? id;
  final String rawSms;
  final TransactionSource source;
  final TransactionType type;
  final double amount;
  final double? balance;
  final String? beneficiaryName;
  final String? beneficiaryPhone;
  final String? merchantName;
  final String? reference;
  final DateTime date;
  final int? categoryId;

  Transaction({
    this.id,
    required this.rawSms,
    required this.source,
    required this.type,
    required this.amount,
    this.balance,
    this.beneficiaryName,
    this.beneficiaryPhone,
    this.merchantName,
    this.reference,
    required this.date,
    this.categoryId,
  });

  String get displayName {
    if (beneficiaryName != null && beneficiaryName!.isNotEmpty) {
      return beneficiaryName!;
    }
    if (merchantName != null && merchantName!.isNotEmpty) {
      return merchantName!;
    }
    switch (type) {
      case TransactionType.phoneCredit:
        return 'Crédit téléphonique';
      case TransactionType.bankToWallet:
        return 'Recharge portefeuille';
      default:
        return 'Transaction ${source.name}';
    }
  }

  String get sourceName {
    switch (source) {
      case TransactionSource.cacBank:
        return 'CAC Bank';
      case TransactionSource.waafi:
        return 'Waafi';
      case TransactionSource.dMoney:
        return 'D-Money';
      default:
        return 'Inconnu';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'raw_sms': rawSms,
      'source': source.index,
      'type': type.index,
      'amount': amount,
      'balance': balance,
      'beneficiary_name': beneficiaryName,
      'beneficiary_phone': beneficiaryPhone,
      'merchant_name': merchantName,
      'reference': reference,
      'date': date.millisecondsSinceEpoch,
      'category_id': categoryId,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      rawSms: map['raw_sms'] ?? '',
      source: TransactionSource.values[map['source'] ?? 3],
      type: TransactionType.values[map['type'] ?? 0],
      amount: (map['amount'] ?? 0).toDouble(),
      balance: map['balance']?.toDouble(),
      beneficiaryName: map['beneficiary_name'],
      beneficiaryPhone: map['beneficiary_phone'],
      merchantName: map['merchant_name'],
      reference: map['reference'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      categoryId: map['category_id'],
    );
  }

  Transaction copyWith({int? categoryId}) {
    return Transaction(
      id: id,
      rawSms: rawSms,
      source: source,
      type: type,
      amount: amount,
      balance: balance,
      beneficiaryName: beneficiaryName,
      beneficiaryPhone: beneficiaryPhone,
      merchantName: merchantName,
      reference: reference,
      date: date,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
