import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../models/recordItemReference"

import { safeCalculate } from '../utils/safeCalculate';
import { UserSetting } from "../models/userSetting"
import { findFlag } from '../utils/FindCountryFlags';
import { it } from '@ohos/hypium';
import { CustomContentDialog } from '@kit.ArkUI';

const RECORDS_DATA_KEY = 'incomeExpenseRecords';

//规定普通title样式
@Extend(Text)
function secondTitle() {
  .fontSize(24)
  .margin({ bottom: 10 })
}

@Styles
function basicCard() {
  .width('100%')
  .padding(12)
  .backgroundColor($r("app.color.Basic_Card_background"))
  .borderRadius(24)
  .margin({ bottom: 12 })

}

@Entry
@Component
struct AddRecordPage {
  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text("Privacy Information").fontWeight(FontWeight.Bold).fontSize(20)

            Button({ type: ButtonType.Circle }) {
              Image($r('app.media.right_arrow')).width(24).height(24).margin({ left: 2 })
            }
            .width(40)
            .height(40)
            .backgroundColor($r('app.color.Basic_Card_background'))
            .onClick((event: ClickEvent) => {
              router.back()
            })
          }.justifyContent(FlexAlign.SpaceBetween)
          .width("100%")
          .margin({ bottom: 12 })

          Column() {
            Text(" " +
              "Privacy Information" +
              "") {
            }.fontSize(15)
          }.basicCard()

        }.width("90%").borderRadius(24).alignItems(HorizontalAlign.Start)
      }

    }
    .sticky(StickyStyle.Header)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .height("100%")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .alignListItem(ListItemAlign.Center)

  }
}