// src/models/RecordItem.ts
import { Type } from '@kit.ArkUI';

@ObservedV2
export class RecordItem {
  @Trace id: string = Date.now().toString(36) + Math.random().toString(36).substring(2, 9);
  @Trace amount: number = 0; // 正数=收入，负数=支出
  @Trace unit: string = 'CNY';
  @Trace tag: string = '';
  @Trace note: string = '';
  @Trace date: string = new Date().toISOString();

  // 动态计算类型（不再需要存储type字段）
  get type(): 'income' | 'expense' {
    return this.amount >= 0 ? 'income' : 'expense';
  }

  // 获取显示用绝对值金额
  get displayAmount(): number {
    return Math.abs(this.amount);
  }
}

export interface singleCurrency{
  amount: number; unit: string
}


// RecordsData.ets
@ObservedV2
export class RecordsData {
  @Type(RecordItem)
  @Trace
  items: RecordItem[] = [];

}



// src/model/TransferModel.ts
@ObservedV2
export class TransferItem {
  @Trace date: string = new Date().toISOString();
  @Trace fromAmount: number = 0;
  @Trace toAmount: number = 0;
  @Trace unit: string = 'CNY';
  @Trace tag: string = '';
  @Trace note?: string;
  @Trace createdAt: string = new Date().toISOString();

  // 汇率计算
  get exchangeRate(): number {
    return this.toAmount / this.fromAmount;
  }
}
