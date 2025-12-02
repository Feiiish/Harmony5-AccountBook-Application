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
            Text("使用指导").fontWeight(FontWeight.Bold).fontSize(20)

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
            Row() {
              Text('导语')
            }.width('100%')

            Row() {
              Text('本App专为多货币管理而打造。帮助用户快速管理资产, 查看汇率等。')
                .fontSize(15)
            }
          }.basicCard()

          Column() {
            Row() {
              Text('添加账单')
            }.width('100%')

            Row() {
              Text('底部导航栏提供录入日常账单的入口,在收支页面输入数字即可记录对应的金额,输入正数为收入, 输入负数为支出.')
                .fontSize(15)
            }

            Row() {
              Text('金额输入框支持简单的四则运算 点击货币一栏即可更换货币单位.')
                .fontSize(15)
            }

            Row() {
              Text('在收支页面选择一个标签后, 点击标签的垃圾桶图表可以删除标签')
                .fontSize(15)
            }
          }.basicCard().alignItems(HorizontalAlign.Start)

          Column() {
            Row() {
              Text('预算')
            }.width('100%')

            Row() {
              Text('通过在预算页面设置金额来创建预算或者存款计划. 输入正数是存款计划, 输入负数是预算.')
                .fontSize(15)
            }

            Row() {

              Text('如果在创建预算时选择了标签, 则此预算只会计算带有当前标签的记录')
                .fontSize(15)

            }

            Row() {

              Text('默认情况下预算只会计算当前货币的记录, 如果打开计算所有币种,则会换算所有记录.')
                .fontSize(15)
            }

          }.basicCard().alignItems(HorizontalAlign.Start)

          Column() {
            Row() {
              Text('多货币  ')
            }.width('100%')

            Row() {
              Text('在应用的图表界面可以查看不同货币兑换本位币的比值, 也可以在货币页面查看汇率.')
                .fontSize(15)
            }

            Row() {
              Text('货币页面提供了货币信息和分布状态')
                .fontSize(15)
            }

          }.basicCard().alignItems(HorizontalAlign.Start)


          Column() {
            Row() {
              Row() {
                Text('云端和备份')
              }.width('100%')

            }

            Row() {

              Text('登陆后用户可以使用云端上传和下载功能.用户可以将当前账本中的最新文字数据上传到云端. 并且跨设备下载')
                .fontSize(15)
            }

            Row() {
              Text('用户可以随时导出当前账本为csv格式的文本文件. 同时用户可以导入相同格式的csv文件到当前账本.')
                .fontSize(15)
            }

            Row() {

              Text('图片不会保存到云端或是被导出到csv格式')
                .fontSize(15)
            }

          }.basicCard().alignItems(HorizontalAlign.Start)

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