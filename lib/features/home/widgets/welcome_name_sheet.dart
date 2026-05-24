import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/chicks_input_styles.dart';
import '../../../core/utils/user_profile_rules.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_preferences_repository.dart';

/// Bottom sheet for setting display name after sign-up / Google login.
class WelcomeNameSheet extends StatefulWidget {
  const WelcomeNameSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: const WelcomeNameSheet(),
      ),
    );
    return saved == true;
  }

  @override
  State<WelcomeNameSheet> createState() => _WelcomeNameSheetState();
}

class _WelcomeNameSheetState extends State<WelcomeNameSheet> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await AuthRepository.instance.updateProfileDetails(displayName: name);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _skipForNow() async {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isNotEmpty) {
      await ProfilePreferencesRepository.instance.setNamePromptDismissed(
        uid: uid,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Как тебя зовут?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Так мы обратимся к тебе на главном экране',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.35),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: ChicksInputStyles.value,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: ChicksInputStyles.decoration(
              hintText: 'Твоё имя',
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppBrandColors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Сохранить'),
          ),
          TextButton(
            onPressed: _isSaving ? null : _skipForNow,
            child: Text(
              'Позже',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows name prompt once when the user has no real display name yet.
abstract final class WelcomeNamePrompt {
  static Future<void> maybeShow(BuildContext context, UserModel user) async {
    if (user.isEmpty) return;
    if (!UserProfileRules.isGenericDisplayName(user.displayName)) return;

    final dismissed =
        await ProfilePreferencesRepository.instance.wasNamePromptDismissed(
      user.uid,
    );
    if (dismissed) return;

    if (!context.mounted) return;
    await WelcomeNameSheet.show(context);
  }
}
