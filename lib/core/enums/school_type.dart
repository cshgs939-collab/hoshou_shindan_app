enum EducationPolicy {
  publicAll,
  privateAll,
  publicToPrivate,
  custom,
  university4,
  universityPrivate,
  universityScience,
  vocational,
  noHigherEd,
}

/// 世帯全体の教育方針（Step1 ラジオ用）
const householdEducationPolicies = [
  EducationPolicy.publicAll,
  EducationPolicy.privateAll,
  EducationPolicy.publicToPrivate,
  EducationPolicy.custom,
];

/// 子どもごとの進路（custom モードのドロップダウン用）
const childEducationPolicies = [
  EducationPolicy.publicAll,
  EducationPolicy.privateAll,
  EducationPolicy.publicToPrivate,
  EducationPolicy.university4,
  EducationPolicy.universityPrivate,
  EducationPolicy.universityScience,
  EducationPolicy.vocational,
  EducationPolicy.noHigherEd,
];

String educationPolicyLabel(EducationPolicy policy) {
  return switch (policy) {
    EducationPolicy.publicAll => 'すべて公立',
    EducationPolicy.privateAll => 'すべて私立',
    EducationPolicy.publicToPrivate => '高校まで公立、大学私立',
    EducationPolicy.custom => '子ごとに個別設定',
    EducationPolicy.university4 => '4年制大学（国公立）',
    EducationPolicy.universityPrivate => '4年制大学（私立文系）',
    EducationPolicy.universityScience => '4年制大学（私立理系）',
    EducationPolicy.vocational => '専門学校（2年）',
    EducationPolicy.noHigherEd => '高卒就職',
  };
}

enum SchoolType {
  public,
  private,
  national,
  privateLib,
  privateSci,
  vocational,
}
