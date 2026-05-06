import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';

class TransactionItem extends StatelessWidget {
  final BankakTransaction tx;
  final bool isArabic;
  const TransactionItem({super.key, required this.tx, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final isDebit = tx.type == TransactionType.debit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDebit ? Colors.redAccent.withAlpha(25) : Colors.greenAccent.withAlpha(25),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isDebit ? Icons.south_east_rounded : Icons.north_east_rounded,
                color: isDebit ? Colors.redAccent : Colors.greenAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.category,
                          style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(128), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(tx.date),
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(77)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? '-' : '+'}${fmt.format(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDebit ? Colors.white : Colors.greenAccent,
                  ),
                ),
                Text(
                  fmt.format(tx.balanceAfter),
                  style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(51)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
