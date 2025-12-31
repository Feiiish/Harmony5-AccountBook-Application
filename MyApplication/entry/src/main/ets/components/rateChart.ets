import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { displayExchangeRates } from '../utils/currencyExchange';
import {
  RecordItem,
  RecordsData,
  filterRecordItems,
  BudgetItem,
  LedgerManager,
  singleCurrency
} from '../models/recordItemReference';
import { UserSetting, CachedRatesStatus } from "../models/userSetting"
import { variousToPreferred } from '../utils/moneyCount';
import { recordDeleter } from '../utils/recordDeleter';
import { text } from '@kit.ArkGraphics2D';
import { updateExchangeRates } from "../utils/currencyExchange"
import { formatDateAdvanced } from "../utils/formatDateAdvanced"
import { findFlag } from "../utils/FindCountryFlags"
import { ratesStatus } from "../components/RatesStatus"

// 将样式定义移动到组件外部
@Styles
function basicCard() {
  .width('100%')
  .padding(16)
  .borderRadius(15)
  .margin({ bottom: 12 })
  .backgroundColor($r("app.color.Basic_Card_background"))
}

@Preview
@ComponentV2
export struct rateChart {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local
  cachedRatesStorage: CachedRatesStatus = PersistenceV2.connect(
    CachedRatesStatus,
    "cachedRatesStatus",
    () => new CachedRatesStatus()
  )!;
  @Local ratesMap: Record<string, string> = {} // 改用 Map！关键！
  @Local filteredCurrencies: string[] = [] // 专门存“不含本位币”的订阅货币

  @Monitor('ledgerManager.activeBook.rateChartCurrency')
  on1Change() {
    console.log('ActiveBook1')
    this.refreshData()
  }

  @Monitor('ledgerManager.activeBook.preferredCurrency')
  on2Change() {
    this.refreshData()
  }

  @Monitor('cachedRatesStorage.lastUpdateTime')
  on3Change() {
    this.refreshData()
  }

  @Local value: number = 0
  @Local isShowSheet: boolean = false
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;

  aboutToAppear(): void {
    this.refreshData()
  }

  private refreshData() {
    const preferred = this.ledgerManager.activeBook.preferredCurrency;

    // 1. 过滤掉本位币，生成最终显示顺序（这才是真正的渲染顺序！）
    this.filteredCurrencies = this.ledgerManager.activeBook.rateChartCurrency
      .filter(c => c !== preferred)

    // 2. 开始异步更新汇率（用 Promise.all + .then）
    this.updateRatesAsync(preferred, this.filteredCurrencies)
      .then(() => {
        // 只有所有汇率都算完，才触发一次 UI 重绘（完美避免闪烁/错位）
        // ArkUI 会自动检测 ratesMap 变化
      })
  }

  private async updateRatesAsync(base: string, targets: string[]): Promise<void> {
    const newMap: Record<string, string> = {}

    // 即使 targets 为空也走一遍（避免旧数据残留）
    for (const currency of targets) {
      try {
        const rate = await displayExchangeRates(base, currency)
        newMap[currency] = (1 / rate).toFixed(2)
      } catch (e) {
        newMap[currency] = "-.--"
      }
    }

    // 一次性赋值，触发最小化重绘
    this.ratesMap = newMap
  }

