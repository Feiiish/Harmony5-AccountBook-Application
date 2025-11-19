import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, BudgetItem, LedgerManager } from "../models/recordItemReference"
import type { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

import { safeCalculate } from '../utils/safeCalculate';

import { findFlag } from '../utils/FindCountryFlags';
import { CustomContentDialog } from '@kit.ArkUI';
import { displayExchangeRates, updateExchangeRates } from '../utils/currencyExchange'

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
          planningPage() // 转账页面
        }.tabBar('预算')
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

@CustomDialog
struct CurrencyPickerDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: "just no sense" })
  @State selected: string = ''
  onAccept: (value: string) => void = (_) => {
  }
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;

  build() {
    Stack() {


      Column({ space: 20 }) {

        TextPicker({
          range: this.ledgerManager.activeBook.chosenCurrency
        })
          .selectedIndex(1)
          .onChange((value, index) => {
            this.selected = value as string
          })

          .defaultPickerItemHeight(40)
          .canLoop(false)
          .disappearTextStyle({ color: Color.Gray, font: { size: 14, weight: FontWeight.Regular } })
          .textStyle({ color: Color.Gray, font: { size: 18, weight: FontWeight.Normal } })
          .selectedTextStyle({ font: { size: 22, weight: FontWeight.Bold } })

        Row({ space: 12 }) {
          Button('取消')
            .onClick(() => {
              this.controller.close()
            })
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .fontSize(22)
            .fontWeight(FontWeight.Normal)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.Font_Color'))
            .width("50%")


          Button('确认')
            .onClick(() => {
              this.onAccept(this.selected) // ✅ 调用回调函数传值
              updateExchangeRates(this.selected)
              console.log('选择了:', this.selected)
              this.controller.close()
            })
            .buttonStyle(ButtonStyleMode.TEXTUAL)
            .fontSize(22)
            .fontWeight(FontWeight.Normal)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.Font_Color'))
            .width("50%")
        }.justifyContent(FlexAlign.SpaceAround).width("80%")
      }
      .padding(20)
      .borderRadius(12)

      Image($r('app.media.settings'))
        .width(35)
        .onClick(() => {
          router.pushUrl({
            url: "pages/CurrencySetting"
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.log("跳转失败:", err)
            }
          })
          this.controller.close()

        })
        .margin({ right: 8, top: 20 })

    }.alignContent(Alignment.TopEnd)

  }
}

// 收支页面组件
@ComponentV2
struct IncomePage {
  @Local message: string = "";
  @Local tempAmount: number | null = 0
  @Local couldSave: boolean = false;
  @Local showSelect: boolean = true;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local recordsData: RecordsData = this.ledgerManager.activeBook.data
  /*
  @Local
  recordsData: RecordsData = PersistenceV2.connect(
    RecordsData,
    RECORDS_DATA_KEY,
    () => new RecordsData()
  )!;
  * */
  @Local tempUnit: string = this.ledgerManager.activeBook.preferredCurrency;
  @Local tempDate: string = new Date().toDateString();
  @Local tempTag: string = ""
  @Local tempNote: string = ""
  @Local tempString: string = ""
  //For image
  @Local imageUri: string = '';
  @Local imgDatas: string[] = [];
  @Local selectedImage: ResourceStr = '';
  @Local backBlur: boolean = false;
  @Local rate: number = 0
  controller: TextInputController = new TextInputController();
  @Local show: boolean = true;

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
    console.log('The date is ' + newRecord.date.toString());

    this.recordsData.items = [...this.recordsData.items, newRecord];
    // 重置表单
    this.tempAmount = 0;
    this.tempUnit = this.ledgerManager.activeBook.preferredCurrency
    this.tempDate = '';
    this.tempTag = ""
    this.tempNote = '';
    this.selectedImage = ''


