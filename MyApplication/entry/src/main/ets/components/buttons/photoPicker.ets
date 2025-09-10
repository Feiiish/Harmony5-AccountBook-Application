import { PersistenceV2, promptAction, router } from '@kit.ArkUI';
import { RecordItem, RecordsData } from "../../models/recordItemReference"

import type { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

@Entry
@Component
export struct PhotoViewPickerComponent {
  @State imageUri: string = '';
  @State imgDatas: string[] = [];
  @State selectedImage: ResourceStr = '';
  @State backBlur: boolean = false;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.selectedImage !== '') {
        Image(this.selectedImage)
          .objectFit(ImageFit.Contain)
          .borderRadius($r('sys.float.corner_radius_level5'))
          .width('100%')
          .height('100%')
      }


      Image($r('app.media.image')).onClick(() => {
        try {
          const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
          photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
          photoSelectOptions.maxSelectNumber = 1;
          const photoPicker = new photoAccessHelper.PhotoViewPicker();
          photoPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
            this.imgDatas = photoSelectResult.photoUris;
            this.imageUri = this.imgDatas[0];
            this.selectedImage = this.imgDatas[0];
            if (this.selectedImage.length > 0) {
              this.backBlur = true;
            }
            console.info(`PhotoViewPicker.select successfully, PhotoSelectResult uri: ${photoSelectResult.photoUris[0]}`);

          }).catch((err: BusinessError) => {
            console.info(`PhotoViewPicker.select failed with err: ${err.code}, ${err.message}`);
          });
        } catch (error) {
          const err: BusinessError = error as BusinessError;
          console.error(`PhotoViewPicker failed with err: ${err.code}, ${err.message}`);
        }
      })
        .width("20%")

      /*
            Button('选择图片')
              .buttonStyle(ButtonStyleMode.NORMAL)
              .backgroundBlurStyle(this.backBlur ? BlurStyle.BACKGROUND_THICK : BlurStyle.NONE,
                {
                  colorMode: ThemeColorMode.SYSTEM,
                  adaptiveColor: AdaptiveColor.DEFAULT,
                  scale: 1.0
                })
              .fontColor(this.backBlur ? $r('sys.color.font_on_primary') : $r('sys.color.font_emphasize'))
              .height(40)
              .fontWeight(FontWeight.Medium)
              .fontSize($r('sys.float.Body_L'))
              .margin({ bottom: 36 })
              .onClick(() => {
                try {
                  const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
                  photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
                  photoSelectOptions.maxSelectNumber = 1;
                  const photoPicker = new photoAccessHelper.PhotoViewPicker();
                  photoPicker.select(photoSelectOptions).then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
                    this.imgDatas = photoSelectResult.photoUris;
                    this.imageUri = this.imgDatas[0];
                    this.selectedImage = this.imgDatas[0];
                    if (this.selectedImage.length > 0) {
                      this.backBlur = true;
                    }
                    console.info(`PhotoViewPicker.select successfully, PhotoSelectResult uri: ${photoSelectResult.photoUris[0]}`);

                  }).catch((err: BusinessError) => {
                    console.info(`PhotoViewPicker.select failed with err: ${err.code}, ${err.message}`);
                  });
                } catch (error) {
                  const err: BusinessError = error as BusinessError;
                  console.error(`PhotoViewPicker failed with err: ${err.code}, ${err.message}`);
                }
              })
              * */
    }
    .height('40%')
    .width("40%")
    .backgroundColor(Color.Red)

  }
}