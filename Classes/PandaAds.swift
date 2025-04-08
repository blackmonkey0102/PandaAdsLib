import Adjust
import Foundation
import GoogleMobileAds

public class PandaAds: NSObject{
    public static let shared = PandaAds()
    private override init() {}

    private var adjustToken: String = ""
    
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

        MyHelpers.myLog(text: "Adjust token: \(adjustToken)")
        // Setup AdMob
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    public class Builder {
        private var token: String = ""

        public init() {}

        public func setAdjustToken(_ token: String) -> Builder {
            self.token = token
            return self
        }

        public func build() -> PandaAds {
            let instance = PandaAds.shared
            instance.adjustToken = self.token
          
            return instance
        }
    }
}

