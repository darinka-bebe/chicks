import 'package:flutter/material.dart';

/// Categories, seasons, style metadata, and icons for wardrobe items.
abstract final class WardrobeCatalog {
  static const List<String> categories = [
    'Верх',
    'Низ',
    'Платья',
    'Верхняя одежда',
    'Обувь',
    'Аксессуары',
  ];

  static const List<String> seasons = [
    'Весна',
    'Лето',
    'Осень',
    'Зима',
    'Всесезон',
  ];

  static const List<String> styles = [
    'casual',
    'old money',
    'streetwear',
    'clean girl',
    'sporty',
    'feminine',
  ];

  static const List<String> occasions = [
    'школа',
    'прогулка',
    'office',
    'date',
    'party',
  ];

  static const List<String> fits = [
    'oversized',
    'slim',
    'relaxed',
    'regular',
  ];

  static const List<String> vibes = [
    'минимализм',
    'романтичный',
    'дерзкий',
    'уютный',
    'элегантный',
    'игривый',
  ];

  static IconData iconForCategory(String category) {
    switch (category) {
      case 'Верх':
        return Icons.checkroom_outlined;
      case 'Низ':
        return Icons.straighten_outlined;
      case 'Платья':
        return Icons.woman_outlined;
      case 'Верхняя одежда':
        return Icons.cloud_outlined;
      case 'Обувь':
        return Icons.directions_run_outlined;
      case 'Аксессуары':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.checkroom_outlined;
    }
  }
}
