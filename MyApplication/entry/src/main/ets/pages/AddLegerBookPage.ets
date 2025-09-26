import { CustomContentDialog, TipsDialog } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';

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
      Button('创建新账本')
        .buttonStyle(ButtonStyleMode.NORMAL)
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.Body_L'))
        .fontColor($r('sys.color.font_emphasize'))
        .onClick(() => {
          this.dialogController?.open();
        })
    }
    .width('100%')
  }
}