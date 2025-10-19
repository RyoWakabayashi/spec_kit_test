<!--
Sync Impact Report:
- Version change: [NEW_TEMPLATE] → 1.0.0
- Modified principles: N/A (initial constitution)
- Added sections: All core sections
- Removed sections: N/A
- Templates requiring updates:
  ✅ plan-template.md (Constitution Check section exists)
  ✅ spec-template.md (User scenarios structure compatible)
  ✅ tasks-template.md (no specific updates needed)
- Follow-up TODOs: None
-->

# Phoenix Scroll Shooter Constitution

## Core Principles

### I. Real-Time First

All game mechanics MUST operate in real-time using Phoenix LiveView's pub/sub capabilities.
Game state updates MUST be broadcast to all connected clients within 16ms for 60fps gameplay.
No client-side state synchronization - server is the single source of truth for all game entities.

**Rationale**: Ensures consistent multiplayer experience and prevents cheating through client-side manipulation.

### II. Functional Game Logic (NON-NEGOTIABLE)

Game state transitions MUST be pure functions that take current state and input, returning new state.
All game entities (player, enemies, bullets) MUST be immutable data structures.
Side effects (rendering, sound, network) MUST be isolated from core game logic.

**Rationale**: Enables predictable behavior, easy testing, and time-travel debugging capabilities.

### III. LiveView Component Architecture

Each game element (player ship, enemy, bullet, UI panel) MUST be a dedicated LiveView component.
Components MUST communicate only through well-defined assigns and events.
Component lifecycle MUST align with game entity lifecycle (spawn, update, destroy).

**Rationale**: Maintains code organization, enables independent testing, and leverages Phoenix's built-in optimization.

### IV. Performance-First Rendering

Game loop MUST maintain 60fps target with frame time monitoring.
Rendering MUST use Phoenix's diff-based updates to minimize DOM manipulation.
Large state changes MUST be batched using `Phoenix.LiveView.send_update_after/3`.

**Rationale**: Ensures smooth gameplay experience and efficient use of browser resources.

### V. Test-Driven Game Development

Game mechanics MUST have unit tests covering all state transitions before implementation.
Integration tests MUST verify real-time multiplayer scenarios using Phoenix.LiveViewTest.
Performance tests MUST validate frame rate stability under load.

**Rationale**: Complex real-time systems require comprehensive testing to prevent regressions.

## Technical Constraints

**Technology Stack**: Phoenix LiveView 0.20+, Elixir 1.15+, Phoenix PubSub for real-time communication
**Browser Support**: Modern browsers with WebSocket support (Chrome 88+, Firefox 85+, Safari 14+)
**Performance Target**: 60fps gameplay, <50ms server response time, <100MB memory usage per client
**Scalability Goal**: Support 100+ concurrent players in single game instance

## Development Workflow

**Feature Development**: All new game features MUST follow spec → plan → tasks → implement → test cycle
**Code Review**: All PRs MUST verify real-time performance impact and multiplayer compatibility
**Testing Gates**: Unit tests (100% game logic), integration tests (multiplayer scenarios), performance benchmarks

## Governance

This constitution supersedes all other development practices for the Phoenix Scroll Shooter project.
All feature implementations MUST comply with real-time and functional programming principles.
Performance regressions automatically block deployment until resolved.
Amendments require documentation of impact on existing game systems and player experience.

**Version**: 1.0.0 | **Ratified**: 2025-10-19 | **Last Amended**: 2025-10-19
