import 'dart:math';

import '../../core/enums/housing_type.dart';
import '../../data/models/diagnosis_input.dart';
import 'calculation_engine.dart';

class CoverageTimelinePoint {
  const CoverageTimelinePoint({
    required this.age,
    required this.requiredAmount,
    required this.existingCoverage,
    required this.gap,
  });

  final int age;
  final int requiredAmount;
  final int existingCoverage;
  final int gap;
}

const post65MedicalAdvice =
    '65歳以降は死亡保障より医療保障（がん・入院・介護）が重要になります。'
    '現在の医療保険の保障内容も合わせてご確認ください。';

const _mortgageAmortizationYears = 30;

List<int> timelineAges(int currentAge) {
  final ages = <int>[];
  for (var age = currentAge; age < 65; age += 5) {
    ages.add(age);
  }
  if (ages.isEmpty || ages.last != 65) {
    ages.add(65);
  }
  return ages;
}

List<CoverageTimelinePoint> calcCoverageTimeline(
  DiagnosisInput input, {
  CalculationEngine? engine,
}) {
  final calculator = engine ?? CalculationEngine();
  return timelineAges(input.age).map((age) {
    final projected = projectInputToAge(input, age);
    final requiredAmount = calculator.calculate(projected).requiredAmount;
    final existingCoverage = calcLifeAndTermCoverageAtAge(input, age);
    return CoverageTimelinePoint(
      age: age,
      requiredAmount: requiredAmount,
      existingCoverage: existingCoverage,
      gap: requiredAmount - existingCoverage,
    );
  }).toList();
}

DiagnosisInput projectInputToAge(DiagnosisInput input, int targetAge) {
  final yearsPassed = max(0, targetAge - input.age);
  final projectedChildren = input.childrenAges
      .map((age) => min(22, age + yearsPassed))
      .toList();

  final projectedMortgage = _projectMortgageBalance(input, yearsPassed);

  return input.copyWith(
    age: targetAge,
    spouseAge: input.hasSpouse && input.spouseAge != null
        ? input.spouseAge! + yearsPassed
        : input.spouseAge,
    childrenAges: projectedChildren,
    mortgageBalance: projectedMortgage,
  );
}

int? _projectMortgageBalance(DiagnosisInput input, int yearsPassed) {
  if (input.residenceType != HousingType.mortgaged) {
    return input.mortgageBalance;
  }
  final balance = input.mortgageBalance ?? 0;
  if (balance <= 0) return 0;
  final annualPaydown = (balance / _mortgageAmortizationYears).ceil();
  return max(0, balance - annualPaydown * yearsPassed);
}

int calcLifeAndTermCoverageAtAge(DiagnosisInput input, int atAge) {
  var total = input.lifeInsurance;
  if (input.termInsurance > 0) {
    final endAge = input.termInsuranceEndAge;
    if (endAge <= 0 || atAge <= endAge) {
      total += input.termInsurance;
    }
  }
  return total;
}

String? buildTimelineGapAdvice(List<CoverageTimelinePoint> points) {
  if (points.length < 2) return null;

  final midIndex = points.length ~/ 2;
  final earlyGap = points.first.gap;
  final laterGap = points[midIndex].gap;
  final finalGap = points.last.gap;

  if (laterGap > earlyGap + 100 || finalGap > earlyGap + 100) {
    return '50歳以降、不足額が拡大する見込みです。定期保険の見直しを検討しましょう。';
  }
  return null;
}
