import { formatDateAdvanced } from '../utils/formatDateAdvanced'
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../models/recordItemReference"

import { safeCalculate } from '../utils/safeCalculate';
import { UserSetting } from "../models/userSetting"
import { findFlag } from '../utils/FindCountryFlags';
import { it } from '@ohos/hypium';
import { CustomContentDialog } from '@kit.ArkUI';
import { McLineChart, Options } from '@mcui/mccharts'

const RECORDS_DATA_KEY = 'incomeExpenseRecords';

//规定普通title样式
@Extend(Text)
function secondTitle() {
  .fontSize(24)
  .margin({ bottom: 10 })
}


@Entry
@Component
struct Index {
  @State maxData: number[] = [11, 11, 15, 13, 12, 130, 10]
  @State minData: number[] = [1, -20, 2, 5, 3, 2, 0]
  // 初始化数据
  @State seriesOption: Options = new Options({
    xAxis: {
      data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
    },
    yAxis: {
      name: '温度'
    },
    series: [
      {
        name: '最高气温',
        data: this.maxData
      },
      {
        name: '最低气温',
        data: this.minData
      }
    ]
  })

  // 动态修改数据
  aboutToAppear() {
    setTimeout(() => {
      // 传递需要修改的属性与数值，不需要全部传
      this.maxData = [110, 110, 150, 130, 120, 190, 100]
      this.minData = [-1, -2, -2, -5, 3, -2, 0]
      this.seriesOption.setVal({
        series: [
          {
            name: '最高气温',
            data: this.maxData
          },
          {
            name: '最低气温',
            data: this.minData
          }
        ]
      })
    }, 2000)
  }

  build() {
    Row() {
      Button().onClick((event: ClickEvent) => {
        setTimeout(() => {
          // 传递需要修改的属性与数值，不需要全部传
          this.maxData = [100, 100, 100, 100, 100, 100, 100, 100]
          this.minData = [50, 50, 50, 50, 50, 50, 0]
          this.seriesOption.setVal({
            series: [
              {
                name: '最高气温',
                data: this.maxData
              },
              {
                name: '最低气温',
                data: this.minData
              }
            ]
          })
        }, 200)

      })
      McLineChart({
        options: this.seriesOption
      })
    }
    .height('50%')
  }
}