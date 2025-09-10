import { router } from "@kit.ArkUI"

@Preview
@ComponentV2
export struct BottomNavigation {
  build() {
    Stack() {


      Circle()
        .fill(Color.Gray)
        .width(60)
        .height(60)


      Text('＋')
        .fontSize(64)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          router.pushUrl({
            url: "pages/AddRecordPage"
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.log("跳转失败:", err)
            }
          })
        })
    }.width("40%")
  }
}
