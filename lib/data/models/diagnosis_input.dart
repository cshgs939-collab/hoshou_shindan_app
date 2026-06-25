import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/enums/housing_type.dart';
import '../../core/enums/insured_employment_type.dart';
import '../../core/enums/pension_mode.dart';
import '../../core/enums/school_type.dart';

part 'diagnosis_input.g.dart';

@HiveType(typeId: 0)
class DiagnosisInput extends HiveObject {
  DiagnosisInput({
    required this.id,
    required this.createdAt,
    required this.age,
    required this.hasSpouse,
    this.spouseAge,
    int? spouseEmploymentType,
    this.childrenAges = const [],
    int? schoolType,
    this.annualIncome = 0,
    this.spouseIncome = 0,
    this.monthlyExpense = 0,
    int? housingType,
    this.mortgageBalance,
    this.monthlyRent,
    this.hasGroupCreditLifeInsurance = true,
    this.retirementMonthlyExpense = 20,
    this.lifeInsurance = 0,
    this.termInsurance = 0,
    this.incomeProtectionMonthly = 0,
    this.incomeProtectionYears = 0,
    this.termInsuranceEndAge = 0,
    this.retirementPay = 0,
    this.financialAssets = 0,
    int? pensionMode,
    this.manualPensionAnnual,
    this.workingYears,
    int? insuredEmploymentType,
    this.insuredWorkTypeRaw = -1,
    this.childrenSchoolTypes = const [],
  })  : spouseEmploymentType =
            spouseEmploymentType ?? SpouseEmploymentType.fullTime.index,
        schoolType = schoolType ?? EducationPolicy.publicAll.index,
        housingType = housingType ?? HousingType.renting.index,
        pensionMode = pensionMode ?? SurvivorPensionMode.auto.index,
        insuredEmploymentType = insuredEmploymentType ??
            InsuredEmploymentType.companyEmployee.index;

  factory DiagnosisInput.empty() {
    return DiagnosisInput(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      age: 35,
      hasSpouse: true,
      spouseAge: 33,
      childrenAges: const [3],
      annualIncome: 500,
      spouseIncome: 200,
      monthlyExpense: 30,
      monthlyRent: 10,
    );
  }

  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  int age;

  @HiveField(3)
  bool hasSpouse;

  @HiveField(4)
  int? spouseAge;

  @HiveField(5)
  int spouseEmploymentType;

  @HiveField(6)
  List<int> childrenAges;

  @HiveField(7)
  int schoolType;

  @HiveField(8)
  int annualIncome;

  @HiveField(9)
  int spouseIncome;

  @HiveField(10)
  int monthlyExpense;

  @HiveField(11)
  int housingType;

  @HiveField(12)
  int? mortgageBalance;

  @HiveField(13)
  int? monthlyRent;

  @HiveField(25, defaultValue: true)
  bool hasGroupCreditLifeInsurance;

  @HiveField(14)
  int retirementMonthlyExpense;

  @HiveField(15)
  int lifeInsurance;

  @HiveField(16)
  int termInsurance;

  @HiveField(17)
  int incomeProtectionMonthly;

  @HiveField(18)
  int incomeProtectionYears;

  @HiveField(27, defaultValue: 0)
  int termInsuranceEndAge;

  @HiveField(19)
  int retirementPay;

  @HiveField(20)
  int financialAssets;

  @HiveField(21)
  int pensionMode;

  @HiveField(22)
  int? manualPensionAnnual;

  @HiveField(23)
  int? workingYears;

  @HiveField(24, defaultValue: [])
  List<int> childrenSchoolTypes;

  @HiveField(26, defaultValue: 0)
  int insuredEmploymentType;

  /// あなた（世帯主）の就業状況。SpouseEmploymentType の index。-1 は未設定（旧データ）。
  @HiveField(28, defaultValue: -1)
  int insuredWorkTypeRaw;

  SpouseEmploymentType get employmentType =>
      SpouseEmploymentType.values[spouseEmploymentType];

  SpouseEmploymentType get insuredWorkType {
    if (insuredWorkTypeRaw >= 0 &&
        insuredWorkTypeRaw < SpouseEmploymentType.values.length) {
      return SpouseEmploymentType.values[insuredWorkTypeRaw];
    }
    return insuredEmploymentType == InsuredEmploymentType.selfEmployed.index
        ? SpouseEmploymentType.selfEmployed
        : SpouseEmploymentType.fullTime;
  }

  EducationPolicy get educationPolicy =>
      EducationPolicy.values[schoolType];

  HousingType get residenceType => HousingType.values[housingType];

