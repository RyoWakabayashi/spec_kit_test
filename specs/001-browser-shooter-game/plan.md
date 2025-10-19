# Implementation Plan: ブラウザシューティングゲーム

**Branch**: `001-browser-shooter-game` | **Date**: 2025-10-19 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-browser-shooter-game/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Phoenix LiveViewを用いたリアルタイムブラウザシューティングゲームの実装。マウス操作による自機の移動と射撃、敵との戦闘、スコアシステムをLiveView Hooksで実現。DBは使用せず、スコアはブラウザのローカルストレージに保存。mise経由でElixir/Erlangをインストールし、Phoenix LiveViewプロジェクト(--no-ecto)で構築。JS-Elixir間はHooksでリアルタイム通信。

## Technical Context

**Language/Version**: Elixir (latest via mise), Erlang (latest via mise)  
**Primary Dependencies**: Phoenix Framework (LiveView), Phoenix PubSub, esbuild (JS bundler)  
**Storage**: Browser LocalStorage (no database, --no-ecto)  
**Testing**: ExUnit (Elixir標準), Phoenix.LiveViewTest  
**Target Platform**: Modern browsers (Chrome 88+, Firefox 85+, Safari 14+) with WebSocket support  
**Project Type**: Web application (Phoenix LiveView SPA-like)  
**Performance Goals**: 60fps gameplay, <16ms frame time, <50ms server response time  
**Constraints**: <100MB memory per client, real-time mouse tracking, continuous bullet firing during click  
**Scale/Scope**: Single-player game, ~5-10 LiveView components, LocalStorage persistence only

**Additional Requirements**:
- mise環境管理ツールでElixir/Erlangのインストール
- `mix phx.new` with `--no-ecto` flag
- LiveView Hooks for JS-Elixir real-time communication
- Canvas or SVG rendering for game graphics (NEEDS CLARIFICATION)
- Game loop implementation strategy (server-side tick vs client-side animation frame) (NEEDS CLARIFICATION)
- Collision detection approach (server vs client) (NEEDS CLARIFICATION)
- Enemy spawning and AI patterns (NEEDS CLARIFICATION)
- Bullet firing rate limiting (NEEDS CLARIFICATION)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Real-Time First**: LiveView PubSub + Hooks for real-time mouse/click events, server broadcasts game state at 60fps
- [x] **Functional Game Logic**: Game state as immutable Elixir data structures, pure functions for collision detection and entity updates
- [x] **LiveView Component Architecture**: Separate components for StartScreen, GameScreen, Player, Enemy, Bullet, ScoreDisplay, GameOver
- [x] **Performance-First Rendering**: Phoenix diff-based updates, game loop with frame time monitoring, batched state updates
- [x] **Test-Driven Development**: ExUnit for game logic, LiveViewTest for multiplayer scenarios (適用: シングルプレイだが同様のテスト手法)

**Notes**: 
- シングルプレイヤーゲームだがconstitutionの「multiplayer」原則は同様に適用（複数のゲームセッションが同時実行可能）
- LocalStorage使用はconstitutionに抵触せず（サーバーが真実のソースであることは維持）

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
shooter_game/                    # Phoenix project root (mix phx.new shooter_game --no-ecto)
├── lib/
│   ├── shooter_game/
│   │   ├── game/               # Game logic (pure functions)
│   │   │   ├── state.ex        # Game state struct
│   │   │   ├── player.ex       # Player entity logic
│   │   │   ├── enemy.ex        # Enemy entity logic
│   │   │   ├── bullet.ex       # Bullet entity logic
│   │   │   ├── collision.ex    # Collision detection
│   │   │   └── spawner.ex      # Enemy spawning logic
│   │   └── application.ex      # Application supervisor
│   └── shooter_game_web/
│       ├── live/
│       │   ├── game_live.ex           # Main game LiveView
│       │   ├── start_screen_live.ex   # Start screen component
│       │   └── components/
│       │       ├── player_component.ex
│       │       ├── enemy_component.ex
│       │       ├── bullet_component.ex
│       │       └── score_display_component.ex
│       ├── components/
│       │   └── core_components.ex
│       ├── router.ex
│       └── endpoint.ex
├── assets/
│   ├── js/
│   │   ├── app.js
│   │   └── hooks/
│   │       ├── game_hook.js    # Main game loop hook
│   │       ├── mouse_hook.js   # Mouse tracking hook
│   │       └── storage_hook.js # LocalStorage hook
│   └── css/
│       └── app.css
└── test/
    ├── shooter_game/
    │   └── game/               # Unit tests for game logic
    │       ├── collision_test.exs
    │       ├── player_test.exs
    │       ├── enemy_test.exs
    │       └── spawner_test.exs
    └── shooter_game_web/
        └── live/               # Integration tests
            └── game_live_test.exs
```

**Structure Decision**: Phoenix LiveView web application structure selected. Game logic isolated in `lib/shooter_game/game/` as pure functions, LiveView components in `lib/shooter_game_web/live/`, client-side hooks in `assets/js/hooks/`. This aligns with Phoenix conventions and constitution's functional + component architecture principles.

## Complexity Tracking

No violations detected. All constitution principles are satisfied:

- Real-time updates via LiveView PubSub and Hooks
- Functional game logic with immutable data structures
- Component-based architecture
- Performance-optimized rendering (60fps client, 30fps server)
- Test-driven development with ExUnit and LiveViewTest

No additional complexity justification required.

