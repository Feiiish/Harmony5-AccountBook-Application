import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { authentication } from '@kit.AccountKit';
import { UserSetting } from "../models/userSetting"
import { util } from '@kit.ArkTS';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { request } from '@kit.BasicServicesKit';
import auth from '@hw-agconnect/auth';


@Entry
@Component
struct PreviewLoginButtonPage {
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
          this.getProfile()
          const authCode = response.authorizationCode;
          const openID = response.openID
          //Open ID, Union ID, authCode
          // 开发者处理authCode
        }

      });

  public getProfile() {
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
      this.userSetting.profile = avatarUri;
      this.userSetting.nickName = nickName;

    }).catch((error: BusinessError) => {
      this.dealAllError(error);
    });
  }

  aboutToAppear(): void {
    auth.signIn({
      autoCreateUser: true,
      "credentialInfo": {
        "kind": 'hwid'
      }
    }).then(signInResult => {
      hilog.info(0x0000, 'testTag', '%{public}s', `signInHwid success. result: ${signInResult.getUser().getUid()}`);
    })
      .catch((error: BusinessError) => {
        hilog.error(0x0000, 'testTag', '%{public}s',
          `signInHwid error, Code: ${error.code}, message: ${error.message}`);
      })
  }

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

  build() {
    Column() {
      Column() {
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
            controller: this.controller
          })
        }
        .height(40)
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