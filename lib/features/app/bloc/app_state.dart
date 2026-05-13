import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Модели ───────────────────────────────────────────────────

class WardrobeItem {
  final String id;
  final String name;
  final String category;
  final String color;
  final String emoji;
  final bool isUserAdded;

  const WardrobeItem({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
    required this.emoji,
    this.isUserAdded = false,
  });
}

class Outfit {
  final String id;
  final String name;
  final List<String> itemIds;
  final String occasion;

  const Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.occasion,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class UserProfile {
  final String name;
  final String email;
  final String colorType;
  final String figureType;
  final String styleVibe;

  const UserProfile({
    this.name = '',
    this.email = '',
    this.colorType = '',
    this.figureType = '',
    this.styleVibe = '',
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? colorType,
    String? figureType,
    String? styleVibe,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        colorType: colorType ?? this.colorType,
        figureType: figureType ?? this.figureType,
        styleVibe: styleVibe ?? this.styleVibe,
      );
}

// ─── Базовый гардероб ─────────────────────────────────────────

final List<WardrobeItem> kBaseWardrobe = [
  const WardrobeItem(id: 'b1', name: 'Белая рубашка', category: 'Верх', color: 'Белый', emoji: '👔'),
  const WardrobeItem(id: 'b2', name: 'Чёрные джинсы', category: 'Низ', color: 'Чёрный', emoji: '👖'),
  const WardrobeItem(id: 'b3', name: 'Маленькое чёрное платье', category: 'Платья', color: 'Чёрный', emoji: '👗'),
  const WardrobeItem(id: 'b4', name: 'Кожаная куртка', category: 'Верх', color: 'Чёрный', emoji: '🧥'),
  const WardrobeItem(id: 'b5', name: 'Белые кроссовки', category: 'Обувь', color: 'Белый', emoji: '👟'),
  const WardrobeItem(id: 'b6', name: 'Золотые серьги', category: 'Аксессуары', color: 'Золотой', emoji: '✨'),
  const WardrobeItem(id: 'b7', name: 'Бежевый тренч', category: 'Верх', color: 'Бежевый', emoji: '🧣'),
  const WardrobeItem(id: 'b8', name: 'Белая футболка', category: 'Верх', color: 'Белый', emoji: '👕'),
];

// ─── Советы дня ───────────────────────────────────────────────

final List<Map<String, String>> kDailyTips = [
  {'emoji': '💗', 'text': 'Монохромный образ всегда выглядит элегантно и стройнит силуэт.'},
  {'emoji': '✨', 'text': 'Один яркий аксессуар оживит любой базовый образ.'},
  {'emoji': '👑', 'text': 'Осанка — лучший аксессуар. Носи себя уверенно!'},
  {'emoji': '🌸', 'text': 'Правило 1/3: смешивай пропорции одежды 1 к 3 для баланса.'},
  {'emoji': '🖤', 'text': 'Чёрное и белое — вечная классика, которая всегда в тренде.'},
  {'emoji': '🎨', 'text': 'Знай свой цветотип — это основа идеального гардероба.'},
  {'emoji': '💄', 'text': 'Меньше деталей = больше стиля. Выбери 1 акцент в образе.'},
];

// ─── AppState ─────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  UserProfile _profile = const UserProfile();
  List<WardrobeItem> _userItems = [];
  List<Outfit> _outfits = [];
  List<ChatMessage> _messages = [];
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _onboardingDone = false;

  // Геттеры
  UserProfile get profile => _profile;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get onboardingDone => _onboardingDone;
  List<ChatMessage> get messages => _messages;
  List<Outfit> get outfits => _outfits;

  /// Все вещи (база + пользовательские)
  List<WardrobeItem> get allItems => [...kBaseWardrobe, ..._userItems];

  /// Совет дня — меняется по дню недели
  Map<String, String> get dailyTip =>
      kDailyTips[DateTime.now().weekday % kDailyTips.length];

  // ── Init ──────────────────────────────────────────────────

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _isLoggedIn = p.getBool('isLoggedIn') ?? false;
    _onboardingDone = p.getBool('onboardingDone') ?? false;
    _profile = UserProfile(
      name: p.getString('name') ?? '',
      email: p.getString('email') ?? '',
      colorType: p.getString('colorType') ?? '',
      figureType: p.getString('figureType') ?? '',
      styleVibe: p.getString('styleVibe') ?? '',
    );
    notifyListeners();
  }

