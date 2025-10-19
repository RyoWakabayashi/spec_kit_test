# Shooter Game

A real-time browser-based shooting game built with Phoenix LiveView.

## Features

- **Real-time gameplay**: Mouse-controlled spaceship with continuous firing
- **Enemy AI**: Randomly spawning enemies that shoot back
- **Score system**: Points for destroying enemies
- **High score persistence**: Scores saved in browser localStorage
- **Time limit**: 3-minute game sessions
- **Game over conditions**: Hit by enemy or enemy bullet, or time runs out

## Quick Start

```bash
# Install dependencies
mix deps.get
cd assets && npm install && cd ..

# Start the server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser and click START to play!

## How to Play

1. **Start**: Click the START button on the opening screen
2. **Move**: Move your mouse to control the spaceship
3. **Shoot**: Hold down the mouse button to fire continuously
4. **Survive**: Destroy enemies and avoid their bullets
5. **Score**: Each enemy destroyed gives you 10 points

## Requirements

- Elixir (latest via mise)
- Erlang (latest via mise)
- Modern browser (Chrome 88+, Firefox 85+, Safari 14+)

## Game Mechanics

- **Player**: 40x40px, fires every 150ms
- **Enemies**: Spawn every 2 seconds, move downward, fire every 2 seconds
- **Scoring**: 10 points per enemy destroyed
- **Time Limit**: 3 minutes per game

## Architecture

Built with Phoenix LiveView for real-time communication:
- Server-side game logic (30fps tick)
- Client-side Canvas rendering (60fps)
- WebSocket for low-latency updates

## Testing

```bash
mix test
```

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

