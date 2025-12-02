//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'
import { PromptAction } from '@kit.ArkUI'

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { findFlag, } from "../utils/FindCountryFlags"
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';
import { UserSetting } from "../models/userSetting"
import { ConfigurationConstant } from '@kit.AbilityKit';
import {
  TabSegmentButtonV2,
  CapsuleSegmentButtonV2,
  MultiCapsuleSegmentButtonV2,
  SegmentButtonV2Items
} from '@kit.ArkUI';

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
struct appSetting {
  @Local isShowSheet: boolean = false;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local selectedIndex: number = 0;
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;
  context = getContext();
  @Local textItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '系统' },
    { text: '亮色' },
    { text: '暗色' },
  ]);

  @Builder
  mySheet() {
    Column() {
      Row() {
        Text($r('app.string.app_version'))
          .fontWeight(FontWeight.Bold)
          .margin({ right: 12 })
          .fontSize(22)
      }
      .width('100%')
      .margin({ top: 25 })

      Column({ space: 12 }) {
        Text('本次更新重新设计了添加记录页面.')
        Text('本次更新添加了设置中的主页布局. 用户可以关闭主页中的一些组件.')
        Text('本次更新添加了用户指南和联系作者页面.')
        Text('修复了一些已知Bug. 优化了用户体验.')
      }.alignItems(HorizontalAlign.Start)

    }
    .width('75%')
    .alignItems(HorizontalAlign.Start)
  }

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
              Text('主题')
              CapsuleSegmentButtonV2({
                items: this.textItems,
                selectedIndex: this.userSetting.darkMode,
                $selectedIndex: (index: number) => {
                  this.userSetting.darkMode = index;

                  if (index === 0) {
                    this.context.getApplicationContext()

                      .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

                  } else if (index === 1) {
                    this.context.getApplicationContext()
                      .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
                  } else {
                    this.context.getApplicationContext()
                      .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

                  }

                }

              }).width("50%")
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')
          }.basicCard()

          //main page components
          Column() {
            Text('主页布局')
            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('收支总结')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.MonthlySummaryPanel })
                .onChange((statue) => {
                  this.userSetting.MonthlySummaryPanel = statue
                  console.log(this.userSetting.MonthlySummaryPanel + "Toggle 被触发");
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('预算面板')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.budgetComponent })
                .onChange((statue) => {
                  this.userSetting.budgetComponent = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('快捷按钮')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.menuList }).onChange((statue) => {
                this.userSetting.menuList = statue
              })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

          }.basicCard()

          /*
          //second page components
          Column() {
            Text('副页布局')
            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('货币卡片')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.MultiCurrencyComposition })
                .onChange((statue) => {
                  this.userSetting.MultiCurrencyComposition = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)

            Row() {
              Text('日历')
              Toggle({ type: ToggleType.Switch, isOn: this.userSetting.calendar })
                .onChange((statue) => {
                  this.userSetting.calendar = statue
                })
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

          }.basicCard()
          * */

          //about this app
          Column() {
            Row() {
              Text('隐私政策')
              Text('❯')
                .fontSize(14)
                .fontColor('#999999')
            }.justifyContent(FlexAlign.SpaceBetween).width('100%').onClick(() => {
              router.pushUrl({
                url: "pages/AboutThisApp"
              }, router.RouterMode.Standard, (err) => {
                if (err) {
                  console.log("跳转失败:", err)
                }
              })
            })

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)

            Row() {
              Text('版本信息')
              Row({ space: 6 }) {
                Text($r('app.string.app_version'))
                  .fontSize(16)
                  .fontColor('#999999')
                Text('❯')
                  .fontSize(14)
                  .fontColor('#999999')
              }

            }.justifyContent(FlexAlign.SpaceBetween).width('100%')
            .onClick(() => {
              this.isShowSheet = true;

            })
            .bindSheet(this.isShowSheet, this.mySheet(), {
              height: 360,
              onWillDisappear: () => {
                this.isShowSheet = false;
              }
            })


            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)

            Row() {
              Text('使用指南')
              Text('❯')
                .fontSize(14)
                .fontColor('#999999')
            }.justifyContent(FlexAlign.SpaceBetween).width('100%').onClick(() => {
              router.pushUrl({
                url: "pages/userGuide"
              }, router.RouterMode.Standard, (err) => {
                if (err) {
                  console.log("跳转失败:", err)
                }
              })
            })

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('电子版权号')
              Text('软著认000371952号')
                .fontSize(14)
                .fontColor('#999999')
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