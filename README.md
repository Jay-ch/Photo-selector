# PhotoSelector 相册选择控件

## 概述

`PhotoSelector` 是一个通用的相册选择和显示控件，支持图片预览、添加、删除功能，可广泛应用于需要图片上传的场景。

> **注意**: 该组件已模块化，建议从 `../modules/photo-selector` 导入使用。

## 功能特性

- 图片选择：支持从相册选择多张图片
- 图片预览：点击已选图片可全屏预览
- 图片删除：点击删除按钮可移除已选图片
- 数量限制：可配置最大可选图片数量
- 自动布局：根据最大数量自动计算网格列数
- 样式自定义：支持自定义标题、颜色、字体等
- 回调通知：图片变化时触发回调

## 使用方法

### 1. 导入组件

**推荐方式（使用模块化导入）：**

```typescript
import { PhotoSelector } from '../modules/photo-selector/PhotoSelector'
import type { ImageFile } from '../modules/photo-selector/ImageFile'
```

**或者从统一入口导入：**

```typescript
import { PhotoSelector, ImageFile } from '../modules/photo-selector'
```

**兼容方式（旧版本导入，已标记为废弃）：**

```typescript
import { PhotoSelector } from '../views/PhotoSelector'
import { ImageFile } from '../entity/ImageFile'
```

### 2. 定义状态变量

```typescript
@State selectedImages: ImageFile[] = []
```

### 3. 使用组件

#### 基础用法

```typescript
PhotoSelector({
  selectedFiles: this.selectedImages,
  maxSelectNumber: 9,
  showTitle: true,
  title: '选择图片',
  onFilesChange: (files: ImageFile[]) => {
    console.info(`当前已选 ${files.length} 张图片`)
  }
})
```

#### 处理前照片示例（最多 3 张）

```typescript
@State beforePhotos: ImageFile[] = []

// 在 build() 中
PhotoSelector({
  selectedFiles: this.beforePhotos,
  maxSelectNumber: 3,
  showTitle: false,
  onFilesChange: (files: ImageFile[]) => {
    console.info(`处理前照片：${files.length}张`)
  }
})
```

#### 处理后照片示例（最多 9 张）

```typescript
@State afterPhotos: ImageFile[] = []

// 在 build() 中
PhotoSelector({
  selectedFiles: this.afterPhotos,
  maxSelectNumber: 9,
  showTitle: false,
  onFilesChange: (files: ImageFile[]) => {
    console.info(`处理后照片：${files.length}张`)
  }
})
```

#### 自定义样式

```typescript
PhotoSelector({
  selectedFiles: this.selectedImages,
  maxSelectNumber: 6,
  title: '上传图片',
  showTitle: true,
  titleColor: '#00428E',
  titleFontSize: 18,
  showDeleteButton: true,
  hideAddButtonWhenFull: true,
  onFilesChange: (files: ImageFile[]) => {
    // 处理图片变化
  }
})
.padding(16)
.backgroundColor('#FFFFFF')
.borderRadius(12)
```

## 参数说明

### Props

| 参数名 | 类型 | 默认值 | 必填 | 说明 |
|--------|------|--------|------|------|
| `selectedFiles` | `ImageFile[]` | `[]` | 是 | 已选择的图片列表（双向绑定） |
| `maxSelectNumber` | `number` | `9` | 否 | 最大可选图片数量 |
| `title` | `string` | `''` | 否 | 标题文字 |
| `showTitle` | `boolean` | `true` | 否 | 是否显示标题 |
| `titleColor` | `string` | `'#333333'` | 否 | 标题颜色 |
| `titleFontSize` | `number \| string` | `16` | 否 | 标题字体大小 |
| `showDeleteButton` | `boolean` | `true` | 否 | 是否显示删除按钮 |
| `hideAddButtonWhenFull` | `boolean` | `true` | 否 | 达到最大数量时是否隐藏添加按钮 |

### Callbacks

| 回调名称 | 参数类型 | 说明 |
|----------|----------|------|
| `onFilesChange` | `(files: ImageFile[]) => void` | 图片列表变化时的回调 |

### 完整示例

#### 提交处理页面示例

```typescript
import { PhotoSelector } from '../modules/photo-selector/PhotoSelector'
import type { ImageFile } from '../modules/photo-selector/ImageFile'

@Entry
@Component
struct SubmitProcessPage {
  @State beforePhotos: ImageFile[] = []
  @State afterPhotos: ImageFile[] = []

  build() {
    Column() {
      // 处理前照片
      Column() {
        Text('处理前照片')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .margin({ bottom: 8 })
        
        PhotoSelector({
          selectedFiles: this.beforePhotos,
          maxSelectNumber: 3,
          showTitle: false,
          onFilesChange: (files: ImageFile[]) => {
            console.info(`处理前照片：${files.length}张`)
          }
        })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 处理后照片
      Column() {
        Text('处理后照片')
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .margin({ bottom: 8 })
        
        PhotoSelector({
          selectedFiles: this.afterPhotos,
          maxSelectNumber: 9,
          showTitle: false,
          onFilesChange: (files: ImageFile[]) => {
            console.info(`处理后照片：${files.length}张`)
          }
        })
      }
      .width('100%')
    }
  }
}
```

## 注意事项

1. **图片格式**: 组件使用 `ImageFile` 接口，包含 `uri`、`name`、`size` 属性
2. **数量限制**: 达到最大数量后，添加按钮会自动隐藏（除非设置 `hideAddButtonWhenFull: false`）
3. **预览功能**: 点击图片可进入全屏预览模式，支持左右滑动切换
4. **删除功能**: 点击删除按钮会立即移除图片，无需确认
5. **性能优化**: 大量图片时建议启用图片压缩或限制最大选择数量

## 样式定制

可以通过以下方式定制样式：

```typescript
PhotoSelector({
  selectedFiles: this.selectedImages,
  maxSelectNumber: 9,
  title: '选择图片',
  showTitle: true,
  titleColor: '#00428E',
  titleFontSize: '20px',
  onFilesChange: (files: ImageFile[]) => {}
})
.padding(16)
.backgroundColor('#FFFFFF')
.borderRadius(12)
.shadow({ radius: 4, color: '#00000020', offsetX: 0, offsetY: 2 })
```

## 示例页面

项目已包含示例页面 `PhotoSelectorExample.ets`，展示了多种使用场景：

- 示例 1: 处理前照片（最多 3 张）
- 示例 2: 处理后照片（最多 9 张）
- 示例 3: 不显示标题
- 示例 4: 始终显示添加按钮

可以通过以下路由访问示例页面：

```typescript
router.pushUrl({ url: 'pages/PhotoSelectorExample' })
```

## 更新日志

### v1.0.0 (2026-04-01)
- 初始版本发布
- 支持图片选择、预览、删除
- 支持数量限制
- 支持样式自定义
- 提供示例页面

## 技术支持

如有问题或建议，请联系开发者。
