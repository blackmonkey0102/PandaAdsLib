import Foundation
import Adjust
import GoogleMobileAds
import UIKit

public class RewardedAdManager: NSObject {
    public static let shared = RewardedAdManager()
    private override init() {}

    private var rewardedAd: GADRewardedAd?
    private var onAdLoadSuccess: (() -> Void)?
    private var onAdLoadFail: ((Error) -> Void)?
    private var onAdRewardEarned: (() -> Void)?
    private var onAdClosed: (() -> Void)?
    
    private var loadingTimeoutTimer: Timer?
    private let TIME_OUT_LOADING = 10
    private var adPlacement = ""
    
    public func loadRewardedAd(adPlacement: String, adUnitID: String, vc:UIViewController, isShowLoading: Bool, onSuccess: (() -> Void)? = nil, onFail: ((Error) -> Void)? = nil) {
        self.adPlacement = adPlacement
        self.onAdLoadSuccess = onSuccess
        self.onAdLoadFail = onFail

        AnalyticEvent.adsLogEvent(.ad_reward_call_load)
        
        var isTimeout = false
        
        if isShowLoading {
            showLoadingDialog(view: vc.view, timeout: TimeInterval(TIME_OUT_LOADING))
            
            loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(TIME_OUT_LOADING), repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    self.dismissLoadingDialog()
                    isTimeout = true // Đánh dấu timeout
                    MyHelpers.myLog(text: "Loading timeout reached")
                    self.onAdLoadFail?(NSError(domain: "com.app.ads", code: -1, userInfo: [NSLocalizedDescriptionKey: "Loading timeout reached"]))
                }
        }
        
        AnalyticEvent.adsLogEvent(.ad_reward_request)
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            guard let self = self else { return }
            
            if isTimeout {
                return
            }
            
            self.dismissLoadingDialog()

            if let error = error {
                MyHelpers.myLog(text: "Failed to load rewarded ad: \(error.localizedDescription)")
                self.onAdLoadFail?(error)
                AnalyticEvent.adsLogEvent(.ad_reward_load_failed)
                return
            }
            
            ad?.paidEventHandler = {value in
                let responseInfo = ad?.responseInfo
                let adNetworkName = responseInfo?.adNetworkClassName
                // Log analytic với ad_source
                AnalyticEvent.adsLogEvent(.ad_reward_paid, parameters: [
                    "ad_placement": adPlacement,
                    "ad_platform": "Admob",
                    "ad_unit_name": adUnitID,
                    "internet_status": "\(MyHelpers.isConnectionInternet())",
                    "ad_source": adNetworkName ?? "unknown"
                ])
               
                let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                adRevenue?.setAdRevenuePlacement("Reward")
                adRevenue?.setAdRevenueNetwork(responseInfo?.adNetworkClassName ?? "unknown")
                Adjust.trackAdRevenue(adRevenue!)
            }

            MyHelpers.myLog(text: "Rewarded ad loaded successfully")
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.onAdLoadSuccess?()
            AnalyticEvent.adsLogEvent(.ad_reward_loaded)
        }
        
       
    }

    public func showRewardedAd(
        from viewController: UIViewController,
        onRewardEarned: (() -> Void)? = nil,
        onClosed: (() -> Void)? = nil
    ) {
        AnalyticEvent.adsLogEvent(.ad_reward_call_show)
        guard let rewardedAd = rewardedAd else {
            MyHelpers.myLog(text: "Rewarded ad is not ready to show")
            return
        }

        self.onAdRewardEarned = onRewardEarned
        self.onAdClosed = onClosed

        rewardedAd.present(fromRootViewController: viewController) { [weak self] in
            guard let self = self else { return }
            let reward = rewardedAd.adReward
//            MyHelpers.myLog(text: "User earned reward: \(reward.amount) \(reward.type)")
            self.onAdRewardEarned?()
        }
    }

    public func isAdReady() -> Bool {
        return rewardedAd != nil
    }
    
  
    public func showLoadingDialog(view:UIView, timeout: TimeInterval) {
        
    }

    public func dismissLoadingDialog(){
        // Invalidate the timeout timer
        loadingTimeoutTimer?.invalidate()
        loadingTimeoutTimer = nil
     
    }
}

extension RewardedAdManager: GADFullScreenContentDelegate {
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        MyHelpers.myLog(text: "Failed to present rewarded ad: \(error.localizedDescription)")
        AnalyticEvent.adsLogEvent(.ad_reward_show_failed)
    }

    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        MyHelpers.myLog(text: "Rewarded ad dismissed")
        rewardedAd = nil
        //loadRewardedAd(adUnitID: adUnitID) // Reload the ad after it’s closed
        onAdClosed?()
        StatusAds.isShowingInter = false
        AnalyticEvent.adsLogEvent(.ad_reward_closed)
    }

    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        MyHelpers.myLog(text: "Rewarded ad recorded impression")
        StatusAds.isShowingInter = true
        AnalyticEvent.adsLogEvent(.ad_reward_open)
    }

    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        MyHelpers.myLog(text: "Rewarded ad recorded click")
        AnalyticEvent.adsLogEvent(.ad_reward_clicked)
    }
    
    
}

