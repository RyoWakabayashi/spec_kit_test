---
description: "Implementation tasks for browser shooter game"
---

# Tasks: ブラウザシューティングゲーム

**Input**: Design documents from `/specs/001-browser-shooter-game/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/liveview-events.md

**Tests**: Test tasks are included per TDD approach specified in constitution.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Project root: `shooter_game/`
- Game logic: `shooter_game/lib/shooter_game/game/`
- LiveView: `shooter_game/lib/shooter_game_web/live/`
- JavaScript Hooks: `shooter_game/assets/js/hooks/`
- Tests: `shooter_game/test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic Phoenix LiveView structure

- [X] T001 Verify mise installation and install Elixir/Erlang per quickstart.md
- [X] T002 Create Phoenix project with `mix phx.new shooter_game --no-ecto`
- [X] T003 [P] Create directory structure: lib/shooter_game/game, lib/shooter_game_web/live/components, assets/js/hooks
- [X] T004 [P] Configure PubSub in shooter_game/lib/shooter_game/application.ex
- [X] T005 [P] Setup esbuild configuration in shooter_game/config/config.exs for JavaScript bundling
- [X] T006 [P] Add Canvas CSS styles in shooter_game/assets/css/app.css
- [X] T007 Verify development server starts with `mix phx.server` and loads on <http://localhost:4000>

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core game entities and infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T008 [P] Define GameState struct in shooter_game/lib/shooter_game/game/state.ex with all fields per data-model.md
- [X] T009 [P] Define Player struct in shooter_game/lib/shooter_game/game/player.ex
- [X] T010 [P] Define Enemy struct in shooter_game/lib/shooter_game/game/enemy.ex
- [X] T011 [P] Define Bullet struct in shooter_game/lib/shooter_game/game/bullet.ex
- [X] T012 [P] Implement AABB collision detection in shooter_game/lib/shooter_game/game/collision.ex
- [X] T013 [P] Write unit tests for collision detection in shooter_game/test/shooter_game/game/collision_test.exs
- [X] T014 Create base GameLive module in shooter_game/lib/shooter_game_web/live/game_live.ex with mount/3
- [X] T015 Add route for GameLive in shooter_game/lib/shooter_game_web/router.ex
- [X] T016 [P] Setup JavaScript hooks registration in shooter_game/assets/js/app.js

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - ゲーム開始とプレイ (Priority: P1) 🎯 MVP

**Goal**: ユーザーは開始画面からゲームを開始し、マウスで自機を操作して弾を発射できる

**Independent Test**: 開始画面→ゲーム画面遷移、マウス移動で自機が追従、クリックで弾発射を確認


### Tests for User Story 1

**Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T017 [P] [US1] Write LiveViewTest for start screen rendering in shooter_game/test/shooter_game_web/live/game_live_test.exs
- [ ] T018 [P] [US1] Write LiveViewTest for start_game event transition in shooter_game/test/shooter_game_web/live/game_live_test.exs
- [ ] T019 [P] [US1] Write unit test for Player.move_to/3 in shooter_game/test/shooter_game/game/player_test.exs
- [ ] T020 [P] [US1] Write unit test for Player.fire_bullet/2 with cooldown in shooter_game/test/shooter_game/game/player_test.exs

### Implementation for User Story 1