  // ── Онбординг ─────────────────────────────────────────────

  Future<void> completeOnboarding() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboardingDone', true);
    _onboardingDone = true;
    notifyListeners();
  }

  // ── Авторизация ───────────────────────────────────────────

  Future<String?> register(String name, String email, String password) async {
    if (name.trim().isEmpty) return 'Введите имя';
    if (!email.contains('@')) return 'Некорректный email';
    if (password.length < 6) return 'Пароль минимум 6 символов';

    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    final p = await SharedPreferences.getInstance();
    await p.setBool('isLoggedIn', true);
    await p.setString('name', name.trim());
    await p.setString('email', email.trim());
    _profile = UserProfile(name: name.trim(), email: email.trim());
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return null; // null = успех
  }

  Future<String?> login(String email, String password) async {
    if (!email.contains('@')) return 'Некорректный email';
    if (password.isEmpty) return 'Введите пароль';

    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    final p = await SharedPreferences.getInstance();
    final savedEmail = p.getString('email') ?? '';
    if (savedEmail.isNotEmpty && savedEmail != email.trim()) {
      _isLoading = false;
      notifyListeners();
      return 'Пользователь не найден';
    }

    final name = p.getString('name') ?? email.split('@').first;
    await p.setBool('isLoggedIn', true);
    _profile = UserProfile(name: name, email: email.trim(),
      colorType: p.getString('colorType') ?? '',
      figureType: p.getString('figureType') ?? '',
      styleVibe: p.getString('styleVibe') ?? '',
    );
    _isLoggedIn = true;
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('isLoggedIn', false);
    _isLoggedIn = false;
    _profile = const UserProfile();
    _messages = [];
    _userItems = [];
    _outfits = [];
    notifyListeners();
  }

  // ── Профиль ───────────────────────────────────────────────

  Future<void> saveProfile({
    String? name,
    String? colorType,
    String? figureType,
    String? styleVibe,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (name != null) await p.setString('name', name);
    if (colorType != null) await p.setString('colorType', colorType);
    if (figureType != null) await p.setString('figureType', figureType);
    if (styleVibe != null) await p.setString('styleVibe', styleVibe);
    _profile = _profile.copyWith(
      name: name, colorType: colorType,
      figureType: figureType, styleVibe: styleVibe,
    );
    notifyListeners();
  }

  // ── Гардероб ──────────────────────────────────────────────

  void addItem(WardrobeItem item) {
    _userItems = [..._userItems, item];
    notifyListeners();
  }

  void removeItem(String id) {
    _userItems = _userItems.where((e) => e.id != id).toList();
    // Удаляем аутфиты, содержащие эту вещь
    _outfits = _outfits.where((o) => !o.itemIds.contains(id)).toList();
    notifyListeners();
  }

  // ── Аутфиты ───────────────────────────────────────────────

  void saveOutfit(Outfit outfit) {
    _outfits = [..._outfits, outfit];
    notifyListeners();
  }

  void removeOutfit(String id) {
    _outfits = _outfits.where((e) => e.id != id).toList();
    notifyListeners();
  }

  /// Подобрать случайный аутфит из гардероба
  List<WardrobeItem> generateOutfit(String occasion) {
    final tops = allItems.where((e) => e.category == 'Верх').toList();
    final bottoms = allItems.where((e) => e.category == 'Низ').toList();
    final dresses = allItems.where((e) => e.category == 'Платья').toList();
    final shoes = allItems.where((e) => e.category == 'Обувь').toList();
    final acc = allItems.where((e) => e.category == 'Аксессуары').toList();

    final result = <WardrobeItem>[];

    if (occasion == 'Вечер' && dresses.isNotEmpty) {
      result.add(dresses[DateTime.now().second % dresses.length]);
    } else {
      if (tops.isNotEmpty) result.add(tops[DateTime.now().second % tops.length]);
      if (bottoms.isNotEmpty) result.add(bottoms[DateTime.now().millisecond % bottoms.length]);
    }
    if (shoes.isNotEmpty) result.add(shoes[DateTime.now().minute % shoes.length]);
    if (acc.isNotEmpty) result.add(acc[DateTime.now().hour % acc.length]);

    return result;
  }

  // ── Чат ───────────────────────────────────────────────────

  void clearChat() {
    _messages = [];
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    _messages = [..._messages, ChatMessage(text: text, isUser: true, time: DateTime.now())];
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1000));
    _messages = [..._messages, ChatMessage(text: _buildReply(text), isUser: false, time: DateTime.now())];
    notifyListeners();
  }

  String _buildReply(String text) {
    final t = text.toLowerCase();
    final name = _profile.name.isNotEmpty ? _profile.name : 'красотка';

    if (t.contains('привет') || t.contains('хай') || t.contains('hello')) {
      return 'Привет, $name! 💗 Я Chicks AI — твой персональный стилист. Спроси меня про образы, тренды, сочетания цветов или что надеть на любое событие!';
    }
    if (t.contains('надеть') || t.contains('outfit') || t.contains('образ')) {
      final fig = _profile.figureType;
      final vibe = _profile.styleVibe;
      return '✨ Для тебя, $name:\n\n'
          '${fig.isNotEmpty ? "• Фигура $fig — " + _figureAdvice(fig) + "\n" : ""}'
          '${vibe.isNotEmpty ? "• Твой вайб «$vibe» — держись этой эстетики\n" : ""}'
          '• Монохром всегда выигрывает 👌\n'
          '• Высокая талия + тонкий ремень\n\n'
          'Хочешь образ на конкретное событие? Напиши куда идёшь!';
    }
    if (t.contains('свидани') || t.contains('романтик')) {
      return '💕 Образ на свидание:\n\n'
          '• Облегающее платье миди или юбка + красивый топ\n'
          '• Каблук или мюли\n'
          '• Нежный аромат и лёгкий макияж\n'
          '• Один яркий акцент: серьги или сумочка\n\n'
          'Главное — будь собой, $name, это самое привлекательное 💗';
    }
    if (t.contains('работ') || t.contains('офис') || t.contains('деловой')) {
      return '💼 Деловой образ:\n\n'
          '• Прямые брюки или юбка-карандаш\n'
          '• Рубашка или блуза с воротником\n'
          '• Пиджак — всегда выигрышно\n'
          '• Закрытые туфли или лоферы\n\n'
          'Уверенная и стильная — ты завоюешь любой офис, $name!';
    }
    if (t.contains('тренд') || t.contains('мода') || t.contains('2025') || t.contains('2026')) {
      return '🔥 Актуальные тренды:\n\n'
          '1. Бохо с кожаными деталями\n'
          '2. Пастельный монохром\n'
          '3. Оверсайз пиджаки с поясом\n'
          '4. Мини + длинные сапоги\n'
          '5. Корсеты поверх всего\n'
          '6. Джинсы с низкой талией (снова!)\n\n'
          'Какой тренд хочешь примерить?';
    }
    if (t.contains('цвет') || t.contains('цветотип') || t.contains('палитр')) {
      final ct = _profile.colorType;
      if (ct.isEmpty) {
        return '🎨 Цветотип ещё не определён!\n\nЗайди в Профиль → выбери цветотип → я дам персональные рекомендации по палитре. Это важно для идеальных образов!';
      }
      return '🎨 Твой цветотип: $ct\n\n${_colorAdvice(ct)}';
    }
    if (t.contains('гардероб') || t.contains('базов') || t.contains('капсул')) {
      return '👗 Капсульный гардероб на сезон:\n\n'
          '☑️ 2 белые рубашки/футболки\n'
          '☑️ Чёрные брюки прямого кроя\n'
          '☑️ Качественные джинсы\n'
          '☑️ Маленькое чёрное платье\n'
          '☑️ Нейтральный тренч\n'
          '☑️ Кожаная куртка\n'
          '☑️ Белые кроссовки\n'
          '☑️ Чёрные лодочки\n\n'
          'Всё это уже есть в твоём гардеробе, $name? 👀';
    }
    if (t.contains('похуде') || t.contains('стройн') || t.contains('скрыть')) {
      final fig = _profile.figureType;
      return '💪 Лайфхаки для фигуры ${fig.isNotEmpty ? fig : "любого типа"}:\n\n'
          '${_figureFullAdvice(fig)}';
    }
    if (t.contains('аксессуар') || t.contains('украшени') || t.contains('сумк')) {
      return '👜 Аксессуары — финальный штрих:\n\n'
          '• Правило: 1 яркий акцент в образе\n'
          '• Золото тёплому цветотипу, серебро — холодному\n'
          '• Маленькая сумка = вечерний образ\n'
          '• Тоут = дневной и деловой\n'
          '• Ремень тонкий — для платьев, широкий — для пальто';
    }
    if (t.contains('макияж') || t.contains('beauty') || t.contains('губ')) {
      return '💄 Макияж под образ:\n\n'
          '• Нейтральный образ → яркая губа\n'
          '• Яркий образ → нюдовый макияж\n'
          '• Деловой → лёгкий тон + тушь\n'
          '• Вечерний → смоки или стрелка\n\n'
          'Главное правило: акцент либо на глаза, либо на губы — не оба сразу!';
    }
    if (t.contains('спасибо') || t.contains('класс') || t.contains('супер') || t.contains('огонь')) {
      return 'Ты лучшая, $name! 🌸 Ты уже идеальна — мода лишь подчёркивает это 💅\nЕсли ещё что-то понадобится — я здесь!';
    }
    if (t.contains('сочетан') || t.contains('комбинир')) {
      return '🎨 Правила сочетания цветов:\n\n'
          '• Нейтрал + 1 яркий цвет — беспроигрышно\n'
          '• Монохром разных оттенков — элегантно\n'
          '• Аналогичные цвета (рядом в круге) — гармонично\n'
          '• Контрастные цвета (напротив) — смело\n\n'
          'Какие цвета хочешь сочетать?';
    }
    return 'Интересный вопрос, $name! 🤔 Уточни подробнее:\n\n'
        '• 👗 Образ на событие (какое?)\n'
        '• 🎨 Сочетание цветов\n'
        '• 💪 Советы по типу фигуры\n'
        '• 🔥 Тренды сезона\n'
        '• 👜 Аксессуары и украшения\n\n'
        'Я помогу с любым модным вопросом!';
  }

  String _figureAdvice(String fig) {
    return switch (fig) {
      'Груша' => 'акцент на верх, пышные рукава, яркие топы',
      'Песочные часы' => 'подчёркивай талию, облегающие силуэты',
      'Яблоко' => 'A-силуэты, empire-талия, вертикальные линии',
      'Прямоугольник' => 'создавай иллюзию талии поясом, оборки',
      _ => 'любой силуэт подойдёт, экспериментируй!',
    };
  }

  String _figureFullAdvice(String fig) {
    return switch (fig) {
      'Груша' => '• Яркие топы и объёмные рукава\n• Тёмный низ\n• A-силуэт юбок\n• Горизонтальные линии на верху',
      'Песочные часы' => '• Облегающие платья\n• Поясá и корсеты\n• Wrap-платья\n• Любые высокие талии',
      'Яблоко' => '• Empire-талия\n• A-силуэты ниже талии\n• V-образный вырез\n• Вертикальные принты',
      'Прямоугольник' => '• Оборки и рюши\n• Пышные юбки\n• Пояс на талии\n• Многослойность',
      _ => '• Высокая талия — твой лучший друг\n• Монохром стройнит\n• Вертикальные линии вытягивают\n• Правильное бельё — основа всего',
    };
  }

  String _colorAdvice(String ct) {
    return switch (ct) {
      'Весна' => 'Тебе идут тёплые яркие тона:\n• Коралл, персик, золото\n• Тёплый бежевый, кремовый\n• Избегай холодных и чёрного как базового 🌸',
      'Лето' => 'Тебе идут холодные пастели:\n• Лавандовый, нежно-розовый\n• Голубой, серо-бежевый\n• Избегай оранжевого и жёлтого 💙',
      'Осень' => 'Тебе идут насыщенные тёплые тона:\n• Терракота, горчица, шоколад\n• Оливка, ржавый, бордо\n• Настоящая богиня осени! 🍂',
      'Зима' => 'Тебе идут контрастные чистые цвета:\n• Чёрный, белый, ярко-красный\n• Синий, фуксия, изумруд\n• Ты создана для смелых образов! ❄️',
      _ => 'Определи цветотип в профиле и я дам точные рекомендации!',
    };
  }
}