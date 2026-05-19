import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedColor;
  String? _selectedFigure;
  File? _photo;
  int _quizStep = 0;
  String? _selectedVibe;
  bool _quizDone = false;
  String _quizResult = '';

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Какой вайб тебе ближе?',
      'options': ['Нежный', 'Тёмный', 'Минимал', 'Хаос'],
    },
    {
      'question': 'Твой любимый цвет в одежде?',
      'options': ['Пастельный', 'Чёрный', 'Нейтральный', 'Яркий'],
    },
    {
      'question': 'Идеальный образ на выход?',
      'options': ['Платье', 'Кожаные брюки', 'Белая рубашка', 'Слои и принты'],
    },
  ];

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _nextQuestion(String option) {
    setState(() {
      _selectedVibe ??= option;
      if (_quizStep < _questions.length - 1) {
        _quizStep++;
      } else {
        _quizDone = true;
        _quizResult = _selectedVibe == 'Нежный'
            ? '🌸 Романтик — рюши, пастель и нежность'
            : _selectedVibe == 'Тёмный'
                ? '🖤 Тёмная эстетика — монохром и характер'
                : _selectedVibe == 'Минимал'
                    ? '🤍 Минималист — чистые линии и нейтраль'
                    : '🌈 Эклектик — смешиваешь всё и это работает';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Профиль',
                style: textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFFFF4FA0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Фото + поля
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF4FA0),
                          width: 1.5,
                        ),
                      ),
                      child: _photo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(_photo!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0xFFFF4FA0),
                                  size: 28,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Поля
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileLabel('Имя:'),
                        _ProfileField(
                          controller: _nameController,
                          hint: 'Введите имя',
                        ),
                        const SizedBox(height: 8),
                        _ProfileLabel('Цветотип:'),
                        _ProfileDropdown(
                          hint: 'выберите: сочка',
                          value: _selectedColor,
                          items: const ['Весна', 'Лето', 'Осень', 'Зима'],
                          onChanged: (v) =>
                              setState(() => _selectedColor = v),
                        ),
                        const SizedBox(height: 8),
                        _ProfileLabel('Фигура:'),
                        _ProfileDropdown(
                          hint: 'выберите: груша',
                          value: _selectedFigure,
                          items: const [
                            'Груша',
                            'Песочные часы',
                            'Яблоко',
                            'Прямоугольник',
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedFigure = v),
                        ),
                        const SizedBox(height: 8),
                        _ProfileLabel('Поиск:'),
                        _ProfileField(
                          controller: _searchController,
                          hint: 'Нынешние предпочтения',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Кнопка загрузить фото
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _pickPhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4FA0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Загрузить фото'),
                ),
              ),
              const SizedBox(height: 32),

              // Тест
              Center(
                child: Text(
                  'Твой стиль и вайб',
                  style: textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFFF4FA0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Узнай свой тип и подбери образы по душе',
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 12),

              // Прогресс-бар
              if (!_quizDone)
                LinearProgressIndicator(
                  value: (_quizStep + 1) / _questions.length,
                  backgroundColor: const Color(0xFFFFD6E8),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF4FA0)),
                  borderRadius: BorderRadius.circular(4),
                ),
              const SizedBox(height: 20),

              // Вопрос или результат
              if (_quizDone)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _quizResult,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF4FA0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() {
                          _quizStep = 0;
                          _quizDone = false;
                          _selectedVibe = null;
                        }),
                        child: const Text('Пройти заново'),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  '${_quizStep + 1}. ${_questions[_quizStep]['question']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D1A24),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: (_questions[_quizStep]['options'] as List<String>)
                      .map((opt) => GestureDetector(
                            onTap: () => _nextQuestion(opt),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFFFD6E8),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _nextQuestion(
                      (_questions[_quizStep]['options'] as List<String>).first,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4FA0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Далее'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLabel extends StatelessWidget {
  final String text;
  const _ProfileLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _ProfileField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFFFF0F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _ProfileDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          isExpanded: true,
          isDense: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}