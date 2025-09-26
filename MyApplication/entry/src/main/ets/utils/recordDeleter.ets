import { RecordItem, RecordsData, filterRecordItems, BudgetItem } from "../models/recordItemReference"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { UserSetting } from "../models/userSetting"
import { TipsDialog } from '@kit.ArkUI'
import { emitter, Callback } from '@kit.BasicServicesKit';


@ComponentV2
export struct recordDeleter {
  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'incomeExpenseRecords',
    () => new RecordsData()
  )!;
  @Local
  userSetting: UserSetting = PersistenceV2.connect(// 本地持久化用户设置
    UserSetting,
    "userSetting",
    () => new UserSetting()
  )!;

  public deleteDataFromAll(item: RecordItem) {

    if (!this.recordsData) {
      promptAction.showToast({ message: '数据连接失败，无法删除记录' });
      return;
    }

    const index = this.recordsData.items.findIndex(record =>
    record.id === item.id
    );

    if (index !== -1) {
      if (this.recordsData) {
        this.recordsData.items = this.recordsData.items.filter((item, i) => i !== index);
      }
      // filter
    } else {
      promptAction.showToast({ message: '未找到指定记录，无法删除' });
    }
  }

  public deleteBudgetFromAll(budget: BudgetItem) {

    if (!this.recordsData) {
      promptAction.showToast({ message: '数据连接失败，无法删除记录' });
      return;
    }

    const index = this.recordsData.budgets.findIndex(bud =>
    bud.id === budget.id
    );

    if (index !== -1) {
      if (this.recordsData) {
        this.recordsData.budgets = this.recordsData.budgets.filter((item, i) => i !== index);
      }
      // filter
    } else {
      promptAction.showToast({ message: '未找到指定记录，无法删除' });
    }
  }

  build() {

  }
}





