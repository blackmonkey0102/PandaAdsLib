import Adjust
import Foundation
import GoogleMobileAds

public class PandaAds: NSObject{
    public static let shared = PandaAds()
    private override init() {}

    public var adjustToken: String = ""
    public var adjustIapPurchase: String = ""
    public var adjustAdImpression: String = ""
    public var intervalBetweenInterstitial: Int = 20
    
    /// Closure để app truyền custom NativeAdView từ xib
    public var nativeAdViewProvider: ((_ isSmall: Bool) -> GADNativeAdView?)?
    
    public func initialize() {
        // Setup Adjust
        if !adjustToken.isEmpty{
            let myAdjustConfig = ADJConfig(
                appToken: adjustToken,
                environment: ADJEnvironmentProduction,
                allowSuppressLogLevel: true)
             myAdjustConfig?.logLevel = ADJLogLevelSuppress
            Adjust.appDidLaunch(myAdjustConfig)
        }
        
        // Setup AdMob
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    public class Builder {
        private var token: String = ""
        private var iap_purchase: String = ""
        private var ad_impression: String = ""
        private var interval_between_interstitial: Int = 20

        public init() {}

        public func setAdjustToken(_ token: String) -> Builder {
            self.token = token
            return self
        }
        
        public func setIapPurchase(_ token: String) -> Builder {
            self.iap_purchase = token
            return self
        }
        
        public func setAdImpression(_ token: String) -> Builder {
            self.ad_impression = token
            return self
        }
        
        public func setIntervalBetweenInterstitial(_ value: Int) -> Builder {
            self.interval_between_interstitial = value
            return self
        }

        public func build() -> PandaAds {
            let instance = PandaAds.shared
            instance.adjustToken = self.token
            instance.adjustIapPurchase = self.iap_purchase
            instance.adjustAdImpression = self.ad_impression
            instance.intervalBetweenInterstitial = self.interval_between_interstitial
          
            return instance
        }
    }
}

extension PandaAds {
    @discardableResult
    public func setInterval(_ value: Int) -> Self {
        self.intervalBetweenInterstitial = value
        return self
    }
}
