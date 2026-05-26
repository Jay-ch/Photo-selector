import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { ImageFile } from './ImageFile'
import { http } from '@kit.NetworkKit'
import util from '@ohos.util'
import { ImageKnifeComponent } from '@ohos/imageknife'

/**
 * ImageKnife Header 选项接口
 */
interface ImageKnifeHeaderOption {
  key: string
  value: string
}

/**
 * @author J.query
 * @date 2026/4/1
 * @email j-query@foxmail.com
 * Description: 通用相册选择和显示控件
 */

@Component
export struct PhotoSelector {
  // Props
  @Link @Watch('onSelectedFilesChange') selectedFiles: ImageFile[]
  @Prop maxSelectNumber: number = 9
  @Prop title: string = ''
  @Prop showTitle: boolean = true
  @Prop titleColor: string = '#333333'
  @Prop titleFontSize: number | string = 16
  @Prop showDeleteButton: boolean = true
  @Prop hideAddButtonWhenFull: boolean = true
  @Prop columnCount: number = 3
  @Prop showPreviewButton: boolean = false // 是否显示预览按钮
  @Prop showIndexNumber: boolean = false // 是否显示序号（默认不显示）
  @Prop hideAddButton: boolean = false // 是否隐藏添加按钮（默认 false，显示添加按钮）
  @Prop cookieHeader: string = '' // Cookie 请求头（可选，用于网络图片加载）
  onFilesChange?: (files: ImageFile[]) => void
  onPreviewAll?: (files: ImageFile[]) => void
  // 新增状态：Grid 的实际宽度
  @State gridWidth: number = 0
  @State gridHeight: number = 0
  // 缓存的图片数据（用于需要认证的网络图片）
  @State cachedImageUris: Map<string, string> = new Map()

  // 是否达到最大选择数量
  get isMaxSelect(): boolean {
    return this.selectedFiles.length >= this.maxSelectNumber
  }

  // 计算每个 GridItem 的宽度（基于实际 Grid 宽度或预设值）
  get itemWidth(): number {
    // 确保 columnCount 有效
    const validColumnCount = this.columnCount || 3
    if (this.gridWidth <= 0 || validColumnCount <= 0) {
      // 如果还没有获取到实际宽度，返回预设值（假设屏幕宽度 360vp，减去左右边距各 16vp）
      const defaultScreenWidth = 320
      const totalGap = (validColumnCount - 1) * 8
      return (defaultScreenWidth - totalGap) / validColumnCount
    }
    // 计算每个 GridItem 的宽度 = (总宽度 - (列数 -1)*列间距) / 列数
    const totalGap = (validColumnCount - 1) * 8 // 8 是 columnsGap
    return (this.gridWidth - totalGap) / validColumnCount
  }

  // 获取网格列模板 - 返回字符串格式
  get gridColumns(): string {
    const columns = Array(this.columnCount).fill('1fr').join(' ')
    console.info(`[PhotoSelector] gridColumns: "${columns}", columnCount: ${this.columnCount}, selectedFiles.length: ${this.selectedFiles.length}`)
    return columns
  }

  // 计算每个 GridItem 的边长（正方形）
  private calculateItemSize(): number {
    if (this.gridWidth <= 0) {
      // 如果还没有获取到宽度，返回默认值
      return 100
    }
    // 总宽度 - 列间距 = 可用宽度
    const totalGapWidth = (this.columnCount - 1) * 8
    const availableWidth = this.gridWidth - totalGapWidth
    // 每列宽度 = 可用宽度 / 列数
    const itemSize = availableWidth / this.columnCount
    console.info(`[PhotoSelector] calculateItemSize: ${itemSize}vp, gridWidth: ${this.gridWidth}, columnCount: ${this.columnCount}`)
    return itemSize
  }

