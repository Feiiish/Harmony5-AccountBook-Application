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

  @Monitor('cachedRatesStorage.lastUpdateTime')
  onStatusChange(monitor: IMonitor) {
    this.updateRates()
  }

  @Monitor('ledgerManager.activeBook.rateChartCurrency')
  onListChange(monitor: IMonitor) {
    this.updateRates()
  }

  @Monitor('ledgerManager.activeBook.preferredCurrency')
  onPreferChange(monitor: IMonitor) {
    this.updateRates()
  }

  @Local value: number = 0
  @Local isShowSheet: boolean = false
  @Local rates: string[] = []
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;

  aboutToAppear(): void {
    this.updateRates()
  }

  async updateRates() {
    const preferred = this.ledgerManager.activeBook.preferredCurrency;
    this.rates = []
    for (const currency of this.ledgerManager.activeBook.rateChartCurrency) {
      const rate = await displayExchangeRates(preferred, currency);
      // 存储汇率，可以直接写入对象或单独保存
      this.rates.push((1 / rate).toFixed(2))
    }

    console.log("所有汇率已更新:",);
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
              this.ledgerManager.activeBook.rateChartCurrency =
                this.ledgerManager.activeBook.rateChartCurrency.filter(
                  c => c !== currency
                );


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
              this.ledgerManager.activeBook.rateChartCurrency.push(currency)
              this.updateRates()
            })
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
            Text(`当前汇率`)
            ratesStatus()
          }.width('90%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 12, bottom: 12 })

          ForEach((this.ledgerManager.activeBook.rateChartCurrency), (r: string, index: number) => {
            if (r === this.ledgerManager.activeBook.preferredCurrency) {
              Column() {
                Divider()
                Row({ space: 6 }) {

                  findFlag({ flagName: r })
                  Row() {
                    Text(`1:`)
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .opacity(0.5)
                    Text(`${this.rates[index]}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                  }

                  if (this.userSetting.showCurrencyCode) {
                    Text(r)
                      .fontSize(14)
                      .fontColor($r('app.color.Font_Color'))
                      .fontColor(Color.Gray)
                  }

                  Text($r(`app.string.${r}`))
                    .fontSize(14)
                    .fontColor($r('app.color.Font_Color'))
                    .fontColor(Color.Gray)

                  Text('本位币')
                    .fontColor($r('app.color.Font_Color'))
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
            }
          })
          ForEach(
            this.ledgerManager.activeBook.rateChartCurrency
              .filter(c => c !== this.ledgerManager.activeBook.preferredCurrency),
            (r: string, index: number) => {

              Column() {
                Divider()
                Row({ space: 6 }) {


                  findFlag({ flagName: r })
                  Row() {
                    Text(`1:`)
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .opacity(0.5)
                    Text(`${this.rates[index]}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                  }

                  if (this.userSetting.showCurrencyCode) {
                    Text(r)
                      .fontSize(14)
                      .fontColor($r('app.color.Font_Color'))
                      .fontColor(Color.Gray)
                  }

                  Text($r(`app.string.${r}`))
                    .fontSize(14)
                    .fontColor($r('app.color.Font_Color'))
                    .fontColor(Color.Gray)
                  if (r === this.ledgerManager.activeBook.preferredCurrency) {
                    Text('本位币')
                      .fontColor($r('app.color.Font_Color'))
                      .fontSize(14)
                      .textAlign(TextAlign.Center)
                      .backgroundColor('#66ccff')
                      .padding(4)
                      .borderRadius(5)
                      .opacity(0.5)
                  }
                }.padding(12)

              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)

            })
          Column() {
            Divider()
            Row() {

              Text((`订阅货币+`))
                .fontSize(14)
                .fontColor($r('app.color.Font_Color'))
                .fontColor(Color.Gray)
                .onClick(() => {
                  this.isShowSheet = !this.isShowSheet
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
          Text("暂无汇率数据").fontColor(Color.Gray)
        }
      }.backgroundColor($r('app.color.Card_background_2')).borderRadius(12)

    }.basicCard()

  }
}