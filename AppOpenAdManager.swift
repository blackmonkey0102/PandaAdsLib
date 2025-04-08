import Foundation
import Adjust
import GoogleMobileAds
import UIKit

public class AppOpenAdManager: NSObject {
    public static let shared = AppOpenAdManager()
    private override init() {}
    
    private var appOpenAd: GADAppOpenAd?
    private var isAdShowing: Bool = false
    private var lastLoadTime: Date?
        
    public func loadAppOpenAd(idAds: String) {
            AnalyticEvent.adsLogEvent(.ad_open_call_load)
            // Kiểm tra nếu quảng cáo đã tồn tại hoặc đang hiển thị
        if appOpenAd != nil || isAdShowing || MySettings.isRemoveAds() || !RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.AppOpen_resume){ return }
           
            AnalyticEvent.adsLogEvent(.ad_open_request)
        GADAppOpenAd.load(withAdUnitID: idAds, request: GADRequest(), orientation: .portrait) { [weak self] ad, error in
                if let error = error {
                    Helpers.myLog(text: "Failed to load AppOpen ad: \(error.localizedDescription)")
                    AnalyticEvent.adsLogEvent(.ad_open_load_failed)
                    return
                }

                self?.appOpenAd = ad
                self?.lastLoadTime = Date()
                self?.appOpenAd?.fullScreenContentDelegate = self

                AnalyticEvent.adsLogEvent(.ad_open_loaded)
                Helpers.myLog(text: "AppOpen ad loaded successfully.")
                
                self?.appOpenAd?.paidEventHandler = { value in
                    let responseInfo = self?.appOpenAd?.responseInfo
                    let adNetworkName = responseInfo?.adNetworkClassName
                    AnalyticEvent.adsLogEvent(.ad_open_paid, parameters: [
                        "ad_placement": "AppOpen_resume",
                        "ad_platform": "Admob",
                        "ad_unit_name": "\(idAds ?? "")",
                        "internet_status": "\(Helpers.isConnectionInternet())",
                        "ad_source": adNetworkName ?? "unknown"
                    ])
                    
                    let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                    adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                    adRevenue?.setAdRevenuePlacement("AppOpen")
                    adRevenue?.setAdRevenueNetwork(responseInfo?.adNetworkClassName ?? "unknown")
                    Adjust.trackAdRevenue(adRevenue!)
                }
            }
        }
        
        public func showAdIfAvailable(from viewController: UIViewController) {
            if MySettings.isRemoveAds() || !RemoteConfigManager.valueBoolean(forKey: RemoteConfigManager.AppOpen_resume) {
                return
            }
            if StatusAds.isShowSettingSystem{
                Helpers.myLog(text: "Back from system setting, not show AOA.")
                StatusAds.isShowSettingSystem = false
                return
            }
            
            if !StatusAds.isShowAoaOnScreen{
                return
            }
            
            guard let appOpenAd = appOpenAd else {
                Helpers.myLog(text: "AppOpen Ad is not ready to show.")
                loadAppOpenAd() // Tải quảng cáo mới nếu chưa có
                return
            }

            if isAdShowing {
                Helpers.myLog(text: "AppOpen Ad is already showing.")
                return
            }
            
            if StatusAds.isShowingInter{
                Helpers.myLog(text: "Inter Ad is already showing.")
                return
            }

            isAdShowing = true
            appOpenAd.present(fromRootViewController: viewController)
            AnalyticEvent.adsLogEvent(.ad_open_call_show)
        }

        public func handleAppDidBecomeActive() {
            // Kiểm tra nếu quảng cáo đã hết hạn (thời gian hết hạn thường là 4 tiếng kể từ khi tải)
            if let lastLoadTime = lastLoadTime, Date().timeIntervalSince(lastLoadTime) > 3600 * 4 {
                appOpenAd = nil
            }

            if appOpenAd == nil {
                loadAppOpenAd()
            }
        }
        
    }

    extension AppOpenAdManager: GADFullScreenContentDelegate {
        public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            Helpers.myLog(text: "AppOpen Ad did dismiss full screen content.")
            appOpenAd = nil
            isAdShowing = false
            loadAppOpenAd()
            AnalyticEvent.adsLogEvent(.ad_open_closed)
        }

        public func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
            Helpers.myLog(text: "AppOpen Ad adDidRecordImpression.")
            AnalyticEvent.adsLogEvent(.ad_open_open)
        }
        
        public func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
            AnalyticEvent.adsLogEvent(.ad_open_clicked)
        }

        public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            Helpers.myLog(text: "AppOpen Ad failed to present full screen content: \(error.localizedDescription)")
            appOpenAd = nil
            isAdShowing = false
            loadAppOpenAd()
            
            AnalyticEvent.adsLogEvent(.ad_open_show_failed)
        }
    }

