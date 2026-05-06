enum TransactionType { debit, credit }

class BankakTransaction {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final TransactionType type;
  final double balanceAfter;

  BankakTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.type,
    required this.balanceAfter,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'description': description,
        'category': category,
        'date': date.toIso8601String(),
        'type': type.index,
        'balanceAfter': balanceAfter,
      };

  factory BankakTransaction.fromJson(Map<String, dynamic> json) => BankakTransaction(
        id: json['id'],
        amount: json['amount'],
        description: json['description'],
        category: json['category'],
        date: DateTime.parse(json['date']),
        type: TransactionType.values[json['type']],
        balanceAfter: json['balanceAfter'],
      );
}
