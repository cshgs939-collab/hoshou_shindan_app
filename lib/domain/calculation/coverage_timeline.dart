import 'dart:math';

import '../../core/constants/pension_constants.dart';
import '../../core/enums/housing_type.dart';
import '../../data/models/diagnosis_input.dart';
import 'calculation_engine.dart';

/// ある年齢時点の既存保障内訳（万円）
class CoverageBreakdown {
  const CoverageBreakdown({
    required this.life,
    required this.term,
    required this.incomeProtection,
    required this.savings,
  });

  final int life;
  final int term;
  final int incomeProtection;
  final int savings;

  int get total => life + term + incomeProtection + savings;
}

class CoverageTimelinePoint {
  const CoverageTimelinePoint({
    required this.age,
    required this.requiredAmount,
    required this.existingCoverage,
    required this.gap,
    required this.breakdown,
  });

  final int age;
  final int requiredAmount;
  final int existingCoverage;
  final int gap;
  final CoverageBreakdown breakdown;
}

/// 「1,000万円・35歳〜60歳」形式の保障区間
class CoveragePeriodSegment {
  const CoveragePeriodSegment({
    required this.categoryLabel,
    required this.amountMan,
    required this.startAge,
    required this.endAge,
    required this.colorValue,
  });

  final String categoryLabel;
  final int amountMan;
  final int startAge;
  final int endAge;
  final int colorValue;

  String get ageRangeLabel =>
      endAge <= startAge ? '${startAge}歳' : '${startAge}歳〜${endAge}歳';
}

class CoveragePeriodRow {
  const CoveragePeriodRow({
    required this.title,
    required this.segments,
  });

  final String title;
  final List<CoveragePeriodSegment> segments;
}

class CoveragePeriodChartData {
  const CoveragePeriodChartData({
    required this.startAge,
    required this.endAge,
    required this.rows,
    required this.summaryLines,
  });

  final int startAge;
  final int endAge;
  final List<CoveragePeriodRow> rows;
  final List<String> summaryLines;

