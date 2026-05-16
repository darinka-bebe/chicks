import 'dart:convert';

import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant }

/// A single message in the stylist chat session.
class ChatMessage extends Equatable {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.assistant,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String?;
    final role = ChatRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => ChatRole.user,
    );

    return ChatMessage(
      id: json['id'] as String? ?? '',
      role: role,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static List<ChatMessage> listFromJsonString(String jsonString) {
    if (jsonString.trim().isEmpty) return [];

    final decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .where((m) => m.content.isNotEmpty)
        .toList();
  }

  static String listToJsonString(List<ChatMessage> messages) {
    return jsonEncode(messages.map((m) => m.toJson()).toList());
  }

  @override
  List<Object?> get props => [id, role, content, createdAt];
}
