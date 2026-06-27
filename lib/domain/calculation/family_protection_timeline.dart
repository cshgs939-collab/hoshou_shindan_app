import 'dart:math';

import '../../core/constants/app_explanations.dart';
import '../../core/constants/education_costs.dart';
import '../../core/constants/pension_constants.dart';
import '../../core/enums/school_type.dart';
import '../../data/models/diagnosis_input.dart';
import 'insurance_period.dart';
import 'survivor_pension_calculator.dart';

class ChildGraduationMilestone {
  const ChildGraduationMilestone({
    required this.childNumber,
    required this.currentAge,
    required this.policy,
    required this.graduationAge,
    required this.yearsUntilGraduation,
    required this.insuredAgeWhenGraduates,
    required this.pathLabel,
  });

  final int childNumber;
  final int currentAge;
  final EducationPolicy policy;
  final int graduationAge;
  final int yearsUntilGraduation;
  final int insuredAgeWhenGraduates;
  final String pathLabel;
}

class TimelineSpan {
  const TimelineSpan({
    required this.label,
    required this.startInsuredAge,
    required this.endInsuredAge,
    required this.colorValue,
  });

  final String label;
  final int startInsuredAge;
  final int endInsuredAge;
  final int colorValue;

  int get durationYears => max(0, endInsuredAge - startInsuredAge);
}

class FamilyProtectionTimeline {
  const FamilyProtectionTimeline({
    required this.insuredAge,
    required this.timelineEndAge,
    required this.recommendedYears,
    required this.insuredAgeAtRecommendedEnd,
    required this.children,
    this.termInsuranceEndAge,
    this.termRemainingYears,
    this.insuredAgeAtSpouse65,
    this.hasSpouse = false,
  });

  final int insuredAge;
  final int timelineEndAge;
  final int recommendedYears;
  final int insuredAgeAtRecommendedEnd;
  final int? termInsuranceEndAge;
  final int? termRemainingYears;
  final int? insuredAgeAtSpouse65;
  final bool hasSpouse;
  final List<ChildGraduationMilestone> children;

  int get timelineSpanYears => max(1, timelineEndAge - insuredAge);

  List<TimelineSpan> get spans {
    final items = <TimelineSpan>[];

    if (termInsuranceEndAge != null &&
        termInsuranceEndAge! > insuredAge &&
        termRemainingYears != null) {
      items.add(
        TimelineSpan(
          label: '定期保険（${termInsuranceEndAge}歳まで）',
          startInsuredAge: insuredAge,
          endInsuredAge: termInsuranceEndAge!,
          colorValue: 0xFF43A047,
        ),
      );
    }

    items.add(
      TimelineSpan(
        label: '推奨保障期間（約${recommendedYears}年）',
        startInsuredAge: insuredAge,
        endInsuredAge: insuredAgeAtRecommendedEnd,
        colorValue: 0xFF1565C0,
      ),
    );

    for (final child in children) {
      items.add(
        TimelineSpan(
          label: '${child.childNumber}人目 ${child.pathLabel}',
          startInsuredAge: insuredAge,
          endInsuredAge: child.insuredAgeWhenGraduates,
          colorValue: _childColor(child.childNumber),
        ),
      );
    }

    if (insuredAgeAtSpouse65 != null && insuredAgeAtSpouse65! > insuredAge) {
      items.add(
        TimelineSpan(
          label: '配偶者${retirementStartAge}歳',
          startInsuredAge: insuredAge,
          endInsuredAge: insuredAgeAtSpouse65!,
          colorValue: 0xFF7B1FA2,
        ),
      );
    }

    return items;
  }
}

int _childColor(int childNumber) {
  return switch (childNumber) {
    1 => 0xFFEF6C00,
    2 => 0xFF00838F,
    3 => 0xFF6A1B9A,
    _ => 0xFF546E7A,
  };
}

FamilyProtectionTimeline buildFamilyProtectionTimeline(DiagnosisInput input) {
  final period = InsurancePeriodSummary.from(input);
  final insuredAge = input.age;

  final children = <ChildGraduationMilestone>[];
  for (var i = 0; i < input.childrenAges.length; i++) {
    final childAge = input.childrenAges[i];
    final policy = input.educationPolicyForChild(i);
    final graduationAge = graduationAgeForPolicy(policy);
    if (childAge >= graduationAge) continue;

    final yearsUntil = graduationAge - childAge;
    children.add(
      ChildGraduationMilestone(
        childNumber: i + 1,
        currentAge: childAge,
        policy: policy,
        graduationAge: graduationAge,
        yearsUntilGraduation: yearsUntil,
        insuredAgeWhenGraduates: insuredAge + yearsUntil,
        pathLabel: graduationMilestoneLabel(policy),
      ),
    );
  }

  final insuredAgeAtRecommendedEnd = insuredAge + period.recommendedYears;
  final insuredAgeAtSpouse65 = input.hasSpouse && input.spouseAge != null
      ? insuredAge + calcSurvivorWorkYears(input)
      : null;

  final endCandidates = <int>[
    insuredAgeAtRecommendedEnd,
    if (period.termInsuranceEndAge != null) period.termInsuranceEndAge!,
    ...children.map((c) => c.insuredAgeWhenGraduates),
    if (insuredAgeAtSpouse65 != null) insuredAgeAtSpouse65,
  ];

  return FamilyProtectionTimeline(
    insuredAge: insuredAge,
    timelineEndAge: endCandidates.reduce(max),
    recommendedYears: period.recommendedYears,
    insuredAgeAtRecommendedEnd: insuredAgeAtRecommendedEnd,
    termInsuranceEndAge: period.termInsuranceEndAge,
    termRemainingYears: period.termRemainingYears,
    insuredAgeAtSpouse65:
        insuredAgeAtSpouse65 != null && insuredAgeAtSpouse65 > insuredAge
            ? insuredAgeAtSpouse65
            : null,
    hasSpouse: input.hasSpouse,
    children: children,
  );
}

String familyTimelineIntro(DiagnosisInput input) =>
    AppExplanations.familyTimelineLead(input);
