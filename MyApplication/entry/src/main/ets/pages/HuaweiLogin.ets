import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct PreviewLoginButtonPage {
  // 构造LoginWithHuaweiIDButton组件的控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.dealAllError(error);
          return;
        }

        if (response) {
          console.log("success");
          hilog.info(0x0000, 'testTag', 'Succeeded in getting response.');
          const authCode = response.authorizationCode;
          // 开发者处理authCode
        }
      });

  // 错误处理
  dealAllError(error: BusinessError): void {
    hilog.error(0x0000, 'testTag',
      `Failed to login, errorCode is ${error.code}, errorMessage is ${error.message}`);
    // 在应用登录涉及UI交互场景下，建议按照如下错误码指导提示用户
    if (error.code === ErrorCode.ERROR_CODE_LOGIN_OUT) {
      // 用户未登录华为账号，请登录华为账号并重试或者尝试使用其他方式登录
    } else if (error.code === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
      // 网络异常，请检查当前网络状态并重试或者尝试使用其他方式登录
    } else if (error.code === ErrorCode.ERROR_CODE_INTERNAL_ERROR) {
      // 登录失败，请尝试使用其他方式登录
    } else if (error.code === ErrorCode.ERROR_CODE_USER_CANCEL) {
      // 用户取消授权
    } else if (error.code === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
      // 系统服务异常，请稍后重试或者尝试使用其他方式登录
    } else if (error.code === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
      // 重复请求，应用无需处理
    } else if (error.code === ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED) {
      // 用户未同意协议
    } else {
      // 应用登录失败，请尝试使用其他方式登录
    }
  }

  build() {
    Column() {
      Column() {
        Column() {
          LoginWithHuaweiIDButton({
            params: {
              // LoginWithHuaweiIDButton支持的样式
              style: loginComponentManager.Style.BUTTON_RED,
              // 账号登录按钮在登录过程中展示加载态
              extraStyle: {
                buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                  show: true
                })
              },
              // LoginWithHuaweiIDButton的边框圆角半径
              borderRadius: 24,
              // LoginWithHuaweiIDButton支持的登录类型
              loginType: loginComponentManager.LoginType.ID,
              // LoginWithHuaweiIDButton支持按钮的样式跟随系统深浅色模式切换
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