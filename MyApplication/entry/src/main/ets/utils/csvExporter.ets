import { RecordItem, RecordsData, LedgerManager, LedgerBook } from '../models/recordItemReference';
import { systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { fileIo as fs } from '@kit.CoreFileKit';
import { data } from '@kit.TelephonyKit';
import { formatDateAdvanced } from '../utils/formatDateAdvanced';

function generateCSV(items: RecordItem[]): string {
  const header = ['id', 'amount', 'unit', 'tag', 'note', 'date', 'selectimageUriedImage'];
  let result = header.join(',') + '\n';

  items.forEach(item => {
    const row = [
      item.id,
      item.amount,
      item.unit,
      item.tag,
      item.note ?? '',
      item.date,
      item.selectimageUriedImage ?? ''
    ];
    result += row.map(field => `"${field}"`).join(',') + '\n';
  });

  return result;
}

async function saveCSVToSandbox(fileName: string, content: string): Promise<string> {
  const context = getContext();
  const dirPath = `${context.filesDir}/csvExports`;
  const filePath = `${dirPath}/${fileName}`;

  const exists = fs.accessSync(dirPath, fs.AccessModeType.EXIST);
  if (!exists) {
    await fs.mkdir(dirPath);
  }

  const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
  await fs.write(file.fd, content);
  await fs.close(file.fd);

  return filePath;
}


@Entry
@ComponentV2
export struct exporter {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  public exportAndShare() {
    const csv = generateCSV(this.ledgerManager.activeBook.data.items);

    saveCSVToSandbox(`${this.ledgerManager.activeBook.name}${formatDateAdvanced(new Date, "YY-MM-DD")}.csv`, csv)
      .then(filePath => {
        const csvType = utd.getUniformDataTypeByFilenameExtension('.csv');
        let data = new systemShare.SharedData({
          utd: csvType,
          uri: fileUri.getUriFromPath(filePath)
        });


        const uiContext = this.getUIContext();
        const context = uiContext.getHostContext() as common.UIAbilityContext;
        const controller = new systemShare.ShareController(data);

        controller.on('dismiss', () => {
          console.info('✅ 分享面板已关闭');
        });

        controller.show(context, {
          previewMode: systemShare.SharePreviewMode.DETAIL,
          selectionMode: systemShare.SelectionMode.SINGLE,
          excludedAbilities: [systemShare.ShareAbilityType.PRINT] // 屏蔽打印按钮
        });
      });
  }

  build() {
    Button().onClick((event: ClickEvent) => {
      this.exportAndShare()
    })
  }
}

