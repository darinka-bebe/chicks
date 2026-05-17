import 'package:flutter/material.dart';

import '../../../core/constants/stylist_suggestion_chips.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/chicks_input_styles.dart';
import 'chat_suggestion_chips.dart';

class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;

  const ChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertChipPrompt(StylistSuggestionChip chip) {
    final snippet = chip.promptSnippet.toLowerCase();
    final current = _controller.text.trim();

    String next;
    if (current.isEmpty) {
      next = 'Подбери $snippet';
    } else if (current.toLowerCase().contains(snippet)) {
      next = current;
    } else if (current.toLowerCase().startsWith('подбери')) {
      next = '$current, $snippet';
    } else {
      next = '$current. Подбери $snippet';
    }

    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _focusNode.requestFocus();
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          ChatSuggestionChips(
            enabled: widget.enabled,
            onChipTap: _insertChipPrompt,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    style: ChicksInputStyles.value,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: widget.enabled ? (_) => _submit() : null,
                    decoration: ChicksInputStyles.chatDecoration(
                      hintText: 'Спроси о стиле...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: widget.enabled
                      ? AppBrandColors.pink
                      : AppBrandColors.pink.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: widget.enabled ? _submit : null,
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
