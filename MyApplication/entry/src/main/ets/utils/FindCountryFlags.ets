import { RecordItem, LedgerManager } from '../models/recordItemReference';
import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { variousToPreferred } from '../utils/moneyCount';
import { CachedRatesStatus, UserSetting } from "../models/userSetting"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { formatLargeNumber } from "../utils/formatLargeNumber"
import { recordDeleter } from "../utils/recordDeleter"

@ComponentV2
export struct findFlag {
  @Require @Param flagName: string

  build() {
    Column() {
      if (this.isImageExist(this.flagName)) {
        Image(this.getImageResource(this.flagName))
          .width(25)
      } else {
        Text('✕')
          .fontSize(30)
          .fontColor(Color.Red)
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private isImageExist(imageName: string): boolean {
    try {
      const resource = this.getImageResource(imageName)
      return resource !== undefined
    } catch (error) {
      return false
    }
  }

  private getImageResource(imageName: string): Resource {
    // 现在直接引用media目录下的图片
    return $r(`app.media.${imageName}`)
  }
}

let colorCache: Record<string, string> = {};

export function findColor(unit: string): string {
  const ledgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  const keys = ledgerManager.activeBook.chosenCurrency;

  if (colorCache[unit]) {
    return colorCache[unit];
  }

  colorCache = {};

  const total = keys.length;
  const saturation = 70;
  const lightness = 60;

  keys.forEach((key, index) => {
    const hue = Math.floor((index / total) * 360);
    colorCache[key] = hslToHex(hue, saturation, lightness);
  });

  return colorCache[unit];
}

// --- 工具函数：HSL -> HEX ---
function hslToHex(h: number, s: number, l: number): string {
  s /= 100;
  l /= 100;

  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l - c / 2;
  let r = 0, g = 0, b = 0;

  if (0 <= h && h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (60 <= h && h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (120 <= h && h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (180 <= h && h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (240 <= h && h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  const toHex = (v: number) =>
  Math.round((v + m) * 255)
    .toString(16)
    .padStart(2, '0');

  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}
