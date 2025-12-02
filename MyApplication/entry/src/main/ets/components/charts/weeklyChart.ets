import App from "@system.app";
import { RecordItem, RecordsData } from "../../models/recordItemReference"

import { variousToPreferred } from "../../utils/moneyCount"
import { PersistenceV2, promptAction, router, CapsuleSegmentButtonV2 } from '@kit.ArkUI';
import { displayExchangeRates } from '../../utils/currencyExchange';
import { SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI';
import { McLineChart, Options } from '@mcui/mccharts'

@Styles
function basicChart() {
  .margin({ bottom: 12 })
  .width('100%')
  .padding(16)
  .borderRadius(15)
  .backgroundColor($r("app.color.Basic_Card_background"))
}

interface chartResult {
  income: number[],
  expense: number[],
  surplus: number[]
}


// 返回 { income, expense, surplus } 三个长度为7的数组
export async function calculateWeeklyTables(recordList: RecordItem[],
  targetCurrency: string): Promise<chartResult> {
  const income: number[] = new Array(7).fill(0);
  const expense: number[] = new Array(7).fill(0);
  const surplus: number[] = new Array(7).fill(0);

  const now = new Date();
  const currentDay = now.getDay(); // 0 = Sunday
  const mondayOffset = (currentDay + 6) % 7;
  const monday = new Date(now);
  monday.setDate(now.getDate() - mondayOffset);
  monday.setHours(0, 0, 0, 0);

  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  sunday.setHours(23, 59, 59, 999);

  for (const item of recordList) {
    try {
      const date = new Date(item.date);
      if (isNaN(date.getTime())) {
        continue;
      }
      if (date < monday || date > sunday) {
        continue;
      }

      const dayIndex = (date.getDay() + 6) % 7; // 0..6 for Mon..Sun

      let amount = Number(item.amount) || 0;

      // 汇率转换：把 item.unit 转换到 targetCurrency
      if (item.unit && item.unit !== targetCurrency) {
        const rate = await displayExchangeRates(targetCurrency, item.unit);
        if (!Number.isNaN(rate) && rate !== 0) {
          amount = amount / rate;
        } else {
          amount = 0;
        }
      }

      if (amount >= 0) {
        income[dayIndex] += amount;
      } else {
        expense[dayIndex] += amount; // 保持为负值，便于后续 surplus = income + expense
      }

    } catch (error) {
      console.warn('跳过无效记录:', item, error);
    }
  }

  for (let i = 0; i < 7; i++) {
    surplus[i] = income[i] + expense[i];
  }
  for (let i = 0; i < 7; i++) {
    income[i] = parseFloat(income[i].toFixed(1));
    expense[i] = parseFloat(expense[i].toFixed(1));
    surplus[i] = parseFloat(surplus[i].toFixed(1));
  }

  return { income, expense, surplus };
}


@ComponentV2
export struct WeeklyChart {
  @Require @Param recordList: RecordItem[] = [];
  @Require @Param unit: string = ""

  @Monitor('recordList')
  onChanged(monitor: IMonitor) {
    calculateWeeklyTables(this.recordList, this.unit).then((result) => {
      //设定为目标数字
      this.tempIncome = result.income
      this.tempExpense = result.expense
      this.tempSurplus = result.surplus;
    })
  }

  @Local selectedIndex: number = 0;
  @Local textItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '周收支' },
    { text: '周盈余' },
  ]);
  @Local pillarHeight: number = 120
  // 星期标签
  private days: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  @Local tempIncome: number[] = new Array(7).fill(0)
  @Local tempExpense: number[] = new Array(7).fill(0)
  @Local tempSurplus: number[] = new Array(7).fill(0)
  @Local seriesOption: Options = new Options({

    xAxis: {
      axisLabel: {

        fontWeight: '600',
        fontSize: 30,
      },

      data: ['一', '二', '三', '四', '五', '六', '日']
    },
    yAxis: {
      axisLabel: {

        fontWeight: '600',
        fontSize: 35,
      },
      name: this.unit
    },
    series: [
      {
        name: '收入',
        data: new Array(7).fill(0),
        endLabel: { color: '#66CCFF' },
        label: {
          // 文本标签样式
          fontWeight: '600',

          fontSize: 35,

        }
      },
      {
        name: '支出',
        data: new Array(7).fill(0),
        label: {
          // 文本标签样式
          fontWeight: '600',

          fontSize: 35,

        }
      },
    ],
    legend: {
      show: true,

      itemGap: 30, // 图例每项之间的间隔。横向布局时为水平间隔，纵向布局时为纵向间隔。

      textStyle: {
        fontSize: 40,
        color: "#808080"
      }
    },
  })

  // 获取最大值用于计算比例
  private getMaxAbsValue(nums: number[]): number {
    if (nums.length === 0) {
      return 100;
    }
    const maxPositive = Math.max(...nums.filter(val => val >= 0));
    const minNegative = Math.min(...nums.filter(val => val < 0));

    const maxAbs = Math.max(
      maxPositive > 0 ? maxPositive : 0,
      Math.abs(minNegative < 0 ? minNegative : 0)
    );
    return maxAbs > 0 ? maxAbs * 1.1 : 100;
  }

  // 格式化数值显示
  private formatValue(value: number): string {
    const absValue = Math.abs(value);
    if (absValue >= 1000) {
      return (value / 1000).toFixed(1) + 'k';
    }
    if (Number.isInteger(value)) {
      return value.toString()
    } else {
      return value.toFixed(1).toString();
    }
  }

  // 计算总计
  private getTotal(nums: number[]): number {
    return nums.reduce((sum, val) => sum + val, 0);
  }

  // 计算平均值
  private getAverage(): number {
    return Math.round(this.getTotal(this.tempSurplus) / 7);
  }

  aboutToAppear() {
    calculateWeeklyTables(this.recordList, this.unit).then((result) => {
      //设定为目标数字
      this.tempIncome = result.income
      this.tempExpense = result.expense.map(val => Math.abs(val));
      this.tempSurplus = result.surplus;
    })
  }

  build() {
    Column() {
      CapsuleSegmentButtonV2({
        items: this.textItems,
        selectedIndex: this.selectedIndex,
        $selectedIndex: (index: number) => {
          this.selectedIndex = index;
        }
      }).width("80%")
      Column() {
        // 数据统计摘要
        if (this.selectedIndex === 0) {
          Row() {
            Index({ list: this.recordList, unit: this.unit })
          }
          .height(220)
        } else {
          // 柱状图图表主体
          Row() {

            // 柱状图区域
            Column() {
              // 柱状图
              Row() {
                ForEach(this.tempSurplus, (value: number, index: number) => {
                  // 每个柱子、标签的容器 - 关键修改：固定宽度确保对齐
                  Column() {
                    // 柱子上的数值标签
                    if (!Number.isNaN(value)) {
                      Text(this.formatValue(value))
                        .fontSize(12)
                        .margin({ bottom: 5 })
                        .opacity(0.8)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                    } else {
                      // 空占位，保持高度一致

                      Text('')
                        .fontSize(11)
                        .margin({ bottom: 4 })
                        .height(16)
                        .opacity(0)
                    }

                    // 柱子容器
                    Stack() {
                      // 柱子背景（可选，用于视觉参考）
                      Column()
                        .width(15)
                        .height(this.pillarHeight)
                        .backgroundColor(0x10000000)
                        .borderRadius(6)


                      // 柱子前景（根据数值比例）
                      if (value != 0) {
                        Column()
                          .width(15)
                          .height(this.pillarHeight * (Math.abs(value) / this.getMaxAbsValue(this.tempSurplus)))
                          .backgroundColor(value > 0 ? 0xFF4CAF50 : 0xFFF44336)
                          .borderRadius(6)
                          .align(Alignment.Bottom)
                          .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                      }
                    }
                    .width(28)
                    .height(this.pillarHeight)


                    // X轴日期标签
                    Text(this.days[index])
                      .fontSize(12)
                      .margin({ top: 8 })
                      .width('100%')
                      .textAlign(TextAlign.Center)
                  }
                  .width("12%") // 固定每个柱状图区域的宽度
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => {
                    console.log(`点击了${this.days[index]}, 数值: ${value}`);
                  })
                })
              }
              .justifyContent(FlexAlign.SpaceBetween)
              .width('100%')
              .height(180)
            }
            .layoutWeight(1)
          }
          .height(180)
        }
      }
      .margin({ top: 8 })
      .justifyContent(FlexAlign.Center)

      Column({ space: 8 }) {
        Text(`本周收入: ${this.getTotal(this.tempSurplus).toFixed(2)} ${this.unit}`)
          .fontSize(15)
        Text(`每日平均收入: ${this.getAverage()} ${this.unit}`)
          .fontSize(15)
      }
      .width('100%')
      .padding(16)
      .borderRadius(15)
      .backgroundColor($r("app.color.Basic_Card_background"))
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .alignItems(HorizontalAlign.Start)
    }.basicChart()
    .shadow({
      radius: 6,
      color: 0x0A000000,
      offsetX: 0,
      offsetY: 2
    })

  }
}


