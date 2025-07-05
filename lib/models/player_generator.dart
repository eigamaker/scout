// 選手生成ロジック
import 'dart:math';
import 'player.dart';
import 'pitch.dart';

class PlayerGenerator {
  static final Random _random = Random();
  
  // 大学生・社会人選手を生成（ドラフト候補レベル）
  static List<Player> generateCollegeAndSocialPlayers() {
    final players = <Player>[];
    
    // 大学生選手を生成（ドラフト候補レベル）
    for (int i = 0; i < 20; i++) {
      players.add(_generateCollegePlayer());
    }
    
    // 社会人選手を生成（ドラフト候補レベル）
    for (int i = 0; i < 15; i++) {
      players.add(_generateSocialPlayer());
    }
    
    return players;
  }
  
  // 大学生選手を生成
  static Player _generateCollegePlayer() {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final universities = ['早稲田大学', '慶應義塾大学', '明治大学', '法政大学', '立教大学', '中央大学'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final personalities = ['真面目', '明るい', 'クール', 'リーダー', '努力家'];
    
    final name = names[_random.nextInt(names.length)] + 
                (_random.nextInt(999) + 1).toString().padLeft(3, '0');
    final university = universities[_random.nextInt(universities.length)];
    final position = positions[_random.nextInt(positions.length)];
    final personality = personalities[_random.nextInt(personalities.length)];
    final yearsAfterGraduation = _random.nextInt(4); // 0-3年（大学1-4年生相当）
    
    final isPitcher = position == '投手';
    
    if (isPitcher) {
      // 投手の能力値を生成（高校生より少し高い）
      final fastballVelo = 135 + _random.nextInt(20); // 135-155 km/h
      final control = 40 + _random.nextInt(41); // 40-80
      final stamina = 50 + _random.nextInt(41); // 50-90
      final breakAvg = 45 + _random.nextInt(41); // 45-85
      
      // 球種を生成
      final pitchTypes = ['直球', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ'];
      final pitches = <Pitch>[];
      
      // 直球は必ず習得
      pitches.add(Pitch(
        type: '直球',
        breakAmount: 15 + _random.nextInt(21), // 15-35
        breakPot: 20 + _random.nextInt(26), // 20-45
        unlocked: true,
      ));
      
      // 他の球種はランダムに習得
      for (final type in pitchTypes.skip(1)) {
        if (_random.nextBool()) {
          pitches.add(Pitch(
            type: type,
            breakAmount: 25 + _random.nextInt(41), // 25-65
            breakPot: 30 + _random.nextInt(51), // 30-80
            unlocked: true,
          ));
        }
      }
      
      return Player(
        name: name,
        school: university,
        grade: 0, // 大学生は学年を0に
        position: position,
        personality: personality,
        type: PlayerType.college,
        yearsAfterGraduation: yearsAfterGraduation,
        fastballVelo: fastballVelo,
        control: control,
        stamina: stamina,
        breakAvg: breakAvg,
        pitches: pitches,
        mentalGrit: (_random.nextDouble() - 0.5) * 0.3,
        growthRate: 0.85 + _random.nextDouble() * 0.3,
        peakAbility: 90 + _random.nextInt(61), // 90-150
        positionFit: _generatePositionFit(position, positions),
      );
    } else {
      // 野手の能力値を生成（高校生より少し高い）
      final batPower = 45 + _random.nextInt(41); // 45-85
      final batControl = 50 + _random.nextInt(41); // 50-90
      final run = 50 + _random.nextInt(41); // 50-90
      final field = 50 + _random.nextInt(41); // 50-90
      final arm = 45 + _random.nextInt(41); // 45-85
      
      return Player(
        name: name,
        school: university,
        grade: 0, // 大学生は学年を0に
        position: position,
        personality: personality,
        type: PlayerType.college,
        yearsAfterGraduation: yearsAfterGraduation,
        batPower: batPower,
        batControl: batControl,
        run: run,
        field: field,
        arm: arm,
        mentalGrit: (_random.nextDouble() - 0.5) * 0.3,
        growthRate: 0.85 + _random.nextDouble() * 0.3,
        peakAbility: 90 + _random.nextInt(61), // 90-150
        positionFit: _generatePositionFit(position, positions),
      );
    }
  }
  
  // 社会人選手を生成
  static Player _generateSocialPlayer() {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final companies = ['日本生命', '三菱重工', 'JR東日本', 'トヨタ自動車', 'NTT東日本', '富士通'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final personalities = ['真面目', '明るい', 'クール', 'リーダー', '努力家'];
    
    final name = names[_random.nextInt(names.length)] + 
                (_random.nextInt(999) + 1).toString().padLeft(3, '0');
    final company = companies[_random.nextInt(companies.length)];
    final position = positions[_random.nextInt(positions.length)];
    final personality = personalities[_random.nextInt(personalities.length)];
    final yearsAfterGraduation = 4 + _random.nextInt(5); // 4-8年（社会人1-5年目相当）
    
    final isPitcher = position == '投手';
    
    if (isPitcher) {
      // 投手の能力値を生成（大学生よりさらに高い）
      final fastballVelo = 140 + _random.nextInt(15); // 140-155 km/h
      final control = 50 + _random.nextInt(41); // 50-90
      final stamina = 60 + _random.nextInt(41); // 60-100
      final breakAvg = 55 + _random.nextInt(41); // 55-95
      
      // 球種を生成
      final pitchTypes = ['直球', 'カーブ', 'スライダー', 'フォーク', 'チェンジアップ'];
      final pitches = <Pitch>[];
      
      // 直球は必ず習得
      pitches.add(Pitch(
        type: '直球',
        breakAmount: 20 + _random.nextInt(21), // 20-40
        breakPot: 25 + _random.nextInt(26), // 25-50
        unlocked: true,
      ));
      
      // 他の球種はランダムに習得
      for (final type in pitchTypes.skip(1)) {
        if (_random.nextBool()) {
          pitches.add(Pitch(
            type: type,
            breakAmount: 30 + _random.nextInt(41), // 30-70
            breakPot: 35 + _random.nextInt(51), // 35-85
            unlocked: true,
          ));
        }
      }
      
      return Player(
        name: name,
        school: company,
        grade: 0, // 社会人は学年を0に
        position: position,
        personality: personality,
        type: PlayerType.social,
        yearsAfterGraduation: yearsAfterGraduation,
        fastballVelo: fastballVelo,
        control: control,
        stamina: stamina,
        breakAvg: breakAvg,
        pitches: pitches,
        mentalGrit: (_random.nextDouble() - 0.5) * 0.3,
        growthRate: 0.85 + _random.nextDouble() * 0.3,
        peakAbility: 95 + _random.nextInt(56), // 95-150
        positionFit: _generatePositionFit(position, positions),
      );
    } else {
      // 野手の能力値を生成（大学生よりさらに高い）
      final batPower = 55 + _random.nextInt(41); // 55-95
      final batControl = 60 + _random.nextInt(41); // 60-100
      final run = 55 + _random.nextInt(41); // 55-95
      final field = 60 + _random.nextInt(41); // 60-100
      final arm = 55 + _random.nextInt(41); // 55-95
      
      return Player(
        name: name,
        school: company,
        grade: 0, // 社会人は学年を0に
        position: position,
        personality: personality,
        type: PlayerType.social,
        yearsAfterGraduation: yearsAfterGraduation,
        batPower: batPower,
        batControl: batControl,
        run: run,
        field: field,
        arm: arm,
        mentalGrit: (_random.nextDouble() - 0.5) * 0.3,
        growthRate: 0.85 + _random.nextDouble() * 0.3,
        peakAbility: 95 + _random.nextInt(56), // 95-150
        positionFit: _generatePositionFit(position, positions),
      );
    }
  }
  
  // ポジション適性を生成
  static Map<String, int> _generatePositionFit(String mainPosition, List<String> allPositions) {
    final positionFit = <String, int>{};
    for (final pos in allPositions) {
      if (pos == mainPosition) {
        positionFit[pos] = 75 + _random.nextInt(21); // メインポジション 75-95
      } else {
        positionFit[pos] = 45 + _random.nextInt(31); // サブポジション 45-75
      }
    }
    return positionFit;
  }
} 