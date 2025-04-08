import UserNotifications
import Adjust
import Foundation
import GoogleMobileAds

public class InterstitialAdAdManager: NSObject, GADFullScreenContentDelegate{
    public static let shared = InterstitialAdAdManager()
    private override init() {}
    
    
    weak var delegate: InterstitialAdDelegate?
    
    public var delegates = NSHashTable<AnyObject>.weakObjects()
    public var interstitialAds: [String: GADInterstitialAd] = [:]
    
    private var adPlacement = ""
    
    
    // Thêm delegate
    public func addDelegate(_ delegate: InterstitialAdDelegate) {
        delegates.add(delegate)
    }
    
    // Xóa delegate
    public func removeDelegate(_ delegate: InterstitialAdDelegate) {
        delegates.remove(delegate)
    }
    
    /// Load interstitial ad with a completion callback
    public func loadInterAd(adPlacement:String, idInter: String, interName: String, canShowAds: Bool, completion: @escaping (GADInterstitialAd?, Error?) -> Void) {
        self.adPlacement = adPlacement
        AnalyticEvent.adsLogEvent(.ad_inter_call_load)
        
        if let existingAd = interstitialAds[interName] {
            MyHelpers.myLog(text: "Interstitial ad for ID \(interName) already loaded")
            completion(existingAd, nil)
            return
        }
        
        if !canShowAds{
            MyHelpers.myLog(text: "Interstitial config false, of remove ads")
            completion(nil, nil)
            return
        }
        
        AnalyticEvent.adsLogEvent(.ad_inter_request)
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: idInter, request: request) { [weak self] interAd, error in

            if let error = error {
                MyHelpers.myLog(text: "Load inter failed: \(error.localizedDescription)")
                AnalyticEvent.adsLogEvent(.ad_inter_load_failed)
                
                completion(nil, error)
            } else if let interAd = interAd {
                AnalyticEvent.adsLogEvent(.ad_inter_loaded)
                
                interAd.paidEventHandler = {value in
                    let responseInfo = interAd.responseInfo
                    let adNetworkName = responseInfo.adNetworkClassName
                    // Log analytic với ad_source
                    AnalyticEvent.adsLogEvent(.ad_inter_paid, parameters: [
                        "ad_placement": adPlacement,
                        "ad_platform": "Admob",
                        "ad_unit_name": idInter,
                        "internet_status": "\(MyHelpers.isConnectionInternet())",
                        "ad_source": adNetworkName ?? "unknown"
                    ])
                   
                    let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                    adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                    adRevenue?.setAdRevenuePlacement("Interstitial")
                    adRevenue?.setAdRevenueNetwork(responseInfo.adNetworkClassName ?? "unknown")
                    Adjust.trackAdRevenue(adRevenue!)
                    
                    AnalyticEvent.logEventPurchaseAdjust(amount: Double(value.value), currency: value.currencyCode)
                }
                
                MyHelpers.myLog(text: "Interstitial loaded successfully")
                self?.interstitialAds[interName] = interAd
                self?.interstitialAds[interName]!.fullScreenContentDelegate = self
                completion(interAd, nil)
                
            }
        }
    }
    
    public func presentAd(idInter: String, interName: String, canShowAds: Bool, from viewController: UIViewController) {
        guard let interstitialAd = interstitialAds[interName] else {
            MyHelpers.myLog(text: "No interstitial available for ID \(interName)")
            notifyAdDismissed()
            return
        }
        if MySettings.isShowAdsAfter30Seconds() && canShowAds{
            AnalyticEvent.adsLogEvent(.ad_inter_call_show)
            interstitialAd.present(fromRootViewController: viewController)
        }else{
            notifyAdDismissed()
        }
    }
    
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        MyHelpers.myLog(text: "Interstitial failed to present full screen content: \(error.localizedDescription)")
        notifyAdDismissed()
        AnalyticEvent.adsLogEvent(.ad_inter_show_failed)
    }
    
    public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        MyHelpers.myLog(text: "Interstitial adDidRecordImpression")
        StatusAds.isShowingInter = true
        AnalyticEvent.adsLogEvent(.ad_inter_open)
        AnalyticEvent.logEventAdImpressionAdjust()
    }
    
    public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        AnalyticEvent.adsLogEvent(.ad_inter_clicked)
    }
    
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        MyHelpers.myLog(text: "Interstitial did dismiss full screen content")
        AnalyticEvent.adsLogEvent(.ad_inter_closed)
        
        StatusAds.isShowingInter = false
        
        // Xóa quảng cáo khỏi từ điển sau khi đã hiển thị
        if let (key, value) = interstitialAds.first(where: { $0.value === ad }) {
            interstitialAds.removeValue(forKey: key)
            MyHelpers.myLog(text: "Removed interstitial ad for ID \(key) \(value.adUnitID)")
            
            // auto reload ads
            if !StatusAds.NAME_INTER_NOT_RELOAD.contains(key){
                loadInterAd(adPlacement: self.adPlacement, idInter: value.adUnitID, interName: key, canShowAds: true) { _, error in
                    if let error = error {
                        MyHelpers.myLog(text: "Failed to reload ad for ID \(key): \(error.localizedDescription)")
                    } else {
                        MyHelpers.myLog(text: "Reloaded ad successfully for ID \(key)")
                    }
                }
            }
           
        }
        
        MySettings.setShowAdsAfter30Seconds()
        notifyAdDismissed()
    }
    
    // Gửi thông báo đến tất cả delegate
    public func notifyAdDismissed() {
        for delegate in delegates.allObjects {
            (delegate as? InterstitialAdDelegate)?.onAdDismissed()
        }
    }
}

public protocol InterstitialAdDelegate: AnyObject {
    func onAdDismissed()
}

