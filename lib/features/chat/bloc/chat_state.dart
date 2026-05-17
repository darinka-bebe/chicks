import 'package:equatable/equatable.dart';

import '../../../core/models/weather_snapshot.dart';
import '../../../data/models/chat_message.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isRestoringHistory;
  final String? error;
  final WeatherSnapshot? currentWeather;
  final bool isLoadingWeather;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRestoringHistory = false,
    this.error,
    this.currentWeather,
    this.isLoadingWeather = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isRestoringHistory,
    String? error,
    bool clearError = false,
    WeatherSnapshot? currentWeather,
    bool? isLoadingWeather,
    bool clearWeather = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRestoringHistory: isRestoringHistory ?? this.isRestoringHistory,
      error: clearError ? null : (error ?? this.error),
      currentWeather:
          clearWeather ? null : (currentWeather ?? this.currentWeather),
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isLoading,
        isRestoringHistory,
        error,
        currentWeather,
        isLoadingWeather,
      ];
}
