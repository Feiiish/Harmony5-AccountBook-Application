/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { promptAction } from '@kit.ArkUI';
import { Constants } from './Constants';
import { TabContentConstants } from './TabContentConstants';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class Utils {
  public showPromptAction() {
    try {
      promptAction.showToast({
        message: "Some Message",
        duration: TabContentConstants.TAB_DURATION
      });
    } catch (error) {
     const err = error as BusinessError;
      hilog.error(0x0000, 'Utils', `showPromptAction catch err, code: ${err.code}, message: ${err.message}`);
    }
  }
}

export class BreakpointType<T> {
  private sm: T;
  private md: T;
  private lg: T;

  constructor(sm: T, md: T, lg: T) {
    this.sm = sm;
    this.md = md;
    this.lg = lg;
  }

  public getValue(currentBreakpoint: string): T {
    if (currentBreakpoint === Constants.BREAK_POINT_MD) {
      return this.md;
    }
    if (currentBreakpoint === Constants.BREAK_POINT_LG) {
      return this.lg;
    } else {
      return this.sm;
    }
  }
}