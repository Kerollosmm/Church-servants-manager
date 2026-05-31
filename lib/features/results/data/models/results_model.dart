import 'package:church_management_system/features/results/domain/entities/result.dart';
import 'package:hive/hive.dart';

part 'results_model.g.dart';

@HiveType(typeId: 21)
class ResultsModel {
  @HiveField(0)
  final String studentId;
  @HiveField(1)
  final String termId;
  @HiveField(2)
  final double score;
  @HiveField(3)
  final String? notes;
  @HiveField(4)
  final String groupId;

  ResultsModel({
    required this.studentId,
    required this.termId,
    required this.score,
    this.notes,
    required this.groupId,
  });

  factory ResultsModel.fromMap(Map<String, dynamic> map, String id) {
    return ResultsModel(
      studentId: map['studentId'] as String,
      termId: map['termId'] as String,
      score: (map['score'] as num).toDouble(),
      notes: map['notes'] as String?,
      groupId: map['groupId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'termId': termId,
      'score': score,
      'notes': notes,
      'groupId': groupId,
    };
  }

  Result toDomain() {
    return Result(
      studentId: studentId,
      termId: termId,
      score: score,
      notes: notes,
      groupId: groupId,
    );
  }

  factory ResultsModel.fromDomain(Result result) {
    return ResultsModel(
      studentId: result.studentId,
      termId: result.termId,
      score: result.score,
      notes: result.notes,
      groupId: result.groupId,
    );
  }
}
