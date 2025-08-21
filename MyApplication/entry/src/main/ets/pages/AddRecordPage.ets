import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../models/recordItemReference"
import preferences from '@ohos.data.preferences';
import { safeCalculate } from '../utils/safeCalculate';
import {UserSetting} from "../models/userSetting"
import { findFlag } from '../utils/FindCountryFlags';



const RECORDS_DATA_KEY = 'incomeExpenseRecords';

//规定普通title样式
@Extend(Text)
function secondTitle() {
  .fontSize(24)
  .margin({ bottom: 10 })
}




@Entry
@Component
struct AddRecordPage {
  @State currentTab: number = 0 // 0-收支 1-转账

  build() {
    Column() {
      // 顶部Tab栏
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          IncomePage() // 收支页面


       }.tabBar('收支')

        TabContent() {
          TransferPage() // 转账页面
        }.tabBar('转账')
      }
      .barWidth('100%')
      .barHeight(50)
      .width('100%')
      .height('100%')
      .onChange((index: number) => {
        this.currentTab = index
      })
    }
    .width('100%')
    .height('100%')

  }
}

// 收支页面组件
@ComponentV2
struct IncomePage {
  @Local message: string = "";
  @Local tempAmount: number | null = 0
  @Local couldSave: boolean = false;
  @Local showSelect: boolean = false;


  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    RECORDS_DATA_KEY,
    () => new RecordsData()
  )!;

  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    "userSetting",
    () => new UserSetting()
  )!;

  @Local tempUnit: string = this.userSetting.preferredCurrency;
  @Local tempDate: string =  new Date().toISOString();
  @Local tempTag: string = ""
  @Local tempNote: string = ""
  private tags: string[] = ['餐饮', '购物', '交通', '娱乐', '住房', '医疗', '教育', '工资', '奖金', '投资', '其他'];

  private saveRecord() {
    // 创建新记录
    const newRecord = new RecordItem();

    if (this.tempAmount !== null) {
      newRecord.amount = this.tempAmount
    }
    newRecord.unit = this.tempUnit;
    newRecord.date= this.tempDate;
    newRecord.tag = this.tempTag;
    newRecord.note = this.tempTag;

    this.recordsData.items.push(newRecord);
    // 重置表单
    this.tempAmount = 0;
    this.tempUnit = this.userSetting.preferredCurrency
    this.tempDate =  new Date().toISOString();
    this.tempTag = ""
    this.tempNote = '';



    // 数据会自动持久化，无需手动保存
    promptAction.showToast({ message: '保存成功'+ JSON.stringify(newRecord)  });
    router.back();
  }

  build() {


    Column() {
      Column({ space: 20 }) {
        // 收入/支出切换
        Row({ space: 10 }) {

          // 金额输入
          TextInput({ placeholder: '请输入金额' })
            .type(InputType.PhoneNumber)
            .width('60%')
            .height(50)
            .inputFilter("[0-9+\\-*/]", (value: string) => {
              console.log("被过滤的字符: " + value);
            })
            .onChange((value: string) => {

              this.tempAmount = safeCalculate(value);


              if (this.tempAmount == null) {

                this.message = "请输入正确表达式"
                this.couldSave = false;
              } else if(this.tempAmount < 0){
                this.message = "支出: " + JSON.stringify(this.tempAmount)
                this.couldSave = true;
              }else {

                this.message = "收入： " + JSON.stringify(this.tempAmount)
                this.couldSave = true;
              }
            })

          //currency Sign
          Row({ space: 4 }) {
            findFlag({flagName: this.tempUnit})

          }.onClick(() => {
            TextPickerDialog.show({

              range: this.userSetting.chosenCurrency,defaultPickerItemHeight: 36,
              canLoop: false,
              onAccept:(value: TextPickerResult) =>{
                this.tempUnit = value.value as string
            }
            })
          })
        }.margin({ top: 20 })


        //record message
        Text(this.message)

        Column() {
          Row() {
            Text("时间").secondTitle()
            CalendarPicker({ hintRadius: 10, selected: new Date })
              .width("30%")
              .edgeAlign(CalendarAlign.CENTER, { dx: 1, dy: 1 })
              .onChange((date: Date) => {
                this.tempDate = date.toISOString();
              })


          }.width("100%")
          .justifyContent(FlexAlign.SpaceBetween)
        }

        Column() {
          Text("选择分类").secondTitle().width("100%")
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.tags, (item: string) => {
              Text(item)
                .fontSize(16)
                .fontColor(this.tempTag === item ? "#FFFFFF" : "#000000")// 选中时白色文字
                .padding("2%")
                .backgroundColor(this.tempTag === item ? "#FFCC22" : "#EFEFEF")// 选中时黄色背景
                .borderRadius(5)
                .margin({ right: 10, bottom: 10 })
                .onClick(() => {
                  if (this.tempTag === item) {
                    this.tempTag = "none"
                  } else {
                    this.tempTag = item;
                  }


                  console.log("Now the tag is " + this.tempTag)
                })
            })
          }

        }

        Column() {
          //note textInput
          Text("备注").secondTitle().width("100%")
          TextInput({ placeholder: '添加备注' })
            .height(40)
            .onChange((value: string) => {
              this.tempNote = value
            })
        }


        // 保存按钮
        Button('保存记录')
          .width('30%')
          .height(50)
          .margin(20)
          .onClick(() => {
            if (this.couldSave) {
              // 保存逻辑
              this.saveRecord()
            } else {
              promptAction.showToast({ message: '保存失败' });
            }

          })
      }.width("90%")

    }
    .width('95%')
    .height('100%')
    .borderRadius(20)


  }
}

// 转账页面组件
@Component
struct TransferPage {
  @State amount: string = ''
  @State fromAccount: string = 'CNY'
  @State toAccount: string = 'CAD'

  build() {
    Column() {
      // 金额输入
      TextInput({ placeholder: '转账金额' })
        .type(InputType.Number)
        .width('80%')
        .height(50)
        .onChange((value: string) => {
          this.amount = value
        })


      // 保存按钮
      Button('确认转账')
        .width('80%')
        .height(50)
        .margin(20)
        .onClick(() => {
          // 保存逻辑
        })
    }
    .width('100%')
    .height('100%')
  }
}