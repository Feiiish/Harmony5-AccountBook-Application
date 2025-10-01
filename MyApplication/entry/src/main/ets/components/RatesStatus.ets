import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';
import { UserSetting, CachedRatesStatus } from "../models/userSetting"
import { text } from '@kit.ArkGraphics2D';
import { updateExchangeRates } from "../utils/currencyExchange"

// 将样式定义移动到组件外部
@Styles
function basicCard() {
  .width('100%')
  .padding(16)
  .borderRadius(15)
  .margin({ bottom: 12 })
  .backgroundColor($r("app.color.Basic_Card_background"))
}

@ComponentV2
export struct ratesStatus {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local currentTime: number = Date.now()
  @Local timerId: number = 0 // 存储定时器ID
  @Local
  cachedRatesStorage: CachedRatesStatus = PersistenceV2.connect(// 本地持久化用户设置
    CachedRatesStatus,
    "cachedRatesStatus",
    () => new CachedRatesStatus()
  )!;

  // 组件挂载时启动定时器
  aboutToAppear() {
    updateExchangeRates(this.ledgerManager.activeBook.preferredCurrency)
    this.timerId = setInterval(() => {
      this.currentTime = Date.now() // 更新当前时间
    }, 60000) // 每分钟更新一次
  }

  // 组件卸载时清除定时器
  aboutToDisappear() {
    if (this.timerId) {
      clearInterval(this.timerId)
    }
  }

  // 修复时间差计算，确保使用UTC时间避免时区问题
  private getTimeDiffMinutes(): number {
    if (!this.cachedRatesStorage.lastUpdateTime) {
      return Number.MAX_SAFE_INTEGER; // 返回极大值表示无数据
    }

    const lastUpdate = new Date(this.cachedRatesStorage.lastUpdateTime).getTime();
    const diffMinutes = Math.floor((this.currentTime - lastUpdate) / 60000);
    if (diffMinutes >= 20) {
      updateExchangeRates(this.ledgerManager.activeBook.preferredCurrency);
      this.currentTime = Date.now();
    }
    return diffMinutes;
  }

  build() {
    // 使用Column作为根组件，应用样式
    Row() {
      if (!this.cachedRatesStorage.lastUpdateTime) {
        Text("暂无汇率数据")
          .fontSize(14)
          .fontColor(Color.Gray)
      } else {

        if (this.getTimeDiffMinutes() < 20) {

          Text("汇率正常")
            .fontSize(14)
            .fontColor("#00B300")
        } else if (this.getTimeDiffMinutes() >= 20 && this.getTimeDiffMinutes() < 1440) {

          // 小于24小时显示分钟
          Text(`汇率滞后${this.getTimeDiffMinutes()}分钟`)
            .fontSize(14)
            .fontColor(Color.Yellow)
        } else {
          // 大于24小时显示天数
          Text(`汇率滞后${Math.floor(this.getTimeDiffMinutes() / 1440)}天`)
            .fontSize(14)
            .fontColor(Color.Red)
        }
      }
      /*
            Image($r('app.media.refresh'))
              .onClick(() => {
                updateExchangeRates(this.userSetting.preferredCurrency)
                this.currentTime = Date.now();
              }).height(28).margin({ left: 4 })
      */
    }
    .width("100%")
    .justifyContent(FlexAlign.Center)

  }
}