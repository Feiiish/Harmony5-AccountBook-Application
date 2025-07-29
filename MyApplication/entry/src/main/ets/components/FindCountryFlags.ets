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