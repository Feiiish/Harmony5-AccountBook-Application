//from system
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';

//from myself
import { calculateTotalAssets, calculateMonthlySummary } from "../utils/moneyCount"
import { RecordItem, RecordsData } from '../models/recordItemReference';
import { displayExchangeRates } from '../utils/currencyExchange';
import { MultiCurrencyComposition } from '../components/multiCurrency';
import { UserSetting } from "../models/userSetting"
import {WeeklyChart} from "../components/charts/weeklyChart"

//components
import { BottomNavigation } from "../components/bottomNavi"
import { MonthlySummary, RecordListView } from '../components/MainPageComponents';
import { PopupComponent } from '../components/MenuPopup';


// 接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
});


const RECORDS_DATA_KEY = 'incomeExpenseRecords';

//获取指定货币的汇率
displayExchangeRates("USD")


@Entry
@ComponentV2
struct Index {
  @Local currentTabIndex: number = 0
  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    RECORDS_DATA_KEY,
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

  @Local weeklyData: number[] = [12440, 85, 2800, 65, 4150, 3050, 180];


  private async fetchRate() {
    this.tempMessage = "约为" + this.userSetting.preferredCurrency +
    (await calculateTotalAssets(this.recordsData.items, "CNY")).toFixed(2).toString()
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
                  Text('日期选择 ↓')
                    .fontSize(25)
                    .fontWeight(FontWeight.Bold)

                  PopupComponent()

                }.justifyContent(FlexAlign.SpaceBetween).width("90%").margin({ bottom: 18 })

                MonthlySummary({
                  totalAmount: this.tempMessage
                })

                MultiCurrencyComposition({ recordList: this.recordsData.items })

                RecordListView({ recordList: this.recordsData.items })

                Button().onClick((event: ClickEvent) => {
                  this.fetchRate();
                })
              }.padding(8)

            }

          }.sticky(StickyStyle.Header)
          .scrollBar(BarState.Off)
          .listDirection(Axis.Vertical)
          .edgeEffect(EdgeEffect.Spring)
          .height("100%")


        }.tabBar('首页')


        TabContent() {

          WeeklyChart({ data: this.weeklyData })

        }.tabBar('我的')
      }

      BottomNavigation()


    }.height("100%")

  }
}