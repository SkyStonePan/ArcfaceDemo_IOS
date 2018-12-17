# ArcfaceDemo_IOS
Arcface2.0的IosDemo

一、环境要求
1、运行环境
arm64、armv7

2、系统要求
iOS 8.x及以上

3、开发环境
Xcode 9.x及以上

二、快速上手
1、从官网申请sdk：http://www.arcsoft.com.cn/ai/arcface.html，下载iOS2.0版本SDK；

2、打开xcode开发工具，将解压好的SDK中的ArcSoftFaceEngine.framework文件导入进示例Demo中；

3、由于SDK采用了Objective-C++实现，需要保证工程中至少有一个.mm 后缀的源文件(可以将任意一个.m后缀的文件改名为.mm)；

4、需要在Demo中引入系统库：libstdc++.6.0.9.tbd，xcode10.0及以上版本没有该文件，需要从xcode9.0版本的libstdc++.6.0.9.tbd复制过来，引入到Demo中；

5、修改Demo中的Info.plist文件，新增一个属性App Transport Security Settings，在该属性下添加Allow Arbitrary Loads类型Boolean，值设为YES；

6、上述配置修改好之后，将Demo中ASFVideoProcessor.mm和ImageCheckController.m文件中的appId、sdkkey替换为从官网申请的APP_ID、SDK_KEY；

三、问题指南：
1、详细接入指南可见官网：http://ai.arcsoft.com.cn/manual/arcface_ios_guideV2.html；

2、常见问题可见SDK中的doc文档ARCSOFT_ARC_FACE_DEVELOPER'S_GUIDE.pdf，或官网帮助与支持。



