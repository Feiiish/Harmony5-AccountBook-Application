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
import { avatarControl } from "../../components/buttons/avatarControl"
import {
  PreviewLoginButtonPage
} from '../../pages/HuaweiLogin'
import { ifaa } from '@kit.OnlineAuthenticationKit';
import auth from '@hw-agconnect/auth';

let databaseZone = cloudDatabase.zone('QuickStartDemo');
let condition = new cloudDatabase.DatabaseQuery(CloudRecord);

@ComponentV2
export struct cloudData {
  @Local newFound: number = 0;
  @Local recFound: number = 0
  @Local unionID: string = ""
  @Local avatar: avatarControl = new avatarControl
  @Local
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

    this.avatar.checkLoginStatus().then((res) => {
      if (res) {
        this.unionID = this.avatar.UnionID
        promptAction.showToast({ message: "查询记录中, 请稍后" });
        this.upsertWholeBook()

      } else {
        promptAction.showToast({ message: "请登录账号" });
      }
    }).catch((error: BusinessError) => {
      hilog.error(0x0000, 'testTag', `getCurrentUser error: ${error.message}`);
    });

  }

  async upsertWholeBook() {
    try {

      // 查询当前账本记录是否已存在
      const items = this.ledgerManager.activeBook.data.items;
      const allIds = items.map(item => item.id);
      const existQuery = new cloudDatabase.DatabaseQuery(CloudRecord);
      existQuery.in('id', allIds);
      const existingCloudRecords = await databaseZone.query(existQuery);
      const existingIdSet = new Set(existingCloudRecords.map(r => r.id));

      const newRecords: CloudRecord[] = [];
      const existingRecords: CloudRecord[] = [];

      for (const record of items) {
        const newRecord = new CloudRecord();
        newRecord.fromBookID = this.ledgerManager.activeBookId;
        newRecord.id = record.id;
        newRecord.amount = record.amount;
        newRecord.unit = record.unit;
        newRecord.tag = record.tag;
        newRecord.note = record.note;
        newRecord.date = record.date;
        newRecord.selectimageUriedImage = record.selectimageUriedImage;
        newRecord.fromAccount = this.unionID;

        if (!existingIdSet.has(record.id)) {
          newRecords.push(newRecord);
        } else {
          existingRecords.push(newRecord);
        }
      }

      // 弹窗确认
      const message =
        `发现 ${newRecords.length} 条新记录 \n是否上传并删除云端旧项？`;
      this.getUIContext().showAlertDialog({
        title: `上传账本 ${this.ledgerManager.activeBook.name}`,
        message: message,
        primaryButton: {
          value: '取消',
          action: () => {
            hilog.info(0x0000, 'upsert', '用户取消了上传操作');
          }
        },
        secondaryButton: {
          value: '确定上传',
          action: async () => {

            //处理本地垃圾
            try {
              const trashIds = this.ledgerManager.cloudTrashBin;
              if (Array.isArray(trashIds) && trashIds.length > 0) {
                const query1 = new cloudDatabase.DatabaseQuery(CloudRecord);
                query1.in('id', trashIds);
                const query2 = new cloudDatabase.DatabaseQuery(CloudRecord);
                query2.in('fromBookID', trashIds);
                const result1 = await databaseZone.query(query1);
                const result2 = await databaseZone.query(query2);

                if (result1.length > 0) {
                  await databaseZone.delete(result1);
                }

                if (result2.length > 0) {
                  await databaseZone.delete(result2);
                }
              }
            } catch (err) {
              hilog.error(0x0000, 'testTag', `删除失败，code: ${err.code}, message: ${err.message}`);
            }

            promptAction.showToast({ message: "尝试上传记录" });

            const uploadResults = await Promise.all(
              newRecords.map(record => databaseZone.upsert(record))
            );

            promptAction.showToast({ message: `${uploadResults.length} 条记录已上传` });
            hilog.info(0x0000, 'upsert', '所有记录已成功同步到云端');
          }
        }

      });
    } catch (err) {
      promptAction.showToast({
        message: `同步失败: ${err.code}, ${err.message}`,
      });
      hilog.error(0x0000, 'upsert', `同步失败: ${err.code}, ${err.message}`);
    }
  }

  build() {

  }
}



