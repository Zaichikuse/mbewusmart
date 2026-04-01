import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String phoneNumber;
  final String? pin;

  const AuthLoginRequested({
    required this.phoneNumber,
    this.pin,
  });

  @override
  List<Object?> get props => [phoneNumber, pin];
}

class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String phoneNumber;
  final String? nationalId;
  final UserRole role;
  final String? pin;

  const AuthRegisterRequested({
    required this.fullName,
    required this.phoneNumber,
    this.nationalId,
    required this.role,
    this.pin,
  });

  @override
  List<Object?> get props => [fullName, phoneNumber, nationalId, role, pin];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final User? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}