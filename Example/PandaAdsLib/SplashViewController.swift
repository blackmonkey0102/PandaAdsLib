import PandaAdsLib
import UIKit
import AppTrackingTransparency

class SplashViewController: UIViewController{


    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        SubscriptionManager.shared.checkPurchaseStatus(idSharedSecretInappPurchase: IDS_Constants.SHARED_SECRET_INAPP_PURCHASE, lifetimeProductId: nil){ result in
            guard let (isSubscriptionActive, isLifetimePurchased, idSubPurchsed) = result else {
                print("myLog: ❌ Không thể xác định trạng thái mua hàng (mất mạng, lỗi JSON, receipt không tồn tại, ...)")
                DispatchQueue.main.async {
                    self.requestUMP()
                }
                return
            }
            
            if isLifetimePurchased {
                print("myLog: ✅ Người dùng đã mua gói lifetime 🎉")
            }
            if isSubscriptionActive {
                print("myLog: User đã gia hạn subscription ✅ giữ nguyên k làm gì")
            } else {
                print("myLog: Subscription đã hết hạn ❌ bật ads")
            }
            DispatchQueue.main.async {
                self.requestUMP()
            }
        }
        
    }
    
    func requestUMP() {
        RemoteConfigManager.configure(exprationDuration: 0, completion: {isSuccess in
            if RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.enable_ump){
                ConsentManager.shared.checkAndRequestConsent(isRelease: true, completion: {consentGranted in
                    DispatchQueue.main.async {
                        if consentGranted {
                            self.startSplash()
                        } else {
                            self.startSplash()
                        }
                    }
                })
            }else{
                DispatchQueue.main.async {
                    self.startSplash()
                }
            }
        })
    }
    
    private func startSplash(){
        // don't show AOA
        StatusAds.isShowAoaOnScreen = false
       
        requestAppTracking()
      
    }
    
    func requestAppTracking() {
        if #available(iOS 14, *) {
            StatusAds.isShowSettingSystem = true
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    self.requestAds()
                }
            }
        }else{
            requestAds()
        }
    }

    private func requestAds(){
        // set time interval between interstitial
        PandaAds.shared.setInterval(Int(RemoteConfigManager.valueNumber(forKey: RemoteConfigManager.interval_between_interstitial)))
        
        loadInter()
        loadAOA()
    }
    private func loadAOA(){
        AppOpenAdManager.shared.configure(idAds: IDS_Constants.AppOpen_resume, canShowAds: true)
        AppOpenAdManager.shared.loadAppOpenAd()
    }
    
    private func loadInter(){
        InterstitialAdSplashAdManager.shared.onAdDismissed = {
            self.navigateToNextScreen()
        }
        
        InterstitialAdSplashAdManager.shared.loadInterAdSplash(adPlacement: "Inter_splash", idInterSplash: IDS_Constants.Inter_splash, canShowAds: RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.Inter_splash), completion: {interAd, error in
            if interAd == nil{
                DispatchQueue.main.async {
                    self.navigateToNextScreen()
                }
            }else{
                interAd!.present(fromRootViewController: self)
            }
        })
    }

    private func navigateToNextScreen(){
        StatusAds.isShowAoaOnScreen = true
        StatusAds.isShowSettingSystem = false
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            let screen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeVIewController") as! HomeVIewController
            screen.modalPresentationStyle = .fullScreen
            self.present(screen, animated: true)
        }
    }
    
 
}
