import { RecordItem } from "./recordItemReference";

type ExchangeRates = Record<string, number>;


@ObservedV2
export class UserSetting {
  @Trace profile: string | undefined = ""
  @Trace nickName: string | undefined = ""
  // IndexComponents
  @Trace MonthlySummaryPanel: boolean = true
  @Trace budgetComponent: boolean = true
  @Trace menuList: boolean = true
  @Trace WeeklyChart: boolean = true
  @Trace searchBarView: boolean = true
  @Trace rateChart: boolean = true
  //secTabComponents
  @Trace MultiCurrencyComposition: boolean = true
  @Trace calendar: boolean = true
  //currencySetting
  @Trace showCurrencyCode: boolean = true
  @Trace awfawf: boolean = true
}

@ObservedV2
export class CachedRatesStatus {
  @Trace lastUpdateTime: string = ""
  @Trace lastUpdatedUnit: string = ""
  @Trace cachedData: ExchangeRates | null = null

  getParsedTime(): Date | null {
    return this.lastUpdateTime ? new Date(this.lastUpdateTime) : null;
  }
}

