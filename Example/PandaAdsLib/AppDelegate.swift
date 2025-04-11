import PandaAdsLib
import FirebaseCore
import UIKit
import GoogleMobileAds

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        let pandaAds = PandaAds.Builder()
            .setAdjustToken(IDS_Constants.ADJUST_TOKEN)             // Adjust token
            //.setIapPurchase(IDS_Constants.ADJUST_IAP_PURCHASE)      // Adjust custom event
            //.setAdImpression(IDS_Constants.ADJUST_AD_IMPRESSION)    // Adjust custom event
            .build()
        pandaAds.initialize()
        
        //MyUnifiedNativeAdViewSmall, MyUnifiedNativeAdView là 2 file xib chứa layout của native ads large và small, Lấy nó ở trong thư mục Example
      
        
        PandaAds.shared.nativeAdViewProvider = { isSmall, isLightMode in
            let nibName = isSmall
                ? (isLightMode ? "MyUnifiedNativeAdViewSmall" : "MyUnifiedNativeAdViewSmallDarkMode")
                : (isLightMode ? "MyUnifiedNativeAdView" : "MyUnifiedNativeAdViewDarkMode")

            return Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as? GADNativeAdView
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

