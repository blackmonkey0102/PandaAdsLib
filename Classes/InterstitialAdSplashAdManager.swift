import UserNotifications
import Adjust
import Foundation
import GoogleMobileAds

public class InterstitialAdSplashAdManager: NSObject, GADFullScreenContentDelegate{
    public static let shared = InterstitialAdSplashAdManager()
    private override init() {}
    
    public var onAdDismissed: (() -> Void)?
    private var adPlacement = ""
    private var interstitialAd: GADInterstitialAd?
    private var isLoadAppOpen = false
    
    
    // load AOA Splash
    public func loadAdAppOpen(idAdOpenApp: String, adPlacement: String, idAppOpenSplash: String, canShowAds: Bool, completion: @escaping (GADAppOpenAd?, Error?) -> Void) {
        AnalyticEvent.adsLogEvent(.ad_open_call_load)
        isLoadAppOpen = true
        if !canShowAds {
            MyHelpers.myLog(text: "\(adPlacement) config false, of remove ads")
            completion(nil, nil)
            return
        }
        
        GADAppOpenAd.load(withAdUnitID: idAdOpenApp, request: GADRequest(), orientation: .portrait) { ad, error in
            if let error = error {
                MyHelpers.myLog(text: "Failed to load AppOpen Splash ad: \(error.localizedDescription)")
                AnalyticEvent.adsLogEvent(.ad_open_load_failed)
                completion(nil, error)
                return
            }
            
            ad?.fullScreenContentDelegate = self
            ad?.paidEventHandler = { value in
                let responseInfo = ad?.responseInfo
                let adNetworkName = responseInfo?.adNetworkClassName
                AnalyticEvent.adsLogEvent(.ad_open_paid, parameters: [
                    "ad_placement": "\(adPlacement)",
                    "ad_platform": "Admob",
                    "ad_unit_name": "\(idAppOpenSplash ?? "")",
                    "internet_status": "\(MyHelpers.isConnectionInternet())",
                    "ad_source": adNetworkName ?? "unknown"
                ])
                
                let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                adRevenue?.setAdRevenuePlacement("AppOpen")
                adRevenue?.setAdRevenueNetwork(responseInfo?.adNetworkClassName ?? "unknown")
                Adjust.trackAdRevenue(adRevenue!)
            }
            completion(ad, nil)
        }
       
    }
    
    /// Load interstitial ad with a completion callback
    public func loadInterAdSplash(adPlacement: String, idInterSplash: String, canShowAds: Bool, completion: @escaping (GADInterstitialAd?, Error?) -> Void) {
        self.adPlacement = adPlacement
        AnalyticEvent.adsLogEvent(.ad_inter_call_load)
        isLoadAppOpen = false
        if !canShowAds {
            MyHelpers.myLog(text: "\(adPlacement) config false, of remove ads")
            completion(nil, nil)
            return
        }
         
        let request = GADRequest()
        var isCompletionCalled = false
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            if !isCompletionCalled {
                isCompletionCalled = true
                MyHelpers.myLog(text: "\(adPlacement) load timeout after 30 seconds")
                completion(nil, NSError(domain: "InterstitialAdSplashAdManager", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Ad load timeout"]))
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeoutWorkItem)
        
        AnalyticEvent.adsLogEvent(.ad_inter_request)
        GADInterstitialAd.load(withAdUnitID: idInterSplash, request: request) { [weak self] interAd, error in
            if !isCompletionCalled{
                isCompletionCalled = true
                timeoutWorkItem.cancel()
                
                if let error = error {
                    MyHelpers.myLog(text: "Load \(adPlacement) failed: \(error.localizedDescription)")
                    AnalyticEvent.adsLogEvent(.ad_inter_load_failed)
                    completion(nil, error)
                } else if let interAd = interAd {
                    AnalyticEvent.adsLogEvent(.ad_inter_loaded)
                    AnalyticEvent.adsLogEvent(.ad_inter_call_show)
                    interAd.paidEventHandler = {value in
                        let responseInfo = interAd.responseInfo
                        let adNetworkName = responseInfo.adNetworkClassName
                        // Log analytic với ad_source
                        AnalyticEvent.adsLogEvent(.ad_inter_paid, parameters: [
                            "ad_placement": adPlacement,
                            "ad_platform": "Admob",
                            "ad_unit_name": idInterSplash,
                            "internet_status": "\(MyHelpers.isConnectionInternet())",
                            "ad_source": adNetworkName ?? "unknown"
                        ])
                        
                        let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                        adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                        adRevenue?.setAdRevenuePlacement("Interstitial")
                        adRevenue?.setAdRevenueNetwork(responseInfo.adNetworkClassName ?? "unknown")
                        Adjust.trackAdRevenue(adRevenue!)
                    }
                    
                    MyHelpers.myLog(text: "\(adPlacement) loaded successfully")
                    self?.interstitialAd = interAd
                    self?.interstitialAd!.fullScreenContentDelegate = self
                    completion(interAd, nil)
                }
            }
        }
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        if isLoadAppOpen{
            MyHelpers.myLog(text: "AppOpen splash Ad failed to present full screen content: \(error.localizedDescription)")
            AnalyticEvent.adsLogEvent(.ad_open_show_failed)
            onAdDismissed?()
            return
        }
        MyHelpers.myLog(text: "\(adPlacement) failed to present full screen content: \(error.localizedDescription)")
        onAdDismissed?()
        AnalyticEvent.adsLogEvent(.ad_inter_show_failed)
    }
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        if isLoadAppOpen{
            AnalyticEvent.adsLogEvent(.ad_open_clicked)
            return
        }
        AnalyticEvent.adsLogEvent(.ad_inter_clicked)
    }
    
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        if isLoadAppOpen{
            MyHelpers.myLog(text: "AppOpen splash Ad adDidRecordImpression.")
            AnalyticEvent.adsLogEvent(.ad_open_open)
            StatusAds.isShowingInter = true
            return
        }
        MyHelpers.myLog(text: "\(adPlacement) adDidRecordImpression")
        StatusAds.isShowingInter = true
        AnalyticEvent.adsLogEvent(.ad_inter_open)
    }

//    public func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        MyHelpers.myLog(text: "Interstitial splash did present full screen content")
//        StatusAds.isShowingInter = true
//    }
//
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if isLoadAppOpen{
            MyHelpers.myLog(text: "AppOpen splash Ad did dismiss full screen content.")
            AnalyticEvent.adsLogEvent(.ad_open_closed)
            MySettings.setShowAdsAfter30Seconds()
            onAdDismissed?()
            StatusAds.isShowingInter = false
            return
        }
        MyHelpers.myLog(text: "\(adPlacement) did dismiss full screen content")
        AnalyticEvent.adsLogEvent(.ad_inter_closed)
        
        MySettings.setShowAdsAfter30Seconds()
        onAdDismissed?()
        StatusAds.isShowingInter = false
    }
    
}


