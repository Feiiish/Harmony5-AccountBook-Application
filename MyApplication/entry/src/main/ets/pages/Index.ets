//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';
import { MultiCurrencyComposition } from '../components/multiCurrency';
import { UserSetting } from "../models/userSetting"
import { WeeklyChart, calculateWeeklyData } from "../components/charts/weeklyChart"

//components
import { BottomNavigation } from "../components/bottomNavi"
import { RecordListView, MonthlySummaryPanel } from '../components/mainPageComponents';
import { menuButtons } from '../components/menuButtons';
import { budgetComponent } from '../components/bugetComponent';

import { searchBarView } from '../components/searchBar';
import { datePicker } from '../components/buttons/MonthPicker';
import { Constants } from '../common/Constants';
import { resourceManager } from '@kit.LocalizationKit';
import { formatDateAdvanced } from '../utils/formatDateAdvanced';

// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});


@Entry
@Preview
@ComponentV2
struct Index {
  @Local weeklyData: number[] = [];
  @Local currentTabIndex: number = 0
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local recordsData: RecordsData = this.ledgerManager.activeBook.data


  @Local
  tomonthRecords: RecordsData = PersistenceV2.connect(
    RecordsData,
    'tomonthRecords',
    () => new RecordsData()
  )!;

  @Monitor('tomonthRecords.items')
  onItemsChange(monitor: IMonitor) {
    console.log("Items changed");
    this.UpdateThings()
  }

  private async UpdateThings() {
    this.weeklyData = await calculateWeeklyData(this.recordsData.items, this.userSetting.preferredCurrency)
  }

  @Local
  userSetting: UserSetting = PersistenceV2.connect(// 本地持久化用户设置
    UserSetting,
    "userSetting",
    () => new UserSetting()
  )!;

  aboutToAppear(): void {
    this.UpdateThings()
    console.log(new Date().toDateString());
    console.log(formatDateAdvanced(new Date(), "DD"));

  }

  onPageShow(): void {
    this.UpdateThings()
  }

  @Local
  tempMessage: string = ""
  /*
  private async fetchRate() {
    this.tempMessage = "约为" + this.userSetting.preferredCurrency +
    (await calculateTotalAssets(this.tomonthRecords.items, this.userSetting.preferredCurrency)).toFixed(2).toString()
  }
  * */

  //SideBar
  @Local active: number = 0;
  @Local show: boolean = false;

  build() {

    SideBarContainer(SideBarContainerType.Overlay) {

      //边栏内容
      Column() {

        List() {
          ListItem() {
            //边栏菜单
            Column() {
              Row() {
                Image($r('app.media.right_arrow'))
                  .width(24)
                  .height(25)
                  .onClick(() => {
                    this.show = false
                    this.getUIContext().animateTo({
                      duration: Constants.ANIMATION_DURATION,
                      curve: Curve.EaseOut,
                      playMode: PlayMode.Normal,
                    }, () => {
                    })
                  })
              }.width("90%").margin({ bottom: 14 }).justifyContent(FlexAlign.Start)

              //login component
              Column() {
                Column()
                  .width(120)
                  .height(120)
                  .backgroundColor(Color.Gray)

                  .borderRadius(150)
                  .onClick(() => {
                    router.pushUrl({
                      url: "pages/HuaweiLogin"
                    }, router.RouterMode.Standard, (err) => {
                      if (err) {
                        console.log("跳转失败:", err)
                      }
                    })
                  })
                Text('未登录').padding({ top: 15 })
              }
              .justifyContent(FlexAlign.Center)
              .height(180)
              .width("100%")

              menuButtons()


            }
            .borderRadius(8)
            .clip(true)
          }
        }
        .sticky(StickyStyle.Header)
        .scrollBar(BarState.Off)
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.Spring)
        .height("100%")

      }
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 14 })
      .backgroundColor($r("app.color.Darker_window_background"))
      .width(272)
      .height(344)
      .borderRadius(20)

      //主要内容
      Column() {
        Stack({ alignContent: Alignment.Bottom }) {
          Tabs({ barPosition: BarPosition.End }) {
            TabContent() {

              List() {
                ListItem() {

                  Column({ space: 2 }) {

                    //顶栏
                    Row() {
                      datePicker()
                      //抽屉开关
                      Button({ type: ButtonType.Circle, stateEffect: true }) {
                        Image($r('app.media.moreMenu')).width(35).height(35).align(Alignment.Center)
                      }
                      .backgroundColor($r('app.color.Basic_Card_background'))
                      .width(40)
                      .height(40)
                      .onClick(() => {

                        this.show = !this.show
                        this.getUIContext().animateTo({
                          duration: Constants.ANIMATION_DURATION,
                          curve: Curve.EaseOut,
                          playMode: PlayMode.Normal,
                        }, () => {
                          // 动画完成后的回调
                        })
                      })
                    }
                    .justifyContent(FlexAlign.SpaceBetween)
                    .width("90%")
                    .margin({ bottom: 18 })
                    .height(40)

                    //########
                    MonthlySummaryPanel({ recordList: this.tomonthRecords.items })
                      .transition(
                        TransitionEffect.OPACITY
                          .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 }))
                          .animation({ duration: 500, curve: Curve.FastOutSlowIn })
                      );
                    WeeklyChart({ data: this.weeklyData })
                      .transition(
                        TransitionEffect.OPACITY
                          .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 }))
                          .animation({ duration: 500, curve: Curve.FastOutSlowIn })
                      );

                    // RecordListView({ recordList: this.choosedData.items })
                    searchBarView({ recordList: this.tomonthRecords.items })
                      .transition(
                        TransitionEffect.OPACITY
                          .combine(TransitionEffect.scale({ x: 0.8, y: 0.8 }))
                          .animation({ duration: 500, curve: Curve.FastOutSlowIn })
                      );
                  }.padding(12)
                }
              }
              .sticky(StickyStyle.Header)
              .scrollBar(BarState.Off)
              .listDirection(Axis.Vertical)
              .edgeEffect(EdgeEffect.Spring)
              .height("100%")

            }.tabBar('首页')


            TabContent() {
              List() {
                ListItem() {
                  Column({ space: 2 }) {
                    budgetComponent()

                    MultiCurrencyComposition({ recordList: this.recordsData.items })
                  }
                }.padding(10)
              }
              .sticky(StickyStyle.Header)
              .scrollBar(BarState.Off)
              .listDirection(Axis.Vertical)
              .edgeEffect(EdgeEffect.Spring)
              .height("100%")

            }.tabBar('我的')
          }

          // BottomNavigation()
          Image($r('app.media.add'))
            .width(80)
            .height(80)
            .onClick(() => {
              router.pushUrl({
                url: "pages/AddRecordPage"
              }, router.RouterMode.Standard, (err) => {
                if (err) {
                  console.log("跳转失败:", err)
                }
              })
            })
            .backgroundColor(Color.White)
            .borderRadius(66)


        }.height("100%")

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

    }
    .sideBarPosition(SideBarPosition.End)
    .showSideBar(this.show)
    .showControlButton(false)

    .onChange((value: boolean) => {
      this.show = value;
    })
    .backgroundColor($r("app.color.start_window_background"))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

  }
}