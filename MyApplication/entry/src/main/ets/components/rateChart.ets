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
  selectedCurre: singleCurrency = {
    unit: "",
    rate: 1,
    amount: 0
  };
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

  @Monitor('this.ledgerManager.activeBook.rateChartCurrency')
  onListChange(monitor: IMonitor) {
    this.updateRates()
  }

  @Monitor('this.ledgerManager.activeBook.preferredCurrency')
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
  mySheet(budget: singleCurrency) {
    Column() {
      // 标题
      Text(
        budget.unit
      )
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {


    Column() {
      Column() {

        if (this.ledgerManager.activeBook.chosenCurrency.length > 0) {

          ratesStatus().margin({ top: 8, bottom: 8 })
          ForEach(this.ledgerManager.activeBook.rateChartCurrency, (r: string, index: number) => {

            Column() {
              Divider()
              Row({ space: 6 }) {
                findFlag({ flagName: r })

                Text(`${this.rates[index]}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
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

              }.padding(12)

              if (index + 1 !== this.ledgerManager.activeBook.chosenCurrency.length) {
                Divider()
              }

            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            /*
            .onClick(() => {
              this.isShowSheet = !this.isShowSheet
            })
            .bindSheet(this.isShowSheet, this.mySheet(this.selectedCurre), {
              height: 300,
              onWillDisappear: () => {
                this.isShowSheet = false
              }
            })
            * */
          })
        } else {
          Text("暂无汇率数据").fontColor(Color.Gray)
        }
      }.backgroundColor($r('app.color.Card_background_2')).borderRadius(12)

    }.basicCard()

  }
}