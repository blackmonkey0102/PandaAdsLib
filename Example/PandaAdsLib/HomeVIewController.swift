import PandaAdsLib
import UIKit

class HomeVIewController: UIViewController, InterstitialAdDelegate{
    func onAdDismissed() {
        print("myLog: Inter dismiss")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    private func initView(){
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
        InterstitialAdAdManager.shared.loadInterAd(adPlacement: "Inter_home", idInter: IDS_Constants.Inter_home, interName: "Inter_home", canShowAds: true, completion: {interAd, error in
        })
    }
    
    @IBOutlet weak var viewADNativeLarge: UIView!
    private func loadNativeAd(){
        NativeAdManager.shared.onNativeAdLoadSuccess = { (nativeAd, adPlacement) in
            print("myLog: Native Ad Loaded Successfully: \(nativeAd.headline ?? "")")
        }

        NativeAdManager.shared.onNativeAdLoadFail = { (error, adPlacement) in
            print("myLog: Failed to load Native Ad: \(error?.localizedDescription)")
        }
        
        NativeAdManager.shared.loadNativeAd(
            adPlacement: "Native_language_2F",
            adUnitID: IDS_Constants.Native_language_2F,
            canShowAds: true,
            isSmall: false,
            isLightMode: false,
            containerView: viewADNativeLarge,
            viewController: self
        )
    }
    
    @IBOutlet weak var viewADNativeSmall: UIView!
    func loadNativeSmallAd() {
        NativeAdManager.shared.loadNativeAd(
            adPlacement: "Native_permission",
            adUnitID: IDS_Constants.Native_permission,
            canShowAds: true,
            isSmall: true,
            containerView: viewADNativeSmall,
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
