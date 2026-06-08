import 'package:flutter/material.dart';

import '../../../core/services/weather/weather_repository.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/chicks_input_styles.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_preferences_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Edit display name, city (weather), and optional username.
class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({
    super.key,
    required this.initialDisplayName,
    required this.initialUsername,
    required this.initialCity,
    required this.uid,
  });

  final String initialDisplayName;
  final String initialUsername;
  final String initialCity;
  final String uid;

  static Future<bool> show(
    BuildContext context, {
    required String displayName,
    required String username,
    required String uid,
    String city = '',
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ProfileEditSheet(
          initialDisplayName: displayName,
          initialUsername: username,
          initialCity: city,
          uid: uid,
        ),
      ),
    );
    return saved == true;
  }

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _cityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
    _usernameController = TextEditingController(text: widget.initialUsername);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.profileEditNameRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final city = _cityController.text.trim();
    if (city.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.profileEditCityRequired),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final cityChanged = city != widget.initialCity.trim();

      await AuthRepository.instance.updateProfileDetails(
        displayName: name,
        username: _usernameController.text,
      );

      if (cityChanged) {
        await ProfilePreferencesRepository.instance.saveCity(
          uid: widget.uid,
          city: city,
        );
        WeatherRepository.instance.clearCache();
      }

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
          Text(
            loc.profileEditTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            style: ChicksInputStyles.value,
            textCapitalization: TextCapitalization.words,
            decoration: ChicksInputStyles.decoration(
              hintText: loc.profileEditNameHint,
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            style: ChicksInputStyles.value,
            textCapitalization: TextCapitalization.words,
            decoration: ChicksInputStyles.decoration(
              hintText: loc.profileEditCityHint,
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameController,
            style: ChicksInputStyles.value,
            decoration: ChicksInputStyles.decoration(
              hintText: loc.profileEditUsernameHint,
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.profileEditEmailNote,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                : Text(loc.profileEditSave),
          ),
        ],
      ),
    );
  }
}