  // 添加计算属性
  private getGridHeight(): string | number {
    // 计算实际显示的项目数：已选图片数 + (未达最大值且未隐藏添加按钮时的添加按钮)
    const itemCount = this.selectedFiles.length + 
      (this.selectedFiles.length < this.maxSelectNumber && !this.hideAddButton ? 1 : 0)
    const rowCount = Math.ceil(itemCount / this.columnCount)
    // 至少显示一行
    const actualRowCount = Math.max(1, rowCount)

    // 获取每个 GridItem 的边长（正方形，宽 = 高）
    // 直接使用 gridWidth 计算，避免使用 itemWidth getter
    const validColumnCount = this.columnCount || 3
    let itemSize: number
    if (this.gridWidth <= 0) {
      // 使用预设值
      const defaultScreenWidth = 320
      const totalGap = (validColumnCount - 1) * 8
      itemSize = (defaultScreenWidth - totalGap) / validColumnCount
    } else {
      const totalGap = (validColumnCount - 1) * 8
      itemSize = (this.gridWidth - totalGap) / validColumnCount
    }

    // 高度 = 行数 * itemSize + 行间距
    const height = actualRowCount * itemSize + (actualRowCount > 1 ? (actualRowCount - 1) * 8 : 0)
    console.info(`[PhotoSelector] getGridHeight: ${height}vp, rowCount: ${rowCount}, actualRowCount: ${actualRowCount}, itemCount: ${itemCount}, columnCount: ${this.columnCount}, itemSize: ${itemSize}, selectedFiles.length: ${this.selectedFiles.length}, maxSelectNumber: ${this.maxSelectNumber}`)
    console.info(`[PhotoSelector]   → 添加按钮应该显示：${this.selectedFiles.length < this.maxSelectNumber}`)
    return height
  }

  aboutToAppear() {
    console.info('[PhotoSelector] 组件创建')
  }

  /**
   * 预加载网络图片（带认证）
   */
  private async preloadNetworkImages(): Promise<void> {
    for (const imageFile of this.selectedFiles) {
      if (imageFile.uri.startsWith('http://') || imageFile.uri.startsWith('https://')) {
        await this.loadNetworkImage(imageFile.uri)
      }
    }
  }

