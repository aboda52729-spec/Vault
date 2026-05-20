import 'package:hive/hive.dart';

class BudgetEntry extends HiveObject {
  final String id;
  final String category;
  final double amount;
  final int month;
  final int year;

  BudgetEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });
}

class BudgetEntryAdapter extends TypeAdapter<BudgetEntry> {
  @override
  final int typeId = 1;

  @override
  BudgetEntry read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return BudgetEntry(
      id: fields[0] as String,
      category: fields[1] as String,
      amount: fields[2] as double,
      month: fields[3] as int,
      year: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetEntry obj) {
    writer.writeByte(5);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.category);
    writer.writeByte(2); writer.write(obj.amount);
    writer.writeByte(3); writer.write(obj.month);
    writer.writeByte(4); writer.write(obj.year);
  }
}
