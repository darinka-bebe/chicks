import '../../../data/models/wardrobe_item.dart';

/// Bundled flat-lay photos for demo / QA wardrobe seed.
abstract final class MockWardrobeAssets {
  static const _dir = 'assets/wardrobe_mock';

  static const whiteShirt = '$_dir/01_white_shirt.png';
  static const jeans = '$_dir/02_jeans.png';
  static const blazer = '$_dir/03_blazer.png';
  static const sneakers = '$_dir/04_sneakers.png';
  static const dress = '$_dir/05_dress.png';
  static const sweater = '$_dir/06_sweater.png';
  static const tote = '$_dir/07_tote.png';
  static const trench = '$_dir/08_trench.png';
}

/// Local mock wardrobe items for MVP (seeded on first launch).
abstract final class MockWardrobeData {
  static const List<WardrobeItem> items = [
    WardrobeItem(
      id: '1',
      title: 'Белая рубашка',
      category: 'Верх',
      color: 'Белый',
      season: 'Всесезон',
      fit: 'regular',
      styles: ['casual', 'clean girl'],
      occasions: ['школа', 'office'],
      vibes: ['минимализм', 'элегантный'],
      imagePath: MockWardrobeAssets.whiteShirt,
    ),
    WardrobeItem(
      id: '2',
      title: 'Джинсы straight',
      category: 'Низ',
      color: 'Синий',
      season: 'Всесезон',
      fit: 'regular',
      styles: ['casual'],
      occasions: ['прогулка', 'школа'],
      vibes: ['уютный'],
      imagePath: MockWardrobeAssets.jeans,
    ),
    WardrobeItem(
      id: '3',
      title: 'Пиджак оверсайз',
      category: 'Верх',
      color: 'Бежевый',
      season: 'Осень',
      fit: 'oversized',
      styles: ['old money', 'feminine'],
      occasions: ['office', 'date'],
      vibes: ['элегантный'],
      imagePath: MockWardrobeAssets.blazer,
    ),
    WardrobeItem(
      id: '4',
      title: 'Кроссовки',
      category: 'Обувь',
      color: 'Белый / розовый',
      season: 'Весна',
      fit: 'regular',
      styles: ['sporty', 'casual'],
      occasions: ['прогулка', 'школа'],
      vibes: ['игривый'],
      imagePath: MockWardrobeAssets.sneakers,
    ),
    WardrobeItem(
      id: '5',
      title: 'Шёлковое платье',
      category: 'Платья',
      color: 'Чёрный',
      season: 'Лето',
      fit: 'slim',
      styles: ['feminine', 'clean girl'],
      occasions: ['date', 'party'],
      vibes: ['романтичный', 'элегантный'],
      imagePath: MockWardrobeAssets.dress,
    ),
    WardrobeItem(
      id: '6',
      title: 'Кашемировый свитер',
      category: 'Верх',
      color: 'Пудровый',
      season: 'Зима',
      fit: 'relaxed',
      styles: ['casual', 'old money'],
      occasions: ['прогулка', 'date'],
      vibes: ['уютный'],
      imagePath: MockWardrobeAssets.sweater,
    ),
    WardrobeItem(
      id: '7',
      title: 'Сумка tote',
      category: 'Аксессуары',
      color: 'Карамель',
      season: 'Всесезон',
      fit: 'regular',
      styles: ['clean girl', 'casual'],
      occasions: ['office', 'прогулка'],
      vibes: ['минимализм'],
      imagePath: MockWardrobeAssets.tote,
    ),
    WardrobeItem(
      id: '8',
      title: 'Тренч',
      category: 'Верхняя одежда',
      color: 'Хаки',
      season: 'Весна',
      fit: 'oversized',
      styles: ['old money', 'feminine'],
      occasions: ['office', 'date'],
      vibes: ['элегантный'],
      imagePath: MockWardrobeAssets.trench,
    ),
  ];

  static final Map<String, WardrobeItem> byId = {
    for (final item in items) item.id: item,
  };
}
