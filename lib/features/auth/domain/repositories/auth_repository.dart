import 'package:dartz/dartz.dart';
import 'package:church_managment_system/core/error/failures.dart';
import 'package:church_managment_system/shared/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> register(String email, String password, UserRole role);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
