import 'package:flutter/material.dart';

import '../../../core/constants/stylist_suggestion_chips.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/chicks_input_styles.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'chat_suggestion_chips.dart';

class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onSend;
  final ValueChanged<bool>? onFocusChanged;

  const ChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
    this.onFocusChanged,
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
    final focused = _focusNode.hasFocus;
    if (_isFocused != focused) {
      setState(() => _isFocused = focused);
      widget.onFocusChanged?.call(focused);
    }
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
    final snippet = chip.localizedPromptSnippet;
    final current = _controller.text.trim();
    final prefix = AppLocale.isRussian() ? 'Подбери' : 'Suggest';

    String next;
    if (current.isEmpty) {
      next = '$prefix $snippet';
    } else if (current.toLowerCase().contains(snippet.toLowerCase())) {
      next = current;
    } else if (current.toLowerCase().startsWith(prefix.toLowerCase()) ||
        current.toLowerCase().startsWith('suggest')) {
      next = '$current, $snippet';
    } else {
      next = '$current. $prefix $snippet';
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppBrandColors.pink.withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isFocused) ...[
            const SizedBox(height: 10),
            ChatSuggestionChips(
              enabled: widget.enabled,
              onChipTap: _insertChipPrompt,
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              keyboardInset > 0 ? 10 : 10 + MediaQuery.paddingOf(context).bottom,
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
                    cursorColor: AppBrandColors.pink,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: widget.enabled ? (_) => _submit() : null,
                    decoration: ChicksInputStyles.chatDecoration(
                      hintText: loc.chatInputHint,
                    ),
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
