import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/school_type.dart';
import '../../data/models/diagnosis_input.dart';
import '../../data/repositories/hive_repository.dart';

class DiagnosisInputNotifier extends StateNotifier<DiagnosisInput> {
  DiagnosisInputNotifier(this._repository) : super(DiagnosisInput.empty()) {
    final draft = _repository.getDraft();
    if (draft != null) {
      state = draft;
    }
  }

  final HiveRepository _repository;

  List<int> _syncChildSchoolTypes(List<int> ages, List<int> current) {
    final synced = List<int>.from(current);
    while (synced.length < ages.length) {
      synced.add(EducationPolicy.publicAll.index);
    }
    while (synced.length > ages.length) {
      synced.removeLast();
    }
    return synced;
  }

  Future<void> _persistDraft() async {
    await _repository.saveDraft(state);
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
    _persistDraft();
  }

  void updateHasSpouse(bool hasSpouse) {
    state = state.copyWith(
      hasSpouse: hasSpouse,
      spouseAge: hasSpouse ? (state.spouseAge ?? 33) : null,
      clearSpouseAge: !hasSpouse,
    );
    _persistDraft();
  }

  void updateSpouseAge(int age) {
    state = state.copyWith(spouseAge: age);
    _persistDraft();
  }

  void updateSpouseEmployment(int index) {
    state = state.copyWith(spouseEmploymentType: index);
    _persistDraft();
  }

  void updateChildrenCount(int count) {
    final clamped = count.clamp(0, 6);
    final ages = List<int>.from(state.childrenAges);
    while (ages.length < clamped) {
      ages.add(3);
    }
    while (ages.length > clamped) {
      ages.removeLast();
    }
    final schoolTypes = _syncChildSchoolTypes(ages, state.childrenSchoolTypes);
    state = state.copyWith(
      childrenAges: ages,
      childrenSchoolTypes: schoolTypes,
    );
    _persistDraft();
  }

  void updateChildAge(int index, int age) {
    final ages = List<int>.from(state.childrenAges);
    if (index < 0 || index >= ages.length) return;
    ages[index] = age;
    state = state.copyWith(childrenAges: ages);
    _persistDraft();
  }

  void updateEducationPolicy(int index) {
    final schoolTypes = index == EducationPolicy.custom.index
        ? _syncChildSchoolTypes(
            state.childrenAges,
            state.childrenSchoolTypes,
          )
        : state.childrenSchoolTypes;
    state = state.copyWith(
      schoolType: index,
      childrenSchoolTypes: schoolTypes,
    );
    _persistDraft();
  }

  void updateChildSchoolPolicy(int index, int policyIndex) {
    if (index < 0 || index >= state.childrenAges.length) return;
    final schoolTypes = _syncChildSchoolTypes(
      state.childrenAges,
      state.childrenSchoolTypes,
    );
    schoolTypes[index] = policyIndex;
    state = state.copyWith(childrenSchoolTypes: schoolTypes);
    _persistDraft();
  }

  void updateAnnualIncome(int income) {
    state = state.copyWith(annualIncome: income);
    _persistDraft();
  }

  void updateSpouseIncome(int income) {
    state = state.copyWith(spouseIncome: income);
    _persistDraft();
  }

  void updateMonthlyExpense(int expense) {
    state = state.copyWith(monthlyExpense: expense);
    _persistDraft();
  }

  void updateHousingType(int index) {
    state = state.copyWith(housingType: index);
    _persistDraft();
  }

  void updateMortgageBalance(int? balance) {
    state = state.copyWith(
      mortgageBalance: balance,
      clearMortgageBalance: balance == null,
    );
    _persistDraft();
  }

  void updateMonthlyRent(int? rent) {
    state = state.copyWith(
      monthlyRent: rent,
      clearMonthlyRent: rent == null,
    );
    _persistDraft();
  }

  void updateRetirementMonthlyExpense(int expense) {
    state = state.copyWith(retirementMonthlyExpense: expense);
    _persistDraft();
  }

  void updateLifeInsurance(int value) {
    state = state.copyWith(lifeInsurance: value);
    _persistDraft();
  }

  void updateTermInsurance(int value) {
    state = state.copyWith(termInsurance: value);
    _persistDraft();
  }

  void updateIncomeProtectionMonthly(int value) {
    state = state.copyWith(incomeProtectionMonthly: value);
    _persistDraft();
  }

  void updateIncomeProtectionYears(int value) {
    state = state.copyWith(incomeProtectionYears: value);
    _persistDraft();
  }

  void updateRetirementPay(int value) {
    state = state.copyWith(retirementPay: value);
    _persistDraft();
  }

  void updateFinancialAssets(int value) {
    state = state.copyWith(financialAssets: value);
    _persistDraft();
  }

  void updatePensionMode(int index) {
    state = state.copyWith(pensionMode: index);
    _persistDraft();
  }

  void updateManualPensionAnnual(int? value) {
    state = state.copyWith(
      manualPensionAnnual: value,
      clearManualPensionAnnual: value == null,
    );
    _persistDraft();
  }

  void updateWorkingYears(int? value) {
    state = state.copyWith(
      workingYears: value,
      clearWorkingYears: value == null,
    );
    _persistDraft();
  }

  void reset() {
    state = DiagnosisInput.empty();
    _persistDraft();
  }
}

final diagnosisInputProvider =
    StateNotifierProvider<DiagnosisInputNotifier, DiagnosisInput>((ref) {
  return DiagnosisInputNotifier(ref.watch(hiveRepositoryProvider));
});

final currentStepProvider = StateProvider<int>((ref) => 0);
