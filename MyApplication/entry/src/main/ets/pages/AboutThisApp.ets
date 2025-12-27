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
            Text("隐私政策").fontWeight(FontWeight.Bold).fontSize(20)

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
            Text("全球账本 是由 A （以下简称“我们”）为您提供的，用于国际账单记录的应用。本隐私声明由我们为处理您的个人信息而制定。\n" +
              "\n" +
              "我们非常重视您的个人信息和隐私保护，将会按照法律要求和业界成熟的安全标准，为您的个人信息提供相应的安全保护措施。\n" +
              "\n" +
              "1. 我们如何收集和使用您的个人信息\n" +
              "我们仅在有合法性基础的情形下才会使用您的个人信息。根据适用的法律，我们可能会基于您的同意、为履行/订立您与我们的合同所必需、履行法定义务所必需等合法性基础，使用您的个人信息。\n" +
              "\n" +
              "1.1 我们为您提供下述实时汇率计算 在您使用相关业务的过程中，我们会处理所必需的信息，以便履行我们的合同义务若您不提供相关信息，会影响到您使用本应用的相关功能/服务。\n" +
              "\n" +
              "为了实现应用功能，在获取您的同意后我们需要收集您的交易记录、 订单信息、 其他交易信息、 账号信息、 图片或视频、 文字信息、 搜索词、 剪贴板、 其他通讯内容、 其他用户内容、 应用基本信息、 应用设置信息、 WIFI参数、 WIFI状态、 网络类型、 运营商、 IP地址 。\n" +
              "\n" +
              "2. 管理您的个人信息\n" +
              "如您对您的数据主体权利有进一步要求或存在任何疑问、意见或建议，可通过本声明中“如何联系我们”章节中所述方式与我们取得联系，并行使您的相关权利。\n" +
              "\n" +
              "3. 信息存储地点及期限\n" +
              "3.1 我们承诺，除法律法规另有规定外，我们对您的信息的保存期限应当为实现处理目的所必要的最短时间。\n" +
              "\n" +
              "3.2 上述信息将会传输并保存至中国境内的服务器。\n" +
              "\n" +
              "4. 如何联系我们\n" +
              "您可通过以下方式联系我们，并行使您的相关权利，我们会尽快回复。\n" +
              "\n" +
              "邮箱：lxin54682@gmail.com\n" +
              "\n" +
              "如果您对我们的回复不满意, 特别是当个人信息处理行为损害了您的合法权益时您还可以通过向有管辖权的人民法院提起诉讼、向行业自律协会或政府相关管理机构投诉等外部途径进行解决。 您也可以向我们了解可能适用的相关投诉途径的信息。") {
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