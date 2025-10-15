import {
  CellStatus,
  CJCalendarControl,
  CJCalStatusParams,
  CJCellStyle,
  CJDateItem,
  CJCalendar,
  SelectedShape,
  SelectedStyle,
  CJViewModel,
  OptMode,
  CJDateShowBackMode
} from 'cjcalendar';

import { findFlag } from '../../utils/FindCountryFlags';

import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'
import { RecordItem, RecordsData, LedgerManager, filterRecordItems } from '../../models/recordItemReference';


@ComponentV2
@Entry
export struct calendar {
  @Local selectedRecords: RecordItem[] = [];
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  cjDataItem: CJDateItem = new CJDateItem(new Date())
  @Local message: string = 'Hello World';
  cjCellStyle: CJCellStyle = new CJCellStyle()
  cjCalStatus: CJCalStatusParams = new CJCalStatusParams()
  cjCellStatus: CellStatus = new CellStatus()
  controller: CJCalendarControl = new CJCalendarControl()
  @Local defSelectedItems: Array<string> = ["2024-11-03", "2024-11-08"]
  @Local extras: Record<string, number | string | boolean> = {}
  // 测试刷新
  @Local test: string = "xx"
  @Local dateList: number[] = []
  @Local YYYYMMtime: string = ""

  updateDateList() {
    const cjDate = new Date(this.cjDataItem.fullYear, this.cjDataItem.month, 1)
    this.YYYYMMtime = cjDate.getFullYear().toString() + cjDate.getMonth()
    const records = this.ledgerManager.activeBook.data.toMonthItems(cjDate)
    for (let index = 0; index < records.length; index++) {
      const result = new Date(records[index].date).getDate()
      if (!this.dateList.includes(result)) {
        this.dateList.push(result)
        console.log("new item pushed " + result);
      }
    }
  }

