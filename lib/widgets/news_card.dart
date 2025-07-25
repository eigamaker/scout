import 'package:flutter/material.dart';
import '../models/news/news_item.dart';

class NewsCard extends StatelessWidget {
  final NewsItem news;
  final VoidCallback? onTap;

  const NewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // 明るい背景色に固定
      child: ListTile(
        title: Text(news.title, style: const TextStyle(color: Colors.black)),
        subtitle: Text(news.getShortContent(), style: const TextStyle(color: Colors.black87)),
        trailing: Text(news.getFormattedDate(), style: const TextStyle(color: Colors.black54)),
        onTap: onTap,
      ),
    );
  }
} 