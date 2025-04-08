import UserNotifications
import Adjust
import Foundation
import GoogleMobileAds

private enum STATE_LOAD_BANNER{
    case LOADING
    case FAIL
    case SUCCESS
}

public class BannerAdManager: NSObject {
    public static let shared = BannerAdManager()
    private override init() {}
    
    public var onBannerAdLoadSuccess: ((GADBannerView) -> Void)?
    public var onBannerAdLoadFail: ((Error) -> Void)?
    
    private var containerView: UIView!
    private var adUnitNameRequest = ""
    private var nameViewController = ""
    private var adPlacement = ""
   
    private var stateLoadBanner = STATE_LOAD_BANNER.SUCCESS
    private var isShowingBanner = false
    private var isShowingBannerMainVC = false
    
    public func loadBannerAd(
            adPlacement:String,
            adUnitID: String,
            canShowAds: Bool,
            containerView: UIView,
            viewController: UIViewController
        ) {
            self.adPlacement = adPlacement
            if !canShowAds || MySettings.isRemoveAds() || !Helpers.isConnectionInternet(){
                Helpers.myLog(text: "Banner config false, or remove ads, or no internet")
                containerView.isHidden = true
                return
            }
           
            if adUnitNameRequest == "" || adUnitNameRequest != adUnitID || nameViewController != String(describing: type(of: viewController)){
                isShowingBanner = false
                adUnitNameRequest = adUnitID
                stateLoadBanner = .SUCCESS
            }
            Helpers.myLog(text: "Banner adUnitNameRequest = \(adUnitNameRequest) - isShowingBanner = \(isShowingBanner) - stateLoadBanner = \(stateLoadBanner) - title: \(String(describing: type(of: viewController)))")
            if stateLoadBanner == .SUCCESS || stateLoadBanner == .FAIL || adUnitNameRequest != adUnitID || nameViewController != String(describing: type(of: viewController)){
                adUnitNameRequest = adUnitID
                nameViewController = String(describing: type(of: viewController))
                
                // Tạo banner mới
                let bannerView = GADBannerView()
                
                // Tính toán kích thước banner dựa trên chiều rộng của view
                let frame = { () -> CGRect in
                    if #available(iOS 11.0, *) {
                        return viewController.view.frame.inset(by: viewController.view.safeAreaInsets)
                    } else {
                        return viewController.view.frame
                    }
                }()
                let viewWidth = frame.size.width
                
                bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
                bannerView.adUnitID = adUnitID
                bannerView.rootViewController = viewController
                bannerView.delegate = self
                
                // Lưu tham chiếu containerView và hiện nó mặc định
                self.containerView = containerView
                self.containerView.isHidden = false // Container hiển thị mặc định

                // Gắn banner view vào container
                containerView.addSubview(bannerView)

                // Load quảng cáo mới
                bannerView.load(GADRequest())
                stateLoadBanner = .LOADING
                
                AnalyticEvent.adsLogEvent(.ad_banner_load)
            }

        }
    }

    extension BannerAdManager: GADBannerViewDelegate {
        public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            Helpers.myLog(text: "Banner did receive ad: \(bannerView.adUnitID ?? "Unknown ID")")
            AnalyticEvent.adsLogEvent(.ad_banner_loaded)
            
            bannerView.paidEventHandler = {value in
                let responseInfo = bannerView.responseInfo
                let adNetworkName = responseInfo?.adNetworkClassName
                AnalyticEvent.adsLogEvent(.ad_banner_paid, parameters: [
                    "ad_placement": self.adPlacement,
                    "ad_platform": "Admob",
                    "ad_unit_name": "\(bannerView.adUnitID ?? "Unknown ID")",
                    "internet_status": "\(Helpers.isConnectionInternet())",
                    "ad_source": adNetworkName ?? "unknown"
                ])
                
                let adRevenue = ADJAdRevenue(source: ADJAdRevenueSourceAdMob)
                adRevenue?.setRevenue(Double(value.value), currency: value.currencyCode)
                adRevenue?.setAdRevenuePlacement("Banner")
                adRevenue?.setAdRevenueNetwork(responseInfo?.adNetworkClassName ?? "unknown")
                Adjust.trackAdRevenue(adRevenue!)
            }
            
            // Gắn banner view vào container
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                bannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                bannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bannerView.heightAnchor.constraint(equalToConstant: bannerView.adSize.size.height)
            ])

            // Cập nhật chiều cao containerView theo banner
            containerView.heightAnchor.constraint(equalToConstant: bannerView.adSize.size.height).isActive = true

            onBannerAdLoadSuccess?(bannerView)
            stateLoadBanner = .SUCCESS
            isShowingBanner = true
            if StatusAds.NAME_BANNER_RELOAD_VC.contains(nameViewController){
                isShowingBannerMainVC = true
            }
        }
        
        public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            Helpers.myLog(text: "Banner failed to load: \(error.localizedDescription)")
            AnalyticEvent.adsLogEvent(.ad_banner_load_failed)
            
            stateLoadBanner = .FAIL
            onBannerAdLoadFail?(error)
            
            if StatusAds.NAME_BANNER_RELOAD_VC.contains(nameViewController) && isShowingBannerMainVC{
                return
            }
            // Ẩn containerView khi banner không tải được
            if !isShowingBanner {
                containerView.isHidden = true
            }
            
        }
        
        public func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            AnalyticEvent.adsLogEvent(.ad_banner_clicked)
        }
        
        public func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            Helpers.myLog(text: "Banner ad recorded impression")
            
        }
        
        public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            Helpers.myLog(text: "Banner ad will present screen")
        }
        
        public func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
            Helpers.myLog(text: "Banner ad will dismiss screen")
        }
        
        public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            Helpers.myLog(text: "Banner ad did dismiss screen")
        }
    }

