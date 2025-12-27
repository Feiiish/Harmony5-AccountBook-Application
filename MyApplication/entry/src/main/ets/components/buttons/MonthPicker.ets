import { RecordItem, RecordsData, filterRecordItems, LedgerManager } from "../../models/recordItemReference"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { CachedRatesStatus, UserSetting } from "../../models/userSetting"
import { formatDateAdvanced } from "../../utils/formatDateAdvanced"
import { TipsDialog } from '@kit.ArkUI'

import {
  SegmentButton, SegmentButtonItemTuple, SegmentButtonOptions,
} from '@kit.ArkUI';

@Component
export struct datePicker {
  @State isShowSheet: boolean = false;
  @State selectedDate: Date = new Date();
  @State now: Date = new Date();
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @State singleSelectCapsuleSelectedIndexes: number[] = this.ledgerManager.activeBook.dateIndex;
  @State singleSelectCapsuleOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [
      { text: '按年' },
      { text: '按月' },
      { text: '全部' }
    ] as SegmentButtonItemTuple,
    multiply: false,
    backgroundBlurStyle: BlurStyle.BACKGROUND_THICK
  ,
    backgroundColor: $r('app.color.Darker_window_background'),
    textPadding: {
      top: 10,
      right: 10,
      bottom: 10,
      left: 10
    },
  });
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

    if (this.singleSelectCapsuleSelectedIndexes[0] === 0) {
      range = [this.generateYears(2000, 2030)];
      selected = [currentYear - 2000];
    } else if (this.singleSelectCapsuleSelectedIndexes[0] === 1) {
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
          month = this.singleSelectCapsuleSelectedIndexes[0] === 1 ? value.index[1] : 0;
        } else {
          year += value.index;
          month = 0; // 强制重置月份为一月
        }

        let date: Date;
        if (isStart) {
          date = new Date(year, month, 1);
          this.ledgerManager.activeBook.startDate = date;
        } else {
          date = this.singleSelectCapsuleSelectedIndexes[0] === 0
            ? new Date(year, 11, 31)
            : new Date(year, month + 1, 0);
          this.ledgerManager.activeBook.endDate = date;
        }

        // 自动调整逻辑
        const start = this.ledgerManager.activeBook.startDate;
        const end = this.ledgerManager.activeBook.endDate;

        if (start && end && start.getTime() > end.getTime()) {
          if (isStart) {
            this.ledgerManager.activeBook.endDate = this.singleSelectCapsuleSelectedIndexes[0] === 0
              ? new Date(start.getFullYear() + 1, 11, 31)
              : new Date(start.getFullYear(), start.getMonth() + 1, 0);
          } else {
            this.ledgerManager.activeBook.startDate = this.singleSelectCapsuleSelectedIndexes[0] === 0
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
      Text(this.singleSelectCapsuleSelectedIndexes[0] === 0 ? '按照年份过滤账单'
        : this.singleSelectCapsuleSelectedIndexes[0] === 1 ? '按照月份过滤账单'
          : '展示所有账单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 16 })

      Column() {
        if (this.singleSelectCapsuleSelectedIndexes[0] === 0 || this.singleSelectCapsuleSelectedIndexes[0] === 1) {

          Column({ space: 6 }) {
            Row() {
              Text("开始时间:")
                .fontSize(20)
              Button(formatDateAdvanced(this.ledgerManager.activeBook.startDate,
                this.singleSelectCapsuleSelectedIndexes[0] === 0 ? "YYYY年" : "YYYY年MM月"))
                .onClick(() => this.showDatePicker(true))
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .fontSize(20)
            }

            Row() {
              Text("结束时间:")
                .fontSize(20)
              Button(formatDateAdvanced(this.ledgerManager.activeBook.endDate,
                this.singleSelectCapsuleSelectedIndexes[0] === 0 ? "YYYY年" : "YYYY年MM月"))
                .onClick(() => this.showDatePicker(false))
                .buttonStyle(ButtonStyleMode.TEXTUAL)
                .fontSize(20)
            }

          }.width('80%')
        } else {
          Text("展示所有账单").fontSize(24)
        }
      }.height(140).justifyContent(FlexAlign.Center)


      SegmentButton({
        options: this.singleSelectCapsuleOptions,
        selectedIndexes: $singleSelectCapsuleSelectedIndexes,
        onItemClicked: (index: number) => {
          const book = this.ledgerManager.activeBook;
          this.ledgerManager.activeBook.dateIndex = [index]
          if (index === 0) {
            // 按年
            const year = book.endDate.getFullYear(); // 或者用当前年也行
            book.startDate = new Date(year, 0, 1);
            book.endDate = new Date(year, 11, 31);
          } else if (index === 1) {
            // 按月
            const year = book.endDate.getFullYear();
            const month = book.endDate.getMonth();
            book.startDate = new Date(year, month, 1);
            book.endDate = new Date(year, month + 1, 0);
          } else {
            // 全部
            book.startDate = new Date(2000, 0, 1);
            book.endDate = new Date();
          }

        },

      })
        .width("80%")
        .margin({ top: 22 })
    }.width('100%').alignItems(HorizontalAlign.Center)
  }

  build() {

    Column() {
      Row() {
        Text(this.singleSelectCapsuleSelectedIndexes[0] === 0
          ? formatDateAdvanced(this.ledgerManager.activeBook.endDate, "... YYYY年")
          : this.singleSelectCapsuleSelectedIndexes[0] === 1
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
