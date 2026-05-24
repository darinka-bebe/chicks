import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/user_profile_rules.dart';
import '../../../core/widgets/iphone_layout.dart';
import '../../../core/router/route_names.dart';
import '../../../features/app/bloc/app_bloc.dart';
import '../../../features/home/widgets/welcome_name_sheet.dart';
import '../../../features/profile/widgets/profile_edit_sheet.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/user_avatar.dart';

/// Вкладка «Главная» с анимированными карточками.
///
/// Читает данные из [AppBloc] через `context.watch`.
/// Карточки появляются последовательно (staggered animation).
class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _cardAnims;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 4 элемента: аватар+приветствие, 3 карточки
    _cardAnims = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptForName());
  }

  Future<void> _maybePromptForName() async {
    if (!mounted) return;
    final user = context.read<AppBloc>().state.user;
    await WelcomeNamePrompt.maybeShow(context, user);
  }

  Future<void> _openNameSetup() async {
    await WelcomeNameSheet.show(context);
  }

  Future<void> _openNameEdit() async {
    final user = context.read<AppBloc>().state.user;
    if (user.isEmpty) return;
    await ProfileEditSheet.show(
      context,
      displayName: user.displayName,
      username: user.username,
      uid: user.uid,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final animation = _cardAnims[index];
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  void _openStylistChat() {
    context.pushNamed(RouteNames.chatName);
  }

  void _openWardrobe() {
    context.pushNamed(RouteNames.wardrobeName);
  }

  void _openFavorites() {
    context.pushNamed(RouteNames.favoritesName);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = context.watch<AppBloc>().state;
    final user = appState.user;
    final textTheme = Theme.of(context).textTheme;
    final greetingName = UserProfileRules.greetingName(user.displayName);
    final hasPersonalName = greetingName.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.tabMain,
          style: textTheme.titleLarge?.copyWith(
            color: const Color(0xFFFF4FA0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: IphoneLayout.scrollPadding(
          context,
          horizontal: 24,
          top: 8,
          extraBottom: IphoneLayout.shellBottomNavHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар + приветствие
            _animated(
              0,
              Column(
                children: [
                  GestureDetector(
                    onTap: hasPersonalName ? _openNameEdit : _openNameSetup,
                    child: UserAvatar(
                      photoUrl: user.photoUrl,
                      userId: user.uid,
                      avatarRevision: user.avatarRevision,
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  if (hasPersonalName) ...[
                    GestureDetector(
                      onTap: _openNameEdit,
                      child: Text(
                        loc.greeting(greetingName),
                        style: textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFFFF4FA0),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Привет! 👋',
                      style: textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFFFF4FA0),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Как тебя зовут?',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF2D1A24),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _openNameSetup,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Добавить имя'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4FA0),
                        side: const BorderSide(color: Color(0xFFFF4FA0)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Твой персональный стилист всегда с тобой 💗',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Карточка — Гардероб
            _animated(
              1,
              _FeatureCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Твой гардероб',
                subtitle: 'Создай цифровой гардероб и получай рекомендации',
                onTap: _openWardrobe,
              ),
            ),
            const SizedBox(height: 12),

            // Карточка — Чат
            _animated(
              2,
              _FeatureCard(
                icon: Icons.chat_bubble_outline,
                title: 'Чат со стилистом',
                subtitle: 'ИИ-помощник ответит на все вопросы о моде',
                onTap: _openStylistChat,
              ),
            ),
            const SizedBox(height: 12),

            // Карточка — Избранные образы
            _animated(
              3,
              _FeatureCard(
                icon: Icons.favorite_rounded,
                title: 'Избранные образы',
                subtitle: 'Сохранённые рекомендации стилиста в одном месте',
                onTap: _openFavorites,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Карточка функции с анимацией нажатия (scale feedback).
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.forward(),
      onTap: () {
        _pressController.forward();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: const Color(0xFFFF4FA0), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D1A24),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFFFF4FA0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
