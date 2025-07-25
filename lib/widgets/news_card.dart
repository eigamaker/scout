import 'package:flutter/material.dart';
import '../models/news/news_item.dart';

class NewsCard extends StatelessWidget {
  final NewsItem news;
  final VoidCallback? onTap;

  const NewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: news.getImportanceColor().withOpacity(0.1),
      child: ListTile(
        title: Text(news.title),
        subtitle: Text(news.getShortContent()),
        trailing: Text(news.getFormattedDate()),
        onTap: onTap,
      ),
    );
  }
} 