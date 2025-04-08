import Foundation
import Adjust
import GoogleMobileAds
import UIKit

public class NativeAdManager: NSObject {
    public static let shared = NativeAdManager()
    private override init() {}

    public var onNativeAdLoadSuccess: ((GADNativeAd, String) -> Void)?
    public var onNativeAdLoadFail: ((Error?, String) -> Void)?

    private var adLoader: GADAdLoader?
    private var containerView: UIView!
    private var isSmall: Bool = false
    private var adPlacement = ""
    
    public func loadNativeAd(
            adPlacement: String,
            adUnitID: String,
            canShowAds: Bool,
            isSmall: Bool,
            containerView: UIView,
            viewController: UIViewController
        ) {
            self.adPlacement = adPlacement
            AnalyticEvent.adsLogEvent(.ad_native_call_load)
            if !canShowAds{
                MyHelpers.myLog(text: "Native config false, of remove ads")
                containerView.isHidden = true
                onNativeAdLoadFail?(nil, adPlacement)
                return
            }
            self.containerView = containerView
            self.containerView.isHidden = false // Hiển thị container mặc định
            self.isSmall = isSmall

            adLoader = GADAdLoader(
                adUnitID: adUnitID,
                rootViewController: viewController,
                adTypes: [.native],
                options: [GADNativeAdMediaAdLoaderOptions()]
            )

            adLoader?.delegate = self
            adLoader?.load(GADRequest())
            AnalyticEvent.adsLogEvent(.ad_native_request)
        }

        private func configureNativeAdView(_ nativeAd: GADNativeAd) -> GADNativeAdView {
            // Tạo và cấu hình NativeAdView từ nib (hoặc bằng code nếu không có nib)
           
            AnalyticEvent.adsLogEvent(.ad_native_call_show)
            
            guard let nativeAdView = Bundle.main.loadNibNamed(isSmall ? "UnifiedNativeAdViewSmall" : "UnifiedNativeAdView", owner: nil, options: nil)?.first as? GADNativeAdView else {
                fatalError("NativeAdView nib file not found")
            }

            // Gắn dữ liệu từ nativeAd vào các thành phần của nativeAdView
            nativeAdView.nativeAd = nativeAd

            // Headline
            if let headlineView = nativeAdView.headlineView as? UILabel {
                headlineView.text = nativeAd.headline
            }

            // Media content
            if let mediaView = nativeAdView.mediaView {
                mediaView.mediaContent = nativeAd.mediaContent
            }

            // Icon
            if let iconView = nativeAdView.iconView as? UIImageView {
                if let icon = nativeAd.icon {
                    iconView.image = icon.image
                    iconView.isHidden = false
                } else {
                    iconView.isHidden = true
                }
            }

            // Call to Action
            if let callToActionView = nativeAdView.callToActionView as? UIButton {
                callToActionView.setTitle(nativeAd.callToAction, for: .normal)
                callToActionView.isHidden = nativeAd.callToAction == nil
            }

            // Body
            if let bodyView = nativeAdView.bodyView as? UILabel {
                bodyView.text = nativeAd.body
                bodyView.isHidden = nativeAd.body == nil
            }
            
            // Advertiser
    //        if let advertiserView = nativeAdView.advertiserView as? UILabel {
    //            advertiserView.text = nativeAd.advertiser
    //            advertiserView.isHidden = nativeAd.advertiser == nil
    //        }

            return nativeAdView
        }
    }

    extension NativeAdManager: GADNativeAdLoaderDelegate {
        public func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad did load: \(adLoader.adUnitID ?? "Unknown ID")")
            nativeAd.paidEventHandler = {value in
                let responseInfo = nativeAd.responseInfo
                let adNetworkName = responseInfo.adNetworkClassName
                AnalyticEvent.adsLogEvent(.ad_native_paid, parameters: [
                    "ad_placement": self.adPlacement,
                    "ad_platform": "Admob",
                    "ad_unit_name": "\(adLoader.adUnitID ?? "Unknown ID")",
                    "internet_status": "\(MyHelpers.isConnectionInternet())",
                    "ad_source": adNetworkName ?? "unknown"
                ])
                
                let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                adRevenue?.setAdRevenuePlacement("Native")
                adRevenue?.setAdRevenueNetwork(responseInfo.adNetworkClassName ?? "unknown")
                Adjust.trackAdRevenue(adRevenue!)
            }
            
            AnalyticEvent.adsLogEvent(.ad_native_loaded)
            
            // Xóa subviews cũ
            containerView.subviews.forEach { $0.removeFromSuperview() }

            // Tạo NativeAdView và cấu hình
            let nativeAdView = configureNativeAdView(nativeAd)
            containerView.addSubview(nativeAdView)
            nativeAdView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                nativeAdView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                nativeAdView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                nativeAdView.topAnchor.constraint(equalTo: containerView.topAnchor),
                nativeAdView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

            containerView.isHidden = false
            onNativeAdLoadSuccess?(nativeAd, adPlacement)
        }

        public func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
            MyHelpers.myLog(text: "Native ad failed to load: \(error.localizedDescription)")
            
            AnalyticEvent.adsLogEvent(.ad_native_load_failed)
            
            containerView.isHidden = true
            onNativeAdLoadFail?(error, adPlacement)
        }
    }

    extension NativeAdManager: GADNativeAdDelegate {
        public func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad did record impression")
            AnalyticEvent.adsLogEvent(.ad_native_open)
        }

        public func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad did record click")
            AnalyticEvent.adsLogEvent(.ad_native_clicked)
        }


        public func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad will present screen")
        }

        public func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad will dismiss screen")
        }

        public func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad did dismiss screen")
        }

        public func nativeAdIsMuted(_ nativeAd: GADNativeAd) {
            MyHelpers.myLog(text: "Native ad is muted")
        }
    }


