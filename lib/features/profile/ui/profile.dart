import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/models/seasonal_color_type.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../features/favorites/favorites_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/user_avatar.dart';
import '../../app/bloc/app_bloc.dart';
import '../../app/bloc/app_event.dart';
import '../../app/bloc/auth_state.dart';
import '../data/profile_stats_loader.dart';
import '../widgets/profile_color_type_card.dart';
import '../widgets/profile_action_tile.dart';
import '../widgets/profile_card_decoration.dart';
import '../widgets/profile_stat_card.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final GlobalKey<_ProfileStatsPanelState> _statsPanelKey =
      GlobalKey<_ProfileStatsPanelState>();

  SeasonalColorType? _colorType;

  static const int _listItemCount = 11;

  @override
  void initState() {
    super.initState();
    _loadColorType();
  }

  Future<void> _loadColorType() async {
    final type = await UserProfileRepository.instance.getColorType();
    if (!mounted) return;
    setState(() => _colorType = type);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Ты уверена? Придётся входить снова 🥺'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Остаться'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Выйти',
              style: TextStyle(color: AppBrandColors.pink),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.read<AppBloc>().add(const AppSignOutRequested());
  }

  void _showStylePreferences() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Стиль и настроение',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppBrandColors.title,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'В чате со стилистом выбирай подсказки: romantic, comfy, school, rainy и другие — AI учтёт настроение, погоду и повод.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.pushNamed(RouteNames.chatName);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppBrandColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Открыть чат со стилистом'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Настройки'),
        content: const Text(
          'Chicks — твой персональный AI-стилист\nВерсия 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshStats() async {
    await Future.wait([
      _statsPanelKey.currentState?.reload() ?? Future<void>.value(),
      _loadColorType(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return BlocListener<AppBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AppStatus.unauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppBrandColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            loc.profileTitle,
            style: const TextStyle(
              color: AppBrandColors.pink,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          color: AppBrandColors.pink,
          onRefresh: _refreshStats,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: _listItemCount,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return RepaintBoundary(
                    child: BlocSelector<AppBloc, AuthState, UserModel>(
                      selector: (state) => state.user,
                      builder: (context, user) => _ProfileHeader(user: user),
                    ),
                  );
                case 1:
                  return const SizedBox(height: 16);
                case 2:
                  return ProfileColorTypeCard(
                    colorType: _colorType,
                    onUpdated: _loadColorType,
                  );
                case 3:
                  return const SizedBox(height: 20);
                case 4:
                  return _ProfileStatsPanel(key: _statsPanelKey);
                case 5:
                  return const SizedBox(height: 24);
                case 6:
                  return const _SectionTitle(title: 'Быстрые действия');
                case 7:
                  return const SizedBox(height: 12);
                case 8:
                  return _ProfileActionsBlock(
                    onWardrobe: () => context.pushNamed(RouteNames.wardrobeName),
                    onFavorites: () =>
                        context.pushNamed(RouteNames.favoritesName),
                    onHistory: () =>
                        context.pushNamed(RouteNames.outfitHistoryName),
                    onStyle: _showStylePreferences,
                    onSettings: _showSettings,
                  );
                case 9:
                  return const SizedBox(height: 28);
                case 10:
                  return _SignOutButton(
                    label: loc.signOut,
                    onPressed: _confirmSignOut,
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Loads stats in isolation so the rest of the profile tree does not rebuild.
class _ProfileStatsPanel extends StatefulWidget {
  const _ProfileStatsPanel({super.key});

  @override
  State<_ProfileStatsPanel> createState() => _ProfileStatsPanelState();
}

class _ProfileStatsPanelState extends State<_ProfileStatsPanel> {
  ProfileStats _stats = ProfileStats.empty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final favorites = context.read<FavoritesController>();
    if (!favorites.isLoaded) {
      await favorites.ensureLoaded();
    }
    if (!mounted) return;

    final stats = await ProfileStatsLoader.load(
      favoritesCount: favorites.isLoaded ? favorites.outfits.length : null,
    );
    if (!mounted) return;

    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Твоя статистика'),
        const SizedBox(height: 12),
        _StatsRow(stats: _stats, isLoading: _isLoading),
      ],
    );
  }
}

class _ProfileActionsBlock extends StatelessWidget {
  const _ProfileActionsBlock({
    required this.onWardrobe,
    required this.onFavorites,
    required this.onHistory,
    required this.onStyle,
    required this.onSettings,
  });

  final VoidCallback onWardrobe;
  final VoidCallback onFavorites;
  final VoidCallback onHistory;
  final VoidCallback onStyle;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileActionTile(
          icon: Icons.checkroom_outlined,
          title: 'Мой гардероб',
          subtitle: 'Вещи для персональных образов',
          onTap: onWardrobe,
        ),
        const SizedBox(height: 10),
        ProfileActionTile(
          icon: Icons.favorite_rounded,
          title: 'Избранные образы',
          subtitle: 'Сохранённые рекомендации стилиста',
          onTap: onFavorites,
        ),
        const SizedBox(height: 10),
        ProfileActionTile(
          icon: Icons.history_rounded,
          title: 'История образов',
          subtitle: 'Все AI-рекомендации с вещами из гардероба',
          onTap: onHistory,
        ),
        const SizedBox(height: 10),
        ProfileActionTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Стиль и настроение',
          subtitle: 'Подсказки для AI-стилиста',
          onTap: onStyle,
        ),
        const SizedBox(height: 10),
        ProfileActionTile(
          icon: Icons.settings_outlined,
          title: 'Настройки',
          subtitle: 'О приложении',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : 'Пользователь';

    return DecoratedBox(
      decoration: ProfileCardDecoration.header,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppBrandColors.pink.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: UserAvatar(photoUrl: user.photoUrl, radius: 52),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppBrandColors.title,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI fashion enthusiast ✨',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppBrandColors.pink,
              ),
            ),
            if (user.email.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppBrandColors.title,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.isLoading,
  });

  final ProfileStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 110,
        child: Center(
          child: CircularProgressIndicator(color: AppBrandColors.pink),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ProfileStatCard(
            icon: Icons.checkroom_outlined,
            value: '${stats.wardrobeCount}',
            label: 'Вещей в гардеробе',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ProfileStatCard(
            icon: Icons.favorite_rounded,
            value: '${stats.favoritesCount}',
            label: 'Сохранённых образов',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ProfileStatCard(
            icon: Icons.chat_bubble_outline_rounded,
            value: '${stats.stylistRequestsCount}',
            label: 'Запросов стилисту',
          ),
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          Icons.logout_rounded,
          size: 18,
          color: Colors.grey[700],
        ),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
