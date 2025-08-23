//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';

//from myself
import { calculateTotalAssets, } from "../utils/moneyCount"
import { RecordItem, RecordsData } from '../models/recordItemReference';
import { MultiCurrencyComposition } from '../components/multiCurrency';
import { UserSetting } from "../models/userSetting"
import { WeeklyChart } from "../components/charts/weeklyChart"
import { displayExchangeRates } from "../utils/currencyExchange"

//components
import { BottomNavigation } from "../components/bottomNavi"
import { RecordListView, MonthlySummaryPanel } from '../components/MainPageComponents';
import { PopupComponent } from '../components/buttons/MenuPopup';
import { MonthPickerComponent, } from '../components/buttons/MonthPickerComponent';
import { DrawerTab } from "../components/DrawerTab"

import { Constants } from '../common/Constants';
// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});


@Entry
@Preview
@ComponentV2
struct Index {
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
  @Local
  userSetting: UserSetting = PersistenceV2.connect(// 本地持久化用户设置
    UserSetting,
    "userSetting",
    () => new UserSetting()
  )!;

  onPageShow(): void {
    this.userSetting.chosenCurrency = ["CNY", "CAD", "USD", "JPY"]


  }

  @Local
  tempMessage: string = ""
  @Local weeklyData: number[] = [140, -85, 100, -88, 150, -150, -180];

  private async fetchRate() {
    this.tempMessage = "约为" + this.userSetting.preferredCurrency +
    (await calculateTotalAssets(this.choosedData.items, this.userSetting.preferredCurrency)).toFixed(2).toString()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {


      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {

          List() {
            ListItem() {

              Column({ space: 2 }) {

                //顶栏
                Row() {
                  PopupComponent()
                  MonthPickerComponent()


                }.justifyContent(FlexAlign.SpaceBetween).width("90%").margin({ bottom: 18 })

                MonthlySummaryPanel({
                  recordList: this.choosedData.items
                })

                MultiCurrencyComposition({ recordList: this.recordsData.items })

                RecordListView({ recordList: this.choosedData.items })

                Button().onClick((event: ClickEvent) => {
                  this.fetchRate();
                  console.log("14141414141414")
                })
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

          Column({ space: 2 }) {
            WeeklyChart({ data: this.weeklyData })
          }.padding(10)

        }.tabBar('我的')
      }

      BottomNavigation()
      DrawerTab()

    }.height("100%")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r("app.color.start_window_background"))

  }
}