  SurvivorPensionMode get survivorPensionMode =>
      SurvivorPensionMode.values[pensionMode];

  InsuredEmploymentType get insuredEmployment =>
      InsuredEmploymentType.values[insuredEmploymentType];

  int get youngestChildAge =>
      childrenAges.isEmpty ? 0 : childrenAges.reduce((a, b) => a < b ? a : b);

  EducationPolicy educationPolicyForChild(int index) {
    if (educationPolicy != EducationPolicy.custom) {
      return educationPolicy;
    }
    if (index < 0 || index >= childrenSchoolTypes.length) {
      return EducationPolicy.publicAll;
    }
    final value = childrenSchoolTypes[index];
    if (value < 0 || value >= EducationPolicy.values.length) {
      return EducationPolicy.publicAll;
    }
    final policy = EducationPolicy.values[value];
    if (policy == EducationPolicy.custom) {
      return EducationPolicy.publicAll;
    }
    return policy;
  }

  List<int> normalizedChildSchoolTypes() {
    return List<int>.generate(childrenAges.length, (index) {
      return educationPolicyForChild(index).index;
    });
  }

  DiagnosisInput copyWith({
    String? id,
    DateTime? createdAt,
    int? age,
    bool? hasSpouse,
    int? spouseAge,
    int? spouseEmploymentType,
    List<int>? childrenAges,
    int? schoolType,
    int? annualIncome,
    int? spouseIncome,
    int? monthlyExpense,
    int? housingType,
    int? mortgageBalance,
    int? monthlyRent,
    bool? hasGroupCreditLifeInsurance,
    int? retirementMonthlyExpense,
    int? lifeInsurance,
    int? termInsurance,
    int? incomeProtectionMonthly,
    int? incomeProtectionYears,
    int? termInsuranceEndAge,
    int? retirementPay,
    int? financialAssets,
    int? pensionMode,
    int? manualPensionAnnual,
    int? workingYears,
    int? insuredEmploymentType,
    int? insuredWorkTypeRaw,
    List<int>? childrenSchoolTypes,
    bool clearSpouseAge = false,
    bool clearMortgageBalance = false,
    bool clearMonthlyRent = false,
    bool clearManualPensionAnnual = false,
    bool clearWorkingYears = false,
  }) {
    return DiagnosisInput(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      age: age ?? this.age,
      hasSpouse: hasSpouse ?? this.hasSpouse,
      spouseAge: clearSpouseAge ? null : (spouseAge ?? this.spouseAge),
      spouseEmploymentType:
          spouseEmploymentType ?? this.spouseEmploymentType,
      childrenAges: childrenAges ?? List<int>.from(this.childrenAges),
      schoolType: schoolType ?? this.schoolType,
      annualIncome: annualIncome ?? this.annualIncome,
      spouseIncome: spouseIncome ?? this.spouseIncome,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      housingType: housingType ?? this.housingType,
      mortgageBalance: clearMortgageBalance
          ? null
          : (mortgageBalance ?? this.mortgageBalance),
      monthlyRent:
          clearMonthlyRent ? null : (monthlyRent ?? this.monthlyRent),
      hasGroupCreditLifeInsurance:
          hasGroupCreditLifeInsurance ?? this.hasGroupCreditLifeInsurance,
      retirementMonthlyExpense:
          retirementMonthlyExpense ?? this.retirementMonthlyExpense,
      lifeInsurance: lifeInsurance ?? this.lifeInsurance,
      termInsurance: termInsurance ?? this.termInsurance,
      incomeProtectionMonthly:
          incomeProtectionMonthly ?? this.incomeProtectionMonthly,
      incomeProtectionYears:
          incomeProtectionYears ?? this.incomeProtectionYears,
      termInsuranceEndAge: termInsuranceEndAge ?? this.termInsuranceEndAge,
      retirementPay: retirementPay ?? this.retirementPay,
      financialAssets: financialAssets ?? this.financialAssets,
      pensionMode: pensionMode ?? this.pensionMode,
      manualPensionAnnual: clearManualPensionAnnual
          ? null
          : (manualPensionAnnual ?? this.manualPensionAnnual),
      workingYears:
          clearWorkingYears ? null : (workingYears ?? this.workingYears),
      insuredEmploymentType:
          insuredEmploymentType ?? this.insuredEmploymentType,
      insuredWorkTypeRaw: insuredWorkTypeRaw ?? this.insuredWorkTypeRaw,
      childrenSchoolTypes: childrenSchoolTypes ??
          List<int>.from(this.childrenSchoolTypes),
    );
  }
}
