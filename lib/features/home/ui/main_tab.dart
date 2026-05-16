import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../features/app/bloc/app_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = context.watch<AppBloc>().state;
    final user = appState.user;
    final textTheme = Theme.of(context).textTheme;

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар + приветствие
            _animated(
              0,
              Column(
                children: [
                  UserAvatar(photoUrl: user.photoUrl),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    loc.greeting(
                      user.displayName.isNotEmpty ? user.displayName : 'User',
                    ),
                    style: textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFFF4FA0),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                onTap: () {},
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

            // Карточка — Стиль
            _animated(
              3,
              _FeatureCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Твой стиль',
                subtitle: 'Узнай свой тип и подбери образы по душе',
                onTap: () {},
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
