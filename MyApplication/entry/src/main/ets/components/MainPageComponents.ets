import { BudgetItem, RecordItem, LedgerManager } from '../models/recordItemReference';
import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { findFlag } from '../utils/FindCountryFlags';
import { variousToPreferred } from '../utils/moneyCount';
import { CachedRatesStatus, UserSetting } from "../models/userSetting"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { formatLargeNumber } from "../utils/formatLargeNumber"
import { recordDeleter } from "../utils/recordDeleter"
import { systemDateTime } from '@kit.BasicServicesKit';


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

  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  @Monitor('userSetting.preferredCurrency')
  onCurrencyChange(monitor: IMonitor) {
    console.log("From Monthly Panel: preferredCurrency changed");
    this.updateMonthlySummary();
  }

  @Local
  cachedRatesStorage: CachedRatesStatus = PersistenceV2.connect(
    CachedRatesStatus,
    "cachedRatesStatus",
    () => new CachedRatesStatus()
  )!;

  @Monitor('cachedRatesStorage.lastUpdateTime')
  onStatusChange(monitor: IMonitor) {
    console.log("From Monthly Panel: lastUpdateTime changed");
    this.updateMonthlySummary();
  }

  @Local monthlyInOut: number[] = [0, 0]

  aboutToAppear(): void {
    this.updateMonthlySummary()
  }

  private async updateMonthlySummary() {
    try {
      this.monthlyInOut = await variousToPreferred(this.recordList, this.ledgerManager.activeBook.preferredCurrency);
      console.log('月度统计已更新');
    } catch (error) {
      console.error('更新月度统计失败:', error);
    }
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Column() {
          Text($r('app.string.totalExpense'))
          Text(formatLargeNumber(this.monthlyInOut[0] - this.monthlyInOut[1]) + " " +
          this.ledgerManager.activeBook.preferredCurrency)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)


        }.alignItems(HorizontalAlign.Start)

        // 本月支出&收入
        Column() {
          Row() {
            Text($r('app.string.Summary'))
              .fontSize(16)
            Text(formatLargeNumber(this.monthlyInOut[1]))
              .fontColor('#FF3A3A')
          }
          .onClick(() => {
            // 可以在这里添加点击事件处理
          })

          Row() {
            Text($r('app.string.Income'))
              .fontSize(16)
            Text(formatLargeNumber(this.monthlyInOut[0]))
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
  @Local isShowSheet: boolean = false;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  handleDelete(item: RecordItem) {
    new recordDeleter().deleteDataFromAll(item);
  }

  @Builder
  mySheet() {
    Column() {
      // 标题
      Text('记录详情')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      // 金额和货币类型
      Row() {
        Text(`${this.item.type === 'expense' ? '' : '+'}${this.item.amount}`)
          .fontSize(24)
          .fontColor(this.item.type === 'expense' ? '#FF3A3A' : '#00B300')
          .fontWeight(FontWeight.Bold)

        findFlag({ flagName: this.item.unit })
          .margin({ left: 8 })
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .margin({ bottom: 20 })

      // 详细信息容器
      Column() {
        // 标签/分类
        Row() {
          Text('分类：')
            .fontSize(16)
            .fontColor('#666')
            .width(80)
          Text(this.item.tag || '未分类')
            .fontSize(16)
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .margin({ bottom: 12 })

        // 设定时间
        Row() {
          Text('日期：')
            .fontSize(16)
            .fontColor('#666')
            .width(80)
          Text(formatDateAdvanced(this.item.date, "YYYY-MM-DD") || '未设定')
            .fontSize(16)
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .margin({ bottom: 12 })

        // 备注
        Row() {
          Text('备注：')
            .fontSize(16)
            .fontColor('#666')
            .width(80)
          Text(this.item.note || '无备注')
            .fontSize(16)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width(200)
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .margin({ bottom: 20 })
      }
      .padding({ left: 24, right: 24 })

      Image(this.item.selectimageUriedImage).borderRadius(12).shadow(ShadowStyle.OUTER_DEFAULT_MD)

      Image($r('app.media.bin')).height(45).width(45).margin({ top: 8 }).onClick(() => {
        this.handleDelete(this.item)
        this.ledgerManager.activeBook.cloudTrashBin.push(this.item.id)
      })

    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  build() {

    Column() {
      Line()
        .width(2000)  // 线的长度
        .height(1)   // 线的粗细
        .backgroundColor(Color.Gray)
        .opacity(0.2)


      Row() {
        Row() {
          Text(this.item.tag)
            .fontSize(16)
            .margin({ right: 6 })
          if (this.item.note !== "") {
            Text("i")
              .fontWeight(FontWeight.Medium)
              .width(24)
              .height(24)
              .textAlign(TextAlign.Center)
              .fontSize(20)
              .backgroundColor($r('app.color.start_window_background'))
              .borderRadius(22)
              .padding(0)
              .align(Alignment.Center)
              .margin({ right: 6 })
          }

          if (this.item.selectimageUriedImage !== "") {
            Image($r('app.media.image'))
              .width(24)
              .borderRadius(4)
              .align(Alignment.Center)
              .margin({ right: 6 })
          }
        }


        Row() {
          Text(`${this.item.type === 'expense' ? '' : '+'}${this.item.amount}`)
            .fontSize(18)
            .fontColor(this.item.type === 'expense' ? '#FF3A3A' : '#00B300')
            .margin({ right: 8 })
          findFlag({ flagName: this.item.unit })
        }
      }.width("95%").height(40).justifyContent(FlexAlign.SpaceBetween)

    }
    .onClick(() => {
      this.isShowSheet = !this.isShowSheet
    })
    .bindSheet(this.isShowSheet, this.mySheet(), {
      height: 300,
      onWillDisappear: () => {
        this.isShowSheet = false
      }
    })
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

    for (const item of this.recordList) {
      const date = new Date(item.date);
      date.setHours(0, 0, 0, 0); // 清除时间部分
      const dateKey = date.toDateString(); // 标准 YYYY-MM-DD

      if (!groups.has(dateKey)) {
        groups.set(dateKey, []);
      }
      groups.get(dateKey)!.push(item);
    }

    const result: GroupedRecord[] = [];
    groups.forEach((items, date) => {

      let shownDate: string;
      let today: number = Number(formatDateAdvanced(new Date, "DD"))
      if (today - Number(formatDateAdvanced(date, "DD")) === 0) {
        shownDate = '今天'
      } else if (today - Number(formatDateAdvanced(date, "DD")) === -1) {
        shownDate = '明天'
      } else if (today - Number(formatDateAdvanced(date, "DD")) === 1) {
        shownDate = '昨天'
      } else {
        shownDate = formatDateAdvanced(date, "MM-DD");
      }
      result.push({
        date,
        items,
        shownDate: shownDate
      });
    });

    return result.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
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
                .margin({ top: 10, bottom: 6 })
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