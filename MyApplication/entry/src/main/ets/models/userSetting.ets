import { RecordItem } from "./recordItemReference";

type ExchangeRates = Record<string, number>;

@ObservedV2
export class UserSetting {
  @Trace preferredCurrency: string = "CNY";
  @Trace chosenCurrency: string[] = ["CNY", "CAD", "USD", "JPY"];
  @Trace tags: string[] = ['餐饮', '购物', '交通', '娱乐', '住房', '工资', '奖金', '投资'];
  //

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

