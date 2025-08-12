# 選手能力値設計ドキュメント

## 概要
高校野球の現実を反映し、すべての選手が投手と野手の両方の能力値を持つ設計となっています。Football ManagerやOut of the Park Baseball（OOTP）を参考に、技術・メンタル・フィジカルの3つのカテゴリで選手の能力を表現し、現実的な成績シミュレーションを実現します。

## 能力値の基本設計

### 生涯ポテンシャル用の世代別能力値レンジ

| 世代 | 能力値範囲 | 球速範囲 | 特徴 | 備考 |
|------|------------|----------|------|------|
| 高校生全体 | 25-100 | 125-155 km/h | 現行能力値のメイン | 甲子園出場レベル: 70-100 |
| 大学生 | 75-103 | 140-155 km/h | 高校より高いレベル | |
| 社会人 | 85-105 | 140-155 km/h | 実戦経験豊富 | |
| NPB2軍 | 95-105 | 140-155 km/h | 二軍主力レベル | |
| NPB1軍 | 100-115 | 140-160 km/h | 一軍主力レベル | |
| NPBスーパースター | 115-120 | 158-160 km/h | トップレベル | |
| MLB選手 | 115-135 | 140-165 km/h | 世界レベル | |
| MLBオールスター級 | 136-145 | 160-165 km/h | 超一流 | |
| MLBスーパースター | 146-150 | 165-170 km/h | 最高レベル | |

## 基本能力の定義と役割

### 基本能力値の定義

#### 成長関連能力値

| 能力値 | 範囲 | 役割 | 影響範囲 | 計算方法 |
|--------|------|------|----------|----------|
| **成長スピード (growthRate)** | 0.9-1.2 | 能力値の成長速度を決定 | 全能力値の成長 | 基本値1.0から±20%の変動 |
| **才能ランク (talent)** | 1-6 | 選手の総合的な才能レベル | ポテンシャル範囲、成長上限 | 出現確率に基づく決定 |
| **成長タイプ (growthType)** | early/normal/late/spurt | 成長パターンを決定 | 学年別成長曲線 | ランダム選択 |

#### 精神・メンタル関連能力値

| 能力値 | 範囲 | 役割 | 影響範囲 | 計算方法 |
|--------|------|------|----------|----------|
| **精神力 (mentalGrit)** | 0.5-0.8 | 成長や試合での精神的な強さ | 成長効率、試合パフォーマンス | 基本値0.65から±15%の変動 |
| **才能基準値 (talentBase)** | 60-150 | 才能ランクに基づく基準値 | 個別ポテンシャル生成の基準 | 才能ランクに基づく決定 |

#### 注目度・評価関連能力値

| 能力値 | 範囲 | 役割 | 影響範囲 | 計算方法 |
|--------|------|------|----------|----------|
| **注目度 (fame)** | 0-100 | スカウトからの注目度 | スカウト判定、発掘優先度 | 選手クラス+ポジション+チーム強度 |
| **信頼度 (trustLevel)** | 0-100 | スカウトとの信頼関係 | 情報開示度、分析精度 | 接触回数、分析精度に基づく |

### 基本能力値の使用方法

#### 1. 成長システムでの活用

**成長スピード (growthRate)**
- **計算式**: `新しい能力値 = 現在の能力値 + (成長係数 × growthRate × 精神力補正)`
- **学年別成長**: 1年生→2年生、2年生→3年生での成長量を決定
- **成長上限**: ポテンシャル値まで成長可能

**成長タイプ (growthType)**
- **early**: 1年生時点で既に高い能力値、成長は緩やか
- **normal**: 標準的な成長パターン
- **late**: 3年生で急激に成長
- **spurt**: 2年生で急成長、その後は緩やか

#### 2. 試合パフォーマンスでの活用

**精神力 (mentalGrit)**
- **試合中の能力値補正**: `実際の能力値 = 基本能力値 × (0.8 + mentalGrit × 0.4)`
- **プレッシャー耐性**: 重要な場面での能力値低下を軽減
- **成長効率**: 練習効果の向上
- **数値の意味**: 0.5（低い精神力）〜0.8（高い精神力）、0.65が標準値

#### 3. スカウトシステムでの活用

