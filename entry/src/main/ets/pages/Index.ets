import { initTCPServer } from '../lib/http_server';
import { BusinessError } from '@kit.BasicServicesKit';
import { rcp } from '@kit.RemoteCommunicationKit';
import { GameState } from '../lib/game_state';
import { buffer } from '@kit.ArkTS';

interface PairResponse {
  game: string,
  me: string
}

@Entry
@Component
struct Index {
  @State pairAddressInput: string = '';
  @State mode: 'host' | 'client' = 'client';
  @State pairAddress: string = '';
  @State game: GameState = new GameState();
  @State logs: Array<string> = ['hello'];
  @State paired: boolean = false;
  @State playerPen: string = '';
  @State showGameStartInfo: boolean = false;
  session: rcp.Session = rcp.createSession();

  onPageShow(): void {
    this.startHttpServer();
  }

  startHttpServer() {
    initTCPServer(4567, async (request) => {
      if (request.url === '/pair') {
        this.pairAddress = request.body.trim();
        this.logs.push('Pairing with ' + this.pairAddress)
        this.game = new GameState();
        this.paired = true;
        this.playerPen = dateRnd() > 0.5 ? 'X' : 'O';
        this.showGameStartInfo = true;
        setTimeout(() => {
          this.showGameStartInfo = false;
        }, 3000)
        return {
          status: '200 OK',
          result: JSON.stringify({
            game: this.game.serialize(),
            me: this.playerPen
          }),
        }
      }

      if (request.url === '/sync') {
        this.logs.push('Syncing with ' + this.pairAddress)
        this.game = new GameState(JSON.parse(request.body));
        return {
          status: '200 OK',
          result: '',
        }
      }

      this.logs.push('Unhandled request ' + request.url)

      return {
        status: '200 OK',
        result: `This is my mobile server.\n${JSON.stringify(request.url, null, 2)}`,
      }
    });
  }

  pair() {
    this.logs.push('Sending pair request to' + this.pairAddressInput)
    const me = '' // Write other IP Address
    this.session.post(this.pairAddressInput + '/pair', me)
      .then((response) => {
        this.pairAddress = this.pairAddressInput;
        this.paired = true;
        const parsed = JSON.parse(buffer.from(response.body).toString('utf-8')) as PairResponse
        this.playerPen = parsed.me === 'X' ? 'O' : 'X'
        this.game = GameState.deserialize(parsed.game);
        this.showGameStartInfo = true;
        setTimeout(() => {
          this.showGameStartInfo = false;
        }, 3000)
      })
      .catch((err: BusinessError) => {
      })
  }

  sync() {
    this.logs.push('Sending sync request to' + this.pairAddressInput)
    this.session.post(this.pairAddress + '/sync', this.game.serialize())
      .then((response) => {
      })
      .catch((err: BusinessError) => {
      });
  }

  restart() {
    this.game.reset();
    this.sync();
  }

  @Builder
  ShowResult() {
    Column() {
      Text(this.game.winner + ' is winner!')
        .fontSize(24).fontWeight(FontWeight.Bold).padding(8)
        .fontColor(this.game.winner === 'X' ? Color.Blue : Color.Red)

      Button('Restart')
        .backgroundColor(Color.White)
        .fontColor(this.game.winner === 'X' ? Color.Blue : Color.Red)
        .borderColor(this.game.winner === 'X' ? Color.Blue : Color.Red)
        .borderWidth(1)
        .fontSize(24)
        .onClick(() => this.restart())
    }
  }

  @Builder
  GameStartInfo() {
    Column() {
      Column() {
        Text(`You're ${this.playerPen}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .padding(8)
          .fontColor(this.playerPen === 'X' ? Color.Blue : Color.Red)

        Text(`First move: ${this.game.pen}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .padding(8)
          .fontColor(this.game.pen === 'X' ? Color.Blue : Color.Red)
      }
    }
    .position({
      bottom: -10,
      left: 0,
    })
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('50%')
    .zIndex(9999)
    .backgroundColor('#1b1b1b')
    .borderRadius({
      topLeft: 20,
      topRight: 20
    })
    .border({
      width: 1,
      color: '#fff'
    })
  }

  canPlay(boxIndex: number) {
    return !this.game.boxes[boxIndex] &&
      !this.game.winner &&
      this.game.pen === this.playerPen
  }

  computeIndex(i1: number, i2: number) {
    return i1 * 3 + i2;
  }

  turnPen(i1: number, i2: number) {
    return this.game.boxes[this.computeIndex(i1, i2)];
  }

  @Builder
  PairScreen() {
    Scroll() {
      Column() {
        TextInput({ text: $$this.pairAddressInput })
          .margin({
            left: 20,
            right: 20,
            bottom: 10
          })
          .fontSize(14)
        Button('Pair Now')
          .onClick(() => this.pair())
          .fontSize(14)
      }
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
  }

  @Builder
  GameScreen() {

    RelativeContainer() {
      if (this.showGameStartInfo) {
        this.GameStartInfo()
      }
      Column() {
        ForEach(
          new Array(3).fill(0),
          (_: string, i1) => {
            Row() {
              ForEach(
                new Array(3).fill(0),
                (_: string, i2) => {
                  Row() {
                    Text(this.game.boxes[this.computeIndex(i1, i2)])
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.turnPen(i1, i2) === 'X' ? Color.Blue : Color.Red)
                      .margin({
                        top: i1 === 0 && i2 !== 1 ? 20 : 0,
                        bottom: i1 === 2 && i2 !== 1 ? 20 : 0,
                        left: i2 === 0 && i1 !== 1 ? 20 : 0,
                        right: i2 === 2 && i1 !== 1 ? 20 : 0,
                      })
                      .fontSize(28)
                  }
                  .onClick(() => {
                    if (this.canPlay(this.computeIndex(i1, i2))) {
                      this.game.play(this.computeIndex(i1, i2));
                      this.sync();
                    }
                  })
                  .width(i2 === 1 ? '32%' : '34%')
                  .height('100%')
                  .borderRadius({
                    topLeft: i1 === 0 && i2 === 0 ? '100%' : 0,
                    topRight: i1 === 0 && i2 === 2 ? '100%' : 0,
                    bottomLeft: i1 === 2 && i2 === 0 ? '100%' : 0,
                    bottomRight: i1 === 2 && i2 === 2 ? '100%' : 0,
                  })

                  .justifyContent(FlexAlign.Center)
                  .border({
                    'color': Color.Gray,
                  })
                  .borderWidth({
                    left: i2 !== 0 ? 2 : 0
                  })
                }, (item: string, index: number) => item)

            }
            .width('100%')
            .height(i1 === 1 ? '32%' : '34%')
            .border({
              'color': Color.Gray,
            })
            .borderWidth({
              top: i1 !== 0 ? 2 : 0
            })

          }, (item: string, index: number) => item)
      }
      .bindSheet(this.game.isGameOver, this.ShowResult(), {
        height: '50%',
        showClose: false
      })
      .justifyContent(FlexAlign.Center)
      .border({ 'color': Color.Gray, 'width': 2 })
      .width('100%')
      .height('100%')
      .margin('0%')
      .padding('0%')
      .borderRadius('50%')
      .clip(true)
    }
    .padding('0%')
    .height('100%')
    .width('100%')
  }

  build() {
    if (this.paired) {
      this.GameScreen();
    } else {
      this.PairScreen();
    }
  }
}

function dateRnd() {
  return (Date.now() % 1000) / 1000;
}