@Component
struct Index {
  // 初始化数据
  @Prop @Watch('onListChange') list: RecordItem[]

  onListChange(propName: string): void {
    this.setData()
  }

  @Prop @Watch('onUnitChange') unit: string

  onUnitChange(propName: string): void {
    this.setData()
  }

  @State result: chartResult = {
    income: [],
    expense: [],
    surplus: []
  }
  // 通过watch 监听recordItem变化, 然后请求table赋值

  @State seriesOption: Options = new Options({
    xAxis: {
      axisLabel: {

        fontWeight: '400',
        fontSize: 25,
      },

      data: ['一', '二', '三', '四', '五', '六', '日']
    },
    yAxis: {
      axisLabel: {

        fontWeight: '600',
        fontSize: 35,
      },
      name: this.unit,
      nameTextStyle: {

        fontWeight: 'normal',
        fontFamily: 'sans-serif',
        fontSize: 35,
      },
    },

    series: [
      {
        name: '收入',
        data: new Array(7).fill(0),
        smooth: true,
        color: '#4CAF50',
        label: {
          fontWeight: '500',
          fontSize: 35,
        },
        lineStyle: {
          // 折线样式配置
          width: 3,
          type: 'solid'
        },
      },


      {
        name: '支出',
        data: new Array(7).fill(0),
        smooth: true,
        color: '#F44336',

        label: {
          // 文本标签样式
          fontWeight: '600',
          fontSize: 35,
        },
        lineStyle: {
          // 折线样式配置
          width: 3,
          type: 'solid'
        },
      },

    ],
    legend: {
      show: true,
      itemGap: 30,
      textStyle: {
        fontSize: 40,
        color: "#808080"
      }

    },
  })

  setData() {
    calculateWeeklyTables(this.list, this.unit).then((res) => {
      this.result = res
      console.log(this.result.income.length.toString() + " " + this.result.expense.length);
      this.seriesOption.setVal({
        series: [
          {
            name: '收入',
            data: this.result.income,
          },


          {
            name: '支出',
            data: this.result.expense.map(val => Math.abs(val))
          },

        ],
      })
    })

  }

  aboutToAppear(): void {
    this.setData()
  }

  build() {

    Column() {
      McLineChart({
        options: this.seriesOption
      })

    }

  }
}