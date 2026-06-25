import '../enums/pension_mode.dart';

String employmentTypeLabel(SpouseEmploymentType type) {
  switch (type) {
    case SpouseEmploymentType.fullTime:
      return '正社員・会社員';
    case SpouseEmploymentType.partTime:
      return 'パート・アルバイト';
    case SpouseEmploymentType.unemployed:
      return '無職・専業主婦(夫)';
    case SpouseEmploymentType.selfEmployed:
      return '自営業';
  }
}

String insuredPensionHelper(SpouseEmploymentType type) {
  switch (type) {
    case SpouseEmploymentType.fullTime:
    case SpouseEmploymentType.partTime:
      return '遺族基礎年金＋遺族厚生年金を概算（厚生年金加入）';
    case SpouseEmploymentType.selfEmployed:
      return '国民年金のみ → 遺族基礎年金（子あり）のみ概算';
    case SpouseEmploymentType.unemployed:
      return '厚生年金なし → 遺族基礎年金（子あり）のみ概算';
  }
}

bool insuredWorkTypeHasKousei(SpouseEmploymentType type) {
  switch (type) {
    case SpouseEmploymentType.fullTime:
    case SpouseEmploymentType.partTime:
      return true;
    case SpouseEmploymentType.unemployed:
    case SpouseEmploymentType.selfEmployed:
      return false;
  }
}
