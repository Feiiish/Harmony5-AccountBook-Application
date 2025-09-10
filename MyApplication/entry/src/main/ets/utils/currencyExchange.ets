import { App, PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { http } from '@kit.NetworkKit';
import { ratesStatus } from '../components/RatesStatus';
import { CachedRatesStatus, UserSetting } from "../models/userSetting"

let apiUrl: string = 'https://api.exchangerate-api.com/v4/latest/'

interface ExchangeRateApiResponse {
  provider: string;
  WARNING_UPGRADE_TO_V6?: string;
  terms: string;
  base: string;
  date: string;
  rates: Record<string, number>;
}

type ExchangeRates = Record<string, number>;


// 创建持久化存储实例
const cachedRatesStorage = PersistenceV2.connect(CachedRatesStatus, "cachedRatesStatus", () => new CachedRatesStatus());

export async function getExchangeRatesWithCache(userCurrency: string): Promise<ExchangeRates> {
  // 从持久化存储获取缓存数据
  const cachedRates = cachedRatesStorage?.cachedData
  const lastUpdated = cachedRatesStorage?.getParsedTime()
  const lastUpdatedUnit = cachedRatesStorage?.lastUpdatedUnit

  if (cachedRates && Object.keys(cachedRates).length > 0 && lastUpdated && userCurrency === lastUpdatedUnit) {
    if (Math.abs(new Date().getTime() - lastUpdated.getTime()) / 1000 < 1800) {
      console.log("Using cached data: time difference " +
        Math.abs(new Date().getTime() - lastUpdated.getTime()) / 1000);
      return cachedRates;
    }
  }

  try {
    const req = http.createHttp();
    const res = await req.request(apiUrl + userCurrency);
    const data: ExchangeRateApiResponse = JSON.parse(res.result as string);

    // 验证数据格式
    if (!data.rates || typeof data.rates !== 'object') {
      throw new Error('Invalid API response format');
    }

    if (cachedRatesStorage) {
      cachedRatesStorage.cachedData = data.rates;
      const lastUpdated = cachedRatesStorage?.getParsedTime()
      cachedRatesStorage.lastUpdatedUnit = userCurrency;
    }


    console.log("Fetched new data: " + JSON.stringify(data.rates));
    return data.rates;
  } catch (error) {
    console.error('获取汇率失败:', error);
    // 如果失败但缓存存在，返回缓存
    if (cachedRates && Object.keys(cachedRates).length > 0) {
      console.warn('使用缓存的汇率数据');
      return cachedRates;
    }
    throw new Error('Failed to fetch exchange rates and no cache available');
  }
}

export async function updateExchangeRates(userCurrency: string): Promise<ExchangeRates> {
  const status = PersistenceV2.connect(CachedRatesStatus, "cachedRatesStatus", () => new CachedRatesStatus())

  const cachedRates = cachedRatesStorage?.cachedData
  const lastUpdated = cachedRatesStorage?.getParsedTime()
  const lastUpdatedUnit = cachedRatesStorage?.lastUpdatedUnit

  try {
    const req = http.createHttp();
    const res = await req.request(apiUrl + userCurrency);
    const data: ExchangeRateApiResponse = JSON.parse(res.result as string);

    // 验证数据格式
    if (!data.rates || typeof data.rates !== 'object') {
      throw new Error('Invalid API response format');
    }

    if (cachedRatesStorage) {
      cachedRatesStorage.cachedData = data.rates;
      cachedRatesStorage.lastUpdateTime = new Date().toISOString()
      cachedRatesStorage.lastUpdatedUnit = userCurrency;
    }

    console.log("Fetched new data: " + JSON.stringify(data.rates));
    return data.rates;
  } catch (error) {
    console.error('获取汇率失败:', error);
    // 如果失败但缓存存在，返回缓存
    if (cachedRates && Object.keys(cachedRates).length > 0) {
      console.warn('使用缓存的汇率数据');
      return cachedRates;
    }
    throw new Error('Failed to fetch exchange rates and no cache available');
  }
}

export async function displayExchangeRates(userCurrency: string, oneCurrency?: string): Promise<number> {
  try {
    const rates = await getExchangeRatesWithCache(userCurrency);

    if (oneCurrency) {
      // 显示特定货币汇率
      const rate = rates[oneCurrency];
      if (rate !== undefined) {
        console.log(`1 ${userCurrency} = ${rate} ${oneCurrency}`);
        return rate;
      } else {
        console.error(`未找到货币代码 ${oneCurrency} 的汇率`);
      }
    } else {
      // 显示所有汇率（保持原样不返回值）
      const entries = Object.entries(rates);
      for (let i = 0; i < entries.length; i++) {
        const currency = entries[i][0];
        const rate = entries[i][1];
        console.log(`1 ${userCurrency} = ${rate} ${currency}`);
      }
    }

  } catch (error) {
    console.error('处理汇率数据时出错:', error);
  }
  return 0
}