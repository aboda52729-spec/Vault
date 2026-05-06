import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  /// Requests SMS permission from the user.
  Future<bool> requestSmsPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }
    return status.isGranted;
  }

  /// Fetches SMS messages from the inbox that match Bankak patterns.
  Future<List<SmsMessage>> getBankakMessages() async {
    final hasPermission = await requestSmsPermission();
    if (!hasPermission) {
      return [];
    }

    // Query recent messages from the inbox
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 1000, // Look through the last 1000 messages
    );

    // Filter messages that look like they are from Bank of Khartoum
    return messages.where((msg) {
      final sender = msg.address?.toLowerCase() ?? '';
      final body = msg.body ?? '';
      
      return sender.contains('bok') || 
             sender.contains('bankak') || 
             body.contains('بنك الخرطوم') || 
             body.contains('Bank of Khartoum');
    }).toList();
  }
}
