import App from "@system.app";
import { RecordItem, RecordsData } from "../../models/recordItemReference"
import { variousToPreferred } from "../../utils/moneyCount"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { displayExchangeRates } from '../../utils/currencyExchange';

@Styles
function basicChart() {
  .margin({ bottom: 12 })
  .width('100%')
  .padding(16)
  .borderRadius(15)
  .backgroundColor($r("app.color.Basic_Card_background"))
}

export async function calculateWeeklyData(recordList: RecordItem[], targetCurrency: string): Promise<number[]> {
  const weeklyData: number[] = new Array(7).fill(0); // 周一到周日

  const now = new Date();
  const currentDay = now.getDay(); // 0 = 周日
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
      if (date >= monday && date <= sunday) {
        const dayIndex = (date.getDay() + 6) % 7;

        let amount = Number(item.amount) || 0;

        // 汇率转换
        if (item.unit !== targetCurrency) {
          const rate = await displayExchangeRates(targetCurrency, item.unit);
          if (!Number.isNaN(rate)) {
            amount = amount / rate;
          } else {
            amount = 0;
          }
        }

        weeklyData[dayIndex] += amount;
      }
    } catch (error) {
      console.warn(`跳过无效记录:`, item, error);
    }
  }

  return weeklyData;
}


@Component
export struct WeeklyChart {
  @State pillarHeight: number = 120
  // 接收外部传入的周数据，默认为0
  @Prop data: number[] = [0, 0, 0, 0, 0, 0, 0];
  // 星期标签
  private days: string[] = ['一', '二', '三', '四', '五', '六', '日'];

  // 获取最大值用于计算比例
  private getMaxAbsValue(): number {
    if (this.data.length === 0) {
      return 100;
    }

    const maxPositive = Math.max(...this.data.filter(val => val >= 0));
    const minNegative = Math.min(...this.data.filter(val => val < 0));

    const maxAbs = Math.max(
      maxPositive > 0 ? maxPositive : 0,
      Math.abs(minNegative < 0 ? minNegative : 0)
    );

    return maxAbs > 0 ? maxAbs * 1.1 : 100;
  }

  // 获取Y轴刻度值
  private getYAxisValues(): number[] {
    const maxValue = this.getMaxAbsValue();
    return [0, Math.floor(maxValue * 0.25), Math.floor(maxValue * 0.5), Math.floor(maxValue * 0.75),
      Math.floor(maxValue)];
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
  private getTotal(): number {
    return this.data.reduce((sum, val) => sum + val, 0);
  }

  // 计算平均值
  private getAverage(): number {
    return Math.round(this.getTotal() / 7);
  }

  build() {
    Column() {
      Text("本周总结")
      // 图表主体
      Row() {

        // 柱状图区域
        Column() {
          // 柱状图
          Row() {
            ForEach(this.data, (value: number, index: number) => {
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
                      .height(this.pillarHeight * (Math.abs(value) / this.getMaxAbsValue()))
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


      // 数据统计摘要
      Row() {
        Text(`总计: ${this.getTotal().toFixed(2)}`)
          .fontSize(15)


        Text(`平均: ${this.getAverage()}`)
          .fontSize(15)
          .margin({ left: 16 })
      }
      .margin({ top: 8 })
      .justifyContent(FlexAlign.Center)

    }.basicChart()
    .shadow({
      radius: 6,
      color: 0x0A000000,
      offsetX: 0,
      offsetY: 2
    })

  }
}