import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../../models/recordItemReference"
import { UserSetting } from "../../models/userSetting"
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { authentication } from '@kit.AccountKit';

import { util } from '@kit.ArkTS';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { request } from '@kit.BasicServicesKit';
import auth from '@hw-agconnect/auth';

@ComponentV2
export struct avatarControl {
  @Local isLoggedIn: boolean = false;
  @Local UnionID: string = '';
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;

  public async checkLoginStatus(): Promise<boolean> {
    const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['profile']; // 获取头像和昵称
    authRequest.permissions = ['serviceauthcode']; // 获取 authorizationCode（服务端用）
    authRequest.forceAuthorization = false; // 不强制弹出授权页面，适合静默检查
    authRequest.state = util.generateRandomUUID();

    const controller = new authentication.AuthenticationController(this.getUIContext().getHostContext());

    try {
      const data = await controller.executeRequest(authRequest);
      const response = data as authentication.AuthorizationWithHuaweiIDResponse;

      const avatarUri = response?.data?.avatarUri;
      const nickName = response?.data?.nickName;
      const authorizationCode = response?.data?.authorizationCode;

      console.log("头像:", avatarUri);
      console.log("昵称:", nickName);
      console.log("authCode:", authorizationCode);
      this.UnionID = response.data?.unionID!
      this.userSetting.profile = avatarUri;
      this.userSetting.nickName = nickName;
      this.isLoggedIn = true
      // 如果拿到了昵称或头像，认为已登录
      return !!nickName || !!avatarUri;
    } catch (error) {
      this.dealAllError(error as BusinessError);
      this.isLoggedIn = false
      return false;
    }
  }

  aboutToAppear(): void {
    this.checkLoginStatus().then((res) => {
    }
    )
  }

  build() {
    Column() {
      if (!this.userSetting.profile) {
        Circle()
          .width(80)
          .height(80)
          .fill(Color.Gray)
      } else {
        Image(this.userSetting.profile)
          .width(80)
          .backgroundColor(Color.Gray)
          .borderRadius(150)

      }

      if (!this.userSetting.nickName) {
        Text('未登录').padding({ top: 15 })
      } else {
        Text(this.userSetting.nickName).padding({ top: 15 })
      }
    }
    .onClick(() => {
      router.pushUrl({
        url: "pages/HuaweiLogin"
      }, router.RouterMode.Standard, (err) => {
        if (err) {
          console.log("跳转失败:", err)
        }
      })
    })
    .justifyContent(FlexAlign.Center)
    .height(130)
    .width("40%")

  }

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