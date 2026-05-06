package com.example.bankak_analytics

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (message in messages) {
                val body = message.displayMessageBody
                val address = message.displayOriginatingAddress

                // Only process messages from Bankak (BOK)
                if (address.contains("BOK", ignoreCase = true) || address.contains("Bankak", ignoreCase = true)) {
                    Log.d("BankakSms", "Received Bankak SMS: $body")
                    methodChannel?.invokeMethod("onSmsReceived", body)
                }
            }
        }
    }
}