- [ ] T021 [P] [US1] Implement start screen component in shooter_game/lib/shooter_game_web/live/start_screen_live.ex
- [ ] T022 [P] [US1] Create StartScreen template with START button in shooter_game/lib/shooter_game_web/live/start_screen_live.html.heex
- [ ] T023 [US1] Implement handle_event("start_game") in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T024 [US1] Initialize GameState in GameLive mount with player centered at (game_width/2, game_height - 100)
- [ ] T025 [P] [US1] Create MouseHook in shooter_game/assets/js/hooks/mouse_hook.js for mouse_move, mouse_down, mouse_up events
- [ ] T026 [US1] Implement handle_event("mouse_move") in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T027 [P] [US1] Implement Player.move_to/3 function in shooter_game/lib/shooter_game/game/player.ex
- [ ] T028 [US1] Implement handle_event("mouse_down") to set player.is_firing = true in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T029 [US1] Implement handle_event("mouse_up") to set player.is_firing = false in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T030 [P] [US1] Implement Player.fire_bullet/2 with cooldown logic in shooter_game/lib/shooter_game/game/player.ex
- [ ] T031 [P] [US1] Create GameHook in shooter_game/assets/js/hooks/game_hook.js with Canvas rendering and requestAnimationFrame loop
- [ ] T032 [US1] Add Canvas element with phx-hook="Game" in shooter_game/lib/shooter_game_web/live/game_live.html.heex
- [ ] T033 [US1] Implement game loop with Process.send_after(:tick, 33) in shooter_game/lib/shooter_game_web/live/game_live.ex for 30fps server tick
- [ ] T034 [US1] Implement handle_info(:tick) to update bullets and push_event("game_state") in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T035 [P] [US1] Implement bullet movement logic in shooter_game/lib/shooter_game/game/bullet.ex
- [ ] T036 [P] [US1] Implement Canvas rendering for player, bullets in shooter_game/assets/js/hooks/game_hook.js
- [ ] T037 [US1] Add bullet spawning logic in game tick when player.is_firing == true in shooter_game/lib/shooter_game/game/state.ex

**Checkpoint**: At this point, User Story 1 should be fully functional - start game, move player with mouse, fire bullets on click

---

## Phase 4: User Story 2 - 敵との戦闘とスコアシステム (Priority: P2)

**Goal**: 敵が出現し、弾の当たり判定でスコア加算とゲームオーバーを実現

**Independent Test**: 敵出現、自機の弾で敵を倒すとスコア加算、敵の弾で被弾するとゲームオーバーを確認

### Tests for User Story 2

- [ ] T038 [P] [US2] Write unit test for Spawner.should_spawn?/1 in shooter_game/test/shooter_game/game/spawner_test.exs
- [ ] T039 [P] [US2] Write unit test for Spawner.spawn_enemy/1 in shooter_game/test/shooter_game/game/spawner_test.exs
- [ ] T040 [P] [US2] Write unit test for Enemy.fire_bullet/2 in shooter_game/test/shooter_game/game/enemy_test.exs
- [ ] T041 [P] [US2] Write unit test for player bullet vs enemy collision in shooter_game/test/shooter_game/game/collision_test.exs
- [ ] T042 [P] [US2] Write unit test for enemy bullet vs player collision in shooter_game/test/shooter_game/game/collision_test.exs
- [ ] T043 [P] [US2] Write LiveViewTest for game_over state transition in shooter_game/test/shooter_game_web/live/game_live_test.exs

### Implementation for User Story 2

- [ ] T044 [P] [US2] Implement Spawner module with spawn timing logic in shooter_game/lib/shooter_game/game/spawner.ex
- [ ] T045 [P] [US2] Implement Enemy.move/2 with velocity logic in shooter_game/lib/shooter_game/game/enemy.ex
- [ ] T046 [P] [US2] Implement Enemy.fire_bullet/2 with fire interval in shooter_game/lib/shooter_game/game/enemy.ex
- [ ] T047 [US2] Add enemy spawning logic to game tick in shooter_game/lib/shooter_game/game/state.ex
- [ ] T048 [US2] Add enemy movement and firing to game tick in shooter_game/lib/shooter_game/game/state.ex
- [ ] T049 [US2] Implement Collision.detect_player_bullet_enemy_collisions/1 in shooter_game/lib/shooter_game/game/collision.ex
- [ ] T050 [US2] Implement Collision.detect_enemy_bullet_player_collisions/1 in shooter_game/lib/shooter_game/game/collision.ex
- [ ] T051 [US2] Add collision detection calls to game tick and update score/game_over status in shooter_game/lib/shooter_game/game/state.ex
- [ ] T052 [P] [US2] Create ScoreDisplay component in shooter_game/lib/shooter_game_web/live/components/score_display_component.ex
- [ ] T053 [P] [US2] Add enemy rendering to Canvas in shooter_game/assets/js/hooks/game_hook.js
- [ ] T054 [P] [US2] Add enemy bullets rendering to Canvas in shooter_game/assets/js/hooks/game_hook.js
- [ ] T055 [US2] Create GameOver screen component in shooter_game/lib/shooter_game_web/live/components/game_over_component.ex
- [ ] T056 [US2] Add conditional rendering for game_over status in shooter_game/lib/shooter_game_web/live/game_live.html.heex
- [ ] T057 [US2] Implement handle_event("restart_game") in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T058 [US2] Add time limit check in game tick to trigger game_over at elapsed_time >= time_limit in shooter_game/lib/shooter_game/game/state.ex
- [ ] T059 [P] [US2] Add elapsed time display to UI in shooter_game/lib/shooter_game_web/live/components/score_display_component.ex

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - full gameplay with enemies, combat, score, and game over

