import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/weather_condition.dart';
import '../../../core/models/weather_snapshot.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/style_insights_loader.dart';
import '../../../core/services/weather/weather_repository.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/utils/user_profile_rules.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../core/widgets/iphone_layout.dart';
import '../../../data/models/outfit_history_entry.dart';
import '../../../data/repositories/tutorial_repository.dart';
import '../../../features/app/bloc/app_bloc.dart';
import '../../../features/favorites/favorites_controller.dart';
import '../../../features/home/widgets/welcome_name_sheet.dart';
import '../../../features/outfit_history/outfit_history_controller.dart';
import '../../../features/profile/widgets/profile_edit_sheet.dart';
import '../../../features/wardrobe/wardrobe_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/user_avatar.dart';

class MainTab extends StatefulWidget {
  const MainTab({super.key});

  @override
  State<MainTab> createState() => _MainTabState();
}

class _MainTabState extends State<MainTab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _sectionAnims;
  final WeatherRepository _weatherRepository = WeatherRepository.instance;

  WeatherSnapshot? _weather;
  List<String> _insights = const [];
  bool _loadingWeather = false;
  bool _loadingInsights = false;
  String? _weatherError;
  String? _insightsError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    );
    _sectionAnims = List.generate(7, (i) {
      final start = (i * 0.1).clamp(0.0, 0.8);
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybePromptForName();
      await _maybeShowTutorial();
      await _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _loadingWeather = true;
      _loadingInsights = true;
      _weatherError = null;
      _insightsError = null;
    });
    try {
      final weather = await _weatherRepository.getCurrent();
      if (mounted) {
        setState(() => _weather = weather.isAvailable ? weather : null);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _weatherError = 'Не удалось обновить погоду');
      }
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
    }

    try {
      final insights = await StyleInsightsLoader.load();
      if (mounted) {
        setState(() {
          _insights = insights.map((e) => e.title).take(3).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _insightsError = 'Не удалось загрузить style insights');
      }
    } finally {
      if (mounted) setState(() => _loadingInsights = false);
    }
  }

  Future<void> _maybeShowTutorial() async {
    if (!mounted) return;
    final done = await TutorialRepository.instance.isCompleted();
    if (!done && mounted) {
      context.go(RouteNames.tutorial);
    }
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

  Future<void> _refreshAll() async {
    final wardrobeController = context.read<WardrobeController>();
    final favoritesController = context.read<FavoritesController>();
    final historyController = context.read<OutfitHistoryController>();
    await _loadDashboardData();
    if (!mounted) return;
    await wardrobeController.reloadFromStorage();
    await favoritesController.refresh();
    await historyController.refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final animation = _sectionAnims[index];
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

  void _openStylistChat() => context.pushNamed(RouteNames.chatName);

  void _openStylistChatWithPrompt(String prompt) {
    context.pushNamed(RouteNames.chatName, extra: prompt);
  }

  void _openWardrobe() => context.pushNamed(RouteNames.wardrobeName);

  void _openFavorites() => context.pushNamed(RouteNames.favoritesName);

  String _weatherPrompt() {
    if (_weather == null || !_weather!.isAvailable) {
      return 'Подбери comfy образ на сегодня';
    }
    return 'Подбери образ на сегодня: ${_weather!.compactUiLabel.toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = context.watch<AppBloc>().state;
    final wardrobe = context.watch<WardrobeController>();
    final favorites = context.watch<FavoritesController>();
    final history = context.watch<OutfitHistoryController>();
    final user = appState.user;
    final greetingName = UserProfileRules.greetingName(user.displayName);
    final hasPersonalName = greetingName.isNotEmpty;
    final latest = history.entries.isNotEmpty ? history.entries.first : null;

    return Scaffold(
      backgroundColor: AppBrandColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.tabMain,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppBrandColors.pink,
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: IphoneLayout.scrollPadding(
            context,
            horizontal: 20,
            top: 8,
            extraBottom: IphoneLayout.shellBottomNavHeight,
          ),
          children: [
            _animated(
              0,
              _HomeGreeting(
                userId: user.uid,
                photoUrl: user.photoUrl,
                avatarRevision: user.avatarRevision,
                greeting: hasPersonalName ? loc.greeting(greetingName) : 'Привет! 👋',
                subtitle: hasPersonalName
                    ? 'AI-стилист подготовил идеи специально для тебя'
                    : 'Добавь имя, чтобы персонализировать опыт',
                onTapAvatar: hasPersonalName ? _openNameEdit : _openNameSetup,
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              1,
              _WeatherCard(
                weather: _weather,
                isLoading: _loadingWeather,
                errorMessage: _weatherError,
                onGenerate: () => _openStylistChatWithPrompt(_weatherPrompt()),
                onRetry: _loadDashboardData,
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              2,
              _QuickPromptsCard(onTapPrompt: _openStylistChatWithPrompt),
            ),
            const SizedBox(height: 14),
            _animated(
              3,
              _OutfitOfDayCard(
                latest: latest,
                onOpenChat: _openStylistChat,
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              4,
              _InsightsCard(
                isLoading: _loadingInsights,
                insights: _insights,
                errorMessage: _insightsError,
                onRetry: _loadDashboardData,
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              5,
              _StatsRow(
                wardrobeCount: wardrobe.items.length,
                favoritesCount: favorites.outfits.length,
                generatedCount: history.entries.length,
              ),
            ),
            const SizedBox(height: 14),
            _animated(
              6,
              Column(
                children: [
                  _FeatureCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Твой гардероб',
                    subtitle: 'Создай цифровой гардероб и получай рекомендации',
                    onTap: _openWardrobe,
                  ),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.favorite_rounded,
                    title: 'Избранные образы',
                    subtitle: 'Сохранённые рекомендации стилиста в одном месте',
                    onTap: _openFavorites,
                  ),
                  if (wardrobe.items.isEmpty) ...[
                    const SizedBox(height: 10),
                    _EmptyWardrobeHint(onOpenWardrobe: _openWardrobe),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({
    required this.userId,
    required this.photoUrl,
    required this.avatarRevision,
    required this.greeting,
    required this.subtitle,
    required this.onTapAvatar,
  });

  final String userId;
  final String photoUrl;
  final int avatarRevision;
  final String greeting;
  final String subtitle;
  final VoidCallback onTapAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTapAvatar,
          child: UserAvatar(
            photoUrl: photoUrl,
            userId: userId,
            avatarRevision: avatarRevision,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding - 2),
        Text(
          greeting,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.weather,
    required this.isLoading,
    required this.errorMessage,
    required this.onGenerate,
    required this.onRetry,
  });

  final WeatherSnapshot? weather;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGenerate;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final label = weather?.compactUiLabel ?? 'Погода недоступна';
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppBrandColors.iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(weather), color: AppBrandColors.pink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading ? 'Обновляем погоду…' : label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppBrandColors.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: isLoading
                ? const Column(
                    key: ValueKey('weather-loading'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChicksSkeleton(height: 12, width: 230, borderRadius: 6),
                      SizedBox(height: 8),
                      ChicksSkeleton(height: 12, width: 180, borderRadius: 6),
                    ],
                  )
                : errorMessage != null
                    ? ChicksErrorState(
                        key: const ValueKey('weather-error'),
                        message: errorMessage!,
                        compact: true,
                        onRetry: onRetry,
                      )
                    : Text(
                        _adviceFor(weather),
                        key: const ValueKey('weather-ready'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: AppBrandColors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Generate weather outfit'),
          ),
        ],
      ),
    );
  }

  static String _adviceFor(WeatherSnapshot? weather) {
    if (weather == null || !weather.isAvailable) {
      return 'Сегодня layered comfy outfits будут универсальным выбором.';
    }
    final rainy = weather.conditions.contains(WeatherCondition.rainy);
    if (rainy && weather.isCold) {
      return 'Сегодня холодно и дождливо — собери тёплый многослойный образ и закрытую обувь.';
    }
    if (rainy) {
      return 'Сегодня дождливо — лучше подойдут многослойные comfy-образы и защищённая обувь.';
    }
    if (weather.isCold) {
      return 'Добавь тёплый слой и более плотные фактуры для баланса.';
    }
    if (weather.isHot) {
      return 'Сделай ставку на лёгкие ткани и светлую палитру.';
    }
    return 'Сегодня хорошо подойдут мягкие многослойные образы.';
  }

  static IconData _iconFor(WeatherSnapshot? weather) {
    final condition = weather?.conditions.firstOrNull;
    return switch (condition) {
      WeatherCondition.sunny => Icons.wb_sunny_rounded,
      WeatherCondition.cloudy => Icons.cloud_rounded,
      WeatherCondition.rainy => Icons.umbrella_rounded,
      WeatherCondition.snowy => Icons.ac_unit_rounded,
      WeatherCondition.windy => Icons.air_rounded,
      WeatherCondition.foggy => Icons.blur_on_rounded,
      null => Icons.wb_cloudy_outlined,
    };
  }
}

class _QuickPromptsCard extends StatelessWidget {
  const _QuickPromptsCard({required this.onTapPrompt});

  final ValueChanged<String> onTapPrompt;

  @override
  Widget build(BuildContext context) {
    const prompts = <(String, String)>[
      ('comfy', 'Подбери comfy образ на сегодня'),
      ('school', 'Подбери образ в школу'),
      ('date night', 'Подбери образ для date night'),
      ('streetwear', 'Подбери streetwear образ'),
      ('rainy', 'Подбери образ на дождливую погоду'),
      ('minimal', 'Подбери минималистичный образ'),
    ];
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick AI Suggestions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (label, prompt) = prompts[index];
                return _PressChip(
                  label: label,
                  onTap: () => onTapPrompt(prompt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitOfDayCard extends StatelessWidget {
  const _OutfitOfDayCard({
    required this.latest,
    required this.onOpenChat,
  });

  final OutfitHistoryEntry? latest;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final entry = latest;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Outfit of the Day',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.title,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenChat,
                child: const Text('К рекомендациям'),
              ),
            ],
          ),
          if (entry == null)
            Text(
              'Сгенерируй первый образ в чате, и он появится здесь.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppBrandColors.iconBackground.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppBrandColors.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.userPrompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.isLoading,
    required this.insights,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final List<String> insights;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    const fallback = <String>[
      'You mostly wear neutral comfy styles',
      'Your dominant palette is Soft Summer',
      'Streetwear is your top aesthetic',
    ];
    final current = insights.isEmpty ? fallback : insights;
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Style Insights',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: isLoading
                ? const Column(
                    key: ValueKey('insights-loading'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChicksSkeleton(height: 12, width: 240, borderRadius: 6),
                      SizedBox(height: 8),
                      ChicksSkeleton(height: 12, width: 220, borderRadius: 6),
                      SizedBox(height: 8),
                      ChicksSkeleton(height: 12, width: 190, borderRadius: 6),
                    ],
                  )
                : errorMessage != null
                    ? ChicksErrorState(
                        key: const ValueKey('insights-error'),
                        message: errorMessage!,
                        compact: true,
                        onRetry: onRetry,
                      )
                    : Column(
                        key: const ValueKey('insights-ready'),
                        children: [
                          for (final item in current.take(3))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: AppBrandColors.pink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.wardrobeCount,
    required this.favoritesCount,
    required this.generatedCount,
  });

  final int wardrobeCount;
  final int favoritesCount;
  final int generatedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Гардероб', value: '$wardrobeCount')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Избранное', value: '$favoritesCount')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'AI образы', value: '$generatedCount')),
      ],
    );
  }
}

class _EmptyWardrobeHint extends StatelessWidget {
  const _EmptyWardrobeHint({required this.onOpenWardrobe});

  final VoidCallback onOpenWardrobe;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Начни с гардероба',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавь минимум 5 вещей, чтобы AI рекомендации стали заметно точнее.',
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onOpenWardrobe,
            style: FilledButton.styleFrom(
              backgroundColor: AppBrandColors.pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Добавить вещи'),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppBrandColors.pink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PressChip extends StatefulWidget {
  const _PressChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_PressChip> createState() => _PressChipState();
}

class _PressChipState extends State<_PressChip> with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.96,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.reverse(),
      onTapCancel: () => _pressController.forward(),
      onTap: () {
        _pressController.forward();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _pressController,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppBrandColors.iconBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppBrandColors.pink.withValues(alpha: 0.24)),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppBrandColors.title,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppBrandColors.pink.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

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
        scale: _pressController,
        child: _DashboardCard(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppBrandColors.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: AppBrandColors.pink, size: 24),
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
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppBrandColors.pink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
