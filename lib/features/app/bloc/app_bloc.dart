import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'app_event.dart';
import 'auth_state.dart';

/// Глобальный BLoC авторизации.
///
/// Подписывается на стрим `authStateChanges` из [AuthRepository]
/// и транслирует изменения в [AuthState].
///
/// Живёт на уровне всего приложения (оборачивает MaterialApp),
/// поэтому любой экран может прочитать текущего пользователя.
class AppBloc extends Bloc<AppEvent, AuthState> {
  final AuthRepository _authRepository;

  /// Подписка на стрим авторизации.
  late final StreamSubscription<UserModel> _authSubscription;

  AppBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    // Регистрируем обработчики событий.
    on<AppAuthStateChanged>(_onAuthStateChanged);
    on<AppSignOutRequested>(_onSignOutRequested);

    // Подписываемся на стрим авторизации.
    // Каждый раз, когда пользователь входит/выходит,
    // стрим присылает нового [UserModel].
    _authSubscription = _authRepository.authStateChanges.listen(
      (UserModel user) {
        add(AppAuthStateChanged(user));
      },
    );
  }

  /// Обработчик: изменился статус авторизации.
  void _onAuthStateChanged(
    AppAuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user.isNotEmpty) {
      AppLogger.info('AppBloc: пользователь авторизован — ${event.user.email}');
      emit(AuthState.authenticated(event.user));
    } else {
      AppLogger.info('AppBloc: пользователь не авторизован');
      emit(const AuthState.unauthenticated());
    }
  }

  /// Обработчик: пользователь нажал «Выйти».
  Future<void> _onSignOutRequested(
    AppSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    // Стрим authStateChanges сам пришлёт AppAuthStateChanged(empty),
    // поэтому emit здесь не нужен.
  }

  /// Закрываем подписку при уничтожении BLoC.
  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}
