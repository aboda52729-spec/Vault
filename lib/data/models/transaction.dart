import 'package:hive/hive.dart';

class BankakTransaction extends HiveObject {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final int typeIndex;
  final double balanceAfter;

  BankakTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.typeIndex,
    required this.balanceAfter,
  });

  bool get isDebit => typeIndex == 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'description': description,
    'category': category,
    'date': date.toIso8601String(),
    'typeIndex': typeIndex,
    'balanceAfter': balanceAfter,
  };

  factory BankakTransaction.fromJson(Map<String, dynamic> json) => BankakTransaction(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    description: json['description'] as String,
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
    typeIndex: json['typeIndex'] as int,
    balanceAfter: (json['balanceAfter'] as num).toDouble(),
  );
}

class BankakTransactionAdapter extends TypeAdapter<BankakTransaction> {
  @override
  final int typeId = 0;

  @override
  BankakTransaction read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return BankakTransaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      description: fields[2] as String,
      category: fields[3] as String,
      date: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      typeIndex: fields[5] as int,
      balanceAfter: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BankakTransaction obj) {
    writer.writeByte(7);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.amount);
    writer.writeByte(2);
    writer.write(obj.description);
    writer.writeByte(3);
    writer.write(obj.category);
    writer.writeByte(4);
    writer.write(obj.date.millisecondsSinceEpoch);
    writer.writeByte(5);
    writer.write(obj.typeIndex);
    writer.writeByte(6);
    writer.write(obj.balanceAfter);
  }
}
