export class GameState {
  boxes: Array<string> = [];
  pen: string = 'X';
  winner: string = '';
  isGameOver: boolean = false;

  constructor(state?: Partial<GameState>) {
    if (state) {
      Object.assign(this, state);
    } else {
      this.reset();
    }
  }

  play(index: number): void {
    if (this.boxes[index] !== '' || this.winner) {
      return;
    }

    this.boxes[index] = this.pen;
    this.checkWin();
    if (!this.winner) {
      this.pen = this.pen === 'X' ? 'O' : 'X';
    }
  }

  checkWin(): void {
    const winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];

    for (const [a, b, c] of winPatterns) {
      if (this.boxes[a] &&
        this.boxes[a] === this.boxes[b] &&
        this.boxes[a] === this.boxes[c]
      ) {
        this.winner = this.boxes[a];
        this.isGameOver = true;
        return;
      }
    }

    if (this.boxes.every(v => v !== '')) {
      this.isGameOver = true;
    }
  }

  reset(): void {
    this.boxes = new Array(9).fill('');
    this.pen = 'X';
    this.winner = '';
    this.isGameOver = false;
  }

  serialize(): string {
    return JSON.stringify(this);
  }

  static deserialize(data: string): GameState {
    return new GameState(JSON.parse(data));
  }
}
