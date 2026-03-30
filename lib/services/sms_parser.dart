import '../models/transaction.dart';

class SmsParser {
  /// Tente de parser un SMS selon son expéditeur
  static Transaction? parse(String sender, String body, DateTime date) {
    final s = sender.toUpperCase();
    if (s.contains('CAC') || s.contains('CACINTBANK')) {
      return _parseCacBank(body, date);
    }
    if (s.contains('SALAAM') || s.contains('WAAFI')) {
      return _parseWaafi(body, date);
    }
    if (s.contains('DMONEY') || s.contains('D-MONEY')) {
      return _parseDMoney(body, date);
    }
    return null;
  }

  // ───────────────────────── CAC BANK ─────────────────────────
  // Ex: "Votre compte 12000005462 a été débité de 100.00 DJF
  //      solde disponible 881.00 DJF
  //      Détails :CAC PAY - USSD ePOS103842  BOUTIQUE ASRAR AHMAD  - Market -  - 26089004026808000
  //      Date :30/03/2026 7:26:48 AM@"
  static Transaction? _parseCacBank(String body, DateTime smsDate) {
    final amountMatch =
        RegExp(r'débit[eé].*?de\s+([\d,.]+)\s*DJF', caseSensitive: false)
            .firstMatch(body);
    if (amountMatch == null) return null;

    final amount = _parseAmount(amountMatch.group(1)!);

    final balanceMatch =
        RegExp(r'solde disponible\s+([\d,.]+)\s*DJF', caseSensitive: false)
            .firstMatch(body);
    final balance =
        balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : null;

    // Extraire le marchand : après le code ePOS, avant " - Market"
    final merchantMatch = RegExp(
            r'ePOS\d+\s+(.+?)\s+-\s+\w+\s+-',
            caseSensitive: false)
        .firstMatch(body);
    final merchant = merchantMatch?.group(1)?.trim();

    // Référence
    final refMatch = RegExp(r'ePOS(\d+)').firstMatch(body);
    final ref = refMatch?.group(1);

    // Date dans le SMS
    final dateMatch =
        RegExp(r'Date\s*:([\d/]+\s+[\d:]+\s+[AP]M)', caseSensitive: false)
            .firstMatch(body);
    final parsedDate =
        dateMatch != null ? _parseCacDate(dateMatch.group(1)!) : smsDate;

    return Transaction(
      rawSms: body,
      source: TransactionSource.cacBank,
      type: TransactionType.debit,
      amount: amount,
      balance: balance,
      merchantName: merchant,
      reference: ref,
      date: parsedDate,
    );
  }

  // ───────────────────────── WAAFI ─────────────────────────
  // Ex: "WAAFI -> Transfer-Id: 65190492 Vous avez transféré avec succès
  //      DJF 100 vers Yacin Ali Djama (77144667) à 30/03/26 07:08:47,
  //      votre solde est de DJF 5,814.01."
  static Transaction? _parseWaafi(String body, DateTime smsDate) {
    final transferMatch = RegExp(
            r'Transfer-Id:\s*(\d+).*?DJF\s+([\d,]+)\s+vers\s+(.+?)\s*\((\d+)\)\s+à\s+([\d/]+\s+[\d:]+)',
            caseSensitive: false,
            dotAll: true)
        .firstMatch(body);

    if (transferMatch == null) return null;

    final ref = transferMatch.group(1);
    final amount = _parseAmount(transferMatch.group(2)!);
    final benefName = transferMatch.group(3)?.trim();
    final benefPhone = transferMatch.group(4);
    final dateStr = transferMatch.group(5);

    final balanceMatch =
        RegExp(r'solde est de DJF\s+([\d,]+\.?\d*)', caseSensitive: false)
            .firstMatch(body);
    final balance =
        balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : null;

    final parsedDate =
        dateStr != null ? _parseWaafiDate(dateStr) : smsDate;

    return Transaction(
      rawSms: body,
      source: TransactionSource.waafi,
      type: TransactionType.transfer,
      amount: amount,
      balance: balance,
      beneficiaryName: benefName,
      beneficiaryPhone: benefPhone,
      reference: ref,
      date: parsedDate,
    );
  }

