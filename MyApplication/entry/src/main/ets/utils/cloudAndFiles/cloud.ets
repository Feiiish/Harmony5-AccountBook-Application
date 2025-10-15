import { cloudDatabase } from '@kit.CloudFoundationKit';
import { CloudRecord } from '../../models/CloudRecord'; // xx是BookInfo文件的相对路径
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { http } from '@kit.NetworkKit';
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { authentication } from '@kit.AccountKit';
import { UserSetting } from "../../models/userSetting"
import { util } from '@kit.ArkTS';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager } from '../../models/recordItemReference';

let databaseZone = cloudDatabase.zone('QuickStartDemo');
let condition = new cloudDatabase.DatabaseQuery(CloudRecord);

@ComponentV2
export struct cloudData {
  @Local newFound: number = 0;
  @Local recFound: number = 0
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  public askToUpsert() {
    this.getUIContext().showAlertDialog({
      title: '上传到云端 ☁️',
      message: `是否将账本 ${this.ledgerManager.activeBook.name} 上传到云端？ \n图片会保存在本地`,
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('用户取消');
        }
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          this.upsertWholeBook()
        }
      }
    });

  }

  public askToDownload() {
    this.queryAll().then((newRecs) => {
      this.getUIContext().showAlertDialog({
        title: '从云端下载账单 ☁️',
        message: `云端中存在 ${this.ledgerManager.activeBook.name} 的${this.recFound}条记录 \n其中${this.newFound}条新记录 \n是否下载到本地`,
        primaryButton: {
          value: '取消',
          action: () => {
            console.info('用户取消');
          }
        },
        secondaryButton: {
          value: '确定',
          action: () => {
            this.saveTheRecord(newRecs)
          }
        }
      });
    })

  }

  saveTheRecord(cloudRecs: CloudRecord[]) {
    cloudRecs.forEach((rec) => {
      if (rec.fromBookID === this.ledgerManager.activeBookId) {
        const newRec = new RecordItem()
        if (rec.id !== undefined) {
          newRec.id = rec.id;
        }
        if (rec.amount !== undefined) {
          newRec.amount = rec.amount;
        }
        if (rec.unit !== undefined) {
          newRec.unit = rec.unit;
        }
        if (rec.tag !== undefined) {
          newRec.tag = rec.tag;
        }
        if (rec.note !== undefined) {
          newRec.note = rec.note;
        }
        if (rec.date !== undefined) {
          newRec.date = rec.date;
        }
        if (rec.selectimageUriedImage !== undefined) {
          newRec.selectimageUriedImage = rec.selectimageUriedImage;
        }
        this.ledgerManager.activeBook.data.items.push(newRec)
      }

    })
  }

  async queryAll(): Promise<CloudRecord[]> {
    try {
      this.recFound = 0
      this.newFound = 0
      const bookId = this.ledgerManager.activeBookId;
      const condition = new cloudDatabase.DatabaseQuery(CloudRecord);
      condition.equalTo('fromBookID', bookId);

      const resultArray = await databaseZone.query(condition);
      this.recFound = resultArray.length
      hilog.info(0x0000, 'queryAll',
        `✅ 查询成功， BookID ${bookId}, 结果如下：\n${JSON.stringify(resultArray, null, 2)}`);

      const localIds = this.ledgerManager.activeBook.data.items.map(item => item.id);
      const uniqueCloudRecords = resultArray.filter(rec => !localIds.includes(rec.id!));
      this.newFound = uniqueCloudRecords.length
      return uniqueCloudRecords;
    } catch (err) {
      hilog.error(0x0000, 'queryAll', `❌ 查询失败\n错误码: ${err.code}\n错误信息: ${err.message}`);
      return [];
    }
  }

  async upsertWholeBook() {
    try {
      const items = this.ledgerManager.activeBook.data.items;

      for (const record of items) {
        // 构造查询条件：按主键 ID 查找是否已存在
        const condition = new cloudDatabase.DatabaseQuery(CloudRecord);
        condition.equalTo('id', record.id);

        // 如果记录不存在，则插入；否则更新
        let newRecord = new CloudRecord();
        newRecord.fromBookID = this.ledgerManager.activeBookId;
        newRecord.id = record.id;
        newRecord.amount = record.amount;
        newRecord.unit = record.unit;
        newRecord.tag = record.tag;
        newRecord.note = record.note;
        newRecord.date = record.date;
        newRecord.selectimageUriedImage = record.selectimageUriedImage;
        newRecord.fromAccount = "For test now"
        // check if logged in, use union ID

        const resultArray = await databaseZone.query(condition);

        if (resultArray.length === 0) {
          // 云端没有这条记录 → 执行 upsert（或 insert）
          let result = await databaseZone.upsert(newRecord);
          hilog.info(0x0000, 'upsert', `新增记录写入成功: ${JSON.stringify(result)}`);
        } else {
          // 云端已有这条记录 → 可以跳过或执行 update（如果你想覆盖）
          hilog.info(0x0000, 'upsert', `记录已存在，跳过: ${record.id}`);
        }
      }
      promptAction.showToast({
        message: "记录同步成功",
      });
      hilog.info(0x0000, 'upsert', '所有记录已成功同步到云端');
    } catch (err) {
      promptAction.showToast({
        message: `同步失败: ${err.code}, ${err.message}`,
      });
      hilog.error(0x0000, 'upsert', `同步失败: ${err.code}, ${err.message}`);
    }
  }

  build() {
    Column() {
      Text("数据同步中")
      Button("WholeBookUpsert").onClick((event: ClickEvent) => {
        this.upsertWholeBook()
        this.queryAll()
      })
    }

  }
}



