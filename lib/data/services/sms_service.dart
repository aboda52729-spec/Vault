import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/arabic_keywords.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  Future<bool> requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }
    return status.isGranted;
  }

  Future<List<SmsMessage>> getBankakMessages() async {
    final hasPermission = await requestSmsPermission();
    if (!hasPermission) return [];

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 1000,
    );

    return messages.where((msg) {
      final sender = msg.address?.toLowerCase() ?? '';
      final body = msg.body ?? '';
      return ArabicKeywords.bankIdentification
          .any((kw) => sender.contains(kw.toLowerCase()) || body.contains(kw));
    }).toList();
  }
}
