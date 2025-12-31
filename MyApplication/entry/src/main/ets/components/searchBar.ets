import { RecordItem } from '../models/recordItemReference';
import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { findFlag } from '../utils/FindCountryFlags';
import { variousToPreferred } from '../utils/moneyCount';
import { CachedRatesStatus, UserSetting } from "../models/userSetting"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { formatLargeNumber } from "../utils/formatLargeNumber"
import { recordDeleter } from "../utils/recordDeleter"
import { systemDateTime } from '@kit.BasicServicesKit';

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


//记账记录
@ComponentV2
export struct searchItemView {
  @Require @Param item: RecordItem
  @Local isShowSheet: boolean = false;

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
export struct searchBarView {
  @Require @Param recordList: RecordItem[];
  @Local searchKeyword: string = '';

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

  get filteredList(): RecordItem[] {
    const keyword = this.searchKeyword.trim().toLowerCase();
    if (!keyword) {
      return this.recordList;
    }

    const result: RecordItem[] = [];

    for (let item of this.recordList) {
      const amountStr = item.amount?.toString() ?? '';
      const categoryStr = item.tag?.toLowerCase() ?? '';
      const noteStr = item.note?.toLowerCase() ?? '';

      let matched = false;

      if (amountStr.includes(keyword)) {
        matched = true;
      } else if (categoryStr.includes(keyword)) {
        matched = true;
      } else if (noteStr.includes(keyword)) {
        matched = true;
      }

      if (matched) {
        result.push(item);
      }
    }

    return result;
  }

  get groupedRecords(): Map<string, RecordItem[]> {
    const map = new Map<string, RecordItem[]>();
    for (const item of this.recordList) {
      const dateKey = item.date?.slice(0, 10) ?? '未知日期';
      if (!map.has(dateKey)) {
        map.set(dateKey, []);
      }
      map.get(dateKey)!.push(item);
    }
    return map;
  }

  build() {
    Stack() {
      List() {
        ListItem() {
          Column() {

            Row() {
            }.width("95%").height(40).justifyContent(FlexAlign.SpaceBetween)

            if (this.searchKeyword.trim() === '') {
              ForEach(this.records, (group: GroupedRecord) => {
                Column() {
                  Text(group.shownDate)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 6 });

                  ForEach(group.items, (item: RecordItem) => {
                    searchItemView({ item });
                  });
                }
                .width('100%')
                .padding(8)
                .borderRadius(15)
                .margin({ bottom: 12 })
                .backgroundColor($r("app.color.Basic_Card_background"))
              });
            } else {
              ForEach(this.filteredList, (item: RecordItem) => {
                searchItemView({ item });
              });
            }


            //如果有内容则显示filteredList

          }
        }
      }
      .backgroundColor($r('app.color.Darker_window_background'))
      .width('100%')
      .padding(16)
      .borderRadius(15)
      .margin({ top: 4 })

      TextInput({ placeholder: 'Search for amount, tag' })
        .width("100%")
        .height(50)
        .backgroundColor($r('app.color.Basic_Card_background'))
        .onChange((value: string) => {
          this.searchKeyword = value;
        })
    }.margin({ bottom: 8 }).alignContent(Alignment.Top)
  }
}
