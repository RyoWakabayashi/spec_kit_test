# Data Model: 敵難易度の段階的スケーリング

**Feature**: 002-enemy-difficulty-scaling  
**Date**: 2025年10月19日  
**Status**: Complete

## Entity Overview

本機能では以下の新規エンティティと既存エンティティの拡張を行います:

1. **DifficultyLevel** (新規): 難易度レベルの設定
2. **MovementPattern** (新規): 敵の移動パターン定義
3. **State** (拡張): 難易度レベル情報を追加
4. **Enemy** (拡張): 移動パターンと耐久力スケーリング対応

## Entity Definitions

### 1. DifficultyLevel (新規エンティティ)

難易度レベルごとのゲームバランス設定を管理するエンティティ。

**Location**: `lib/shooter_game/game/difficulty_level.ex`

**Fields**:

| Field | Type | Required | Default | Description | Validation |
|-------|------|----------|---------|-------------|------------|
| level | pos_integer | Yes | 1 | 現在の難易度レベル | >= 1, <= 15 |
| spawn_interval_ms | pos_integer | Yes | 2000 | 敵出現間隔（ミリ秒） | >= 500, <= 3000 |
| max_enemies | pos_integer | Yes | 5 | 画面上の最大敵数 | >= 1, <= 20 |
| enemy_health_multiplier | float | Yes | 1.0 | 敵耐久力の倍率 | >= 1.0, <= 5.0 |
| fire_interval_ms | pos_integer | Yes | 3000 | 敵弾発射間隔（ミリ秒） | >= 1000, <= 5000 |
| movement_patterns | [atom] | Yes | [:linear] | 使用可能な移動パターンリスト | 有効なパターン名のみ |

**Relationships**:
- 1対1: State → DifficultyLevel (has one)
- 1対多: DifficultyLevel → MovementPattern (references multiple patterns)

**State Transitions**:
```
Level 1 → Level 2 → Level 3 → ... → Level 15 (max)
     ↑                                    |
     └────────────────────────────────────┘
            (game restart)
```

**Invariants**:
- レベルは1から開始し、単調増加のみ
- 10秒ごとに正確に1レベル上昇
- レベル15に到達後は値を維持

**Derived Values**:
- `seconds_to_next_level`: 次のレベルまでの残り秒数 = `10 - (elapsed_time / 1000) % 10`
- `base_enemy_health`: レベルに基づく基礎耐久力 = `floor(1 + (level - 1) * 0.5)`

### 2. MovementPattern (新規エンティティ)

敵の移動パターンの定義と実行ロジック。

**Location**: `lib/shooter_game/game/movement_pattern.ex`

**Pattern Types** (Atom-based enumeration):

| Pattern | Level Introduced | Parameters | Description |
|---------|------------------|------------|-------------|
| :linear | 1 | - | 固定速度で直線移動 |
| :zigzag | 2 | amplitude, frequency | X軸方向に周期的な方向転換 |
| :sine_wave | 3 | amplitude, wavelength | サイン波軌道 |
| :circular | 4 | radius, angular_velocity | 円運動 |
| :spiral | 5 | radius_decay, angular_velocity | 螺旋軌道 |
| :random_walk | 5 | change_interval, max_velocity | ランダムな方向転換 |

**Pattern Configuration Structure**:
```elixir
%{
  pattern_type: atom(),          # パターン識別子
  params: map(),                 # パターン固有のパラメータ
  spawn_time: integer()          # パターン開始時刻（計算用）
}
```

**Behavior Functions**:
- `apply_pattern(enemy, pattern_config, current_time, game_bounds)`: 
  - 入力: Enemy構造体, パターン設定, 現在時刻, ゲーム境界
  - 出力: 更新されたEnemy構造体（位置・速度変更済み）
  - 純粋関数（副作用なし）

**Validation Rules**:
- パターン適用後の座標は必ずゲーム境界内
- 速度は最大値を超えない（max_velocity設定）
- 時間ベースの計算でフレームレート非依存

### 3. State (既存エンティティの拡張)

**Location**: `lib/shooter_game/game/state.ex`

**追加フィールド**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| difficulty_level | DifficultyLevel.t() | Yes | DifficultyLevel.new(1) | 現在の難易度設定 |
| last_difficulty_update | integer | Yes | 0 | 最後に難易度が更新された時刻（elapsed_time基準） |

**Modified Fields**: なし（既存フィールドはそのまま）

