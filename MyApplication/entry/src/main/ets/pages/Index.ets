//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import i18n from '@ohos.i18n'

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { RecordItem, RecordsData } from '../models/recordItemReference';
import { MultiCurrencyComposition } from '../components/multiCurrency';
import { UserSetting } from "../models/userSetting"
import { WeeklyChart, calculateWeeklyData } from "../components/charts/weeklyChart"
import { ratesStatus } from "../components/RatesStatus"

//components
import { BottomNavigation } from "../components/bottomNavi"
import { RecordListView, MonthlySummaryPanel } from '../components/mainPageComponents';
import { MonthPickerComponent, } from '../components/buttons/DataMonthManager';
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
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'incomeExpenseRecords',
    () => new RecordsData()
  )!;
  @Local
  choosedData: RecordsData = PersistenceV2.connect(
    RecordsData,
    'choosedRecords',
    () => new RecordsData()
  )!;

  @Monitor('choosedData.items')
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

  private async fetchRate() {
    this.tempMessage = "约为" + this.userSetting.preferredCurrency +
    (await calculateTotalAssets(this.choosedData.items, this.userSetting.preferredCurrency)).toFixed(2).toString()
  }

  //SideBar
  @Local active: number = 0;
  @Local show: boolean = false;
  @Local menuItems: string[] = [
    '货币设置',
    '删除记录',
    '隐私政策',
  ];

  handleMenuItemClick(item: string) {
    switch (item) {
      case "货币设置":
        router.pushUrl({
          url: "pages/CurrencySetting"
        }, router.RouterMode.Standard, (err) => {
          if (err) {
            console.log("跳转失败:", err)
          }
        })
        console.log('执行货币设置');
        break;
      case "删除记录":
        AlertDialog.show({
          title: `要删除记录吗`,
          message: `此操作不可退回`,
          buttons: [
            {
              value: '取消',
              action: () => {
              }
            },
            {
              value: '确认',
              action: () => {
                this.recordsData.items = []
                this.choosedData.items = []
                console.log('执行删除操作');
              }
            },
          ]
        })

        break;

      case "隐私政策":
        router.pushUrl({
          url: "pages/AboutThisApp"
        }, router.RouterMode.Standard, (err) => {
          if (err) {
            console.log("跳转失败:", err)
          }
        })
        break;
      // 其他case...
    }
  }

  private getMenuItemIcon(item: string): string {
    const iconMap: Record<string, string> = {
      '货币设置': '️💴',
      '删除记录': '🗑️',
      '分享记录': '↗️',
      '隐私政策': '🔒',
      '设置': '⚙️',
      '帮助': '❓',
      '关于应用': 'ℹ️'
    };
    return iconMap[item] || '▪️'; // 默认符号
  }

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


              Column().height(250).width("100%").backgroundColor(Color.Gray)
                .margin({ bottom: 14 })

              ratesStatus()

              ForEach(this.menuItems, (item: string, index: number) => {
                Column() {
                  Row() {
                    // 图标（使用Unicode符号）
                    Text(this.getMenuItemIcon(item))
                      .fontSize(20)
                      .margin({ right: 12 })
                      .fontColor('#007AFF')
                    // 文字
                    Text(item)
                      .fontSize(16)
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

                    this.show = !this.show
                    this.getUIContext().animateTo({
                      duration: Constants.ANIMATION_DURATION,
                      curve: Curve.EaseOut,
                      playMode: PlayMode.Normal,
                    }, () => {
                      // 动画完成后的回调
                    })
                  })

                  if (index < this.menuItems.length - 1) {
                    Divider()
                      .strokeWidth(1)
                      .color('#F0F0F0')
                      .margin({ left: 24, right: 46 }) // 与图标对齐
                  }
                }
              })
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
      .backgroundColor($r("app.color.Basic_Card_background"))
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


                      MonthPickerComponent()
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
                    MonthlySummaryPanel({ recordList: this.choosedData.items })
                    WeeklyChart({ data: this.weeklyData })

                    RecordListView({ recordList: this.choosedData.items })

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