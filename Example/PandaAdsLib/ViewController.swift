import PandaAdsLib
import UIKit

class ViewController: UIViewController, InterstitialAdDelegate{
    func onAdDismissed() {
        print("myLog: Inter dismiss")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        RemoteConfigManager.configure(exprationDuration: 0, completion: {isSuccess in
            
            // set time interval between interstitial
            PandaAds.shared.setInterval(Int(RemoteConfigManager.valueNumber(forKey: RemoteConfigManager.interval_between_interstitial)))
            
            if RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.enable_ump){
                ConsentManager.shared.checkAndRequestConsent(isRelease: true, completion: {consentGranted in
                    DispatchQueue.main.async {
                        if consentGranted {
                            MyHelpers.myLog(text: "Consent granted, proceed with ads")
                            // Initialize Google Mobile Ads SDK or load ads
                            self.initView()
                        } else {
                            MyHelpers.myLog(text: "Consent not granted or required")
                            self.initView()
                        }
                    }
                })
            }else{
                DispatchQueue.main.async {
                    self.initView()
                }
            }
        })
        
    }
    
    private func initView(){
        print("myLog: \(PandaAds.shared.intervalBetweenInterstitial)")
        loadBannerAd()
        
        loadNativeAd()
        
        loadInterAd()
    }
    
    private func loadReward(){
        RewardedAdManager.shared.loadRewardedAd(adPlacement: "Reward_ads", adUnitID: IDS_Constants.Reward_ads, vc: self, onSuccess: {
            print("myLog: Rewarded ad loaded successfully")
            RewardedAdManager.shared.showRewardedAd(from: self, onClosed: {
                print("myLog: rewarded close")
            })
        }) { error in
            print("myLog: Failed to load rewarded ad: \(error.localizedDescription)")
        }
       
    }
    
    private func loadInterAd(){
        InterstitialAdAdManager.shared.addDelegate(self)
        InterstitialAdAdManager.shared.loadInterAd(adPlacement: "Inter_home", idInter: IDS_Constants.Inter_home, interName: "Inter_home", canShowAds: RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.Inter_home), completion: {interAd, error in
        })
    }
    
    @IBOutlet weak var viewADNative: UIView!
    func loadNativeAd() {
        NativeAdManager.shared.onNativeAdLoadSuccess = { (nativeAd, adPlacement) in
            print("myLog: Native Ad Loaded Successfully: \(nativeAd.headline ?? "")")
        }

        NativeAdManager.shared.onNativeAdLoadFail = { (error, adPlacement) in
            print("myLog: Failed to load Native Ad: \(error?.localizedDescription)")
        }
        
        NativeAdManager.shared.loadNativeAd(
            adPlacement: "Native_language",
            adUnitID: IDS_Constants.Native_language,
            canShowAds: RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.Native_language),
            isSmall: false,
            containerView: viewADNative,
            viewController: self
        )
    }
    

    @IBOutlet weak var viewAD: UIView!
    func loadBannerAd() {
        BannerAdManager.shared.onBannerAdLoadSuccess = { bannerView in
            print("Banner loaded successfully")
        }

        BannerAdManager.shared.onBannerAdLoadFail = { error in
            print("Banner failed to load: \(error.localizedDescription)")
        }
        AnalyticEvent.adsLogEvent(.ad_banner_create)
        BannerAdManager.shared.loadBannerAd(
            adPlacement: "Banner_splash",
            adUnitID: IDS_Constants.Banner_all,
            canShowAds: RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.Banner_splash),
            containerView: viewAD,
            viewController: self
        )
    }
    
    @IBAction func btShowInterAction(_ any: UIButton){
        InterstitialAdAdManager.shared.presentAd(idInter: IDS_Constants.Inter_home, interName: "Inter_home", canShowAds: RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.Inter_home), from: self)
    }
    
    @IBAction func btShowRewardAction(_ any: UIButton){
        loadReward()
    }
    
    deinit {
        InterstitialAdAdManager.shared.removeDelegate(self)
    }
}

