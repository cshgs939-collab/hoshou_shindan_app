import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/housing_type.dart';
import '../../../core/enums/pension_mode.dart';
import '../../../core/enums/school_type.dart';
import '../../../domain/scenario/scenario_comparison.dart';
import '../../../domain/validation/diagnosis_input_validator.dart';
import '../../providers/diagnosis_input_provider.dart';
import '../../widgets/number_input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/step_progress_bar.dart';

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
          const SizedBox(height: 24),
          AgeSliderField(
            label: 'あなたの年齢',
            value: input.age,
            onChanged: notifier.updateAge,
          ),
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
            Text('配偶者の就業状況',
                style: Theme.of(context).textTheme.titleMedium),
            RadioGroup<int>(
              groupValue: input.spouseEmploymentType,
              onChanged: (value) {
                if (value != null) notifier.updateSpouseEmployment(value);
              },
              child: Column(
                children: SpouseEmploymentType.values
                    .map(
                      (type) => RadioListTile<int>(
                        title: Text(_employmentLabel(type)),
                        value: type.index,
                      ),
                    )
                    .toList(),
              ),
            ),
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

  String _employmentLabel(SpouseEmploymentType type) {
    switch (type) {
      case SpouseEmploymentType.fullTime:
        return '正社員・フルタイム';
      case SpouseEmploymentType.partTime:
        return 'パート・アルバイト';
      case SpouseEmploymentType.unemployed:
        return '専業主婦(夫)';
      case SpouseEmploymentType.selfEmployed:
        return '自営業';
    }
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
          const SizedBox(height: 24),
          NumberInputField(
            label: 'あなたの年収（税込）',
            value: input.annualIncome > 0 ? input.annualIncome : null,
            onChanged: (v) => notifier.updateAnnualIncome(v ?? 0),
            helper: '※ 源泉徴収票の「支払金額」',
          ),
          const SizedBox(height: 20),
          if (input.hasSpouse)
            NumberInputField(
              label: '配偶者の年収（税込）',
              value: input.spouseIncome,
              onChanged: (v) => notifier.updateSpouseIncome(v ?? 0),
            ),
          if (input.hasSpouse) const SizedBox(height: 20),
          NumberInputField(
            label: '月間の生活費',
            value: input.monthlyExpense > 0 ? input.monthlyExpense : null,
            suffix: '万円/月',
            onChanged: (v) => notifier.updateMonthlyExpense(v ?? 0),
            helper: '※ 住居費・保険料込みの総額',
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
          AgeSliderField(
            label: '老後の生活費想定',
            value: input.retirementMonthlyExpense,
            min: 10,
            max: 50,
            onChanged: notifier.updateRetirementMonthlyExpense,
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
          const SizedBox(height: 24),
          NumberInputField(
            label: '現在の死亡保障額（生命保険）',
            value: input.lifeInsurance,
            onChanged: (v) => notifier.updateLifeInsurance(v ?? 0),
            helper: 'ℹ️ 保険証券の「死亡保険金」',
          ),
          const SizedBox(height: 20),
          NumberInputField(
            label: '定期保険の保障額',
            value: input.termInsurance,
            onChanged: (v) => notifier.updateTermInsurance(v ?? 0),
          ),
          const SizedBox(height: 20),
          NumberInputField(
            label: '収入保障保険（月額）',
            value: input.incomeProtectionMonthly,
            suffix: '万円/月',
            onChanged: (v) => notifier.updateIncomeProtectionMonthly(v ?? 0),
          ),
          const SizedBox(height: 12),
          AgeSliderField(
            label: '収入保障保険（保障期間）',
            value: input.incomeProtectionYears.clamp(1, 40),
            min: 1,
            max: 40,
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
              label: '勤続年数',
              value: input.workingYears ?? 20,
              min: 1,
              max: 50,
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
