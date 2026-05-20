import 'package:flutter/material.dart';

import '../../../core/constants/stylist_suggestion_chips.dart';
import '../../../core/widgets/iphone_layout.dart';
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
  State<ChatInputBar> createState() => ChatInputBarState();
}

class ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Inserts a full prompt from empty-state suggestions.
  void insertPrompt(String text) {
    final next = text.trim();
    if (next.isEmpty) return;

    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _focusNode.requestFocus();
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

    insertPrompt(next);
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.unfocus();
  }

  InputDecoration _inputDecoration() {
    final base = ChicksInputStyles.chatDecoration(
      hintText: 'Спроси о стиле, гардеробе или поводе…',
    );

    if (!_isFocused) return base;

    return base.copyWith(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: AppBrandColors.pink.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(
          color: AppBrandColors.pink.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
    );
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
              padding: IphoneLayout.inputBarPadding(context),
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
                      decoration: _inputDecoration(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: widget.enabled
                        ? AppBrandColors.pink
                        : AppBrandColors.pink.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: widget.enabled ? _submit : null,
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: widget.enabled
                            ? const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22,
                              )
                            : const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
