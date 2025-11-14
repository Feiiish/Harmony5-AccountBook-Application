import { cloudDatabase } from '@kit.CloudFoundationKit';
import { CloudRecord } from '../models/CloudRecord'; // xx是BookInfo文件的相对路径
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cloudCommon } from '@kit.CloudFoundationKit';
import { http } from '@kit.NetworkKit';
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { authentication } from '@kit.AccountKit';
import { UserSetting } from "../models/userSetting"
import { util } from '@kit.ArkTS';
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData, LedgerManager } from '../models/recordItemReference';
import {
  PreviewLoginButtonPage
} from './HuaweiLogin'
import { ifaa } from '@kit.OnlineAuthenticationKit';
import auth from '@hw-agconnect/auth';
import { avatarControl } from "../components/buttons/avatarControl"

let databaseZone = cloudDatabase.zone('QuickStartDemo');


class GroupedRecords {
  bookId: string = ''
  records: CloudRecord[] = []
}

@Preview
@Entry
@ComponentV2
export struct cloudDownload {
  @Local isLoading: boolean = true;
  @Local isDeleting: boolean = false;
  @Local isSaving: boolean = false;
  @Local newFound: number = 0;
  @Local recFound: number = 0
  @Local unionID: string = ""
  @Local avatar: avatarControl = new avatarControl
  @Local
  userSetting: UserSetting = PersistenceV2.connect(
    UserSetting,
    'userSetting',
    () => new UserSetting()
  )!;
  @Local
  ledgerManager: LedgerManager = PersistenceV2.connect(
    LedgerManager,
    'multiLedgerStorage',
    () => new LedgerManager()
  )!;
  @Local groupedList: GroupedRecords[] = []

  public askToSave() {
    this.avatar.checkLoginStatus().then((res) => {
      if (res) {
        this.unionID = this.avatar.UnionID
        this.queryAll().then((newRecs) => {
          //save logic
          this.isSaving = false
          this.getUIContext().showAlertDialog({
            title: '从云端下载账单 ☁️',
            message: `是否将${this.newFound}条新记录下载到账本 ${this.ledgerManager.activeBook.name}`,
            primaryButton: {
              value: '取消',
              action: () => {
                console.info('用户取消');
              }
            },
            secondaryButton: {
              value: '确定',
              action: () => {
                this.saveTheRecord(newRecs)
              }
            }
          });
        })

      } else {
        promptAction.showToast({ message: "请登录账号" });
      }
    }).catch((error: BusinessError) => {
      hilog.error(0x0000, 'testTag', `getCurrentUser error: ${error.message}`);
    });


  }

  saveTheRecord(cloudRecs: CloudRecord[]) {
    cloudRecs.forEach((rec) => {
      const newRec = new RecordItem()
      if (rec.id !== undefined) {
        newRec.id = rec.id;
      }
      if (rec.amount !== undefined) {
        newRec.amount = rec.amount;
      }
      if (rec.unit !== undefined) {
        newRec.unit = rec.unit;
      }
      if (rec.tag !== undefined) {
        newRec.tag = rec.tag;
      }
      if (rec.note !== undefined) {
        newRec.note = rec.note;
      }
      if (rec.date !== undefined) {
        newRec.date = rec.date;
      }
      if (rec.selectimageUriedImage !== undefined) {
        newRec.selectimageUriedImage = rec.selectimageUriedImage;
      }
      this.ledgerManager.activeBook.data.items.push(newRec)


    })
    promptAction.showToast({ message: `已将 ${cloudRecs.length.toString()} 条记录下载到本地` });
  }

  async queryAndGroupRecords() {
    this.groupedList = []

    const cloudRecs = await this.queryAll()

    cloudRecs.forEach((rec) => {
      const bookId = rec.fromBookID ?? '未知账本'

      // 查找是否已有对应 bookId 的分组
      let group = this.groupedList.find(g => g.bookId === bookId)

      // 如果没有，创建新的分组并加入列表
      if (!group) {
        group = new GroupedRecords()
        group.bookId = bookId
        this.groupedList.push(group)
      }

      // 将记录加入对应分组
      group.records.push(rec)
    })
    this.isLoading = false
  }

  async queryAll(): Promise<CloudRecord[]> {
    try {
      this.recFound = 0
      this.newFound = 0

      const condition = new cloudDatabase.DatabaseQuery(CloudRecord);
      condition.equalTo('fromAccount', this.unionID);

      const resultArray = await databaseZone.query(condition);

      this.recFound = resultArray.length
      hilog.info(0x0000, 'queryAll',
        `✅ 查询成功 结果如下：\n${JSON.stringify(resultArray, null, 2)} unionID ${this.unionID}` + resultArray.length);

      const localIds = this.ledgerManager.activeBook.data.items.map(item => item.id);
      const uniqueCloudRecords = resultArray.filter(rec => !localIds.includes(rec.id!));
      this.newFound = uniqueCloudRecords.length
      return uniqueCloudRecords;
    } catch (err) {
      hilog.error(0x0000, 'queryAll', `❌ 查询失败\n错误码: ${err.code}\n错误信息: ${err.message}`);
      return [];
    }
  }

