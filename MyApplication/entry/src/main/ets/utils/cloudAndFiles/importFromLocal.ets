import { picker, fileUri } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import type { BusinessError } from '@kit.BasicServicesKit';
import { OperateIcon, PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager, filterRecordItems } from '../../models/recordItemReference';
import { MaxSelected } from '@kit.MediaLibraryKit';
import { uri } from '@kit.ArkTS';

import util from '@ohos.util';


@ComponentV2
export struct filePicker {
  @Local message: string = '点击选择CSV文件';
  @Local preview: string = '点击导入 CSV 文件';
  @Local error: string = '';
  @Local listTo: RecordItem[] = []
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  build() {
    Column() {
      Text("List To be Add" + this.listTo.length.toString())
      Text(this.preview)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin(10)
        .width('90%');

      if (this.error !== '') {
        Text(this.error)
          .fontSize(16)
          .fontColor(Color.Red)
          .margin(10);
      }

      Button('选择并解析 CSV')
        .margin(20)
        .onClick(() => {
          this.importCsv()
        });
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center);
  }

  public async importCsv(): Promise<string[][]> {
    try {
      this.error = '';
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;


      const documentPicker = new picker.DocumentViewPicker(context);
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.defaultFilePathUri = "file://docs/storage/Users/currentUser/test";
      options.fileSuffixFilters = ['.csv'];
      let uris: string[] = [];

      documentPicker.select(options).then((documentSelectResult: Array<string>) => {
        //文件选择成功后，返回被选中文档的URI结果集。
        uris = documentSelectResult;
        console.info('documentViewPicker.select to file succeed and uris are:' + uris);
        if (uris.length > 0) {
          let uri: string = uris[0];
          let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
          let buffer = new ArrayBuffer(4096);

          let readLen = fs.readSync(file.fd, buffer);
          fs.closeSync(file);
          // ✅ 解析 CSV 内容
          const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
          const content: string = decoder.decodeWithStream(new Uint8Array(buffer), { stream: false });

          const lines: Array<string> = content.split('\n');
          const parsed: Array<Array<string>> = lines.map(line =>
          line.split(',').map(cell => {
            const trimmed = cell.trim();
            return trimmed.startsWith('"') && trimmed.endsWith('"')
              ? trimmed.slice(1, -1).replace(/""/g, '"') // 处理转义双引号
              : trimmed;
          })
          );


          // ✅ 显示前几行预览
          let previewText: string = 'CSV预览：\n';
          for (let i = 0; i < Math.min(parsed.length, 5); i++) {
            previewText += parsed[i].join(' | ') + '\n';
          }
          this.preview = previewText;
          this.addContent(parsed)
          return parsed
        } else {
          console.warn("no file found");
        }
        return []
      }).catch((err: BusinessError) => {
        console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
      })
    } catch (err) {
      this.error = '解析失败：' + JSON.stringify(err);
    }
    return [""][""]
  }

  addContent(content: string[][]) {
    this.error = '';

    // ✅ 解析 CSV 行为 RecordItem
    let headers: Array<string> = content[0];
    let parsedRecords: RecordItem[] = [];

    for (let i = 1; i < content.length; i++) {
      let row = content[i];

      // 防御式检查：字段数量不足则跳过
      if (row.length < 7) {
        console.warn(`第 ${i + 1} 行字段不足，已跳过`);
        continue;
      }

      let parsedRecord: RecordItem = new RecordItem();
      parsedRecord.id = row[0];
      parsedRecord.amount = Number.parseFloat(row[1]);
      parsedRecord.unit = row[2];
      parsedRecord.tag = row[3];
      parsedRecord.note = row[4];
      parsedRecord.date = row[5];
      parsedRecord.selectimageUriedImage = row[6];

      parsedRecords.push(parsedRecord);
    }

    // ✅ 更新待导入列表
    this.listTo = parsedRecords;

    // ✅ 去重：只保留新纪录
    const existingIds = new Set(this.ledgerManager.activeBook.data.items.map(item => item.id));
    const newItems = this.listTo.filter(item => !existingIds.has(item.id));
    const newCount = newItems.length;

    // ✅ 弹窗确认
    this.getUIContext().showAlertDialog({
      title: '导入记录',
      message: `成功解析 ${this.listTo.length} 条记录，其中 ${newCount} 条为新纪录。是否添加到账本 ${this.ledgerManager.activeBook.name}?`,
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('用户取消');
        }
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          this.ledgerManager.activeBook.data.items = [
            ...this.ledgerManager.activeBook.data.items,
            ...newItems
          ];
          console.info(`已添加 ${newCount} 条新纪录到账本`);
        }
      }
    });
  }
}
