//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { RecordItem, RecordsData, LedgerManager, LedgerBook } from '../models/recordItemReference';
import { MultiCurrencyComposition } from '../components/multiCurrency';
import { UserSetting } from "../models/userSetting"
import { WeeklyChart, calculateWeeklyData } from "../components/charts/weeklyChart"
import { ratesStatus } from "../components/RatesStatus"

//components
import { BottomNavigation } from "../components/bottomNavi"
import { RecordListView, MonthlySummaryPanel } from '../components/mainPageComponents';

import { budgetComponent } from '../components/bugetComponent';
import { searchBarView } from '../components/searchBar';
import { datePicker } from '../components/buttons/MonthPicker';
import { Constants } from '../common/Constants';
import { resourceManager } from '@kit.LocalizationKit';
import { formatDateAdvanced } from '../utils/formatDateAdvanced';

@Styles
function buttonList() {
  .backgroundColor($r('app.color.Basic_Card_background'))
  .padding(6)
  .width('90%')
  .borderRadius(14)
  .margin({ bottom: 12 })
}

@Styles
function buttonItemStyle() {
  .backgroundColor($r('app.color.Basic_Card_background'))
  .padding(6)
  .width('90%')
  .borderRadius(14)
  .margin({ bottom: 12 })
}


@Entry
@ComponentV2
export struct menuButtons {
  build() {
    Column() {

      LedgerUI()
      ratesStatus().margin({ bottom: 8 })
      functionButtons1()
      Button()
        .onClick(() => {
          router.pushUrl({
            url: "pages/AddLegerBookPage"
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.log("跳转失败:", err)
            }
          })
        })

    }

  }
}


@ComponentV2
export struct functionButtons1 {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local recordsData: RecordsData = this.ledgerManager.activeBook.data
  @Local menuItems: string[] = [
    '货币设置',
    '删除记录',
    '隐私政策',
  ];

  handleMenuItemClick(item: string) {
    switch (item) {
      case "货币设置":
        router.pushUrl({
          url: "pages/CurrencySetting"
        }, router.RouterMode.Standard, (err) => {
          if (err) {
            console.log("跳转失败:", err)
          }
        })
        console.log('执行货币设置');
        break;
      case "删除记录":
        AlertDialog.show({
          title: `要删除记录吗`,
          message: `此操作不可退回`,
          buttons: [
            {
              value: '取消',
              action: () => {
              }
            },
            {
              value: '确认',
              action: () => {
                this.recordsData.items = []
                console.log('执行删除操作');
              }
            },
          ]
        })

        break;

      case "隐私政策":
        router.pushUrl({
          url: "pages/AboutThisApp"
        }, router.RouterMode.Standard, (err) => {
          if (err) {
            console.log("跳转失败:", err)
          }
        })
        break;
      // 其他case...
    }
  }

  private getMenuItemIcon(item: string): string {
    const iconMap: Record<string, string> = {
      '货币设置': '️💴',
      '删除记录': '🗑️',
      '分享记录': '↗️',
      '隐私政策': '🔒',
      '设置': '⚙️',
      '帮助': '❓',
      '关于应用': 'ℹ️'
    };
    return iconMap[item] || '▪️'; // 默认符号
  }

  build() {
    Column() {
      ForEach(this.menuItems, (item: string, index: number) => {
        Column() {
          Row() {
            // 图标（使用Unicode符号）
            Text(this.getMenuItemIcon(item))
              .fontSize(20)
              .margin({ right: 12 })
              .fontColor('#007AFF')
            // 文字
            Text(item)
              .fontSize(16)
              .layoutWeight(1)
            // 箭头（Unicode符号）
            if (index < this.menuItems.length - 1) {
              Text('❯')
                .fontSize(14)
                .fontColor('#999999')
            }
          }
          .height(48)
          .width('100%')
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.handleMenuItemClick(item);

            this.getUIContext().animateTo({
              duration: Constants.ANIMATION_DURATION,
              curve: Curve.EaseOut,
              playMode: PlayMode.Normal,
            }, () => {
              // 动画完成后的回调
            })
          })

          if (index < this.menuItems.length - 1) {
            Divider()
              .strokeWidth(1)
              .color('#F0F0F0')
              .margin({ left: 24, right: 46 }) // 与图标对齐
          }
        }
      })
    }
    .buttonList()

  }
}

// LedgerUI.ets
@ComponentV2
export struct LedgerUI {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local recordsData: RecordsData = this.ledgerManager.activeBook.data
  @Local newBookName: string = '';

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('账本选择 1/3')
        Text('❯')
          .fontSize(14)
          .fontColor('#999999')
      }.justifyContent(FlexAlign.SpaceBetween).width('95%').onClick(() => {

      })

      ForEach(this.ledgerManager.books, (book: LedgerBook) => {

        Text(book.name)
          .onClick(() => {
            this.ledgerManager.switchBook(book.id);
            this.recordsData = this.ledgerManager.activeBook.data;
          })
          .backgroundColor(book.id === this.ledgerManager.activeBookId ? $r('app.color.Currency_Card_Main') :
          $r('app.color.Currency_Card_1'))
          .width("90%")
          .textAlign(TextAlign.Center)
          .padding(8)
          .borderRadius(28)
          .shadow(ShadowStyle.OUTER_DEFAULT_XS)

      })


    }
    .buttonList()
    .padding(12)
  }
}