  getEachTag(groupe: GroupedRecords): string {
    const tags = groupe.records
      .map(rec => rec.tag)
      .filter(tag => tag !== undefined && tag !== '')

    const uniqueTags = Array.from(new Set(tags))
    const displayTags = uniqueTags.slice(0, 6).join(', ')
    const suffix = uniqueTags.length > 6 ? '...' : ''

    return `${displayTags}${suffix}`
  }

  aboutToAppear(): void {
    this.isLoading = true
    this.avatar.checkLoginStatus().then((res) => {
      if (res) {
        this.unionID = this.avatar.UnionID
        this.queryAndGroupRecords()
      } else {
        promptAction.showToast({ message: "请登录账号" });
      }
    }).catch((error: BusinessError) => {
      hilog.error(0x0000, 'testTag', `getCurrentUser error: ${error.message}`);
    });
  }

  deleteBookRecords(groupe: GroupedRecords) {
    try {
      databaseZone.delete(groupe.records).then(() => {
        this.isDeleting = false
        promptAction.showToast({ message: `已从云端删除此账本` })
        this.queryAndGroupRecords()
      })


    } catch (e) {

    }


  }

  build() {

    Column() {
      Column() {

        Row() {
          Text('☁️云端记录').fontWeight(FontWeight.Bold).fontSize(20)

          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.right_arrow')).width(24).height(24).margin({ left: 2 })
          }
          .width(40)
          .height(40)
          .backgroundColor($r('app.color.Basic_Card_background'))
          .onClick((event: ClickEvent) => {
            router.back()
          })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width("100%")
        .margin({ bottom: 12 })


        List() {
          ListItem() {
            Column() {
              if (this.isLoading) {
                Column().height('20%')
                Text('加载中')
                  .fontSize(18)
                  .fontColor(Color.Grey)

              } else {
                if (this.unionID === "") {
                  Column().height('20%')
                  Text('请登录')
                    .fontSize(18)
                    .fontColor(Color.Grey)

                } else {
                  Column() {


                    ForEach(this.groupedList, (group: GroupedRecords) => {
                      Column() {
                        if (this.ledgerManager.getBookName(group.bookId) !== '') {
                          Text(`来自账本：${this.ledgerManager.getBookName(group.bookId)}`)
                            .fontSize(18)
                            .fontWeight(FontWeight.Medium)
                            .margin({ bottom: 8, top: 8 })
                        } else {
                          Text(`未知账本`)
                            .fontSize(18)
                            .fontWeight(FontWeight.Medium)
                            .margin({ bottom: 8, top: 8 })
                        }

                        Text(`共 ${group.records.length} 条记录`)
                          .fontSize(14)
                          .fontColor(Color.Grey)
                          .margin({ bottom: 8 })

                        Text(`标签: ${this.getEachTag(group)}`)
                          .fontSize(14)
                          .fontColor(Color.Grey)
                          .margin({ bottom: 8 })

                        Row() {


                          Button('从云端删除')
                            .buttonStyle(ButtonStyleMode.TEXTUAL)
                            .backgroundColor(Color.Transparent)
                            .fontColor('#FF3A3A')
                            .onClick(() => {

                              if (this.isDeleting) {
                                promptAction.showToast({ message: "正在处理" });
                                return;
                              }
                              this.isDeleting = true;
                              this.deleteBookRecords(group)
                            })
                          Blank(15)

                          Button('下载到帐本')
                            .buttonStyle(ButtonStyleMode.TEXTUAL)
                            .backgroundColor(Color.Transparent)
                            .onClick(() => {
                              if (this.isSaving) {
                                promptAction.showToast({ message: "准备下载中" });
                                return;
                              }
                              this.isSaving = true;
                              this.askToSave()
                            })

                        }.justifyContent(FlexAlign.SpaceBetween)
                      }
                      .backgroundColor($r('app.color.Basic_Card_background'))
                      .padding(12)
                      .borderRadius(24)
                      .width('90%')
                      .margin({ bottom: 16 })
                      .shadow({
                        radius: 4,
                        color: '#00000020',
                        offsetX: 0,
                        offsetY: 2
                      })

                    })
                    Column() {
                      if (this.groupedList.length === 0) {
                        Text(`${this.recFound} 条云端记录已同步`)
                          .fontSize(16)
                          .fontColor(Color.Grey)

                      } else {
                        Button('刷新记录')
                          .onClick(() => {

                            this.avatar.checkLoginStatus().then((res) => {
                              if (res) {
                                this.unionID = this.avatar.UnionID
                                this.queryAndGroupRecords()
                              } else {
                                promptAction.showToast({ message: "请登录账号" });
                              }
                            }).catch((error: BusinessError) => {
                              hilog.error(0x0000, 'testTag', `getCurrentUser error: ${error.message}`);
                            });

                          })
                      }
                    }
                  }
                }

              }
            }

            .width('100%')
            .justifyContent(FlexAlign.Center)

          }

        }
        .sticky(StickyStyle.Header)
        .scrollBar(BarState.Off)
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.Spring)

      }.width('90%')

    }.width('100%').height('100%')
  }
}


