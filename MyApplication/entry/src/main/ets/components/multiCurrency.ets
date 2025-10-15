import { UserSetting, CachedRatesStatus } from "../models/userSetting"
import { displayExchangeRates } from "../utils/currencyExchange"
import { App, PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, singleCurrency, LedgerManager } from '../models/recordItemReference';
import { calculateEachCurrencyAmount } from '../utils/moneyCount';
import { findFlag, findColor } from '../utils/FindCountryFlags';
import { formatLargeNumber } from "../utils/formatLargeNumber"
import { PieChartExample } from "../components/charts/pieChart"
import { text } from "@kit.ArkGraphics2D";

// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});


//规定普通Row样式
@Extend(Row)
function currencyCard() {
  .justifyContent(FlexAlign.Start)
  .width("28%")
  .padding(4)
}

@Styles
function basicCard() {
  .width('100%')
  .padding(16)
  .borderRadius(15)
  .margin({ bottom: 12 })
  .backgroundColor($r("app.color.Basic_Card_background"))
}

@ComponentV2
export struct MultiCurrencyComposition {
  @Require @Param recordList: RecordItem[];

  @Monitor('recordList')
  onItemsChange(monitor: IMonitor) {
    console.log("MultiCurrency Inital")
    this.refreshData();
  }

  @Local
  cachedRatesStorage: CachedRatesStatus = PersistenceV2.connect(
    CachedRatesStatus,
    "cachedRatesStatus",
    () => new CachedRatesStatus()
  )!;

  @Monitor('cachedRatesStorage.lastUpdateTime')
  onStatusChange(monitor: IMonitor) {
    console.log("From Monthly Panel: lastUpdateTime changed");
    this.refreshData()
  }

  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  @Monitor('userSetting.preferredCurrency')
  onSettingChange(monitor: IMonitor) {
    console.log("MultiCurrency Inital: setting changed")
    this.refreshData();
  }

  @Local
  currencyAmounts: singleCurrency[] = []; // 货币金额数组
  @Local
  isLoading: boolean = true; // 加载状态
  @Local
  errorMessage: string = ""; // 错误信息
  @Local DEBUG: boolean = true;
  @Local isShowSheet: boolean = false;
  @Local colors: string[] = ['#FF6384', '#36A2EB', '#FFCE56', '#4CAF50', '#F44336'];
  @Local totalAmount: number = 0;
  private selectedCurrency: singleCurrency | null = null

  aboutToAppear() {
    this.refreshData();
  }

