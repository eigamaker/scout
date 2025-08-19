# スカウトシステム設計ドキュメント v2.0

## 概要
高校野球のスカウトシステムを設計します。スカウトは段階的なアクションを通じて選手情報を収集し、球団にレポートを提出する役割を担います。

## 1. スカウトスキルセット（8項目）

| スキル | 定義 | 主な関連行動 | 効果 |
|--------|------|------------|------|
| **探索 (Exploration)** | 隠れた才能・注目選手の発見 | 練習視察、情報交換 | 隠れた才能の発掘、注目選手の早期発見 |
| **観察 (Observation)** | 実パフォーマンス計測精度 | 試合観戦、練習試合観戦 | 試合中の細かい動きを見抜く、正確な能力値評価 |
| **分析 (Analysis)** | データ統合と将来予測 | ビデオ分析、レポート作成 | 統計・技術的評価、将来性の予測 |
| **洞察 (Insight)** | 潜在才能・怪我リスク察知 | ビデオ分析、情報交換 | 選手の内面・将来性を見る、リスク評価 |
| **コミュニケーション (Communication)** | 面談・信頼構築 | インタビュー、情報交換 | 選手・関係者との対話、信頼関係の構築 |
| **交渉 (Negotiation)** | 利害調整・提案採用率 | 球団訪問、レポート作成 | 球団との調整・提案、レポートの質向上 |
| **体力 (Stamina)** | 遠征疲労耐性 | 全アクション | 行動回数・効率に影響、疲労軽減 |
| **直観 (Intuition)** | 一瞬の判断・予感 | 全アクション（補助） | 予期しない発見・危機回避、ボーナス効果 |

### スキル値の範囲
- **初期値**: 1-5（スカウトの経験レベルに応じて）
- **最大値**: 10
- **成長**: アクション実行時に経験値を獲得

## 2. アクション定義と取得可能情報

### 2.1 基本アクション

| ID | 行動 | AP | ¥ | 取得可能情報 | 成功判定 | 直観効果 |
|----|------|----|----|------------|---------|---------|
| PRAC_WATCH | 練習視察 | 2 | 20k | **基本情報**、**フィジカル面能力値**、**ポテンシャル基準発掘** | 60% + 探索×8% | 隠れた才能発見（全選手対象） |
| GAME_WATCH | 試合観戦 | 3 | 50k | **技術面・フィジカル面能力値**、**高能力値選手発掘** | 55% + 観察×4% | 重要な瞬間を捉える（レギュラーのみ） |
| SCRIMMAGE | 練習試合観戦 | 2 | 30k | **技術面能力値**、**高能力値選手発掘** | 50% + 観察×4% | 隠れた実力発見（レギュラーのみ） |
| INTERVIEW | インタビュー | 1 | 10k | **性格**、**精神力**、**メンタル面能力値** | 65% + コミュ×4% | 本音を引き出す |
| VIDEO_ANALYZE | ビデオ分析 | 2 | 0 | **才能**、**成長タイプ**、**ポテンシャル** | 70% + 分析×3% | 技術的発見 |

### 2.2 取得情報の詳細

#### 基本情報（PRAC_WATCH）
- 名前、学校、学年、ポジション
- **自動取得**（100%精度）

#### フィジカル面能力値（PRAC_WATCH, GAME_WATCH）
- 走力、加速力、敏捷性、バランス、ジャンプ力、自然体力、持久力、筋力、怪我しやすさ
- **判定精度**: 観察×0.7 + 分析×0.3

#### 技術面能力値（GAME_WATCH, SCRIMMAGE）
- 投手：球速、制球、変化球、投球術
- 野手：パワー、バットコントロール、守備、肩力
- **判定精度**: 観察×0.7 + 分析×0.3

#### メンタル面能力値（INTERVIEW）
- 勤勉さ、自己管理、プレッシャー耐性、勝負強さ、リーダーシップ、チームワーク
- **判定精度**: コミュニケーション×0.7 + 洞察×0.3

#### 成長・ポテンシャル情報（VIDEO_ANALYZE）
- 才能ランク、成長タイプ、ポテンシャル
- **判定精度**: 分析×0.6 + 洞察×0.4

### 2.3 選手発掘ルール

#### 練習視察（PRAC_WATCH）
- **発掘基準**: ポテンシャル重視
- **対象**: 全選手（現在能力値に関係なく）
- **発掘ロジック**: 
  - `peakAbility >= 120`: 発掘確率+40%
  - `talent >= 8`: 発掘確率+30%
  - `growthRate >= 0.8`: 発掘確率+20%
  - **隠れた才能ボーナス**: `trueTotalAbility < 60 && peakAbility >= 100`の場合+30%

#### 試合観戦・練習試合観戦（GAME_WATCH, SCRIMMAGE）
- **発掘基準**: 現在能力値重視
- **対象**: レギュラー選手のみ（`trueTotalAbility >= 70`）
- **発掘ロジック**: 高能力値選手を優先的に発掘

## 3. 精度計算システム

