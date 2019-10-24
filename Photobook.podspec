Pod::Spec.new do |s|

  s.name         = "Photobook"
  s.version      = "2.1.2"
  s.summary      = "The Photobook SDK makes it easy to create beautiful, high quality photo books from within your app"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.platform     = :ios, "10.0"
  s.authors      = { 'Konstantinos Karagiannis' => 'kkarayannis@gmail.com', 'Jaime Landazuri' => 'jlandazuri42@gmail.com', 'Julian Gruber' => '' }
  s.homepage     = 'https://www.kite.ly'
  s.source       = { :git => "https://github.com/OceanLabs/Photobook-iOS.git", :tag => "v" + s.version.to_s }
  s.source_files  = ["Photobook/**/*.swift", "PhotobookSDK/**/*.swift"]
  s.swift_version = "5.0"
  s.resource_bundles  = { 'PhotobookResources' => ['Photobook/Base.lproj/Photobook.storyboard', 'Photobook/Resources/Assets.xcassets', 'Photobook/Resources/Lora-Regular.ttf', 'Photobook/Resources/Montserrat-Bold.ttf', 'Photobook/Resources/OpenSans-Regular.ttf'] }
  s.module_name         = 'Photobook'
  s.dependency "KeychainSwift", "~> 17.0.0"
  s.dependency "SDWebImage", "~> 5.2.0"
  s.dependency "Stripe", "~> 18.0.0"
  s.dependency "Analytics", "~> 3.7.0"
  s.dependency "PayPal-iOS-Dynamic-Loader"

end