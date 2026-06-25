// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnosis_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiagnosisResultAdapter extends TypeAdapter<DiagnosisResult> {
  @override
  final int typeId = 1;

  @override
  DiagnosisResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiagnosisResult(
      id: fields[0] as String,
      inputId: fields[1] as String,
      calculatedAt: fields[2] as DateTime,
      requiredAmount: fields[3] as int,
      existingCoverage: fields[4] as int,
      survivorPension: fields[5] as int,
      gap: fields[6] as int,
      livingExpense: fields[7] as int,
      educationFee: fields[8] as int,
      housingFee: fields[9] as int,
      funeralFee: fields[10] as int,
      childrenCount: fields[11] as int,
      hasSpouse: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosisResult obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.inputId)
      ..writeByte(2)
      ..write(obj.calculatedAt)
      ..writeByte(3)
      ..write(obj.requiredAmount)
      ..writeByte(4)
      ..write(obj.existingCoverage)
      ..writeByte(5)
      ..write(obj.survivorPension)
      ..writeByte(6)
      ..write(obj.gap)
      ..writeByte(7)
      ..write(obj.livingExpense)
      ..writeByte(8)
      ..write(obj.educationFee)
      ..writeByte(9)
      ..write(obj.housingFee)
      ..writeByte(10)
      ..write(obj.funeralFee)
      ..writeByte(11)
      ..write(obj.childrenCount)
      ..writeByte(12)
      ..write(obj.hasSpouse);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosisResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
