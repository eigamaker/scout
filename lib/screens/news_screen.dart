import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final newsService = Provider.of<NewsService>(context);
    
    // 1か月経過したニュースを削除
    newsService.removeOldNews();
    
    // 最新順にソートされたニュースリストを取得
    final newsList = newsService.getSortedNewsList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ニュース一覧'),
      ),
      body: newsList.isEmpty
          ? const Center(child: Text('ニュースがありません'))
          : ListView.builder(
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return NewsCard(
                  news: news,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/newsDetail',
                      arguments: news,
                    );
                  },
                );
              },
            ),
    );
  }
} 