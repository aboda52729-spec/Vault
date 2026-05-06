import 'package:flutter/services.dart';
import 'bankak_store.dart';

class NativeIntegrationService {
  static const MethodChannel _channel = MethodChannel('com.example.bankak_analytics/sms');
  
  final BankakStore store;

  NativeIntegrationService(this.store);

  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final String smsBody = call.arguments;
        store.processBankakSMS(smsBody);
      }
    });
  }
}
