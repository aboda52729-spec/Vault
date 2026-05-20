import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';

class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.03),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stat(context, 'Avg/Day', '45K', Icons.calendar_today, Colors.blue),
              const SizedBox(width: 12),
              _stat(context, 'Largest', '200K', Icons.trending_up, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, 'Top Cat.', 'طعام', Icons.restaurant, Colors.green),
              const SizedBox(width: 12),
              _stat(context, 'Streak', '7d', Icons.whatshot, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
