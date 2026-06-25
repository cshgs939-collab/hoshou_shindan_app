/// 公的年金の原則受給開始年齢（老齢基礎・老齢厚生年金）。
/// 60〜75歳の繰上げ・繰下げ選択は別途。遺族年金の生活費区分はこの年齢を基準とする。
const retirementStartAge = 65;

/// 繰下げ受給の上限年齢（2022年4月改正）。
const deferredPensionMaxAge = 75;

/// 遺族基礎年金（令和8年度目安・万円/年）
const survivorBasicPensionAnnual = 85;

/// 子の加算（1・2人目・万円/年）
const survivorChildAdditionFirst = 24;

/// 子の加算（3人目以降・万円/年）
const survivorChildAdditionExtra = 8;

/// 老齢基礎年金・満額（令和8年度目安・万円/年）
const oldAgeBasicPensionFullAnnual = 81;

/// 老齢基礎年金・満額に必要な加入年数
const nationPensionFullYears = 40;

/// 第3号被保険者期間の簡易起算年齢（婚姻〜就労前を含む概算）
const nationPensionCategory3StartAge = 20;

/// 配偶者が専業主婦(夫)の場合に想定する就労年収（万円/年）
const assumedSurvivorWorkIncomeAnnual = 250;

/// パート等から増える就労年収の下限（万円/年）
const minimumSurvivorWorkIncomeAnnual = 200;
