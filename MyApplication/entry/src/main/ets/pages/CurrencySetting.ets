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
  .width('100%')
  .padding(12)
  .backgroundColor($r("app.color.Basic_Card_background"))
  .borderRadius(24)
  .margin({ bottom: 12 })

}

@Styles
function basicRow() {
  .height(45)
  .width("100%")
  .padding(6)
  .borderRadius(12)
  .shadow(ShadowStyle.OUTER_DEFAULT_XS)
  .backgroundColor($r('app.color.Currency_Card_1'))
  .margin({ bottom: 8 })

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


@Preview
@Entry
@ComponentV2
struct currencySettingPage {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local showAllCurrencies: boolean = false
  @Local showAllAvailableCurrencies: boolean = false
  availableCurrencies: string[] = [
    "USD", "CAD", "EUR", "GBP", "AUD", "JPY", "CNY", "INR", "KRW", "CHF",
    "BRL", "RUB", "MXN", "ZAR", "NGN", "SAR", "AED", "TWD", "HKD", 'SGD', 'NZD', 'SEK', 'NOK', 'DKK', 'THB',
    'MYR', 'IDR', 'PHP', 'PLN', 'TRY', 'ILS', 'EGP', 'VND',
    'UAH', 'ARS', 'CLP', 'COP'
  ]

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text(`货币设置`).fontWeight(FontWeight.Bold).fontSize(20)

            Button({ type: ButtonType.Circle }) {
              Image($r('app.media.right_arrow')).width(24).height(24).margin({ left: 2 })
            }
            .width(40)
            .height(40)
            .backgroundColor($r('app.color.Basic_Card_background'))
            .onClick(() => {
              router.back()
            })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width("100%")
          .margin({ bottom: 12 })

          Column() {
            Row() {
              Text('只显示货币代码')
              Text('开关')
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')

            Divider().margin({ top: 8, bottom: 8 }).color(Color.Gray)
            Row() {
              Text('只显示货币代码')
              Text('开关')
            }.justifyContent(FlexAlign.SpaceBetween).width('100%')
          }
          .basicCard()

          Column() {
            Text("当前货币")
              .fontSize(20)
              .padding(10).width("100%")
            Grid() {
              ForEach(
                this.showAllCurrencies
                  ? this.ledgerManager.activeBook.chosenCurrency
                  : this.ledgerManager.activeBook.chosenCurrency.slice(0, 5),
                (currency: string, index: number) => {
                  GridItem() {
                    Row() {
                      Row() {
                        Text($r(`app.string.${currency}`))
                          .fontSize(20)
                          .margin({ right: 6 })

                        Text(currency)
                          .fontSize(20)
                          .margin({ right: 6 })
                        findFlag({ flagName: currency })
                      }

                      if (
                        !this.ledgerManager.activeBook.data.items.some((item: RecordItem) => item.unit === currency)
                          && this.ledgerManager.activeBook.preferredCurrency !== currency
                      ) {
                        Image($r('app.media.bin')).height(30).width(30)
                          .onClick(() => {
                            this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
                              this.ledgerManager.activeBook.chosenCurrency =
                                this.ledgerManager.activeBook.chosenCurrency.filter(c => c !== currency);
                            });
                          }).margin({ left: 8 })
                      }
                    }
                    .basicRow()
                    .justifyContent(FlexAlign.SpaceBetween)
                    .backgroundColor(
                      currency === this.ledgerManager.activeBook.preferredCurrency ?
                        $r('app.color.Currency_Card_Main') :
                        $r('app.color.Currency_Card_1')
                    )
                    .transition(
                      TransitionEffect.asymmetric(
                        TransitionEffect.scale({ x: 0.9, y: 0.9 }),
                        TransitionEffect.IDENTITY
                      ).animation({ duration: 400, curve: Curve.FastOutSlowIn })
                    )
                    .onClick(() => {
                      if (currency !== this.ledgerManager.activeBook.preferredCurrency) {
                        AlertDialog.show({
                          title: `提示`,
                          message: `是否将${currency} 设置为本位币`,
                          buttons: [
                            {
                              value: '取消', action: () => {
                            }
                            },
                            {
                              value: '确认',
                              action: () => {
                                this.ledgerManager.activeBook.preferredCurrency = currency
                              }
                            },
                          ]
                        })
                      }
                    })
                  }
                }
              )
            }
            .padding(2)
            .maxCount(1)
            .layoutDirection(GridDirection.Row)
            .columnsGap(12)

            // 展开/折叠按钮
            if (this.ledgerManager.activeBook.chosenCurrency.length > 5) {
              Button(this.showAllCurrencies ? '折叠' : '···')
                .fontSize(18)
                .backgroundColor(Color.Gray)
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  this.showAllCurrencies = !this.showAllCurrencies;
                })
            }

          }
          .basicCard()


          Column() {
            Text("添加货币")
              .fontSize(20)
              .padding(10).width("100%")
            Grid(new Scroller()) {
              ForEach(
                this.showAllAvailableCurrencies
                  ? this.availableCurrencies.filter(currency =>
                !this.ledgerManager.activeBook.chosenCurrency.includes(currency)
                )
                  : this.availableCurrencies.filter(currency =>
                !this.ledgerManager.activeBook.chosenCurrency.includes(currency)
                ).slice(0, 5),
                (currency: string) => {
                  GridItem() {
                    Row() {
                      Row() {
                        Text($r(`app.string.${currency}`))
                          .fontSize(20)
                          .margin({ right: 6 })

                        Text(currency)
                          .fontSize(20)
                          .margin({ right: 6 })
                        findFlag({ flagName: currency })
                      }
                    }
                    .basicRow()
                    .justifyContent(FlexAlign.SpaceBetween)
                    .onClick(() => {
                      if (!this.ledgerManager.activeBook.chosenCurrency.includes(currency)) {
                        this.getUIContext()?.animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
                          this.ledgerManager.activeBook.chosenCurrency = [
                            ...this.ledgerManager.activeBook.chosenCurrency,
                            currency
                          ];
                        });
                        promptAction.showToast({ message: `${currency} 已添加` });
                      }
                    })
                  }
                }
              )
            }
            .padding(2)
            .maxCount(1)
            .layoutDirection(GridDirection.Row)
            .columnsGap(12)

            // 展开/折叠按钮
            if (
              this.availableCurrencies.filter(currency =>
              !this.ledgerManager.activeBook.chosenCurrency.includes(currency)
              ).length > 5
            ) {
              Button(this.showAllAvailableCurrencies ? '折叠' : '···')
                .fontSize(18)
                .backgroundColor(Color.Gray)
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  this.showAllAvailableCurrencies = !this.showAllAvailableCurrencies;
                })
            }
          }
          .basicCard()

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
