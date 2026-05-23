import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/services/user_directory_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UserDirectoryService userDirectoryService;
  final AuthLocalDataSource localDataSource;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.userDirectoryService,
    required this.localDataSource,
  }) : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthChangePinRequested>(_onChangePinRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await getCurrentUserUseCase();
    await result.fold(
      (_) async => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearErrorMessage: true,
        ),
      ),
      (user) async {
        if (user == null) {
          emit(
            state.copyWith(
              status: AuthStatus.unauthenticated,
              clearUser: true,
              clearErrorMessage: true,
            ),
          );
          return;
        }
        unawaited(_syncUser(user, 'auth check'));
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await loginUseCase(event.phoneNumber, event.pin);
    await result.fold(
      (failure) async => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (user) async =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await registerUseCase(
      fullName: event.fullName,
      phoneNumber: event.phoneNumber,
      nationalId: event.nationalId,
      role: event.role,
      pin: event.pin,
    );
    await result.fold(
      (failure) async => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (user) async =>
          emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearErrorMessage: true,
        ),
      ),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: event.user));
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          clearErrorMessage: true,
        ),
      );
    }
  }

  Future<void> _onChangePinRequested(
    AuthChangePinRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null) {
      emit(
        state.copyWith(status: AuthStatus.error, errorMessage: 'Not logged in'),
      );
      return;
    }

    try {
      final isCurrentPinValid = await localDataSource.verifyPin(
        phoneNumber: currentUser.phoneNumber,
        pin: event.currentPin,
      );

      if (!isCurrentPinValid) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Current PIN is incorrect',
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            clearErrorMessage: true,
          ),
        );
        return;
      }

      final updatedUser = await localDataSource.changePin(
        userId: currentUser.id,
        newPin: event.newPin,
      );

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: updatedUser,
          clearErrorMessage: true,
        ),
      );

      unawaited(_syncUser(updatedUser, 'pin change'));
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Failed to change PIN: $e',
        ),
      );
    }
  }

  Future<void> _syncUser(User user, String source) async {
    try {
      await userDirectoryService.syncUser(user);
    } catch (e) {
      debugPrint('User sync failed during $source: $e');
    }
  }
}