    // 数据会自动持久化，无需手动保存
    promptAction.showToast({ message: '保存成功' });
    router.back();
  }

  private async cacuRate() {
    await displayExchangeRates(this.ledgerManager.activeBook.preferredCurrency, this.tempUnit).then((result) => {
      this.rate = result
      this.updateMessage();
    })
    // 确保 rate 有值后再更新 message
  }

  private updateMessage() {
    if (this.tempAmount == null) {
      this.message = "请输入正确表达式"
      this.couldSave = false;
    } else if (this.tempUnit === this.ledgerManager.activeBook.preferredCurrency) {
      if (this.tempAmount! >= 0) {
        this.message =
          "收入 " + JSON.stringify(this.tempAmount) + " " +
          this.ledgerManager.activeBook.preferredCurrency
      } else {
        this.message =
          "支出: " + JSON.stringify(this.tempAmount) + " " +
          this.ledgerManager.activeBook.preferredCurrency
      }
      this.couldSave = true
    } else {

      if (this.tempAmount! >= 0 && this.rate) {
        this.message =
          "收入: " + JSON.stringify(this.tempAmount) + " " + this.tempUnit +
            ` 约为${(this.tempAmount! / this.rate
            ).toFixed(2)} ${this.ledgerManager.activeBook.preferredCurrency}`
      } else {
        this.message =
          "支出: " + JSON.stringify(this.tempAmount) + " " + this.tempUnit +
            ` 约为${(this.tempAmount! / this.rate
            ).toFixed(2)} ${this.ledgerManager.activeBook.preferredCurrency}`
      }
      this.couldSave = true
    }

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
  // button tag
  @Local inputTagValue: string = ""

  @Builder
  customKeyboardBuilder() {
    Column() {
      Row({}) {
        TextInput({ text: this.tempString, controller: this.controller, placeholder: '请输入金额' })
          .customKeyboard(this.customKeyboardBuilder())
          .width('60%')
          .height(50)
          .inputFilter("[0-9+\\-*/.]", (value: string) => {
            console.log("被过滤的字符: " + value);
          })
          .defaultFocus(true)
          .onChange((value: string) => {

            this.tempAmount = safeCalculate(value);
            this.cacuRate()
          })
      }.width("100%").justifyContent(FlexAlign.SpaceAround).height(30)

      Grid() {
        ForEach([
          '1', '2', '3', '+',
          '4', '5', '6', '-',
          '7', '8', '9', '*',
          '/', '0', '.', '⌫'
        ], (item: string) => {
          GridItem() {
            Button(item)
              .width("20%")
              .height("6%")
              .fontSize(20)
              .backgroundColor(item === '⌫' ? Color.Red : $r('app.color.Basic_Card_background'))
              .fontColor($r('app.color.Font_Color'))
              .borderRadius(15)
              .shadow(ShadowStyle.OUTER_DEFAULT_XS)
              .gesture(
                LongPressGesture({ repeat: false })
                  .onAction(() => {
                    if (item === '⌫') {
                      this.tempString = ''
                      this.message = ""

                    }
                  })
              )
              .onClick(() => {
                if (item === '⌫') {
                  this.tempString = this.tempString.slice(0, -1)
                } else {
                  this.tempString += item
                }
              })
          }
        })
      }
      .maxCount(4)
      .columnsGap(14)
      .rowsGap(14)
      .padding(10)
    }
    .backgroundColor($r('app.color.Basic_Card_background'))
    .padding(10)

  }

  // button to add a tag #1
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
          this.tagButtonOnAccept();
          this.dialogController?.close();
        }
      }]
    })
  }

  tagButtonOnAccept() {

    for (const str of this.ledgerManager.activeBook.tags) {
      if (this.inputTagValue === str) {
        this.tempTag = this.inputTagValue;
        return;
      }
    }
    this.ledgerManager.activeBook.tags = [...this.ledgerManager.activeBook.tags, this.inputTagValue.trim()]
    this.tempTag = this.inputTagValue
    console.info('Callback when the second button is clicked');
  }

  // button to add a tag #2
  @Builder
  buildContent(): void {
    Column() {
      Text("创建标签").width("100%").padding(10).fontSize(24)
      Row() {
        TextInput({ text: "输入标签", placeholder: "" })
          .onChange((value: string) => {
            this.inputTagValue = value
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

  currencyDialogController: CustomDialogController = new CustomDialogController({
    builder: CurrencyPickerDialog({
      onAccept: (value: string) => {
        this.tempUnit = value
        this.cacuRate().then(() => {
          this.updateMessage()
        })
        console.log('用户选择了货币:', value)
      }
    })
  })

  build() {

    List() {
      ListItem() {
        Column() {
          Column({ space: 20 }) {
            // 收入/支出切换
            Row({ space: 10 }) {

              // 金额输入
              TextInput({ text: this.tempString, controller: this.controller, placeholder: '请输入金额' })
                .customKeyboard(this.customKeyboardBuilder())
                .width('60%')
                .height(50)
                .backgroundColor(Color.Transparent)
                .caretStyle({ width: '0vp' })
                .defaultFocus(true)
                .onChange((value: string) => {
                  this.tempAmount = safeCalculate(value);
                  this.cacuRate()
                })

              //currency Sign
              Row({ space: 4 }) {
                findFlag({ flagName: this.tempUnit })

              }.onClick(() => {
                this.currencyDialogController.open()


              })
            }.margin({ top: 20 })


            //record message
            Text(this.message)

            Column() {
              Row() {
                Text("时间").secondTitle()
                CalendarPicker({ hintRadius: 10, selected: new Date() })
                  .edgeAlign(CalendarAlign.END)
                  .textStyle({ color: $r('app.color.Font_Color'), font: { size: 20, weight: FontWeight.Normal } })
                  .onChange((value) => {
                    this.tempDate = value.toDateString();
                    console.info(`CalendarPicker onChange: ${value.toString()}`);
                  })
              }.width("100%")
              .justifyContent(FlexAlign.SpaceBetween)
            }

            Column() {
              Row() {
                Text("选择标签").secondTitle()
                Image($r('app.media.delete')).width(24).margin({ left: 8, bottom: 12 }).onClick(() => {
                  AlertDialog.show({
                    title: '删除确认',
                    message: this.tempTag === '' ? '请选择要删除的标签' : `确定要删除标签 "${this.tempTag}" 吗？`,
                    primaryButton: {
                      value: '取消',
                      action: () => {
                      }
                    },
                    secondaryButton: {


                      value: '删除',
                      action: () => {
                        console.log("123" + this.ledgerManager.activeBook.tags.toString());
                        this.ledgerManager.activeBook.tags =
                          this.ledgerManager.activeBook.tags.filter((item: string) => item !== this.tempTag);

                      }
                    }
                  });
                });
              }.width('100%')


              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.ledgerManager.activeBook.tags, (item: string) => {
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
                        this.tempTag = ""
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
                .width(32)


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
                if (!this.ledgerManager.activeBook.chosenCurrency.includes(this.tempUnit)) {
                  this.couldSave = false
                  promptAction.showToast({ message: '单位不存在' });
                  return
                }

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
@ComponentV2
struct planningPage {
  @Local message: string = "";
  @Local tempAmount: number | null = 0
  @Local tempString: string = "";
  @Local couldSave: boolean = false;
  @Local showSelect: boolean = false;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local tempUnit: string = this.ledgerManager.activeBook.preferredCurrency;
  @Local tempStartDate: string = new Date().toDateString();
  @Local tempEndDate: string = (() => {
    const date = new Date();
    date.setMonth(date.getMonth() + 1);
    return date.toDateString();
  })()
  @Local tempTag: string = ""
  @Local bugetName: string = ""
  @Local isLimitedToTag: boolean = false;
  @Local countAll: boolean = false;
  controller: TextInputController = new TextInputController();
  @Local show: boolean = false;

  private saveRecord() {
    // 创建新记录
    const newBuget = new BudgetItem();

    if (this.tempAmount !== null) {
      newBuget.targetAmount = this.tempAmount
    }
    newBuget.unit = this.tempUnit;
    if (this.isLimitedToTag) {
      newBuget.tag = this.tempTag;
    }

    newBuget.startDate = this.tempStartDate;
    newBuget.endDate = this.tempEndDate;
    newBuget.countAll = this.countAll;
    newBuget.name = this.bugetName;


    this.ledgerManager.activeBook.data.budgets = [...this.ledgerManager.activeBook.data.budgets, newBuget];
    // 重置表单
    this.tempAmount = 0;
    this.tempUnit = this.ledgerManager.activeBook.preferredCurrency
    this.tempTag = ""
    this.bugetName = "";


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
  // button tag
  @Local inputValue: string = ""

  @Builder
  customKeyboardBuilder() {
    Column() {
      Row({}) {
        Image($r('app.media.arrow_down'))
          .height("100%")
          .onClick(() => {
            this.controller.stopEditing();
            this.show = !this.show;
          })
      }.width("100%").justifyContent(FlexAlign.Center).height(30)

      Grid() {
        ForEach([
          '1', '2', '3', '+',
          '4', '5', '6', '-',
          '7', '8', '9', '*',
          '/', '0', '.', '⌫'
        ], (item: string) => {
          GridItem() {
            Button(item)
              .width("20%")
              .height("6%")
              .fontSize(20)
              .backgroundColor(item === '⌫' ? Color.Red : $r('app.color.Basic_Card_background'))
              .fontColor($r('app.color.Font_Color'))
              .borderRadius(15)
              .shadow(ShadowStyle.OUTER_DEFAULT_XS)
              .gesture(
                LongPressGesture({ repeat: false })
                  .onAction(() => {
                    if (item === '⌫') {
                      this.tempString = ''
                      this.message = ""

                    }
                  })
              )
              .onClick(() => {
                if (item === '⌫') {
                  this.tempString = this.tempString.slice(0, -1)
                } else {
                  this.tempString += item
                }
              })
          }
        })
      }
      .maxCount(4)
      .columnsGap(10)
      .rowsGap(10)
      .padding(10)
    }
    .backgroundColor($r('app.color.Basic_Card_background'))
    .padding(10)

  }

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
          this.tagButtonOnAccept();
          this.dialogController?.close();
        }
      }]
    })
  }

  tagButtonOnAccept() {

    for (const str of this.ledgerManager.activeBook.tags) {
      if (this.inputValue === str) {
        this.tempTag = this.inputValue;
        return;
      }
    }
    this.ledgerManager.activeBook.tags = [...this.ledgerManager.activeBook.tags, this.inputValue.trim()]
    this.tempTag = this.inputValue
    console.info('Callback when the second button is clicked');
  }

  // button to add a tag #2
  @Builder
  buildContent(): void {
    Column() {
      Text("创建标签").width("100%").padding(10).fontSize(24)
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

  currencyDialogController: CustomDialogController = new CustomDialogController({
    builder: CurrencyPickerDialog({
      onAccept: (value: string) => {
        this.tempUnit = value

        console.log('用户选择了货币:', value)
      }
    })
  })

  build() {

    List() {
      ListItem() {
        Column() {
          Column({ space: 20 }) {

            // 收入/支出切换
            Row({ space: 10 }) {

              // 金额输入
              TextInput({ controller: this.controller, text: this.tempString, placeholder: '请输入金额' })
                .customKeyboard(this.customKeyboardBuilder())
                .width('60%')
                .height(50)
                .inputFilter("[0-9+\\-*/.]", (value: string) => {
                  console.log("被过滤的字符: " + value);
                })
                .onChange((value: string) => {

                  this.tempAmount = safeCalculate(value);

                  if (this.tempAmount == null) {
                    this.message = "请输入正确表达式"
                    this.couldSave = false;
                  } else if (this.tempAmount < 0) {
                    this.message = "支出预算: " + JSON.stringify(this.tempAmount) + " " + this.tempUnit
                    this.couldSave = true;
                  } else {

                    this.message = "存钱计划： " + JSON.stringify(this.tempAmount) + " " + this.tempUnit
                    this.couldSave = true;
                  }
                })

              //currency Sign
              Row({ space: 4 }) {
                findFlag({ flagName: this.tempUnit })

              }.onClick(() => {
                this.currencyDialogController.open()

              })
            }.margin({ top: 20 })

            //record message
            Text(this.message)

            Column() {
              Row() {
                Text("名称").secondTitle()
                TextInput({ placeholder: '计划名称' })
                  .margin({ bottom: 14 })
                  .width('40%')
                  .height(40)
                  .onChange((value: string) => {
                    this.bugetName = value
                  })
              }.width("100%").justifyContent(FlexAlign.SpaceBetween)

              Row() {
                Text("开始时间").secondTitle()
                CalendarPicker({ hintRadius: 10, selected: new Date() })
                  .margin({ bottom: 12 })
                  .edgeAlign(CalendarAlign.END)
                  .textStyle({ color: $r('app.color.Font_Color'), font: { size: 20, weight: FontWeight.Normal } })
                  .onChange((value) => {
                    this.tempStartDate = value.toDateString();
                    console.info(`CalendarPicker onChange: ${value.toString()}`);
                  })
              }.width("100%")
              .justifyContent(FlexAlign.SpaceBetween)

              Row() {
                Text("结束时间").secondTitle()
                CalendarPicker({ hintRadius: 10, selected: new Date(this.tempEndDate) })
                  .margin({ bottom: 12 })
                  .edgeAlign(CalendarAlign.END)
                  .textStyle({ color: $r('app.color.Font_Color'), font: { size: 20, weight: FontWeight.Normal } })
                  .onChange((value) => {
                    this.tempEndDate = value.toDateString();
                    console.info(`CalendarPicker onChange: ${value.toString()}`);
                  })
              }.width("100%")
              .justifyContent(FlexAlign.SpaceBetween)
            }

            Column() {
              Row() {
                Text("限制标签").secondTitle()
                Toggle({ type: ToggleType.Switch, isOn: false })
                  .margin({ left: 12, bottom: 12 })
                  .onChange((isOn: boolean) => {

                    this.isLimitedToTag = isOn

                  })

              }.width('100%')

              if (this.isLimitedToTag) {
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(this.ledgerManager.activeBook.tags, (item: string) => {
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
                          this.tempTag = ""
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
                Text("计算所有币种").secondTitle()
                Toggle({ type: ToggleType.Switch, isOn: false })
                  .margin({ left: 12, bottom: 12 })
                  .onChange((isOn: boolean) => {

                    this.countAll = isOn
                  })

              }.width('100%')

            }


            // 保存按钮
            Button('保存记录')
              .width('30%')
              .height(50)
              .margin(20)
              .onClick(() => {
                if (!this.ledgerManager.activeBook.chosenCurrency.includes(this.tempUnit)) {
                  this.couldSave = false
                  promptAction.showToast({ message: '单位不存在' });
                  return
                } else if (this.tempAmount === 0) {
                  this.couldSave = false
                  promptAction.showToast({ message: '请输入金额' });
                  return
                } else if (new Date(this.tempStartDate) > new Date(this.tempEndDate)) {
                  this.couldSave = false
                  promptAction.showToast({ message: '结束时间必须晚于开始时间' });
                  return
                } else if (this.isLimitedToTag && this.tempTag === "") {
                  this.couldSave = false
                  promptAction.showToast({ message: '请选择限制的标签' });
                  return
                } else {
                  this.couldSave = true
                }

                if (this.couldSave) {
                  this.saveRecord()
                } else {
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