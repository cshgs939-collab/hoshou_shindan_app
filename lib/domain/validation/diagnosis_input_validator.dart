import '../../core/enums/housing_type.dart';
import '../../core/enums/pension_mode.dart';
import '../../data/models/diagnosis_input.dart';

class DiagnosisInputValidator {
  static String? validateAge(int? age) {
    if (age == null) return '年齢を入力してください';
    if (age < 20 || age > 79) return '20〜79歳の範囲で入力してください';
    return null;
  }

  static String? validateAnnualIncome(int? income) {
    if (income == null || income <= 0) return '年収を入力してください';
    if (income > 5000) return '5,000万円以下で入力してください';
    return null;
  }

  static String? validateSpouseIncome(int? income) {
    if (income == null || income < 0) return '0以上で入力してください';
    if (income > 3000) return '3,000万円以下で入力してください';
    return null;
  }

  static String? validateMonthlyExpense(int? expense) {
    if (expense == null || expense <= 0) return '生活費を入力してください';
    if (expense < 10) return '10万円以上で入力してください';
    if (expense > 100) return '100万円以下で入力してください';
    return null;
  }

  static String? validateChildAge(int? age) {
    if (age == null) return '年齢を入力してください';
    if (age < 0 || age > 22) return '0〜22歳の範囲で入力してください';
    return null;
  }

  static String? validateMortgageBalance(int? balance) {
    if (balance == null) return '住宅ローン残債を入力してください';
    if (balance < 0 || balance > 10000) {
      return '0〜1億円の範囲で入力してください';
    }
    return null;
  }

  static String? validateMonthlyRent(int? rent) {
    if (rent == null) return '月額家賃を入力してください';
    if (rent < 1 || rent > 100) return '1〜100万円の範囲で入力してください';
    return null;
  }

  static bool isStep1Valid(DiagnosisInput input) {
    if (validateAge(input.age) != null) return false;
    if (input.hasSpouse) {
      if (validateAge(input.spouseAge) != null) return false;
    }
    for (final age in input.childrenAges) {
      if (validateChildAge(age) != null) return false;
    }
    return true;
  }

  static bool isStep2Valid(DiagnosisInput input) {
    if (validateAnnualIncome(input.annualIncome) != null) return false;
    if (input.hasSpouse && validateSpouseIncome(input.spouseIncome) != null) {
      return false;
    }
    if (validateMonthlyExpense(input.monthlyExpense) != null) return false;
    if (input.residenceType == HousingType.mortgaged &&
        validateMortgageBalance(input.mortgageBalance) != null) {
      return false;
    }
    if (input.residenceType == HousingType.renting &&
        validateMonthlyRent(input.monthlyRent) != null) {
      return false;
    }
    return true;
  }

  static bool isStep3Valid(DiagnosisInput input) {
    if (input.survivorPensionMode == SurvivorPensionMode.manual &&
        (input.manualPensionAnnual == null || input.manualPensionAnnual! < 0)) {
      return false;
    }
    return true;
  }
}
