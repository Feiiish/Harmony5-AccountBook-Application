// src/utils/financeCalculator.ts
import { RecordItem, singleCurrency } from '../models/recordItemReference';
import { displayExchangeRates } from '../utils/currencyExchange';
import { promptAction } from '@kit.ArkUI';
import { it } from '@ohos/hypium';


export async function calculateTotalAssets(
  recordList: RecordItem[],
  targetCurrency: string
): Promise<number> {
  try {
    // 1. 获取所有需要的汇率
    const exchangeRates: Record<string, number> = {};

    // 收集所有需要查询的货币类型（排除目标货币）
    const currenciesToQuery = Array.from(
      new Set(recordList.map(item => item.unit).filter(unit => unit !== targetCurrency))
    );

    // 批量获取汇率
    for (const currency of currenciesToQuery) {
      const rate = await displayExchangeRates(targetCurrency, currency);
      if (typeof rate !== 'undefined') {
        exchangeRates[currency] = rate;
      } else {
        console.warn(`无法获取 ${currency} 的汇率，将跳过该货币计算`);
        promptAction.showToast({ message: '获取总资产时出错:' });
      }
    }

    // 2. 计算总值（转换为目标货币）
    return recordList.reduce((sum, item) => {
      const amount = Number(item.amount) || 0;

      if (item.unit === targetCurrency) {
        return sum + amount;
      }

      const rate = exchangeRates[item.unit];
      if (rate) {
        return sum + (amount / rate); // 转换为目标货币
      }

      return sum; // 汇率不可用时跳过该货币
    }, 0);

  } catch (error) {
    promptAction.showToast({ message: '计算总资产时出错:' });
    return 0; // 或根据业务需求抛出错误
  }
}


export async function calculateEachCurrencyAmount(
  recordList: RecordItem[]
): Promise<singleCurrency[]> {
  const currencyMap = new Map<string, number>();

  // 遍历记录并按货币单位汇总金额
  for (let i = 0; i < recordList.length; i++) {
    const record = recordList[i];
    const amount = record.amount;
    const unit = record.unit;
    const currentAmount = currencyMap.get(unit) || 0;
    currencyMap.set(unit, currentAmount + amount);
  }
  // 转换为目标格式
  const result: singleCurrency[] = [];
  currencyMap.forEach((amount, unit) => {
    result.push({ amount, unit });
  });
  return result;

}


export async function monthlyInMonthlyOut(recordList: RecordItem[], userCurrency: string): Promise<number[]> {
  let income: number = 0;
  let expense: number = 0;

  if (!recordList || recordList.length === 0) {
    return [0, 0];
  }

  // 使用for...of循环替代forEach
  for (const item of recordList) {
    try {
      let amount = item.amount;

      // 如果货币不同，进行转换
      if (item.unit !== userCurrency) {
        const exchangeRate = await displayExchangeRates(userCurrency, item.unit);
        if (!Number.isNaN(exchangeRate)) {
          amount = item.amount / Number(exchangeRate);
        } else {
          console.warn(`无法获取 ${item.unit} 到 ${userCurrency} 的汇率`);
          amount = 0;
        }
      }

      // 根据金额正负判断收入支出
      if (item.amount > 0) {
        income += amount;
      } else {
        expense += Math.abs(amount);
      }

    } catch (error) {
      console.error(`处理记录时发生错误:`, item, error);
    }
  }

  return [income, expense];
}