  @Builder
  mySheet() {
    Column() {
      Row({ space: 12 }) {
        Text('已订阅货币')
          .fontWeight(FontWeight.Bold)
          .fontSize(22)
      }
      .width('100%')
      .margin({ top: 25, bottom: 12 })

      Column() {
        Column({ space: 4 }) {
          Divider()

          Row() {

            //currency name
            Row({ space: 12 }) {
              Text($r(`app.string.${this.ledgerManager.activeBook.preferredCurrency}`)).fontSize(18)
              findFlag({ flagName: this.ledgerManager.activeBook.preferredCurrency })
              if (this.userSetting.showCurrencyCode) {
                Text(this.ledgerManager.activeBook.preferredCurrency)
                  .opacity(0.5)
              }
            }.transition(
              TransitionEffect.asymmetric(
                TransitionEffect.scale({ x: 0.9, y: 0.9 }),
                TransitionEffect.IDENTITY
              ).animation({ duration: 400, curve: Curve.FastOutSlowIn })
            )

          }
          .height(30)
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .onClick(() => {
            promptAction.showToast({ message: "无法取消本位币" })
            return

          })

          ForEach(this.ledgerManager.activeBook.rateChartCurrency, (currency: string, index: number) => {
            Divider()

            Row() {

              //currency name
              Row({ space: 12 }) {
                Text($r(`app.string.${currency}`)).fontSize(18)
                findFlag({ flagName: currency })
                if (this.userSetting.showCurrencyCode) {
                  Text(currency)
                    .opacity(0.5)
                }
              }.transition(
                TransitionEffect.asymmetric(
                  TransitionEffect.scale({ x: 0.9, y: 0.9 }),
                  TransitionEffect.IDENTITY
                ).animation({ duration: 400, curve: Curve.FastOutSlowIn })
              )

            }
            .height(30)
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .onClick(() => {
              if (currency === this.ledgerManager.activeBook.preferredCurrency) {
                promptAction.showToast({ message: "无法取消本位币" })
                return
              } else {
                this.ledgerManager.activeBook.rateChartCurrency =
                  this.ledgerManager.activeBook.rateChartCurrency.filter(
                    c => c !== currency
                  );
              }


            })
          }
          )
        }
        .padding(2)

      }.alignItems(HorizontalAlign.Start)

      Row({ space: 12 }) {
        Text('可订阅货币')
          .fontWeight(FontWeight.Bold)
          .fontSize(22)
      }
      .width('100%')
      .margin({ top: 25, bottom: 12 })

      Column() {
        Column({ space: 4 }) {
          ForEach(this.ledgerManager.activeBook.chosenCurrency.filter(
            c => !this.ledgerManager.activeBook.rateChartCurrency.includes(c)
          ), (currency: string, index: number) => {
            if (currency !== this.ledgerManager.activeBook.preferredCurrency) {
              Divider()

              Row() {

                //currency name
                Row({ space: 12 }) {
                  Text($r(`app.string.${currency}`)).fontSize(18)
                  findFlag({ flagName: currency })
                  if (this.userSetting.showCurrencyCode) {
                    Text(currency)
                      .opacity(0.5)
                  }
                }.transition(
                  TransitionEffect.asymmetric(
                    TransitionEffect.scale({ x: 0.9, y: 0.9 }),
                    TransitionEffect.IDENTITY
                  ).animation({ duration: 400, curve: Curve.FastOutSlowIn })
                )

              }
              .height(30)
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .onClick(() => {
                if (currency === this.ledgerManager.activeBook.preferredCurrency) {
                  promptAction.showToast({ message: "本位币无需订阅" })
                  return
                }
                if (!this.ledgerManager.activeBook.rateChartCurrency.includes(currency)) {
                  this.ledgerManager.activeBook.rateChartCurrency = [
                    ...this.ledgerManager.activeBook.rateChartCurrency,
                    currency
                  ];
                  // 不需要手动调用 updateRates，@Monitor 会自动触发 refreshData / updateAllRates
                }
              })
            }

          }
          )
        }
        .padding(2)

      }.alignItems(HorizontalAlign.Start)

    }
    .width('75%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {


    Column() {
      Column() {
        if (this.ledgerManager.activeBook.chosenCurrency.length > 0) {
          Row() {
            Text(`Current Rate`)
            ratesStatus()
          }
          .width('90%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 12, bottom: 12 })


          Column() {
            Divider()
            Row({ space: 6 }) {
              findFlag({ flagName: this.ledgerManager.activeBook.preferredCurrency })
              Row() {
                Text("1:").fontSize(12).fontWeight(FontWeight.Medium).opacity(0.5)
                Text("1.00").fontSize(16).fontWeight(FontWeight.Medium)
              }

              if (this.userSetting.showCurrencyCode) {
                Text(this.ledgerManager.activeBook.preferredCurrency).fontSize(14).fontColor(Color.Gray)
              }
              Text($r(`app.string.${this.ledgerManager.activeBook.preferredCurrency}`))
                .fontSize(14)
                .fontColor(Color.Gray)
              Text('main currency')
                .fontSize(14)
                .textAlign(TextAlign.Center)
                .backgroundColor('#66ccff')
                .padding(4)
                .borderRadius(5)
                .opacity(0.5)
            }.padding(12)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // 2. 其它已订阅货币（用 Map 取值，永不错位）
          ForEach(this.ledgerManager.activeBook.rateChartCurrency
            .filter(c => c !== this.ledgerManager.activeBook.preferredCurrency), (currency: string) => {
            Column() {
              Divider()
              Row({ space: 6 }) {
                findFlag({ flagName: currency })
                Row() {
                  Text("1:").fontSize(12).fontWeight(FontWeight.Medium).opacity(0.5)
                  Text(this.ratesMap[currency] ?? "--")   // 异步还没回来时显示 --
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                }

                if (this.userSetting.showCurrencyCode) {
                  Text(currency).fontSize(14).fontColor(Color.Gray)
                }
                Text($r(`app.string.${currency}`))
                  .fontSize(14)
                  .fontColor(Color.Gray)
              }.padding(12)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          })

          // 3. 订阅按钮（完全不变）
          Column() {
            Divider()
            Row() {
              Text("Subscribe+")
                .fontSize(14)
                .fontColor(Color.Gray)
                .onClick(() => {
                  this.isShowSheet = true
                })
                .bindSheet(this.isShowSheet, this.mySheet(), {
                  height: 360,
                  onWillDisappear: () => {
                    this.isShowSheet = false
                  }
                })
            }.padding(12)
          }
          .width('100%')

        } else {
          Text("No rate data").fontColor(Color.Gray)
        }
      }
      .backgroundColor($r('app.color.Card_background_2'))
      .borderRadius(12)

    }.basicCard()

  }
}