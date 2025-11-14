import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { authentication } from '@kit.AccountKit';
import { UserSetting } from "../models/userSetting"
import { avatarControl } from "../components/buttons/avatarControl"
import { util } from '@kit.ArkTS';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { request } from '@kit.BasicServicesKit';

import auth from '@hw-agconnect/auth';

@Entry
@ComponentV2
export struct PreviewLoginButtonPage {
  @Local isLoggedIn: boolean = false
  @Local readyToShow: boolean = false;
  @Local avatar: avatarControl = new avatarControl
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.dealAllError(error);
          return;
        }
        if (response) {
          console.log("登录成功");
          hilog.info(0x0000, 'testTag', '成功获取响应。');
          auth.signIn({
            autoCreateUser: true,
            "credentialInfo": {
              "kind": 'hwid'
            }
          })
          const authCode = response.authorizationCode;
          const openID = response.openID

          //Open ID, Union ID, authCode
          // 开发者处理authCode

          const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
          authRequest.scopes = ['profile']; // 获取头像和昵称
          authRequest.permissions = ['serviceauthcode']; // 获取 authorizationCode（服务端用）
          authRequest.forceAuthorization = true;
          authRequest.state = util.generateRandomUUID();

          const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());
          controller.executeRequest(authRequest).then((data) => {
            const response = data as authentication.AuthorizationWithHuaweiIDResponse;
            const avatarUri = response?.data?.avatarUri;
            const nickName = response?.data?.nickName;
            const authorizationCode = response?.data?.authorizationCode;

            console.log("头像:", avatarUri);
            console.log("昵称:", nickName);
            console.log("authCode:", authorizationCode);
            this.userSetting.profile = avatarUri
            this.userSetting.nickName = nickName
            router.back()
            promptAction.showToast({ message: '登录成功' });
          }).catch((error: BusinessError) => {
            this.dealAllError(error);
          });

          promptAction.showToast({ message: '拉起授权弹窗中, 请稍后' });

        }

      });

  // 错误处理
  dealAllError(error: BusinessError): void {
    hilog.error(0x0000, 'testTag',
      `登录失败，错误码: ${error.code}, 错误信息: ${error.message}`);
    if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
      // 用户未登录华为账号，请登录华为账号并重试
    } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
      // 网络异常，请检查网络状态并重试
    } else if (error.code === ErrorCode.ERROR_CODE_INTERNAL_ERROR) {
      // 登录失败，请尝试其他登录方式
    } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
      // 用户取消授权
    } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
      // 系统服务异常，请稍后重试
    } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
      // 重复请求，应用无需处理
    } else if (error.code === ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED) {
      // 用户未同意协议
    } else {
      // 登录失败，请尝试其他登录方式
    }
  }

  aboutToAppear(): void {

    this.avatar.checkLoginStatus().then((res) => {
      this.isLoggedIn = res
      this.readyToShow = true
    })

  }

  build() {
    Column() {
      Column() {
        Column() {
          if (this.readyToShow) {
            if (this.isLoggedIn) {
              Column() {
                Row() {
                  Text('账号详情').fontWeight(FontWeight.Bold).fontSize(20)

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
                }.height('20%')

                Column() {
                  //user info
                  Image(this.userSetting.profile).width(80).margin({ bottom: 20 }).borderRadius(44)
                  Column() {
                    Row() {
                      Text(`用户名`)
                      Text(`${this.userSetting.nickName}`).fontSize(15)
                    }.width('90%').justifyContent(FlexAlign.SpaceBetween)
                    .margin({ bottom: 8 })

                    Column() {
                      Text("唯一标识符")
                      Text(`${this.avatar.UnionID}`).fontSize(10)
                    }.alignItems(HorizontalAlign.Start).width('90%')

                  }
                  .backgroundColor($r('app.color.Basic_Card_background'))
                  .width('90%')
                  .padding(12)
                  .borderRadius(14)
                  .margin({ bottom: 40 })
                }

                //logoutButton
                Button('退出登录')
                  .width("90%")
                  .onClick((event: ClickEvent) => {
                    auth.signOut()

                    promptAction.showToast({ message: '正在退出登录' });
                    const controller =
                      new authentication.AuthenticationController(this.getUIContext().getHostContext());
                    const authRequest = new authentication.HuaweiIDProvider().createCancelAuthorizationRequest();
                    controller.executeRequest(authRequest).then((data) => {
                      this.userSetting.profile = ''
                      this.userSetting.nickName = ''
                      router.back()
                      promptAction.showToast({ message: '退出成功' });
                    })

                  })
              }.height('100%')

            } else {
              Column() {
                Row() {
                  Text('登录').fontWeight(FontWeight.Bold).fontSize(20)

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
                }.height('20%')

                Column() {
                  Image($r('app.media.startIcon')).width(80).borderRadius(20).margin({ bottom: 20 })
                  Text($r('app.string.EntryAbility_label')).fontSize(20)
                }.height(250)


                //huaweiLoginButton
                Column() {
                  LoginWithHuaweiIDButton({
                    params: {
                      style: loginComponentManager.Style.BUTTON_RED,
                      extraStyle: {
                        buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                          show: true
                        })
                      },
                      borderRadius: 24,
                      loginType: loginComponentManager.LoginType.ID,
                      supportDarkMode: true
                    },
                    controller: this.controller,
                  })
                }
                .height(40)
              }.height('100%')
            }
          } else {
            Text('加载中')
          }


        }.justifyContent(FlexAlign.Center).width("90%").height("100%")

      }.width('100%')
    }
    .justifyContent(FlexAlign.Center)
    .constraintSize({ minHeight: '100%' })
    .margin({
      left: 16,
      right: 16
    })
  }
}

export enum ErrorCode {
  // 账号未登录
  ERROR_CODE_LOGIN_OUT = 1001502001,
  // 网络错误
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  // 内部错误
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  // 用户取消授权
  ERROR_CODE_USER_CANCEL = 1001502012,
  // 系统服务异常
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  // 重复请求
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  // 用户未同意用户协议
  ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001
}