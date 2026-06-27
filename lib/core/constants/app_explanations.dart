import '../../data/models/diagnosis_input.dart';
import '../../domain/calculation/old_age_pension_calculator.dart';
import '../constants/pension_constants.dart';

/// アプリ内で使う説明文（日本語）を一箇所に集約
abstract final class AppExplanations {
  /// 万一の保障試算（遺族年金）の概要
  static String survivorDiagnosisLead(DiagnosisInput input) {
    if (!input.hasSpouse && input.childrenAges.isNotEmpty) {
      return 'この試算は「あなたが万一の際に亡くなった場合」、'
          'お子さんとあなたの遺族年金・既存保障で足りるかを調べます。'
          'ひとり親世帯では、遺族基礎年金（お子さんがいる期間）と'
          '遺族厚生年金（会社員の場合）が中心になります。';
    }
    return 'この試算は「あなたが万一の際に亡くなった場合」、'
        '残された家族の生活費・教育費・住居費などに対し、'
        '遺族年金・配偶者の就労・既存保障でどこまで賄えるかを調べます。';
  }

  static List<String> survivorDiagnosisBullets(DiagnosisInput input) {
    final bullets = <String>[
      '65歳前の不足 ＝（必要月額 − 遺族年金 − 配偶者就労）× 年数',
      '65歳以降の不足 ＝（老後生活費 − 公的年金）× 年数 ※就労は見込まない',
      '教育費・住居費・葬儀等300万円は別枠で加算します',
      '不足額 ＝ 必要保障額合計 − 既存保障（生命保険・貯蓄等）',
    ];
    if (!input.hasSpouse && input.childrenAges.isNotEmpty) {
      bullets.add(
        'ひとり親世帯：配偶者就労は試算に含めません。'
        'お子さんの進路により卒業年齢は18・20・22歳で異なります',
      );
    }
    return bullets;
  }

  /// 老齢年金（健在前提）の概要
  static String oldAgePensionLead(DiagnosisInput input) {
    if (!input.hasSpouse && input.childrenAges.isNotEmpty) {
      return '【老後収入の目安】万一の試算とは別枠です。'
          'あなた自身が${retirementStartAge}歳まで健在な場合に受け取れる'
          '老齢基礎年金・老齢厚生年金の概算です。'
          'ひとり親世帯でも、あなたの老後生活費との差額確認に使えます。';
    }
    if (!input.hasSpouse) {
      return '【老後収入の目安】万一の試算とは別枠です。'
          '${retirementStartAge}歳からの老齢年金概算と、'
          '老後生活費想定との差額を表示します。';
    }
    return '【老後収入の目安】万一の試算（遺族年金）とは別枠です。'
        '夫婦それぞれが${retirementStartAge}歳まで健在な場合の老齢年金概算と、'
        '老後生活費との差額を表示します。';
  }

  static List<String> oldAgePensionBullets() {
    return [
      '老齢基礎年金：国民年金の加入年数から按分（満額目安 年81万円）',
      '老齢厚生年金：正社員・パートのみ。年収と勤続年数から概算',
      '自営業・無職：老齢厚生は0、老齢基礎のみの試算',
      '繰上げ・繰下げ（60〜75歳）は未反映。原則${retirementStartAge}歳開始',
      '実際の額は年金定期便・ねんきんネットでご確認ください',
    ];
  }

  static String retirementGapExplanation(RetirementPensionGap gap) {
    if (gap.hasShortfall) {
      if (gap.isSingleParent) {
        return '老後生活費 ${gap.needMonthlyMan}万円/月に対し、'
            '老齢年金合計 約${gap.pensionMonthlyMan}万円/月。'
            '毎月 約${gap.gapMonthlyMan}万円不足する試算です。'
            'この不足に加え、万一の際のお子さんの生活費・教育費は'
            '生命保険等で別途備える必要があります。';
      }
      return '老後生活費 ${gap.needMonthlyMan}万円/月に対し、'
          '老齢年金合計 約${gap.pensionMonthlyMan}万円/月。'
          '毎月 約${gap.gapMonthlyMan}万円不足する試算です（${gap.householdLabel}）。';
    }
    return '老後生活費 ${gap.needMonthlyMan}万円/月に対し、'
        '老齢年金合計 約${gap.pensionMonthlyMan}万円/月。'
        '公的年金だけで概ね足りる試算です（${gap.householdLabel}）。';
  }

