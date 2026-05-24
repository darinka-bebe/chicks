import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../core/utils/user_profile_rules.dart';

class UserModel extends Equatable {
  final String uid;
  final String displayName;
  final String username;
  final String email;
  final String photoUrl;
  /// Bumps when [photoUrl] file is overwritten at the same path (UI cache bust).
  final int avatarRevision;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.username = '',
    required this.email,
    required this.photoUrl,
    this.avatarRevision = 0,
    this.createdAt,
    this.lastLoginAt,
  });

  static const UserModel empty = UserModel(
    uid: '',
    displayName: '',
    username: '',
    email: '',
    photoUrl: '',
  );

  bool get isEmpty => this == empty;

  bool get isNotEmpty => this != empty;

  /// Email for UI — hides guest/placeholder addresses.
  String get visibleEmail => UserProfileRules.visibleEmail(email);

  String get visibleUsername =>
      username.trim().isNotEmpty ? '@${username.trim()}' : '';

  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : '',
      email: UserProfileRules.sanitizeStoredEmail(user.email),
      photoUrl: user.photoURL?.trim() ?? '',
      lastLoginAt: DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? username,
    String? email,
    String? photoUrl,
    int? avatarRevision,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarRevision: avatarRevision ?? this.avatarRevision,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        username,
        email,
        photoUrl,
        avatarRevision,
        createdAt,
        lastLoginAt,
      ];
}
