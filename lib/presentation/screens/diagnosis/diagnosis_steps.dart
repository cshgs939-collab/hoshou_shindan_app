import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/pension_constants.dart';
import '../../../core/utils/employment_advice.dart';
import '../../../core/utils/employment_labels.dart';
import '../../../core/enums/housing_type.dart';
import '../../../core/enums/pension_mode.dart';
import '../../../core/enums/school_type.dart';
import '../../../domain/scenario/scenario_comparison.dart';
import '../../../domain/validation/diagnosis_input_validator.dart';
import '../../providers/diagnosis_input_provider.dart';
import '../../widgets/number_input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/employment_advice_panel.dart';
import '../../widgets/existing_insurance_guide.dart';
import '../../widgets/insurance_period_panel.dart';
import '../../widgets/step_progress_bar.dart';
import '../guide/sample_guide_screen.dart';

class Step1Screen extends ConsumerWidget {
  const Step1Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(diagnosisInputProvider);
    final notifier = ref.read(diagnosisInputProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('基本情報')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StepProgressBar(currentStep: 0, totalSteps: 3),
          const SampleModeBanner(),
          const SizedBox(height: 24),
          AgeSliderField(
            label: 'あなたの年齢',
            value: input.age,
            onChanged: notifier.updateAge,
          ),
          const SizedBox(height: 24),
          Text('あなたの就業状況',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            insuredEmploymentIntro(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: input.insuredWorkType.index,
            onChanged: (value) {
              if (value != null) notifier.updateInsuredWorkType(value);
            },
            child: Column(
              children: SpouseEmploymentType.values
                  .map(
                    (type) => RadioListTile<int>(
                      title: Text(employmentTypeLabel(type)),
                      value: type.index,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          EmploymentAdvicePanel(input: input),
          const SizedBox(height: 24),
          Text('配偶者はいますか？',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('あり')),
              ButtonSegment(value: false, label: Text('なし')),
            ],
            selected: {input.hasSpouse},
            onSelectionChanged: (value) =>
                notifier.updateHasSpouse(value.first),
          ),
          if (input.hasSpouse) ...[
            const SizedBox(height: 24),
            AgeSliderField(
              label: '配偶者の年齢',
              value: input.spouseAge ?? 33,
              onChanged: notifier.updateSpouseAge,
            ),
            const SizedBox(height: 24),
            Text('配偶者の就業状況（現在）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              spouseEmploymentIntro(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: input.spouseEmploymentType,
              onChanged: (value) {
                if (value != null) notifier.updateSpouseEmployment(value);
              },
              child: Column(
                children: SpouseEmploymentType.values
                    .map(
                      (type) => RadioListTile<int>(
                        title: Text(employmentTypeLabel(type)),
                        value: type.index,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SpouseEmploymentAdvicePanel(input: input),
          ],
          const SizedBox(height: 24),
          Text('お子さんの人数',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: input.childrenAges.isNotEmpty
                    ? () => notifier
                        .updateChildrenCount(input.childrenAges.length - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: Center(
                  child: Text('${input.childrenAges.length}人',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
              IconButton.filledTonal(
                onPressed: input.childrenAges.length < 6
                    ? () => notifier
                        .updateChildrenCount(input.childrenAges.length + 1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (input.childrenAges.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('お子さんの年齢',
                style: Theme.of(context).textTheme.titleMedium),
            ...List.generate(input.childrenAges.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AgeSliderField(
                  label: '${index + 1}人目',
                  value: input.childrenAges[index],
                  min: 0,
                  max: 22,
                  onChanged: (age) => notifier.updateChildAge(index, age),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text('教育方針',
                style: Theme.of(context).textTheme.titleMedium),
            RadioGroup<int>(
              groupValue: input.schoolType,
              onChanged: (value) {
                if (value != null) notifier.updateEducationPolicy(value);
              },
              child: Column(
                children: EducationPolicy.values
                    .map(
                      (policy) => RadioListTile<int>(
                        title: Text(_educationLabel(policy)),
                        value: policy.index,
                      ),
                    )
                    .toList(),
              ),
            ),
            if (input.educationPolicy == EducationPolicy.custom) ...[
              const SizedBox(height: 8),
              Text('お子さんごとの進路',
                  style: Theme.of(context).textTheme.titleMedium),
              ...List.generate(input.childrenAges.length, (index) {
                final selected = input.educationPolicyForChild(index);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '${index + 1}人目',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selected.index,
                        items: ScenarioComparisonService.comparablePolicies
                            .map(
                              (policy) => DropdownMenuItem(
                                value: policy.index,
                                child: Text(_educationLabel(policy)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            notifier.updateChildSchoolPolicy(index, value);
                          }
                        },
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            label: '次へ →',
            enabled: DiagnosisInputValidator.isStep1Valid(input),
            onPressed: () => context.push('/diagnosis/step2'),
          ),
        ],
      ),
    );
  }

  String _educationLabel(EducationPolicy policy) {
    switch (policy) {
      case EducationPolicy.publicAll:
        return 'すべて公立';
      case EducationPolicy.privateAll:
        return 'すべて私立';
      case EducationPolicy.publicToPrivate:
        return '高校まで公立、大学私立';
      case EducationPolicy.custom:
        return '子ごとに個別設定';
    }
  }
}

class Step2Screen extends ConsumerWidget {
  const Step2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(diagnosisInputProvider);
    final notifier = ref.read(diagnosisInputProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('収入・支出')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StepProgressBar(currentStep: 1, totalSteps: 3),
          const SampleModeBanner(),
          const SizedBox(height: 24),
          NumberInputField(
            label: 'あなたの年収（税込）',
            value: input.annualIncome > 0 ? input.annualIncome : null,
            onChanged: (v) => notifier.updateAnnualIncome(v ?? 0),
            helper: '※ 源泉徴収票の「支払金額」。公的年金で補えない収入分を試算します',
          ),
          if (input.annualIncome > 0) ...[
            const SizedBox(height: 12),
            EmploymentAdvicePanel(
              input: input,
              showIncomeBreakdown: true,
            ),
          ],
          const SizedBox(height: 20),
          if (input.hasSpouse)
            NumberInputField(
              label: '配偶者の年収（税込）',
              value: input.spouseIncome,
              onChanged: (v) => notifier.updateSpouseIncome(v ?? 0),
              helper: '現在の収入。死亡後は就労増を前提に不足額を計算します。',
            ),
          if (input.hasSpouse) const SizedBox(height: 20),
          NumberInputField(
            label: '月間の生活費',
            value: input.monthlyExpense > 0 ? input.monthlyExpense : null,
            suffix: '万円/月',
            onChanged: (v) => notifier.updateMonthlyExpense(v ?? 0),
            helper: '食費・光熱費等の総額。賃貸の場合は家賃を除いて入力してください。',
          ),
          const SizedBox(height: 20),
          Text('住居の状況', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('持家(ローン)')),
              ButtonSegment(value: 1, label: Text('持家(完済)')),
              ButtonSegment(value: 2, label: Text('賃貸')),
            ],
            selected: {input.housingType},
            onSelectionChanged: (value) =>
                notifier.updateHousingType(value.first),
          ),
          if (input.residenceType == HousingType.mortgaged) ...[
            const SizedBox(height: 20),
            NumberInputField(
              label: '住宅ローン残債',
              value: input.mortgageBalance,
              onChanged: notifier.updateMortgageBalance,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('団体信用生命保険（団信）に加入'),
              subtitle: const Text(
                '加入していれば、死亡時にローン残債は免除され住居費に含めません',
              ),
              value: input.hasGroupCreditLifeInsurance,
              onChanged: notifier.updateHasGroupCreditLifeInsurance,
            ),
          ],
          if (input.residenceType == HousingType.renting) ...[
            const SizedBox(height: 20),
            NumberInputField(
              label: '月額家賃',
              value: input.monthlyRent,
              suffix: '万円/月',
              onChanged: notifier.updateMonthlyRent,
            ),
          ],
          const SizedBox(height: 20),
          NumberInputField(
            label: '老後の生活費想定',
            value: input.retirementMonthlyExpense,
            suffix: '万円/月',
            onChanged: (v) =>
                notifier.updateRetirementMonthlyExpense(v ?? 20),
            helper:
                '配偶者が${retirementStartAge}歳以降の月額生活費。'
                '老齢基礎年金・遺族/老齢厚生を差し引きます（就労は見込みません）。',
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(
                  alpha: 0.25,
                ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 計算の前提',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '・65歳前：遺族年金＋配偶者就労を差し引き',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    '・65歳以降：公的年金のみ差し引き（就労は見込まない）',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    '・教育費・家賃・葬儀費は別枠で加算',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Text(
                    '・結果画面「計算の考え方」で詳細を確認できます',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: '次へ →',
            enabled: DiagnosisInputValidator.isStep2Valid(input),
            onPressed: () => context.push('/diagnosis/step3'),
          ),
        ],
      ),
    );
  }
}

class Step3Screen extends ConsumerWidget {
  const Step3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(diagnosisInputProvider);
    final notifier = ref.read(diagnosisInputProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('既存の保障')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const StepProgressBar(currentStep: 2, totalSteps: 3),
          const SampleModeBanner(),
          const SizedBox(height: 16),
          InsurancePeriodPanel(input: input),
          const SizedBox(height: 16),
          const ExistingInsuranceGuide(),
          const SizedBox(height: 24),
          NumberInputField(
            label: '終身・養老保険など（死亡保障・一時金）',
            value: input.lifeInsurance,
            onChanged: (v) => notifier.updateLifeInsurance(v ?? 0),
            helper: '保険証券の「死亡保険金」。満期返戻金は含めません。',
          ),
          const SizedBox(height: 20),
          NumberInputField(
            label: '定期保険（死亡保障・一時金）',
            value: input.termInsurance,
            onChanged: (v) => notifier.updateTermInsurance(v ?? 0),
            helper: '掛け捨て型。契約中に死亡した場合の一時金（万円）。',
          ),
          const SizedBox(height: 12),
          AgeSliderField(
            label: '定期保険の保障終了年齢',
            value: input.termInsuranceEndAge > 0
                ? input.termInsuranceEndAge
                : (input.age + 25).clamp(input.age + 1, 80),
            min: input.age + 1,
            max: 80,
            valueSuffix: '歳まで',
            helper: input.termInsuranceEndAge <= 0
                ? '証券の「保険期間満了日」の年齢。スライダーで設定してください'
                : '残り約 ${input.termInsuranceEndAge - input.age} 年の保障',
            onChanged: notifier.updateTermInsuranceEndAge,
          ),
          const SizedBox(height: 20),
          NumberInputField(
            label: '収入保障保険（月額受取）',
            value: input.incomeProtectionMonthly,
            suffix: '万円/月',
            onChanged: (v) => notifier.updateIncomeProtectionMonthly(v ?? 0),
            helper: '死亡後、毎月いくら受け取れるか。'
                '例：月10万円 × 20年 → 2400万円相当',
          ),
          const SizedBox(height: 12),
          AgeSliderField(
            label: '収入保障保険（受取年数）',
            value: input.incomeProtectionYears.clamp(0, 40),
            min: 0,
            max: 40,
            valueSuffix: '年',
            helper: '上の月額を、何年間もらえるか。0年＝収入保障なし',
            onChanged: notifier.updateIncomeProtectionYears,
          ),
          const SizedBox(height: 20),
          NumberInputField(
            label: '退職金の概算',
            value: input.retirementPay,
            onChanged: (v) => notifier.updateRetirementPay(v ?? 0),
          ),
          const SizedBox(height: 20),
          NumberInputField(
            label: '貯蓄・金融資産（概算）',
            value: input.financialAssets,
            onChanged: (v) => notifier.updateFinancialAssets(v ?? 0),
          ),
          const SizedBox(height: 20),
          Text('遺族年金', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('自動で概算')),
              ButtonSegment(value: 1, label: Text('金額を入力')),
            ],
            selected: {input.pensionMode},
            onSelectionChanged: (value) =>
                notifier.updatePensionMode(value.first),
          ),
          if (input.survivorPensionMode == SurvivorPensionMode.auto) ...[
            const SizedBox(height: 16),
            AgeSliderField(
              label: '厚生年金の勤続年数（あなた）',
              value: input.workingYears ?? 20,
              min: 1,
              max: 50,
              valueSuffix: '年',
              helper:
                  '会社等に加入していた年数です。'
                  '遺族年金の「金額」を概算するための入力で、'
                  'もらう年数（受取期間）は別途自動計算されます。',
              onChanged: notifier.updateWorkingYears,
            ),
          ] else ...[
            const SizedBox(height: 16),
            NumberInputField(
              label: '遺族年金（年額）',
              value: input.manualPensionAnnual,
              suffix: '万円/年',
              onChanged: notifier.updateManualPensionAnnual,
            ),
          ],
          const SizedBox(height: 32),
          PrimaryButton(
            label: '計算する →',
            enabled: DiagnosisInputValidator.isStep3Valid(input),
            onPressed: () => context.push('/diagnosis/calculating'),
          ),
        ],
      ),
    );
  }
}
