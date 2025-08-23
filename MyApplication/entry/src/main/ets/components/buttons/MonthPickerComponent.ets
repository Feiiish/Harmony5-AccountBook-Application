import { RecordItem, RecordsData } from "../../models/recordItemReference"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { emitter, Callback } from '@kit.BasicServicesKit';


@ComponentV2
export struct MonthPickerComponent {
  @Local selectedYear: number = new Date().getFullYear()
  @Local selectedMonth: number = new Date().getMonth() + 1


  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'incomeExpenseRecords',
    () => new RecordsData()
  )!;

  @Monitor('recordsData.items')
  onItemsChange(monitor: IMonitor) {
    console.log("DataFilteredByMonth")
    this.filterRecords()
  }

  @Local
  choosedData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'choosedRecords',
    () => new RecordsData()
  )!;

  showPicker() {
    this.getUIContext().showDatePickerDialog({
      start: new Date("2000-1-1"),
      end: new Date("2100-12-31"),
      selected: new Date(this.selectedYear, this.selectedMonth - 1),
      mode: 1,
      onDateAccept: (value: Date) => {
        this.selectedYear = value.getFullYear()
        this.selectedMonth = value.getMonth()! + 1
        this.filterRecords()
      }
    })
  }

  private filterRecords() {
    // 确保日期格式统一处理
    this.choosedData.items = this.recordsData.items.filter(item => {
      const itemDate = new Date(item.date);
      return itemDate.getFullYear() === this.selectedYear &&
        itemDate.getMonth() === this.selectedMonth - 1
    })
  }

  onPageShow(): void {
    this.filterRecords()
  }



  build() {

    Column() {
      Text(this.selectedMonth.toString() + "月👇").fontSize(28)
        .fontWeight(FontWeight.Bold)
        .onClick(() => this.showPicker())
    }

  }
}