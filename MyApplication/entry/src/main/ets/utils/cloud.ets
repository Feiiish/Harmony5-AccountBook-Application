import { cloudDatabase } from '@kit.CloudFoundationKit';
import { record } from '../models/record'; // xx是BookInfo文件的相对路径
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { http } from '@kit.NetworkKit';
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { authentication } from '@kit.AccountKit';
import { UserSetting } from "../models/userSetting"
import { util } from '@kit.ArkTS';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';

let databaseZone = cloudDatabase.zone('QuickStartDemo');
let condition = new cloudDatabase.DatabaseQuery(record);

@ComponentV2
export struct cloudData {
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

  async queryAll() {
    try {
      let resultArray = await databaseZone.query(condition);
      hilog.info(0x0000, 'testTag', `Succeeded in querying data, result: ${JSON.stringify(resultArray)}`);
    } catch (err) {
      hilog.error(0x0000, 'testTag', `Failed to query data, code: ${err.code}, message: ${err.message}`);
    }
  }

  async upsert() {
    try {
      this.ledgerManager.activeBook.data.items.forEach((record) => {

        //if record.id is not in database
        //updert data from active book

      })

      // 创建一个新的 record 对象
      let newRecord = new record();
      newRecord.id = 'abb'; // 示例字段
      newRecord.amount = 100; // 示例字段
      newRecord.unit = 'CNY';
      newRecord.tag = 'nihao';
      newRecord.note = '测试';
      newRecord.date = (new Date).toISOString();
      newRecord.selectimageUriedImage = ""
      
      // 写入数据库（如果主键已存在则更新）
      let result = await databaseZone.upsert(newRecord);
      hilog.info(0x0000, 'testTag', `写入成功: ${JSON.stringify(result)}`);
    } catch (err) {
      hilog.error(0x0000, 'testTag', `写入失败: ${err.code}, ${err.message}`);
    }
  }

  build() {
    Column() {
      Text("数据同步中")
      Button().onClick((event: ClickEvent) => {
        this.upsert()
        this.queryAll()
      })
    }

  }
}



