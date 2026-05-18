import 'package:flutter/material.dart';

class SyncPanel extends StatelessWidget {
  final bool isArabic;
  final bool isSyncing;
  final String? errorMessage;
  final VoidCallback onSync;

  const SyncPanel({
    super.key,
    required this.isArabic,
    required this.isSyncing,
    this.errorMessage,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.sync_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isArabic
                ? 'اسحب بيانات معاملاتك من صندوق الوارد'
                : 'Pull your transaction data from SMS inbox',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withAlpha(153),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isSyncing ? null : onSync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                isSyncing
                    ? (isArabic ? 'جارٍ المزامنة...' : 'Syncing...')
                    : (isArabic ? 'بدء المزامنة من الرسائل' : 'Start SMS Sync'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
