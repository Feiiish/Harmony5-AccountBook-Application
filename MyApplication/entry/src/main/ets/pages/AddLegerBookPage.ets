import { CustomContentDialog, TipsDialog } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager, LedgerBook } from '../models/recordItemReference';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { formatDateAdvanced } from '../utils/formatDateAdvanced';
import { sendableColorSpaceManager } from '@kit.ArkGraphics2D';
import { manager } from '@kit.NearLinkKit';

@Entry
@ComponentV2
export struct CustomDialogComponent {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local maxBook: number = 6
  @Local recordsData: RecordsData = this.ledgerManager.activeBook.data
  @Local inputNameValue: string = ''
  @Local isChecked: boolean = true;
  private dialogController: CustomDialogController | undefined = new CustomDialogController({
    builder: this.tipDialogBuilder,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss();
      }
      if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss();
      }
    },
    alignment: DialogAlignment.Center,
    autoCancel: true,
    cornerRadius: $r('sys.float.padding_level10')
  });

  @Builder
  tipDialogBuilder() {
    CustomContentDialog({
      contentBuilder: () => {
        this.buildContent()
      },
      buttons: [{
        value: '取消',
        action: () => {
          this.dialogController?.close();
        }
      }, {
        value: '确认',
        action: () => {
          this.onAccept();
          this.dialogController?.close();
        }
      }]
    })
  }

  @Builder
  buildContent(): void {
    Text('创建新账本').width("100%").padding(10).fontSize(24)
    TextInput({ placeholder: "输入账本名称" }).onChange((value: string) => {
      this.inputNameValue = value
    })
  }

  aboutToDisappear() {
    this.dialogController = undefined;
  }

  onAccept() {
    console.info('Callback when the second button is clicked');
    this.ledgerManager.addBook(this.inputNameValue)
  }

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('本地账本 ' + this.ledgerManager.books.length + "/6").fontWeight(FontWeight.Bold).fontSize(20)

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


          ForEach(this.ledgerManager.books, (book: LedgerBook) => {
            Column() {
              Stack() {
                Column() {
                  Column() {
                  }.height(6)

                  Row() {
                    Text(`账单数量: ${book.data.items.length}`)
                      .fontSize(14)
                      .margin({ top: 4, right: 6 })
                    Text(`计划数量: ${book.data.budgets.length}`)
                      .fontSize(14)
                      .margin({ top: 4 })
                  }

                  // 创建日期
                  Text(`创建日期: ${formatDateAdvanced(book.createdAt, "YYYY-MM-DD")}`)
                    .fontSize(14)
                    .margin({ top: 4 })

                }
                .justifyContent(FlexAlign.Center)
                .width('95%')
                .padding(12)
                .borderRadius(12)
                .backgroundColor(book.id === this.ledgerManager.activeBookId ? $r('app.color.Currency_Card_Main') :
                  $r('app.color.Currency_Card_1'))
                .opacity(0.5)
                .margin({ top: 44 })

                Column({ space: 10 }) {
                  // 账本名称
                  Row() {
                    Row() {
                      Image($r('app.media.agenda')).width(30).margin({ right: 12 })
                      Text(book.name)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .lineHeight(24)
                    }

                    Image($r('app.media.bin')).width(30)
                      .onClick(() => {

                        AlertDialog.show({
                          title: `删除账本 ${book.name}`,
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
                                this.ledgerManager.deleteBook(book.id)
                                console.log('执行删除操作');
                              }
                            },
                          ]
                        })

                      })
                  }.justifyContent(FlexAlign.SpaceBetween).width('100%')

                }
                .alignItems(HorizontalAlign.Start)
                .width('95%')
                .padding(12)
                .backgroundColor(book.id === this.ledgerManager.activeBookId ? $r('app.color.Currency_Card_Main') :
                  $r('app.color.Currency_Card_1'))
                .borderRadius(12)
                .shadow(ShadowStyle.OUTER_DEFAULT_XS)

                .onClick(() => {
                  if (book.id !== this.ledgerManager.activeBookId) {
                    AlertDialog.show({
                      title: '更换账本',
                      message: `是否将当前账本更换为 ${book.name}`,
                      primaryButton: {
                        value: '取消',
                        action: () => {

                        }
                      },
                      secondaryButton: {
                        value: '确认',
                        action: () => {
                          this.ledgerManager.switchBook(book.id);
                        }
                      }
                    });
                  }


                })

              }.alignContent(Alignment.Top)
            }.margin({ bottom: 30 }).width('90%').height('20%')

          })


          Button('添加账本')
            .buttonStyle(ButtonStyleMode.NORMAL)
            .margin({ bottom: 6 })
            .fontWeight(FontWeight.Medium)
            .fontSize($r('sys.float.Body_L'))
            .fontColor($r('sys.color.font_emphasize'))
            .opacity(this.ledgerManager.books.length < 6 ? 1 : 0.4)
            .onClick(() => {
              if (this.ledgerManager.books.length < 6) {
                this.dialogController?.open();
              } else {
                promptAction.showToast({ message: "本地账本已达到上限" });
              }

            })


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