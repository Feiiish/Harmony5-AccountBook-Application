import { RecordItem, RecordsData, filterRecordItems, LedgerManager } from "../../models/recordItemReference"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { CachedRatesStatus, UserSetting } from "../../models/userSetting"
import { formatDateAdvanced } from "../../utils/formatDateAdvanced"
import { TipsDialog } from '@kit.ArkUI'
import { emitter, Callback } from '@kit.BasicServicesKit';
import {
  TabSegmentButtonV2,
  CapsuleSegmentButtonV2,
  MultiCapsuleSegmentButtonV2,
  SegmentButtonV2Items,
} from '@kit.ArkUI';

@ComponentV2
export struct datePicker {
  @Local isShowSheet: boolean = false;
  @Local selectedIndex: number = 0;
  @Local selectedDate: Date = new Date();
  @Local now: Date = new Date();
  @Local ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local textItems: SegmentButtonV2Items = new SegmentButtonV2Items([
    { text: '按年' },
    { text: '按月' },
    { text: '所有' },
  ]);
  private fruits: string[][] = [
    this.generateYears(2000, 2030),
    ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']
  ];

  generateYears(start: number, end: number): string[] {
    const years: string[] = [];
    for (let i = start; i <= end; i++) {
      years.push(`${i}年`);
    }
    return years;
  }

  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const monthNames =
      ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月'];
    const month = monthNames[date.getMonth()];
    return `${year}年${month}`;
  }

  private showDatePicker(isStart: boolean) {
    const currentYear = this.now.getFullYear();
    const currentMonth = this.now.getMonth();

    let selected: number[] = [currentYear - 2000, currentMonth];
    let range: string[][] = [];

    if (this.selectedIndex === 0) {
      range = [this.generateYears(2000, 2030)];
      selected = [currentYear - 2000];
    } else if (this.selectedIndex === 1) {
      range = this.fruits;
    } else {
      return;
    }

    this.getUIContext().showTextPickerDialog({
      range: range,
      selected: selected,
      value: this.formatDate(isStart ? this.ledgerManager.activeBook.startDate : this.ledgerManager.activeBook.endDate),
      defaultPickerItemHeight: 40,
      onAccept: (value: TextPickerResult) => {
        let year = 2000;
        let month = 0;

        if (Array.isArray(value.index)) {
          year += value.index[0];
          month = this.selectedIndex === 1 ? value.index[1] : 0;
        } else {
          year += value.index;
          month = 0; // 强制重置月份为一月
        }

        let date: Date;
        if (isStart) {
          date = new Date(year, month, 1);
          this.ledgerManager.activeBook.startDate = date;
        } else {
          date = this.selectedIndex === 0
            ? new Date(year, 11, 31)
            : new Date(year, month + 1, 0);
          this.ledgerManager.activeBook.endDate = date;
        }

        // 自动调整逻辑
        const start = this.ledgerManager.activeBook.startDate;
        const end = this.ledgerManager.activeBook.endDate;

        if (start && end && start.getTime() > end.getTime()) {
          if (isStart) {
            this.ledgerManager.activeBook.endDate = this.selectedIndex === 0
              ? new Date(start.getFullYear() + 1, 11, 31)
              : new Date(start.getFullYear(), start.getMonth() + 1, 0);
          } else {
            this.ledgerManager.activeBook.startDate = this.selectedIndex === 0
              ? new Date(end.getFullYear() - 1, 0, 1)
              : new Date(end.getFullYear(), end.getMonth() - 1, 1);
          }
        }

        console.info(`${isStart ? "开始" : "结束"}日期选择: ` + date.toDateString());
      }
    });
  }

  @Builder
  mySheet() {
    Column() {
      Text(this.selectedIndex === 0 ? '按照年份过滤账单'
        : this.selectedIndex === 1 ? '按照月份过滤账单'
          : '展示所有账单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      Column() {
        if (this.selectedIndex === 0 || this.selectedIndex === 1) {
          Row({ space: 20 }) {
            Button(formatDateAdvanced(this.ledgerManager.activeBook.startDate,
              this.selectedIndex === 0 ? "YYYY年" : "YYYY-MM"))
              .onClick(() => this.showDatePicker(true))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontSize(24)
            Text("-")
              .fontSize(24)
            Button(formatDateAdvanced(this.ledgerManager.activeBook.endDate,
              this.selectedIndex === 0 ? "YYYY年" : "YYYY-MM"))
              .onClick(() => this.showDatePicker(false))
              .buttonStyle(ButtonStyleMode.TEXTUAL)
              .fontSize(24)
          }.margin({ bottom: 20 })
        } else {
          Text("展示所有账单").fontSize(20).margin({ bottom: 20 })
        }
      }.height(140).justifyContent(FlexAlign.Center)

      CapsuleSegmentButtonV2({
        items: this.textItems,
        selectedIndex: this.selectedIndex,
        $selectedIndex: (index: number) => {
          this.selectedIndex = index;

          const start = this.ledgerManager.activeBook.startDate;
          const end = this.ledgerManager.activeBook.endDate;

          if (index === 0) {
            // 周总结（按年） → 保留年份，重置为该年起止
            const startYear = start.getFullYear();
            const endYear = end.getFullYear();

            this.ledgerManager.activeBook.startDate = new Date(startYear, 0, 1); // 年初
            this.ledgerManager.activeBook.endDate = new Date(endYear, 11, 31); // 年末
          } else if (index === 1) {
            // 按月 → 保留年月，重置为该月起止
            const startYear = start.getFullYear();
            const startMonth = start.getMonth();
            const endYear = end.getFullYear();
            const endMonth = end.getMonth();

            this.ledgerManager.activeBook.startDate = new Date(startYear, startMonth, 1); // 月初
            this.ledgerManager.activeBook.endDate = new Date(endYear, endMonth + 1, 0); // 月末
          } else {
            // 所有账单 → 默认范围
            this.ledgerManager.activeBook.startDate = new Date(2000, 0, 1);
            this.ledgerManager.activeBook.endDate = new Date();
          }

        }

      }).width("80%").margin({ top: 22 })
    }.width('100%').alignItems(HorizontalAlign.Center)
  }

  build() {

    Column() {
      Row() {
        Text(this.selectedIndex === 0
          ? formatDateAdvanced(this.ledgerManager.activeBook.endDate, "... YYYY年")
          : this.selectedIndex === 1
            ? formatDateAdvanced(this.ledgerManager.activeBook.endDate, "... YY年MM月")
            : "所有账单")
          .fontWeight(FontWeight.Bold)
          .fontSize(28)

        Text("👇").fontSize(25)
      }
      .onClick(() => {
        this.isShowSheet = !this.isShowSheet;
      })
      .bindSheet(this.isShowSheet, this.mySheet(), {
        height: 300,
        onWillDisappear: () => {
          this.isShowSheet = false;
        }
      });
    }
  }
}
