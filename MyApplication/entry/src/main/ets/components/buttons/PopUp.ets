import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../../models/recordItemReference"

const RECORDS_DATA_KEY = 'incomeExpenseRecords';

@ComponentV2
export struct PopupComponent {
  @Local handlePopup: boolean = false;
  @Local menuItems: string[] = ['编辑记录', '删除记录', '分享记录', '导出记录'];
  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    RECORDS_DATA_KEY,
    () => new RecordsData()
  )!;

  @Builder
  popupBuilder() {
    Column() {
      Text('请选择操作')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 12 })

      // 美化列表
      Column() {
        ForEach(this.menuItems, (item: string, index: number) => {
          Column() {
            // 菜单项
            Row() {
              // 图标（使用Unicode符号）
              Text(this.getMenuItemIcon(item))
                .fontSize(20)
                .margin({ right: 12 })
                .fontColor('#007AFF')

              // 文字
              Text(item)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)

              // 箭头（Unicode符号）
              if (index < this.menuItems.length - 1) {
                Text('❯')
                  .fontSize(14)
                  .fontColor('#999999')
              }
            }
            .height(48)
            .width('100%')
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.handleMenuItemClick(item);
              this.handlePopup = false;
            })


            // 分隔线（最后一项不加）
            if (index < this.menuItems.length - 1) {
              Divider()
                .strokeWidth(1)
                .color('#F0F0F0')
                .margin({ left: 44, right: 16 }) // 与图标对齐
            }
          }
        })
      }
      .width('100%')
      .borderRadius(8)
      .backgroundColor('#FFFFFF')
      .clip(true) // 确保圆角裁剪生效

      // 取消按钮
      Button('取消', { type: ButtonType.Normal })
        .width('100%')
        .height(40)
        .margin({ top: 12 })
        .fontColor('#666666')
        .backgroundColor('#F7F7F7')
        .onClick(() => {

        })
    }
    .padding(16)
    .width(280)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 16, color: '#10000000' })
  }

  // 菜单项点击处理
  handleMenuItemClick(item: string) {
    switch (item) {
      case '编辑记录':
        console.log('执行编辑操作');
        break;
      case '删除记录':

        this.recordsData.items = []

        console.log('执行删除操作');

        break;
      // 其他case...
    }
  }

  // 获取Unicode图标
  private getMenuItemIcon(item: string): string {
    const iconMap: Record<string, string> = {
      '编辑记录': '✏️',
      '删除记录': '🗑️',
      '分享记录': '↗️',
      '导出记录': '⤓',
      '设置': '⚙️',
      '帮助': '❓'
    };
    return iconMap[item] || '▪️'; // 默认符号
  }

  build() {
    Column() {
      Button("三")
        .onClick(() => {
          this.handlePopup = true;
        })
        .bindPopup(this.handlePopup, {
          builder: this.popupBuilder(),
          placement: Placement.Bottom,
          width: "300vp",
          onStateChange: (e) => {
            if (!e.isVisible) {
              this.handlePopup = false;
            }
          }
        })
    }
  }
}