import '../models/school/school.dart';
import '../utils/name_generator.dart';

/// デフォルトの学校データを提供するクラス
class DefaultSchoolData {
  static const List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  // 各都道府県の主要都市・地域
  static const Map<String, List<String>> _majorCities = {
    '北海道': ['札幌', '旭川', '函館', '小樽', '室蘭', '苫小牧', '帯広', '北見', '釧路', '網走'],
    '青森県': ['青森', '弘前', '八戸', '黒石', '五所川原', '十和田', '三沢', 'むつ', 'つがる', '平川'],
    '岩手県': ['盛岡', '宮古', '大船渡', '花巻', '北上市', '久慈', '遠野', '一関', '陸前高田', '釜石'],
    '宮城県': ['仙台', '石巻', '塩竈', '気仙沼', '白石', '名取', '角田', '多賀城', '岩沼', '登米'],
    '秋田県': ['秋田', '能代', '横手', '大館', '男鹿', '湯沢', '鹿角', '由利本荘', '潟上', '大仙'],
    '山形県': ['山形', '米沢', '鶴岡', '酒田', '新庄', '寒河江', '上山市', '長井', '天童', '東根'],
    '福島県': ['福島', '会津若松', '郡山', 'いわき', '白河', '須賀川', '二本松', '田村', '南相馬', '伊達'],
    '茨城県': ['水戸', '日立', '土浦', '古河', '石岡', '結城', '下妻', '常総', '常陸太田', '高萩'],
    '栃木県': ['宇都宮', '足利', '栃木', '佐野', '鹿沼', '日光', '小山市', '真岡', '大田原', '矢板'],
    '群馬県': ['前橋', '高崎', '桐生', '伊勢崎', '太田', '沼田', '館林', '渋川', '藤岡', '富岡'],
    '埼玉県': ['さいたま', '川越', '所沢', '越谷', '草加', '春日部', '上尾', '新座', '久喜', '北本市'],
    '千葉県': ['千葉', '船橋', '柏', '市川', '松戸', '佐倉', '成田', '習志野', '八千代', '流山'],
    '東京都': ['新宿', '渋谷', '港', '千代田', '中央', '文京', '台東', '墨田', '江東', '品川'],
    '神奈川県': ['横浜', '川崎', '相模原', '藤沢', '横須賀', '茅ヶ崎', '厚木', '大和', '海老名', '座間'],
    '新潟県': ['新潟', '長岡', '三条', '柏崎', '新発田', '小千谷', '加茂', '十日町', '見附', '燕'],
    '富山県': ['富山', '高岡', '魚津', '氷見', '滑川', '黒部', '砺波', '小矢部', '南砺', '射水'],
    '石川県': ['金沢', '七尾', '小松', '輪島', '珠洲', '加賀', '羽咋', 'かほく', '白山市', '能美'],
    '福井県': ['福井', '敦賀', '小浜', '大野', '勝山', '鯖江', 'あわら', '越前', '坂井', '三方上中'],
    '山梨県': ['甲府', '富士吉田', '都留', '山梨', '大月', '韮崎', '南アルプス', '北杜', '甲斐', '笛吹'],
    '長野県': ['長野', '松本', '上田', '岡谷', '飯田', '諏訪', '小諸', '茅野', '佐久', '伊那'],
    '岐阜県': ['岐阜', '大垣', '高山市', '多治見', '関', '中津川', '美濃', '可児', '各務原', '山県'],
    '静岡県': ['静岡', '浜松', '沼津', '富士', '磐田', '焼津', '藤枝', '島田', '掛川', '袋井'],
    '愛知県': ['名古屋', '豊田', '岡崎', '一宮', '春日井', '豊橋', '津島', '碧南', '刈谷', '安城'],
    '三重県': ['津', '四日市', '松阪', '桑名', '鈴鹿', '名張', '尾鷲', '亀山', '鳥羽', '熊野'],
    '滋賀県': ['大津', '彦根', '長浜', '近江八幡', '草津', '守山', '栗東', '甲賀', '野洲', '高島'],
    '京都府': ['京都市', '福知山', '舞鶴', '綾部', '宇治', '長岡京', '八幡', '京田辺', '京丹後', '南丹'],
    '大阪府': ['大阪市', '堺', '豊中', '吹田', '茨木', '高槻', '枚方', '寝屋川', '八尾', '岸和田'],
    '兵庫県': ['神戸', '姫路', '尼崎', '明石', '西宮', '芦屋', '伊丹', '宝塚', '川西', '三田'],
    '奈良県': ['奈良', '大和高田', '大和郡山', '天理', '橿原', '桜井', '五條', '御所', '生駒', '香芝'],
    '和歌山県': ['和歌山', '海南', '橋本', '有田', '御坊', '田辺', '新宮', '紀の川', '岩出', '海草'],
    '鳥取県': ['鳥取', '米子', '倉吉', '境港', '岩美', '八頭', '東伯', '西伯', '日野', '日南'],
    '島根県': ['松江', '浜田', '出雲', '益田', '大田', '安来', '江津', '雲南', '仁多', '邑智'],
    '岡山県': ['岡山', '倉敷', '津山', '玉野', '笠岡', '井原', '総社', '高梁', '新見', '備前'],
    '広島県': ['広島', '呉', '福山', '東広島', '廿日市', '安芸高田', '江田島', '大竹', '竹原', '三原'],
    '山口県': ['山口', '下関', '宇部', '周南', '岩国', '長門', '萩', '美祢', '柳井', '光'],
    '徳島県': ['徳島', '鳴門', '小松島', '阿南', '吉野川', '阿波', '美馬', '三好', '勝浦', '板野'],
    '香川県': ['高松', '丸亀', '坂出', '善通寺', '観音寺', 'さぬき', '東かがわ', '綾歌', '小豆島', '土庄'],
    '愛媛県': ['松山', '今治', '新居浜', '西条', '大洲', '伊予', '四国中央', '西予', '上浮穴', '伊予'],
    '高知県': ['高知', '室戸', '安芸', '南国', '土佐', '須崎', '宿毛', '土佐清水', '四万十', '香南'],
    '福岡県': ['福岡', '北九州', '久留米', '大牟田', '直方', '飯塚', '田川', '柳川', '八女', '筑後'],
    '佐賀県': ['佐賀', '唐津', '鳥栖', '多久', '伊万里', '武雄', '鹿島', '小城', '嬉野', '神埼'],
    '長崎県': ['長崎', '佐世保', '島原', '諫早', '大村', '平戸', '松浦', '対馬', '壱岐', '五島'],
    '熊本県': ['熊本', '八代', '人吉', '荒尾', '水俣', '玉名', '山鹿', '菊池', '宇土', '上天草'],
    '大分県': ['大分', '別府', '中津', '日田', '佐伯', '臼杵', '津久見', '竹田', '豊後高田', '杵築'],
    '宮崎県': ['宮崎', '都城市', '延岡', '小林', '日南', '日向', '西都市', 'えびの', '三股', '高千穂'],
    '鹿児島県': ['鹿児島', '鹿屋', '枕崎', '阿久根', '出水', '指宿', '西之表', '垂水', '薩摩川内', '日置'],
    '沖縄県': ['那覇', '沖縄', '宜野湾', '石垣', '浦添', '名護', '糸満', '豊見城', 'うるま', '宮古島'],
  };

