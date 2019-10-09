platform :ios, '10.0'
use_frameworks!

target 'Photobook App' do
pod 'Fabric', '~> 1.10.0'
pod 'Crashlytics', '~> 3.14.0'
pod 'OAuthSwift', '~> 2.0.0'
pod 'KeychainSwift', '~> 17.0.0'
pod 'SDWebImage', '~> 5.2.0'
pod 'FBSDKCoreKit', '~> 5.8.0'
pod 'FBSDKLoginKit', '~> 5.8.0'
pod 'Analytics', '~> 3.7.0'
end

target 'SDK Demo' do
end

target 'Photobook' do
pod 'Stripe', '~> 18.0.0'
pod 'KeychainSwift', '~> 17.0.0'
pod 'SDWebImage', '~> 5.2.0'
pod 'Analytics', '~> 3.7.0'
pod 'PayPal-iOS-Dynamic-Loader'
end

target 'PhotobookTests' do
pod 'OAuthSwift', '~> 2.0.0'
end

# Revert build for active architecture being set to YES by installation
post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
