// ゲームのデータモデル
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_system.dart';

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

// 選手クラス
class Player {
  final String name;
  final String school;
  int grade; // 1年生、2年生、3年生
  final String position;
  final String personality;
  final int trustLevel; // 信頼度 0-100
  int fame; // 知名度 0-100
  bool isWatched; // スカウトが注目しているかどうか
  
  // 投手能力値（投手のみ）
  int? fastballVelo; // 球速 110-170 km/h
  int? control; // 制球 0-100
  int? stamina; // スタミナ 0-100
  int? breakAvg; // 変化 0-100
  List<Pitch>? pitches; // 球種
  
  // 野手能力値（野手のみ）
  int? batPower; // パワー 0-100
  int? batControl; // バットコントロール 0-100
  int? run; // 走力 0-100
  int? field; // 守備 0-100
  int? arm; // 肩 0-100
  
  // 隠し能力値
  final double mentalGrit; // 精神力 -0.15〜+0.15
  final double growthRate; // 成長スピード 0.85-1.15
  final int peakAbility; // ポテンシャル 80-150
  final Map<String, int> positionFit; // ポジション適性
  
  // スカウトの評価（個人評価）
  String? scoutEvaluation; // スカウトの個人評価
  String? scoutNotes; // スカウトのメモ
  
  Player({
    required this.name,
    required this.school,
    required this.grade,
    required this.position,
    required this.personality,
    this.trustLevel = 0,
    this.fame = 0,
    this.isWatched = false,
    this.fastballVelo,
    this.control,
    this.stamina,
    this.breakAvg,
    this.pitches,
    this.batPower,
    this.batControl,
    this.run,
    this.field,
    this.arm,
    required this.mentalGrit,
    required this.growthRate,
    required this.peakAbility,
    required this.positionFit,
    this.scoutEvaluation,
    this.scoutNotes,
  });
  
  // 投手かどうか
  bool get isPitcher => position == '投手';
  
  // 投手の球速スコア（0-100に換算）
  int get veloScore {
    if (!isPitcher || fastballVelo == null) return 0;
    return ((fastballVelo! - 110) * 1.6).round().clamp(0, 100);
  }
  
  // 真の総合能力値を計算（0-100）
  int get _trueTotalAbility {
    if (isPitcher) {
      final veloScore = this.veloScore;
      final controlScore = control ?? 0;
      final staminaScore = stamina ?? 0;
      final breakScore = breakAvg ?? 0;
      return ((veloScore + controlScore + staminaScore + breakScore) / 4).round();
    } else {
      final powerScore = batPower ?? 0;
      final controlScore = batControl ?? 0;
      final runScore = run ?? 0;
      final fieldScore = field ?? 0;
      final armScore = arm ?? 0;
      return ((powerScore + controlScore + runScore + fieldScore + armScore) / 5).round();
    }
  }
  
  // スカウトスキルに基づく能力値の表示範囲を取得
  int _getVisibleAbilityRange(int scoutSkill) {
    // スカウトスキルが高いほど正確な能力値が見える
    if (scoutSkill >= 80) return 5; // ±5の誤差
    if (scoutSkill >= 60) return 10; // ±10の誤差
    if (scoutSkill >= 40) return 20; // ±20の誤差
    if (scoutSkill >= 20) return 30; // ±30の誤差
    return 50; // ±50の誤差（ほぼ見えない）
  }
  
  // スカウトスキルに基づく表示能力値を取得
  int getVisibleAbility(int scoutSkill) {
    final trueAbility = _trueTotalAbility;
    final range = _getVisibleAbilityRange(scoutSkill);
    final random = Random();
    
    // スカウトスキルが低いほどランダム要素が強くなる
    final accuracy = scoutSkill / 100.0;
    final randomFactor = (1.0 - accuracy) * range;
    
    final visibleAbility = trueAbility + (random.nextDouble() - 0.5) * randomFactor * 2;
    return visibleAbility.round().clamp(0, 100);
  }
  
  // 一般的な評価（世間の評価）- 現時点の能力値から自動算出、確率的ブレあり
  String getGeneralEvaluation() {
    final ability = _trueTotalAbility;
    final random = Random();
    
    // 評価のブレ（±10%の確率的変動）
    final evaluationVariance = (random.nextDouble() - 0.5) * 0.2; // -10%〜+10%
    final adjustedAbility = ability * (1.0 + evaluationVariance);
    
    if (adjustedAbility > 85) return 'S';
    if (adjustedAbility > 70) return 'A';
    if (adjustedAbility > 55) return 'B';
    if (adjustedAbility > 40) return 'C';
    return 'D';
  }
  
  // ポテンシャル評価（スカウトの目利きが活きる）
  String getPotentialEvaluation(int scoutSkill) {
    final currentAbility = _trueTotalAbility;
    final potential = peakAbility;
    final random = Random();
    
    // スカウトスキルが高いほど正確なポテンシャルが見える
    final skillAccuracy = scoutSkill / 100.0;
    
    // 現在の能力値とポテンシャルの関係を分析
    final growthPotential = potential - currentAbility;
    final growthRate = growthPotential / 100.0; // 成長余地の割合
    
    // スカウトスキルに基づくポテンシャル推定
    final estimatedPotential = currentAbility + (growthPotential * skillAccuracy);
    
    // ランダム要素（スカウトの勘）
    final randomFactor = (random.nextDouble() - 0.5) * (1.0 - skillAccuracy) * 30;
    final finalEstimate = estimatedPotential + randomFactor;
    
    // ポテンシャル評価の基準
    if (finalEstimate > 120) return '超一流級の可能性';
    if (finalEstimate > 110) return '一流級の可能性';
    if (finalEstimate > 100) return '有望な可能性';
    if (finalEstimate > 90) return '成長の可能性あり';
    if (finalEstimate > 80) return 'やや期待できる';
    return '限定的な可能性';
  }
  
  // ポテンシャルの曖昧な表現（従来のメソッドを更新）
  String getPotentialDescription() {
    // スカウトスキル50をデフォルトとして使用
    return getPotentialEvaluation(50);
  }
  
  // スカウトの個人評価を設定
  void setScoutEvaluation(String evaluation, String notes) {
    scoutEvaluation = evaluation;
    scoutNotes = notes;
  }
  
  // 投手の総合評価（一般的評価）
  String getPitcherEvaluation() {
    if (!isPitcher) return 'N/A';
    return getGeneralEvaluation();
  }
  
  // 野手の総合評価（一般的評価）
  String getBatterEvaluation() {
    if (isPitcher) return 'N/A';
    return getGeneralEvaluation();
  }
  
  // 入学時の知名度を計算（学校の知名度と個人能力の組み合わせ）
  void calculateInitialFame() {
    final ability = _trueTotalAbility;
    final evaluation = getGeneralEvaluation();
    
    // 学校の知名度を考慮（有名校ほど基本知名度が高い）
    final schoolFame = _getSchoolFame();
    
    // 能力値に基づく個人知名度
    int personalFame = 0;
    if (evaluation == 'S') personalFame = 60;
    else if (evaluation == 'A') personalFame = 40;
    else if (evaluation == 'B') personalFame = 20;
    else if (evaluation == 'C') personalFame = 10;
    else personalFame = 5;
    
    // 学年による調整（上級生ほど注目される）
    final gradeBonus = (grade - 1) * 5;
    
    // 投手の球速による追加知名度
    int veloBonus = 0;
    if (isPitcher && fastballVelo != null) {
      if (fastballVelo! >= 150) veloBonus = 15;
      else if (fastballVelo! >= 145) veloBonus = 10;
      else if (fastballVelo! >= 140) veloBonus = 5;
    }
    
    // ランダム要素（無名校から優秀な選手が現れる可能性）
    final random = Random();
    final randomFactor = random.nextDouble() * 20 - 10; // -10〜+10
    
    // 学校の知名度と個人能力を組み合わせ
    final baseFame = (schoolFame * 0.6 + personalFame * 0.4).round();
    fame = (baseFame + gradeBonus + veloBonus + randomFactor.round()).clamp(0, 100);
  }
  
