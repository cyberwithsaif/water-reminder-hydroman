import 'package:hive/hive.dart';

part 'water_log.g.dart';

@HiveType(typeId: 1)
class WaterLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int amountMl;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  String cupType; // 'espresso', 'glass', 'bottle', 'sports', 'custom'

  @HiveField(4)
  DateTime? deletedAt;

  WaterLog({
    required this.id,
    required this.amountMl,
    required this.timestamp,
    this.cupType = 'glass',
    this.deletedAt,
  });
}
