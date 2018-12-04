# MovieousDemo-Cocoa

`MovieousDemo` is an open source commercial level audio and video demo application developed by [Movieous](https://movieous.cn/) based on [MovieousPlayer](https://github.com/movieous-team/MovieousPlayer-Cocoa-Release)、[MovieousLive](https://github.com/movieous-team/MovieousLive-Cocoa-Release) and [MovieousShortVideo](https://github.com/movieous-team/MovieousShortVideo-Cocoa-Release). It provides various functions including live broadcast and short video play, live broadcast, short video creatiin and upload, and it is also a great resource to learn how to use these SDKs.

*Read this in other languages: [English](README.md), [简体中文](README.zh-cn.md).*

## 功能

- [x] Short video play
- [x] Short video record
- [x] Short video edit
- [x] Short video upload

## SDK Requirements

iOS 9.0 or later

## how to use
To run this demo, you must use CocoaPods to install dependencies, if you haven't installed CocoaPods, you can refer to the following steps to install

### Installation CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build MovieousShortVideo.

### Install dependencies
find directory where `Podfile` is in, run `pod install` in terminal and wait the command's completion

### add vendor licenses
please contact [Sales](sales@movieous.video) to retrieve trial licenses

#### TuSDK license
fill `[TuSDK initSdkWithAppKey:@""]` method in `AppDelegate.h` with TuSDK license。(if you don't need these functions, you can omit this step)

#### SenseTime license
drop `SENSEME.lic` to the project and check `MovieousDemo` in `Add to target`. (if you don't need these functions, you can omit this step)

#### FU license
paste content in your FU license to `Vendor/Faceunity/authpack.h`. (if you don't need these functions, you can omit this step)

## Feedback and Suggestions

Please feedback the problem by submitting issues on GitHub's repo if any problems you got, describe it as clearly as possible, It would be nice if an error message or screenshot also came together, and pointed out the type of bug or other issues in Labels.

[View existing issues and submit bugs here](https://github.com/movieous-team/MovieousDemo-Cocoa-Release/issues).
[Submit issue](https://github.com/movieous-team/MovieousDemo-Cocoa-Release/issues/new)