**New Functions**:
- `update_difficulty(state)`: 経過時間に基づき難易度レベルを更新
- `should_increase_difficulty?(state)`: 難易度上昇条件を判定

**Relationships**:
- State has one DifficultyLevel
- State has many Enemies (既存)
- State has many Bullets (player/enemy) (既存)

### 4. Enemy (既存エンティティの拡張)

**Location**: `lib/shooter_game/game/enemy.ex`

**追加フィールド**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| movement_pattern | map() | Yes | %{pattern_type: :linear, params: %{}, spawn_time: 0} | 移動パターン設定 |
| max_health | pos_integer | Yes | 1 | 最大耐久力（倒すのに必要なヒット数） |

**Modified Fields**:

| Field | Before | After | Reason |
|-------|--------|-------|--------|
| health | 常に1 | DifficultyLevelから計算 | レベルに応じた耐久力スケーリング |
| fire_interval_ms | 固定2000ms | DifficultyLevelから取得 | レベルに応じた発射間隔調整 |

**New Functions**:
- `new_with_difficulty(x, y, difficulty_level)`: 難易度レベルを考慮した敵生成
- `update_movement(enemy, current_time, game_bounds)`: 移動パターンに基づく位置更新
- `calculate_health(difficulty_level)`: レベルから耐久力を計算

**State Transitions** (Health):
```
max_health → (hit) → health - 1 → ... → 0 (destroyed)
```

### 5. Bullet (既存エンティティ - 変更なし)

**Location**: `lib/shooter_game/game/bullet.ex`

敵弾用のBulletは既存の実装をそのまま使用。`owner: :enemy`で区別。

**Note**: 敵弾の速度や見た目は将来的に調整可能だが、本機能では既存実装を維持。

## Entity Relationships Diagram

```
State
├── player: Player
├── enemies: [Enemy]
│   └── movement_pattern: MovementPattern config
├── player_bullets: [Bullet]
├── enemy_bullets: [Bullet]
├── difficulty_level: DifficultyLevel
│   └── movement_patterns: [atom] (参照)
└── last_difficulty_update: integer

DifficultyLevel (configuration entity)
└── defines parameters for current level

MovementPattern (behavior module)
└── provides pure functions for enemy movement
```

## Data Flow

### 難易度レベル上昇フロー

1. **Game Tick** (`handle_info(:game_tick, ...)`)
2. **Check Elapsed Time**: `state.elapsed_time` が10秒倍数を超えたか判定
3. **Update Difficulty**: `DifficultyLevel.next_level(state.difficulty_level)`
4. **Apply to State**: 新しいDifficultyLevelをStateに反映
5. **Notify Client**: LiveView assignを更新してUI再描画
6. **Trigger Feedback**: JSフック経由でレベルアップアニメーション

### 敵生成フロー (難易度考慮)

1. **Spawn Timer Check**: 現在時刻とlast_spawn_timeの差分チェック
2. **Get Difficulty**: `state.difficulty_level`から設定取得
3. **Count Check**: `length(state.enemies) < difficulty_level.max_enemies`
4. **Pattern Selection**: `difficulty_level.movement_patterns`からランダム選択
5. **Create Enemy**: `Enemy.new_with_difficulty(x, y, difficulty_level, pattern)`
6. **Add to State**: enemiesリストに追加

### 敵移動更新フロー

1. **For Each Enemy**: enemiesリストをEnumerate
2. **Get Pattern**: `enemy.movement_pattern`
3. **Apply Movement**: `MovementPattern.apply_pattern(enemy, pattern, time, bounds)`
4. **Update Position**: 新しい座標を計算
5. **Boundary Check**: 画面外判定、削除処理
6. **Update State**: 新しいenemiesリストをStateに反映

### 敵弾発射フロー (既存機能の活用)

1. **For Each Enemy**: 生存中の全敵をチェック
2. **Fire Check**: `Enemy.can_fire?(enemy)` - fire_interval_ms考慮
3. **Create Bullet**: `Enemy.fire_bullet(enemy)` - プレイヤー方向計算
4. **Add to State**: enemy_bulletsリストに追加
5. **Update Enemy**: last_fire_timeを更新

### 衝突判定・耐久力処理フロー

1. **Bullet-Enemy Collision**: 既存のbounding box判定
2. **Apply Damage**: `Enemy.take_damage(enemy, 1)`
3. **Health Check**: `enemy.health <= 0`で破壊判定
4. **Score Update**: 破壊された敵のscore_valueを加算
5. **Remove Entities**: 破壊された敵と当たった弾を削除

