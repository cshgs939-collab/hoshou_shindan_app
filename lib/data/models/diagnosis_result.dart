import 'package:hive/hive.dart';

part 'diagnosis_result.g.dart';

@HiveType(typeId: 1)
class DiagnosisResult extends HiveObject {
  DiagnosisResult({
    required this.id,
    required this.inputId,
    required this.calculatedAt,
    required this.requiredAmount,
    required this.existingCoverage,
    required this.survivorPension,
    required this.gap,
    required this.livingExpense,
    required this.educationFee,
    required this.housingFee,
    required this.funeralFee,
    this.childrenCount = 0,
    this.hasSpouse = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String inputId;

  @HiveField(2)
  DateTime calculatedAt;

  @HiveField(3)
  int requiredAmount;

  @HiveField(4)
  int existingCoverage;

  @HiveField(5)
  int survivorPension;

  @HiveField(6)
  int gap;

  @HiveField(7)
  int livingExpense;

  @HiveField(8)
  int educationFee;

  @HiveField(9)
  int housingFee;

  @HiveField(10)
  int funeralFee;

  @HiveField(11)
  int childrenCount;

  @HiveField(12)
  bool hasSpouse;
}
