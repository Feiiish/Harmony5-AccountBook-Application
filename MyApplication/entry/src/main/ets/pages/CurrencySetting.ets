//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'
import { PromptAction } from '@kit.ArkUI'

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { findFlag, } from "../utils/FindCountryFlags"
import { RecordItem, RecordsData } from '../models/recordItemReference';

import { UserSetting } from "../models/userSetting"


@Styles
function basicCard() {
  .width('100%')

  .padding(16)
  .borderRadius(15)
  .margin({ bottom: 12 })
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
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'incomeExpenseRecords',
    () => new RecordsData()
  )!;
  @Local
  userSetting: UserSetting = PersistenceV2.connect(// 本地持久化用户设置
    UserSetting,
    "userSetting",
    () => new UserSetting()
  )!;
  availableCurrencies: string[] = [
    "USD", "CAD", "EUR", "GBP", "AUD", "JPY", "CNY", "INR", "KRW", "CHF",
    "BRL", "RUB", "MXN", "ZAR", "NGN", "SAR", "AED"]

  build() {
    List() {
      ListItem() {
        Column() {
          Text("货币设置")
            .fontWeight(FontWeight.Bold)
            .fontSize(24)
            .padding(10)


          Column() {
            Text("当前货币")
              .fontSize(20)
              .padding(10).width("100%")

            Grid() {
              ForEach(this.userSetting.chosenCurrency, (currency: string, index: number) => {
                GridItem() {

                  Row() {
                    Row() {
                      Text(currency)
                        .fontSize(20)
                        .padding(10)
                      findFlag({ flagName: currency })
                    }

                    if (
                      !this.recordsData.items.some((item: RecordItem) => item.unit === currency)
                        && this.userSetting.preferredCurrency !== currency
                    ) {
                      Image($r('app.media.bin')).height(30).width(30)
                        .onClick(() => {
                          this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
                            this.userSetting.chosenCurrency =
                              this.userSetting.chosenCurrency.filter(c => c !== currency);
                          });
                        }).margin({ right: 4 })

                    }
                  }
                  .width("45%")
                  .padding(6)
                  .borderRadius(12)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                  .backgroundColor(
                    currency === this.userSetting.preferredCurrency ? $r('app.color.Currency_Card_Main') :
                    $r('app.color.Currency_Card_1')
                  )
                  .margin({ bottom: 8 })
                  .transition(
                    TransitionEffect.asymmetric(
                      TransitionEffect.scale({ x: 0.9, y: 0.9 }),
                      TransitionEffect.IDENTITY
                    ).animation({ duration: 400, curve: Curve.FastOutSlowIn })
                  )


                  .onClick(() => {
                    if (currency !== this.userSetting.preferredCurrency) {
                      AlertDialog.show({
                        title: `提示`,
                        message: `是否将${currency} 设置为本位币`,
                        buttons: [
                          {
                            value: '取消',
                            action: () => {
                            }
                          },
                          {
                            value: '确认',
                            action: () => {
                              this.userSetting.preferredCurrency = currency
                              //refresh data
                            }
                          },
                        ]

                      })
                    }
                  })
                }
              })
            }
            .padding(12)
            .maxCount(2)
            .layoutDirection(GridDirection.Row)
            .columnsGap(12)

          }
          .backgroundColor($r("app.color.Basic_Card_background"))
          .width("90%")
          .borderRadius(12)
          .margin({ top: 16 })
          .padding(12)


          Column() {
            Text("添加货币")
              .fontSize(20)
              .padding(10).width("100%")


            Grid(new Scroller()) {
              ForEach(this.availableCurrencies.filter(currency =>
              !this.userSetting.chosenCurrency.includes(currency)
              ), (currency: string) => {
                GridItem() {
                  Row() {
                    Row() {
                      Text(currency)
                        .fontSize(20)
                        .padding(10)
                      findFlag({ flagName: currency })
                    }
                  }
                  .width("45%")
                  .padding(6)
                  .borderRadius(12)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .shadow(ShadowStyle.OUTER_DEFAULT_XS)
                  .backgroundColor($r('app.color.Currency_Card_1'))
                  .margin({ bottom: 8 })
                  .onClick(() => {

                    if (!this.userSetting.chosenCurrency.includes(currency)) {
                      this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
                        this.userSetting.chosenCurrency = [
                          ...this.userSetting.chosenCurrency,
                          currency
                        ];
                      });
                      promptAction.showToast({ message: `${currency} 已添加` });
                    }
                  })
                }
              })
            }
            .padding(12)
            .maxCount(2)
            .layoutDirection(GridDirection.Row)
            .columnsGap(12)

          }
          .basicCard()
          .width("90%")
          .borderRadius(12)
          .margin({ top: 16 })
          .padding(12)
          .backgroundColor($r("app.color.Basic_Card_background"))

        }
      }
    }
    .sticky(StickyStyle.Header)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .height("100%")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .alignListItem(ListItemAlign.Center)

  }
}