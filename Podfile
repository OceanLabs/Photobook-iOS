platform :ios, '10.0'
use_frameworks!

target 'Photobook App' do
pod 'Fabric'
pod 'Crashlytics'
pod 'OAuthSwift', '~> 2.0.0'
pod 'KeychainSwift', '~> 16.0.1'
pod 'SDWebImage', '~> 4.3'
pod 'FBSDKCoreKit'
pod 'FBSDKLoginKit'
pod 'Analytics', '~> 3.6.10'
end

target 'SDK Demo' do
end

target 'Photobook' do
pod 'Stripe', '~> 18.0.0'
pod 'Fabric'
pod 'Crashlytics'
pod 'KeychainSwift', '~> 16.0.1'
pod 'SDWebImage', '~> 4.3'
pod 'Analytics', '~> 3.6.10'
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
