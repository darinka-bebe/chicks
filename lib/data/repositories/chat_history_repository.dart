import '../../core/storage/hive_json_list_codec.dart';
import '../../core/storage/local_hive_storage.dart';
import '../../core/utils/logger.dart';
import '../models/chat_message.dart';

/// Persists stylist chat messages locally (Hive).
class ChatHistoryRepository {
  ChatHistoryRepository._();

  static final ChatHistoryRepository instance = ChatHistoryRepository._();

  factory ChatHistoryRepository() => instance;

  static const _messagesKey = LocalHiveStorage.chatMessagesKey;

  Future<List<ChatMessage>> loadMessages() async {
    final maps = HiveJsonListCodec.decode(
      LocalHiveStorage.chatBox.get(_messagesKey),
    );
    if (maps.isEmpty) return [];

    try {
      return maps
          .map(ChatMessage.fromJson)
          .where((message) => message.content.isNotEmpty)
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'ChatHistoryRepository.loadMessages: corrupt data',
        error: e,
        stackTrace: stack,
      );
      await LocalHiveStorage.chatBox.delete(_messagesKey);
      return [];
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    await HiveJsonListCodec.write(
      LocalHiveStorage.chatBox,
      _messagesKey,
      messages.map((message) => message.toJson()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalHiveStorage.chatBox.delete(_messagesKey);
  }

  Future<int> countUserMessages() async {
    final messages = await loadMessages();
    return messages.where((message) => message.role == ChatRole.user).length;
  }
}