  build() {
    Column() {
      CJCalendar({
        logSwitch: true,
        controller: this.controller,
        extras: this.extras,
        // 初始化默认选中项目
        optMode: OptMode.RANGE,
        // 切换从周一 / 周天开始

        selectedShape: SelectedShape.SHAPE_CIRCLE,
        selectedStyle: SelectedStyle.ALONE,
        // 全局圆角设置
        // selectedBorderRadius: 50,
        // 是否需要标记处今日
        isNeedMarkToday: true,
        // 回显方式，只有在 OptMode.NORMAL下才生效
        dateShowBackMode: CJDateShowBackMode.SHOW_PRE_LAST_NEXT_FIRST | CJDateShowBackMode.SHOW_CLICK,
        viewModel: CJViewModel.MONTH,
        // 初始化选中项
        // defSelectedItems: [new Date("2024-12-02")],
        // 指定每一行高度，如果没有特殊需求不需要指定
        // itemCellHeight: 55,
        // startDate: new Date("2024-12-02"),
        // endDate:  new Date("2025-01-15"),
        // initShowDate: new Date("2024-05-01"),
        showFastToday: true,
        // 是否显示折叠按钮
        isShowFoldView: false,
        // 标题栏高度
        // titleHeight: 100,
        // 标题栏背景色
        // titleBackgroundColor: Color.Green,
        // 标题格式化显示
        titleFormat: "yyyy年MM月",
        titleFontColor: $r('app.color.Font_Color'),
        // 是否显示农历
        showLunar: false,
        // 设置整个月份视图高度
        // monthHeight: 400,
        // 是否显示节日
        showJieRi: false,
        // 仅需要日期显示区域，不需要底部自定义区域
        onlyShowDateArea: false,
        // 是否将底部自定义区域添加到整体
        isAttchCustomLayoutToWhole: false,
        // 主题色
        themeColor: "#d13f3f",
        // 是否显示节气
        // showJieQi: false,
        // 是否仅显示当月日期
        // onlyShowCurrMonthDay: true,
        // showToolbar: true,
        // 自定义标题栏
        // toolbarLayout: this.ToolbarLayout,
        // 不可选中Cell背景
        // buildDisableCellBackground: this.BuildDisableCellBackground,

        // 当需要自定义农历部分描述信息时添加以下方法
        // buildCellLunarDesc:(item:CJDateItem)=>{
        //   return ""
        // },
        onMonthChanged: (month: CJDateItem) => {
          this.updateDateList()
          console.log("月份切换结束：", month.toString())
        },
        onCellItemClick: (item: CJDateItem) => {
          // 这里修改数据后会同步更新到界面
          // item.date = item.date + 1
          // item.extras.set("test", "-" + (item.date + 1) + "-")
          console.log("点击了：", JSON.stringify(item))
          return false
        },
        // 点击拦截，可根据业务实现点击拦截
        // onCellClickIntercept:(item: CJDateItem)=>{
        //   if (item.date == 2 || item.date == 4) {
        //     return true
        //   }
        //   return false
        // },
        onDisableCellItemClick: (item: CJDateItem) => {
          console.log("越界点击了：", JSON.stringify(item))
          return false
        },
        onSelectedChanged: (items: Array<CJDateItem>) => {

          if (items.length === 0) {
            return;
          }
          console.log("选择变化：", JSON.stringify(items));
          // Assuming items are sorted or you want the first and last selected dates
          const startD = new Date(items[0].fullYear, items[0].month, items[0].date,);
          console.log("std: " + startD.toDateString());
          const endD =
            new Date(items[items.length -1].fullYear, items[items.length -1].month, items[items.length -1].date,);
          console.log("end: " + endD.toISOString());
          this.selectedRecords = []
          this.selectedRecords = filterRecordItems(this.ledgerManager.activeBook.data.items, startD, endD);
        },

        // 日历初始化完成
        onInitFinish: () => {

          // 1、强制刷新所有
          this.controller.refresh(false)

          // this.controller.setFoldStatue(true)
          this.updateDateList()

        },
        // 自定义标注
        buildMark: this.BuildMark,
        // 自定义单元格背景
        // buildCellBackground: this.BuildCellBackground,
        // 自定义主体部分
        // buildCellBody: this.BuildCellBody,
        // 向CellItem中添加自定义属性
        reBuildCellItem: (cjDateItem: CJDateItem) => {
          //   // 需要向 CJDateItem 中添加附加数据时，可是使用如下方式
          //   cjDateItem.extras.test = "自定义附加属性" + cjDateItem.date
          if (cjDateItem.isToday) {
            cjDateItem.dateText = "今"
          }
          //   // cjDateItem.desc = "描述" // 根据业务添加描述，一般显示农历，不赋值即可
          if (this.dateList.includes(cjDateItem.date) &&
            (cjDateItem.fullYear.toString() + cjDateItem.month) === this.YYYYMMtime) {
            //     // 文字与图片优先显示图片
            cjDateItem.markText = "标"
            //     cjDateItem.markIcon = $r("app.media.icon")
            //     cjDateItem.markImageUrl =
            //       "https://img2.baidu.com/it/u=2105446738,2493267053&fm=253&fmt=auto&app=138&f=JPEG?w=100&h=100"
          }
          //   if (cjDateItem.fullYear == 2024 && cjDateItem.month == 7
          //     && cjDateItem.date < 20 && cjDateItem.date > 15) {
          //     // 设置不能选中
          //     cjDateItem.disabled = true
          //   }
          //   if (cjDateItem.date > 5 && cjDateItem.date < 13) {
          //     cjDateItem.markText = this.test
          //   }
        },

        // 自定义Cell样式风格
        buildCellStyle: (item: CJDateItem) => {
          let cjCellStyle: CJCellStyle = new CJCellStyle()
          // cjCellStyle.selectItemBackgroundColor = "#b83b5e"
          // if (item.isToday) {
          cjCellStyle.fontColor = $r('app.color.Font_Color')
          //   cjCellStyle.itemBackgroundColor = "#00ccbb"
          // }
          //
          // if ((item.isPre || item.isNext) && item.isToday) {
          //   cjCellStyle.disabledBackgroundColor = "#b83b5e"
          // }

          //   if (item.week == 0 || item.week == 6) {
          //     cjCellStyle.fontColor = "#b83b5e"
          //   }
          //   // 农历字体颜色
          //   cjCellStyle.lunarFontColor = "#AA55CC"
          //   // 设置选中色
          //   cjCellStyle.selectItemBackgroundColor = "#FF00BB"
          //   // 标注样式
          cjCellStyle.markFontColor = $r('app.color.Font_Color')
          //   cjCellStyle.markFontSize = 10
          //   cjCellStyle.markMarin = 4
          //   cjCellStyle.markFontWeight = FontWeight.Bold
          //   cjCellStyle.markImageWidth = 12
          //   cjCellStyle.markAlignment = Alignment.TopEnd
          //
          //   // 设置今天文字颜色
          //   cjCellStyle.todayFontColor = "#FFFFFF"
          //   // 设置今天背景色
          //   cjCellStyle.todayBackgroundColor = "#ff1c6a46"
          //
          //   // 设置空心
          //   // if (item.isToday) {
          //   //   cjCellStyle.todayFontColor = "#ff1c6a46"
          //   //   cjCellStyle.todayBackgroundColor = "#FFFFFF"
          //   //   cjCellStyle.boderColor = "#ff1c6a46"
          //   //   cjCellStyle.boderWidth = 1
          //   //   cjCellStyle.boderRadius = 100
          //   // }
          //   // 根绝条件修改背景色、字体色等
          //   if (item.date < 7) {
          //     cjCellStyle.itemBackgroundColor = "#abedd8"
          //     cjCellStyle.fontColor = "#3f72af"
          //   } else if (item.date >= 10 && item.date < 16) {
          //     cjCellStyle.itemBackgroundColor = "#e4f9f5"
          //     cjCellStyle.fontColor = "#3d84a8"
          //   } else if (item.date >= 20 && item.date <= 28) {
          //     cjCellStyle.itemBackgroundColor = "#88304e"
          //     cjCellStyle.fontColor = "#fae3d9"
          //    }
          return cjCellStyle
        },
        // 自定义星期标题样式
        // buildWeekTitleCell: (week: string) => {
        //   this.BuildWeekTitleCell(week)
        // }
        // 月视图下的用户布局区域
        buildMonthCustomLayout: () => {

        },
      })
        .height(440)
      Column() {
        Text("账单数量： " + this.selectedRecords.length.toString()).height(40)
        ForEach(this.selectedRecords, (item: RecordItem) => {


          Row() {
            Row() {
              Text(item.tag)
                .fontSize(16)
                .margin({ right: 6 })

              if (item.note !== "") {
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

              if (item.selectimageUriedImage !== "") {
                Image($r('app.media.image'))
                  .width(24)
                  .borderRadius(4)
                  .align(Alignment.Center)
                  .margin({ right: 6 })
              }
            }

            Row() {
              Text(`${item.type === 'expense' ? '' : '+'}${item.amount}`)
                .fontSize(18)
                .fontColor(item.type === 'expense' ? '#FF3A3A' : '#00B300')
                .margin({ right: 8 })
              findFlag({ flagName: item.unit })
            }
          }.transition(
            TransitionEffect.OPACITY
              .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 }))
              .animation({ duration: 200, curve: Curve.FastOutSlowIn })
          )


          .width("95%")
          .height(40)
          .justifyContent(FlexAlign.SpaceBetween)

        })


      }
      .backgroundColor($r('app.color.Darker_window_background'))
      .padding(12)
      .width('98%')
      .borderRadius(18)
    }

  }

  @Builder
  BuildMark() {
    Column() {

      Circle()
        .width(8)
        .height(8)
        .fill("#d13f3f")
    }
    .width('100%')
    .height('90%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.End)

    // 或者以下可自定义各种复杂布局
    // Stack() {
    //   // ......
    // }
    // .width("100%")
    // .height("100%")
    // .alignContent(Alignment.TopEnd)
  }

  @Builder
  BuildWeekTitleCell(week: string) {
    Text(week)
      .textAlign(TextAlign.Center)
      .fontColor(week == '日' || week == '六' ? "#b83b5e" : "#9E9E9E")
      .fontSize(13)
      .layoutWeight(1)

  }

  @Builder
  BuildCellBackground() {
    if (this.cjDataItem.isToday && this.cjDataItem.extras.test == '1') {
      Column()
        .backgroundColor("#D13F3F")
        .width(50)
        .height(56)
        .borderRadius(6)
        .opacity(0.5)

    } else if (this.cjDataItem.isToday && this.cjDataItem.extras.test == '0') {
      Column()
        .backgroundColor("#D13F3F")
        .width(50)
        .height(56)
        .borderRadius(6)

    } else if (this.cjDataItem.isToday) {
      Column()
        .backgroundColor("#D13F3F")
        .width(50)
        .height(56)
        .borderRadius(6)
    } else {
      if (this.cjDataItem.isSelected) {
        Column()
          .alignItems(HorizontalAlign.End)
          .justifyContent(FlexAlign.Start)// .backgroundColor(this.cjDataItem.extras.test == '1' ? Color.Orange : this.cjCellStatus.backgroundColor)
          .width(50)
          .height(56)
          .border({
            width: 1,
            color: "#D13F3F"
          })
          .borderRadius(6)
      }
    }
  }

  @Builder
  BuildMonthCustomLayout() {
    Flex({ wrap: FlexWrap.Wrap }) {
      Button("触发点击")
        .onClick(() => {
          // 实现还没写完
          this.controller.clickItem(2024, 6, 6)
        })
      Button("设置选中")
        .onClick(() => {
          this.controller.selectItems(["2024-06-09"])
        })
      Button("显示农历")
        .onClick(() => {
          this.controller.showLunar(true)
        })
      Button("隐藏农历")
        .onClick(() => {
          this.controller.showLunar(false)
        })
      Button("切换周模式")
        .onClick(() => {
          this.controller.changViewModel(CJViewModel.WEEK)
        })
      Button("切换月模式")
        .onClick(() => {
          this.controller.changViewModel(CJViewModel.MONTH)
        })
      Button("切换年模式")
        .onClick(() => {
          this.controller.changViewModel(CJViewModel.YEAR)
        })
      Button("切换单选/常规操作模式")
        .onClick(() => {
          this.controller.changViewModel(CJViewModel.YEAR)
        })
      Button("跳转至指定星期/月份/年份【1996-02-12】")
        .onClick(() => {
          // this.controller.skipToDate("2024-10-12")
          this.controller.skipToDate("2024-08-12")
        })
      Button("折叠")
        .onClick(() => {
          this.controller.setFoldStatue(true)
        })
      Button("展开")
        .onClick(() => {
          this.controller.setFoldStatue(false)
        })

      Button("异步刷新")
        .onClick(() => {
          this.test = "11"
          // 模拟异步请求
          setTimeout(() => {
            this.controller.refresh()
          }, 3000)
        })

      Button("直接修改当前月全部/指定项数据")
        .onClick(() => {
          let days: CJDateItem[] | undefined = this.controller.getCurrMonthDays()
          if (days) {
            days[7].date = 39
          }
        })
    }
    .margin({
      top: 30
    })
  }

  step: number = 1

  @Builder
  BuildCellBody() {

    Column() {
      //
      Text(this.cjDataItem.date + '')
        .fontColor(this.cjDataItem.isPre || this.cjDataItem.isNext ? "#e1e1e1" : Color.Black)
        .fontSize(this.cjCellStyle.fontSize)
        .fontWeight(this.cjCellStyle.fontFontWeight)
      // 可以加备注之类的自定义信息
      Text(this.cjDataItem.extras.test as string)
        .fontSize(10)
        .fontColor(Color.Gray)
        .fontColor(this.cjCellStatus.fontColor)
    }
    .alignItems(HorizontalAlign.Center)

  }

  @Builder
  BuildDisableCellBackground() {
    Column() {
      Text("测试")
    }
    .backgroundColor(Color.Yellow)
    .width('85%')
    .aspectRatio(1)
    .border({
      width: this.cjCellStyle.borderWidth,
      color: this.cjCellStyle.borderColor
    })
    .borderRadius(this.cjCellStyle.borderRadius)

  }
}
