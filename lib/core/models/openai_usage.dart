/// Token usage returned by OpenAI Chat Completions API.
class OpenAiUsage {
  const OpenAiUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  bool get hasTokens => totalTokens > 0 || promptTokens > 0 || completionTokens > 0;
}