### 3.1 基本精度計算式
```
基本精度 = (プライマリスキル値 × プライマリ係数 + サブスキル値 × サブ係数) × 8
視察回数ボーナス = min(視察回数 × 2, 20)  // 最大20%のボーナス
直観ボーナス = 直観スキル値 × 0.8
時間ペナルティ = 1年経過後に徐々に低下（最大20%）

最終精度 = 基本精度 + 視察回数ボーナス + 直観ボーナス - 時間ペナルティ
最終精度 = min(最終精度, 95)  // 最大95%に制限
```

### 3.2 係数設定
- **プライマリ係数**: 0.7（70%の重み）
- **サブ係数**: 0.3（30%の重み）

### 3.3 精度レベル判定と誤差範囲
| 精度範囲 | 判定結果 | 誤差範囲 | 説明 |
|---------|---------|---------|------|
| 0-9% | 判定失敗 | 情報取得不可 | スカウトが情報を把握できない |
| 10-29% | 非常に不正確 | ±20 | 大まかな推測レベル |
| 30-49% | 不正確 | ±16 | 概算レベル |
| 50-69% | やや正確 | ±12 | 実用レベル |
| 70-84% | 正確 | ±8 | 信頼できるレベル |
| 85-94% | 非常に正確 | ±6 | 高精度レベル |
| 95% | 最大精度 | ±3 | 人間の限界 |

### 3.4 スキルレベル別期待精度
| スキルレベル | プライマリ単体 | プライマリ+サブ | 最終精度（直観込み） |
|-------------|---------------|----------------|-------------------|
| レベル1 | 5.6% | 8.0% | 8.8% |
| レベル2 | 11.2% | 16.0% | 17.6% |
| レベル3 | 16.8% | 24.0% | 26.4% |
| レベル4 | 22.4% | 32.0% | 35.2% |
| レベル5 | 28.0% | 40.0% | 44.0% |
| レベル6 | 33.6% | 48.0% | 52.8% |
| レベル7 | 39.2% | 56.0% | 61.6% |
| レベル8 | 44.8% | 64.0% | 70.4% |
| レベル9 | 50.4% | 72.0% | 79.2% |
| レベル10 | 56.0% | 80.0% | 88.0% |

## 4. 段階的スカウトシステム

### 4.1 スカウトフロー
```
1. 練習視察（PRAC_WATCH）
   ↓ 基本情報 + フィジカル面能力値を取得
   
2. 試合観戦・練習試合観戦（GAME_WATCH, SCRIMMAGE）
   ↓ 技術面能力値を取得
   
3. インタビュー（INTERVIEW）
   ↓ メンタル面能力値を取得
   
4. ビデオ分析（VIDEO_ANALYZE）
   ↓ 成長・ポテンシャル情報を取得
   
5. レポート作成（REPORT_WRITE）
   ↓ 総合評価・将来予測
```

### 4.2 情報取得の制限

#### 練習視察（PRACTICE_WATCH）
**分析対象カラム:**
- **基本情報**: `personality_scouted`, `talent_scouted`, `growth_scouted`, `mental_scouted`, `potential_scouted`
- **フィジカル面能力値**: `acceleration_scouted`, `agility_scouted`, `balance_scouted`, `stamina_scouted`, `strength_scouted`, `pace_scouted`, `flexibility_scouted`, `jumping_reach_scouted`, `natural_fitness_scouted`, `injury_proneness_scouted`
- **技術面能力値（一部）**: `fielding_scouted`, `throwing_scouted`, `bat_control_scouted`

**取得不可**: 技術面の詳細能力値、メンタル面能力値

#### 試合観戦（GAME_WATCH）
**分析対象カラム:**
- **技術面能力値**: `contact_scouted`, `power_scouted`, `plate_discipline_scouted`, `bunt_scouted`, `opposite_field_hitting_scouted`, `pull_hitting_scouted`, `bat_control_scouted`, `swing_speed_scouted`, `fielding_scouted`, `throwing_scouted`, `catcher_ability_scouted`, `control_scouted`, `fastball_scouted`, `breaking_ball_scouted`, `pitch_movement_scouted`
- **フィジカル面能力値**: `pace_scouted`, `acceleration_scouted`, `agility_scouted`, `balance_scouted`, `jumping_reach_scouted`, `stamina_scouted`, `strength_scouted`, `flexibility_scouted`, `natural_fitness_scouted`, `injury_proneness_scouted`

**取得不可**: 基本情報、メンタル面能力値

#### 練習試合観戦（PRACTICE_GAME_WATCH）
**分析対象カラム:**
- **技術面能力値**: `contact_scouted`, `power_scouted`, `plate_discipline_scouted`, `bunt_scouted`, `opposite_field_hitting_scouted`, `pull_hitting_scouted`, `bat_control_scouted`, `swing_speed_scouted`, `fielding_scouted`, `throwing_scouted`, `catcher_ability_scouted`, `control_scouted`, `fastball_scouted`, `breaking_ball_scouted`, `pitch_movement_scouted`

**取得不可**: 基本情報、フィジカル面能力値、メンタル面能力値

