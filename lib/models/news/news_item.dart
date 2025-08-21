import 'package:flutter/material.dart';

// ニュースの重要度
enum NewsImportance { low, medium, high, critical }

// ニュースのカテゴリ
enum NewsCategory { 
  player, // 選手関連
  school, // 学校関連
  game, // 試合関連
  draft, // ドラフト関連
  tournament, // 大会関連
  general // 一般
}

// ニュースアイテムクラス
class NewsItem {
  final String title;
  final String content;
  final DateTime date;
  final NewsImportance importance;
  final NewsCategory category;
  final String? relatedPlayerId; // 関連選手ID
  final String? relatedSchoolId; // 関連学校ID
  final bool isRead; // 既読かどうか
  
  NewsItem({
    required this.title,
    required this.content,
    required this.date,
    required this.importance,
    required this.category,
    this.relatedPlayerId,
    this.relatedSchoolId,
    this.isRead = false,
  });
  
  // 重要度に基づく色を取得
  Color getImportanceColor() {
    switch (importance) {
      case NewsImportance.low:
        return Colors.grey;
      case NewsImportance.medium:
        return Colors.blue;
      case NewsImportance.high:
        return Colors.orange;
      case NewsImportance.critical:
        return Colors.red;
    }
  }
  
  // カテゴリに基づく色を取得
  Color getCategoryColor() {
    switch (category) {
      case NewsCategory.player:
        return Colors.green;
      case NewsCategory.school:
        return Colors.purple;
      case NewsCategory.game:
        return Colors.blue;
      case NewsCategory.draft:
        return Colors.orange;
      case NewsCategory.tournament:
        return Colors.red;
      case NewsCategory.general:
        return Colors.grey;
    }
  }
  
  // 重要度の文字列を取得
  String getImportanceText() {
    switch (importance) {
      case NewsImportance.low:
        return '低';
      case NewsImportance.medium:
        return '中';
      case NewsImportance.high:
        return '高';
      case NewsImportance.critical:
        return '重要';
    }
  }
  
  // カテゴリの文字列を取得
  String getCategoryText() {
    switch (category) {
      case NewsCategory.player:
        return '選手';
      case NewsCategory.school:
        return '学校';
      case NewsCategory.game:
        return '試合';
      case NewsCategory.draft:
        return 'ドラフト';
      case NewsCategory.tournament:
        return '大会';
      case NewsCategory.general:
        return '一般';
    }
  }
  
  // 日付のフォーマット
  String getFormattedDate() {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
  
  // 短縮版の内容を取得（プレビュー用）
  String getShortContent() {
    if (content.length <= 50) {
      return content;
    }
    return content.substring(0, 47) + '...';
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'importance': importance.index,
    'category': category.index,
    'relatedPlayerId': relatedPlayerId,
    'relatedSchoolId': relatedSchoolId,
    'isRead': isRead,
  };

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    title: json['title'],
    content: json['content'],
    date: DateTime.parse(json['date']),
    importance: NewsImportance.values[json['importance']],
    category: NewsCategory.values[json['category']],
    relatedPlayerId: json['relatedPlayerId'],
    relatedSchoolId: json['relatedSchoolId'],
    isRead: json['isRead'] ?? false,
  );
} 