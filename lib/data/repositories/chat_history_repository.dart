import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';

/// Persists stylist chat messages locally as JSON.
class ChatHistoryRepository {
  static const _storageKey = 'stylist_chat_history_v1';

  Future<List<ChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      return ChatMessage.listFromJsonString(raw);
    } catch (_) {
      await prefs.remove(_storageKey);
      return [];
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    if (messages.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(_storageKey, ChatMessage.listToJsonString(messages));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