**注目度 (fame)**
- **発掘優先度**: 高注目度選手を優先的に発掘
- **分析精度**: 注目度が高いほど分析精度が向上
- **情報開示**: 高注目度選手はより詳細な情報が開示

**信頼度 (trustLevel)**
- **情報開示度**: 信頼度が高いほど詳細な能力値を表示
- **分析精度**: 信頼度に応じてスカウト分析の誤差が減少
- **接触効果**: 接触回数に応じて信頼度が上昇

#### 4. ポテンシャルシステムでの活用

**才能基準値 (talentBase)**
- **個別ポテンシャル生成**: 各能力値の個別ポテンシャルは才能基準値±変動幅の範囲
- **才能ランク連動**: 才能ランクに応じて才能基準値の範囲が決定
- **成長判定**: 現在の能力値が個別ポテンシャルに達しているかチェック

**才能ランク (talent)**
- **才能基準値範囲決定**: ランク1(60-75)〜ランク6(130-150)
- **成長係数**: 高ランクほど成長効率が向上
- **希少性**: ランク5以上は0.1%以下の希少性

### 基本能力値の相互関係

#### 成長効率の計算
```
成長効率 = 基本成長係数 × growthRate × (0.8 + mentalGrit × 0.4) × 才能ランク補正
```

#### 注目度の計算
```
注目度 = 基本注目度(選手クラス) + ポジションボーナス + チーム強度ボーナス + 才能ランクボーナス
```

#### 信頼度の計算
```
信頼度 = 接触回数 × 分析精度 × (1 + 注目度補正)
```

### システム実装での活用例

1. **選手生成時**: 才能ランク→才能基準値→個別ポテンシャル→初期能力値の順で決定
2. **成長計算時**: growthRate、mentalGrit、才能ランクを総合して成長量を計算
3. **スカウト判定時**: fame、trustLevelを基に発掘優先度と分析精度を決定
4. **試合シミュレーション時**: mentalGritを基にプレッシャー下での能力値補正を適用

## 成長システムの参照

詳細な成長システムについては、`growth_system_design.md`を参照してください。

### 成長関連の基本能力値

