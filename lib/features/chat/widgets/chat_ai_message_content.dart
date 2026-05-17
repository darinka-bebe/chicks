import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_brand_colors.dart';
import 'chat_markdown_styles.dart';

/// Renders AI replies — lightweight [Text] when possible, else markdown.
class ChatAiMessageContent extends StatefulWidget {
  const ChatAiMessageContent({super.key, required this.content});

  final String content;

  static final RegExp _markdownSignals = RegExp(
    r'(\*\*|__|^#{1,3}\s|\n[-*•]\s|\n\d+\.\s)',
    multiLine: true,
  );

  static String prepareForDisplay(String raw) {
    var text = raw.trim();
    text = text.replaceAllMapped(
      RegExp(r'«([^»]+)»'),
      (match) => '**«${match[1]}»**',
    );
    return text;
  }

  static bool needsMarkdown(String prepared) =>
      _markdownSignals.hasMatch(prepared);

  @override
  State<ChatAiMessageContent> createState() => _ChatAiMessageContentState();
}

class _ChatAiMessageContentState extends State<ChatAiMessageContent> {
  late String _prepared;
  late bool _useMarkdown;

  @override
  void initState() {
    super.initState();
    _syncContent();
  }

  @override
  void didUpdateWidget(ChatAiMessageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _syncContent();
    }
  }

  void _syncContent() {
    _prepared = ChatAiMessageContent.prepareForDisplay(widget.content);
    _useMarkdown = ChatAiMessageContent.needsMarkdown(_prepared);
  }

  @override
  Widget build(BuildContext context) {
    if (!_useMarkdown) {
      return RepaintBoundary(
        child: Text(
          widget.content.trim(),
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppBrandColors.title,
          ),
        ),
      );
    }

    final styleSheet = ChatMarkdownStyles.cachedAiBubble(context);

    return RepaintBoundary(
      child: MarkdownBody(
        key: ValueKey<String>(widget.content),
        data: _prepared,
        shrinkWrap: true,
        selectable: true,
        styleSheet: styleSheet,
      ),
    );
  }
}