  private async refreshData() {
    //if (this.DEBUG) console.log('Refreshing currency data...');
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
      ...this.ledgerManager.activeBook.chosenCurrency,
      this.ledgerManager.activeBook.preferredCurrency
    ]);
    this.ledgerManager.activeBook.chosenCurrency = Array.from(currencies);
  }

  // 异步计算各货币金额
  async calculateCurrencyAmounts() {
    this.isLoading = true;
    this.errorMessage = "";

    try {
      const amounts =
        await calculateEachCurrencyAmount(this.recordList, this.ledgerManager.activeBook.preferredCurrency);

      // 过滤并排序货币数据
      this.currencyAmounts = amounts
        .filter(item => this.ledgerManager.activeBook.chosenCurrency.includes(item.unit))
        .sort((a, b) => {
          // 将首选货币排在最前面
          if (a.unit === this.ledgerManager.activeBook.preferredCurrency) {
            return -1;
          }
          if (b.unit === this.ledgerManager.activeBook.preferredCurrency) {
            return 1;
          }
          return a.unit.localeCompare(b.unit); // 其他按字母排序
        });
      this.totalAmount = this.currencyAmounts.reduce((sum, item) => {
        return sum + item.amount / item.rate;
      }, 0);

    } catch (error) {
      this.errorMessage = "货币计算失败";
      console.error("计算错误:", error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Text("货币总额").fontSize(20).fontWeight(FontWeight.Bold).margin({ bottom: 8, top: 4 })
      /*
            if (this.DEBUG) {
              Text(`当前货币: ${this.userSetting.chosenCurrency.join(", ")}`)
                .fontSize(12)
                .fontColor("#999")
                .margin({ bottom: 8 });
            }
            * */
      //build pie chart
      if (this.currencyAmounts.length !== 0) {
        PieChartExample({ pieData: this.currencyAmounts, colors: this.colors })

      }

      Column() {

        Row() {
          Text(`净资产 ≈ ${this.totalAmount.toFixed(2)} ${this.ledgerManager.activeBook.preferredCurrency}`)
            .margin({ top: 4 })
            .fontWeight(20)
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

          List({ space: 8, initialIndex: 0 }) {
            this.buildCurrencyListView();
          }
          .lanes(2)
          .contentStartOffset(20)
          .contentEndOffset(20)
          .width('100%')
          .scrollBar(BarState.Off)
          .friction(0.6)
          .alignListItem(ListItemAlign.Center)
        }


      }
      .basicCard()
      .shadow(ShadowStyle.OUTER_FLOATING_SM)
      .borderRadius(24)
      .backgroundColor($r('app.color.Card_background_2'))
      .margin({ top: 12 })

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

  @Builder
  private buildCurrencyListView() {
    //
    ForEach(this.currencyAmounts, (currency: singleCurrency) => {
      currencyItemView({ currency: currency })
    })
  }
}

@ComponentV2
export struct currencyItemView {
  @Require @Param currency: singleCurrency
  @Local isShowSheet: boolean = false;
  @Local forCalcu: number = 0;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  @Builder
  mySheet() {
    Column() {
      Row() {
        Text(`${this.currency.unit}`)
          .fontWeight(FontWeight.Bold)
          .margin({ right: 12 })
          .fontSize(22)
        findFlag({ flagName: this.currency.unit })

      }
      .width('100%')
      .margin({ top: 25 })


      Column() {
        //text Input 可以用指定货币换算成目标货币
        Text('计算汇率').width('90%').fontSize(18).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
        Row() {
          TextInput({ text: "1" })
            .type(InputType.NUMBER_DECIMAL)
            .width(100)
            .onChange((val: string) => {
              this.forCalcu = Number(val)
            })
          // enter prefered currency
          Text(" " + this.ledgerManager.activeBook.preferredCurrency + " ")

          Text(`${"≈" + " " + (this.currency.rate * this.forCalcu).toFixed(2) + " " + this.currency.unit}`)
        }.width('90%')

      }
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
      .width("100%")
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r("app.color.Basic_Card_background"))
      .padding(12)
      .borderRadius(24)
      .margin({ top: 22 })


      Column() {


        if (this.currency.unit !== this.ledgerManager.activeBook.preferredCurrency) {
          Row() {
            Text("汇率：")
            Text(`${(1 / this.currency.rate).toFixed(4)}`)

          }.margin({ bottom: 12 })

          Row() {
            Text("货币总额：")
            Text(`${this.currency.amount}`)

              .fontColor(this.currency.amount >= 0 ? '#00B300' : '#FF3A3A')
          }.margin({ bottom: 12 })

          Row() {
            Text("大约为：")
            Text(`${(this.currency.amount / this.currency.rate).toFixed(2) + " " +
            this.ledgerManager.activeBook.preferredCurrency}`)
          }.margin({ bottom: 12 })

        }

      }.alignItems(HorizontalAlign.Start)
      .margin({ top: 22 })

    }
    .width('75%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      Row() {
        Row() {
          findFlag({ flagName: this.currency.unit })
            .width(28)
            .height(20)
          Text(this.currency.unit)
            .fontSize(20)
        }

        Circle()
          .width(12)
          .height(12)
          .margin({ right: 6 })
          .fill(findColor(this.currency.unit))

      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width("100%")
      .margin({ bottom: 4 })

      Text(formatLargeNumber(this.currency.amount))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .flexGrow(1)
      if (this.currency.unit == this.ledgerManager.activeBook.preferredCurrency) {
        Text(" 本位币")
      } else {
        Text(`汇率：${parseFloat((1 / this.currency.rate).toFixed(4))}`)
      }

    }
    .width("94%")
    .height(100)
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .borderRadius(12)
    .backgroundColor(
      this.ledgerManager.activeBook.preferredCurrency === this.currency.unit
        ? $r("app.color.Currency_Card_Main")
        : $r("app.color.Currency_Card_1")
    )
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .onClick(() => {
      this.isShowSheet = true;
      console.log(JSON.stringify(this.currency));
    })
    .bindSheet(this.isShowSheet, this.mySheet(), {
      height: 560,
      onWillDisappear: () => {
        this.isShowSheet = false;
      }
    })
    .margin({ bottom: 6 })
  }
}


