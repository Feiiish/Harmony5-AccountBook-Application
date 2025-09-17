import { RecordItem, RecordsData } from '../models/recordItemReference';
import { PersistenceV2, promptAction } from '@kit.ArkUI';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

/*
@ComponentV2
export struct ExportCSV {
  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'incomeExpenseRecords',
    () => new RecordsData()
  )!;

  async exportToCSV(context: Context) {
    const recordList: RecordItem[] = this.recordsData.items;

    // 1️⃣ 构建 CSV 内容
    const headers = ['Date', 'Category', 'Amount', 'Note'];
    const rows = recordList.map(item =>
    `${item.date},${item.tag},${item.amount},${item.note}`
    );
    const csvContent = [headers.join(','), ...rows].join('\n');

    // 2️⃣ 申请存储权限
    const atManager = abilityAccessCtrl.createAtManager();
    const { authResults } = await atManager.requestPermissionsFromUser(
      context,
      ['ohos.permission.WRITE_USER_STORAGE']
    );
    if (authResults[0] !== 0) {
      promptAction.showToast({ message: '存储权限被拒绝' });
      return;
    }

    // 3️⃣ 使用文件选择器保存为 .csv 文件
    const fileName = `records_${new Date().toISOString().replace(/[:.]/g, '-')}.csv`;
    const documentPicker = new picker.DocumentViewPicker();
    const saveResult = await documentPicker.saveAs({
      newFileNames: [fileName],
      types: ['text/csv']
    });

    const targetUri = saveResult[0];
    const fd = fs.openSync(targetUri, fs.OpenMode.READ_WRITE);
    fs.writeSync(fd, csvContent);
    fs.closeSync(fd);

    promptAction.showToast({ message: 'CSV 导出成功！' });
  }

  build() {
    Button('导出为 CSV')
      .onClick(() => {
        this.exportToCSV(getContext(this));
      })
      .margin(20);
  }
}
* */