成長システムで使用される基本能力値については、以下のセクションで定義されています：
- [基本能力の定義と役割](#基本能力の定義と役割)
- [才能ランクとポテンシャルの関係](#才能ランクとポテンシャルの関係)

## 高校生レベル別既存能力値レンジ（システム参考値）

### 選手クラス別能力値範囲

| クラス | 能力値範囲 | 球速範囲 | 特徴 | 出現率 | 注目度(fame) | 備考 |
|--------|------------|----------|------|--------|--------------|------|
| **D級** | 25-40 | 125-135 km/h | 一般レベル | 50% | 0-10 | 部活レベル |
| **C級** | 40-55 | 130-140 km/h | 県大会レベル | 30% | 10-25 | 県大会出場 |
| **B級** | 55-70 | 135-145 km/h | 県大会上位 | 15% | 25-40 | 県大会ベスト8 |
| **A級** | 70-85 | 140-150 km/h | 県トップレベル | 4% | 40-60 | 県大会優勝候補 |
| **S級** | 85-95 | 145-155 km/h | 甲子園レベル | 0.9% | 60-80 | 甲子園出場 |
| **SS級** | 95-100 | 150-155 km/h | 甲子園上位 | 0.1% | 80-95 | 甲子園ベスト8 |

### 詳細レベル別能力値範囲

| レベル | 能力値範囲 | 球速範囲 | 特徴 | 出現率 | 注目度(fame) | 備考 |
|--------|------------|----------|------|--------|--------------|------|
| **一般レベル** | 25-45 | 125-135 km/h | 一般高校レベル | 60% | 0-15 | 県大会1回戦止まり |
| **県大会レベル** | 45-55 | 130-140 km/h | 県大会出場レベル | 25% | 15-30 | 県大会ベスト16-32 |
| **県大会ベスト8** | 55-65 | 135-145 km/h | 県大会上位レベル | 10% | 30-45 | 県大会ベスト8-16 |
| **県大会ベスト4** | 65-75 | 140-150 km/h | 県大会準決勝レベル | 3% | 45-60 | 県大会ベスト4-8 |
| **県トップレベル** | 75-85 | 145-155 km/h | 県大会決勝レベル | 1.5% | 60-75 | 県大会優勝候補 |
| **甲子園1回戦** | 70-80 | 140-150 km/h | 甲子園出場レベル | 0.3% | 75-85 | 甲子園1-2回戦 |
| **甲子園2回戦** | 80-85 | 145-155 km/h | 甲子園2回戦レベル | 0.1% | 85-90 | 甲子園2-3回戦 |
| **甲子園ベスト8** | 85-90 | 150-155 km/h | 甲子園上位レベル | 0.05% | 90-95 | 甲子園ベスト8-16 |
| **甲子園ベスト4** | 90-95 | 150-155 km/h | 甲子園準決勝レベル | 0.02% | 95-98 | 甲子園ベスト4-8 |
| **甲子園優勝候補** | 95-100 | 150-155 km/h | 甲子園決勝レベル | 0.01% | 98-100 | 甲子園優勝候補 |
| **常勝チーム** | 90-100 | 150-155 km/h | 伝統校レベル | 0.005% | 100 | 甲子園常連校 |

### ポジション別能力値基準

| ポジション | 主要能力値 | 基準範囲 | 特徴 | 注目度ボーナス |
|------------|------------|----------|------|----------------|
| **投手** | 球速・制球・スタミナ | 60-100 | 投手能力が最重要 | +10 |
| **捕手** | 捕球・送球・リード | 50-95 | 守備技術が重要 | +5 |
| **内野手** | 守備・送球・打撃 | 45-90 | バランスが重要 | +3 |
| **外野手** | 走力・守備・打撃 | 50-95 | 運動能力が重要 | +2 |

### チーム強度評価基準

| チームレベル | 平均能力値 | 主力選手レベル | 特徴 | 注目度影響 |
|-------------|------------|----------------|------|------------|
| **弱小校** | 30-40 | C級以下 | 県大会1回戦止まり | -5 |
| **一般校** | 40-50 | C級 | 県大会出場レベル | 0 |
| **中堅校** | 50-60 | B級 | 県大会ベスト16 | +5 |
| **強豪校** | 60-70 | A級 | 県大会ベスト4 | +10 |
| **名門校** | 70-80 | S級 | 甲子園出場レベル | +15 |
| **伝統校** | 80-90 | SS級 | 甲子園常連校 | +20 |
| **超名門校** | 90-100 | SS級 | 甲子園優勝候補 | +25 |

### 注目度（fame）の計算要素

1. **基本注目度**: 選手クラスに基づく基本値
2. **ポジションボーナス**: 投手は+10、捕手は+5など
3. **チーム強度ボーナス**: 名門校所属で+15〜+25
4. **実績ボーナス**: 甲子園出場経験、県大会優勝など
5. **才能ランクボーナス**: 才能ランクが高いほど+5〜+20

### システム参考値としての活用

- **選手生成時**: クラス別の能力値範囲を基準に生成
- **注目度計算**: 選手クラス、ポジション、チーム強度を総合評価
- **スカウト判定**: 高注目度選手の優先度を上げる
- **成長予測**: クラス別の成長パターンを設定

## 能力値カテゴリ設計

### Technical（技術面）- 100段階評価

#### 打撃技術
- **ミート（Contact）**: ヒットを打つ能力
- **パワー（Power）**: 長打力、本塁打能力
- **選球眼（Plate Discipline）**: ボールを見極める能力
- **バント（Bunt）**: バント技術
- **流し打ち（Opposite Field Hitting）**: 逆方向への打撃
- **プルヒッティング（Pull Hitting）**: 引っ張り打撃
- **バットコントロール（Bat Control）**: ファールや変化球への対応力
- **スイングスピード（Swing Speed）**: バットスイングの速度

#### 守備技術
- **捕球（Fielding）**: 守備の基本技術
- **送球（Throwing）**: 送球の正確性
- **捕手リード（Catcher Ability）**: 捕手としてのリード能力

#### 投手技術
- **コントロール（Control）**: 投球の制球力
- **球速（Fastball）**: 直球の球速
- **変化球（Breaking Ball）**: 変化球の質
- **球種ごとの変化量（Pitch Movement）**: 各球種の変化量

### Mental（メンタル面）- 100段階評価

#### 集中力・判断力
- **集中力（Concentration）**: 試合中の集中力
- **予測力（Anticipation）**: 守備時の飛んでくるボールの予測、打撃時の投手の球種予測など、様々な場面で状況を読む能力
- **視野（Vision）**: 広い視野での判断
- **冷静さ（Composure）**: プレッシャー下での冷静さ

#### 性格・精神面
- **積極性（Aggression）**: 積極的なプレー
- **勇敢さ（Bravery）**: 危険なプレーへの挑戦
- **リーダーシップ（Leadership）**: チームを引っ張る力
- **勤勉さ（Work Rate）**: 練習への取り組み
- **自己管理（Self-Discipline）**: 自己管理能力
- **野心（Ambition）**: 上昇志向

#### チームプレー
- **チームワーク（Teamwork）**: チームプレーへの貢献
- **ポジショニング（Positioning）**: 守備位置の判断
- **プレッシャー耐性（Pressure Handling）**: プレッシャーへの対応
- **勝負強さ（Clutch Ability）**: 重要な場面での活躍

### Physical（フィジカル面）- 100段階評価

#### 運動能力
- **加速力（Acceleration）**: 瞬発力
- **敏捷性（Agility）**: 身のこなし
- **バランス（Balance）**: 体のバランス
- **走力（Pace/Speed）**: 走塁速度

#### 体力・筋力
- **持久力（Stamina/Natural Fitness）**: 体力の持続性
- **筋力（Strength）**: 筋力
- **柔軟性（Flexibility）**: 体の柔軟性
- **ジャンプ力（Jumping Reach）**: 跳躍力

## 球速の詳細レンジ（学年別・ポジション別）

#### 投手の球速範囲目安
- **1年生**: 125-140 km/h（平均: 130-135 km/h）
- **2年生**: 125-145 km/h（平均: 130-140 km/h）
- **3年生**: 125-155 km/h（平均: 130-145 km/h）

#### 野手の球速範囲（投手能力に応じた制限）
- **投手能力が非常に高い選手**: 最大145 km/h
- **投手能力が高い選手**: 最大140 km/h
- **投手能力がやや高い選手**: 最大135 km/h
- **投手能力が中程度の選手**: 最大130 km/h
- **投手能力が低い選手**: 最大128 km/h

#### 球速の学年別想定分布（各学年28,200人中）

**1年生（28,200人）**
- 150-155 km/h: ほぼゼロ（0.00001%）
- 145-149 km/h: ほぼゼロ（0.00035%）
- 140-144 km/h: ほぼゼロ（0.005%）
- 135-139 km/h: 1人
- 130-134 km/h: 3人
- 125-129 km/h: 10人
- 120-124 km/h: 25人
- 115-119 km/h: 500人
- 110-114 km/h: 8,000人
- 105-109 km/h: 10,000人
- 100-104 km/h: 8,000人
- 95-99 km/h: 2,000人

**2年生（28,200人）**
- 150-155 km/h: ほぼゼロ（0.00005%）
- 145-149 km/h: ほぼゼロ（0.0008%）
- 140-144 km/h: 2人（0.01%）
- 135-139 km/h: 3人
- 130-134 km/h: 10人
- 125-129 km/h: 50人
- 120-124 km/h: 150人
- 115-119 km/h: 800人
- 110-114 km/h: 4,000人
- 105-109 km/h: 12,000人
- 100-104 km/h: 9,000人
- 95-99 km/h: 1,000人

**3年生（28,200人）**
- 150-155 km/h: ほぼゼロ（0.001%）
- 145-149 km/h: 1人（0.035%）
- 140-144 km/h: 3人
- 135-139 km/h: 6人
- 130-134 km/h: 15人
- 125-129 km/h: 100人
- 120-124 km/h: 250人
- 115-119 km/h: 1,000人
- 110-114 km/h: 5,000人
- 105-109 km/h: 13,000人
- 100-104 km/h: 8,000人
- 95-99 km/h: 1,000人

## 才能ランクとポテンシャルの関係

才能ランクとポテンシャルの詳細については、`growth_system_design.md`の「才能ランクとポテンシャルシステム」セクションを参照してください。

### 基本概念の要約

- **才能ランク**: 1-6段階（1:一般、6:怪物級）
- **個別ポテンシャル**: 各能力値の生涯最大到達可能値（50-150）
- **才能基準値**: 才能ランクに基づく基準値（60-150）
- **出現確率**: ランク1（49.9%）～ランク6（0.0004%）

## 学年別生成戦略

### 新入生（1年生）生成
- **目標**: 3年間の成長でポテンシャル上限に到達
- **初期能力値**: 成長を逆算して設定（25-100基準）
- **成長余地**: 最大限確保

### 2年生・3年生生成
- **目標**: 既に一定の成長を遂げた状態
- **初期能力値**: 学年に応じた成長を反映
- **現実性**: 高校野球の実態に近い分布

## 一般能力値の理想分布（各学年28,200人中）

### 1年生の想定（28,200人）
- **98〜100**: ほぼゼロ（0.00001%）
- **95〜97**: ほぼゼロ（0.00035%）
- **90〜94**: ほぼゼロ（0.005%）
- **85〜89**: 1人
- **80〜84**: 3人
- **75〜79**: 10人
- **70〜74**: 25人
- **60〜69**: 500人
- **50〜59**: 8,000人
- **40〜49**: 10,000人
- **30〜39**: 8,000人
- **25〜29**: 2,000人

### 2年生の想定（28,200人）
- **98〜100**: ほぼゼロ（0.00005%）
- **95〜97**: ほぼゼロ（0.0008%）
- **90〜94**: 2人（0.01%）
- **85〜89**: 3人
- **80〜84**: 10人
- **75〜79**: 50人
- **70〜74**: 150人
- **60〜69**: 800人
- **50〜59**: 4,000人
- **40〜49**: 12,000人
- **30〜39**: 9,000人
- **25〜29**: 1,000人

### 3年生の想定（28,200人）
- **98〜100**: ほぼゼロ（0.001%）
- **95〜97**: 1人（0.035%）
- **90〜94**: 3人
- **85〜89**: 6人
- **80〜84**: 15人
- **75〜79**: 100人
- **70〜74**: 250人
- **60〜69**: 1,000人
- **50〜59**: 5,000人
- **40〜49**: 13,000人
- **30〜39**: 8,000人
- **25〜29**: 1,000人

## 投手能力ベースのポジション決定システム

### ポジション決定の流れ
1. **才能ランク決定**: 選手の基本才能を決定
2. **投手能力総合評価**: 球速40% + 制球25% + スタミナ20% + 変化球15%
3. **野手能力総合評価**: 打撃50% + 守備50%
4. **バランス判定**: 投手能力と野手能力の差に基づいて投手適性を判定
5. **ポジション確定**: 投手適性に応じて最終ポジションを決定

### 投手適性判定基準

| 投手能力 - 野手能力 | 投手適性確率 | 説明 |
|---------------------|--------------|------|
| +30以上 | 90% | 投手能力が野手能力より大幅に高い |
| +20〜+29 | 75% | 投手能力が野手能力より高い |
| +10〜+19 | 60% | 投手能力が野手能力よりやや高い |
| 0〜+9 | 45% | 投手能力と野手能力が同等 |
| -10〜-1 | 30% | 野手能力が投手能力よりやや高い |
| -20〜-11 | 15% | 野手能力が投手能力より高い |
| -20未満 | 5% | 野手能力が投手能力より大幅に高い |

### 野手ポジション決定（投手能力に基づく）

| 投手能力総合スコア | 候補ポジション | 説明 |
|-------------------|----------------|------|
| 140以上 | 捕手、外野手 | 投手能力が非常に高い場合 |
| 130-139 | 捕手、外野手、三塁手 | 投手能力が高い場合 |
| 120-129 | 三塁手、遊撃手、外野手 | 投手能力が中程度の場合 |
| 120未満 | 一塁手、二塁手 | 投手能力が低い場合 |

## メインポジションによる調整

### 投手の場合
- **投手能力値**: 基本値 + 0〜20のボーナス
- **野手能力値**: 基本値のまま
- **球種**: 直球は必ず習得、他の球種（カーブ、スライダー、フォーク、チェンジアップ）はランダム習得

### 野手の場合
- **投手能力値**: 基本値のまま
- **野手能力値**: 基本値 + 0〜20のボーナス
- **球種**: なし（空のリスト）

## 隠し能力値

| 能力値 | 範囲 | 説明 |
|--------|------|------|
| 精神力 (mentalGrit) | 0.5-0.8 | 成長や試合での精神的な強さ |
| 成長スピード (growthRate) | 0.9-1.2 | 能力値の成長速度 |
| 才能基準値 (talentBase) | 60-150 | 才能ランクに基づく基準値 |
| 才能ランク (talent) | 1-6 | 選手の才能レベル（1:低、6:高） |
| 成長タイプ (growthType) | early/normal/late/spurt | 成長パターン |

## ポジション適性

各選手は全ポジションに対する適性値を持ちます：

- **メインポジション**: 70-90
- **サブポジション**: 40-70

## 球種システム（投手のみ）

### 基本球種
- **直球**: 必ず習得（変化量: なし, 潜在: 15-40）
- **カーブ**: ランダム習得（変化量: 20-60, 潜在: 25-75）
- **スライダー**: ランダム習得（変化量: 20-60, 潜在: 25-75）
- **フォーク**: ランダム習得（変化量: 20-60, 潜在: 25-75）
- **チェンジアップ**: ランダム習得（変化量: 20-60, 潜在: 25-75）

## データベース保存

すべての選手の投手と野手の両方の能力値がデータベースに保存されます：

### Playerテーブル

```sql
CREATE TABLE Player (
  id INTEGER PRIMARY KEY,
  school_id INTEGER,
  grade INTEGER,
  position TEXT,
  fame INTEGER,
  growth_rate REAL,
  talent INTEGER,
  growth_type TEXT,
  mental_grit REAL,
  peak_ability INTEGER,
  
  -- Technical（技術面）能力値
  contact INTEGER,
  power INTEGER,
  plate_discipline INTEGER,
  bunt INTEGER,
  opposite_field_hitting INTEGER,
  pull_hitting INTEGER,
  bat_control INTEGER,
  swing_speed INTEGER,
  fielding INTEGER,
  throwing INTEGER,
  catcher_ability INTEGER,
  control INTEGER,
  fastball INTEGER,
  breaking_ball INTEGER,
  pitch_movement INTEGER,
  
  -- Mental（メンタル面）能力値
  concentration INTEGER,
  anticipation INTEGER,
  vision INTEGER,
  composure INTEGER,
  aggression INTEGER,
  bravery INTEGER,
  leadership INTEGER,
  work_rate INTEGER,
  self_discipline INTEGER,
  ambition INTEGER,
  teamwork INTEGER,
  positioning INTEGER,
  pressure_handling INTEGER,
  clutch_ability INTEGER,
  
  -- Physical（フィジカル面）能力値
  acceleration INTEGER,
  agility INTEGER,
  balance INTEGER,
  jumping_reach INTEGER,
  natural_fitness INTEGER,
  injury_proneness INTEGER,
  stamina INTEGER,
  strength INTEGER,
  pace INTEGER,
  flexibility INTEGER
)
```

### PlayerPotentialsテーブル

```sql
CREATE TABLE PlayerPotentials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_id INTEGER,
  
  -- Technical（技術面）ポテンシャル
  contact_potential INTEGER,
  power_potential INTEGER,
  plate_discipline_potential INTEGER,
  bunt_potential INTEGER,
  opposite_field_hitting_potential INTEGER,
  pull_hitting_potential INTEGER,
  bat_control_potential INTEGER,
  swing_speed_potential INTEGER,
  fielding_potential INTEGER,
  throwing_potential INTEGER,
  catcher_ability_potential INTEGER,
  control_potential INTEGER,
  fastball_potential INTEGER,
  breaking_ball_potential INTEGER,
  pitch_movement_potential INTEGER,
  
  -- Mental（メンタル面）ポテンシャル
  concentration_potential INTEGER,
  anticipation_potential INTEGER,
  vision_potential INTEGER,
  composure_potential INTEGER,
  aggression_potential INTEGER,
  bravery_potential INTEGER,
  leadership_potential INTEGER,
  work_rate_potential INTEGER,
  self_discipline_potential INTEGER,
  ambition_potential INTEGER,
  teamwork_potential INTEGER,
  positioning_potential INTEGER,
  pressure_handling_potential INTEGER,
  clutch_ability_potential INTEGER,
  
  -- Physical（フィジカル面）ポテンシャル
  acceleration_potential INTEGER,
  agility_potential INTEGER,
  balance_potential INTEGER,
  jumping_reach_potential INTEGER,
  natural_fitness_potential INTEGER,
  injury_proneness_potential INTEGER,
  stamina_potential INTEGER,
  strength_potential INTEGER,
  pace_potential INTEGER,
  flexibility_potential INTEGER,
  
  FOREIGN KEY (player_id) REFERENCES Player (id)
)
```

### ScoutAnalysisテーブル

```sql
CREATE TABLE ScoutAnalysis (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_id INTEGER,
  scout_id TEXT,
  analysis_date TEXT,
  accuracy REAL,
  
  -- Technical（技術面）仮の能力値
  contact_scouted INTEGER,
  power_scouted INTEGER,
  plate_discipline_scouted INTEGER,
  bunt_scouted INTEGER,
  opposite_field_hitting_scouted INTEGER,
  pull_hitting_scouted INTEGER,
  bat_control_scouted INTEGER,
  swing_speed_scouted INTEGER,
  fielding_scouted INTEGER,
  throwing_scouted INTEGER,
  catcher_ability_scouted INTEGER,
  control_scouted INTEGER,
  fastball_scouted INTEGER,
  breaking_ball_scouted INTEGER,
  pitch_movement_scouted INTEGER,
  
  -- Mental（メンタル面）仮の能力値
  concentration_scouted INTEGER,
  anticipation_scouted INTEGER,
  vision_scouted INTEGER,
  composure_scouted INTEGER,
  aggression_scouted INTEGER,
  bravery_scouted INTEGER,
  leadership_scouted INTEGER,
  work_rate_scouted INTEGER,
  self_discipline_scouted INTEGER,
  ambition_scouted INTEGER,
  teamwork_scouted INTEGER,
  positioning_scouted INTEGER,
  pressure_handling_scouted INTEGER,
  clutch_ability_scouted INTEGER,
  
  -- Physical（フィジカル面）仮の能力値
  acceleration_scouted INTEGER,
  agility_scouted INTEGER,
  balance_scouted INTEGER,
  jumping_reach_scouted INTEGER,
  natural_fitness_scouted INTEGER,
  injury_proneness_scouted INTEGER,
  stamina_scouted INTEGER,
  strength_scouted INTEGER,
  pace_scouted INTEGER,
  flexibility_scouted INTEGER,
  
  FOREIGN KEY (player_id) REFERENCES Player (id)
)
```

### データベース構造の特徴

1. **Playerテーブル**: 選手の基本情報と現在の能力値を保存
2. **PlayerPotentialsテーブル**: 各能力値の成長上限（ポテンシャル）を保存
3. **ScoutAnalysisテーブル**: スカウトが分析した仮の能力値を保存（精度に応じた誤差あり）

### 能力値の範囲

- **現在の能力値**: 25-100（高校生レベル）
- **ポテンシャル**: 50-150（生涯を通じての成長上限）
- **スカウト分析値**: 実際の能力値に誤差を加えた値

## 設計思想

1. **現実性**: 高校野球で選手が複数ポジションを経験する現実を反映
2. **多様性**: 投手でも野手能力値を持ち、野手でも投手能力値を持つことで多様な選手タイプを表現
3. **成長性**: 隠し能力値により選手の成長パターンに個性を持たせる
4. **バランス**: メインポジションに応じた調整により、専門性と汎用性のバランスを取る
5. **希少性**: 才能ランク5の選手は0.1%の希少性を持ち、特別な価値を持つ

## 今後の拡張可能性

- ポジション変更システム
- 二刀流選手の特別処理
- 能力値の相関関係（例：球速と肩力の相関）
- 成長イベントによる能力値変動
- 怪我による能力値低下
- 世代別選手の生成（大学・社会人・NPB・MLB）
- 甲子園出場選手の特別能力値調整
- ドラフトシステムとの連携
- 学年別成長システムの実装
- 成長係数の精密計算 