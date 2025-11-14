source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitee.com/polyv_ef/plvspecs.git'
#source 'https://github.com/volcengine/volcengine-specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'PolyvLiveScenesDemo' do
  use_frameworks!

  # 保利威 多场景 SDK
  pod 'PLVLiveScenesSDK', '1.29.3'

  # 保利威 手机开播场景 需依赖的库
  pod 'PLVBytedEffectSDK', '4.4.2'
  pod 'PLVBeautyEffect','1.3.1'

  pod 'PLVBusinessSDK', '1.29.3', :subspecs => ['Beauty']
  
  # 保利威 SM2加密 需依赖的库
  pod 'PLVLOpenSSL', '~> 1.1.12100'
  pod 'PLVFoundationSDK', '1.29.1', :subspecs => ['CryptoUtils']

  # 保利威 投屏 需依赖的库
  pod 'PLVDLNA', '0.2.0'
  
  # 保利威 UI源码 需依赖的库
  pod 'SDWebImage', '4.4.0'
  pod 'MJRefresh', '~> 3.5.0'
  pod 'PLVImagePickerController', '~> 0.1.5' # 仅手机开播场景需要
  pod 'SVGAPlayer', '~> 2.3'
  pod 'Protobuf', '3.22.4'
end

target 'PLVScreenShareExtension' do
  use_frameworks!
  pod 'PLVBusinessSDK', '1.29.3', :subspecs => ['AbstractBSH','ReplayKitExt']
  pod 'PLVFoundationSDK', '1.29.1', :subspecs => ['AbstractBase']
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
            # 支持模拟器
            config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
         end
    end
  end
end
