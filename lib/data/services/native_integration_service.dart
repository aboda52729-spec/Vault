import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class NativeIntegrationService {
  static const MethodChannel _channel = MethodChannel(AppConstants.channelName);

  final void Function(String smsBody) onSmsReceived;

  NativeIntegrationService({required this.onSmsReceived}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == AppConstants.methodOnSmsReceived) {
      final String smsBody = call.arguments as String;
      onSmsReceived(smsBody);
    }
  }
}
