import { RecordItem, RecordsData, filterRecordItems, BudgetItem, LedgerManager } from "../models/recordItemReference"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { UserSetting } from "../models/userSetting"
import { TipsDialog } from '@kit.ArkUI'
import { emitter, Callback } from '@kit.BasicServicesKit';


@ComponentV2
export struct recordDeleter {
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  public deleteDataFromAll(item: RecordItem) {

    if (!this.ledgerManager.activeBook.data) {
      promptAction.showToast({ message: '数据连接失败，无法删除记录' });
      return;
    }

    const index = this.ledgerManager.activeBook.data.items.findIndex(record =>
    record.id === item.id
    );

    if (index !== -1) {
      if (this.ledgerManager.activeBook.data) {
        this.ledgerManager.activeBook.data.items =
          this.ledgerManager.activeBook.data.items.filter((item, i) => i !== index);
      }
      // filter
    } else {
      promptAction.showToast({ message: '未找到指定记录，无法删除' });
    }
  }

  public deleteBudgetFromAll(budget: BudgetItem) {

    if (!this.ledgerManager.activeBook.data) {
      promptAction.showToast({ message: '数据连接失败，无法删除记录' });
      return;
    }

    const index = this.ledgerManager.activeBook.data.budgets.findIndex(bud =>
    bud.id === budget.id
    );

    if (index !== -1) {
      if (this.ledgerManager.activeBook.data) {
        this.ledgerManager.activeBook.data.budgets =
          this.ledgerManager.activeBook.data.budgets.filter((item, i) => i !== index);
      }
      // filter
    } else {
      promptAction.showToast({ message: '未找到指定记录，无法删除' });
    }
  }

  build() {

  }
}





