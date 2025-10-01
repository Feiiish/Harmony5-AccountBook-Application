import { RecordItem } from "./recordItemReference";

type ExchangeRates = Record<string, number>;

@ObservedV2
export class UserSetting {
  @Trace profile: string | undefined = ""
  @Trace nickName: string | undefined = ""
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

