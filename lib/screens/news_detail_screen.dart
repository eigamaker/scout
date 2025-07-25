import 'package:flutter/material.dart';
import '../models/news/news_item.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news.getFormattedDate(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(news.content, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('カテゴリ: ${news.getCategoryText()}'),
            Text('重要度: ${news.getImportanceText()}'),
            // 必要に応じて他の情報も追加
          ],
        ),
      ),
    );
  }
} 