---

## Phase 5: User Story 3 - スコア保存と履歴 (Priority: P3)

**Goal**: ゲーム終了時にハイスコアをLocalStorageに保存し、開始画面に表示

**Independent Test**: ゲーム終了後にLocalStorageにスコア保存、ページリロード後に開始画面でハイスコア表示を確認

### Tests for User Story 3

- [ ] T060 [P] [US3] Write LiveViewTest for high_score_loaded event handling in shooter_game/test/shooter_game_web/live/game_live_test.exs
- [ ] T061 [P] [US3] Write JavaScript unit test for StorageHook save/load in shooter_game/assets/js/hooks/storage_hook.test.js (optional)

### Implementation for User Story 3

- [ ] T062 [P] [US3] Create StorageHook in shooter_game/assets/js/hooks/storage_hook.js with localStorage operations
- [ ] T063 [US3] Implement handleEvent("save_score") in StorageHook to save to localStorage in shooter_game/assets/js/hooks/storage_hook.js
- [ ] T064 [US3] Add StorageHook initialization in mounted() to load high score on page load in shooter_game/assets/js/hooks/storage_hook.js
- [ ] T065 [US3] Implement handle_event("high_score_loaded") in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T066 [US3] Add push_event("save_score") call when status changes to :game_over in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T067 [US3] Update GameState to store high_score field in shooter_game/lib/shooter_game/game/state.ex
- [ ] T068 [P] [US3] Display high score on start screen in shooter_game/lib/shooter_game_web/live/start_screen_live.html.heex
- [ ] T069 [US3] Pass high_score from GameLive to StartScreen component via assigns in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T070 [P] [US3] Add storage event listener registration in shooter_game/assets/js/app.js

**Checkpoint**: All user stories should now be independently functional - complete game with score persistence

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [ ] T071 [P] Add game width/height constants validation in shooter_game/lib/shooter_game/game/state.ex
- [ ] T072 [P] Add offscreen entity removal logic in shooter_game/lib/shooter_game/game/state.ex
- [ ] T073 [P] Improve Canvas rendering with sprite images (optional) in shooter_game/assets/js/hooks/game_hook.js
- [ ] T074 [P] Add visual feedback for player hit detection in shooter_game/assets/js/hooks/game_hook.js
- [ ] T075 [P] Optimize collision detection performance with early exits in shooter_game/lib/shooter_game/game/collision.ex
- [ ] T076 [P] Add client-side input throttling (16ms) for mouse_move in shooter_game/assets/js/hooks/mouse_hook.js
- [ ] T077 [P] Add server-side coordinate validation in shooter_game/lib/shooter_game_web/live/game_live.ex
- [ ] T078 [P] Add comprehensive documentation in shooter_game/README.md
- [ ] T079 [P] Code formatting with `mix format` across all Elixir files
- [ ] T080 Run full test suite with `mix test` and verify all tests pass
- [ ] T081 Run quickstart.md validation - complete setup from scratch and verify game works
- [ ] T082 [P] Performance profiling of game loop to ensure 60fps client / 30fps server
- [ ] T083 [P] Browser compatibility testing (Chrome, Firefox, Safari, Edge)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 can start after Phase 2
  - US2 depends on US1 (needs player, bullets, game loop)
  - US3 can start after Phase 2 (independent of US1/US2 but needs game_over state from US2)
