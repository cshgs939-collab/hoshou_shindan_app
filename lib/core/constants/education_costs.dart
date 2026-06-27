import '../enums/school_type.dart';

enum SchoolStage {
  kindergarten,
  elementary,
  juniorHigh,
  highSchool,
  university,
  vocational,
}

class RemainingStage {
  const RemainingStage(this.stage, this.schoolType, this.remainingYears);

  final SchoolStage stage;
  final SchoolType schoolType;
  final int remainingYears;
}

const Map<SchoolStage, Map<SchoolType, int>> educationCostPerYear = {
  SchoolStage.kindergarten: {
    SchoolType.public: 16,
    SchoolType.private: 33,
    SchoolType.national: 16,
    SchoolType.privateLib: 33,
    SchoolType.privateSci: 33,
    SchoolType.vocational: 16,
  },
  SchoolStage.elementary: {
    SchoolType.public: 35,
    SchoolType.private: 167,
    SchoolType.national: 35,
    SchoolType.privateLib: 167,
    SchoolType.privateSci: 167,
    SchoolType.vocational: 35,
  },
  SchoolStage.juniorHigh: {
    SchoolType.public: 54,
    SchoolType.private: 144,
    SchoolType.national: 54,
    SchoolType.privateLib: 144,
    SchoolType.privateSci: 144,
    SchoolType.vocational: 54,
  },
  SchoolStage.highSchool: {
    SchoolType.public: 51,
    SchoolType.private: 105,
    SchoolType.national: 51,
    SchoolType.privateLib: 105,
    SchoolType.privateSci: 105,
    SchoolType.vocational: 51,
  },
  SchoolStage.university: {
    SchoolType.public: 64,
    SchoolType.private: 100,
    SchoolType.national: 64,
    SchoolType.privateLib: 100,
    SchoolType.privateSci: 136,
    SchoolType.vocational: 64,
  },
  SchoolStage.vocational: {
    SchoolType.vocational: 80,
  },
};

bool _usesPublicK12(EducationPolicy policy) {
  return switch (policy) {
    EducationPolicy.privateAll => false,
    _ => true,
  };
}

SchoolType resolveSchoolType(EducationPolicy policy) {
  return _usesPublicK12(policy) ? SchoolType.public : SchoolType.private;
}

SchoolType? resolveUniversityType(EducationPolicy policy) {
  return switch (policy) {
    EducationPolicy.publicAll || EducationPolicy.university4 => SchoolType.national,
    EducationPolicy.privateAll || EducationPolicy.universityPrivate =>
      SchoolType.privateLib,
    EducationPolicy.publicToPrivate => SchoolType.privateLib,
    EducationPolicy.universityScience => SchoolType.privateSci,
    EducationPolicy.noHigherEd || EducationPolicy.vocational => null,
    EducationPolicy.custom => SchoolType.national,
  };
}

List<RemainingStage> getRemainingStages(int childAge, EducationPolicy policy) {
  if (childAge >= 22) return [];

  final stages = <RemainingStage>[];

  void addStage(SchoolStage stage, int startAge, int endAge, SchoolType type) {
    if (childAge >= endAge) return;
    final effectiveStart = childAge < startAge ? startAge : childAge;
    final years = endAge - effectiveStart;
    if (years > 0) {
      stages.add(RemainingStage(stage, type, years));
    }
  }

  final elementaryType = resolveSchoolType(policy);
  final highSchoolType = policy == EducationPolicy.publicToPrivate
      ? SchoolType.public
      : resolveSchoolType(policy);
  final universityType = resolveUniversityType(policy);

  addStage(SchoolStage.kindergarten, 3, 6, elementaryType);
  addStage(SchoolStage.elementary, 6, 12, elementaryType);
  addStage(SchoolStage.juniorHigh, 12, 15, elementaryType);
  addStage(SchoolStage.highSchool, 15, 18, highSchoolType);

  switch (policy) {
    case EducationPolicy.vocational:
      addStage(SchoolStage.vocational, 18, 20, SchoolType.vocational);
    case EducationPolicy.noHigherEd:
      break;
    default:
      if (universityType != null) {
        addStage(SchoolStage.university, 18, 22, universityType);
      }
  }

  return stages;
}

int calcEducationFee(int childAge, EducationPolicy policy) {
  var totalFee = 0;
  for (final stage in getRemainingStages(childAge, policy)) {
    final cost = educationCostPerYear[stage.stage]?[stage.schoolType] ?? 0;
    totalFee += cost * stage.remainingYears;
  }
  return totalFee;
}

/// 進路ごとの「卒業・自立」年齢
int graduationAgeForPolicy(EducationPolicy policy) {
  return switch (policy) {
    EducationPolicy.noHigherEd => 18,
    EducationPolicy.vocational => 20,
    _ => 22,
  };
}

String graduationMilestoneLabel(EducationPolicy policy) {
  final age = graduationAgeForPolicy(policy);
  final path = switch (policy) {
    EducationPolicy.noHigherEd => '高卒就職',
    EducationPolicy.vocational => '専門学校卒',
    EducationPolicy.university4 => '国公立大卒',
    EducationPolicy.universityPrivate => '私立大（文系）卒',
    EducationPolicy.universityScience => '私立大（理系）卒',
    EducationPolicy.publicAll => '公立コース大卒',
    EducationPolicy.privateAll => '私立コース大卒',
    EducationPolicy.publicToPrivate => '大学私立卒',
    EducationPolicy.custom => '進学卒',
  };
  return '$path（${age}歳）';
}