  int get spanYears => max(1, endAge - startAge);
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
    final breakdown = calcCoverageBreakdownAtAge(input, age);
    final existingCoverage = breakdown.total;
    return CoverageTimelinePoint(
      age: age,
      requiredAmount: requiredAmount,
      existingCoverage: existingCoverage,
      gap: requiredAmount - existingCoverage,
      breakdown: breakdown,
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

CoverageBreakdown calcCoverageBreakdownAtAge(DiagnosisInput input, int atAge) {
  final life = input.lifeInsurance;
  var term = 0;
  if (input.termInsurance > 0) {
    final endAge = input.termInsuranceEndAge;
    if (endAge <= 0 || atAge <= endAge) {
      term = input.termInsurance;
    }
  }

  final yearsPassed = max(0, atAge - input.age);
  final incomeYearsLeft = max(0, input.incomeProtectionYears - yearsPassed);
  final incomeProtection =
      input.incomeProtectionMonthly * 12 * incomeYearsLeft;
  final savings = input.retirementPay + input.financialAssets;

  return CoverageBreakdown(
    life: life,
    term: term,
    incomeProtection: incomeProtection,
    savings: savings,
  );
}

/// 後方互換
int calcLifeAndTermCoverageAtAge(DiagnosisInput input, int atAge) {
  final breakdown = calcCoverageBreakdownAtAge(input, atAge);
  return breakdown.life + breakdown.term;
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
  if (points.any((p) => p.breakdown.term > 0) &&
      points.last.breakdown.term < points.first.breakdown.term) {
    return '定期保険満了後は積み上げの緑（定期）がなくなり、不足が広がる可能性があります。';
  }
  return null;
}

CoveragePeriodChartData calcCoveragePeriodChart(DiagnosisInput input) {
  final startAge = input.age;
  const endAge = retirementStartAge;
  final points = calcCoverageTimeline(input);
  final rows = <CoveragePeriodRow>[];

  rows.add(
    CoveragePeriodRow(
      title: '必要保障額',
      segments: _requiredSegments(points, 0xFF1565C0),
    ),
  );

  final b0 = calcCoverageBreakdownAtAge(input, startAge);
  if (b0.life > 0) {
    rows.add(
      CoveragePeriodRow(
        title: '終身・養老',
        segments: [
          CoveragePeriodSegment(
            categoryLabel: '終身・養老',
            amountMan: b0.life,
            startAge: startAge,
            endAge: endAge,
            colorValue: 0xFF43A047,
          ),
        ],
      ),
    );
  }

  if (b0.term > 0) {
    final termEnd = input.termInsuranceEndAge > 0
        ? min(input.termInsuranceEndAge, endAge)
        : endAge;
    rows.add(
      CoveragePeriodRow(
        title: '定期保険',
        segments: [
          CoveragePeriodSegment(
            categoryLabel: '定期保険',
            amountMan: input.termInsurance,
            startAge: startAge,
            endAge: termEnd,
            colorValue: 0xFF00897B,
          ),
        ],
      ),
    );
  }

  if (input.incomeProtectionMonthly > 0 && input.incomeProtectionYears > 0) {
    rows.add(
      CoveragePeriodRow(
        title: '収入保障',
        segments: _incomeProtectionSegments(input, endAge),
      ),
    );
  }

  if (b0.savings > 0) {
    rows.add(
      CoveragePeriodRow(
        title: '退職金・貯蓄',
        segments: [
          CoveragePeriodSegment(
            categoryLabel: '退職金・貯蓄',
            amountMan: b0.savings,
            startAge: startAge,
            endAge: endAge,
            colorValue: 0xFF78909C,
          ),
        ],
      ),
    );
  }

  final summaryLines = <String>[];
  for (final row in rows) {
    for (final seg in row.segments) {
      summaryLines.add(
        '${row.title} ${formatManYenShort(seg.amountMan)}（${seg.ageRangeLabel}）',
      );
    }
  }

  return CoveragePeriodChartData(
    startAge: startAge,
    endAge: endAge,
    rows: rows,
    summaryLines: summaryLines,
  );
}

String formatManYenShort(int amountMan) {
  if (amountMan >= 10000) {
    final oku = amountMan / 10000;
    return oku == oku.roundToDouble()
        ? '${oku.round()}億円'
        : '${oku.toStringAsFixed(1)}億円';
  }
  return '${amountMan}万円';
}

List<CoveragePeriodSegment> _requiredSegments(
  List<CoverageTimelinePoint> points,
  int color,
) {
  if (points.isEmpty) return [];

  final segments = <CoveragePeriodSegment>[];
  var i = 0;
  while (i < points.length) {
    var j = i;
    while (j + 1 < points.length &&
        points[j + 1].requiredAmount == points[i].requiredAmount) {
      j++;
    }
    final endAge = j + 1 < points.length ? points[j + 1].age : points[j].age;
    segments.add(
      CoveragePeriodSegment(
        categoryLabel: '必要保障額',
        amountMan: points[i].requiredAmount,
        startAge: points[i].age,
        endAge: endAge,
        colorValue: color,
      ),
    );
    i = j + 1;
  }
  return segments;
}

List<CoveragePeriodSegment> _incomeProtectionSegments(
  DiagnosisInput input,
  int endAge,
) {
  final incomeEndAge = min(
    input.age + input.incomeProtectionYears,
    endAge,
  );
  if (incomeEndAge <= input.age) return [];

  final checkpoints = timelineAges(input.age)
      .where((a) => a <= incomeEndAge)
      .toList();
  if (checkpoints.isEmpty) {
    checkpoints.add(input.age);
  }
  if (checkpoints.last < incomeEndAge) {
    checkpoints.add(incomeEndAge);
  }

  final segments = <CoveragePeriodSegment>[];
  var i = 0;
  while (i < checkpoints.length - 1) {
    final amount = calcCoverageBreakdownAtAge(input, checkpoints[i]).incomeProtection;
    var j = i;
    while (j + 1 < checkpoints.length) {
      final nextAmount =
          calcCoverageBreakdownAtAge(input, checkpoints[j + 1]).incomeProtection;
      if (nextAmount != amount) break;
      j++;
    }
    if (amount > 0) {
      segments.add(
        CoveragePeriodSegment(
          categoryLabel: '収入保障',
          amountMan: amount,
          startAge: checkpoints[i],
          endAge: checkpoints[j + 1],
          colorValue: 0xFF7B1FA2,
        ),
      );
    }
    i = j + 1;
  }
  return segments;
}
