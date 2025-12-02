import App from "@system.app";
import { RecordItem, RecordsData } from "../../models/recordItemReference"

import { variousToPreferred } from "../../utils/moneyCount"
import { PersistenceV2, promptAction, router, CapsuleSegmentButtonV2 } from '@kit.ArkUI';
import { displayExchangeRates } from '../../utils/currencyExchange';
import { SegmentButtonV2Items, TabSegmentButtonV2 } from '@kit.ArkUI';
import { McLineChart, Options } from '@mcui/mccharts'
import { TipsDialog } from '@kit.ArkUI';
import { UserSetting } from "../../models/userSetting"

@Styles
function basicChart() {
  .margin({ bottom: 12 })
  .width('100%')
  .padding(16)
  .borderRadius(15)
  .backgroundColor($r("app.color.Basic_Card_background"))
}


@ComponentV2
export struct welcomeDialogue {
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;
  private dialogController: CustomDialogController | undefined = new CustomDialogController({
    builder: this.tipDialogBuilder,
    cancel: this.existApp,
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

  public triggerDialogue() {
    this.dialogController?.open();
  }

  @Builder
  tipDialogBuilder() {
    TipsDialog({
      // 替换自己项目src/main/resources/base/media下的资源图片
      imageRes: $r('app.media.mainPage'),
      imageSize: {
        width: 'auto',
        height: 180
      },
      title: '欢迎使用全球账本',
      content: '本App是多货币记账软件 \n请点击下方导航栏加号按钮添加账单',
      isChecked: this.userSetting.welcomeDialogue,
      checkTips: '我已知晓上述内容，不再提醒',
      onCheckedChange: () => {
        this.userSetting.welcomeDialogue = !this.userSetting.welcomeDialogue;
      },
      primaryButton: {
        value: '取消',
        action: () => {
          this.onCancel();
          this.dialogController?.close();
          console.info('Callback when the first button is clicked');
        },
      },
      secondaryButton: {
        value: '确认',
        action: () => {
          this.onAccept();
          this.dialogController?.close();
          console.info('Callback when the second button is clicked');
        }
      }
    })
  }

  aboutToDisappear() {
    this.dialogController = undefined;
  }

  onCancel() {
    console.info('Callback when the first button is clicked');
  }

  onAccept() {
    console.info('Callback when the second button is clicked');
  }

  existApp() {
    console.info('Click the callback in the blank area');
  }

  build() {
    Column() {
      Button('自定义图文弹窗')
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


@ComponentV2
export struct addRecordPage {
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;
  private dialogController: CustomDialogController | undefined = new CustomDialogController({
    builder: this.tipDialogBuilder,
    cancel: this.existApp,
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

  public triggerDialogue() {
    this.dialogController?.open();
  }

  @Builder
  tipDialogBuilder() {
    TipsDialog({
      // 替换自己项目src/main/resources/base/media下的资源图片
      imageRes: $r('app.media.addRecord'),
      imageSize: {
        width: 'auto',
        height: 180,

      },
      title: '添加账单',
      content: '输入正数为收入, 输入负数为支出 \n点击货币栏改变货币单位.',
      isChecked: this.userSetting.welcomeDialogue,
      checkTips: '我已知晓上述内容，不再提醒',
      onCheckedChange: () => {
        this.userSetting.welcomeDialogue = !this.userSetting.welcomeDialogue;
      },
      primaryButton: {
        value: '取消',
        action: () => {
          this.onCancel();
          this.dialogController?.close();
          console.info('Callback when the first button is clicked');
        },
      },
      secondaryButton: {
        value: '确认',
        action: () => {
          this.onAccept();
          this.dialogController?.close();
          console.info('Callback when the second button is clicked');
        }
      }
    })
  }

  aboutToDisappear() {
    this.dialogController = undefined;
  }

  onCancel() {
    console.info('Callback when the first button is clicked');
  }

  onAccept() {
    console.info('Callback when the second button is clicked');
  }

  existApp() {
    console.info('Click the callback in the blank area');
  }

  build() {
    Column() {
      Button('自定义图文弹窗')
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