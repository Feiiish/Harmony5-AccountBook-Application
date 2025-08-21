
@Styles
function basicChart() {
  .width('90%')
  .padding(26)
  .borderRadius(15)
  .margin({ bottom: 12 })
  .backgroundColor("#EFEFEF")
}


@Component
export struct WeeklyChart {


  // 接收外部传入的周数据，默认为0
  @Prop data: number[] = [0, 0, 0, 0, 0, 0, 0];


  // 星期标签
  private days: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  // 获取最大值用于计算比例
  private getMaxValue(): number {
    const max = Math.max(...this.data);
    return max > 0 ? max * 1.1 : 100;
  }

  // 获取Y轴刻度值
  private getYAxisValues(): number[] {
    const maxValue = this.getMaxValue();
    return [0, Math.floor(maxValue * 0.25), Math.floor(maxValue * 0.5), Math.floor(maxValue * 0.75), Math.floor(maxValue)];
  }

  // 格式化数值显示
  private formatValue(value: number): string {
    if (value >= 1000) {
      return (value / 1000).toFixed(1) + 'k';
    }
    return value.toString();
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
                if (value > 0) {
                  Text(this.formatValue(value))
                    .fontSize(11)
                    .fontColor(0x333333)
                    .margin({ bottom: 4 })
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
                    .height(180)
                    .backgroundColor(0x10000000)
                    .borderRadius(6)

                  // 柱子前景（根据数值比例）
                  if (value != 0) {
                    Column()
                      .width(15)
                      .height(180 * (value / this.getMaxValue()))
                      .backgroundColor(value > 0 ? 0xFF4CAF50 : 0xFFF44336)
                      .borderRadius(6)
                      .align(Alignment.Bottom)
                  }
                }
                .width(28)
                .height(180)

                // X轴日期标签
                Text(this.days[index])
                  .fontSize(12)
                  .fontColor(0x666666)
                  .margin({ top: 8 })
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width(28) // 固定每个柱状图区域的宽度
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                console.log(`点击了${this.days[index]}, 数值: ${value}`);
              })
            })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .height(220)
        }
        .layoutWeight(1)
      }
      .height(250)


      // 数据统计摘要
      Row() {
        Text(`总计: ${this.getTotal()}`)
          .fontSize(15)
          .fontColor(0x666666)

        Text(`平均: ${this.getAverage()}`)
          .fontSize(15)
          .fontColor(0x666666)
          .margin({ left: 16 })
      }
      .margin({ top: 8 })
      .justifyContent(FlexAlign.Center)

    }      .basicChart()
    .shadow({ radius: 6, color: 0x0A000000, offsetX: 0, offsetY: 2 })

  }
}