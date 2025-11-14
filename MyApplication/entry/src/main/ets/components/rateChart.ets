import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
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

  @Monitor('ledgerManager.activeBook.data.items')
  onItemsChange(monitor: IMonitor) {
    this.calculateBudgetProgress(this.ledgerManager.activeBook.data);
  }

  @Monitor('ledgerManager.activeBook.data.budgets')
  onCreate(monitor: IMonitor) {
    this.calculateBudgetProgress(this.ledgerManager.activeBook.data);
  }

  @Local value: number = 0
  @Local isShowSheet: boolean = false

  calculateBudgetProgress(recordsData: RecordsData): Promise<void> {

    const tasks = recordsData.budgets.map((budget) => {
      const filteredItems = filterRecordItems(
        recordsData.items,
        new Date(budget.startDate),
        new Date(budget.endDate),
        budget.countAll ? undefined : budget.unit,
        budget.tag !== "" ? budget.tag : undefined
      );

      return variousToPreferred(filteredItems, budget.unit)
        .then((result) => {
          const value = budget.targetAmount > 0 ? result[0] : Math.abs(result[1]);
          budget.currentAmount = parseFloat(value.toFixed(2)); // ✅ 直接赋值
        })
        .catch((e: Error) => {
          console.error("预算进度计算失败", e);
          budget.currentAmount = 0;
        });
    });

    return Promise.all(tasks).then(() => {
    });
  }

  aboutToAppear(): void {
    this.calculateBudgetProgress(this.ledgerManager.activeBook.data)
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


    Column({ space: 8 }) {
      if (this.ledgerManager.activeBook.chosenCurrency.length > 0) {

        ForEach(this.ledgerManager.activeBook.chosenCurrency, (r: string, index: number) => {

          Column() {


            Row() {
              Text(
                r
              )
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .margin({ right: 4 })
              Text(`${r}`)
                .fontSize(14)
                .fontColor($r('app.color.Font_Color'))
                .fontColor(Color.Gray)
            }

            Divider()
          }
          .padding(12)
          .borderRadius(20)
          .backgroundColor($r("app.color.button_color"))
          .onClick(() => {
            this.isShowSheet = !this.isShowSheet
          })
          .bindSheet(this.isShowSheet, this.mySheet(this.selectedCurre), {
            height: 300,
            onWillDisappear: () => {
              this.isShowSheet = false
            }
          })
        })
      } else {
        Text("暂无汇率数据").fontColor(Color.Gray)
      }

    }.basicCard()

  }
}