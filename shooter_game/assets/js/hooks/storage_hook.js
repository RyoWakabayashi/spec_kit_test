// Storage Hook - handles localStorage operations for high score
const StorageHook = {
  mounted() {
    // Load high score from localStorage on mount
    const highScore = localStorage.getItem('shooter_game_high_score')
    if (highScore) {
      this.pushEvent('high_score_loaded', { highScore: parseInt(highScore, 10) })
    }
    
    // Listen for save score events from server
    this.handleEvent('save_score', ({ score }) => {
      const currentHighScore = parseInt(localStorage.getItem('shooter_game_high_score') || '0', 10)
      if (score > currentHighScore) {
        localStorage.setItem('shooter_game_high_score', score.toString())
        this.pushEvent('high_score_loaded', { highScore: score })
      }
    })
  }
}

export default StorageHook
