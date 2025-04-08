import Foundation
import UIKit

public class MySettings {
    static let dataSave = UserDefaults.standard
 
    static let KEY_SHOW_ADS_AFTER_30_SECOND = "key_30_second"
    static let KEY_TIME_SHOW = "key_time_show_ads"

    static func setTimeShowAds(value:Int){
        dataSave.setValue(value, forKey: KEY_TIME_SHOW)
    }
    
    static func getTimeShowAds()->Int{
        dataSave.register(defaults: [KEY_TIME_SHOW : 30])
        return dataSave.integer(forKey: KEY_TIME_SHOW)
    }
    
    static func setShowAdsAfter30Seconds(){
        dataSave.setValue(Date().timeIntervalSince1970, forKey: KEY_SHOW_ADS_AFTER_30_SECOND)
    }
    
    static func isShowAdsAfter30Seconds()->Bool{
        dataSave.register(defaults: [KEY_SHOW_ADS_AFTER_30_SECOND : 0])
        var timeBefore = dataSave.double(forKey: KEY_SHOW_ADS_AFTER_30_SECOND)
        var isAfter = true;
        if timeBefore == 0 {
            isAfter = true
        }else{
            if (Date().timeIntervalSince1970 - timeBefore) >= Double(getTimeShowAds()) {
                isAfter = true
            }else{
                isAfter = false
            }
        }
//        if isAfter {
//            setShowAdsAfter30Seconds()
//        }
        return isAfter
    }
    

}
