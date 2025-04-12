# PandaAdsLib

[![CI Status](https://img.shields.io/travis/La Phong/PandaAdsLib.svg?style=flat)](https://travis-ci.org/La Phong/PandaAdsLib)
[![Version](https://img.shields.io/cocoapods/v/PandaAdsLib.svg?style=flat)](https://cocoapods.org/pods/PandaAdsLib)
[![License](https://img.shields.io/cocoapods/l/PandaAdsLib.svg?style=flat)](https://cocoapods.org/pods/PandaAdsLib)
[![Platform](https://img.shields.io/cocoapods/p/PandaAdsLib.svg?style=flat)](https://cocoapods.org/pods/PandaAdsLib)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
##### platform :ios, '13.0'
##### Info.plist
```
<key>GADApplicationIdentifier</key>
<string>app-id admob của ứng dụng</string>
<key>NSUserTrackingUsageDescription</key>
<string>Your data will be used to measure advertising efficiency.</string>
```

## Installation

PandaAdsLib is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Firebase/Analytics', '~> 8.8.0'
pod 'Firebase/Crashlytics', '~> 8.8.0'
pod 'Firebase/RemoteConfig', '~> 8.8.0'
pod 'Firebase/Messaging', '~> 8.8.0'

pod 'GoogleMobileAdsMediationFacebook'
pod 'GoogleMobileAdsMediationVungle'
pod 'GoogleMobileAdsMediationMintegral', '~> 7.4.1.0'
pod 'GoogleMobileAdsMediationAppLovin', '~> 11.9.0.0'
pod 'GoogleMobileAdsMediationPangle', '~> 5.2.1.1.0'

pod 'PandaAdsLib'
```
## Sử dụng thư viện
##### Các param thường sử dụng khi load ads
`adPlacement`: Tên của id ads, ví dụ **Inter_Splash = "ca-app-pub-3940256099942544/4411468910"** thì giá trị của **adPlacement** là **Inter_Splash**

`canShowAds`: cho phép load ads hay không, thường kết hợp giữa RemoteConfig vị trí ads và RemoveAds khi mua Inapp Purchase. Ví dụ **canShowAds: RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.Inter_splash) && !MySettings.isRemoveAds()**

`StatusAds.isShowAoaOnScreen`: Cho phép show AppOpen Ads hay không. Ví dụ **StatusAds.isShowAoaOnScreen = false** thì sẽ không show AOA khi user trở lại app cho đến khi đặt lại **StatusAds.isShowAoaOnScreen = true**

`isSmall`: Dùng cho load Native ads, **isSmall = true** -> load Native Small, **isSmall = false** -> load Native Large

### 1. Khởi tạo SDK trong AppDelegate
```ruby
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        let pandaAds = PandaAds.Builder()
            .setAdjustToken(IDS_Constants.ADJUST_TOKEN)             // Adjust token
            //.setIapPurchase(IDS_Constants.ADJUST_IAP_PURCHASE)      // Adjust custom event
            //.setAdImpression(IDS_Constants.ADJUST_AD_IMPRESSION)    // Adjust custom event
            .build()
        pandaAds.initialize()
        
        // MyUnifiedNativeAdViewSmall, MyUnifiedNativeAdView, MyUnifiedNativeAdViewSmallDarkMode, MyUnifiedNativeAdViewDarkMode là 4 file xib chứa layout của native ads large và small, Lấy nó ở trong thư mục Example, sau đó custom giao diện, màu sắc tùy theo design Native Ads
        PandaAds.shared.nativeAdViewProvider = { isSmall, isLightMode in
            let nibName = isSmall
                ? (isLightMode ? "MyUnifiedNativeAdViewSmall" : "MyUnifiedNativeAdViewSmallDarkMode")
                : (isLightMode ? "MyUnifiedNativeAdView" : "MyUnifiedNativeAdViewDarkMode")
            return Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? GADNativeAdView
        }
        return true
    }
```
### 2. Ads ở Splash Screen
`Request UMP -> Request App Tracking -> Request Ads -> NextToScreen`

#### Request UMP
``` ruby
    func requestUMP() {
        RemoteConfigManager.configure(exprationDuration: 0, completion: {isSuccess in
            if RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.enable_ump){
                ConsentManager.shared.checkAndRequestConsent(isRelease: true, completion: {consentGranted in
                    DispatchQueue.main.async {
                        self.requestAppTracking()
                    }
                })
            }else{
                DispatchQueue.main.async {
                    self.requestAppTracking()
                }
            }
        })
    }
```
#### Request ATT
```ruby
    func requestAppTracking() {
        StatusAds.isShowAoaOnScreen = false // đặt là false thì không show AOA cho đến khi trạng thái đặt lại là true
        if #available(iOS 14, *) {
            StatusAds.isShowSettingSystem = true // không show AOA sau khi đóng các popup xin quyền của hệ thống
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    self.requestAds()
                }
            }
        }else{
            requestAds()
        }
    }
```
#### Request Ads: Ví dụ Inter Splash
```ruby
    private func requestAds(){
        // set khoảng thời gian tối thiểu giữa 2 lần show interstitial bất kỳ, lấy giá trị từ RemoteConfig
        PandaAds.shared.setInterval(Int(RemoteConfigManager.valueNumber(forKey: RemoteConfigManager.interval_between_interstitial)))
        
        loadInter()
        loadAOA()
    }
    private func loadAOA(){
        // Gọi load AOA 1 lần duy nhất ở Splash
        AppOpenAdManager.shared.configure(idAds: IDS_Constants.AppOpen_resume, canShowAds: true)
        AppOpenAdManager.shared.loadAppOpenAd()
    }
    
    private func loadInter(){
        // Callback sau khi đóng Inter Splash thì chuyển màn hình
        InterstitialAdSplashAdManager.shared.onAdDismissed = {
            self.navigateToNextScreen()
        }
        
        InterstitialAdSplashAdManager.shared.loadInterAdSplash(adPlacement: "Inter_splash", idInterSplash: IDS_Constants.Inter_splash, canShowAds: true, completion: {interAd, error in
            if interAd == nil{
                // Load inter fail -> chuyển màn hình
                DispatchQueue.main.async {
                    self.navigateToNextScreen()
                }
            }else{
                // Gọi show inter
                interAd!.present(fromRootViewController: self)
            }
        })
    }

    private func navigateToNextScreen(){
        StatusAds.isShowAoaOnScreen = true //cho phép show AOA khi quay trở lại App
        StatusAds.isShowSettingSystem = false
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            let screen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVIewController") as! HomeVIewController
            screen.modalPresentationStyle = .fullScreen
            self.present(screen, animated: true)
        }
    }
```
### 3. Show AppOpen Ads khi quay trở lại app
##### Trong `SceneDelegate`
```ruby
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
...
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let rvc = UIApplication.topViewController(){
            AppOpenAdManager.shared.showAdIfAvailable(from: rvc, canShowAds: true)
        }
    }
...
}
extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
```
### 4. Banner Ads
```ruby
    @IBOutlet weak var viewAD: UIView! // placeholder của banner ads
    func loadBannerAd() {
        BannerAdManager.shared.onBannerAdLoadSuccess = { bannerView in
            print("Banner loaded successfully")
        }

        BannerAdManager.shared.onBannerAdLoadFail = { error in
            print("Banner failed to load: \(error.localizedDescription)")
        }
        AnalyticEvent.adsLogEvent(.ad_banner_create) // event banner được gọi load lần đầu tiên
        BannerAdManager.shared.loadBannerAd(
            adPlacement: "Banner_all",
            adUnitID: IDS_Constants.Banner_all,
            canShowAds: true,
            containerView: viewAD,
            viewController: self
        )
    }
