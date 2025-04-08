import Foundation
import FirebaseRemoteConfig

struct RemoteConfigManager {
  
    static let enable_ump = "enable_ump"
    static let interval_between_interstitial = "interval_between_interstitial"
   
    static let in_app_purchase_week = "in_app_purchase_week"
    static let in_app_purchase_month = "in_app_purchase_month"
    static let in_app_purchase_lifetime = "in_app_purchase_lifetime"
    
    static let Inter_splash = "Inter_splash"
    static let AppOpen_resume = "AppOpen_resume"
    static let Native_language = "Native_language"
    static let Inter_home = "Inter_home"
    static let Inter_back = "Inter_back"
    static let Banner_all = "Banner_all"
    static let Banner_splash = "Banner_splash"
    static let Native_onboarding = "Native_onboarding"

    private static var remoteConfig:RemoteConfig = {
        var remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 10
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefault")
        
        return remoteConfig
    }()
    
    static func configure(exprationDuration:TimeInterval = 0, completion: @escaping (Bool) -> Void){
        remoteConfig.fetch(withExpirationDuration: exprationDuration, completionHandler: {
            (status, error) in
            if let err = error{
                print(err.localizedDescription)
                completion(false)
                return
            }
            print("success, received values from remote config!")
            RemoteConfig.remoteConfig().activate { _, _ in
                completion(true)
            }
        })
    }
    
    static func value(forKey key:String)->String{
        return remoteConfig.configValue(forKey: key).stringValue!
    }
    
    static func valueBoolean(forKey key:String)->Bool{
        return remoteConfig.configValue(forKey: key).boolValue
    }
    
    static func valueNumber(forKey key:String)->Int64{
        return Int64(remoteConfig.configValue(forKey: key).numberValue)
    }
    
}