  // 学校種別
  static const List<String> _schoolTypes = [
    '高校', '高等学校', '商業高校', '工業高校', '農業高校', '総合高校', '普通高校', '進学校',
    '学園', '学院', '第一高校', '第二高校', '第三高校', '第四高校', '第五高校',
    '東高校', '西高校', '南高校', '北高校', '中央高校', '新高校', '女子高校', '男子高校'
  ];

  // 学校の接頭辞
  static const List<String> _schoolPrefixes = [
    '県立', '市立', '私立', '国立', '都立', '府立', '町立', '村立'
  ];

  /// 47都道府県×50校のデフォルト学校データを取得
  static List<School> getAllSchools() {
    final schools = <School>[];
    
    for (final prefecture in _prefectures) {
      final prefectureSchools = _getSchoolsForPrefecture(prefecture);
      schools.addAll(prefectureSchools);
    }
    
    return schools;
  }

  /// 都道府県ごとの学校データを取得
  static List<School> _getSchoolsForPrefecture(String prefecture) {
    final schools = <School>[];
    
    // 各都道府県の50校を生成
    for (int i = 0; i < 50; i++) {
      final schoolData = _getSchoolData(prefecture, i);
      final school = School(
        id: '${prefecture}_$i',
        name: schoolData['name']!,
        shortName: _generateShortName(schoolData['name']!),
        location: schoolData['location']!,
        prefecture: prefecture,
        rank: schoolData['rank']!,
        players: [], // 選手は後で生成
        coachTrust: schoolData['coachTrust']!,
        coachName: schoolData['coachName']!,
      );
      
      schools.add(school);
    }
    
    return schools;
  }

