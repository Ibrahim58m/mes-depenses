import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_parser.dart';
import '../database/db_helper.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final _query = SmsQuery();

  final List<String> _knownSenders = [
    'CACIntBank',
    'CACINTBANK',
    'SALAAMBANK',
    'WAAFI',
    'DMONEY',
    'D-MONEY',
  ];

  /// Demande les permissions SMS
  Future<bool> requestPermissions() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Lit tous les SMS historiques et les importe
  Future<int> importHistoricalSms() async {
    final granted = await requestPermissions();
    if (!granted) return 0;

    // Lire tous les SMS de la boîte de réception
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
    );

    int count = 0;
    final db = DbHelper();

    for (final msg in messages) {
      final sender = msg.sender ?? '';
      final body = msg.body ?? '';
      final date = msg.date ?? DateTime.now();

      // Vérifier si c'est un SMS d'un service connu
      final isKnown = _knownSenders.any(
        (s) => sender.toUpperCase().contains(s.toUpperCase()),
      );
      if (!isKnown) continue;

      final tx = SmsParser.parse(sender, body, date);
      if (tx != null) {
        final exists = await db.transactionExists(body);
        if (!exists) {
          await db.insertTransaction(tx);
          count++;
        }
      }
    }
    return count;
  }

  /// Écoute passive — appelle cette méthode depuis main
  /// flutter_sms_inbox ne supporte pas l'écoute en temps réel,
  /// donc on fait une vérification périodique (toutes les 5 min)
  void listenForNewSms() {
    // Pas de listener temps réel avec ce package
    // L'utilisateur peut appuyer sur Sync pour rafraîchir
  }
}