  // ───────────────────────── D-MONEY ─────────────────────────
  // Type 1 – Virement banque → portefeuille :
  //   "Vous avez effectué un virement de 1,000DJF de votre compte bancaire
  //    vers le Compte principal le 12/03/2026 19:22:46.
  //    Des frais de 0DJF sont appliqués.
  //    Votre nouveau solde Compte principal est de 1,050DJF.
  //    L'identifiant de l'opération est 000309835641."
  //
  // Type 2 – Achat crédit téléphonique :
  //   "Vous avez acheté du crédit téléphonique d'une valeur de 1,000DJF
  //    le 12/03/2026 19:24:12.
  //    Votre nouveau solde du Compte principal est de 50DJF."
  static Transaction? _parseDMoney(String body, DateTime smsDate) {
    // --- Crédit téléphonique ---
    final creditMatch = RegExp(
            r"acheté du crédit téléphonique d'une valeur de\s*([\d,]+)DJF\s+le\s+([\d/]+\s+[\d:]+)",
            caseSensitive: false)
        .firstMatch(body);
    if (creditMatch != null) {
      final amount = _parseAmount(creditMatch.group(1)!);
      final parsedDate = _parseDMoneyDate(creditMatch.group(2)!) ?? smsDate;
      final balanceMatch =
          RegExp(r'solde.*?est de\s*([\d,]+)DJF', caseSensitive: false)
              .firstMatch(body);
      final balance =
          balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : null;
      return Transaction(
        rawSms: body,
        source: TransactionSource.dMoney,
        type: TransactionType.phoneCredit,
        amount: amount,
        balance: balance,
        beneficiaryName: 'Crédit téléphonique',
        date: parsedDate,
      );
    }

    // --- Virement banque → portefeuille ---
    final virementMatch = RegExp(
            r'virement de\s*([\d,]+)DJF.*?le\s+([\d/]+\s+[\d:]+)',
            caseSensitive: false,
            dotAll: true)
        .firstMatch(body);
    if (virementMatch != null) {
      final amount = _parseAmount(virementMatch.group(1)!);
      final parsedDate = _parseDMoneyDate(virementMatch.group(2)!) ?? smsDate;
      final refMatch =
          RegExp(r"identifiant.*?est\s+(\w+)", caseSensitive: false)
              .firstMatch(body);
      final balanceMatch =
          RegExp(r'solde.*?est de\s*([\d,]+)DJF', caseSensitive: false)
              .firstMatch(body);
      final balance =
          balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : null;
      return Transaction(
        rawSms: body,
        source: TransactionSource.dMoney,
        type: TransactionType.bankToWallet,
        amount: amount,
        balance: balance,
        beneficiaryName: 'Recharge D-Money',
        reference: refMatch?.group(1),
        date: parsedDate,
      );
    }

    return null;
  }

  // ─────────────────────── HELPERS ───────────────────────────

  static double _parseAmount(String raw) {
    // "1,000.50" → 1000.50  |  "1,000" → 1000  |  "100.00" → 100
    return double.tryParse(raw.replaceAll(',', '').replaceAll(' ', '')) ?? 0;
  }

  /// CAC : "30/03/2026 7:26:48 AM"
  static DateTime _parseCacDate(String s) {
    try {
      final parts = s.trim().split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);
      if (parts.length > 2 && parts[2].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      }
      if (parts.length > 2 && parts[2].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        hour,
        minute,
        second,
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Waafi : "30/03/26 07:08:47"
  static DateTime _parseWaafiDate(String s) {
    try {
      final parts = s.trim().split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      var year = int.parse(dateParts[2]);
      if (year < 100) year += 2000;
      return DateTime(
        year,
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  /// D-Money : "12/03/2026 19:22:46"
  static DateTime? _parseDMoneyDate(String s) {
    try {
      final parts = s.trim().split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      return DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return null;
    }
  }
}