  /// 個別の学校データを取得
  static Map<String, dynamic> _getSchoolData(String prefecture, int index) {
    // 学校ランクの分布（指定された比率）
    final rankDistribution = _getRankDistribution(index);
    
    // 学校名の生成
    final name = _generateSchoolName(prefecture, index, rankDistribution['rank']!);
    
    // 場所の生成
    final location = _generateLocation(prefecture, index);
    
    // 監督の信頼度（ランクに応じて）
    final coachTrust = _getCoachTrustByRank(rankDistribution['rank']!);
    
    // 監督名の生成
          final coachName = NameGenerator.generateCoachName(prefecture, index);
    
    return {
      'name': name,
      'location': location,
      'rank': rankDistribution['rank']!,
      'coachTrust': coachTrust,
      'coachName': coachName,
    };
  }

  /// 学校ランクの分布を決定（指定された比率）
  static Map<String, dynamic> _getRankDistribution(int index) {
    // 各ランクの学校数を決定
    // 名門: 2校 (4%)
    // 強豪: 4校 (8%)
    // 中堅: 7校 (14%)
    // 弱小: 37校 (74%)
    
    if (index < 2) {
      return {'rank': SchoolRank.elite};
    } else if (index < 6) {
      return {'rank': SchoolRank.strong};
    } else if (index < 13) {
      return {'rank': SchoolRank.average};
    } else {
      return {'rank': SchoolRank.weak};
    }
  }

  /// 学校名を生成
  static String _generateSchoolName(String prefecture, int index, SchoolRank rank) {
    final cities = _majorCities[prefecture] ?? [prefecture];
    final city = cities[index % cities.length];
    
    // ランクに応じて学校名のパターンを変える
    switch (rank) {
      case SchoolRank.elite:
        // 名門校は特別な名前
        if (index == 0) {
          return '${city}第一高等学校';
        } else {
          return '${city}中央高等学校';
        }
      case SchoolRank.strong:
        // 強豪校は番号付き
        final number = index - 2 + 1;
        return '${city}第${number}高等学校';
      case SchoolRank.average:
        // 中堅校は方向性
        final directions = ['東', '西', '南', '北', '中央', '新', '総合'];
        final direction = directions[(index - 6) % directions.length];
        return '${city}${direction}高等学校';
      case SchoolRank.weak:
        // 弱小校は現実的な名前
        if (index < 15) {
          // 番号付き高校
          final number = index - 13 + 1;
          return '${city}第${number}高等学校';
        } else if (index < 25) {
          // 専門高校
          final specialTypes = ['商業', '工業', '農業', '総合', '普通'];
          final specialType = specialTypes[(index - 15) % specialTypes.length];
          return '${city}${specialType}高等学校';
        } else if (index < 35) {
          // 方向性高校
          final directions = ['東', '西', '南', '北', '中央', '新'];
          final direction = directions[(index - 25) % directions.length];
          return '${city}${direction}高等学校';
        } else {
          // その他の高校
          final otherTypes = ['高等学校', '高校', '学園', '学院'];
          final otherType = otherTypes[(index - 35) % otherTypes.length];
          return '${city}${otherType}';
        }
    }
  }

  /// 学校の場所を生成
  static String _generateLocation(String prefecture, int index) {
    final cities = _majorCities[prefecture] ?? [prefecture];
    final city = cities[index % cities.length];
    
    // 都道府県名と市名を組み合わせ
    if (city == prefecture) {
      return prefecture;
    } else {
      return '$prefecture$city';
    }
  }

  /// ランクに応じた監督の信頼度を取得
  static int _getCoachTrustByRank(SchoolRank rank) {
    switch (rank) {
      case SchoolRank.elite:
        return 85; // 名門校の監督は高信頼度
      case SchoolRank.strong:
        return 70; // 強豪校の監督は中高信頼度
      case SchoolRank.average:
        return 55; // 中堅校の監督は中信頼度
      case SchoolRank.weak:
        return 40; // 弱小校の監督は低信頼度
    }
  }

  /// 学校名から略称を生成
  static String _generateShortName(String fullName) {
    // 「高等学校」「高校」「学園」「学院」を除去
    String shortName = fullName
        .replaceAll('高等学校', '')
        .replaceAll('高校', '')
        .replaceAll('学園', '')
        .replaceAll('学院', '');
    
    // 「県立」「市立」「私立」「国立」「都立」「府立」「町立」「村立」を除去
    shortName = shortName
        .replaceAll('県立', '')
        .replaceAll('市立', '')
        .replaceAll('私立', '')
        .replaceAll('国立', '')
        .replaceAll('都立', '')
        .replaceAll('府立', '')
        .replaceAll('町立', '')
        .replaceAll('村立', '');
    
    return shortName.isEmpty ? fullName : shortName;
  }

}
