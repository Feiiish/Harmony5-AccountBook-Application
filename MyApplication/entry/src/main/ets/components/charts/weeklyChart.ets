@Component
export struct WeeklyChart {
  // 接收外部传入的周数据，默认为0
  @Prop data: number[] = [0, 0, 0, 0, 0, 0, 0];

  // 柱子颜色数组
  private colors: number[] = [
    0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFFF44336,
    0xFF9C27B0, 0xFF607D8B, 0xFFFFEB3B
  ];

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
        // Y轴刻度
        Column() {
          ForEach(this.getYAxisValues(), (value:number) => {
            Text(this.formatValue(value))
              .fontSize(10)
              .fontColor(0x666666)
              .height(20)
              .width(35)
              .textAlign(TextAlign.End)
              .margin({ right: 8, bottom: 12 })
          })
        }
        .justifyContent(FlexAlign.SpaceBetween)

        // 柱状图区域
        Column() {
          // 柱状图
          Row({ space: '12%' }) {
            ForEach(this.data, (value: number, index) => {
              Column() {
                // 柱子上的数值标签
                if (value > 0) {
                  Text(this.formatValue(value))
                    .fontSize(11)
                    .fontColor(0x333333)
                    .margin({ bottom: 4 })
                    .opacity(0.8)
                }

                // 柱子容器
                Stack() {

                  // 柱子前景（根据数值比例）
                  if (value > 0) {
                    Column()
                      .width(15)
                      .height(180 * (value / this.getMaxValue()))
                      .backgroundColor(this.colors[index])
                      .borderRadius(6)
                      .position({ y: 180 - (180 * (value / this.getMaxValue())) })
                  }
                }
                .width(28)
                .height(180)

                // X轴日期标签
                Text(this.days[index])
                  .fontSize(12)
                  .fontColor(0x666666)
                  .margin({ top: 8 })
              }
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                console.log(`点击了${this.days[index]}, 数值: ${value}`);
              })
            })
          }
          .height(180)
          .alignItems(VerticalAlign.Bottom)
          .width('100%')


        }
        .layoutWeight(1)
      }
      .height(250)

      // 数据统计摘要
      Row() {
        Text(`总计: ${this.getTotal()}`)
          .fontSize(12)
          .fontColor(0x666666)

        Text(`平均: ${this.getAverage()}`)
          .fontSize(12)
          .fontColor(0x666666)
          .margin({ left: 16 })
      }
      .margin({ top: 12 })
    }
    .padding(16)
    .backgroundColor(0xFFFFFFFF)
    .borderRadius(12)
    .shadow({ radius: 6, color: 0x0A000000, offsetX: 0, offsetY: 2 })
    .width('100%')
  }
}