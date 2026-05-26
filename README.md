# PhotoSelector HAR 模块

## 概述

PhotoSelector 是一个独立的 HarmonyOS HAR（Harmony Archive）模块，提供通用的相册选择和显示功能。

## 特性

- ✅ 图片选择：支持从相册选择多张图片
- ✅ 图片预览：点击已选图片可全屏预览
- ✅ 图片删除：点击删除按钮可移除已选图片
- ✅ 数量限制：可配置最大可选图片数量
- ✅ 自动布局：根据最大数量自动计算网格列数
- ✅ 样式自定义：支持自定义标题、颜色、字体等
- ✅ 回调通知：图片变化时触发回调
- ✅ 网络图片：支持带认证的网络图片加载

## 模块信息

- **模块名称**: `@j-query/photo-selector`
- **版本**: 1.0.0
- **类型**: HAR (Harmony Archive)
- **API 类型**: Stage Mode

## 使用方法

### 1. 添加依赖

在项目的 `oh-package.json5` 中添加依赖：

```json5
{
  "dependencies": {
    "@j-query/photo-selector": "file:../photo-selector"
  }
}
```

然后运行：

```bash
hvigorw ohpm install
```

### 2. 导入组件

```typescript
import { PhotoSelector, ImageFile } from '@j-query/photo-selector'
```

### 3. 基本使用

```typescript
@State selectedImages: ImageFile[] = []

PhotoSelector({
  selectedFiles: this.selectedImages,
  maxSelectNumber: 9,
  onFilesChange: (files: ImageFile[]) => {
    console.info(`已选 ${files.length} 张图片`)
  }
})
```

### 4. 带 Cookie 的网络图片支持

如果需要加载需要认证的网络图片，传入 Cookie：

```typescript
PhotoSelector({
  selectedFiles: this.selectedImages,
  cookieHeader: 'your-cookie-here',  // 传入 Cookie
  onFilesChange: (files: ImageFile[]) => {
    // 处理变化
  }
})
```

## API 参考

### Props

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| selectedFiles | ImageFile[] | [] | 已选图片列表（双向绑定） |
| maxSelectNumber | number | 9 | 最大可选数量 |
| title | string | '' | 标题文字 |
| showTitle | boolean | true | 是否显示标题 |
| titleColor | string | '#333333' | 标题颜色 |
| titleFontSize | number \| string | 16 | 标题字体大小 |
| showDeleteButton | boolean | true | 是否显示删除按钮 |
| hideAddButtonWhenFull | boolean | true | 满额时隐藏添加按钮 |
| columnCount | number | 3 | 网格列数 |
| showPreviewButton | boolean | false | 是否显示预览按钮 |
| showIndexNumber | boolean | false | 是否显示序号 |
| hideAddButton | boolean | false | 是否隐藏添加按钮 |
| cookieHeader | string | '' | Cookie 请求头（用于网络图片） |

### Callbacks

| 回调 | 参数 | 说明 |
|------|------|------|
| onFilesChange | (files: ImageFile[]) => void | 图片列表变化时触发 |
| onPreviewAll | (files: ImageFile[]) => void | 点击预览时触发 |

### Interfaces

```typescript
interface ImageFile {
  uri: string      // 图片 URI
  name?: string    // 图片名称（可选）
  size?: number    // 图片大小（可选）
}
```

## 完整示例

```typescript
import { PhotoSelector, ImageFile } from '@j-query/photo-selector'

@Entry
@Component
struct MyPage {
  @State beforePhotos: ImageFile[] = []
  @State afterPhotos: ImageFile[] = []
  @State cookie: string = ''

  aboutToAppear() {
    // 从首选项或其他地方获取 Cookie
    this.loadCookie()
  }

  async loadCookie() {
    // 加载 Cookie 的逻辑
    this.cookie = 'your-cookie-value'
  }

  build() {
    Column() {
      // 处理前照片
      Text('处理前照片')
        .fontSize(14)
        .fontColor('#333333')
      
      PhotoSelector({
        selectedFiles: this.beforePhotos,
        maxSelectNumber: 3,
        cookieHeader: this.cookie,
        onFilesChange: (files: ImageFile[]) => {
          console.info(`处理前：${files.length}张`)
        }
      })

      // 处理后照片
      Text('处理后照片')
        .fontSize(14)
        .fontColor('#333333')
        .margin({ top: 16 })
      
      PhotoSelector({
        selectedFiles: this.afterPhotos,
        maxSelectNumber: 9,
        cookieHeader: this.cookie,
        onFilesChange: (files: ImageFile[]) => {
          console.info(`处理后：${files.length}张`)
        }
      })
    }
    .width('100%')
    .padding(16)
  }
}
```

## 构建模块

### 编译 HAR

```bash
cd photo-selector
hvigorw assembleHar
```

编译后的 HAR 文件位于：`photo-selector/build/default/outputs/default/photo-selector.har`

### 发布到本地仓库

```bash
hvigorw publish
```

## 注意事项

1. **依赖管理**: 模块依赖 `@ohos/imageknife`，确保主项目中已安装
2. **Cookie 传递**: 如需加载需要认证的网络图片，请通过 `cookieHeader` 属性传入
3. **资源引用**: 模块中使用 `$r('app.media.xxx')` 引用资源，确保主项目中有对应资源
4. **权限要求**: 使用相册功能需要在主项目的 `module.json5` 中声明权限

## 权限配置

在主项目的 `module.json5` 中添加：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.READ_IMAGEVIDEO",
        "reason": "$string:permission_reason_read_media",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

## 常见问题

### Q: 如何获取图片的 base64？

A: 需要使用 file 模块读取并转换：

```typescript
import fs from '@ohos.file.fs'
import util from '@ohos.util'

async function imageToBase64(uri: string): Promise<string> {
  const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
  const buffer = new ArrayBuffer(file.statSync().size)
  fs.readSync(file.fd, buffer)
  fs.closeSync(file)
  
  const uint8Array = new Uint8Array(buffer)
  const base64Helper = new util.Base64Helper()
  return base64Helper.encodeToStringSync(uint8Array)
}
```

### Q: 网络图片加载失败怎么办？

A: 检查以下几点：
1. Cookie 是否正确传入
2. 网络连接是否正常
3. 图片 URL 是否有效
4. 查看控制台日志了解详细错误信息

### Q: 如何自定义样式？

A: 可以通过包裹容器并设置样式：

```typescript
PhotoSelector({...})
  .padding(16)
  .backgroundColor('#FFFFFF')
  .borderRadius(12)
  .shadow({ radius: 4, color: '#00000020' })
```

## 版本历史

### v1.0.0 (2026-05-19)
- ✅ 初始版本发布
- ✅ 支持图片选择、预览、删除
- ✅ 支持数量限制和样式自定义
- ✅ 支持网络图片加载（带认证）

## 技术支持

如有问题或建议，请联系：
- Email: j-query@foxmail.com
- Author: J.query

## 许可证

Apache-2.0
