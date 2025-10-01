import { RecordItem, RecordsData, filterRecordItems, LedgerManager } from "../../models/recordItemReference"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { CachedRatesStatus, UserSetting } from "../../models/userSetting"
import { TipsDialog } from '@kit.ArkUI'
import { emitter, Callback } from '@kit.BasicServicesKit';

@Entry
@ComponentV2
export struct datePicker {
  private select: number | number[] = 0;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  generateYears(start: number, end: number): string[] {
    let years: string[] = [];
    for (let i = start; i <= end; i++) {
      years.push(`${i}年`);
    }
    return years;
  }

  private fruits: string[][] = [
    this.generateYears(2000, 2030),
    ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']
  ];
  @Local selectedDate: Date = new Date();
  @Local tomonthRecords: RecordsData = PersistenceV2.connect(
    RecordsData,
    'tomonthRecords',
    () => new RecordsData()
  )!;
  @Local now: Date = new Date();

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const monthNames =
      ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
    const month = monthNames[date.getMonth()];
    return `${year}年${month}`;
  }

  build() {
    Text(this.formatDate(this.ledgerManager.activeBook.chosenDate) + "👇").fontSize(28)
      .fontWeight(FontWeight.Bold)
      .onClick(() => {
        const currentYear = this.now.getFullYear();
        const currentMonth = this.now.getMonth();

        const yearList = this.generateYears(2000, 2030);
        const yearIndex = yearList.indexOf(`${currentYear}年`);
        const monthIndex = currentMonth;

        this.select = [yearIndex, monthIndex];

        this.getUIContext().showTextPickerDialog({
          range: this.fruits,
          selected: this.select,
          value: this.formatDate(this.selectedDate),
          defaultPickerItemHeight: 40,

          onAccept: (value: TextPickerResult) => {
            this.select = value.index;
            const year: number = 2000 + value.index[0];
            const month: number = value.index[1];
            this.ledgerManager.activeBook.chosenDate = new Date(year, month, 1);
            console.info("TextPickerDialog:onAccept()" + JSON.stringify(value));
          }
        });
      });
  }
}
