import '../models/diagnosis_input.dart';
import '../models/diagnosis_result.dart';

Map<String, dynamic> diagnosisInputToJson(DiagnosisInput input) {
  return {
    'id': input.id,
    'createdAt': input.createdAt.toIso8601String(),
    'age': input.age,
    'hasSpouse': input.hasSpouse,
    'spouseAge': input.spouseAge,
    'spouseEmploymentType': input.spouseEmploymentType,
    'childrenAges': input.childrenAges,
    'schoolType': input.schoolType,
    'annualIncome': input.annualIncome,
    'spouseIncome': input.spouseIncome,
    'monthlyExpense': input.monthlyExpense,
    'housingType': input.housingType,
    'mortgageBalance': input.mortgageBalance,
    'monthlyRent': input.monthlyRent,
    'hasGroupCreditLifeInsurance': input.hasGroupCreditLifeInsurance,
    'retirementMonthlyExpense': input.retirementMonthlyExpense,
    'lifeInsurance': input.lifeInsurance,
    'termInsurance': input.termInsurance,
    'termInsuranceEndAge': input.termInsuranceEndAge,
    'incomeProtectionMonthly': input.incomeProtectionMonthly,
    'incomeProtectionYears': input.incomeProtectionYears,
    'retirementPay': input.retirementPay,
    'financialAssets': input.financialAssets,
    'pensionMode': input.pensionMode,
    'manualPensionAnnual': input.manualPensionAnnual,
    'workingYears': input.workingYears,
    'insuredEmploymentType': input.insuredEmploymentType,
    'insuredWorkTypeRaw': input.insuredWorkTypeRaw,
    'childrenSchoolTypes': input.normalizedChildSchoolTypes(),
  };
}

Map<String, dynamic> diagnosisResultToJson(DiagnosisResult result) {
  return {
    'id': result.id,
    'inputId': result.inputId,
    'calculatedAt': result.calculatedAt.toIso8601String(),
    'requiredAmount': result.requiredAmount,
    'existingCoverage': result.existingCoverage,
    'survivorPension': result.survivorPension,
    'survivorWorkIncome': result.survivorWorkIncome,
    'gap': result.gap,
    'livingExpense': result.livingExpense,
    'educationFee': result.educationFee,
    'housingFee': result.housingFee,
    'funeralFee': result.funeralFee,
    'childrenCount': result.childrenCount,
    'hasSpouse': result.hasSpouse,
  };
}

Map<String, dynamic> diagnosisRecordToJson({
  required DiagnosisInput input,
  required DiagnosisResult result,
}) {
  return {
    'app': 'まもる計算',
    'version': '1.0.0',
    'exportedAt': DateTime.now().toIso8601String(),
    'input': diagnosisInputToJson(input),
    'result': diagnosisResultToJson(result),
  };
}