## Validation Rules Summary

### DifficultyLevel Validation

- レベル範囲: 1 <= level <= 15
- 出現間隔: 500 <= spawn_interval_ms <= 3000
- 最大敵数: 1 <= max_enemies <= 20
- 耐久力倍率: 1.0 <= enemy_health_multiplier <= 5.0
- 発射間隔: 1000 <= fire_interval_ms <= 5000

### Enemy Validation

- 座標範囲: 0 <= x <= game_width, 0 <= y <= game_height
- 耐久力: 0 <= health <= max_health
- 移動パターン: pattern_type は定義済みパターンのみ
- 速度制限: velocity_x, velocity_y は絶対値 <= 10.0

### MovementPattern Validation

- パターン適用後の座標は必ずゲーム境界内に補正
- パラメータの妥当性チェック（例: amplitude > 0）
- 時間計算のオーバーフロー防止

## Performance Considerations

### メモリ使用量

- DifficultyLevel: ~200 bytes per instance (1 instance per game)
- MovementPattern config: ~100 bytes per enemy
- 最大敵数20 × 100 bytes = 2KB (negligible)

### 計算コスト

- 難易度更新: O(1) - 10秒ごとに1回のみ
- 移動パターン計算: O(n) where n = 敵数
  - 1体あたり: ~0.05-0.1ms (三角関数含む)
  - 20体合計: ~2ms (16ms予算の12.5%)
- 耐久力計算: O(1) - 敵生成時のみ

### 最適化戦略

1. **パターン計算のメモ化**: 同じ時刻での重複計算を避ける
2. **バッチ更新**: 全敵の更新を1回のassignにまとめる
3. **早期終了**: 画面外の敵は移動計算をスキップ

## Testing Strategy

### Unit Tests

**DifficultyLevel**:
- `new/1`: デフォルト値検証
- `next_level/1`: レベル遷移ロジック
- `get_config/1`: レベル別パラメータ取得
- Edge case: レベル15到達後の挙動

**MovementPattern**:
- 各パターンの数学的正確性（座標計算）
- 境界条件での挙動（画面端）
- パラメータ異常値での安全性

**Enemy** (拡張部分):
- `new_with_difficulty/3`: 難易度反映確認
- `update_movement/3`: パターン適用結果
- `calculate_health/1`: 耐久力計算正確性

### Integration Tests

**Game Flow**:
- 10秒ごとの難易度上昇シナリオ
- レベル上昇時の敵パラメータ変化確認
- 複数パターンの敵が同時に動作
- 耐久力の異なる敵の撃破シナリオ

### Property-Based Tests (オプション)

- ランダムな経過時間での難易度レベル整合性
- ランダムな移動パターンパラメータでの座標範囲保証

## Migration from Current State

既存のゲームコードへの影響を最小化するための移行戦略:

1. **DifficultyLevel導入**: Stateに追加、デフォルト値でレベル1相当を維持
2. **Enemy拡張**: 既存の`new/2`は残し、`new_with_difficulty/3`を追加
3. **段階的有効化**: フィーチャーフラグで新機能を制御可能に（オプション）
4. **後方互換性**: 既存のテストが全て通ることを確認

## Open Design Questions

### Q1: 難易度レベルリセットタイミング

**Question**: ゲームオーバー時に難易度レベルを1にリセットするか、維持するか？

**Decision**: リセットする（毎ゲームレベル1から開始）

**Rationale**: プレイヤーが毎回同じスタート地点から挑戦できる公平性を重視

### Q2: 敵の移動パターン選択方法

**Question**: 同一レベル内で複数パターンが有効な場合、完全ランダムか重み付けか？

**Decision**: 完全ランダム（現時点）

**Rationale**: シンプル実装優先。将来的にバランス調整で重み付け追加可能

### Q3: レベルアップ通知のタイミング

**Question**: レベルアップ直後に通知か、少し遅延させるか？

**Decision**: 即座に通知（視覚的フィードバック重視）

**Rationale**: プレイヤーに明確な進行感を提供

## Summary

本データモデル設計により:

✅ 難易度レベルシステムの型安全な実装基盤  
✅ 拡張可能な移動パターンアーキテクチャ  
✅ 既存コードへの影響最小化  
✅ パフォーマンス目標（60fps）達成可能な設計  
✅ テスト可能な純粋関数ベースの状態遷移

次のステップ: APIコントラクト定義（LiveViewイベント/フック）
