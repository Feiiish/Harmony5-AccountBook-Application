import { Constants } from '../common/Constants';

@Entry
@Component
export struct DrawerTab {
  @State active: number = 0;
  @State show: boolean = false;

  build() {
    SideBarContainer(SideBarContainerType.Embed) {
      Column() {
        Text("列表内容") {
        }
      }
      .height('100%')
      .padding({ top: 104 })
      .backgroundColor('#E9EAEC')
      .width(272)
      .height(344)
      .backgroundColor(Color.White)


      Column() {
        Text("App内容")

      }
      .onClick(() => {
        this.getUIContext().animateTo({
          duration: Constants.ANIMATION_DURATION,
          curve: Curve.EaseOut,
          playMode: PlayMode.Normal,
        }, () => {
          this.show = false;
        })
      })
      .width('100%')
      .height('110%')
      .blur(this.show ? 22 : 0)
    }
    .controlButton({
      left: 32,
      top: 12,
      height: 40,
      width: 40,
    })
    .onChange((value: boolean) => {
      this.show = value;
    })
  }
}