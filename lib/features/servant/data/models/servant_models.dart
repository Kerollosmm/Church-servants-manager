import 'package:freezed_annotation/freezed_annotation.dart';

part 'servant_models.freezed.dart';
part 'servant_models.g.dart';

// ignore_for_file: invalid_annotation_target

@freezed
class ServantModel with _$ServantModel {
  const factory ServantModel({
    required String id,
    required String name,
    required String phone,
    required String email,
    required String image,
    @JsonKey(name: 'team_name') required String teamName,
    required String role,
  }) = _ServantModel;

  factory ServantModel.fromJson(Map<String, dynamic> json) =>
      _$ServantModelFromJson(json);
}
