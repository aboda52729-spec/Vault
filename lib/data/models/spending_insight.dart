import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class SpendingInsight {
  final String title;
  final String description;
  final String icon;
  final int colorValue;

  const SpendingInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.colorValue,
  });
}

class RecurringDetector {
  static List<String> detectRecurring(Map<String, DateTime> descriptions) {
    final grouped = <String, List<DateTime>>{};
    for (final entry in descriptions.entries) {
      final desc = entry.key;
      final date = entry.value;
      grouped.putIfAbsent(desc, () => []).add(date);
    }

    final recurring = <String>[];
    for (final entry in grouped.entries) {
      final dates = entry.value;
      if (dates.length >= 2) {
        final sorted = dates.toList()..sort();
        bool isRegular = true;
        if (sorted.length >= 3) {
          final intervals = <int>[];
          for (int i = 1; i < sorted.length; i++) {
            intervals.add(sorted[i].difference(sorted[i - 1]).inDays);
          }
          final avg = intervals.fold<int>(0, (s, v) => s + v) ~/ intervals.length;
          if (avg < 7 || avg > 60) isRegular = false;
          for (final d in intervals) {
            if ((d - avg).abs() > avg * 0.3) isRegular = false;
          }
        }
        if (isRegular) recurring.add(entry.key);
      }
    }
    return recurring;
  }
}

class SkeletonLoader {
  static String generate(String text) {
    return md5.convert(utf8.encode(text)).toString();
  }
}