- **Polish (Phase 6)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 completion - needs player controls, bullet system, game loop
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Needs game_over status from US2 for save trigger but storage logic is independent

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Core game entities before game loop integration
- Game loop before rendering
- Client hooks before server events
- Core implementation before polish

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T003, T004, T005, T006)
- All Foundational entity structs marked [P] can run in parallel (T008, T009, T010, T011, T012, T013, T016)
- Within US1: Tests (T017-T020), MouseHook (T025), Player logic (T027, T030), GameHook (T031), Bullet logic (T035, T036) can run in parallel
- Within US2: Tests (T038-T043), Spawner (T044), Enemy logic (T045, T046), Collision (T049, T050), UI components (T052, T053, T054, T059) can run in parallel
- Within US3: Tests (T060, T061), StorageHook implementation (T062, T063, T064), UI updates (T068, T070) can run in parallel
- All Polish tasks marked [P] can run in parallel (T071-T079, T082, T083)

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task T017: "Write LiveViewTest for start screen rendering"
Task T018: "Write LiveViewTest for start_game event transition"
Task T019: "Write unit test for Player.move_to/3"
Task T020: "Write unit test for Player.fire_bullet/2"

# Launch all independent implementation tasks for User Story 1:
Task T021: "Implement start screen component"
Task T022: "Create StartScreen template with START button"
Task T025: "Create MouseHook for mouse events"
Task T027: "Implement Player.move_to/3 function"
Task T030: "Implement Player.fire_bullet/2 with cooldown"
Task T031: "Create GameHook with Canvas rendering"
Task T035: "Implement bullet movement logic"
Task T036: "Implement Canvas rendering for player, bullets"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T007) - ~2 hours
2. Complete Phase 2: Foundational (T008-T016) - ~4 hours - CRITICAL checkpoint
3. Complete Phase 3: User Story 1 (T017-T037) - ~8 hours
4. **STOP and VALIDATE**: Test independently - can play game, move player, shoot bullets
5. Deploy/demo if ready - this is a minimal playable game

**Estimated MVP Time**: ~14 hours

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (~6 hours)
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! ~8 hours)
3. Add User Story 2 → Test independently → Deploy/Demo (Full gameplay ~10 hours)
4. Add User Story 3 → Test independently → Deploy/Demo (Persistence ~4 hours)
5. Add Polish → Final validation (~4 hours)

**Total Estimated Time**: ~32 hours for complete feature

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (~6 hours)
2. Once Foundational is done:
   - Developer A: User Story 1 (T017-T037) - ~8 hours
   - Developer B: User Story 2 tests + components in parallel (T038-T046) - start early
   - Developer C: User Story 3 StorageHook prep (T062-T064) - start early
3. User Story 1 completes → Developer A moves to US2 integration (T047-T051)
4. User Story 2 completes → Developer B moves to US2 UI (T055-T059)
5. Developer C completes US3 integration (T065-T070)
6. All team: Polish tasks in parallel (T071-T083)

**Parallel Estimated Time**: ~16 hours with 3 developers

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [US1/US2/US3] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- US2 has dependency on US1 (needs game loop and bullet system)
- US3 is mostly independent but needs game_over state from US2
- Canvas rendering requires understanding of requestAnimationFrame and 2D context API
- LiveView hooks require understanding of JavaScript-Elixir event communication
- Performance critical: maintain 60fps on client, 30fps server broadcasts

---

## Task Count Summary

- **Total Tasks**: 83
- **Phase 1 (Setup)**: 7 tasks
- **Phase 2 (Foundational)**: 9 tasks (CRITICAL - blocks everything)
- **Phase 3 (US1)**: 21 tasks (MVP - playable game)
- **Phase 4 (US2)**: 22 tasks (Full gameplay)
- **Phase 5 (US3)**: 9 tasks (Persistence)
- **Phase 6 (Polish)**: 13 tasks (Final quality)

**Parallel Opportunities**: 42 tasks marked [P] can run in parallel within their phase

**Independent Test Criteria**:

- US1: Can start game, move player with mouse, fire bullets with click
- US2: Enemies appear, collisions work, score updates, game over triggers
- US3: High score saves to LocalStorage, displays on start screen

**Suggested MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1 only) = 37 tasks

