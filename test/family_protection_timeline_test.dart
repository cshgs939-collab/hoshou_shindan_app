import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/constants/education_costs.dart';
import 'package:hoshou_shindan_app/core/enums/pension_mode.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/family_protection_timeline.dart';
import 'package:hoshou_shindan_app/domain/calculation/old_age_pension_calculator.dart';

DiagnosisInput _input({
  bool hasSpouse = true,
  List<int> childrenAges = const [3],
  List<int>? childrenSchoolTypes,
  int schoolType = 3,
}) {
  return DiagnosisInput(
    id: 'timeline-graph-test',
    createdAt: DateTime(2026, 6, 27),
    age: 35,
    hasSpouse: hasSpouse,
    spouseAge: hasSpouse ? 33 : null,
    childrenAges: childrenAges,
    schoolType: schoolType,
    childrenSchoolTypes: childrenSchoolTypes ?? const [],
    annualIncome: 500,
    spouseIncome: 200,
    monthlyExpense: 25,
    retirementMonthlyExpense: 20,
    termInsurance: 1000,
    termInsuranceEndAge: 60,
    pensionMode: SurvivorPensionMode.auto.index,
    workingYears: 20,
  );
}

void main() {
  test('進路ごとに卒業年齢が異なる', () {
    expect(graduationAgeForPolicy(EducationPolicy.noHigherEd), 18);
    expect(graduationAgeForPolicy(EducationPolicy.vocational), 20);
    expect(graduationAgeForPolicy(EducationPolicy.publicAll), 22);
  });

  test('子ごとの進路でタイムライン上の卒業位置が変わる', () {
    final input = _input(
      schoolType: EducationPolicy.custom.index,
      childrenSchoolTypes: [
        EducationPolicy.noHigherEd.index,
        EducationPolicy.publicAll.index,
      ],
      childrenAges: const [5, 3],
    );
    final timeline = buildFamilyProtectionTimeline(input);

    expect(timeline.children.length, 2);
    expect(timeline.children[0].graduationAge, 18);
    expect(timeline.children[0].insuredAgeWhenGraduates, 48);
    expect(timeline.children[1].graduationAge, 22);
    expect(timeline.children[1].insuredAgeWhenGraduates, 54);
  });

  test('ひとり親世帯でもタイムラインを生成する', () {
    final timeline = buildFamilyProtectionTimeline(
      _input(hasSpouse: false, childrenAges: const [8]),
    );
    expect(timeline.hasSpouse, isFalse);
    expect(timeline.insuredAgeAtSpouse65, isNull);
    expect(timeline.children.single.graduationAge, 22);
  });

  test('老後生活費と老齢年金の差額を算出する', () {
    final gap = calcRetirementPensionGap(_input(hasSpouse: false));
    expect(gap.isSingleParent, isTrue);
    expect(gap.householdLabel, contains('ひとり親'));
    expect(gap.needMonthlyMan, 20);
    expect(gap.pensionMonthlyMan, greaterThan(0));
  });
}
