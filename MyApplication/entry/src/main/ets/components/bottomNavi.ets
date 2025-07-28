import { router } from "@kit.ArkUI"


@ComponentV2
export struct BottomNavigation {
  @Event currentTab: number // 当前选中的Tab索引

  build() {
    // 外层用Stack实现悬浮效果
    Stack() {
      // 底部导航栏主体
      Row() {
        // 左侧Tab（首页）
        Column() {
          Text('首页')
            .fontSize(this.currentTab === 0 ? 16 : 14)
            .fontColor(this.currentTab === 0 ? '#007AFF' : '#666666')
            .fontWeight(this.currentTab === 0 ? FontWeight.Bold : FontWeight.Normal)
        }
        .onClick(() => {
          this.currentTab = 0
        })
        .layoutWeight(1) // 平分剩余空间
        .height(64)
        .justifyContent(FlexAlign.Center)

        // 中间占位空间（为"+"按钮预留位置）
        Column()
          .width(80)// 与"+"按钮宽度匹配
          .height(64)

        // 右侧Tab（统计）
        Column() {
          Text('统计')
            .fontSize(this.currentTab === 1 ? 16 : 14)
            .fontColor(this.currentTab === 1 ? '#007AFF' : '#666666')
            .fontWeight(this.currentTab === 1 ? FontWeight.Bold : FontWeight.Normal)
        }
        .onClick(() => {
          this.currentTab = 1
        })
        .layoutWeight(1) // 平分剩余空间
        .height(64)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 40, color: '#20000000' })

      // 悬浮在中间的"+"按钮

      Text('＋')
        .backgroundColor(Color.Gray)
        .fontSize(55)
        .padding(4)
        .borderRadius(75)
        .onClick(() => {
          router.pushUrl({
            url: "pages/AddRecordPage"
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.log("跳转失败:", err)
            }
          })
        })

    }
  }
}
