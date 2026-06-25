// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnosis_input.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiagnosisInputAdapter extends TypeAdapter<DiagnosisInput> {
  @override
  final int typeId = 0;

  @override
  DiagnosisInput read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiagnosisInput(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      age: fields[2] as int,
      hasSpouse: fields[3] as bool,
      spouseAge: fields[4] as int?,
      spouseEmploymentType: fields[5] as int?,
      childrenAges: (fields[6] as List).cast<int>(),
      schoolType: fields[7] as int?,
      annualIncome: fields[8] as int,
      spouseIncome: fields[9] as int,
      monthlyExpense: fields[10] as int,
      housingType: fields[11] as int?,
      mortgageBalance: fields[12] as int?,
      monthlyRent: fields[13] as int?,
      hasGroupCreditLifeInsurance:
          fields[25] == null ? true : fields[25] as bool,
      retirementMonthlyExpense: fields[14] as int,
      lifeInsurance: fields[15] as int,
      termInsurance: fields[16] as int,
      incomeProtectionMonthly: fields[17] as int,
      incomeProtectionYears: fields[18] as int,
      termInsuranceEndAge: fields[27] == null ? 0 : fields[27] as int,
      retirementPay: fields[19] as int,
      financialAssets: fields[20] as int,
      pensionMode: fields[21] as int?,
      manualPensionAnnual: fields[22] as int?,
      workingYears: fields[23] as int?,
      insuredEmploymentType: fields[26] == null ? 0 : fields[26] as int?,
      insuredWorkTypeRaw: fields[28] == null ? -1 : fields[28] as int,
      childrenSchoolTypes:
          fields[24] == null ? [] : (fields[24] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosisInput obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.hasSpouse)
      ..writeByte(4)
      ..write(obj.spouseAge)
      ..writeByte(5)
      ..write(obj.spouseEmploymentType)
      ..writeByte(6)
      ..write(obj.childrenAges)
      ..writeByte(7)
      ..write(obj.schoolType)
      ..writeByte(8)
      ..write(obj.annualIncome)
      ..writeByte(9)
      ..write(obj.spouseIncome)
      ..writeByte(10)
      ..write(obj.monthlyExpense)
      ..writeByte(11)
      ..write(obj.housingType)
      ..writeByte(12)
      ..write(obj.mortgageBalance)
      ..writeByte(13)
      ..write(obj.monthlyRent)
      ..writeByte(25)
      ..write(obj.hasGroupCreditLifeInsurance)
      ..writeByte(14)
      ..write(obj.retirementMonthlyExpense)
      ..writeByte(15)
      ..write(obj.lifeInsurance)
      ..writeByte(16)
      ..write(obj.termInsurance)
      ..writeByte(17)
      ..write(obj.incomeProtectionMonthly)
      ..writeByte(18)
      ..write(obj.incomeProtectionYears)
      ..writeByte(27)
      ..write(obj.termInsuranceEndAge)
      ..writeByte(19)
      ..write(obj.retirementPay)
      ..writeByte(20)
      ..write(obj.financialAssets)
      ..writeByte(21)
      ..write(obj.pensionMode)
      ..writeByte(22)
      ..write(obj.manualPensionAnnual)
      ..writeByte(23)
      ..write(obj.workingYears)
      ..writeByte(24)
      ..write(obj.childrenSchoolTypes)
      ..writeByte(26)
      ..write(obj.insuredEmploymentType)
      ..writeByte(28)
      ..write(obj.insuredWorkTypeRaw);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosisInputAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