  /// 進路別の卒業・自立年齢
  static List<String> educationGraduationBullets() {
    return [
      '高卒就職：18歳で卒業・自立',
      '専門学校（2年）：20歳で卒業',
      '大学（4年）：22歳で卒業',
      'Step1で「子ごとに個別設定」を選ぶと、お子さんごとに進路を指定できます',
      '進路が違えば教育費・保障が必要な年数も変わります',
    ];
  }

  /// 保障期間と進路グラフ
  static String familyTimelineLead(DiagnosisInput input) {
    if (!input.hasSpouse && input.childrenAges.isNotEmpty) {
      return '横軸はあなたの年齢です。'
          '定期保険の残り期間・推奨保障期間・'
          'お子さんごとの卒業タイミングを重ねて表示します。'
          'ひとり親世帯では、最も遅い卒業年齢まで保障が必要になることが多いです。';
    }
    if (input.childrenAges.isEmpty) {
      return '横軸はあなたの年齢です。'
          '定期保険と推奨保障期間、'
          '配偶者が${retirementStartAge}歳になるタイミングを表示します。';
    }
    return '横軸はあなたの年齢です。'
        '定期保険・推奨保障期間・お子さんごとの卒業（進路別）・'
        '配偶者${retirementStartAge}歳を重ねて表示します。';
  }

  static List<String> familyTimelineBullets(DiagnosisInput input) {
    final bullets = <String>[
      '緑のバー：定期保険（入力した保障終了年齢まで）',
      '青のバー：推奨保障期間（卒業・配偶者65歳等の最長期間）',
      '橙など：お子さんごとの卒業年齢（進路により18・20・22歳）',
    ];
    if (input.hasSpouse) {
      bullets.add('紫のバー：配偶者が${retirementStartAge}歳になるタイミング');
    }
    bullets.add('定期保険が推奨期間より短い場合は、満了後に不足が広がる可能性があります');
    return bullets;
  }

  /// 保障額の推移グラフ
  static String coverageTimelineLead(int currentAge) {
    return 'あなた${currentAge}歳から${retirementStartAge}歳まで、'
        '5歳刻みで必要保障額と既存保障（生保＋定期）を試算したグラフです。'
        '子どもの成長・ローン残債の減少・定期保険満了により、'
        '必要額と不足のバランスが変わります。';
  }

  static List<String> coverageTimelineBullets() {
    return [
      '青：必要保障額（教育費・住居費の減少等で逓減）',
      '緑：既存保障（終身保険＋定期保険。満了後は減少）',
      '赤線：不足額（必要 − 既存）の推移',
      '${retirementStartAge}歳以降は死亡保障より医療保障（がん・入院・介護）の見直しが重要',
    ];
  }

  /// Step2「計算の前提」カード
  static List<String> step2PremiseBullets(DiagnosisInput input) {
    final bullets = <String>[
      '【万一の試算】65歳前：遺族年金＋配偶者就労を生活費から差し引き',
      '【万一の試算】65歳以降：公的年金のみ差し引き（就労は見込まない）',
      '【老後の目安】${retirementStartAge}歳からの老齢年金と老後生活費の差額も表示',
      '教育費・家賃・葬儀費は別枠。進路により卒業は18・20・22歳',
      '結果画面「計算の考え方」「保障期間と進路グラフ」で詳細を確認',
    ];
    if (!input.hasSpouse && input.childrenAges.isNotEmpty) {
      bullets.insert(
        1,
        'ひとり親世帯：配偶者就労は含めず、あなたの老後収入も別途表示',
      );
    }
    return bullets;
  }

  /// PDF用の説明まとめ
  static List<String> pdfGuideLines(DiagnosisInput input) {
    return [
      survivorDiagnosisLead(input),
      ...survivorDiagnosisBullets(input).map((b) => '・$b'),
      oldAgePensionLead(input),
      retirementGapExplanation(calcRetirementPensionGap(input)),
      familyTimelineLead(input),
      ...educationGraduationBullets().map((b) => '・$b'),
    ];
  }

  static String retirementExpenseFieldHelper(DiagnosisInput input) {
    if (!input.hasSpouse) {
      return 'あなたが${retirementStartAge}歳以降に必要とする月額生活費。'
          '老齢年金概算との差額計算に使います。';
    }
    return '配偶者が${retirementStartAge}歳以降の月額生活費。'
        '老齢基礎年金・老齢/遺族厚生を差し引きます（就労は見込みません）。';
  }
}
