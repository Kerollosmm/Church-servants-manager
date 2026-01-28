import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:csms/core/constants/enums.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    required String name,
    required String email,
    @Default(UserRole.student) UserRole role,
    String? grade,
    String? linkedStudentId,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
