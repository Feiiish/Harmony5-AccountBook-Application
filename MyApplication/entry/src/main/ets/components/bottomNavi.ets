import { router } from "@kit.ArkUI"


@ComponentV2
export struct BottomNavigation {
  @Event currentTab: number // 当前选中的Tab索引

  build(){
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
