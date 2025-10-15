import App from "@system.app";
import { RecordItem, RecordsData, singleCurrency } from "../../models/recordItemReference"
import { variousToPreferred } from "../../utils/moneyCount"
import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { displayExchangeRates } from '../../utils/currencyExchange';
import { findColor } from "../../utils/FindCountryFlags";

@Preview
@ComponentV2
export struct PieChartExample {
  @Require @Param pieData: singleCurrency[];
  @Require @Param colors: string[];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private total: number = 0;

  aboutToAppear(): void {
    this.calculateTotal();
  }

  @Monitor('pieData')
  onPieDataChanged(monitor: IMonitor) {
    this.calculateTotal();
    this.context.clearRect(0, 0, this.context.width, this.context.height);
    this.drawPieChart();
  }

  private calculateTotal(): void {
    this.total = this.pieData.reduce((sum, item) => sum + Math.abs(item.amount) / item.rate, 0);
  }

  private drawPieChart(): void {
    let centerX = this.context.width / 2;
    let centerY = this.context.height / 2;
    let radius = 65;
    let startAngle = 0;

    if (this.total === 0 || this.pieData.length === 0) {
      // 绘制空白占位圆
      this.context.fillStyle = '#CCCCCC';
      this.context.beginPath();
      this.context.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      this.context.closePath();
      this.context.fill();
      return;
    }

    this.pieData.forEach((item, index) => {
      let value = Math.abs(item.amount) / item.rate;
      let angle = (value / this.total) * 2 * Math.PI;

      let endAngle = startAngle + angle;
      this.context.fillStyle = findColor(item.unit);

      this.context.beginPath();
      this.context.moveTo(centerX, centerY);
      this.context.arc(centerX, centerY, radius, startAngle, endAngle);
      this.context.closePath();
      this.context.fill();

      //白色边框
      this.context.strokeStyle = '#FFFFFF'; // 白色边框
      this.context.lineWidth = 1;
      this.context.stroke();

      this.context.globalCompositeOperation = 'destination-out';
      this.context.beginPath();
      this.context.arc(centerX, centerY, radius * 0.6, 0, 2 * Math.PI);
      this.context.fill();
      this.context.globalCompositeOperation = 'source-over';

      startAngle = endAngle;
    });
  }

  build() {
    Row() {

      Canvas(this.context)
        .width("50%")
        .height(150)
        .onReady(() => {
          this.drawPieChart();
        })


      Column() {
        ForEach(this.pieData, (item: singleCurrency, index) => {

          Row() {
            Circle()
              .width(12)
              .height(12)
              .margin({ right: 6 })
              .fill(findColor(item.unit))


            Text(`${item.unit} (${(
              (Math.abs(item.amount) / item.rate / this.total) * 100
            ).toFixed(1)}%)`)

          }
          .margin({ bottom: 4, right: 14 })
        })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ top: 16 })
    }
    .justifyContent(FlexAlign.Center)
    .width("100%")

  }
}
