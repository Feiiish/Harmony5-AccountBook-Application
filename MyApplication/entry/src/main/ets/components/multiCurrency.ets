import { UserSetting } from "../models/userSetting"

import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, singleCurrency } from '../models/recordItemReference';
import { displayExchangeRates } from '../utils/currencyExchange';
import { calculateEachAmount } from '../utils/moneyCount';
import { findFlag } from '../utils/FindCountryFlags';


// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});

const RECORDS_DATA_KEY = 'incomeExpenseRecords';

//规定普通Row样式
@Extend(Row)
function currencyCard() {
  .justifyContent(FlexAlign.Start)
  .width("28%")
  .padding(4)
  //.backgroundColor(Color.Red)
}

@Styles
function basicCard() {
  .width('100%')

  .padding(16)
  .borderRadius(15)
  .margin({ bottom: 12 })
  .backgroundColor("#EFEFEF")
}

@ComponentV2
export struct MultiCurrencyComposition {
  @Require @Param recordList: RecordItem[]; // 必需传入的账单数据

  //catching the change
  @Local private internalRecordList: RecordItem[] = [];
  @Local private updateTrigger: number = 0;
  @Monitor("internalRecordList")
  onRecordListChange(monitor: IMonitor) {
    monitor.dirty.forEach((path: string) => {
      console.log(`RecordList changed at path: ${path}`);
      this.refreshData();
    });
  }
  @Monitor("updateTrigger")
  onTriggerChange(monitor: IMonitor) {
    this.refreshData();
  }

  @Local
  userSetting: UserSetting = PersistenceV2.connect(// 本地持久化用户设置
    UserSetting,
    "userSetting",
    () => new UserSetting()
  )!;

  @Local
  currencyAmounts: singleCurrency[] = []; // 货币金额数组
  @Local
  isLoading: boolean = true; // 加载状态
  @Local
  errorMessage: string = ""; // 错误信息
  @Local DEBUG: boolean = true;

  aboutToAppear() {
    this.internalRecordList = [...this.recordList];
    this.refreshData();

    // 设置定时器自动更新（可选）
    setInterval(() => {
      this.updateTrigger++; // 改变状态触发刷新
    }, 1000);
  }

  private async refreshData() {
    if (this.DEBUG) console.log('Refreshing currency data...');
    this.isLoading = true;

    try {
      await this.initializeCurrencies();
      await this.calculateCurrencyAmounts();
    } catch (error) {
      this.errorMessage = error.message;
      console.error('Refresh failed:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 初始化货币设置（去重+确保包含首选货币）
  private initializeCurrencies() {
    const currencies = new Set([
      ...this.userSetting.chosenCurrency,
      this.userSetting.preferredCurrency
    ]);
    this.userSetting.chosenCurrency = Array.from(currencies);
  }

  // 异步计算各货币金额
  async calculateCurrencyAmounts() {
    this.isLoading = true;
    this.errorMessage = "";

    try {
      const amounts = await calculateEachAmount(this.recordList);

      // 过滤并排序货币数据
      this.currencyAmounts = amounts
        .filter(item => this.userSetting.chosenCurrency.includes(item.unit))
        .sort((a, b) => {
          // 将首选货币排在最前面
          if (a.unit === this.userSetting.preferredCurrency) {
            return -1;
          }
          if (b.unit === this.userSetting.preferredCurrency) {
            return 1;
          }
          return a.unit.localeCompare(b.unit); // 其他按字母排序
        });
    } catch (error) {
      this.errorMessage = "货币计算失败";
      console.error("计算错误:", error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 调试信息（正式环境可移除）
      if (this.DEBUG) {
        Text(`当前货币: ${this.userSetting.chosenCurrency.join(", ")}`)
          .fontSize(12)
          .fontColor("#999")
          .margin({ bottom: 8 });
      }

      // 加载状态
      if (this.isLoading) {
        this.buildLoadingView();
      }
      // 错误状态
      else if (this.errorMessage) {
        this.buildErrorView();
      }
      // 空数据状态
      else if (this.currencyAmounts.length === 0) {
        this.buildEmptyView();
      }
      // 正常数据展示
      else {

        Column(){  this.buildCurrencyList(); }.justifyContent(FlexAlign.Start)


      }
    }
    .padding(12)
    .basicCard()
  }

  // 构建加载中视图
  @Builder
  private buildLoadingView() {
    Row() {
      ForEach([0, 1, 2], (index: number) => {
        Circle()
          .width(12)
          .height(12)
          .fill("#1890ff")
          .opacity(0.3 + (index * 0.3))
          .margin({ right: 8 })
          .animation({
            duration: 1000,
            curve: Curve.EaseInOut,
            iterations: -1,
            delay: index * 200
          });
      })
    }
    .height(100)
    .justifyContent(FlexAlign.Center)
  }

  // 构建错误视图
  @Builder
  private buildErrorView() {
    Column() {
      /* Image($r("app.media.ic_error"))
        .width(40)
        .height(40)
        .margin({ bottom: 8 });
      */
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor("#ff4d4f");
    }
    .height(100)
    .justifyContent(FlexAlign.Center)
  }

  // 构建空数据视图
  @Builder
  private buildEmptyView() {
    Column() {
      /* Image($r("app.media.ic_empty"))
    .width(60)
    .height(60)
    .margin({ bottom: 8 });
        */
      Text('暂无货币数据')
        .fontSize(16)
        .fontColor("#999");
    }
    .height(100)
    .justifyContent(FlexAlign.Center)
  }

  // 构建货币列表
  @Builder
  private buildCurrencyList() {
    ForEach(this.currencyAmounts, (currency: singleCurrency) => {
      Row() {
        // 货币符号
        Text(currency.unit)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({right:2})
        findFlag({flagName: currency.unit})

        // 金额显示
        Text(currency.amount.toFixed(2))
          .margin({left:4})
          .fontSize(18)
          .fontColor("#333")
          .flexGrow(1)
          .textAlign(TextAlign.End);
      }
      .padding(6)
      .borderRadius(8)
      .backgroundColor(this.userSetting.preferredCurrency === currency.unit ?
        "#e6f7ff" : "#fafafa")
      .margin({ bottom: 6 });
    })
  }
}