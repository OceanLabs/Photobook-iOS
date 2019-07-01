# Photobook SDK for iOS
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg) [![Twitter](https://img.shields.io/badge/twitter-@kite_ly-yellow.svg?style=flat)](http://twitter.com/kite_ly)

The Photobook SDK makes it easy to create beautiful, high quality photo books from within your app.

Harness our worldwide print and distribution network. We'll take care of all the tricky printing and postage stuff for you!

To get started, you will need to have a free Kite developer account. Go to [kite.ly](https://www.kite.ly) to sign up for free.

## Features
- Print a wide variety of photo book sizes on demand
- Dynamic & realtime control over the pricing of products in your app pricing using our web [Developer Dashboard](https://www.kite.ly)
- Revenue & order volume analytics available in the web dashboard
- Review, refund or reprint any order within the web dashboard
- Localized currency support
- No server infrastructure required. We can handle everything for you from processing payments to printing & postage

## Requirements

* Xcode 10.2
* iOS 10.0+ target deployment

## Installation

### CocoaPods

If you're using [CocoaPods](http://cocoapods.org) just add the following to your Podfile:

```ruby
pod "Photobook"
pod 'PayPal-iOS-SDK/Core', '~> 2.18.0'
```

PayPal functionality is also optional although recommended as you'll typically see a higher conversion rate with it.

### Quick Integration
We really mean it when we say integration can be done in minutes.
* **Step 1:** Import the SDK

Objective-C:
```obj-c
@import Photobook;
```
Swift:
```swift
import Photobook
```
* **Step 2:** Set the API key and the environment:

Objective-C:
```obj-c
[[PhotobookSDK shared] setEnvironment:EnvironmentLive]; // Or EnvironmentTest for testing
[[PhotobookSDK shared] setKiteApiKey:@"YOUR_API_KEY"];
```
Swift:
```swift
PhotobookSDK.shared.environment = .live // Or .test for testing
PhotobookSDK.shared.kiteApiKey = "YOUR_API_KEY"
```

* **Step 3:** Set up 3D Secure 2 payments:

Read about SCA (Strong Customer Authentication) requirements [here](https://stripe.com/gb/guides/strong-customer-authentication).

Add a URL Scheme to your info.plist:
```
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>myappname123456</string>
		</array>
	</dict>
</array>
```

Pass the URL Scheme you defined to the Photobook SDK:

Objective-C:
```obj-c
[[PhotobookSDK shared] setKiteUrlScheme:@"myappname123456"];
```
Swift:
```swift
PhotobookSDK.shared.kiteUrlScheme = "myappname123456"
```

Implement the following method in your app delegate:

Objective-C
```obj-c
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return [[PhotobookSDK shared] handleUrlCallBack:url];   
}
```
Swift:
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
   	return PhotobookSDK.shared.handleUrlCallBack(with: url)
}
```

* **Step 4:** Create and present the Photobook SDK ViewController:

Objective-C:
```obj-c
PhotobookAsset *asset = [[PhotobookAsset alloc] initWithUrl:[NSURL URLWithString:@"https://psps.s3.amazonaws.com/sdk_static/4.jpg"] size:CGSizeMake(1034, 1034)];
    
    UIViewController *vc = [[PhotobookSDK shared] photobookViewControllerWith:@[asset] embedInNavigation:YES delegate:nil completion:^(UIViewController *controller, BOOL success){
        [source dismissViewControllerAnimated:YES completion:NULL];
    }];
    
    [self presentViewController:vc animated:YES completion:NULL];
```
Swift:
```swift
let asset = PhotobookAsset(withUrl: URL(string: "https://psps.s3.amazonaws.com/sdk_static/4.jpg"), size: CGSize(width: 1034, height: 1034))
guard let photobookViewController = PhotobookSDK.shared.photobookViewController(with: [asset], completion: { [weak welf = self] (viewController, success) in
    source.navigationController?.popToRootViewController(animated: true)
}) else { return }
present(photobookViewController, animated: true, completion: nil)
```
* **Step 5:**: 🎉Profit🎉

💰💵💶💷💴

## Credentials & Environments
Your mobile app integration requires different API Keys values for each environment: Live and Test (Sandbox).

You can find these Kite API credentials under the [Credentials](https://www.kite.ly/accounts/credentials/) section of the development dashboard.

### Sandbox

Your Sandbox API Key can be used to submit test print orders to our servers. These orders will not be printed and posted but will allow you to integrate the Print SDK into your app without incurring cost. During development and testing you'll primarily want to be using the sandbox environment to avoid moving real money around. To test the sandbox payment you can use your own PayPal sandbox account or contact us at hello@kite.ly

When you're ready to test the end to end printing and postage process; and before you submit your app to the App Store, you'll need to swap in your live API key.

### Live

Your Live API Key is used to submit print orders to our servers that will be printed and posted to the recipient specified. Live orders cost real money. This cost typically passed on to your end user (although this doesn't have to be the case if you want to cover it yourself).

Logging in to our [Developer Dashboard](https://www.kite.ly) allow's you to dynamically change the end user price i.e. the revenue you want to make on every order. Payment in several currencies is supported so that you can easily localize prices for your users. The dashboard also provides an overview of print order volume and the money you're making.

## ApplePay
See our [ApplePay setup documentation](Docs/applepay.md) if you want to enable checkout via ApplePay.

## License
The Photobook SDK is available under a modified MIT license. See the [LICENSE](LICENSE) file for more info.