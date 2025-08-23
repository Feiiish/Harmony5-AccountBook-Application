import { RecordItem } from '../models/recordItemReference';
import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { findFlag } from '../utils/FindCountryFlags';
import { monthlyInMonthlyOut } from '../utils/moneyCount';


//规定普通Row样式
@Extend(Row)
function currencyCard() {
  .justifyContent(FlexAlign.Start)
  .width("28%")
  .padding(4)
  //.backgroundColor(Color.Red)
}

@Styles
function basicCard() {
  .width('100%')

  .padding(16)
  .borderRadius(15)
  .margin({ bottom: 12 })
  .backgroundColor($r("app.color.Basic_Card_background"))
}


@ComponentV2
export struct MonthlySummaryPanel {
  @Require @Param recordList: RecordItem[];

  @Monitor('recordList')
  onItemsChange(monitor: IMonitor) {
    this.updateMonthlySummary()
  }

  @Local monthlyInOut: number[] = [0, 0]

  aboutToAppear(): void {
    this.updateMonthlySummary()
  }

  private async updateMonthlySummary() {
    try {
      this.monthlyInOut = await monthlyInMonthlyOut(this.recordList, "CNY");
      console.log('月度统计已更新');
    } catch (error) {
      console.error('更新月度统计失败:', error);
    }
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Column() {
          Text("本月结余≈")
          Text((this.monthlyInOut[0] - this.monthlyInOut[1]).toFixed(2) + "")
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
        }.alignItems(HorizontalAlign.Start)

        // 本月支出&收入
        Column() {
          Row() {
            Text('本月支出')
              .fontSize(16)
              .fontColor('#666666')
            Text(this.monthlyInOut[1].toFixed(2) + "")
              .fontColor('#FF3A3A')
          }
          .onClick(() => {
            // 可以在这里添加点击事件处理
          })

          Row() {
            Text('本月收入')
              .fontSize(16)
              .fontColor('#666666')
            Text(this.monthlyInOut[0].toFixed(2) + "")
              .fontColor('#00B300')
          }
          .onClick(() => {
            // 可以在这里添加点击事件处理
          })
        }.alignItems(HorizontalAlign.Start)

      }.width("100%").justifyContent(FlexAlign.SpaceBetween)
    }
    .basicCard()
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
  }
}


//记账记录
@ComponentV2
export struct RecordItemView {
  @Require @Param item: RecordItem

  build() {

      Column(){
        Line()
          .width(2000)  // 线的长度
          .height(1)   // 线的粗细
          .backgroundColor(Color.Gray)
          .opacity(0.2)


        Row(){
          Text(this.item.tag)
            .fontSize(16)


          Row() {
            Text(`${this.item.type === 'expense' ? '' : '+'}${this.item.amount}`)
              .fontSize(18)
              .fontColor(this.item.type === 'expense' ? '#FF3A3A' : '#00B300')
              .margin({ right: 8 })
            findFlag({ flagName: this.item.unit })
          }
        }     .width("95%").height(40)   .justifyContent(FlexAlign.SpaceBetween)




    }
    .borderRadius(12)
  }
}

interface GroupedRecord {
  date: string; // 原始日期字符串
  items: RecordItem[];
  shownDate: string; // 显示用的友好日期
}

@ComponentV2
export struct RecordListView {
  @Require @Param recordList: RecordItem[];

  // 计算属性 - 生成带友好日期的分组记录
  private get records(): GroupedRecord[] {
    const groups = new Map<string, RecordItem[]>();
    const today = new Date();
    today.setHours(0, 0, 0, 0); // 清除时间部分

    // 分组逻辑
    for (const item of this.recordList) {
      const dateKey = item.date.split('T')[0];
      if (!groups.has(dateKey)) {
        groups.set(dateKey, []);
      }
      groups.get(dateKey)!.push(item);
    }

    // 转换为数组并添加shownDate
    const result: GroupedRecord[] = [];
    groups.forEach((items, date) => {
      result.push({
        date,
        items,
        shownDate: this.getFriendlyDate(date, today)
      });
    });

    // 按日期排序
    return result.sort((a, b) => b.date.localeCompare(a.date));
  }

  // 获取友好日期显示
  private getFriendlyDate(isoDate: string, today: Date): string {
    const date = new Date(isoDate);
    date.setHours(0, 0, 0, 0);

    const diffDays = Math.round((today.getTime() - date.getTime()) / (1000 * 60 * 60 * 24));

    switch (diffDays) {
      case 0:
        return "今天";
      case 1:
        return "昨天";
      case -1:
        return "明天";
      default:
      // 其他情况显示月日
        return formatDateAdvanced(isoDate, 'MM-DD');
    }
  }

  build() {
    Column() {
      if (this.recordList.length === 0) {
        Column() {
          Text("暂无账单数据")
            .fontSize(16)
            .opacity(0.5)
            .margin(20)
        }.basicCard()

      }

      List() {
        ForEach(this.records, (group: GroupedRecord) => {
          ListItem() {
            Column() {
              // 显示友好日期
              Text(group.shownDate)
                .fontSize(15)
                .margin({top:10, bottom:6})
                .fontWeight(FontWeight.Bold)

              ForEach(group.items, (item: RecordItem) => {
                RecordItemView({ item })
              })
            }.basicCard().padding(2)
          }
        })
      }
    }
  }
}