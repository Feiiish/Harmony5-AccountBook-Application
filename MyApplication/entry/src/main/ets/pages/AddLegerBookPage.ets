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
    Column() {
      Column() {

        Text('我的账本 ' + this.ledgerManager.books.length + "/3")
          .fontWeight(FontWeight.Bold)
          .fontSize(24)
          .padding(10)


        ForEach(this.ledgerManager.books, (book: LedgerBook) => {
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
                    title: `要删除账本吗`,
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
          .alignItems(HorizontalAlign.Start)
          .width('80%')
          .padding(12)
          .backgroundColor(book.id === this.ledgerManager.activeBookId ? $r('app.color.Currency_Card_Main') :
          $r('app.color.Currency_Card_1'))
          .borderRadius(12)
          .shadow(ShadowStyle.OUTER_DEFAULT_XS)
          .margin({ bottom: 12 })
          .onClick(() => {
            this.ledgerManager.switchBook(book.id);
          })
        })


        Button('创建新账本')
          .buttonStyle(ButtonStyleMode.NORMAL)
          .margin({ bottom: 6 })
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_emphasize'))
          .opacity(this.ledgerManager.books.length < 3 ? 1 : 0.4)
          .onClick(() => {
            if (this.ledgerManager.books.length < 3) {
              this.dialogController?.open();
            }

          })

      }.backgroundColor($r('app.color.Basic_Card_background'))
      .borderRadius(15)
      .width('90%')
      .padding(12)

    }
    .width('100%')
  }
}