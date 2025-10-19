// Game Canvas Hook - handles Canvas rendering and mouse events
const GameCanvas = {
  mounted() {
    this.canvas = this.el
    this.ctx = this.canvas.getContext('2d')
    this.gameState = null
    
    // Setup mouse event listeners
    this.canvas.addEventListener('mousemove', (e) => this.handleMouseMove(e))
    this.canvas.addEventListener('mousedown', (e) => this.handleMouseDown(e))
    this.canvas.addEventListener('mouseup', (e) => this.handleMouseUp(e))
    
    // Listen for game state updates from server
    this.handleEvent('game_state', (state) => {
      this.gameState = state
    })
    
    // Start animation loop
    this.animationFrameId = requestAnimationFrame(() => this.animate())
  },
  
  destroyed() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }
  },
  
  handleMouseMove(e) {
    const rect = this.canvas.getBoundingClientRect()
    const x = e.clientX - rect.left
    const y = e.clientY - rect.top
    
    this.pushEvent('mouse_move', { x, y })
  },
  
  handleMouseDown(e) {
    e.preventDefault()
    this.pushEvent('mouse_down', {})
  },
  
  handleMouseUp(e) {
    e.preventDefault()
    this.pushEvent('mouse_up', {})
  },
  
  animate() {
    this.render()
    this.animationFrameId = requestAnimationFrame(() => this.animate())
  },
  
  render() {
    // Clear canvas
    this.ctx.fillStyle = '#000'
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height)
    
    if (!this.gameState) return
    
    // Render player
    if (this.gameState.player) {
      this.ctx.fillStyle = '#00ff00'
      this.ctx.fillRect(
        this.gameState.player.x,
        this.gameState.player.y,
        this.gameState.player.width,
        this.gameState.player.height
      )
    }
    
    // Render player bullets
    this.ctx.fillStyle = '#ffff00'
    this.gameState.player_bullets?.forEach(bullet => {
      this.ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height)
    })
    
    // Render enemies
    this.ctx.fillStyle = '#ff0000'
    this.gameState.enemies?.forEach(enemy => {
      this.ctx.fillRect(enemy.x, enemy.y, enemy.width, enemy.height)
    })
    
    // Render enemy bullets
    this.ctx.fillStyle = '#ff00ff'
    this.gameState.enemy_bullets?.forEach(bullet => {
      this.ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height)
    })
  }
}

export default GameCanvas
