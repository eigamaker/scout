import '../models/news/news_item.dart';

class NewsService {
  final List<NewsItem> _newsList = [];

  List<NewsItem> get newsList => List.unmodifiable(_newsList);

  NewsService() {
    _initializeDummyNews();
  }

  void _initializeDummyNews() {
    _newsList.addAll([
      NewsItem(
        title: '注目の高校生投手が快投！',
        content: '甲子園高校の田中投手が9回無失点の快投を見せた。',
        date: DateTime.now().subtract(const Duration(days: 1)),
        importance: NewsImportance.high,
        category: NewsCategory.player,
      ),
      NewsItem(
        title: 'ドラフト会議の日程が決定',
        content: '今年のドラフト会議は10月25日に開催されることが決定した。',
        date: DateTime.now().subtract(const Duration(days: 2)),
        importance: NewsImportance.medium,
        category: NewsCategory.draft,
      ),
      NewsItem(
        title: '新設校が初勝利',
        content: '新設の希望高校が創部初勝利を挙げた。',
        date: DateTime.now().subtract(const Duration(days: 3)),
        importance: NewsImportance.low,
        category: NewsCategory.school,
      ),
    ]);
  }

  void addNews(NewsItem news) {
    _newsList.add(news);
  }

  void markAsRead(NewsItem news) {
    final index = _newsList.indexOf(news);
    if (index != -1) {
      _newsList[index] = NewsItem(
        title: news.title,
        content: news.content,
        date: news.date,
        importance: news.importance,
        category: news.category,
        relatedPlayerId: news.relatedPlayerId,
        relatedSchoolId: news.relatedSchoolId,
        isRead: true,
      );
    }
  }

  // TODO: ニュース自動生成ロジック
} 