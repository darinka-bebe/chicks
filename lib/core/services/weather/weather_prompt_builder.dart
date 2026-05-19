import '../../models/weather_condition.dart';
import '../../models/weather_snapshot.dart';
import '../../models/stylist_request_context.dart';

/// Builds live-weather blocks for the AI stylist system prompt.
abstract final class WeatherPromptBuilder {
  static String? buildSystemSection({
    required WeatherSnapshot weather,
    StylistRequestContext? userContext,
  }) {
    if (!weather.isAvailable) return null;

    final buffer = StringBuffer()
      ..writeln('ПОГОДА СЕЙЧАС (живые данные приложения):');

    final temp = weather.temperatureCelsius;
    if (temp != null) {
      final rounded = temp.round();
      final sign = rounded > 0 ? '+' : '';
      buffer.writeln('- Температура: $sign$rounded°C');
    }

    if (weather.conditions.isNotEmpty) {
      final labels = weather.conditions
          .map((c) => _conditionRu(c))
          .toSet()
          .join(', ');
      buffer.writeln('- Условия: $labels');
    }

    final phase = WeatherSnapshot.dayPhaseRu(weather.dayPhase);
    if (phase.isNotEmpty) {
      buffer.writeln('- Время суток: $phase');
    }

    if (weather.windSpeedKmh != null && weather.windSpeedKmh! >= 20) {
      buffer.writeln(
        '- Ветер: ${weather.windSpeedKmh!.round()} км/ч',
      );
    }

    buffer.writeln(_stylingRules);

    if (userContext != null && userContext.weather.isNotEmpty) {
      buffer.writeln(
        '\nТеги погоды из сообщения пользователя: ${userContext.weather.join(', ')}. '
        'Совмести их с живыми данными выше.',
      );
    }

    buffer.writeln(
      '\nБаланс: практичность для погоды + эстетика + настроение из запроса. '
      'Образ ТОЛЬКО из гардероба; не выдумывай отсутствующие вещи. '
      'Под погоду выбери ОДНУ верхнюю одежду (если нужна) и ОДНУ обувь — не дублируй слоты.',
    );

    return buffer.toString().trim();
  }

  static String _conditionRu(WeatherCondition condition) {
    return switch (condition) {
      WeatherCondition.sunny => 'солнечно',
      WeatherCondition.cloudy => 'облачно',
      WeatherCondition.rainy => 'дождь',
      WeatherCondition.snowy => 'снег',
      WeatherCondition.windy => 'ветер',
      WeatherCondition.foggy => 'туман',
    };
  }

  static const _stylingRules = '''

Как адаптировать образ под погоду (из гардероба):
- Холод (<12°C): слои, свитера, куртки/пальто, закрытая обувь; сезоны «Зима»/«Осень».
- Жара (>22°C): лёгкие ткани, светлые цвета, минимум слоёв; «Лето»/«Весна».
- Дождь: плащ/тренч/непромокаемая обувь из гардероба; без открытых сандалий.
- Снег: утепление, закрытая обувь, слои.
- Ветер: устойчивые силуэты, ветровка/пиджак, избегай слишком объёмных юбок без слоя.
- Облачно: универсальные слои, мягкие нейтрали.''';
}
