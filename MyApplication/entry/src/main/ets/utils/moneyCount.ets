// src/utils/financeCalculator.ts
import { MonthlySummary } from '../models/recordItemReference';
import { RecordItem,singleCurrency } from '../models/recordItemReference';
import { displayExchangeRates } from '../utils/currencyExchange';
import { promptAction } from '@kit.ArkUI';


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
        const rate = await displayExchangeRates(currency);
      if (typeof rate !== 'undefined') {
        exchangeRates[currency] = rate;
      }
      else {
        console.warn(`无法获取 ${currency} 的汇率，将跳过该货币计算`);
        promptAction.showToast({ message: '获取总资产时出错:'  });
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
    promptAction.showToast({ message: '计算总资产时出错:'  });
    return 0; // 或根据业务需求抛出错误
  }
}



export async function calculateEachAmount(
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

/**
 * 计算月度汇总（返回MonthlySummary实例）
 */
export function calculateMonthlySummary(recordList: RecordItem[]): MonthlySummary {
  const summary = new MonthlySummary();
  const now = new Date();

  recordList.forEach(item => {
    const recordDate = new Date(item.date);
    if (
      recordDate.getMonth() === now.getMonth() &&
        recordDate.getFullYear() === now.getFullYear()
    ) {
      const amount = Number(item.amount) || 0;
      if (amount > 0) {
        summary.income += amount;
      } else {
        summary.expense += Math.abs(amount);
      }
    }
  });

  return summary;
}

/**
 * 按月份分组统计（扩展功能）
 */
export function groupByMonth(recordList: RecordItem[]): Map<string, MonthlySummary> {
  const map = new Map<string, MonthlySummary>();

  recordList.forEach(item => {
    const date = new Date(item.date);
    const key = `${date.getFullYear()}-${date.getMonth()}`;

    if (!map.has(key)) {
      map.set(key, new MonthlySummary());
    }

    const amount = Number(item.amount) || 0;
    const summary = map.get(key)!;

    if (amount > 0) {
      summary.income += amount;
    } else {
      summary.expense += Math.abs(amount);
    }
  });

  return map;
}