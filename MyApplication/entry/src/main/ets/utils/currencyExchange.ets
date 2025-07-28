
import { http } from '@kit.NetworkKit';

// 用户设置中的本位币
let userCurrency: string = 'CNY';  // 假设用户设置中的本位币是CNY
let apiUrl: string = 'https://api.exchangerate-api.com/v4/latest/' + userCurrency;


interface ExchangeRateApiResponse {
  provider: string;
  WARNING_UPGRADE_TO_V6?: string;
  terms: string;
  base: string;
  date: string;
  time_last_updated: number;
  rates: Record<string, number>;
}

type ExchangeRates = Record<string, number>;

let cachedRates: ExchangeRates | null = null;
let lastUpdated: number | null = null;


export async function getExchangeRatesWithCache(): Promise<ExchangeRates> {
  // 如果缓存未过期（假设1小时有效），使用缓存
  const now = Math.floor(Date.now() / 1000); // 转换为秒
  if (cachedRates && lastUpdated && (now - lastUpdated < 3600)) {
    console.log("Overwritten the cache: time difference " + (now - lastUpdated).toString());
    return cachedRates;
  }

  try {
    const req = http.createHttp();
    const res = await req.request(apiUrl);
    const data: ExchangeRateApiResponse = JSON.parse(res.result as string);

    // 验证数据格式
    if (!data.rates || typeof data.rates !== 'object') {
      throw new Error('Invalid API response format');
    }

    // 更新缓存
    cachedRates = data.rates;
    lastUpdated = data.time_last_updated;

    console.log(" the current data"+JSON.stringify( data.rates));
    return data.rates;
  } catch (error) {
    console.error('获取汇率失败:', error);
    // 如果失败但缓存存在，返回缓存
    if (cachedRates) {
      console.warn('使用缓存的汇率数据');
      return cachedRates;
    }
    throw new Error('Failed to fetch exchange rates and no cache available');
  }
}

export async function displayExchangeRates(currencyCode?: string): Promise<number | void> {
  try {
    const rates = await getExchangeRatesWithCache();

    if (currencyCode) {
      // 显示特定货币汇率
      const rate = rates[currencyCode];
      if (rate !== undefined) {
        console.log(`1 ${userCurrency} = ${rate} ${currencyCode}`);
        return rate; // 唯一新增的 return 语句
      } else {
        console.error(`未找到货币代码 ${currencyCode} 的汇率`);
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
}