  /**
   * 加载单个网络图片（带 Cookie 认证）
   */
  private async loadNetworkImage(url: string): Promise<void> {
    try {
      // 如果已经缓存，跳过
      if (this.cachedImageUris.has(url)) {
        return
      }

      console.info(`[PhotoSelector] 开始加载网络图片: ${url}`)

      // 创建 HTTP 请求
      const httpRequest = http.createHttp()
      
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Cookie': this.cookieHeader
        },
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      })

      if (response.responseCode === 200 && response.result) {
        // 将 ArrayBuffer 转换为 base64
        const arrayBuffer = response.result as ArrayBuffer
        const base64 = this.arrayBufferToBase64(arrayBuffer)
        const dataUri = `data:image/jpeg;base64,${base64}`
        
        // 缓存图片 URI
        this.cachedImageUris.set(url, dataUri)
        // 触发 UI 更新
        this.cachedImageUris = new Map(this.cachedImageUris)
        
        console.info(`[PhotoSelector] 网络图片加载成功: ${url}`)
      } else {
        console.error(`[PhotoSelector] 网络图片加载失败，状态码: ${response.responseCode}`)
      }

      httpRequest.destroy()
    } catch (e) {
      console.error(`[PhotoSelector] 加载网络图片异常: ${(e as Error).message}`)
    }
  }

  /**
   * ArrayBuffer 转 Base64
   */
  private arrayBufferToBase64(buffer: ArrayBuffer): string {
    try {
      // 使用 HarmonyOS 的 util.Base64 进行编码
      const uint8Array = new Uint8Array(buffer)
      const base64Helper = new util.Base64Helper()
      const base64String = base64Helper.encodeToStringSync(uint8Array)
      return base64String
    } catch (e) {
      console.error(`[PhotoSelector] Base64 编码失败: ${(e as Error).message}`)
      return ''
    }
  }

  /**
   * 监听 selectedFiles 变化
   */
  onSelectedFilesChange(): void {
    console.info(`[PhotoSelector] selectedFiles 变化，当前数量: ${this.selectedFiles.length}`)
    // 如果 Cookie 已加载，预加载新的网络图片
    if (this.cookieHeader && this.selectedFiles.length > 0) {
      this.preloadNetworkImages()
    }
  }

  /**
   * 获取图片 URI（优先使用缓存）
   */
  private getImageUri(imageFile: ImageFile): string {
    // 如果是网络图片且已缓存，返回缓存的 base64
    if ((imageFile.uri.startsWith('http://') || imageFile.uri.startsWith('https://')) && 
        this.cachedImageUris.has(imageFile.uri)) {
      return this.cachedImageUris.get(imageFile.uri)!
    }
    // 否则返回原始 URI
    return imageFile.uri
  }

  aboutToDisappear() {
    console.info('[PhotoSelector] 组件销毁')
  }

  /**
   * 选择图片
   */
  private async selectImages(): Promise<void> {
    try {
      const remainingCount = this.maxSelectNumber - this.selectedFiles.length
      const photoSelectOptions: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE

      // 关键：传入已选图片的 URI 列表，这样系统相册会保持勾选状态
      if (this.selectedFiles.length > 0) {
        photoSelectOptions.preselectedUris = this.selectedFiles.map(file => file.uri)
        // 如果已达上限，提示用户可以取消已选图片
        if (remainingCount <= 0) {
          console.info(`[PhotoSelector] 已选 ${this.selectedFiles.length} 张，可取消部分图片`)
          // 传入当前已选数量，允许用户取消
          photoSelectOptions.maxSelectNumber = this.selectedFiles.length
        } else {
          // 关键：maxSelectNumber 应该设置总额度，而不是剩余额度
          // 系统会自动计算：maxSelectNumber - preselectedUris.length = 还能选的数量
          photoSelectOptions.maxSelectNumber = this.maxSelectNumber
          console.info(`[PhotoSelector] 已选 ${this.selectedFiles.length} 张，还能再选 ${remainingCount} 张`)
        }
      } else {
        photoSelectOptions.maxSelectNumber = this.maxSelectNumber
      }

      console.info(`[PhotoSelector] 准备选择图片，总额度：${photoSelectOptions.maxSelectNumber}，已选：${photoSelectOptions.preselectedUris?.length ||
        0}，还能选：${remainingCount}`)

      const photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker()
      const result: photoAccessHelper.PhotoSelectResult = await photoPicker.select(photoSelectOptions)

      if (result.photoUris && result.photoUris.length > 0) {
        // 将 URI 转换为 ImageFile 对象
        const resultFiles: ImageFile[] = result.photoUris.map((uri: string) => {
          const imageFile: ImageFile = {
            uri: uri,
            name: uri.substring(uri.lastIndexOf('/') + 1),
            size: undefined
          }
          return imageFile
        })

        // 关键：系统返回的是当前所有勾选的图片（包含旧的和新的）
        // 我们需要找出新增的图片（在结果中但不在已选列表中的）
        const existingUris = new Set(this.selectedFiles.map(file => file.uri))
        const trulyNewFiles = resultFiles.filter(file => !existingUris.has(file.uri))

        console.info(`[PhotoSelector] 系统返回 ${resultFiles.length} 张，其中真正新增 ${trulyNewFiles.length} 张`)

        // 同步更新：保留已选的 + 新增的（自动移除取消的）
        const availableSpace = this.maxSelectNumber - this.selectedFiles.length
        const filesToAdd = trulyNewFiles.slice(0, availableSpace)

        // 构建新的已选列表：保留在结果中的旧图片 + 新增的图片
        const retainedFiles = this.selectedFiles.filter(file =>
        resultFiles.some(resultFile => resultFile.uri === file.uri)
        )
        this.selectedFiles = [...retainedFiles, ...filesToAdd]

        // 触发回调
        if (this.onFilesChange) {
          this.onFilesChange(this.selectedFiles)
        }

        console.info(`[PhotoSelector] 选中图片，当前数量：${this.selectedFiles.length}`)
      }
    } catch (error) {
      console.error(`[PhotoSelector] 选择图片失败：${JSON.stringify(error)}`)
    }
  }

  /**
   * 删除图片
   */
  private deleteImage(index: number): void {
    if (index >= 0 && index < this.selectedFiles.length) {
      this.selectedFiles.splice(index, 1)
      this.selectedFiles = [...this.selectedFiles]

      // 触发回调
      if (this.onFilesChange) {
        this.onFilesChange(this.selectedFiles)
      }

      console.info(`[PhotoSelector] 删除图片，剩余数量：${this.selectedFiles.length}`)
    }
  }

  /**
   * 预览所有图片
   */
  private previewAllImages(): void {
    if (this.selectedFiles.length > 0 && this.onPreviewAll) {
      this.onPreviewAll(this.selectedFiles)
    }
  }

  /**
   * 判断是否为网络图片
   */
  private isNetworkImage(uri: string): boolean {
    return uri.startsWith('http://') || uri.startsWith('https://')
  }

  /**
   * 获取 ImageKnife 的 Header 选项
   */
  private getImageKnifeHeaders(): Array<ImageKnifeHeaderOption> {
    const headers: Array<ImageKnifeHeaderOption> = []
    if (this.cookieHeader) {
      headers.push({
        key: 'Cookie',
        value: this.cookieHeader
      })
    }
    return headers
  }

  /**
   * 构建图片网格项
   */
  @Builder
  ImageGridItem(imageFile: ImageFile, index: number, isAddButton: boolean = false) {
    // 使用 Stack 布局，让删除按钮可以在图片外面
    Stack() {
      // 图片内容或添加按钮
      if (!isAddButton) {
        // 如果是网络图片且 Cookie 已加载，使用 ImageKnife 加载（支持自定义 Header）
        if (this.isNetworkImage(imageFile.uri) && this.cookieHeader) {
          // 使用 ImageKnife 加载带 Cookie 的网络图片
          ImageKnifeComponent({
            imageKnifeOption: {
              loadSrc: imageFile.uri,
              placeholderSrc: $r('app.media.loading'),     // 加载中显示的占位图
              errorholderSrc: $r('app.media.app_icon'),    // 加载失败时显示的错误图
              objectFit: ImageFit.Cover,                   // 图片缩放方式
              headerOption: this.getImageKnifeHeaders()
            }
          })
            .width('100%')
            .height('100%')
            .borderRadius(8)
            .onClick(() => {
              // 单击图片预览也通过回调通知父组件
              if (this.onPreviewAll) {
                this.onPreviewAll(this.selectedFiles)
              }
            })
        } else {
          // 本地图片或 Cookie 未加载时，使用普通 Image 组件
          Image(this.getImageUri(imageFile))
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .onClick(() => {
              // 单击图片预览也通过回调通知父组件
              if (this.onPreviewAll) {
                this.onPreviewAll(this.selectedFiles)
              }
            })
        }
      } else {
        // 添加按钮
        Column() {
          Text('+')
            .fontSize(40)
            .fontColor('#CCCCCC')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E0E0E0' })
        .borderRadius(2)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.selectImages()
        })
        .hoverEffect(HoverEffect.Scale)
      }

      // 删除按钮 - 放在 Stack 上层，位置在右上角外面
      if (!isAddButton && this.showDeleteButton) {
        Row() {
          Text('×')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
        }
        .width(24)
        .height(24)
        .backgroundColor('#000000')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .position({ x: -8, y: -8 }) // 负值让按钮超出图片范围
        .onClick(() => {
          this.deleteImage(index)
        })
      }

      // 显示选择序号（当启用显示序号且有多张图片时）
      if (!isAddButton && this.showIndexNumber && this.selectedFiles.length > 1) {
        Row() {
          Text(`${index + 1}`)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
        }
        .width(24)
        .height(24)
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .position({ x: 8, y: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .aspectRatio(1)
    //添加内边距，给删除按钮留出空间
    .padding(12)
  }

  build() {
    Column() {
      // 标题
      if (this.showTitle && this.title) {
        Row() {
          Text(this.title)
            .fontSize(this.titleFontSize)
            .fontColor(this.titleColor)
            .fontWeight(FontWeight.Medium)
  
          // 预览按钮（当有图片且启用预览功能时显示）
          if (this.showPreviewButton && this.selectedFiles.length > 0) {
            Button('预览全部')
              .fontSize(12)
              .fontColor('#007AFF')
              .backgroundColor('transparent')
              .height(32)
              .padding({ left: 12, right: 12 })
              .borderRadius(16)
              .border({ width: 1, color: '#007AFF' })
              .onClick(() => {
                this.previewAllImages()
              })
          }
  
          Blank()
        }
        .width('100%')
        .margin({ bottom: 12 })
      }
  
      // 图片网格
      Grid() {
        // 已选择的图片
        ForEach(this.selectedFiles, (imageFile: ImageFile, index: number) => {
          GridItem() {
            this.ImageGridItem(imageFile, index, false)
          }
        }, (imageFile: ImageFile, index: number) => index.toString())
  
        // 添加按钮（仅在未达到最大选择数量且未隐藏添加按钮时显示）
        if (this.selectedFiles.length < this.maxSelectNumber && !this.hideAddButton) {
          GridItem() {
            this.ImageGridItem({ uri: '', name: '', size: 0 }, -1, true)
          }
        }
      }
      .columnsTemplate(Array(this.columnCount).fill('1fr').join(' '))  // 直接使用列模板字符串
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .height(this.getGridHeight())  // 添加计算高度的方法
  
      .onAreaChange((oldValue: Area, newValue: Area) => {
        const validColumnCount = this.columnCount || 3
        const validGridWidth = newValue.width as number

        // 直接在 onAreaChange 中计算 itemWidth，避免访问 this.itemWidth
        const totalGap = (validColumnCount - 1) * 8
        const itemWidthValue = (validGridWidth - totalGap) / validColumnCount

        this.gridWidth = validGridWidth
        this.gridHeight = newValue.height as number
      })
    }
    .width('100%')
  }
}