#### インタビュー（INTERVIEW）
**分析対象カラム:**
- **基本情報（一部）**: `personality_scouted`, `mental_scouted`
- **メンタル面能力値**: `concentration_scouted`, `anticipation_scouted`, `vision_scouted`, `composure_scouted`, `aggression_scouted`, `bravery_scouted`, `leadership_scouted`, `work_rate_scouted`, `self_discipline_scouted`, `ambition_scouted`, `teamwork_scouted`, `positioning_scouted`, `pressure_handling_scouted`, `clutch_ability_scouted`, `motivation_scouted`, `adaptability_scouted`, `consistency_scouted`

**取得不可**: `talent_scouted`, `growth_scouted`, `potential_scouted`, 技術面・フィジカル面能力値

#### ビデオ分析（VIDEO_ANALYZE）
**分析対象カラム:**
- **基本情報**: `personality_scouted`, `talent_scouted`, `growth_scouted`, `mental_scouted`, `potential_scouted`
- **技術面能力値**: `contact_scouted`, `power_scouted`, `plate_discipline_scouted`, `bunt_scouted`, `opposite_field_hitting_scouted`, `pull_hitting_scouted`, `bat_control_scouted`, `swing_speed_scouted`, `fielding_scouted`, `throwing_scouted`, `catcher_ability_scouted`, `control_scouted`, `fastball_scouted`, `breaking_ball_scouted`, `pitch_movement_scouted`

**取得不可**: フィジカル面能力値、メンタル面能力値

#### レポート作成（REPORT_WRITE）
**分析対象カラム:**
- **総合評価指標**: `overall_evaluation`, `technical_evaluation`, `physical_evaluation`, `mental_evaluation`

**取得不可**: 個別能力値（既に分析済みの情報を統合・評価）

### 4.3 スカウト完了度システム
- **計算式**: 取得済み情報カテゴリ数 / 全情報カテゴリ数
- **表示段階**:
  - 0.0-0.2: 初期スカウト（オレンジ）
  - 0.2-0.4: 基本調査済み（黄色）
  - 0.4-0.6: 詳細調査中（ライトブルー）
  - 0.6-0.8: ほぼ完了（ブルー）
  - 0.8-1.0: 完全スカウト済み（グリーン）

## 5. 選手発掘システム

### 5.1 発掘基準の明確化

#### 練習視察による発掘
- **目的**: 隠れた才能の発見
- **基準**: ポテンシャル、才能、成長率
- **メリット**: 将来有望な選手を早期発見
- **デメリット**: 現在の実力は未知数

#### 試合観戦による発掘
- **目的**: 実力のある選手の発見
- **基準**: 現在の総合能力値
- **メリット**: 即戦力選手の発見
- **デメリット**: 既に注目されている可能性

### 5.2 発掘確率計算
```
基本発掘確率 = 10%（ベース）

// 練習視察の場合
if (peakAbility >= 120) 発掘確率 += 40%
if (talent >= 8) 発掘確率 += 30%
if (growthRate >= 0.8) 発掘確率 += 20%
if (trueTotalAbility < 60 && peakAbility >= 100) 発掘確率 += 30% // 隠れた才能

// 試合観戦の場合
if (trueTotalAbility >= 70) 発掘確率 = 80%
if (trueTotalAbility >= 80) 発掘確率 = 95%
```

## 6. バランス調整

### 6.1 アクションコストの調整
- **練習視察**: AP2, ¥20k（基本的な調査）
- **試合観戦**: AP3, ¥50k（詳細な観察）
- **練習試合観戦**: AP2, ¥30k（中程度の調査）
- **インタビュー**: AP1, ¥10k（効率的な情報収集）
- **ビデオ分析**: AP2, ¥0（時間はかかるが無料）

### 6.2 情報価値のバランス
- 各アクションで取得できる情報を明確に分離
- 段階的なスカウト活動を促進
- 完全な情報取得には複数のアクションが必要

## 7. 実装上の注意点

### 7.1 情報取得の制限実装
- 各アクションで取得可能な情報カテゴリを厳密に制限
- 練習視察だけでは技術面やメンタル面の詳細は取得不可
- 段階的なスカウト活動を強制

### 7.2 精度計算の統一
- 全ての情報取得で統一された精度計算式を使用
- 誤差範囲の適用を確実に実装
- 真の能力値は表示せず、常に誤差を含んだ値を表示

### 7.3 発掘ロジックの分離
- 練習視察と試合観戦で異なる発掘ロジックを実装
- 各アクションの特性を明確に区別
- プレイヤーに戦略的な選択を促す設計

## 8. 今後の拡張

### 8.1 短期拡張
- 地域別スカウト活動
- 季節による情報取得効率の変化
- スカウト間の情報共有システム

### 8.2 中期拡張
- 選手の成長予測システム
- 球団ニーズに基づくスカウト戦略
- レポートの質による球団評価システム

### 8.3 長期拡張
- AIスカウトとの競争システム
- 国際スカウト活動
- 選手エージェントとの交渉システム

---

このシステムにより、段階的で戦略的なスカウト活動が実現され、各アクションに明確な価値と役割が与えられます。
