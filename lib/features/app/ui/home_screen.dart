import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Иконка сверху
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4FA0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Заголовок
              Text(
                'Добро пожаловать!',
                style: textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFFF4FA0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Твой персональный стилист всегда с тобой 💗',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Карточка — Гардероб
              _FeatureCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Твой гардероб',
                subtitle: 'Создай цифровой гардероб и получай рекомендации',
                onTap: () {
                  // TODO: context.go('/wardrobe')
                },
              ),
              const SizedBox(height: 12),

              // Карточка — Чат
              _FeatureCard(
                icon: Icons.chat_bubble_outline,
                title: 'Чат со стилистом',
                subtitle: 'ИИ-помощник ответит на все вопросы о моде',
                onTap: () {
                  // TODO: context.go('/chat')
                },
              ),
              const SizedBox(height: 12),

              // Карточка — Стиль
              _FeatureCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Твой стиль',
                subtitle: 'Узнай свой тип и подбери образы по душе',
                onTap: () {
                  // TODO: context.go('/profile')
                },
              ),
              const SizedBox(height: 32),

              // Подпись
              Text(
                'Люблю, когда я нарядно, а ты? 🔥',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),

              // Кнопка Начать
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: context.go('/wardrobe')
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4FA0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Начать',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFFFF4FA0), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4FA0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}