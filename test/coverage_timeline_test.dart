import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/enums/housing_type.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';
import 'package:hoshou_shindan_app/data/models/diagnosis_input.dart';
import 'package:hoshou_shindan_app/domain/calculation/coverage_timeline.dart';

DiagnosisInput _sampleInput() {
  return DiagnosisInput(
    id: 'timeline-test',
    createdAt: DateTime(2026, 6, 27),
    age: 35,
    hasSpouse: true,
    spouseAge: 33,
    childrenAges: const [3],
    schoolType: EducationPolicy.publicAll.index,
    annualIncome: 600,
    spouseIncome: 200,
    monthlyExpense: 25,
    housingType: HousingType.mortgaged.index,
    mortgageBalance: 3000,
    lifeInsurance: 500,
    termInsurance: 1000,
    termInsuranceEndAge: 60,
  );
}

void main() {
  test('5歳刻みで現在年齢から65歳まで生成される', () {
    expect(timelineAges(35), [35, 40, 45, 50, 55, 60, 65]);
    expect(timelineAges(37), [37, 42, 47, 52, 57, 62, 65]);
  });

  test('必要保障額は子どもの成長とともに逓減する', () {
    final points = calcCoverageTimeline(_sampleInput());
    expect(points.first.requiredAmount, greaterThan(points.last.requiredAmount));
  });

  test('定期保険終了後は既存保障が減る', () {
    final input = _sampleInput().copyWith(termInsuranceEndAge: 55);
    final at50 = calcLifeAndTermCoverageAtAge(input, 50);
    final at60 = calcLifeAndTermCoverageAtAge(input, 60);
    expect(at50, greaterThan(at60));
    expect(at60, equals(input.lifeInsurance));
  });

  test('収入保障は年数経過で積み上げが減る', () {
    final input = _sampleInput().copyWith(
      incomeProtectionMonthly: 10,
      incomeProtectionYears: 20,
    );
    final now = calcCoverageBreakdownAtAge(input, 35);
    final later = calcCoverageBreakdownAtAge(input, 50);
    expect(now.incomeProtection, greaterThan(later.incomeProtection));
  });

  test('内訳合計がタイムラインの既存保障と一致', () {
    final points = calcCoverageTimeline(_sampleInput());
    for (final point in points) {
      expect(point.existingCoverage, equals(point.breakdown.total));
    }
  });

  test('区間グラフに金額と年齢が含まれる', () {
    final chart = calcCoveragePeriodChart(_sampleInput());
    expect(chart.rows, isNotEmpty);
    expect(chart.summaryLines, isNotEmpty);
    final termRow = chart.rows.firstWhere((r) => r.title == '定期保険');
    expect(termRow.segments.first.amountMan, 1000);
    expect(termRow.segments.first.ageRangeLabel, contains('歳'));
    expect(chart.summaryLines.first, contains('万'));
  });
}
