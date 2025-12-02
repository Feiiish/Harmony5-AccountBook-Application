import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import auth from '@hw-agconnect/auth';
import { buffer } from '@kit.ArkTS';
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { authentication } from '@kit.AccountKit';
import { UserSetting } from "../models/userSetting"
import { util } from '@kit.ArkTS';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { request } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;


export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {


    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    let file = this.context.resourceManager.getRawFileContentSync('agconnect-services.json');
    let json: string = buffer.from(file.buffer).toString();
    auth.init(this.context, json);


  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }

      let usersetting = PersistenceV2.connect(UserSetting, 'userSetting', () => new UserSetting());
      if (usersetting?.darkMode === 0) {
        this.context.getApplicationContext()

          .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

      } else if (usersetting?.darkMode === 1) {
        this.context.getApplicationContext()
          .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      } else {
        this.context.getApplicationContext()
          .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });

    //this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)


  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      AppStorage.setOrCreate("isDarkMode", true);
    } else {
      AppStorage.setOrCreate('isDarkMode', false);
    }

  }
}