# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://bitbucket.org/cybavo/Specs.git'

target 'WalletSDKDemo' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  pod 'GoogleSignIn'
  pod 'SwiftEventBus', :tag => '3.0.1', :git => 'https://github.com/cesarferreira/SwiftEventBus.git'
  pod 'Toast-Swift', '~> 4.0.0'
  pod 'CYBAVOWallet', '~> 1.0.5'

  target 'WalletSDKDemoTests' do
    inherit! :search_paths
    # Pods for testing
  end
end
