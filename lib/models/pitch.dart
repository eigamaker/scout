// 球種クラス
class Pitch {
  final String type; // '直球', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ'
  final int breakAmount; // 現在の変化量 0-100
  final int breakPot; // 潜在変化量 0-100
  final bool unlocked; // 習得済みかどうか
  
  Pitch({
    required this.type,
    required this.breakAmount,
    required this.breakPot,
    required this.unlocked,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'breakAmount': breakAmount,
    'breakPot': breakPot,
    'unlocked': unlocked,
  };
  
  factory Pitch.fromJson(Map<String, dynamic> json) => Pitch(
    type: json['type'],
    breakAmount: json['breakAmount'],
    breakPot: json['breakPot'],
    unlocked: json['unlocked'],
  );
} 