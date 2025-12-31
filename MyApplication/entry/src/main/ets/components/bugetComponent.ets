import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, filterRecordItems, BudgetItem, LedgerManager } from '../models/recordItemReference';
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
export struct budgetComponent {
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
  @Local selectedBudget: BudgetItem = new BudgetItem()

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
          budget.currentAmount = parseFloat(value.toFixed(2));
        })
        .catch((e: Error) => {
          console.error("failed to caculate budget progress", e);
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
  mySheet(budget: BudgetItem) {
    Column() {
      // 标题
      Text(
        budget.name === ""
          ? (budget.targetAmount >= 0 ? "Saving Plan" : "Expend Budget")
          : budget.name
      )
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      // Time Range
      Row() {
        Text(`From：${formatDateAdvanced(budget.startDate, "YYYY-MM-DD")}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ right: 12 })

        Text(`To：${formatDateAdvanced(budget.endDate, "YYYY-MM-DD")}`)
          .fontSize(14)
          .fontColor('#666')
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ bottom: 20 })

      // Detailed INFO
      Column() {

        // TargetAmount
        Row() {
          Text('Target Info')
            .fontSize(16)
            .fontColor('#666')
            .width(80)

          Row() {
            Text(`${budget.targetAmount.toFixed(2)} `)
              .fontSize(16)

            Text($r(`app.string.${budget.unit}`))
              .fontSize(16)
          }

        }
        .margin({ bottom: 12 })

        // 标签
        if (budget.tag !== "") {
          Row() {
            Text('Limit to tag')
              .fontSize(16)
              .fontColor('#666')


            Text(`${budget.tag}`)
              .fontSize(16)
          }

          .margin({ bottom: 12 })
        }

        // 多币种标识
        if (budget.countAll) {
          Row() {
            Text('One Currency')
              .fontSize(16)
              .fontColor('#666')
              .width(80)

            Text('Multi-Currency')
              .fontSize(16)
              .fontColor('#4CAF50')
          }
          .margin({ bottom: 12 })
        } else {
          Row() {
            Text('One Currency')
              .fontSize(16)
              .fontColor('#666')
              .width(80)
            Text($r(`app.string.${budget.unit}`))
              .fontSize(16)
          }
          .margin({ bottom: 12 })
        }

      }
      .height("30%")
      .padding({ left: 24, right: 24 })
      .alignItems(HorizontalAlign.Center)

      Row() {
        Progress({
          value: Math.min(budget.currentAmount / Math.abs(budget.targetAmount) * 100),
          total: 100,
          type: ProgressType.Linear
        })
          .style({ strokeWidth: 8, enableSmoothEffect: true })
          .width('70%')
          .color(budget.isExpired ? "#FFC107" : (budget.targetAmount >= 0 ?
            (budget.isCompleted ? 0xFF4CAF50 : 0xFF2196F3) :
            0xFFFF3A3A
          ))

          .margin({ right: 12 })

        Text(budget.isCompleted ? "已达到" : `${(budget.currentAmount / budget.targetAmount * 100).toFixed(1)}%`)
          .fontSize(14)
          .fontColor(budget.isExpired ? "#FFC107" : (budget.targetAmount >= 0 ?
            (budget.isCompleted ? 0xFF4CAF50 : 0xFF2196F3) :
            0xFFFF3A3A
          ))
      }
      .margin({ bottom: 12 })

      Image($r('app.media.bin')).height(45).width(45).margin({ top: 8 }).onClick(() => {
        new recordDeleter().deleteBudgetFromAll(budget)
      })


    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {


    Column({ space: 10 }) {
      if (this.ledgerManager.activeBook.data.budgets.length > 0) {

        ForEach(this.ledgerManager.activeBook.data.budgets, (budget: BudgetItem, index: number) => {

          Column() {
            // 预算标题和金额
            Row({ space: 8 }) {


              Row() {
                Text(
                  budget.name !== ""
                    ? budget.name
                    : budget.targetAmount > 0
                    ? "expense budget"
                    : "saving plan"
                )
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .margin({ right: 4 })

                Row() {
                  Text(`${budget.targetAmount}`)
                    .fontSize(14)
                    .fontColor($r('app.color.Font_Color'))
                    .fontColor(Color.Gray)

                  Text($r(`app.string.${budget.unit}`))
                    .fontSize(14)
                    .fontColor($r('app.color.Font_Color'))
                    .fontColor(Color.Gray)
                }

              }

              // 标签和单位限制信息
              Row({ space: 6 }) {
                if (budget.countAll) {
                  Text(`multi-currency`)
                    .fontSize(12)
                    .fontColor(Color.Gray)
                }

                if (budget.tag !== "") {
                  Text(`#${budget.tag}`)
                    .fontSize(12)
                    .fontColor(Color.Gray)
                }

              }

              // 判断是否有名称

            }.margin({ bottom: 4 }).width('94%')

            Row() {
              // 进度条
              Progress({
                value: budget.currentAmount / Math.abs(budget.targetAmount) * 100,
                total: 100,
                type: ProgressType.Linear
              })
                .style({ strokeWidth: 10, enableSmoothEffect: true })
                .width('80%')
                .color(budget.isExpired ? "#FFC107" : (budget.targetAmount >= 0 ?
                  (budget.isCompleted ? 0xFF4CAF50 : 0xFF2196F3) :
                  0xFFFF3A3A
                ))

              if (budget.isCompleted) {
                Text("completed").fontSize(14)
                  .fontColor(budget.isCompleted ? '#4CAF50' : '#2196F3')
              } else if (budget.isExpired) {
                Text("outdated")
                  .fontSize(14)
                  .fontColor("#FFC107")
              } else {
                Text(`${Math.abs(budget.currentAmount / budget.targetAmount * 100).toFixed(1)}%`)
                  .fontSize(14)
                  .fontColor(budget.isExpired ? "#FFC107" : (budget.targetAmount >= 0 ?
                    (budget.isCompleted ? 0xFF4CAF50 : 0xFF2196F3) :
                    0xFFFF3A3A
                  ))
              }


            }.justifyContent(FlexAlign.SpaceEvenly).width('100%')

          }
          .onClick(() => {
            this.selectedBudget = budget
            this.isShowSheet = !this.isShowSheet
          })
          .bindSheet(this.isShowSheet, this.mySheet(this.selectedBudget), {
            height: 300,
            onWillDisappear: () => {
              this.isShowSheet = false
            }
          })

          if (index + 1 !== this.ledgerManager.activeBook.data.budgets.length) {
            Divider()
          }

        })
      } else {
        Text("No budget data").fontColor(Color.Gray)
      }

    }.basicCard()

  }
}