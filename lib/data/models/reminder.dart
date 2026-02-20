import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 2)
class Reminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String time; // HH:mm format

  @HiveField(2)
  String label;

  @HiveField(3)
  bool isEnabled;

  @HiveField(4)
  String icon; // Material icon name

  @HiveField(5)
  DateTime? deletedAt;

  Reminder({
    required this.id,
    required this.time,
    required this.label,
    this.isEnabled = true,
    this.icon = 'water_drop',
    this.deletedAt,
  });
}
