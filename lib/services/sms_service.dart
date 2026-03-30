import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_parser.dart';
import '../models/transaction.dart';
import '../database/db_helper.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony _telephony = Telephony.instance;
  final DbHelper _db = DbHelper();

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

    int count = 0;
    for (final sender in _knownSenders) {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(sender),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      for (final msg in messages) {
        final body = msg.body ?? '';
        final address = msg.address ?? '';
        final date = msg.date != null
            ? DateTime.fromMillisecondsSinceEpoch(msg.date!)
            : DateTime.now();

        final tx = SmsParser.parse(address, body, date);
        if (tx != null) {
          final exists = await _db.transactionExists(body);
          if (!exists) {
            await _db.insertTransaction(tx);
            count++;
          }
        }
      }
    }
    return count;
  }

  /// Écoute les nouveaux SMS en temps réel
  void listenForNewSms() {
    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? '';
        final address = message.address ?? '';
        final date = DateTime.now();

        final tx = SmsParser.parse(address, body, date);
        if (tx != null) {
          final exists = await _db.transactionExists(body);
          if (!exists) {
            await _db.insertTransaction(tx);
          }
        }
      },
      listenInBackground: false,
    );
  }
}
