// ニュースアイテムクラス
class NewsItem {
  final String headline;
  final String content;
  final String category;
  final int importance;
  final DateTime timestamp;

  NewsItem({
    required this.headline,
    required this.content,
    required this.category,
    required this.importance,
    required this.timestamp,
  });
} 