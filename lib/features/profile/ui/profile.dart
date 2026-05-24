import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/demo_reset_service.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../core/widgets/iphone_layout.dart';
import '../../../core/models/body_profile.dart';
import '../../../core/models/seasonal_color_type.dart';
import '../../../data/models/user_model.dart';
import '../../../core/models/user_preferences_bundle.dart';
import '../../../data/repositories/user_preferences_repository.dart';
import '../../../features/favorites/favorites_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../app/bloc/app_bloc.dart';
import '../../app/bloc/app_event.dart';
import '../../app/bloc/auth_state.dart';
import '../data/profile_stats_loader.dart';
import '../widgets/profile_body_type_card.dart';
import '../widgets/profile_color_type_card.dart';
import '../widgets/profile_action_tile.dart';
import '../widgets/profile_card_decoration.dart';
import '../widgets/profile_edit_sheet.dart';
import '../widgets/profile_editable_avatar.dart';
import '../widgets/profile_preferences_summary_card.dart';
import '../widgets/profile_section.dart';
import '../widgets/profile_stat_card.dart';
import '../widgets/profile_style_insights_section.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final GlobalKey<_ProfileStatsPanelState> _statsPanelKey =
      GlobalKey<_ProfileStatsPanelState>();

  final GlobalKey<ProfileStyleInsightsSectionState> _styleInsightsKey =
      GlobalKey<ProfileStyleInsightsSectionState>();

  SeasonalColorType? _colorType;
  BodyProfile? _bodyProfile;
  UserPreferencesBundle _preferences = UserPreferencesBundle.empty;

  static const int _listItemCount = 14;

  @override
  void initState() {
    super.initState();
    _loadStyleProfile();
  }

  Future<void> _loadStyleProfile() async {
    final bundle = await UserPreferencesRepository.instance.loadBundle();
    if (!mounted) return;
    setState(() {
      _preferences = bundle;
      _colorType = bundle.colorType;
      _bodyProfile = bundle.bodyProfile;
    });
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
    final bundle = _preferences;
    final moods = bundle.stylistDefaults.topMoods();
    final occasions = bundle.stylistDefaults.topOccasions();

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
              'Стиль и настроение',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppBrandColors.title,
              ),
            ),
            const SizedBox(height: 12),
            if (moods.isNotEmpty || occasions.isNotEmpty) ...[
              if (moods.isNotEmpty)
                Text(
                  'Частые настроения: ${moods.join(', ')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              if (occasions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Частые поводы: ${occasions.join(', ')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Избранных образов: ${bundle.favoritesCount} · '
                'дизлайков: ${bundle.dislikesCount}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ] else
              Text(
                'В чате выбирай подсказки (romantic, comfy, school, rainy…) — '
                'приложение запомнит настроение и повод на этом устройстве.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chicks — твой персональный AI-стилист\nВерсия 1.0.0',
              ),
              const SizedBox(height: 20),
              const Text(
                'Демо и данные',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.pink,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Сбросить демо-данные'),
                subtitle: const Text(
                  'Гардероб, чат, избранное и история образов',
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmDemoReset(includeQuizzes: false);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Сбросить всё + квизы'),
                subtitle: const Text(
                  'Как после первой установки (онбординг заново)',
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _confirmDemoReset(includeQuizzes: true);
                },
              ),
            ],
          ),
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

  Future<void> _confirmDemoReset({required bool includeQuizzes}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(includeQuizzes ? 'Сбросить всё?' : 'Сбросить демо-данные?'),
        content: Text(
          includeQuizzes
              ? 'Будут очищены гардероб, чат, избранное, история и результаты квизов. Аккаунт останется.'
              : 'Гардероб снова заполнится демо-вещами. Чат, избранное и история будут очищены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Сбросить',
              style: TextStyle(color: AppBrandColors.pink),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      if (includeQuizzes) {
        await DemoResetService.resetAllIncludingQuizzes();
      } else {
        await DemoResetService.resetDemoData();
      }
      if (!mounted) return;

      context.read<FavoritesController>().refresh();

      await _refreshStats();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              includeQuizzes
                  ? 'Данные сброшены — откроется онбординг'
                  : 'Демо-данные восстановлены',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      if (includeQuizzes) {
        context.go(RouteNames.splash);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Не удалось сбросить данные'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  Future<void> _refreshStats() async {
    await Future.wait([
      _statsPanelKey.currentState?.reload() ?? Future<void>.value(),
      _styleInsightsKey.currentState?.reload() ?? Future<void>.value(),
      _loadStyleProfile(),
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
            padding: IphoneLayout.shellTabScrollPadding(context),
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
                  return const SizedBox(height: AppSpacing.lg);
                case 2:
                  return ProfileStyleProfileGroup(
                    colorCard: ProfileColorTypeCard(
                      colorType: _colorType,
                      onUpdated: _loadStyleProfile,
                      grouped: true,
                    ),
                    bodyCard: ProfileBodyTypeCard(
                      bodyProfile: _bodyProfile,
                      onUpdated: _loadStyleProfile,
                      grouped: true,
                    ),
                  );
                case 3:
                  return const SizedBox(height: AppSpacing.lg);
                case 4:
                  return ProfilePreferencesSummaryCard(
                    bundle: _preferences,
                  );
                case 5:
                  return const SizedBox(height: AppSpacing.xl);
                case 6:
                  return ProfileStyleInsightsSection(key: _styleInsightsKey);
                case 7:
                  return const SizedBox(height: AppSpacing.xl);
                case 8:
                  return _ProfileStatsPanel(key: _statsPanelKey);
                case 9:
                  return const SizedBox(height: AppSpacing.xxl);
                case 10:
                  return const _SectionTitle(title: 'Быстрые действия');
                case 11:
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: _ProfileActionsBlock(
                      onWardrobe: () =>
                          context.pushNamed(RouteNames.wardrobeName),
                      onFavorites: () =>
                          context.pushNamed(RouteNames.favoritesName),
                      onHistory: () =>
                          context.pushNamed(RouteNames.outfitHistoryName),
                      onStyle: _showStylePreferences,
                      onSettings: _showSettings,
                    ),
                  );
                case 12:
                  return const SizedBox(height: AppSpacing.section);
                case 13:
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
        const SizedBox(height: AppSpacing.md),
        ProfileActionTile(
          icon: Icons.favorite_rounded,
          title: 'Избранные образы',
          subtitle: 'Сохранённые рекомендации стилиста',
          onTap: onFavorites,
        ),
        const SizedBox(height: AppSpacing.md),
        ProfileActionTile(
          icon: Icons.history_rounded,
          title: 'История образов',
          subtitle: 'Все AI-рекомендации с вещами из гардероба',
          onTap: onHistory,
        ),
        const SizedBox(height: AppSpacing.md),
        ProfileActionTile(
          icon: Icons.auto_awesome_outlined,
          title: 'Стиль и настроение',
          subtitle: 'Подсказки для AI-стилиста',
          onTap: onStyle,
        ),
        const SizedBox(height: AppSpacing.md),
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

  Future<void> _openEdit(BuildContext context) async {
    if (user.isEmpty) return;
    await ProfileEditSheet.show(
      context,
      displayName: user.displayName,
      username: user.username,
      uid: user.uid,
    );
  }

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
            ProfileEditableAvatar(
              photoUrl: user.photoUrl,
              userId: user.uid,
              avatarRevision: user.avatarRevision,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Нажмите на фото — выберите и обрежьте кадр',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _openEdit(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppBrandColors.title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey[500],
                    ),
                  ],
                ),
              ),
            ),
            if (user.visibleUsername.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user.visibleUsername,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (user.visibleEmail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                user.visibleEmail,
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
      return const ChicksStatsRowSkeleton();
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
