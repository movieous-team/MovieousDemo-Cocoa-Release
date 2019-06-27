# MovieousDemo-Cocoa

`MovieousDemo-Cocoa` 是 [Movieous](https://movieous.cn/) 开源的基于 [MovieousPlayer](https://github.com/movieous-team/MovieousPlayer-Cocoa-Release)、[MovieousLive](https://github.com/movieous-team/MovieousLive-Cocoa-Release) 和 [MovieousShortVideo](https://github.com/movieous-team/MovieousShortVideo-Cocoa-Release) 的商业级别 iOS 音视频演示应用，它提供包括直播、短视频观看，直播推流，短视频制作，上传等丰富的功能，是学习前述多款 SDK 用法的有效素材。

*其他语言版本: [English](README.en-us.md), [简体中文](README.md).*

## 功能

- [x] 短视频播放
- [x] 短视频录制
- [x] 短视频编辑
- [x] 短视频上传

## 版本要求

iOS 9.0 及其以上

## 使用方法
运行 Demo 需要先使用 CocoaPods 来安装依赖库，如果你没有安装 CocoaPods，可以按照下列步骤安装

### 安装 Cocoapods
如果您已安装 Cocoapods，则请直接跳过该步骤，直接进入下一步骤。
如果你未接触过 Cocoapods ，我们推荐您阅读 [唐巧的博客-用CocoaPods做iOS程序的依赖管理](https://blog.devtang.com/2014/05/25/use-cocoapod-to-manage-ios-lib-dependency/ "用CocoaPods做iOS程序的依赖管理") ，了解我们为何使用 Cocoapods 。另外文章中提及的淘宝源已经不再维护，需要使用 [Ruby-China RubyGems 镜像](https://gems.ruby-china.com/)替换。

如果觉得上面两个文章比较繁琐，可以直接根据我们提供的简要步骤，进行安装。
* 简要步骤：打开mac自带的 终端(terminal)，然后输入依次执行下述命令。

```bash
# 注释：Ruby-China 推荐2.6.x，实际 mac 自带的 ruby 也能用了
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
gem sources -l
# 注释：上面的命令，应该会输出以下内容，>>> 代表此处为输出
>>> https://gems.ruby-china.com
# 注释：确保只有 gems.ruby-china.com

sudo gem install cocoapods
# 注释：由于我们不需要使用官方库，所以可以不执行 pod setup。
```

### 安装依赖
找到 `Podfile` 所在目录，在命令行中运行 `pod install` 命令，等待命令运行完成

### 添加三方 license
请先联系 [销售](mailto:sales@movieous.video) 获取试用 license
#### TuSDK license
在 `AppDelegate.h` 中 `[TuSDK initSdkWithAppKey:@""]` 方法中填写 TuSDK license。（如不需要相关功能可忽略）

#### SenseTime license
将 `SENSEME.lic` 文件拖拽到项目中，并勾选 `Add to target` 中的 `MovieousDemo`。（如不需要相关功能可忽略）

#### FU license
在 `Vendor/Faceunity/authpack.h` 中将 license 中的内容粘贴进去。（如不需要相关功能可忽略）

## 反馈及意见

当你遇到任何问题时，可以向我们提交 issue 来反馈。

[提交 issue](https://github.com/movieous-team/MovieousDemo-Cocoa-Release/issues)。
