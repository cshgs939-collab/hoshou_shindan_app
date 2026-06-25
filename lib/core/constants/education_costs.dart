import '../enums/school_type.dart';

enum SchoolStage {
  kindergarten,
  elementary,
  juniorHigh,
  highSchool,
  university,
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
  },
  SchoolStage.elementary: {
    SchoolType.public: 35,
    SchoolType.private: 167,
    SchoolType.national: 35,
    SchoolType.privateLib: 167,
    SchoolType.privateSci: 167,
  },
  SchoolStage.juniorHigh: {
    SchoolType.public: 54,
    SchoolType.private: 144,
    SchoolType.national: 54,
    SchoolType.privateLib: 144,
    SchoolType.privateSci: 144,
  },
  SchoolStage.highSchool: {
    SchoolType.public: 51,
    SchoolType.private: 105,
    SchoolType.national: 51,
    SchoolType.privateLib: 105,
    SchoolType.privateSci: 105,
  },
  SchoolStage.university: {
    SchoolType.public: 64,
    SchoolType.private: 100,
    SchoolType.national: 64,
    SchoolType.privateLib: 100,
    SchoolType.privateSci: 136,
  },
};

SchoolType resolveSchoolType(EducationPolicy policy) {
  switch (policy) {
    case EducationPolicy.publicAll:
      return SchoolType.public;
    case EducationPolicy.privateAll:
      return SchoolType.private;
    case EducationPolicy.publicToPrivate:
      return SchoolType.public;
    case EducationPolicy.custom:
      return SchoolType.public;
  }
}

SchoolType resolveUniversityType(EducationPolicy policy) {
  switch (policy) {
    case EducationPolicy.publicAll:
      return SchoolType.national;
    case EducationPolicy.privateAll:
      return SchoolType.privateLib;
    case EducationPolicy.publicToPrivate:
      return SchoolType.privateLib;
    case EducationPolicy.custom:
      return SchoolType.national;
  }
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
  addStage(SchoolStage.university, 18, 22, universityType);

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
