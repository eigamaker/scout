import 'dart:math';
import '../player/player.dart';
import '../player/pitch.dart';

// 高校クラス
class School {
  final String name;
  final String location;
  final List<Player> players;
  final int coachTrust; // 監督の信頼度 0-100
  final String coachName;
  
  School({
    required this.name,
    required this.location,
    required this.players,
    required this.coachTrust,
    required this.coachName,
  });
  
  // 新しい選手を生成
  Player generateNewPlayer(int grade) {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final personalities = ['真面目', '明るい', 'クール', 'リーダー', '努力家'];
    
    final position = positions[Random().nextInt(positions.length)];
    final isPitcher = position == '投手';
    
    // 隠し能力値を生成
    final mentalGrit = (Random().nextDouble() - 0.5) * 0.3; // -0.15〜+0.15
    final growthRate = 0.85 + Random().nextDouble() * 0.3; // 0.85-1.15
    final peakAbility = 80 + Random().nextInt(71); // 80-150
    
    // ポジション適性を生成
    final positionFit = <String, int>{};
    for (final pos in positions) {
      if (pos == position) {
        positionFit[pos] = 70 + Random().nextInt(21); // メインポジション 70-90
      } else {
        positionFit[pos] = 40 + Random().nextInt(31); // サブポジション 40-70
      }
    }
    
    Player player;
    
    if (isPitcher) {
      // 投手の能力値を生成
      final fastballVelo = 130 + Random().nextInt(26); // 130-155 km/h
      final control = 30 + Random().nextInt(41); // 30-70
      final stamina = 40 + Random().nextInt(41); // 40-80
      final breakAvg = 35 + Random().nextInt(41); // 35-75
      
      // 球種を生成
      final pitchTypes = ['直球', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ'];
      final pitches = <Pitch>[];
      
      // 直球は必ず習得
      pitches.add(Pitch(
        type: '直球',
        breakAmount: 10 + Random().nextInt(21), // 10-30
        breakPot: 15 + Random().nextInt(26), // 15-40
        unlocked: true,
      ));
      
      // 他の球種はランダムに習得
      for (final type in pitchTypes.skip(1)) {
        if (Random().nextBool()) {
          pitches.add(Pitch(
            type: type,
            breakAmount: 20 + Random().nextInt(41), // 20-60
            breakPot: 25 + Random().nextInt(51), // 25-75
            unlocked: true,
          ));
        }
      }
      
      player = Player(
        name: names[Random().nextInt(names.length)] + 
              (Random().nextInt(999) + 1).toString().padLeft(3, '0'),
        school: name,
        grade: grade,
        position: position,
        personality: personalities[Random().nextInt(personalities.length)],
        fastballVelo: fastballVelo,
        control: control,
        stamina: stamina,
        breakAvg: breakAvg,
        pitches: pitches,
        mentalGrit: mentalGrit,
        growthRate: growthRate,
        peakAbility: peakAbility,
        positionFit: positionFit,
      );
    } else {
      // 野手の能力値を生成
      final batPower = 35 + Random().nextInt(41); // 35-75
      final batControl = 40 + Random().nextInt(41); // 40-80
      final run = 45 + Random().nextInt(41); // 45-85
      final field = 40 + Random().nextInt(41); // 40-80
      final arm = 35 + Random().nextInt(41); // 35-75
      
      player = Player(
        name: names[Random().nextInt(names.length)] + 
              (Random().nextInt(999) + 1).toString().padLeft(3, '0'),
        school: name,
        grade: grade,
        position: position,
        personality: personalities[Random().nextInt(personalities.length)],
        batPower: batPower,
        batControl: batControl,
        run: run,
        field: field,
        arm: arm,
        mentalGrit: mentalGrit,
        growthRate: growthRate,
        peakAbility: peakAbility,
        positionFit: positionFit,
      );
    }
    
    // 知名度を計算
    player.calculateInitialFame();
    
    return player;
  }

  School copyWith({
    String? name,
    String? location,
    List<Player>? players,
    int? coachTrust,
    String? coachName,
  }) {
    return School(
      name: name ?? this.name,
      location: location ?? this.location,
      players: players ?? this.players,
      coachTrust: coachTrust ?? this.coachTrust,
      coachName: coachName ?? this.coachName,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'players': players.map((p) => p.toJson()).toList(),
    'coachTrust': coachTrust,
    'coachName': coachName,
  };

  factory School.fromJson(Map<String, dynamic> json) => School(
    name: json['name'],
    location: json['location'],
    players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
    coachTrust: json['coachTrust'],
    coachName: json['coachName'],
  );
} 