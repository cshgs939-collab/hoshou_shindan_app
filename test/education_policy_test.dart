import 'package:flutter_test/flutter_test.dart';
import 'package:hoshou_shindan_app/core/constants/education_costs.dart';
import 'package:hoshou_shindan_app/core/enums/school_type.dart';

void main() {
  group('拡張教育方針', () {
    test('高卒就職は大学費用を含まない', () {
      final fee = calcEducationFee(3, EducationPolicy.noHigherEd);
      final publicAllFee = calcEducationFee(3, EducationPolicy.publicAll);
      expect(fee, greaterThan(0));
      expect(fee, lessThan(publicAllFee));
    });

    test('専門学校は大学より低く高卒より高い', () {
      final vocationalFee = calcEducationFee(3, EducationPolicy.vocational);
      final noHigherEdFee = calcEducationFee(3, EducationPolicy.noHigherEd);
      final nationalFee = calcEducationFee(3, EducationPolicy.university4);
      expect(vocationalFee, greaterThan(noHigherEdFee));
      expect(vocationalFee, lessThan(nationalFee));
    });

    test('私立理系大学は文系より高い', () {
      final libFee = calcEducationFee(3, EducationPolicy.universityPrivate);
      final sciFee = calcEducationFee(3, EducationPolicy.universityScience);
      expect(sciFee, greaterThan(libFee));
    });

    test('22歳は教育費0', () {
      expect(calcEducationFee(22, EducationPolicy.vocational), equals(0));
    });
  });
}
