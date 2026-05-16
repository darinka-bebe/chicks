import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';

enum AppStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  final AppStatus status;
  final UserModel user;

  const AuthState._({
    required this.status,
    required this.user,
  });

  const AuthState.unknown()
      : this._(status: AppStatus.unknown, user: UserModel.empty);

  const AuthState.authenticated(UserModel user)
      : this._(status: AppStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this._(status: AppStatus.unauthenticated, user: UserModel.empty);

  @override
  List<Object?> get props => [status, user];
}
