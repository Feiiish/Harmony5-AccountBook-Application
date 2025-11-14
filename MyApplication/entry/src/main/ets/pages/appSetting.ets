//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'
import { PromptAction } from '@kit.ArkUI'

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { findFlag, } from "../utils/FindCountryFlags"
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';
import { UserSetting } from "../models/userSetting"


@Styles
function basicCard() {
  .width("98%")
  .borderRadius(24)
  .margin({ top: 16 })
  .padding(12)
  .backgroundColor($r("app.color.Basic_Card_background"))
}

//规定普通title样式
@Extend(Text)
function secondTitle() {
  .fontSize(24)
  .margin({ bottom: 10 })
}


@CustomDialog
struct CurrencyPickerDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: CurrencyPickerDialog({})
  });
  currencies: string[] = [];

  build() {
    Column() {
      Text("请选择要添加的货币")
        .fontSize(22)
        .margin({ bottom: 12 })

      List({ space: 8 }) {
        ForEach(this.currencies, (currency: string) => {
          ListItem() {
            Text(currency)
              .fontSize(20)
              .padding(12)
              .backgroundColor("#f0f0f0")
              .borderRadius(8)
              .onClick(() => {
                this.controller.close(); // 关闭弹窗
              })
          }
        })
      }
      .height("60%") // 控制弹窗高度
      .scrollBar(BarState.On)
    }
    .padding(20)
    .backgroundColor("#ffffff")
    .borderRadius(16)
  }
}


@Entry
@ComponentV2
struct currencySettingPage {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  availableCurrencies: string[] = [
    '黑夜模式', 'App设置', 'wd', '1wwwwwwwwwww````````']
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;

  build() {
    List() {
      ListItem() {
        Column() {

          Row() {
            Text(`设置`).fontWeight(FontWeight.Bold).fontSize(20)

            Button({ type: ButtonType.Circle }) {
              Image($r('app.media.right_arrow')).width(24).height(24).margin({ left: 2 })
            }
            .width(40)
            .height(40)
            .backgroundColor($r('app.color.Basic_Card_background'))
            .onClick((event: ClickEvent) => {
              router.back()
            })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width("100%")
          .margin({ bottom: 12 })

          Column() {

            Row() {
              Text('收支总结')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.indexCompo.MonthlySummaryPanel })
                .onChange((statue) => {
                  this.userSetting.indexCompo.MonthlySummaryPanel = statue
                  console.log(this.userSetting.indexCompo.MonthlySummaryPanel + "Toggle 被触发");
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('预算面板')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.indexCompo.budgetComponent })
                .onChange((statue) => {
                  this.userSetting.indexCompo.budgetComponent = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('快捷按钮')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.indexCompo.menuList }).onChange((statue) => {
                this.userSetting.indexCompo.menuList = statue
              })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('周表')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.indexCompo.WeeklyChart }).onChange((statue) => {
                this.userSetting.indexCompo.WeeklyChart = statue
              })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('账单列表')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.indexCompo.searchBarView })
                .onChange((statue) => {
                  this.userSetting.indexCompo.searchBarView = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

          }.basicCard()

          Column() {

            Row() {
              Text('货币卡片')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.secondCompo.MultiCurrencyComposition })
                .onChange((statue) => {
                  this.userSetting.secondCompo.MultiCurrencyComposition = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)

            Row() {
              Text('日历')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.secondCompo.calendar })
                .onChange((statue) => {
                  this.userSetting.secondCompo.calendar = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

          }.basicCard()
        }.width("90%")
      }
    }
    .sticky(StickyStyle.Header)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .width("100%")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .alignListItem(ListItemAlign.Center)

  }
}