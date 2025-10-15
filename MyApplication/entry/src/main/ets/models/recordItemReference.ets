// src/models/RecordItem.ts
import { Type } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import image from '@ohos.multimedia.image';


export interface singleCurrency {
  amount: number;
  unit: string
  rate: number
}

@ObservedV2
export class RecordItem {
  @Trace id: string = Date.now().toString(36) + Math.random().toString(36).substring(2, 9);
  @Trace amount: number = 0; // 正数=收入，负数=支出
  @Trace unit: string = 'CNY';
  @Trace tag: string = '';
  @Trace note: string = '';
  @Trace date: string = new Date().toDateString();
  @Trace selectimageUriedImage: ResourceStr = ""

  get type(): 'income' | 'expense' {
    return this.amount >= 0 ? 'income' : 'expense';
  }

  // 获取显示用绝对值金额
  get displayAmount(): number {
    return Math.abs(this.amount);
  }
}


@ObservedV2
export class BudgetItem {
  @Trace id: string = Date.now().toString(36) + Math.random().toString(36).substring(2, 9);
  @Trace name: string = '';
  @Trace tag: string = '';
  @Trace targetAmount: number = 0;
  @Trace unit: string = 'CNY';
  @Trace startDate: string = new Date().toDateString();
  @Trace endDate: string = '';
  @Trace countAll: boolean = false
  @Trace currentAmount: number = 0

  get isCompleted(): boolean {
    return this.currentAmount / this.targetAmount >= 1
  }

  get isExpired(): boolean {
    return (new Date() > new Date(this.endDate) && !this.isCompleted)
  }
}


//choose records from time to time
export function filterRecordItems(
  records: RecordItem[],
  startDate: Date,
  endDate: Date,
  unit?: string,
  tag?: string
): RecordItem[] {
  return records.filter(record => {
    const recordDate = new Date(record.date);

    const isWithinDateRange =
      recordDate >= startDate && recordDate <= endDate;

    const matchesUnit = unit ? record.unit === unit : true;
    const matchesTag = tag ? record.tag === tag : true;

    return isWithinDateRange && matchesUnit && matchesTag;
  });
}


// RecordsData.ets
@ObservedV2
export class RecordsData {
  @Type(RecordItem)
  @Trace
  items: RecordItem[] = [];

  public toMonthItems(date: Date): RecordItem[] {
    const startDate = new Date(date.getFullYear(), date.getMonth(), 1);
    const endDate = new Date(date.getFullYear(), date.getMonth() + 1, 0);

    return filterRecordItems(this.items, startDate, endDate);
  }

  @Type(BudgetItem)
  @Trace
  budgets: BudgetItem[] = [];
}


//different account book
@ObservedV2
export class LedgerBook {
  @Trace id: string = Date.now().toString(36) + Math.random().toString(36).substring(2, 9);
  @Trace name: string = '';
  @Trace createdAt: string = new Date().toISOString();
  @Type(RecordsData)
  @Trace data: RecordsData = new RecordsData();
  @Trace preferredCurrency: string = "CNY";
  @Trace chosenCurrency: string[] = ["CNY", "CAD", "USD", "JPY"];
  @Trace tags: string[] = ['餐饮', '购物', '交通', '娱乐', '住房', '工资', '奖金', '投资'];
  @Trace chosenDate: Date = new Date;
  @Trace startDate: Date = new Date;
  @Trace endDate: Date = new Date;
  @Trace cloudTrashBin: string[] = []

  clearBook() {
    this.data.items = []
  }
}


// The class of LederManager
@ObservedV2
export class LedgerManager {
  @Type(LedgerBook)
  @Trace books: LedgerBook[] = [];
  @Trace activeBookId: string = '';

  get activeBook(): LedgerBook {
    let book = this.books.find(book => book.id === this.activeBookId);
    if (!book) {
      // 创建一个默认账本
      book = new LedgerBook();
      book.name = '默认账本';
      this.books.push(book);
      this.activeBookId = book.id;
    }
    return book;
  }

  switchBook(bookId: string) {
    this.activeBookId = bookId;
  }

  addBook(name: string) {
    const newBook = new LedgerBook();
    newBook.name = name;
    this.books.push(newBook);
    this.activeBookId = newBook.id;
  }

  deleteBook(bookId: string) {
    this.books = this.books.filter(book => book.id !== bookId);
    if (this.activeBookId === bookId) {
      this.activeBookId = this.books.length > 0 ? this.books[0].id : '';
    }
  }
}
