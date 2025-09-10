// src/models/RecordItem.ts
import { Type } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import image from '@ohos.multimedia.image';

@ObservedV2
export class RecordItem {
  @Trace id: string = Date.now().toString(36) + Math.random().toString(36).substring(2, 9);
  @Trace amount: number = 0; // 正数=收入，负数=支出
  @Trace unit: string = 'CNY';
  @Trace tag: string = '';
  @Trace note: string = '';
  @Trace date: string = new Date().toDateString();
  @Trace selectimageUriedImage: ResourceStr = ""

  get type(): 'income' | 'expense' {
    return this.amount >= 0 ? 'income' : 'expense';
  }

  // 获取显示用绝对值金额
  get displayAmount(): number {
    return Math.abs(this.amount);
  }
}

export interface singleCurrency {
  amount: number;
  unit: string
  rate: number
}

// RecordsData.ets
@ObservedV2
export class RecordsData {
  @Type(RecordItem)
  @Trace
  items: RecordItem[] = [];
}
