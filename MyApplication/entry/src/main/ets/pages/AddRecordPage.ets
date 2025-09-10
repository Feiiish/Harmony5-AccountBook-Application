import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../models/recordItemReference"
import type { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

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
    .backgroundColor($r('app.color.Darker_window_background'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

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
  @Local tempDate: string = new Date().toDateString();
  @Local tempTag: string = ""
  @Local tempNote: string = ""
  //For image
  @Local imageUri: string = '';
  @Local imgDatas: string[] = [];
  @Local selectedImage: ResourceStr = '';
  @Local backBlur: boolean = false;

  private saveRecord() {
    // 创建新记录
    const newRecord = new RecordItem();

    if (this.tempAmount !== null) {
      newRecord.amount = this.tempAmount
    }
    newRecord.unit = this.tempUnit;
    newRecord.date = this.tempDate;
    newRecord.tag = this.tempTag;
    newRecord.note = this.tempNote;
    newRecord.selectimageUriedImage = this.imageUri

    this.recordsData.items = [...this.recordsData.items, newRecord];
    // 重置表单
    this.tempAmount = 0;
    this.tempUnit = this.userSetting.preferredCurrency
    this.tempDate = new Date().toDateString();
    this.tempTag = ""
    this.tempNote = '';
    this.selectedImage = ''


    // 数据会自动持久化，无需手动保存
    promptAction.showToast({ message: '保存成功' });
    router.back();
  }

  private dialogController: CustomDialogController | undefined = new CustomDialogController({
    builder: this.progressDialogBuilder,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss();
      }
      if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss();
      }
    },
    alignment: DialogAlignment.Center,
    autoCancel: true,
    cornerRadius: $r('sys.float.padding_level10')
  });
  @Local inputValue: string = ""

  @Builder
  progressDialogBuilder() {
    CustomContentDialog({
      contentBuilder: () => {
        this.buildContent();
      },
      buttons: [{
        value: '取消',
        action: () => {
          this.dialogController?.close();
        }
      }, {
        value: '确认',
        action: () => {
          this.onAccept();
          this.dialogController?.close();
        }
      }]
    })
  }

  @Builder
  buildContent(): void {
    Column() {
      Row() {
        TextInput({ text: "", placeholder: "输入标签" }).onChange((value: string) => {
          this.inputValue = value
        })

      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

    }
  }

  aboutToDisappear() {
    this.dialogController = undefined;
  }

  onAccept() {

    for (const str of this.userSetting.tags) {
      if (this.inputValue === str) {
        this.tempTag = this.inputValue;
        return;
      }
    }
    this.userSetting.tags = [...this.userSetting.tags, this.inputValue.trim()]
    this.tempTag = this.inputValue
    console.info('Callback when the second button is clicked');
  }

  build() {

    List() {
      ListItem() {
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
                  } else if (this.tempAmount < 0) {
                    this.message = "支出: " + JSON.stringify(this.tempAmount)
                    this.couldSave = true;
                  } else {

                    this.message = "收入： " + JSON.stringify(this.tempAmount)
                    this.couldSave = true;
                  }
                })

              //currency Sign
              Row({ space: 4 }) {
                findFlag({ flagName: this.tempUnit })

              }.onClick(() => {
                
                TextPickerDialog.show({
                  range: this.userSetting.chosenCurrency,
                  defaultPickerItemHeight: 36,
                  canLoop: false,
                  onAccept: (value: TextPickerResult) => {
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
                    this.tempDate = date.toDateString();
                  })


              }.width("100%")
              .justifyContent(FlexAlign.SpaceBetween)
            }

            Column() {
              Text("选择分类").secondTitle().width("100%")
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.userSetting.tags, (item: string) => {
                  Text(item)
                    .fontSize(16)
                    .fontColor(this.tempTag === item ? "#000000" : $r('app.color.Font_Color'))// 选中时白色文字
                    .padding("2%")
                    .backgroundColor(this.tempTag === item ? "#FFCC22" :
                    $r('app.color.Basic_Card_background'))// 选中时黄色背景
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
                Text("+")
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.Font_Color'))
                  .fontSize(16)
                  .width(44)
                  .textAlign(TextAlign.Center)
                  .backgroundColor($r('app.color.Basic_Card_background'))
                  .padding("2%")
                  .borderRadius(5)
                  .margin({ right: 10, bottom: 10 })
                  .onClick(() => {
                    this.dialogController?.open()
                  })
              }
            }

            Row() {
              TextInput({ placeholder: '添加备注' })
                .width('60%')
                .height(40)
                .onChange((value: string) => {
                  this.tempNote = value
                })

              Image($r('app.media.image')).onClick(() => {
                try {
                  const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
                  photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
                  photoSelectOptions.maxSelectNumber = 1;
                  const photoPicker = new photoAccessHelper.PhotoViewPicker();
                  photoPicker.select(photoSelectOptions)
                    .then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
                      this.imgDatas = photoSelectResult.photoUris;
                      this.imageUri = this.imgDatas[0];
                      this.selectedImage = this.imgDatas[0];
                      if (this.selectedImage.length > 0) {
                        this.backBlur = true;
                      }
                      console.info(`PhotoViewPicker.select successfully, PhotoSelectResult uri: ${photoSelectResult.photoUris[0]}`);

                    })
                    .catch((err: BusinessError) => {
                      console.info(`PhotoViewPicker.select failed with err: ${err.code}, ${err.message}`);
                    });
                } catch (error) {
                  const err: BusinessError = error as BusinessError;
                  console.error(`PhotoViewPicker failed with err: ${err.code}, ${err.message}`);
                }
              })
                .width(35)


            }.width("100%").justifyContent(FlexAlign.SpaceEvenly)

            if (this.selectedImage !== '') {
              Image(this.selectedImage)
                .objectFit(ImageFit.Contain)
                .borderRadius($r('sys.float.corner_radius_level5'))
                .width('100%')
                .height('40%')
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
                  if (this.tempAmount === 0) {
                    promptAction.showToast({ message: '请输入金额' });
                    return
                  }
                  promptAction.showToast({ message: '保存失败' });
                }

              })
          }.width("90%")

        }
      }
    }
    .sticky(StickyStyle.Header)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .height("95%")
    .alignListItem(ListItemAlign.Center)

  }
}

// 转账页面组件
@Component
struct TransferPage {
  @State amount: string = ''
  @State fromAccount: string = 'CNY'
  @State toAccount: string = 'CAD'

  build() {
    List() {
      ListItem() {
        Column() {

          // 金额输入
          TextInput({ placeholder: '转账金额' })
            .type(InputType.Number)
            .width('80%')
            .height(50)
            .onChange((value: string) => {
              this.amount = value
            })

          //转账模块生成两个recordItem, item的note为自动生成的transferID


          // 保存按钮
          Button('确认转账')
            .width('80%')
            .height(50)
            .margin(20)
            .onClick(() => {
              // 保存逻辑
            })

        }
      }
    }
    .sticky(StickyStyle.Header)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .height("95%")
    .alignListItem(ListItemAlign.Center)

  }
}