```
### 5. Native Ads
```ruby
    @IBOutlet weak var viewADNativeLarge: UIView! // placeholder của native ads
    private func loadNativeAd(){
        NativeAdManager.shared.onNativeAdLoadSuccess = { (nativeAd, adPlacement) in
            print("Native Ad Loaded Successfully: \(nativeAd.headline ?? "")")
        }

        NativeAdManager.shared.onNativeAdLoadFail = { (error, adPlacement) in
            print("Failed to load Native Ad: \(error?.localizedDescription)")
        }
        
        NativeAdManager.shared.loadNativeAd(
            adPlacement: "Native_language_2F",
            adUnitID: IDS_Constants.Native_language_2F,
            canShowAds: true,
            isSmall: false, // true nếu muốn show native small
            isLightMode: false, // mặc định là true
            containerView: viewADNativeLarge,
            viewController: self
        )
    }
```
### 5. Interstitial Ads
##### Load interstitial, gọi trong ViewDidLoad
```ruby
    private func loadInterAd(){
        // thêm delegate để nhận callback sau khi đóng Interstitial
        InterstitialAdAdManager.shared.addDelegate(self)
        InterstitialAdAdManager.shared.loadInterAd(adPlacement: "Inter_home", idInter: IDS_Constants.Inter_home, interName: "Inter_home", canShowAds: true, completion: {interAd, error in
        })
    }
```
##### Show interstitial
```ruby
    private func showInterAd(){
        InterstitialAdAdManager.shared.presentAd(idInter: IDS_Constants.Inter_home, interName: "Inter_home", canShowAds: true, from: self)
    }
```
##### Callback khi dismiss interstitial
```ruby
class HomeVIewController: UIViewController, InterstitialAdDelegate{
    func onAdDismissed() {
        print("Inter dismiss - xử lý công việc tại đây")
    }
```
### 6. Rewarded Ads
##### Load và show Reward, Dev có thể thêm dialog loading cho đến khi nhận callback load success hoặc fail, timeout của load reward default = 12s
```ruby
    private func loadReward(){
        RewardedAdManager.shared.loadRewardedAd(adPlacement: "Reward_ads", adUnitID: IDS_Constants.Reward_ads, vc: self, onSuccess: {
            print("Rewarded ad loaded successfully")
            // show Reward sau khi load xong
            RewardedAdManager.shared.showRewardedAd(from: self, onClosed: {
                print("Rewarded close - xử lý công việc tại đây")
            })
        }) { error in
            print("Failed to load rewarded ad: \(error.localizedDescription)")
        }
    }
```

## Author

Panda Team

## License

PandaAdsLib is available under the MIT license. See the LICENSE file for more info.
