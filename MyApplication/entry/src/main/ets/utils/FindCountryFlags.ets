@ComponentV2
export struct findFlag {
  @Require @Param flagName: string

  build() {
    Column() {
      if (this.isImageExist(this.flagName)) {
        Image(this.getImageResource(this.flagName))
          .width(25)
      } else {
        Text('✕')
          .fontSize(30)
          .fontColor(Color.Red)
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private isImageExist(imageName: string): boolean {
    try {
      const resource = this.getImageResource(imageName)
      return resource !== undefined
    } catch (error) {
      return false
    }
  }

  private getImageResource(imageName: string): Resource {
    // 现在直接引用media目录下的图片
    return $r(`app.media.${imageName}`)
  }
}


export function findColor(unit: string) {
  switch (unit.toUpperCase()) {
    case "USD":
      return "#00B300"; // 美元 - 绿色
    case "CAD":
      return "#007FFF"; // 加元 - 蓝色
    case "EUR":
      return "#0000FF"; // 欧元 - 深蓝色
    case "GBP":
      return "#800080"; // 英镑 - 紫色
    case "AUD":
      return "#228B22"; // 澳元 - 森林绿
    case "JPY":
      return "#FF0000"; // 日元 - 红色
    case "CNY":
      return "#FFA500"; // 人民币 - 橙色
    case "INR":
      return "#FFD700"; // 印度卢比 - 金色
    case "KRW":
      return "#4169E1"; // 韩元 - 皇家蓝
    case "CHF":
      return "#8B0000"; // 瑞士法郎 - 深红色
    case "BRL":
      return "#32CD32"; // 巴西雷亚尔 - 青绿色
    case "RUB":
      return "#A52A2A"; // 卢布 - 棕红色
    case "MXN":
      return "#20B2AA"; // 墨西哥比索 - 青蓝色
    case "ZAR":
      return "#FFD700"; // 南非兰特 - 金色
    case "NGN":
      return "#006400"; // 奈拉 - 深绿色
    case "SAR":
      return "#2E8B57"; // 沙特里亚尔 - 海绿色
    case "AED":
      return "#708090"; // 阿联酋迪拉姆 - 石板灰
    default:
      return "#808080"; // 默认 - 灰色
  }
}

