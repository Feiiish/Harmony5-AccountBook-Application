import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, filterRecordItems, BudgetItem } from '../models/recordItemReference';
import { UserSetting, CachedRatesStatus } from "../models/userSetting"
import { variousToPreferred } from '../utils/moneyCount';
import { text } from '@kit.ArkGraphics2D';
import { updateExchangeRates } from "../utils/currencyExchange"


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
  @Local recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'incomeExpenseRecords',
    () => new RecordsData()
  )!;

  @Monitor('recordList')
  onItemsChange(monitor: IMonitor) {
    this.updateProgress()
  }

  @Local budgetProgressList: number[] = []
  @Local value: number = 0
  @Local isShowSheet: boolean = false
  @Local selectedBudget: BudgetItem = new BudgetItem()

  calculateBudgetProgress(recordsData: RecordsData): Promise<number[]> {
    const progressList: number[] = [];

    const tasks = recordsData.budgets.map(async (budget) => {
      const filteredItems = filterRecordItems(
        recordsData.items,
        new Date(budget.startDate),
        new Date(budget.endDate),
        budget.countAll ? undefined : budget.unit,
        budget.tag !== "" ? budget.tag : undefined
      );

      try {
        const result = await variousToPreferred(filteredItems, budget.unit);

        const value = budget.targetAmount > 0 ? result[0] : Math.abs(result[1]);
        progressList.push(parseFloat(value.toFixed(2)));
      } catch (e) {
        console.error("预算进度计算失败", e);
        progressList.push(0);
      }
    });

    return Promise.all(tasks).then(() => progressList);
  }

  private updateProgress() {
    this.calculateBudgetProgress(this.recordsData).then((result) => {
      this.budgetProgressList = result;
    });
  }

  aboutToAppear(): void {
    this.updateProgress()
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
        Text(`起始：${new Date(budget.startDate).toLocaleDateString()}`)
          .fontSize(14)
          .fontColor('#666')
          .margin({ right: 12 })

        Text(`结束：${new Date(budget.endDate).toLocaleDateString()}`)
          .fontSize(14)
          .fontColor('#666')
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ bottom: 20 })

      // 详细信息容器
      Column() {
        // 标签
        if (budget.tag !== "") {
          Row() {
            Text('分类：')
              .fontSize(16)
              .fontColor('#666')
              .width(80)

            Text(`#${budget.tag}`)
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

        // 进度条 + 是否完成
        /*
        let progress = budget.currentAmount / budget.targetAmount;
        let isFinished = progress >= 1;

        Row() {
          Progress({
            value: Math.min(progress * 100, 100),
            total: 100,
            type: ProgressType.Linear
          })
            .style({ strokeWidth: 8, enableSmoothEffect: true })
            .width('70%')
            .color(isFinished ? 0xFF4CAF50 : 0xFF2196F3)
            .margin({ right: 12 })

          Text(isFinished ? "已完成" : `${(progress * 100).toFixed(1)}%`)
            .fontSize(14)
            .fontColor(isFinished ? '#4CAF50' : '#2196F3')
        }
        .margin({ bottom: 12 })
        * */

      }
      .padding({ left: 24, right: 24 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {

    if (this.recordsData.budgets.length > 0) {

      Column() {
        Text("预算和计划").fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 14, top: 4 })

        ForEach(this.recordsData.budgets, (budget: BudgetItem, index: number) => {

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

            }.margin({ bottom: 8 }).width('95%')


            // 进度条
            Progress({
              value: this.budgetProgressList[index] / Math.abs(budget.targetAmount) * 100,
              total: 100,
              type: ProgressType.Linear
            })
              .style({ strokeWidth: 10, enableSmoothEffect: true })
              .width('100%')
              .color(budget.targetAmount > 0 ? 0xFF4CAF50 : 0xFFF44336)
              .margin({ bottom: 4 })


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