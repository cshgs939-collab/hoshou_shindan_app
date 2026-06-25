import '../../core/enums/school_type.dart';
import '../../data/models/diagnosis_input.dart';
import '../../data/models/diagnosis_result.dart';
import '../calculation/calculation_engine.dart';

class EducationScenario {
  const EducationScenario({
    required this.policy,
    required this.result,
  });

  final EducationPolicy policy;
  final DiagnosisResult result;

  String get label => switch (policy) {
        EducationPolicy.publicAll => 'すべて公立',
        EducationPolicy.privateAll => 'すべて私立',
        EducationPolicy.publicToPrivate => '高校まで公立・大学私立',
        EducationPolicy.custom => '個別設定',
      };
}

class ScenarioComparisonService {
  const ScenarioComparisonService(this._engine);

  final CalculationEngine _engine;

  static const comparablePolicies = [
    EducationPolicy.publicAll,
    EducationPolicy.privateAll,
    EducationPolicy.publicToPrivate,
  ];

  List<EducationScenario> compare(DiagnosisInput baseInput) {
    return comparablePolicies.map((policy) {
      final input = baseInput.copyWith(schoolType: policy.index);
      final result = _engine.calculate(input);
      return EducationScenario(policy: policy, result: result);
    }).toList();
  }

  EducationScenario? lowestGapScenario(List<EducationScenario> scenarios) {
    if (scenarios.isEmpty) return null;
    return scenarios.reduce(
      (best, current) => current.result.gap < best.result.gap ? current : best,
    );
  }
}
