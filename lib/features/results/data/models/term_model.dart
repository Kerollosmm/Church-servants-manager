import 'package:hive/hive.dart';

part 'term_model.g.dart';

@HiveType(typeId: 20)
class TermModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;

  TermModel({required this.id, required this.name});

  factory TermModel.fromMap(Map<String, dynamic> map, String id) {
    return TermModel(id: id, name: map['name'] as String);
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
