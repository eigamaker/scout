import 'dart:math';
import '../player/player.dart';
import '../player/player_abilities.dart';
import '../../services/player_generator.dart';
import 'professional_team.dart';
import 'professional_player.dart';
import 'team_properties.dart';
import 'enums.dart';

/// プロ野球団管理クラス
class TeamManager {
  final List<ProfessionalTeam> teams;
  
  TeamManager({List<ProfessionalTeam>? teams}) : teams = teams ?? [];

  // デフォルトチームを生成
  static List<ProfessionalTeam> generateDefaultTeams() {
    return [
      // セ・リーグ
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'giants',
          name: '読売ジャイアンツ',
          shortName: '巨人',
          league: League.central,
          division: Division.east,
          needs: ['投手力', '若手育成'],
          scoutRelations: {},
          draftOrder: 1,
          teamStrength: {'投手': 70, '打撃': 85, '守備': 75},
          strategy: '打撃重視',
        ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'tigers',
          name: '阪神タイガース',
          shortName: '阪神',
          league: League.central,
          division: Division.west,
          needs: ['打撃力', '長打力'],
          scoutRelations: {},
          draftOrder: 2,
          teamStrength: {'投手': 80, '打撃': 70, '守備': 75},
          strategy: 'バランス型',
        ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'carp',
          name: '広島東洋カープ',
          shortName: '広島',
          league: League.central,
          division: Division.central,
          needs: ['投手力', '資金力'],
          scoutRelations: {},
          draftOrder: 3,
          teamStrength: {'投手': 65, '打撃': 75, '守備': 70},
          strategy: '若手育成重視',
        ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'dragons',
          name: '中日ドラゴンズ',
          shortName: '中日',
          league: League.central,
          division: Division.central,
          needs: ['打撃力', '若手育成'],
          scoutRelations: {},
          draftOrder: 4,
          teamStrength: {'投手': 75, '打撃': 65, '守備': 80},
          strategy: '守備重視',
        ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'swallows',
          name: '東京ヤクルトスワローズ',
          shortName: 'ヤクルト',
          league: League.central,
          division: Division.east,
          needs: ['投手力', '資金力'],
          scoutRelations: {},
          draftOrder: 5,
          teamStrength: {'投手': 60, '打撃': 70, '守備': 65},
          strategy: '打撃重視',
        ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'baystars',
          name: '横浜DeNAベイスターズ',
          shortName: 'DeNA',
          league: League.central,
          division: Division.east,
          needs: ['投手力', '守備力'],
          scoutRelations: {},
          draftOrder: 6,
          teamStrength: {'投手': 70, '打撃': 75, '守備': 70},
          strategy: 'バランス型',
        ),
      ),
      // パ・リーグ
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'hawks',
          name: '福岡ソフトバンクホークス',
          shortName: 'ソフトバンク',
          league: League.pacific,
          division: Division.west,
          needs: ['若手育成'],
          scoutRelations: {},
          draftOrder: 7,
          teamStrength: {'投手': 85, '打撃': 80, '守備': 80},
          strategy: '総合力重視',
          ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'marines',
          name: '千葉ロッテマリーンズ',
          shortName: 'ロッテ',
          league: League.pacific,
          division: Division.east,
          needs: ['投手力', '守備力'],
          scoutRelations: {},
          draftOrder: 8,
          teamStrength: {'投手': 70, '打撃': 75, '守備': 70},
          strategy: '打撃重視',
          ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'lions',
          name: '埼玉西武ライオンズ',
          shortName: '西武',
          league: League.pacific,
          division: Division.east,
          needs: ['外野守備', '長打力'],
          scoutRelations: {},
          draftOrder: 9,
          teamStrength: {'投手': 80, '打撃': 70, '守備': 75},
          strategy: 'バランス型',
          ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'fighters',
          name: '北海道日本ハムファイターズ',
          shortName: '日本ハム',
          league: League.pacific,
          division: Division.east,
          needs: ['内野守備', '打撃力'],
          scoutRelations: {},
          draftOrder: 10,
          teamStrength: {'投手': 80, '打撃': 65, '守備': 75},
          strategy: '投手重視',
          ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'buffaloes',
          name: 'オリックス・バファローズ',
          shortName: 'オリックス',
          league: League.pacific,
          division: Division.west,
          needs: ['打撃力', '長打力'],
          scoutRelations: {},
          draftOrder: 11,
          teamStrength: {'投手': 85, '打撃': 70, '守備': 80},
          strategy: '投手重視',
          ),
      ),
      ProfessionalTeam(
        properties: TeamProperties(
          id: 'eagles',
          name: '東北楽天ゴールデンイーグルス',
          shortName: '楽天',
          league: League.pacific,
          division: Division.east,
          needs: ['投手力', '守備力'],
          scoutRelations: {},
          draftOrder: 12,
          teamStrength: {'投手': 65, '打撃': 70, '守備': 65},
          strategy: '若手育成重視',
          ),
      ),
    ];
  }

  // 全チームを取得
  List<ProfessionalTeam> getAllTeams() => teams;

  // リーグ別のチームを取得
  List<ProfessionalTeam> getTeamsByLeague(League league) {
    return teams.where((team) => team.league == league).toList();
  }

  // 地区別のチームを取得
  List<ProfessionalTeam> getTeamsByDivision(Division division) {
    return teams.where((team) => team.division == division).toList();
  }

  // 特定のチームを取得
  ProfessionalTeam? getTeam(String teamId) {
    try {
      return teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  // チーム名で検索
  ProfessionalTeam? getTeamByName(String teamName) {
    try {
      return teams.firstWhere((team) => team.name == teamName || team.shortName == teamName);
    } catch (e) {
      return null;
    }
  }

  // ドラフト順位順にソート
  List<ProfessionalTeam> getTeamsByDraftOrder() {
    final sortedTeams = List<ProfessionalTeam>.from(teams);
    sortedTeams.sort((a, b) => a.draftOrder.compareTo(b.draftOrder));
    return sortedTeams;
  }

  // 戦力順にソート
  List<ProfessionalTeam> getTeamsByStrength() {
    final sortedTeams = List<ProfessionalTeam>.from(teams);
    sortedTeams.sort((a, b) => b.totalStrength.compareTo(a.totalStrength));
    return sortedTeams;
  }


  // チームを追加
  void addTeam(ProfessionalTeam team) {
    if (!teams.any((t) => t.id == team.id)) {
      teams.add(team);
    }
  }

  // チームを更新
  void updateTeam(ProfessionalTeam updatedTeam) {
    final index = teams.indexWhere((team) => team.id == updatedTeam.id);
    if (index != -1) {
      teams[index] = updatedTeam;
    }
  }

  // チームのポジション強さを更新
  void updateTeamPositionStrength(String teamId, Map<String, int> positionStrengths) {
    final teamIndex = teams.indexWhere((team) => team.id == teamId);
    if (teamIndex != -1) {
      final team = teams[teamIndex];
      final updatedProperties = team.properties.copyWith(teamStrength: positionStrengths);
      final updatedTeam = team.copyWith(properties: updatedProperties);
      teams[teamIndex] = updatedTeam;
    }
  }
  
  // 全チームに選手を生成
  void generatePlayersForAllTeams() {
    print('TeamManager.generatePlayersForAllTeams: 開始');
    
    // 全チームの選手に一意のIDを割り当てるためのカウンター
    int globalPlayerId = 1;
    
    for (final team in teams) {
      print('TeamManager.generatePlayersForAllTeams: ${team.name}の選手生成開始');
      
      // チームの戦略に基づいて選手を生成
      final players = _generatePlayersForTeam(team, globalPlayerId);
      
      // ProfessionalPlayerオブジェクトを生成
      final professionalPlayers = _generateProfessionalPlayers(team, players);
      
      // チームの選手リストを更新
      final updatedTeam = team.copyWith(
        players: players,
        professionalPlayers: professionalPlayers,
      );
      updateTeam(updatedTeam);
      
      globalPlayerId += players.length;
      
      print('TeamManager.generatePlayersForAllTeams: ${team.name}の選手生成完了 - ${players.length}人');
    }
    
    print('TeamManager.generatePlayersForAllTeams: 全体完了 - ${teams.length}チーム');
  }

  // ProfessionalPlayerオブジェクトを生成
  List<ProfessionalPlayer> _generateProfessionalPlayers(ProfessionalTeam team, List<Player> players) {
    final professionalPlayers = <ProfessionalPlayer>[];
    final random = Random();
    
    for (final player in players) {
      final professionalPlayer = ProfessionalPlayer(
        playerId: player.id ?? 0,
        teamId: team.id,
        contractYear: 1,
        salary: 1000 + random.nextInt(2000), // 1000-3000万円
        contractType: ContractType.regular,
        draftYear: DateTime.now().year - 1,
        draftRound: 1,
        draftPosition: 1,
        isActive: true,
        joinedAt: DateTime.now().subtract(Duration(days: 365)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        player: player,
        teamName: team.name,
        teamShortName: team.shortName,
      );
      
      professionalPlayers.add(professionalPlayer);
    }
    
    return professionalPlayers;
  }

  // 特定チームの選手を生成
  List<Player> _generatePlayersForTeam(ProfessionalTeam team, int startId) {
    final players = <Player>[];
    final random = Random();
    
    // チームの戦略に基づいて選手数を決定
    final playerCounts = _getPlayerCountsByStrategy(team.strategy);
    
    for (final entry in playerCounts.entries) {
      final position = entry.key;
      final count = entry.value;
      
      for (int i = 0; i < count; i++) {
        final player = _generatePlayerForPosition(position, team, startId + players.length, random);
        players.add(player);
      }
    }
    
    return players;
  }

  // 戦略に基づく選手数を取得
  Map<String, int> _getPlayerCountsByStrategy(String strategy) {
    switch (strategy) {
      case '投手重視':
        return {
          '投手': 15,
          '捕手': 3,
          '一塁手': 2,
          '二塁手': 2,
          '三塁手': 2,
          '遊撃手': 2,
          '外野手': 6,
        };
      case '打撃重視':
        return {
          '投手': 12,
          '捕手': 3,
          '一塁手': 3,
          '二塁手': 3,
          '三塁手': 3,
          '遊撃手': 3,
          '外野手': 8,
        };
      case 'バランス型':
      default:
        return {
          '投手': 13,
          '捕手': 3,
          '一塁手': 2,
          '二塁手': 2,
          '三塁手': 2,
          '遊撃手': 2,
          '外野手': 7,
        };
    }
  }

  // 特定ポジションの選手を生成
  Player _generatePlayerForPosition(String position, ProfessionalTeam team, int playerId, Random random) {
    // チームの戦力レベルに基づいて才能ランクを決定
    final teamStrength = team.getPositionStrength(position);
    final talent = _calculateTalentByTeamStrength(teamStrength, random);
    
    // 年齢を決定（15-18歳）
    final age = 15 + random.nextInt(4);
    
    // 能力値を生成
    final technicalAbilities = PlayerGenerator.generateTechnicalAbilities(talent, position);
    final mentalAbilities = PlayerGenerator.generateMentalAbilities(talent);
    final physicalAbilities = PlayerGenerator.generatePhysicalAbilities(talent, position);
    
    // ポテンシャルを生成
    final individualPotentials = PlayerGenerator.generateIndividualPotentials(talent, position);
    final technicalPotentials = _getTechnicalPotentialsFromIndividual(individualPotentials);
    final mentalPotentials = _getMentalPotentialsFromIndividual(individualPotentials);
    final physicalPotentials = _getPhysicalPotentialsFromIndividual(individualPotentials);
    
    // ピーク能力を計算
    final peakAbility = _calculatePeakAbilityByAge(talent, age);
    
    return Player(
      id: playerId,
      name: _generatePlayerName(),
      school: team.name,
      grade: age - 15 + 1, // 年齢から学年を計算
      age: age,
      position: position,
      positionFit: _generatePositionFit(position, random),
      fame: 30 + random.nextInt(40), // 30-69
      isFamous: random.nextBool(),
      isScoutFavorite: random.nextBool(),
      isScouted: false,
      isGraduated: false,
      isRetired: false,
      growthRate: 0.3 + random.nextDouble() * 0.7, // 0.3-1.0
      talent: talent,
      growthType: _generateGrowthType(random),
      mentalGrit: 0.3 + random.nextDouble() * 0.7, // 0.3-1.0
      peakAbility: peakAbility,
      personality: _generatePersonality(random),
      technicalAbilities: technicalAbilities,
      mentalAbilities: mentalAbilities,
      physicalAbilities: physicalAbilities,
      individualPotentials: individualPotentials,
      technicalPotentials: technicalPotentials,
      mentalPotentials: mentalPotentials,
      physicalPotentials: physicalPotentials,
    );
  }

  // チーム戦力に基づく才能ランクを計算
  int _calculateTalentByTeamStrength(int teamStrength, Random random) {
    if (teamStrength >= 80) {
      // 強豪チーム: 才能ランク3-5
      return 3 + random.nextInt(3);
    } else if (teamStrength >= 60) {
      // 中堅チーム: 才能ランク2-4
      return 2 + random.nextInt(3);
    } else {
      // 弱小チーム: 才能ランク1-3
      return 1 + random.nextInt(3);
    }
  }

  // 年齢に基づくピーク能力を計算
  int _calculatePeakAbilityByAge(int talent, int age) {
    final basePeak = 60 + (talent * 15);
    final ageFactor = 1.0 - ((age - 18).abs() * 0.02);
    return (basePeak * ageFactor).round().clamp(50, 100);
  }

  // ポジション適性を生成
  Map<String, int> _generatePositionFit(String position, Random random) {
    final fit = <String, int>{};
    
    // メインポジションは80-100
    fit[position] = 80 + random.nextInt(21);
    
    // 関連ポジションは60-79
    switch (position) {
      case '投手':
        fit['捕手'] = 60 + random.nextInt(20);
        break;
      case '捕手':
        fit['一塁手'] = 60 + random.nextInt(20);
        break;
      case '一塁手':
        fit['三塁手'] = 60 + random.nextInt(20);
        fit['外野手'] = 50 + random.nextInt(20);
        break;
      case '二塁手':
        fit['遊撃手'] = 70 + random.nextInt(20);
        fit['三塁手'] = 50 + random.nextInt(20);
        break;
      case '三塁手':
        fit['一塁手'] = 60 + random.nextInt(20);
        fit['外野手'] = 50 + random.nextInt(20);
        break;
      case '遊撃手':
        fit['二塁手'] = 70 + random.nextInt(20);
        fit['三塁手'] = 50 + random.nextInt(20);
        break;
      case '外野手':
        fit['一塁手'] = 50 + random.nextInt(20);
        break;
    }
    
    // その他のポジションは40-59
    final allPositions = ['投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手', '外野手'];
    for (final pos in allPositions) {
      if (!fit.containsKey(pos)) {
        fit[pos] = 40 + random.nextInt(20);
      }
    }
    
    return fit;
  }

  // 成長タイプを生成
  String _generateGrowthType(Random random) {
    final types = ['early', 'normal', 'late'];
    final weights = [0.3, 0.5, 0.2];
    
    final randomValue = random.nextDouble();
    double cumulative = 0.0;
    
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (randomValue <= cumulative) {
        return types[i];
      }
    }
    return 'normal';
  }

  // 性格を生成
  String _generatePersonality(Random random) {
    final personalities = [
      '真面目', '明るい', 'クール', '熱血', '冷静', 'リーダーシップ', '努力家', '天才肌'
    ];
    return personalities[random.nextInt(personalities.length)];
  }

  // 選手名を生成
  String _generatePlayerName() {
    final surnames = ['田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山田', '中村', '小林', '加藤'];
    final givenNames = ['太郎', '次郎', '三郎', '四郎', '五郎', '一郎', '二郎', '三郎', '四郎', '五郎'];
    
    final random = Random();
    final surname = surnames[random.nextInt(surnames.length)];
    final givenName = givenNames[random.nextInt(givenNames.length)];
    
    return '$surname$givenName';
  }

  // 個別ポテンシャルから技術面ポテンシャルを抽出
  Map<TechnicalAbility, int> _getTechnicalPotentialsFromIndividual(Map<String, int> individualPotentials) {
    final potentials = <TechnicalAbility, int>{};
    for (final ability in TechnicalAbility.values) {
      potentials[ability] = individualPotentials[ability.name] ?? 50;
    }
    return potentials;
  }

  // 個別ポテンシャルからメンタル面ポテンシャルを抽出
  Map<MentalAbility, int> _getMentalPotentialsFromIndividual(Map<String, int> individualPotentials) {
    final potentials = <MentalAbility, int>{};
    for (final ability in MentalAbility.values) {
      potentials[ability] = individualPotentials[ability.name] ?? 50;
    }
    return potentials;
  }

  // 個別ポテンシャルからフィジカル面ポテンシャルを抽出
  Map<PhysicalAbility, int> _getPhysicalPotentialsFromIndividual(Map<String, int> individualPotentials) {
    final potentials = <PhysicalAbility, int>{};
    for (final ability in PhysicalAbility.values) {
      potentials[ability] = individualPotentials[ability.name] ?? 50;
    }
    return potentials;
  }
}
