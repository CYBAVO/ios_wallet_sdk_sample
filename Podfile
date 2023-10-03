# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/CYBAVO/hw-sdk-ios-release.git'

target 'WalletSDKDemo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WalletSDKDemo
  pod 'GoogleSignIn', '~> 6.2.0'
  pod 'SwiftEventBus', :tag => '5.1.0', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  pod 'Toast-Swift', '~> 4.0.0'
  pod 'CYBAVOWallet', '1.2.505'
  pod 'PKHUD', '~> 5.0'

  target 'WalletSDKDemoTests' do
    inherit! :search_paths
    # Pods for testing
  end
end

# Required for CYBAVOWallet 1.2.497+
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

      # See this: https://developer.apple.com/forums/thread/725300
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
