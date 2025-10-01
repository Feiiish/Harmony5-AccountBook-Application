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
  mySheet(budget: BudgetItem) {
    Column() {
      // 标题
      Text(
        budget.name === ""
          ? (budget.targetAmount >= 0 ? "存款计划" : "支出预算")
          : budget.name
      )
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      // 时间范围
      Row() {
        Text(`起始：${formatDateAdvanced(budget.startDate, "YYYY-MM-DD")}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ right: 12 })

        Text(`结束：${formatDateAdvanced(budget.endDate, "YYYY-MM-DD")}`)
          .fontSize(14)
          .fontColor('#666')
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ bottom: 20 })

      // 详细信息容器
      Column() {

        // 目标金额
        Row() {
          Text('目标金额：')
            .fontSize(16)
            .fontColor('#666')
            .width(80)

          Text(`${budget.targetAmount.toFixed(2)} ${budget.unit}`)
            .fontSize(16)
        }
        .margin({ bottom: 12 })

        // 标签
        if (budget.tag !== "") {
          Row() {
            Text('限制标签：')
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
            Text('币种限制：')
              .fontSize(16)
              .fontColor('#666')
              .width(80)

            Text('多币种')
              .fontSize(16)
              .fontColor('#4CAF50')
          }
          .margin({ bottom: 12 })
        } else {
          Row() {
            Text('币种限制：')
              .fontSize(16)
              .fontColor('#666')
              .width(80)

            Text(`${budget.unit}`)
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

    if (this.ledgerManager.activeBook.data.budgets.length > 0) {

      Column() {
        Text("预算和计划").fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 14, top: 4 })
          .onClick(() => {
            this.ledgerManager.activeBook.data.budgets = []
          })

        ForEach(this.ledgerManager.activeBook.data.budgets, (budget: BudgetItem, index: number) => {

          Column() {
            // 预算标题和金额
            Row({ space: 8 }) {


              Row() {
                Text(
                  budget.name !== ""
                    ? budget.name
                    : budget.targetAmount > 0
                    ? "存款计划"
                    : "支出预算"
                )
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .margin({ right: 4 })

                Text(`${budget.targetAmount} ${budget.unit}`)
                  .fontSize(14)
                  .fontColor($r('app.color.Font_Color'))
                  .fontColor(Color.Gray)
              }

              // 标签和单位限制信息
              Row({ space: 6 }) {
                if (budget.countAll) {
                  Text(`多货币`)
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

            }.margin({ bottom: 8 }).width('94%')

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
                Text("已达到").fontSize(14)
                  .fontColor(budget.isCompleted ? '#4CAF50' : '#2196F3')
              } else if (budget.isExpired) {
                Text("已过期")
                  .fontSize(14)
                  .fontColor("#FFC107")
              } else {
                Text(`${(budget.currentAmount / budget.targetAmount * 100).toFixed(1)}%`)
                  .fontSize(14)
                  .fontColor(budget.isExpired ? "#FFC107" : (budget.targetAmount >= 0 ?
                    (budget.isCompleted ? 0xFF4CAF50 : 0xFF2196F3) :
                    0xFFFF3A3A
                  ))
              }


            }.justifyContent(FlexAlign.SpaceEvenly).width('100%')

          }
          .padding(12)
          .borderRadius(20)
          .backgroundColor($r("app.color.button_color"))
          .margin({ bottom: 12 })
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
        })
      }.basicCard()

    }


  }
}