  // 学校の知名度を取得
  int _getSchoolFame() {
    // 実際の実装では学校クラスに知名度フィールドを追加する
    // ここでは学校名から簡易的に計算
    final schoolNames = ['甲子園高校', '野球名門校', '強豪校', '中堅校', '弱小校'];
    final schoolFameMap = {
      '甲子園高校': 90,
      '野球名門校': 70,
      '強豪校': 50,
      '中堅校': 30,
      '弱小校': 10,
    };
    
    // 学校名に含まれるキーワードで判定
    for (final key in schoolFameMap.keys) {
      if (school.contains(key)) {
        return schoolFameMap[key]!;
      }
    }
    
    // デフォルトは中堅校レベル
    return 30;
  }
  
  // 選手の成長
  void grow() {
    final growthChance = (mentalGrit + 0.15) * growthRate * 0.1;
    
    if (Random().nextDouble() < growthChance) {
      if (isPitcher) {
        _growPitcher();
      } else {
        _growBatter();
      }
      
      // 成長に伴う知名度上昇
      if (fame < 100) {
        fame = (fame + Random().nextInt(3) + 1).clamp(0, 100);
      }
    }
  }
  
  void _growPitcher() {
    if (control != null && control! < peakAbility) {
      control = (control! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (stamina != null && stamina! < peakAbility) {
      stamina = (stamina! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (breakAvg != null && breakAvg! < peakAbility) {
      breakAvg = (breakAvg! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    // 球速は高校生では成長しにくい
    if (fastballVelo != null && Random().nextDouble() < 0.1) {
      fastballVelo = (fastballVelo! + Random().nextInt(2) + 1).clamp(110, 155);
    }
  }
  
  void _growBatter() {
    if (batPower != null && batPower! < peakAbility) {
      batPower = (batPower! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (batControl != null && batControl! < peakAbility) {
      batControl = (batControl! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (run != null && run! < peakAbility) {
      run = (run! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (field != null && field! < peakAbility) {
      field = (field! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
    if (arm != null && arm! < peakAbility) {
      arm = (arm! + Random().nextInt(3) + 1).clamp(0, peakAbility);
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'school': school,
    'grade': grade,
    'position': position,
    'personality': personality,
    'trustLevel': trustLevel,
    'fame': fame,
    'isWatched': isWatched,
    'fastballVelo': fastballVelo,
    'control': control,
    'stamina': stamina,
    'breakAvg': breakAvg,
    'pitches': pitches?.map((p) => p.toJson()).toList(),
    'batPower': batPower,
    'batControl': batControl,
    'run': run,
    'field': field,
    'arm': arm,
    'mentalGrit': mentalGrit,
    'growthRate': growthRate,
    'peakAbility': peakAbility,
    'positionFit': positionFit,
    'scoutEvaluation': scoutEvaluation,
    'scoutNotes': scoutNotes,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    name: json['name'],
    school: json['school'],
    grade: json['grade'],
    position: json['position'],
    personality: json['personality'],
    trustLevel: json['trustLevel'] ?? 0,
    fame: json['fame'] ?? 0,
    isWatched: json['isWatched'] ?? false,
    fastballVelo: json['fastballVelo'],
    control: json['control'],
    stamina: json['stamina'],
    breakAvg: json['breakAvg'],
    pitches: json['pitches'] != null 
      ? (json['pitches'] as List).map((p) => Pitch.fromJson(p)).toList()
      : null,
    batPower: json['batPower'],
    batControl: json['batControl'],
    run: json['run'],
    field: json['field'],
    arm: json['arm'],
    mentalGrit: (json['mentalGrit'] as num).toDouble(),
    growthRate: (json['growthRate'] as num).toDouble(),
    peakAbility: json['peakAbility'],
    positionFit: Map<String, int>.from(json['positionFit']),
    scoutEvaluation: json['scoutEvaluation'],
    scoutNotes: json['scoutNotes'],
  );
}

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
  
  Player _generateNewPlayer(int grade) {
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

// スカウトの能力クラス
class ScoutSkills {
  int exploration; // 探索 (0-100)
  int observation; // 観察 (0-100)
  int analysis; // 分析 (0-100)
  int insight; // 洞察 (0-100)
  int communication; // コミュニケーション (0-100)
  int negotiation; // 交渉 (0-100)
  int stamina; // 体力 (0-100)
  
  ScoutSkills({
    this.exploration = 50,
    this.observation = 50,
    this.analysis = 50,
    this.insight = 50,
    this.communication = 50,
    this.negotiation = 50,
    this.stamina = 50,
  });
  
  // スキルを取得
  int getSkill(String skillName) {
    switch (skillName) {
      case 'exploration': return exploration;
      case 'observation': return observation;
      case 'analysis': return analysis;
      case 'insight': return insight;
      case 'communication': return communication;
      case 'negotiation': return negotiation;
      case 'stamina': return stamina;
      default: return 50;
    }
  }
  
  // スキルを設定
  void setSkill(String skillName, int value) {
    final clampedValue = value.clamp(0, 100);
    switch (skillName) {
      case 'exploration': exploration = clampedValue; break;
      case 'observation': observation = clampedValue; break;
      case 'analysis': analysis = clampedValue; break;
      case 'insight': insight = clampedValue; break;
      case 'communication': communication = clampedValue; break;
      case 'negotiation': negotiation = clampedValue; break;
      case 'stamina': stamina = clampedValue; break;
    }
  }
  
  // スキルを上昇
  void improveSkill(String skillName, int amount) {
    final currentSkill = getSkill(skillName);
    setSkill(skillName, currentSkill + amount);
  }
  
  Map<String, dynamic> toJson() => {
    'exploration': exploration,
    'observation': observation,
    'analysis': analysis,
    'insight': insight,
    'communication': communication,
    'negotiation': negotiation,
    'stamina': stamina,
  };
  
  factory ScoutSkills.fromJson(Map<String, dynamic> json) => ScoutSkills(
    exploration: json['exploration'] ?? 50,
    observation: json['observation'] ?? 50,
    analysis: json['analysis'] ?? 50,
    insight: json['insight'] ?? 50,
    communication: json['communication'] ?? 50,
    negotiation: json['negotiation'] ?? 50,
    stamina: json['stamina'] ?? 50,
  );
}

// スカウトアクションクラス
class ScoutingAction {
  final String id;
  final String name;
  final int apCost;
  final int budgetCost;
  final String description;
  final String category;
  final List<String> requiredSkills; // 必要なスキル
  final List<String> primarySkills; // 主に使用するスキル
  final double baseSuccessRate; // 基本成功率
  final Map<String, double> skillModifiers; // スキル補正
  
  ScoutingAction({
    required this.id,
    required this.name,
    required this.apCost,
    required this.budgetCost,
    required this.description,
    required this.category,
    required this.requiredSkills,
    required this.primarySkills,
    required this.baseSuccessRate,
    required this.skillModifiers,
  });
  
  // 成功判定を計算
  bool calculateSuccess(ScoutSkills skills) {
    final random = Random();
    double successRate = baseSuccessRate;
    
    // スキル補正を適用
    for (final skillName in skillModifiers.keys) {
      final skillValue = skills.getSkill(skillName);
      final modifier = skillModifiers[skillName]!;
      successRate += (skillValue / 100.0) * modifier;
    }
    
    // 体力による疲労ペナルティ
    final staminaPenalty = (100 - skills.stamina) * 0.001; // 体力が低いほど成功率が下がる
    successRate -= staminaPenalty;
    
    return random.nextDouble() < successRate;
  }
  
  // アクションが実行可能かチェック
  bool canExecute(ScoutSkills skills, int currentAp, int currentBudget) {
    if (currentAp < apCost) return false;
    if (currentBudget < budgetCost) return false;
    
    // 必要なスキルをチェック（最低20に緩和）
    for (final skillName in requiredSkills) {
      if (skills.getSkill(skillName) < 20) return false; // 最低20は必要
    }
    
    return true;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'apCost': apCost,
    'budgetCost': budgetCost,
    'description': description,
    'category': category,
    'requiredSkills': requiredSkills,
    'primarySkills': primarySkills,
    'baseSuccessRate': baseSuccessRate,
    'skillModifiers': skillModifiers,
  };
  
  factory ScoutingAction.fromJson(Map<String, dynamic> json) => ScoutingAction(
    id: json['id'],
    name: json['name'],
    apCost: json['apCost'],
    budgetCost: json['budgetCost'],
    description: json['description'],
    category: json['category'],
    requiredSkills: List<String>.from(json['requiredSkills']),
    primarySkills: List<String>.from(json['primarySkills']),
    baseSuccessRate: json['baseSuccessRate'].toDouble(),
    skillModifiers: Map<String, double>.from(json['skillModifiers']),
  );
}

// ニュースアイテムクラス
class NewsItem {
  final String headline; // 見出し
  final String content; // 本文
  final String category; // カテゴリ
  final int importance; // 重要度 1-5
  final String icon; // アイコン
  final DateTime timestamp; // タイムスタンプ
  final String? school; // 関連学校
  final String? player; // 関連選手
  
  NewsItem({
    required this.headline,
    required this.content,
    required this.category,
    required this.importance,
    required this.icon,
    required this.timestamp,
    this.school,
    this.player,
  });
  
  // 重要度に応じた色を取得
  Color getImportanceColor() {
    switch (importance) {
      case 5: return Colors.red;
      case 4: return Colors.orange;
      case 3: return Colors.yellow;
      case 2: return Colors.blue;
      case 1: return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  // カテゴリに応じた色を取得
  Color getCategoryColor() {
    switch (category) {
      case '試合': return Colors.red;
      case '選手': return Colors.blue;
      case '学校': return Colors.green;
      case 'スカウト': return Colors.purple;
      case '一般': return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'headline': headline,
    'content': content,
    'category': category,
    'importance': importance,
    'icon': icon,
    'timestamp': timestamp.toIso8601String(),
    'school': school,
    'player': player,
  };
  
  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    headline: json['headline'],
    content: json['content'],
    category: json['category'],
    importance: json['importance'],
    icon: json['icon'],
    timestamp: DateTime.parse(json['timestamp']),
    school: json['school'],
    player: json['player'],
  );
}

// スカウトアクションの結果クラス
class ActionResult {
  final String actionName;
  final String result;
  final String school;
  final String? player;
  final int apUsed;
  final int budgetUsed;
  final DateTime timestamp;
  final bool success;
  final Map<String, dynamic>? additionalData; // 追加データ（発見した選手、得た情報など）
  
  ActionResult({
    required this.actionName,
    required this.result,
    required this.school,
    this.player,
    required this.apUsed,
    required this.budgetUsed,
    required this.timestamp,
    required this.success,
    this.additionalData,
  });
  
  Map<String, dynamic> toJson() => {
    'actionName': actionName,
    'result': result,
    'school': school,
    'player': player,
    'apUsed': apUsed,
    'budgetUsed': budgetUsed,
    'timestamp': timestamp.toIso8601String(),
    'success': success,
    'additionalData': additionalData,
  };
  
  factory ActionResult.fromJson(Map<String, dynamic> json) => ActionResult(
    actionName: json['actionName'],
    result: json['result'],
    school: json['school'],
    player: json['player'],
    apUsed: json['apUsed'],
    budgetUsed: json['budgetUsed'],
    timestamp: DateTime.parse(json['timestamp']),
    success: json['success'],
    additionalData: json['additionalData'] != null ? Map<String, dynamic>.from(json['additionalData']) : null,
  );
}

// スカウトアクションの対象クラス
class ScoutingTarget {
  final String type; // 'school', 'player', 'region', 'team'
  final String name;
  final String? description;
  final Map<String, dynamic>? metadata;
  
  ScoutingTarget({
    required this.type,
    required this.name,
    this.description,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'description': description,
    'metadata': metadata,
  };
  
  factory ScoutingTarget.fromJson(Map<String, dynamic> json) => ScoutingTarget(
    type: json['type'],
    name: json['name'],
    description: json['description'],
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
  );
}

// 今週の予定クラス
class ScheduleItem {
  final String title;
  final String description;
  final String school;
  final String type; // '試合', '練習', '大会', '視察'
  final DateTime scheduledTime;
  final int importance; // 1-5
  
  ScheduleItem({
    required this.title,
    required this.description,
    required this.school,
    required this.type,
    required this.scheduledTime,
    required this.importance,
  });
  
  Color getTypeColor() {
    switch (type) {
      case '試合': return Colors.red;
      case '練習': return Colors.blue;
      case '大会': return Colors.orange;
      case '視察': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'school': school,
    'type': type,
    'scheduledTime': scheduledTime.toIso8601String(),
    'importance': importance,
  };
  
  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
    title: json['title'],
    description: json['description'],
    school: json['school'],
    type: json['type'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    importance: json['importance'],
  );
}

// アクション結果クラス
class ActionResultData {
  final String message;
  final Map<String, dynamic>? additionalData;
  
  ActionResultData(this.message, [this.additionalData]);
}

// ゲーム状態クラス
class GameState {
  int currentWeek;
  int currentYear;
  int actionPoints;
  int budget;
  int reputation;
  List<School> schools;
  List<Player> discoveredPlayers;
  List<NewsItem> news;
  List<ActionResult> lastWeekActions; // 先週のアクション結果
  List<ScheduleItem> thisWeekSchedule; // 今週の予定
  List<GameResult> gameResults; // 試合結果
  ScoutSkills scoutSkills; // スカウトの能力
  
  GameState({
    this.currentWeek = 1,
    this.currentYear = 2025,
    this.actionPoints = 6,
    this.budget = 1000000,
    this.reputation = 0,
    List<School>? schools,
    List<Player>? discoveredPlayers,
    List<NewsItem>? news,
    List<ActionResult>? lastWeekActions,
    List<ScheduleItem>? thisWeekSchedule,
    List<GameResult>? gameResults,
    ScoutSkills? scoutSkills,
  }) : 
    schools = schools ?? [],
    discoveredPlayers = discoveredPlayers ?? [],
    news = news ?? [],
    lastWeekActions = lastWeekActions ?? [],
    thisWeekSchedule = thisWeekSchedule ?? [],
    gameResults = gameResults ?? [],
    scoutSkills = scoutSkills ?? ScoutSkills() {
    
    // 既存選手の知名度を計算
    for (final school in this.schools) {
      for (final player in school.players) {
        player.calculateInitialFame();
      }
    }
    
    // 発見済み選手の知名度も計算
    for (final player in this.discoveredPlayers) {
      player.calculateInitialFame();
    }
  }
  
  // 週から月を計算
  String getCurrentMonth() {
    // 各月の週数（4月から3月まで）
    final weeksPerMonth = [4, 4, 5, 4, 4, 5, 5, 4, 4, 4, 4, 5]; // 4月-3月
    final monthNames = [
      '4月', '5月', '6月', '7月', '8月', '9月', 
      '10月', '11月', '12月', '1月', '2月', '3月'
    ];
    
    int weekCount = 0;
    for (int i = 0; i < weeksPerMonth.length; i++) {
      weekCount += weeksPerMonth[i];
      if (currentWeek <= weekCount) {
        return monthNames[i];
      }
    }
    return '3月'; // フォールバック
  }
  
  // 月内での週数を計算
  int getWeekInMonth() {
    // 各月の週数（4月から3月まで）
    final weeksPerMonth = [4, 4, 5, 4, 4, 5, 5, 4, 4, 4, 4, 5]; // 4月-3月
    
    int weekCount = 0;
    for (int i = 0; i < weeksPerMonth.length; i++) {
      weekCount += weeksPerMonth[i];
      if (currentWeek <= weekCount) {
        return currentWeek - (weekCount - weeksPerMonth[i]);
      }
    }
    return currentWeek; // フォールバック
  }
  
  // 週を進める
  void advanceWeek() {
    // 先週のアクション結果を保存
    _saveLastWeekActions();
    
    // 3月1週目で卒業処理
    if (currentWeek == 49) { // 3月1週目（4+4+5+4+4+5+5+4+4+4+4+1 = 49週目）
      _processGraduation();
    }
    
    currentWeek++;
    
    // 4月1週目で入学処理
    if (currentWeek == 1) {
      _processEnrollment();
    }
    
    if (currentWeek > 52) {
      currentWeek = 1;
      currentYear++;
    }
    
    // APと予算をリセット
    actionPoints = 6;
    budget = 1000000;
    
    // 今週の予定を生成
    _generateThisWeekSchedule();
    
    // ニュースを生成
    _generateNews();
  }
  
  // 先週のアクション結果を保存
  void _saveLastWeekActions() {
    // 実際のアクション結果は、プレイヤーがアクションを実行した際に追加される
    // ここでは空のリストにリセット
    lastWeekActions.clear();
  }
  
  // 今週の予定を生成
  void _generateThisWeekSchedule() {
    thisWeekSchedule.clear();
    final random = Random();
    
    // 練習試合の予定
    if (random.nextBool()) {
      final school1 = schools[random.nextInt(schools.length)];
      final school2 = schools[random.nextInt(schools.length)];
      if (school1 != school2) {
        thisWeekSchedule.add(ScheduleItem(
          title: '${school1.name} vs ${school2.name}',
          description: '練習試合が予定されています。選手の実力を確認するチャンスです。',
          school: '${school1.name}・${school2.name}',
          type: '試合',
          scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
          importance: 4,
        ));
        
        // 試合結果を自動生成
        final gameResult = GameSimulator.simulateGame(school1, school2, '練習試合');
        gameResults.add(gameResult);
      }
    }
    
    // 大会の予定（月によって）
    final currentMonth = getCurrentMonth();
    if (currentMonth == '6月' || currentMonth == '7月' || currentMonth == '8月') {
      if (random.nextBool()) {
        final school = schools[random.nextInt(schools.length)];
        final opponent = schools[random.nextInt(schools.length)];
        if (school != opponent) {
          thisWeekSchedule.add(ScheduleItem(
            title: '夏の大会',
            description: '${school.name}が夏の大会に出場します。',
            school: school.name,
            type: '大会',
            scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
            importance: 5,
          ));
          
          // 大会の試合結果を自動生成
          final gameResult = GameSimulator.simulateGame(school, opponent, '大会');
          gameResults.add(gameResult);
        }
      }
    }
    
    // 練習視察の予定
    if (random.nextBool()) {
      final school = schools[random.nextInt(schools.length)];
      thisWeekSchedule.add(ScheduleItem(
        title: '${school.name}練習視察',
        description: '${school.name}の練習を視察する予定です。',
        school: school.name,
        type: '視察',
        scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
        importance: 3,
      ));
    }
    
    // 一般練習の予定
    if (random.nextBool()) {
      final school = schools[random.nextInt(schools.length)];
      thisWeekSchedule.add(ScheduleItem(
        title: '${school.name}練習',
        description: '${school.name}の通常練習が行われます。',
        school: school.name,
        type: '練習',
        scheduledTime: DateTime.now().add(Duration(days: random.nextInt(7))),
        importance: 2,
      ));
    }
  }
  
  // アクション結果を追加
  void addActionResult(ActionResult result) {
    lastWeekActions.add(result);
  }
  
  // 卒業処理（3月1週目）
  void _processGraduation() {
    news.add(NewsItem(
      headline: '🎓 卒業シーズンが始まりました',
      content: '',
      category: '学校',
      importance: 5,
      icon: '🎓',
      timestamp: DateTime.now(),
    ));
    
    for (var school in schools) {
      final graduatingPlayers = school.players.where((player) => player.grade == 3).toList();
      if (graduatingPlayers.isNotEmpty) {
        final topPlayer = graduatingPlayers.reduce((a, b) => 
          (a.isPitcher ? a.getPitcherEvaluation() : a.getBatterEvaluation()).compareTo(
            b.isPitcher ? b.getPitcherEvaluation() : b.getBatterEvaluation()
          ) > 0 ? a : b);
        news.add(NewsItem(
          headline: '${school.name}の${topPlayer.name}選手が卒業します',
          content: '',
          category: '学校',
          importance: 5,
          icon: '🎓',
          timestamp: DateTime.now(),
        ));
      }
    }
  }
  
  // 入学処理（4月1週目）
  void _processEnrollment() {
    news.add(NewsItem(
      headline: '🆕 新年度が始まりました！',
      content: '',
      category: '学校',
      importance: 5,
      icon: '🆕',
      timestamp: DateTime.now(),
    ));
    
    for (var school in schools) {
      // 3年生を削除（卒業）
      school.players.removeWhere((player) => player.grade == 3);
      
      // 1年生、2年生を進級
      for (var player in school.players) {
        if (player.grade < 3) {
          player.grade++;
          // 進級時に少し成長
          player.grow();
        }
      }
      
      // 新しい1年生を追加（入学）
      final newStudentCount = Random().nextInt(4) + 4; // 4-7名の新入生
      for (int i = 0; i < newStudentCount; i++) {
        school.players.add(school._generateNewPlayer(1));
      }
      
      news.add(NewsItem(
        headline: '${school.name}に${newStudentCount}名の新入生が入学しました',
        content: '',
        category: '学校',
        importance: 5,
        icon: '🆕',
        timestamp: DateTime.now(),
      ));
    }
    
    // 古いニュースを削除（最大15件まで）
    if (news.length > 15) {
      news.removeRange(0, news.length - 15);
    }
  }
  
  void _startNewYear() {
    // このメソッドは使用しない（_processGraduationと_processEnrollmentに分離）
  }
  
  void _generateNews() {
    final random = Random();
    
    // 実際のゲーム状態に基づくニュースを優先的に生成
    final dynamicNews = _generateDynamicNews();
    if (dynamicNews != null) {
      news.add(dynamicNews);
    } else {
      // 動的ニュースがない場合は通常のテンプレートニュースを生成
      _generateTemplateNews();
    }
    
    // 古いニュースを削除（最大15件まで）
    if (news.length > 15) {
      news.removeAt(0);
    }
  }
  
  // 実際のゲーム状態に基づくニュースを生成
  NewsItem? _generateDynamicNews() {
    final random = Random();
    
    // 1. 試合結果に基づくニュース
    if (gameResults.isNotEmpty) {
      final recentGame = gameResults.last;
      final gameAge = DateTime.now().difference(recentGame.gameDate).inDays;
      
      if (gameAge <= 7) { // 1週間以内の試合
        return _generateGameResultNews(recentGame);
      }
    }
    
    // 2. 選手の成績に基づくニュース
    final topPerformers = _findTopPerformers();
    if (topPerformers.isNotEmpty && random.nextBool()) {
      return _generatePlayerPerformanceNews(topPerformers);
    }
    
    // 3. 学校の強さに基づくニュース
    final strongSchools = _findStrongSchools();
    if (strongSchools.isNotEmpty && random.nextBool()) {
      return _generateSchoolStrengthNews(strongSchools);
    }
    
    // 4. 選手の成長に基づくニュース
    final growingPlayers = _findGrowingPlayers();
    if (growingPlayers.isNotEmpty && random.nextBool()) {
      return _generatePlayerGrowthNews(growingPlayers);
    }
    
    return null;
  }
  
  // 試合結果に基づくニュースを生成
  NewsItem _generateGameResultNews(GameResult game) {
    final random = Random();
    
    if (game.homeScore > game.awayScore) {
      // ホームチーム勝利
      final winner = schools.firstWhere((s) => s.name == game.homeTeam);
      final loser = schools.firstWhere((s) => s.name == game.awayTeam);
      
      if (game.homeScore - game.awayScore >= 5) {
        return NewsItem(
          headline: '🔥 ${winner.name}が${loser.name}に大勝！',
          content: '${game.homeScore}-${game.awayScore}の圧勝。${winner.name}の打線が爆発し、投手陣も好投を見せました。',
          category: '試合',
          importance: 4,
          icon: '🔥',
          timestamp: DateTime.now(),
          school: winner.name,
        );
      } else {
        return NewsItem(
          headline: '⚾ ${winner.name}が${loser.name}を下す',
          content: '${game.homeScore}-${game.awayScore}で${winner.name}が勝利。接戦を制した${winner.name}の粘り強さが光りました。',
          category: '試合',
          importance: 3,
          icon: '⚾',
          timestamp: DateTime.now(),
          school: winner.name,
        );
      }
    } else {
      // アウェイチーム勝利
      final winner = schools.firstWhere((s) => s.name == game.awayTeam);
      final loser = schools.firstWhere((s) => s.name == game.homeTeam);
      
      return NewsItem(
        headline: '⚾ ${winner.name}が${loser.name}を破る',
        content: '${game.awayScore}-${game.homeScore}で${winner.name}が勝利。アウェイでの勝利で${winner.name}の実力が証明されました。',
        category: '試合',
        importance: 3,
        icon: '⚾',
        timestamp: DateTime.now(),
        school: winner.name,
      );
    }
  }
  
  // トップパフォーマーを探す
  List<PlayerPerformance> _findTopPerformers() {
    final allPerformances = <PlayerPerformance>[];
    
    for (final game in gameResults) {
      allPerformances.addAll(game.performances);
    }
    
    if (allPerformances.isEmpty) return [];
    
    // 投手のトップパフォーマー
    final topPitchers = allPerformances
        .where((p) => (p.inningsPitched ?? 0) > 0)
        .toList()
      ..sort((a, b) => ((b.strikeouts ?? 0) / (b.inningsPitched ?? 1)).compareTo((a.strikeouts ?? 0) / (a.inningsPitched ?? 1)));
    
    // 野手のトップパフォーマー
    final topBatters = allPerformances
        .where((p) => (p.atBats ?? 0) > 0)
        .toList()
      ..sort((a, b) => (b.battingAverage ?? 0).compareTo(a.battingAverage ?? 0));
    
    final topPerformers = <PlayerPerformance>[];
    if (topPitchers.isNotEmpty) topPerformers.add(topPitchers.first);
    if (topBatters.isNotEmpty) topPerformers.add(topBatters.first);
    
    return topPerformers;
  }
  
  // 選手の成績に基づくニュースを生成
  NewsItem _generatePlayerPerformanceNews(List<PlayerPerformance> topPerformers) {
    final performance = topPerformers.first;
    
    if ((performance.inningsPitched ?? 0) > 0) {
      // 投手のニュース
      final kPer9 = ((performance.strikeouts ?? 0) * 9.0) / (performance.inningsPitched ?? 1);
      if (kPer9 >= 10) {
        return NewsItem(
          headline: '🔥 ${performance.playerName}選手が奪三振記録を樹立！',
          content: '${performance.school}の${performance.playerName}選手が9回${performance.strikeouts}奪三振の圧巻の投球。奪三振率${kPer9.toStringAsFixed(1)}を記録しました。',
          category: '選手',
          importance: 4,
          icon: '🔥',
          timestamp: DateTime.now(),
          school: performance.school,
          player: performance.playerName,
        );
      }
    } else if ((performance.atBats ?? 0) > 0) {
      // 野手のニュース
      final avg = performance.battingAverage ?? 0;
      if (avg >= 0.400) {
        return NewsItem(
          headline: '⭐ ${performance.playerName}選手が打率4割を達成！',
          content: '${performance.school}の${performance.playerName}選手が打率${(avg * 100).toStringAsFixed(1)}%を記録。プロ野球界から注目を集めています。',
          category: '選手',
          importance: 4,
          icon: '⭐',
          timestamp: DateTime.now(),
          school: performance.school,
          player: performance.playerName,
        );
      } else if ((performance.homeRuns ?? 0) >= 2) {
        return NewsItem(
          headline: '💪 ${performance.playerName}選手が本塁打を連発！',
          content: '${performance.school}の${performance.playerName}選手が${performance.homeRuns}本の本塁打を放ち、打線の中心として活躍しました。',
          category: '選手',
          importance: 3,
          icon: '💪',
          timestamp: DateTime.now(),
          school: performance.school,
          player: performance.playerName,
        );
      }
    }
    
    // デフォルトの選手ニュース
    return NewsItem(
      headline: '⭐ ${performance.playerName}選手が好成績',
      content: '${performance.school}の${performance.playerName}選手が注目の活躍を見せています。',
      category: '選手',
      importance: 3,
      icon: '⭐',
      timestamp: DateTime.now(),
      school: performance.school,
      player: performance.playerName,
    );
  }
  
  // 強い学校を探す
  List<School> _findStrongSchools() {
    final schoolStrength = <School, double>{};
    
    for (final school in schools) {
      double strength = 0;
      
      // 投手の強さ
      final pitchers = school.players.where((p) => p.isPitcher).toList();
      for (final pitcher in pitchers) {
        strength += (pitcher.control ?? 50) + (pitcher.stamina ?? 50) + pitcher.veloScore + (pitcher.breakAvg ?? 50);
      }
      
      // 野手の強さ
      final batters = school.players.where((p) => !p.isPitcher).toList();
      for (final batter in batters) {
        strength += (batter.batPower ?? 50) + (batter.batControl ?? 50) + (batter.run ?? 50) + (batter.field ?? 50) + (batter.arm ?? 50);
      }
      
      schoolStrength[school] = strength;
    }
    
    final sortedSchools = schoolStrength.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSchools.take(3).map((e) => e.key).toList();
  }
  
  // 学校の強さに基づくニュースを生成
  NewsItem _generateSchoolStrengthNews(List<School> strongSchools) {
    final school = strongSchools.first;
    final topPlayer = school.players.reduce((a, b) {
      final aScore = a.isPitcher ? (a.control ?? 0) + (a.stamina ?? 0) + a.veloScore + (a.breakAvg ?? 0) 
                                 : (a.batPower ?? 0) + (a.batControl ?? 0) + (a.run ?? 0) + (a.field ?? 0) + (a.arm ?? 0);
      final bScore = b.isPitcher ? (b.control ?? 0) + (b.stamina ?? 0) + b.veloScore + (b.breakAvg ?? 0)
                                 : (b.batPower ?? 0) + (b.batControl ?? 0) + (b.run ?? 0) + (b.field ?? 0) + (b.arm ?? 0);
      return aScore > bScore ? a : b;
    });
    
    return NewsItem(
      headline: '🏆 ${school.name}が最強チームとして注目',
      content: '${school.name}が選手層の厚さで他校を圧倒。特に${topPlayer.name}選手を中心としたチーム力が評価されています。',
      category: '学校',
      importance: 4,
      icon: '🏆',
      timestamp: DateTime.now(),
      school: school.name,
      player: topPlayer.name,
    );
  }
  
  // 成長している選手を探す
  List<Player> _findGrowingPlayers() {
    final growingPlayers = <Player>[];
    
    for (final school in schools) {
      for (final player in school.players) {
        // 最近成長した選手を判定（実際の成長ロジックに基づく）
        if (player.mentalGrit > 0.1 && player.growthRate > 1.0) {
          growingPlayers.add(player);
        }
      }
    }
    
    return growingPlayers;
  }
  
  // 選手の成長に基づくニュースを生成
  NewsItem _generatePlayerGrowthNews(List<Player> growingPlayers) {
    final player = growingPlayers.first;
    
    return NewsItem(
      headline: '📈 ${player.name}選手が急成長中',
      content: '${player.school}の${player.name}選手が練習での成果を実感。能力向上が期待されています。',
      category: '選手',
      importance: 3,
      icon: '📈',
      timestamp: DateTime.now(),
      school: player.school,
      player: player.name,
    );
  }
  
  // テンプレートベースのニュースを生成（従来の方法）
  void _generateTemplateNews() {
    final random = Random();
    final newsTemplates = [
      // 試合関連ニュース
      {
        'headline': '⚾ ${schools[random.nextInt(schools.length)].name}が練習試合で勝利',
        'content': '投手陣の好投と打線の爆発で圧勝。来季への期待が高まっています。',
        'category': '試合',
        'importance': 3,
        'icon': '⚾',
      },
      {
        'headline': '🔥 新記録が誕生！${schools[random.nextInt(schools.length)].name}の投手が完封',
        'content': '9回無失点、奪三振15個の圧巻の投球で新記録を樹立しました。',
        'category': '試合',
        'importance': 4,
        'icon': '🔥',
      },
      // 選手関連ニュース
      {
        'headline': '⭐ ${schools[random.nextInt(schools.length)].name}の${_getRandomPlayerName()}選手が注目',
        'content': '打率.350、本塁打8本の好成績でプロ野球界から注目を集めています。',
        'category': '選手',
        'importance': 4,
        'icon': '⭐',
      },
      {
        'headline': '💪 ${_getRandomPlayerName()}選手が怪我から復帰',
        'content': '3ヶ月のリハビリを経て、今週末の試合から復帰予定です。',
        'category': '選手',
        'importance': 3,
        'icon': '💪',
      },
      // 学校関連ニュース
      {
        'headline': '🏫 ${schools[random.nextInt(schools.length)].name}に新監督就任',
        'content': '元プロ野球選手の新監督が就任し、チーム改革が始まります。',
        'category': '学校',
        'importance': 3,
        'icon': '🏫',
      },
      {
        'headline': '📚 ${schools[random.nextInt(schools.length)].name}が野球部強化',
        'content': '新たな練習施設の建設が決定し、来年度からの強化が期待されます。',
        'category': '学校',
        'importance': 2,
        'icon': '📚',
      },
      // スカウト関連ニュース
      {
        'headline': '👀 他球団スカウトが${schools[random.nextInt(schools.length)].name}を視察',
        'content': '複数のプロ野球球団のスカウトが同校の選手を視察に訪れました。',
        'category': 'スカウト',
        'importance': 4,
        'icon': '👀',
      },
      {
        'headline': '📊 スカウトレポートが更新されました',
        'content': '最新の選手評価データが公開され、注目選手の情報が更新されています。',
        'category': 'スカウト',
        'importance': 2,
        'icon': '📊',
      },
      // 一般ニュース
      {
        'headline': '🌤️ 好天候で練習環境が良好',
        'content': '今週は晴天が続き、各校の練習が順調に進んでいます。',
        'category': '一般',
        'importance': 1,
        'icon': '🌤️',
      },
      {
        'headline': '📺 高校野球特集番組が放送予定',
        'content': '今週末のテレビ番組で注目選手特集が放送されます。',
        'category': '一般',
        'importance': 2,
        'icon': '📺',
      },
    ];
    
    final selectedNews = newsTemplates[random.nextInt(newsTemplates.length)];
    final newsItem = NewsItem(
      headline: selectedNews['headline'] as String,
      content: selectedNews['content'] as String,
      category: selectedNews['category'] as String,
      importance: selectedNews['importance'] as int,
      icon: selectedNews['icon'] as String,
      timestamp: DateTime.now(),
      school: (selectedNews['headline'] as String).contains('高校') ? 
        schools[random.nextInt(schools.length)].name : null,
    );
    
    news.add(newsItem);
  }
  
  String _getRandomPlayerName() {
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    return names[Random().nextInt(names.length)] + 
           (Random().nextInt(999) + 1).toString().padLeft(3, '0');
  }

  Map<String, dynamic> toJson() => {
    'currentWeek': currentWeek,
    'currentYear': currentYear,
    'actionPoints': actionPoints,
    'budget': budget,
    'reputation': reputation,
    'schools': schools.map((s) => s.toJson()).toList(),
    'discoveredPlayers': discoveredPlayers.map((p) => p.toJson()).toList(),
    'news': news.map((n) => n.toJson()).toList(),
    'lastWeekActions': lastWeekActions.map((a) => a.toJson()).toList(),
    'thisWeekSchedule': thisWeekSchedule.map((s) => s.toJson()).toList(),
    'gameResults': gameResults.map((g) => g.toJson()).toList(),
    'scoutSkills': scoutSkills.toJson(),
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    currentWeek: json['currentWeek'],
    currentYear: json['currentYear'],
    actionPoints: json['actionPoints'],
    budget: json['budget'],
    reputation: json['reputation'],
    schools: (json['schools'] as List).map((s) => School.fromJson(s)).toList(),
    discoveredPlayers: (json['discoveredPlayers'] as List).map((p) => Player.fromJson(p)).toList(),
    news: (json['news'] as List).map((n) => NewsItem.fromJson(n)).toList(),
    lastWeekActions: (json['lastWeekActions'] as List?)?.map((a) => ActionResult.fromJson(a)).toList() ?? [],
    thisWeekSchedule: (json['thisWeekSchedule'] as List?)?.map((s) => ScheduleItem.fromJson(s)).toList() ?? [],
    gameResults: (json['gameResults'] as List?)?.map((g) => GameResult.fromJson(g)).toList() ?? [],
    scoutSkills: ScoutSkills.fromJson(json['scoutSkills']),
  );

  // スカウトアクションを実行
  ActionResult executeAction(ScoutingAction action, ScoutingTarget target) {
    // アクションが実行可能かチェック
    if (!action.canExecute(scoutSkills, actionPoints, budget)) {
      return ActionResult(
        actionName: action.name,
        result: '実行条件を満たしていません',
        school: target.name,
        player: target.type == 'player' ? target.name : null,
        apUsed: 0,
        budgetUsed: 0,
        timestamp: DateTime.now(),
        success: false,
      );
    }
    
    // リソースを消費
    actionPoints -= action.apCost;
    budget -= action.budgetCost;
    
    // 成功判定
    final success = action.calculateSuccess(scoutSkills);
    
    // 成功時のスキル上昇
    if (success) {
      for (final skillName in action.primarySkills) {
        final improvement = Random().nextInt(3) + 1; // 1-3ポイント上昇
        scoutSkills.improveSkill(skillName, improvement);
      }
    }
    
    // 体力消費（全アクションで）
    final staminaLoss = Random().nextInt(5) + 1; // 1-5ポイント減少
    scoutSkills.improveSkill('stamina', -staminaLoss);
    
    // アクション別の結果を生成
    final result = _generateActionResult(action, success, target);
    
    return ActionResult(
      actionName: action.name,
      result: result.message,
      school: target.name,
      player: target.type == 'player' ? target.name : null,
      apUsed: action.apCost,
      budgetUsed: action.budgetCost,
      timestamp: DateTime.now(),
      success: success,
      additionalData: result.additionalData,
    );
  }
  
  // アクション別の結果を生成
  ActionResultData _generateActionResult(ScoutingAction action, bool success, ScoutingTarget target) {
    if (!success) {
      return ActionResultData('${action.name}に失敗しました。条件を確認してください。');
    }
    
    switch (action.id) {
      case 'PRAC_WATCH':
        return _handlePracticeWatch(target);
      case 'TEAM_VISIT':
        return _handleTeamVisit(target);
      case 'INFO_SWAP':
        return _handleInfoSwap(target);
      case 'NEWS_CHECK':
        return _handleNewsCheck(target);
      case 'GAME_WATCH':
        return _handleGameWatch(target);
      case 'SCRIMMAGE':
        return _handleScrimmage(target);
      case 'INTERVIEW':
        return _handleInterview(target);
      case 'VIDEO_ANALYZE':
        return _handleVideoAnalyze(target);
      case 'REPORT_WRITE':
        return _handleReportWrite(target);
      default:
        return ActionResultData('${action.name}を実行しました。');
    }
  }
  
  // 練習視察の結果
  ActionResultData _handlePracticeWatch(ScoutingTarget target) {
    final random = Random();
    final discoveredPlayers = <Player>[];
    
    // 新しい選手を発見する可能性
    if (random.nextDouble() < 0.3) { // 30%の確率で新選手発見
      final newPlayer = _generateRandomPlayer(target.name);
      discoveredPlayers.add(newPlayer);
    }
    
    return ActionResultData(
      '${target.name}の練習を視察しました。選手の基本能力を確認できました。',
      {
        'discoveredPlayers': discoveredPlayers.map((p) => p.toJson()).toList(),
        'schoolTrust': random.nextInt(10) + 5, // 5-15ポイント上昇
      },
    );
  }
  
  // ランダムな選手を生成
  Player _generateRandomPlayer(String schoolName) {
    final random = Random();
    final names = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤'];
    final positions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '左翼手', '中堅手', '右翼手'];
    final grades = [1, 2, 3]; // int型に変更
    final personalities = ['リーダーシップ', 'チームプレイ', '向上心', '冷静', '情熱的'];
    
    final name = names[random.nextInt(names.length)] + 
                (random.nextInt(999) + 1).toString().padLeft(3, '0');
    final position = positions[random.nextInt(positions.length)];
    final grade = grades[random.nextInt(grades.length)];
    final personality = personalities[random.nextInt(personalities.length)];
    
    // 投手か野手かを判定
    final isPitcher = position == '投手';
    
    if (isPitcher) {
      final fastballVelo = 130 + random.nextInt(25); // 130-155km/h
      final control = 30 + random.nextInt(41); // 30-70
      final stamina = 40 + random.nextInt(41); // 40-80
      final breakAvg = 35 + random.nextInt(41); // 35-75
      
      return Player(
        name: name,
        school: schoolName,
        grade: grade,
        position: position,
        personality: personality,
        fastballVelo: fastballVelo,
        control: control,
        stamina: stamina,
        breakAvg: breakAvg,
        mentalGrit: (30 + random.nextInt(41)).toDouble(), // double型に変換
        growthRate: (20 + random.nextInt(31)).toDouble(), // double型に変換
        peakAbility: 100 + random.nextInt(51),
        positionFit: {'P': 60 + random.nextInt(41)}, // Map<String, int>型に修正
      );
    } else {
      final batPower = 35 + random.nextInt(41); // 35-75
      final batControl = 40 + random.nextInt(41); // 40-80
      final run = 45 + random.nextInt(41); // 45-85
      final field = 40 + random.nextInt(41); // 40-80
      final arm = 35 + random.nextInt(41); // 35-75
      
      return Player(
        name: name,
        school: schoolName,
        grade: grade,
        position: position,
        personality: personality,
        batPower: batPower,
        batControl: batControl,
        run: run,
        field: field,
        arm: arm,
        mentalGrit: (30 + random.nextInt(41)).toDouble(), // double型に変換
        growthRate: (20 + random.nextInt(31)).toDouble(), // double型に変換
        peakAbility: 100 + random.nextInt(51),
        positionFit: {'IF': 60 + random.nextInt(41)}, // Map<String, int>型に修正
      );
    }
  }
  
  // 球団訪問の結果
  ActionResultData _handleTeamVisit(ScoutingTarget target) {
    final random = Random();
    final needs = ['投手', '野手', '捕手', '外野手', '内野手'];
    final selectedNeeds = needs.take(random.nextInt(3) + 1).toList();
    
    return ActionResultData(
      '球団を訪問しました。ニーズと指名候補について情報を得ました。',
      {
        'teamNeeds': selectedNeeds,
        'draftPriority': random.nextInt(5) + 1, // 1-5の優先度
        'budget': random.nextInt(50000000) + 10000000, // 1000万-6000万
      },
    );
  }
  
  // 情報交換の結果
  ActionResultData _handleInfoSwap(ScoutingTarget target) {
    final random = Random();
    final regions = ['関東', '関西', '中部', '九州', '東北', '北海道'];
    final selectedRegion = regions[random.nextInt(regions.length)];
    
    // 他地域の選手情報を取得
    final otherPlayers = <Map<String, dynamic>>[];
    for (int i = 0; i < random.nextInt(3) + 1; i++) {
      otherPlayers.add({
        'name': '選手${random.nextInt(999) + 1}',
        'school': '${selectedRegion}高校${random.nextInt(10) + 1}',
        'position': ['投手', '野手'][random.nextInt(2)],
        'evaluation': random.nextInt(20) + 70, // 70-90の評価
      });
    }
    
    return ActionResultData(
      '他地域のスカウトと情報交換しました。${selectedRegion}地域の情報を得ました。',
      {
        'region': selectedRegion,
        'otherPlayers': otherPlayers,
        'reputation': random.nextInt(5) + 1, // 1-5ポイント上昇
      },
    );
  }
  
  // ニュース確認の結果
  ActionResultData _handleNewsCheck(ScoutingTarget target) {
    final random = Random();
    final newsCount = random.nextInt(3) + 1; // 1-3件のニュース
    
    return ActionResultData(
      '最新のニュースを確認しました。${newsCount}件の新しい情報を得ました。',
      {
        'newsCount': newsCount,
        'categories': ['試合', '選手', '学校', 'スカウト'].take(random.nextInt(3) + 1).toList(),
      },
    );
  }
  
  // 試合観戦の結果
  ActionResultData _handleGameWatch(ScoutingTarget target) {
    final random = Random();
    final performanceData = {
      'innings': random.nextInt(9) + 1,
      'hits': random.nextInt(10),
      'runs': random.nextInt(5),
      'strikeouts': random.nextInt(10),
      'walks': random.nextInt(5),
    };
    
    return ActionResultData(
      '${target.name}の試合を観戦しました。詳細なパフォーマンスを確認できました。',
      {
        'performance': performanceData,
        'scoutingAccuracy': random.nextInt(20) + 80, // 80-100%の精度
      },
    );
  }
  
  // 練習試合観戦の結果
  ActionResultData _handleScrimmage(ScoutingTarget target) {
    final random = Random();
    final tendencies = ['積極的', '慎重', '攻撃的', '守備重視', 'バランス型'];
    final selectedTendency = tendencies[random.nextInt(tendencies.length)];
    
    return ActionResultData(
      '${target.name}の練習試合を観戦しました。実戦での傾向を確認できました。',
      {
        'tendency': selectedTendency,
        'teamChemistry': random.nextInt(20) + 70, // 70-90のチーム力
        'coachStyle': ['厳格', '自由', '戦術的'][random.nextInt(3)],
      },
    );
  }
  
  // インタビューの結果
  ActionResultData _handleInterview(ScoutingTarget target) {
    final random = Random();
    final personalities = ['リーダーシップ', 'チームプレイ', '向上心', '冷静', '情熱的'];
    final selectedPersonality = personalities[random.nextInt(personalities.length)];
    
    return ActionResultData(
      '${target.name}にインタビューしました。性格と動機について理解できました。',
      {
        'personality': selectedPersonality,
        'motivation': random.nextInt(20) + 70, // 70-90のモチベーション
        'communication': random.nextInt(20) + 70, // 70-90のコミュニケーション力
        'futurePlans': ['プロ野球', '大学野球', '社会人野球'][random.nextInt(3)],
      },
    );
  }
  
  // ビデオ分析の結果
  ActionResultData _handleVideoAnalyze(ScoutingTarget target) {
    final random = Random();
    final technicalData = {
      'mechanics': random.nextInt(20) + 70, // 70-90のメカニクス
      'consistency': random.nextInt(20) + 70, // 70-90の一貫性
      'potential': random.nextInt(30) + 70, // 70-100のポテンシャル
    };
    
    return ActionResultData(
      '映像分析を完了しました。技術的なメカニクスを詳細に確認できました。',
      {
        'technicalAnalysis': technicalData,
        'improvementAreas': ['投球フォーム', '打撃フォーム', '守備'].take(random.nextInt(2) + 1).toList(),
      },
    );
  }
  
  // レポート作成の結果
  ActionResultData _handleReportWrite(ScoutingTarget target) {
    final random = Random();
    final reportQuality = random.nextInt(20) + 80; // 80-100の品質
    
    return ActionResultData(
      '球団提出用の詳細レポートを作成しました。',
      {
        'reportQuality': reportQuality,
        'pages': random.nextInt(10) + 5, // 5-15ページ
        'recommendations': random.nextInt(3) + 1, // 1-3の推奨事項
        'deadline': DateTime.now().add(Duration(days: random.nextInt(7) + 1)),
      },
    );
  }
}

// 利用可能なスカウトアクション
final List<ScoutingAction> availableActions = [
  ScoutingAction(
    id: 'PRAC_WATCH',
    name: '練習視察',
    apCost: 2,
    budgetCost: 20000,
    description: '地元校の練習を見学し、選手の基本能力を確認',
    category: '視察',
    requiredSkills: ['observation'],
    primarySkills: ['observation', 'exploration'],
    baseSuccessRate: 0.60,
    skillModifiers: {'observation': 0.3},
  ),
  ScoutingAction(
    id: 'TEAM_VISIT',
    name: '球団訪問',
    apCost: 1,
    budgetCost: 0,
    description: '球団を訪問し、ニーズと指名候補を確認',
    category: '交渉',
    requiredSkills: ['negotiation'],
    primarySkills: ['negotiation', 'communication'],
    baseSuccessRate: 0.90,
    skillModifiers: {'negotiation': 0.1},
  ),
  ScoutingAction(
    id: 'INFO_SWAP',
    name: '情報交換',
    apCost: 1,
    budgetCost: 0,
    description: '他地域のスカウトと情報交換',
    category: '情報収集',
    requiredSkills: ['communication'],
    primarySkills: ['communication', 'insight'],
    baseSuccessRate: 0.70,
    skillModifiers: {'insight': 0.2},
  ),
  ScoutingAction(
    id: 'NEWS_CHECK',
    name: 'ニュース確認',
    apCost: 0,
    budgetCost: 0,
    description: '最新のニュースを確認',
    category: '情報収集',
    requiredSkills: [],
    primarySkills: ['exploration'],
    baseSuccessRate: 1.0,
    skillModifiers: {},
  ),
  ScoutingAction(
    id: 'GAME_WATCH',
    name: '試合観戦',
    apCost: 3,
    budgetCost: 50000,
    description: '強豪校の試合を観戦し、詳細なパフォーマンスを確認',
    category: '視察',
    requiredSkills: ['observation'],
    primarySkills: ['observation', 'analysis'],
    baseSuccessRate: 0.55,
    skillModifiers: {'observation': 0.4},
  ),
  ScoutingAction(
    id: 'SCRIMMAGE',
    name: '練習試合観戦',
    apCost: 2,
    budgetCost: 30000,
    description: '練習試合を観戦し、実戦での傾向を確認',
    category: '視察',
    requiredSkills: ['observation'],
    primarySkills: ['observation', 'analysis'],
    baseSuccessRate: 0.50,
    skillModifiers: {'observation': 0.4},
  ),
  ScoutingAction(
    id: 'INTERVIEW',
    name: 'インタビュー',
    apCost: 1,
    budgetCost: 10000,
    description: '選手にインタビューし、性格と動機を確認',
    category: '面談',
    requiredSkills: ['communication'],
    primarySkills: ['communication', 'insight'],
    baseSuccessRate: 0.65,
    skillModifiers: {'communication': 0.4},
  ),
  ScoutingAction(
    id: 'VIDEO_ANALYZE',
    name: 'ビデオ分析',
    apCost: 2,
    budgetCost: 0,
    description: '映像を分析し、技術的なメカニクスを確認',
    category: '分析',
    requiredSkills: ['analysis'],
    primarySkills: ['analysis', 'insight'],
    baseSuccessRate: 0.70,
    skillModifiers: {'analysis': 0.3},
  ),
  ScoutingAction(
    id: 'REPORT_WRITE',
    name: 'レポート作成',
    apCost: 2,
    budgetCost: 0,
    description: '球団提出用の詳細レポートを作成',
    category: '報告',
    requiredSkills: ['analysis'],
    primarySkills: ['analysis', 'negotiation'],
    baseSuccessRate: 1.0,
    skillModifiers: {'negotiation': 0.2},
  ),
];

// 選手の通算成績クラス
class PlayerStats {
  final String playerName;
  final String school;
  final String position;
  
  // 投手通算成績
  int totalInningsPitched = 0;
  int totalHitsAllowed = 0;
  int totalRunsAllowed = 0;
  int totalEarnedRuns = 0;
  int totalWalks = 0;
  int totalStrikeouts = 0;
  double era = 0.0;
  
  // 野手通算成績
  int totalAtBats = 0;
  int totalHits = 0;
  int totalDoubles = 0;
  int totalTriples = 0;
  int totalHomeRuns = 0;
  int totalRbis = 0;
  int totalRuns = 0;
  int totalStolenBases = 0;
  double battingAverage = 0.0;
  double onBasePercentage = 0.0;
  double sluggingPercentage = 0.0;
  
  // 守備通算成績
  int totalPutouts = 0;
  int totalAssists = 0;
  int totalErrors = 0;
  double fieldingPercentage = 0.0;
  
  PlayerStats({
    required this.playerName,
    required this.school,
    required this.position,
  });
  
  // 投手成績を追加
  void addPitchingStats(PlayerPerformance performance) {
    if (performance.inningsPitched != null) {
      totalInningsPitched += performance.inningsPitched!;
      totalHitsAllowed += performance.hitsAllowed ?? 0;
      totalRunsAllowed += performance.runsAllowed ?? 0;
      totalEarnedRuns += performance.earnedRuns ?? 0;
      totalWalks += performance.walks ?? 0;
      totalStrikeouts += performance.strikeouts ?? 0;
      
      // ERA計算
      if (totalInningsPitched > 0) {
        era = (totalEarnedRuns * 9.0) / totalInningsPitched;
      }
    }
  }
  
  // 野手成績を追加
  void addBattingStats(PlayerPerformance performance) {
    if (performance.atBats != null) {
      totalAtBats += performance.atBats!;
      totalHits += performance.hits ?? 0;
      totalDoubles += performance.doubles ?? 0;
      totalTriples += performance.triples ?? 0;
      totalHomeRuns += performance.homeRuns ?? 0;
      totalRbis += performance.rbis ?? 0;
      totalRuns += performance.runs ?? 0;
      totalStolenBases += performance.stolenBases ?? 0;
      
      // 打率計算
      if (totalAtBats > 0) {
        battingAverage = totalHits / totalAtBats;
      }
    }
  }
  
  // 守備成績を追加
  void addFieldingStats(PlayerPerformance performance) {
    totalPutouts += performance.putouts ?? 0;
    totalAssists += performance.assists ?? 0;
    totalErrors += performance.errors ?? 0;
    
    // 守備率計算
    final totalChances = totalPutouts + totalAssists + totalErrors;
    if (totalChances > 0) {
      fieldingPercentage = (totalPutouts + totalAssists) / totalChances;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'school': school,
    'position': position,
    'totalInningsPitched': totalInningsPitched,
    'totalHitsAllowed': totalHitsAllowed,
    'totalRunsAllowed': totalRunsAllowed,
    'totalEarnedRuns': totalEarnedRuns,
    'totalWalks': totalWalks,
    'totalStrikeouts': totalStrikeouts,
    'era': era,
    'totalAtBats': totalAtBats,
    'totalHits': totalHits,
    'totalDoubles': totalDoubles,
    'totalTriples': totalTriples,
    'totalHomeRuns': totalHomeRuns,
    'totalRbis': totalRbis,
    'totalRuns': totalRuns,
    'totalStolenBases': totalStolenBases,
    'battingAverage': battingAverage,
    'onBasePercentage': onBasePercentage,
    'sluggingPercentage': sluggingPercentage,
    'totalPutouts': totalPutouts,
    'totalAssists': totalAssists,
    'totalErrors': totalErrors,
    'fieldingPercentage': fieldingPercentage,
  };
  
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final stats = PlayerStats(
      playerName: json['playerName'],
      school: json['school'],
      position: json['position'],
    );
    
    stats.totalInningsPitched = json['totalInningsPitched'] ?? 0;
    stats.totalHitsAllowed = json['totalHitsAllowed'] ?? 0;
    stats.totalRunsAllowed = json['totalRunsAllowed'] ?? 0;
    stats.totalEarnedRuns = json['totalEarnedRuns'] ?? 0;
    stats.totalWalks = json['totalWalks'] ?? 0;
    stats.totalStrikeouts = json['totalStrikeouts'] ?? 0;
    stats.era = (json['era'] as num?)?.toDouble() ?? 0.0;
    stats.totalAtBats = json['totalAtBats'] ?? 0;
    stats.totalHits = json['totalHits'] ?? 0;
    stats.totalDoubles = json['totalDoubles'] ?? 0;
    stats.totalTriples = json['totalTriples'] ?? 0;
    stats.totalHomeRuns = json['totalHomeRuns'] ?? 0;
    stats.totalRbis = json['totalRbis'] ?? 0;
    stats.totalRuns = json['totalRuns'] ?? 0;
    stats.totalStolenBases = json['totalStolenBases'] ?? 0;
    stats.battingAverage = (json['battingAverage'] as num?)?.toDouble() ?? 0.0;
    stats.onBasePercentage = (json['onBasePercentage'] as num?)?.toDouble() ?? 0.0;
    stats.sluggingPercentage = (json['sluggingPercentage'] as num?)?.toDouble() ?? 0.0;
    stats.totalPutouts = json['totalPutouts'] ?? 0;
    stats.totalAssists = json['totalAssists'] ?? 0;
    stats.totalErrors = json['totalErrors'] ?? 0;
    stats.fieldingPercentage = (json['fieldingPercentage'] as num?)?.toDouble() ?? 0.0;
    
    return stats;
  }
} 